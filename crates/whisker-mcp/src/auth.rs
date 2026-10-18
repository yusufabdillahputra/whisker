//! Lapisan HTTP `/mcp`: cek `Origin` (keputusan owner Q9) lalu autentikasi Bearer PAT (ADR-004).
//! Format token divalidasi tanpa I/O (`parse_token`: prefix → panjang → alfabet → checksum) sebelum
//! DB disentuh. Semua penolakan autentikasi memakai respons `401` yang identik.

use std::future::Future;

use axum::Json;
use axum::extract::{Request, State};
use axum::http::{HeaderValue, StatusCode, header};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use sqlx::PgPool;
use whisker_core::auth::pat::{parse_token, token_hash};
use whisker_core::error::CoreError;
use whisker_core::token::{TokenPrincipal, authenticate_token};

/// Sumber identitas token dari SHA-256-nya (diganti penghitung pada tes).
pub trait TokenAuthenticator: Clone + Send + Sync + 'static {
    fn authenticate(
        &self,
        hash: [u8; 32],
    ) -> impl Future<Output = Result<Option<TokenPrincipal>, CoreError>> + Send;
}

/// `TokenAuthenticator` produksi: `whisker_core::token::authenticate_token` ke PostgreSQL.
#[derive(Clone)]
pub struct PgTokenAuthenticator {
    pool: PgPool,
}

impl PgTokenAuthenticator {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }
}

impl TokenAuthenticator for PgTokenAuthenticator {
    async fn authenticate(&self, hash: [u8; 32]) -> Result<Option<TokenPrincipal>, CoreError> {
        authenticate_token(&self.pool, &hash).await
    }
}

/// Identitas pemanggil `/mcp` (ruling K4: `TokenPrincipal` lengkap), dipasang sebagai extension request.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct McpPrincipal(pub TokenPrincipal);

/// Origin yang diizinkan untuk `/mcp`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct McpConfig {
    /// Origin `WHISKER_PUBLIC_URL` (mis. `https://whisker.example.com`). Request tanpa header `Origin`
    /// selalu lolos; request ber-`Origin` lain → `403`. `None` = setiap `Origin` yang ada ditolak.
    pub allowed_origin: Option<String>,
}

/// Respons `401` generik — identik untuk semua penyebab.
fn unauthorized() -> Response {
    (
        StatusCode::UNAUTHORIZED,
        [(header::WWW_AUTHENTICATE, HeaderValue::from_static("Bearer"))],
        Json(serde_json::json!({ "error": "unauthorized" })),
    )
        .into_response()
}

/// Tolak `403` bila header `Origin` ada dan berbeda dari origin yang diizinkan.
pub async fn origin_guard(State(cfg): State<McpConfig>, req: Request, next: Next) -> Response {
    if let Some(origin) = req.headers().get(header::ORIGIN) {
        let allowed = cfg.allowed_origin.as_deref().is_some_and(|allowed| {
            origin
                .to_str()
                .is_ok_and(|o| o.trim().eq_ignore_ascii_case(allowed))
        });
        if !allowed {
            tracing::debug!("mcp: request ditolak, Origin asing");
            return (
                StatusCode::FORBIDDEN,
                Json(serde_json::json!({ "error": "forbidden" })),
            )
                .into_response();
        }
    }
    next.run(req).await
}

/// Ambil token dari `Authorization: Bearer <token>` (skema tak peka huruf, RFC 7235).
fn bearer_token(req: &Request) -> Option<&str> {
    let value = req.headers().get(header::AUTHORIZATION)?.to_str().ok()?;
    let (scheme, token) = value.split_once(' ')?;
    scheme
        .eq_ignore_ascii_case("bearer")
        .then(|| token.trim())
        .filter(|t| !t.is_empty())
}

/// Autentikasi `Authorization: Bearer <PAT>`. Sukses → extension `McpPrincipal`, header
/// `Authorization` dibuang sebelum diteruskan (token tak ikut ke `http::request::Parts` rmcp).
pub async fn bearer_auth<A: TokenAuthenticator>(
    State(a): State<A>,
    mut req: Request,
    next: Next,
) -> Response {
    // Format dicek tanpa I/O; token salah format tak pernah mencapai DB.
    let Some(hash) = bearer_token(&req)
        .and_then(|t| parse_token(t).ok())
        .map(token_hash)
    else {
        tracing::debug!("mcp: Bearer PAT tidak ada atau salah format");
        return unauthorized();
    };
    match a.authenticate(hash).await {
        Ok(Some(principal)) => {
            req.headers_mut().remove(header::AUTHORIZATION);
            req.extensions_mut().insert(McpPrincipal(principal));
            next.run(req).await
        }
        Ok(None) => {
            tracing::debug!("mcp: PAT tidak dikenal, tercabut, atau user nonaktif");
            unauthorized()
        }
        Err(e) => {
            tracing::error!(error = %e, "mcp: autentikasi PAT gagal");
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(serde_json::json!({ "error": "internal" })),
            )
                .into_response()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::Router;
    use axum::body::Body;
    use axum::extract::Extension;
    use axum::middleware::from_fn_with_state;
    use axum::routing::post;
    use http_body_util::BodyExt;
    use std::io;
    use std::sync::atomic::{AtomicUsize, Ordering};
    use std::sync::{Arc, Mutex};
    use tower::ServiceExt;
    use uuid::Uuid;
    use whisker_core::auth::pat::generate_token;
    use whisker_core::user::Role;

    const ORIGIN: &str = "https://whisker.example.com";

    /// Authenticator penghitung panggilan; `known` = hash yang dikenal.
    #[derive(Clone, Default)]
    struct CountingAuthenticator {
        calls: Arc<AtomicUsize>,
        known: Option<([u8; 32], TokenPrincipal)>,
    }

    impl CountingAuthenticator {
        fn calls(&self) -> usize {
            self.calls.load(Ordering::SeqCst)
        }
    }

    impl TokenAuthenticator for CountingAuthenticator {
        async fn authenticate(&self, hash: [u8; 32]) -> Result<Option<TokenPrincipal>, CoreError> {
            self.calls.fetch_add(1, Ordering::SeqCst);
            Ok(self
                .known
                .as_ref()
                .filter(|(h, _)| *h == hash)
                .map(|(_, p)| p.clone()))
        }
    }

    fn principal() -> TokenPrincipal {
        TokenPrincipal {
            token_id: Uuid::nil(),
            user_id: Uuid::from_u128(7),
            email: "ani@example.com".to_owned(),
            role: Role::Member,
        }
    }

    /// Handler dalam: kembalikan email principal + apakah header `Authorization` masih ada.
    async fn inner(Extension(McpPrincipal(p)): Extension<McpPrincipal>, req: Request) -> String {
        format!(
            "{}|auth_header={}",
            p.email,
            req.headers().contains_key(header::AUTHORIZATION)
        )
    }

    fn app(auth: CountingAuthenticator) -> Router {
        Router::new()
            .route("/mcp", post(inner))
            .layer(from_fn_with_state(
                auth,
                bearer_auth::<CountingAuthenticator>,
            ))
            .layer(from_fn_with_state(
                McpConfig {
                    allowed_origin: Some(ORIGIN.to_owned()),
                },
                origin_guard,
            ))
    }

    async fn send(app: Router, headers: &[(&str, &str)]) -> (StatusCode, Option<String>, String) {
        let mut req = Request::post("/mcp");
        for (k, v) in headers {
            req = req.header(*k, *v);
        }
        let res = app.oneshot(req.body(Body::empty()).unwrap()).await.unwrap();
        let status = res.status();
        let www = res
            .headers()
            .get(header::WWW_AUTHENTICATE)
            .map(|v| v.to_str().unwrap().to_owned());
        let body = res.into_body().collect().await.unwrap().to_bytes();
        (status, www, String::from_utf8(body.to_vec()).unwrap())
    }

    fn valid_token() -> String {
        generate_token().expose().to_owned()
    }

    /// Ganti satu karakter checksum (karakter terakhir) dengan karakter alfanumerik lain.
    fn bad_checksum(token: &str) -> String {
        let mut t = token.to_owned();
        let last = t.pop().unwrap();
        t.push(if last == 'A' { 'B' } else { 'A' });
        t
    }

    fn known(token: &str) -> CountingAuthenticator {
        CountingAuthenticator {
            known: Some((token_hash(token), principal())),
            ..Default::default()
        }
    }

    fn assert_generic_401(status: StatusCode, www: Option<String>, body: &str) {
        assert_eq!(status, StatusCode::UNAUTHORIZED);
        assert_eq!(www.as_deref(), Some("Bearer"));
        assert_eq!(body, r#"{"error":"unauthorized"}"#);
    }

    #[tokio::test]
    async fn missing_authorization_401_without_lookup() {
        let auth = CountingAuthenticator::default();
        let (status, www, body) = send(app(auth.clone()), &[]).await;
        assert_generic_401(status, www, &body);
        assert_eq!(auth.calls(), 0);
    }

    #[tokio::test]
    async fn non_bearer_scheme_401_without_lookup() {
        let auth = CountingAuthenticator::default();
        let basic = format!("Basic {}", valid_token());
        let (status, www, body) = send(app(auth.clone()), &[("authorization", &basic)]).await;
        assert_generic_401(status, www, &body);
        assert_eq!(auth.calls(), 0);
    }

    #[tokio::test]
    async fn bad_checksum_401_without_lookup() {
        let token = bad_checksum(&valid_token());
        let auth = known(&token);
        let bearer = format!("Bearer {token}");
        let (status, www, body) = send(app(auth.clone()), &[("authorization", &bearer)]).await;
        assert_generic_401(status, www, &body);
        assert_eq!(auth.calls(), 0);
    }

    #[tokio::test]
    async fn wrong_prefix_401_without_lookup() {
        let token = valid_token().replacen("whk_", "ghp_", 1);
        let auth = known(&token);
        let bearer = format!("Bearer {token}");
        let (status, www, body) = send(app(auth.clone()), &[("authorization", &bearer)]).await;
        assert_generic_401(status, www, &body);
        assert_eq!(auth.calls(), 0);
    }

    #[tokio::test]
    async fn unknown_token_401_after_one_lookup() {
        let auth = CountingAuthenticator::default();
        let bearer = format!("Bearer {}", valid_token());
        let (status, www, body) = send(app(auth.clone()), &[("authorization", &bearer)]).await;
        assert_generic_401(status, www, &body);
        assert_eq!(auth.calls(), 1);
    }

    #[tokio::test]
    async fn valid_token_passes_principal_to_inner() {
        let token = valid_token();
        let auth = known(&token);
        let bearer = format!("Bearer {token}");
        let (status, _, body) = send(app(auth.clone()), &[("authorization", &bearer)]).await;
        assert_eq!(status, StatusCode::OK);
        // Header `Authorization` tidak diteruskan ke handler dalam.
        assert_eq!(body, "ani@example.com|auth_header=false");
        assert_eq!(auth.calls(), 1);
    }

    #[tokio::test]
    async fn bearer_scheme_is_case_insensitive() {
        let token = valid_token();
        let bearer = format!("bearer {token}");
        let (status, _, _) = send(app(known(&token)), &[("authorization", &bearer)]).await;
        assert_eq!(status, StatusCode::OK);
    }

    #[tokio::test]
    async fn unauthorized_401_body_identical_for_all_causes() {
        let valid = valid_token();
        let cases = [
            None,
            Some(format!("Basic {valid}")),
            Some("Bearer".to_owned()),
            Some("Bearer ".to_owned()),
            Some(format!("Bearer {}", bad_checksum(&valid))),
            Some(format!("Bearer {}", valid.replacen("whk_", "ghp_", 1))),
            Some(format!("Bearer {}x", valid)),
            Some(format!("Bearer {valid}")), // tidak dikenal authenticator
        ];
        let mut seen = Vec::new();
        for case in cases {
            let headers: Vec<(&str, &str)> = case
                .as_deref()
                .map(|v| vec![("authorization", v)])
                .unwrap_or_default();
            let res = app(CountingAuthenticator::default())
                .oneshot({
                    let mut r = Request::post("/mcp");
                    for (k, v) in &headers {
                        r = r.header(*k, *v);
                    }
                    r.body(Body::empty()).unwrap()
                })
                .await
                .unwrap();
            let mut hs: Vec<(String, String)> = res
                .headers()
                .iter()
                .map(|(k, v)| (k.to_string(), v.to_str().unwrap().to_owned()))
                .collect();
            hs.sort();
            let status = res.status();
            let body = res.into_body().collect().await.unwrap().to_bytes();
            seen.push((status, hs, body));
        }
        assert_eq!(seen[0].0, StatusCode::UNAUTHORIZED);
        assert!(seen.iter().all(|s| *s == seen[0]), "{seen:?}");
    }

    #[tokio::test]
    async fn foreign_origin_403() {
        let token = valid_token();
        let auth = known(&token);
        let bearer = format!("Bearer {token}");
        let (status, _, _) = send(
            app(auth.clone()),
            &[
                ("authorization", &bearer),
                ("origin", "https://evil.example"),
            ],
        )
        .await;
        assert_eq!(status, StatusCode::FORBIDDEN);
        // Origin dicek sebelum autentikasi: DB tidak disentuh.
        assert_eq!(auth.calls(), 0);
    }

    #[tokio::test]
    async fn null_origin_403() {
        let (status, _, _) =
            send(app(CountingAuthenticator::default()), &[("origin", "null")]).await;
        assert_eq!(status, StatusCode::FORBIDDEN);
    }

    #[tokio::test]
    async fn matching_origin_passes() {
        let token = valid_token();
        let bearer = format!("Bearer {token}");
        let (status, _, _) = send(
            app(known(&token)),
            &[("authorization", &bearer), ("origin", ORIGIN)],
        )
        .await;
        assert_eq!(status, StatusCode::OK);
    }

    #[tokio::test]
    async fn missing_origin_passes() {
        let token = valid_token();
        let bearer = format!("Bearer {token}");
        let (status, _, _) = send(app(known(&token)), &[("authorization", &bearer)]).await;
        assert_eq!(status, StatusCode::OK);
    }

    #[tokio::test]
    async fn none_allowed_origin_rejects_any_origin() {
        let token = valid_token();
        let bearer = format!("Bearer {token}");
        let app = Router::new()
            .route("/mcp", post(inner))
            .layer(from_fn_with_state(
                known(&token),
                bearer_auth::<CountingAuthenticator>,
            ))
            .layer(from_fn_with_state(McpConfig::default(), origin_guard));
        let (status, _, _) = send(
            app.clone(),
            &[("authorization", &bearer), ("origin", ORIGIN)],
        )
        .await;
        assert_eq!(status, StatusCode::FORBIDDEN);
        let (status, _, _) = send(app, &[("authorization", &bearer)]).await;
        assert_eq!(status, StatusCode::OK);
    }

    /// Writer log ke buffer bersama.
    #[derive(Clone, Default)]
    struct Captured(Arc<Mutex<Vec<u8>>>);

    impl io::Write for Captured {
        fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
            self.0.lock().unwrap().extend_from_slice(buf);
            Ok(buf.len())
        }
        fn flush(&mut self) -> io::Result<()> {
            Ok(())
        }
    }

    #[tokio::test]
    async fn authorization_header_not_logged() {
        let captured = Captured::default();
        let writer = captured.clone();
        let subscriber = tracing_subscriber::fmt()
            .with_max_level(tracing::Level::TRACE)
            .with_writer(move || writer.clone())
            .finish();
        let _guard = tracing::subscriber::set_default(subscriber);

        let valid = valid_token();
        let bad = bad_checksum(&valid_token());
        let unknown = valid_token();
        for token in [&valid, &bad, &unknown] {
            let bearer = format!("Bearer {token}");
            send(app(known(&valid)), &[("authorization", &bearer)]).await;
        }
        tracing::info!("penanda log aktif");

        let logs = String::from_utf8(captured.0.lock().unwrap().clone()).unwrap();
        assert!(
            logs.contains("penanda log aktif"),
            "subscriber tidak menangkap log"
        );
        for token in [&valid, &bad, &unknown] {
            assert!(!logs.contains(token.as_str()), "token muncul di log");
            assert!(
                !logs.contains(&token[4..20]),
                "potongan token muncul di log"
            );
        }
    }
}
