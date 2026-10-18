//! Perakitan aplikasi: root view Inertia + aset frontend ter-embed.

use axum::Router;
use rust_embed::RustEmbed;
use std::fmt;
use url::Url;
use veer::{
    EmbeddedAssets, InertiaConfig, RootView, RootViewContext, ViteManifestError, ViteRootView,
};
use whisker_mcp::McpConfig;

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

/// Skrip tema inline (sebelum CSS dimuat, cegah kedip) + favicon. Token tema final = Task 11.
const HEAD_EXTRAS: &str = r#"<link rel="icon" href="data:," />
<script>(function(){try{var t=localStorage.getItem("theme");var d=t?t==="dark":matchMedia("(prefers-color-scheme: dark)").matches;document.documentElement.classList.toggle("dark",d)}catch(e){}})()</script>
"#;

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
    .head_extras(HEAD_EXTRAS);
    Ok(InertiaConfig::new().root_view(WhiskerRootView(view)))
}

/// Gabungkan router web + router lain (`extra`, mis. MCP) dan sajikan aset ter-embed di `/build/*`.
/// `CsrfLayer` dipasang oleh router web, bukan di sini.
pub fn build_app(web: Router, extra: Router) -> Router {
    let assets = EmbeddedAssets::new(|path| Dist::get(&format!("build/{path}")).map(|f| f.data));
    web.merge(extra).nest_service("/build", assets)
}

/// Konfigurasi `/mcp`: origin yang diizinkan = origin `WHISKER_PUBLIC_URL` (keputusan owner Q9).
pub fn mcp_config(public_url: &Url) -> McpConfig {
    let origin = public_url.origin();
    McpConfig {
        allowed_origin: origin.is_tuple().then(|| origin.ascii_serialization()),
    }
}
