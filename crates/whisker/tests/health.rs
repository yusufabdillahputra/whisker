//! `GET /health`: status DB + versi migration terbaru (Infra-1 bagian app).

use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use http_body_util::BodyExt;
use serde_json::{Value, json};
use sqlx::PgPool;
use sqlx::postgres::PgPoolOptions;
use std::time::Duration;
use tower::ServiceExt;
use whisker::health::health_router;
use whisker::startup::MIGRATOR;

async fn get_health(pool: PgPool) -> (StatusCode, Option<String>, Value) {
    let resp = health_router(pool)
        .oneshot(Request::get("/health").body(Body::empty()).unwrap())
        .await
        .unwrap();
    let status = resp.status();
    let ctype = resp
        .headers()
        .get(header::CONTENT_TYPE)
        .map(|v| v.to_str().unwrap().to_owned());
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    (status, ctype, serde_json::from_slice(&bytes).unwrap())
}

/// Port TCP lokal yang (hampir pasti) tertutup: diikat lalu dilepas.
async fn closed_port() -> u16 {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    listener.local_addr().unwrap().port()
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn health_ok_reports_latest_migration_version(pool: PgPool) {
    let latest = MIGRATOR.iter().map(|m| m.version).max().unwrap();
    let (status, ctype, body) = get_health(pool).await;
    assert_eq!(status, StatusCode::OK);
    assert_eq!(ctype.as_deref(), Some("application/json"));
    assert_eq!(
        body,
        json!({"status": "ok", "database": "ok", "migration": latest})
    );
}

#[tokio::test]
async fn health_returns_503_when_db_unreachable() {
    let url = format!(
        "postgres://whisker:x@127.0.0.1:{}/none",
        closed_port().await
    );
    let pool = PgPoolOptions::new()
        .acquire_timeout(Duration::from_millis(500))
        .connect_lazy(&url)
        .unwrap();
    let (status, ctype, body) = get_health(pool).await;
    assert_eq!(status, StatusCode::SERVICE_UNAVAILABLE);
    assert_eq!(ctype.as_deref(), Some("application/json"));
    assert_eq!(
        body,
        json!({"status": "error", "database": "unreachable", "migration": null})
    );
}
