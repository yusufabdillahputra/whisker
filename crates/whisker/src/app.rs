//! Perakitan aplikasi: root view Inertia + aset frontend ter-embed.

use axum::Router;
use rust_embed::RustEmbed;
use sqlx::PgPool;
use std::fmt;
use std::net::SocketAddr;
use tokio::net::TcpListener;
use url::Url;
use veer::{
    EmbeddedAssets, InertiaConfig, RootView, RootViewContext, ViteManifestError, ViteRootView,
};
use whisker_mcp::McpConfig;

use crate::config::Config;
use crate::health::health_router;
use whisker_web::{AppState, WebConfig, web_router};

/// Hasil `vite build` (`frontend/dist`), di-embed ke binary (fitur `debug-embed`: juga di debug build).
#[derive(RustEmbed)]
#[folder = "../../frontend/dist/"]
struct Dist;

const VITE_ENTRY: &str = "src/app.tsx";
const VITE_MANIFEST: &str = ".vite/manifest.json";

const VIEWPORT_DEFAULT: &str =
    r#"<meta name="viewport" content="width=device-width, initial-scale=1" />"#;
const VIEWPORT: &str =
    r#"<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />"#;

/// Favicon SVG dari canvas logo (DESIGN.md §10), di-inline sebagai data URI.
const FAVICON_SVG: &str = include_str!("../../../frontend/src/assets/logo/whisker-favicon-32.svg");

/// Skrip tema inline: dijalankan sebelum CSS dimuat agar tidak berkedip. Kunci `whisker-theme` dan
/// logikanya sama dengan `frontend/src/lib/theme.ts` (nilai tak sah = `system`).
const THEME_SCRIPT: &str = r#"<script>(function(){try{var p=localStorage.getItem("whisker-theme");if(p!=="light"&&p!=="dark")p="system";var d=p==="dark"||(p==="system"&&matchMedia("(prefers-color-scheme: dark)").matches);var r=document.documentElement;r.classList.toggle("dark",d);r.style.colorScheme=d?"dark":"light"}catch(e){}})()</script>"#;

/// Isi `<head>` tambahan: favicon + skrip tema.
fn head_extras() -> String {
    format!(
        "<link rel=\"icon\" type=\"image/svg+xml\" href=\"data:image/svg+xml,{}\" />\n{THEME_SCRIPT}\n",
        svg_data_uri(FAVICON_SVG)
    )
}

/// Percent-encode SVG untuk data URI di atribut HTML: spasi beruntun diringkas, karakter yang
/// bermakna di URL/atribut (`%`, `#`, `<`, `>`, `"`, `&`, spasi) di-encode.
fn svg_data_uri(svg: &str) -> String {
    let compact = svg.split_whitespace().collect::<Vec<_>>().join(" ");
    let mut out = String::with_capacity(compact.len() * 2);
    for c in compact.chars() {
        match c {
            '%' => out.push_str("%25"),
            '#' => out.push_str("%23"),
            '<' => out.push_str("%3C"),
            '>' => out.push_str("%3E"),
            '"' => out.push_str("%22"),
            '&' => out.push_str("%26"),
            ' ' => out.push_str("%20"),
            c => out.push(c),
        }
    }
    out
}

#[derive(Debug)]
pub enum AppError {
    /// `frontend/dist/.vite/manifest.json` tidak ter-embed.
    ManifestMissing,
    Manifest(ViteManifestError),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ManifestMissing => write!(f, "manifest Vite `{VITE_MANIFEST}` tidak ter-embed"),
            Self::Manifest(e) => write!(f, "{e}"),
        }
    }
}

impl std::error::Error for AppError {}

/// Root view `ViteRootView` dengan meta viewport `viewport-fit=cover`.
/// veer 0.3.0 menulis meta viewport tetap, jadi teksnya diganti setelah render.
struct WhiskerRootView(ViteRootView);

impl RootView for WhiskerRootView {
    fn render(&self, ctx: RootViewContext<'_>) -> Result<String, String> {
        Ok(self.0.render(ctx)?.replacen(VIEWPORT_DEFAULT, VIEWPORT, 1))
    }

    fn version(&self) -> Option<String> {
        self.0.version()
    }
}

/// Konfigurasi Inertia. `vite_dev_server = Some(url)` → skrip dari Vite dev server (HMR);
/// `None` → produksi dari manifest ter-embed, aset di `/build/*`.
pub fn inertia_config(vite_dev_server: Option<&str>) -> Result<InertiaConfig, AppError> {
    let view = match vite_dev_server {
        Some(url) => ViteRootView::dev().dev_server(url).react_refresh(true),
        None => {
            let file = Dist::get(VITE_MANIFEST).ok_or(AppError::ManifestMissing)?;
            let json = String::from_utf8_lossy(&file.data);
            ViteRootView::production()
                .manifest(json.parse().map_err(AppError::Manifest)?)
                // `file` di manifest sudah berawalan `build/` (Vite `assetsDir`), jadi base = root.
                .asset_base("/")
        }
    }
    .title("Whisker")
    .entry(VITE_ENTRY)
    .head_extras(head_extras());
    Ok(InertiaConfig::new().root_view(WhiskerRootView(view)))
}

/// Gabungkan router web + router lain (`extra`, mis. MCP) dan sajikan aset ter-embed di `/build/*`.
/// `CsrfLayer` dipasang oleh router web, bukan di sini.
pub fn build_app(web: Router, extra: Router) -> Router {
    let assets = EmbeddedAssets::new(|path| Dist::get(&format!("build/{path}")).map(|f| f.data));
    web.merge(extra).nest_service("/build", assets)
}

/// Rakit app lengkap: router web (sesi, guard, CSRF), `/health`, `/mcp`, dan aset ter-embed.
///
/// `csrf_secret` (≥ 32 byte) = secret HMAC `CsrfLayer` router web (satu-satunya, ruling K15).
pub fn compose_app(
    pool: PgPool,
    config: &Config,
    csrf_secret: Vec<u8>,
) -> Result<Router, AppError> {
    let inertia = inertia_config(config.vite_dev_server.as_deref())?;
    let state = AppState::new(pool.clone(), web_config(config, csrf_secret));
    let web = web_router(state, inertia);
    let mcp = whisker_mcp::mcp_router(pool.clone(), mcp_config(&config.public_url));
    Ok(build_app(web, health_router(pool).merge(mcp)))
}

/// `Config` → `WebConfig`.
pub fn web_config(config: &Config, csrf_secret: Vec<u8>) -> WebConfig {
    WebConfig {
        cookie_secure: config.cookie_secure,
        public_url: config.public_url.clone(),
        trusted_proxies: config.trusted_proxies.clone(),
        csrf_secret,
    }
}

/// Sajikan `app` di `listener` sampai `shutdown` selesai. `ConnectInfo<SocketAddr>` dipasang
/// (peer TCP) untuk IP klien throttle login.
pub async fn serve<F>(listener: TcpListener, app: Router, shutdown: F) -> std::io::Result<()>
where
    F: Future<Output = ()> + Send + 'static,
{
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown)
    .await
}

/// Konfigurasi `/mcp`: origin yang diizinkan = origin `WHISKER_PUBLIC_URL` (keputusan owner Q9).
pub fn mcp_config(public_url: &Url) -> McpConfig {
    let origin = public_url.origin();
    McpConfig {
        allowed_origin: origin.is_tuple().then(|| origin.ascii_serialization()),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn favicon_data_uri_is_attribute_safe() {
        let uri = svg_data_uri(FAVICON_SVG);
        assert!(uri.starts_with("%3Csvg%20"), "{uri}");
        for bad in ['"', '<', '>', '#', ' ', '\n', '&'] {
            assert!(!uri.contains(bad), "karakter {bad:?} lolos: {uri}");
        }
        assert!(uri.contains("%23FF7A45"), "titik hidung aksen: {uri}");
    }

    #[test]
    fn head_extras_has_favicon_and_theme_script() {
        let head = head_extras();
        assert!(head.starts_with(
            r#"<link rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg"#
        ));
        assert!(head.contains(r#"localStorage.getItem("whisker-theme")"#));
    }
}
