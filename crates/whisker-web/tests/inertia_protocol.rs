//! Protokol Inertia (veer, ADR-001) lewat router Axum nyata: kunjungan page lewat `GET /login`
//! `web_router`. Router spike dihapus di Task 11 (ruling K3, K15); CSRF dan validasi 422 diuji di
//! `csrf.rs` dan `auth_flow.rs`.

use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use axum::routing::get;
use http_body_util::BodyExt;
use serde_json::Value;
use tower::ServiceExt;
use veer::{InertiaConfig, MinimalRootView};
use whisker_web::page::{InertiaCtx, render_page};

const VERSION: &str = "test-v1";
const SECRET: [u8; 32] = [7u8; 32];

fn cfg() -> InertiaConfig {
    InertiaConfig::new()
        .root_view(MinimalRootView::new().title("Whisker"))
        .version_str(VERSION)
}

/// `web_router` dengan pool lazy: `GET /login` tanpa cookie sesi tidak menyentuh DB.
fn web_app() -> Router {
    let state = whisker_web::AppState::new(
        sqlx::PgPool::connect_lazy("postgres://localhost/tidak-dipakai").unwrap(),
        whisker_web::WebConfig {
            cookie_secure: false,
            public_url: url::Url::parse("http://localhost:8080").unwrap(),
            trusted_proxies: Vec::new(),
            csrf_secret: SECRET.to_vec(),
        },
    );
    whisker_web::web_router(state, cfg())
}

async fn body_string(resp: axum::response::Response) -> String {
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    String::from_utf8(bytes.to_vec()).unwrap()
}

async fn body_json(resp: axum::response::Response) -> Value {
    serde_json::from_str(&body_string(resp).await).unwrap()
}

fn inertia_get(uri: &str) -> Request<Body> {
    Request::get(uri)
        .header("X-Inertia", "true")
        .header("X-Inertia-Version", VERSION)
        .body(Body::empty())
        .unwrap()
}

#[tokio::test]
async fn initial_visit_returns_html_with_page_json() {
    let resp = web_app()
        .oneshot(Request::get("/login").body(Body::empty()).unwrap())
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let ct = resp.headers()[header::CONTENT_TYPE].to_str().unwrap();
    assert!(ct.starts_with("text/html"), "content-type: {ct}");
    let html = body_string(resp).await;
    let open = r#"<script data-page="app" type="application/json">"#;
    let start = html.find(open).unwrap_or_else(|| panic!("{html}")) + open.len();
    let end = html[start..].find("</script>").unwrap() + start;
    // veer meng-escape `/` jadi `\/` di dalam <script>; tetap JSON valid.
    let page: Value = serde_json::from_str(&html[start..end]).unwrap();
    assert_eq!(page["component"], "Auth/Login");
    assert_eq!(page["url"], "/login");
    assert_eq!(page["version"], VERSION);
    assert!(html.contains(r#"<div id="app"></div>"#), "{html}");
}

#[tokio::test]
async fn inertia_visit_returns_json_page_object() {
    let resp = web_app().oneshot(inertia_get("/login")).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    assert_eq!(resp.headers()["x-inertia"], "true");
    let page = body_json(resp).await;
    assert_eq!(page["component"], "Auth/Login");
    assert_eq!(page["props"]["auth"], Value::Null);
    assert_eq!(page["url"], "/login");
    assert_eq!(page["version"], VERSION);
}

#[tokio::test]
async fn version_mismatch_returns_409_with_location() {
    let req = Request::get("/login")
        .header("X-Inertia", "true")
        .header("X-Inertia-Version", "versi-lama")
        .body(Body::empty())
        .unwrap();
    let resp = web_app().oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::CONFLICT);
    let location = resp.headers()["x-inertia-location"].to_str().unwrap();
    assert!(
        location.ends_with("/login"),
        "X-Inertia-Location: {location}"
    );
}

#[tokio::test]
async fn spike_routes_removed() {
    for path in ["/spike/forbidden", "/spike/echo"] {
        let resp = web_app().oneshot(inertia_get(path)).await.unwrap();
        assert_eq!(resp.status(), StatusCode::NOT_FOUND, "{path}");
        let page = body_json(resp).await;
        assert_eq!(page["component"], "Errors/NotFound");
    }
}

#[tokio::test]
async fn page_with_status_403_keeps_inertia_payload() {
    let app = Router::new()
        .route(
            "/terlarang",
            get(|ctx: InertiaCtx| async move { whisker_web::routes::errors::forbidden(ctx) }),
        )
        .layer(veer::InertiaLayer::new(cfg()));
    let resp = app.oneshot(inertia_get("/terlarang")).await.unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
    assert_eq!(resp.headers()["x-inertia"], "true");
    let page = body_json(resp).await;
    assert_eq!(page["component"], "Errors/Forbidden");
    assert_eq!(page["props"]["status"], 403);
    assert_eq!(page["url"], "/terlarang");
}

// --- Mekanisme veer tambahan (bukti spike butir i, j). ---

#[tokio::test]
async fn shared_props_are_resolved_per_request() {
    let cfg = InertiaConfig::new()
        .root_view(MinimalRootView::new())
        .version_str(VERSION)
        .share(|req| {
            let url = req.url.clone();
            async move { serde_json::json!({ "requestUrl": url }) }
        });
    let app = Router::new()
        .route(
            "/a",
            get(|ctx: InertiaCtx| async move {
                render_page(ctx, "Test/Page", serde_json::json!({ "message": "a" }))
            }),
        )
        .layer(veer::InertiaLayer::new(cfg));
    let page = body_json(app.oneshot(inertia_get("/a?x=1")).await.unwrap()).await;
    assert_eq!(page["props"]["requestUrl"], "/a?x=1");
    assert_eq!(page["props"]["message"], "a");
}

#[tokio::test]
async fn history_encryption_can_be_enabled_per_response() {
    let cfg = InertiaConfig::new()
        .root_view(MinimalRootView::new())
        .version_str(VERSION);
    let app = Router::new()
        .route(
            "/plain",
            get(|ctx: InertiaCtx| async move {
                render_page(ctx, "Test/Page", serde_json::json!({ "message": "p" }))
            }),
        )
        .route(
            "/secret",
            get(|ctx: InertiaCtx| async move {
                ctx.render("Test/Page", serde_json::json!({ "message": "s" }))
                    .encrypt_history()
            }),
        )
        .layer(veer::InertiaLayer::new(cfg));
    let plain = body_json(app.clone().oneshot(inertia_get("/plain")).await.unwrap()).await;
    let secret = body_json(app.oneshot(inertia_get("/secret")).await.unwrap()).await;
    assert_ne!(plain["encryptHistory"], true);
    assert_eq!(secret["encryptHistory"], true);
}
