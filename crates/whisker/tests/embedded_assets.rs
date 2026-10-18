//! Aset frontend ter-embed di binary (veer `embed` + rust-embed), disajikan di `/build/*`.

use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use http_body_util::BodyExt;
use tower::ServiceExt;

fn app() -> Router {
    let cfg = whisker::app::inertia_config(None).expect("manifest Vite ter-embed");
    let web = whisker_web::spike::router(cfg, vec![9u8; 32], false);
    whisker::app::build_app(web, Router::new())
}

async fn get(app: &Router, uri: &str) -> axum::response::Response {
    app.clone()
        .oneshot(Request::get(uri).body(Body::empty()).unwrap())
        .await
        .unwrap()
}

async fn body_string(resp: axum::response::Response) -> String {
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    String::from_utf8_lossy(&bytes).into_owned()
}

/// `src="/build/<hash>.js"` pertama di HTML root.
fn entry_script(html: &str) -> String {
    let start = html
        .find(r#"<script type="module" src="/build/"#)
        .expect("HTML root menautkan entri JS di /build/")
        + r#"<script type="module" src=""#.len();
    let end = html[start..].find('"').unwrap() + start;
    html[start..end].to_owned()
}

#[tokio::test]
async fn serves_index_and_hashed_asset_from_embed() {
    let app = app();
    let index = get(&app, "/").await;
    assert_eq!(index.status(), StatusCode::OK);
    let html = body_string(index).await;
    let js = entry_script(&html);
    assert!(js.ends_with(".js"), "entri: {js}");

    let asset = get(&app, &js).await;
    assert_eq!(asset.status(), StatusCode::OK);
    assert_eq!(asset.headers()[header::CONTENT_TYPE], "text/javascript");
    assert!(!body_string(asset).await.is_empty());

    // Manifest Vite tidak ikut disajikan; path di luar /build/ bukan aset.
    assert_eq!(
        get(&app, "/build/.vite/manifest.json").await.status(),
        StatusCode::NOT_FOUND
    );
    assert_eq!(
        get(&app, "/build/tidak-ada.js").await.status(),
        StatusCode::NOT_FOUND
    );
}

#[tokio::test]
async fn root_html_has_theme_script_viewport_fit_and_favicon() {
    let html = body_string(get(&app(), "/").await).await;
    assert!(html.contains("viewport-fit=cover"), "{html}");
    assert_eq!(
        html.matches(r#"name="viewport""#).count(),
        1,
        "hanya satu meta viewport: {html}"
    );
    assert!(html.contains(r#"<link rel="icon""#), "{html}");
    assert!(
        html.contains("prefers-color-scheme"),
        "skrip tema inline: {html}"
    );
}

#[tokio::test]
async fn dev_mode_points_scripts_at_vite_dev_server() {
    let cfg = whisker::app::inertia_config(Some("http://localhost:5173")).unwrap();
    let web = whisker_web::spike::router(cfg, vec![9u8; 32], false);
    let app = whisker::app::build_app(web, Router::new());
    let html = body_string(get(&app, "/").await).await;
    assert!(
        html.contains(r#"src="http://localhost:5173/@vite/client""#),
        "{html}"
    );
    assert!(
        html.contains(r#"src="http://localhost:5173/src/app.tsx""#),
        "{html}"
    );
    assert!(!html.contains(r#"src="/build/"#), "{html}");
}
