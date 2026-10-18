//! Aset frontend ter-embed di binary (veer `embed` + rust-embed), disajikan di `/build/*`.

use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use http_body_util::BodyExt;
use std::collections::HashMap;
use tower::ServiceExt;
use whisker::config::Config;

/// App lengkap dengan pool lazy: `GET /login` tanpa cookie sesi tidak menyentuh DB.
fn app_with(vite_dev_server: Option<&str>) -> Router {
    let mut env: HashMap<String, String> = HashMap::new();
    env.insert(
        "DATABASE_URL".into(),
        "postgres://localhost/tidak-dipakai".into(),
    );
    env.insert("WHISKER_PUBLIC_URL".into(), "http://localhost:8080".into());
    if let Some(url) = vite_dev_server {
        env.insert("WHISKER_VITE_DEV_SERVER".into(), url.into());
    }
    let config = Config::from_env(&env).unwrap();
    let pool = sqlx::PgPool::connect_lazy(&config.database_url).unwrap();
    whisker::app::compose_app(pool, &config, vec![9u8; 32]).expect("manifest Vite ter-embed")
}

fn app() -> Router {
    app_with(None)
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
    let index = get(&app, "/login").await;
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
    let html = body_string(get(&app(), "/login").await).await;
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
    let app = app_with(Some("http://localhost:5173"));
    let html = body_string(get(&app, "/login").await).await;
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
