//! `GET /health`: DB terjangkau + versi migration terbaru. Dipakai `whisker healthcheck`
//! (HEALTHCHECK container) dan pemantauan.

use crate::startup::latest_migration_version;
use axum::extract::State;
use axum::http::StatusCode;
use axum::routing::get;
use axum::{Json, Router};
use serde::Serialize;
use sqlx::PgPool;
use std::time::Duration;

/// Batas waktu cek DB: pool sqlx mengulang koneksi yang ditolak sampai `acquire_timeout`,
/// sedangkan `/health` harus menjawab cepat.
const DB_CHECK_TIMEOUT: Duration = Duration::from_secs(3);

#[derive(Debug, Serialize)]
struct Health {
    status: &'static str,
    database: &'static str,
    migration: Option<i64>,
}

pub fn health_router(pool: PgPool) -> Router {
    Router::new().route("/health", get(health)).with_state(pool)
}

async fn health(State(pool): State<PgPool>) -> (StatusCode, Json<Health>) {
    match tokio::time::timeout(DB_CHECK_TIMEOUT, latest_migration_version(&pool)).await {
        Ok(Ok(migration)) => (
            StatusCode::OK,
            Json(Health {
                status: "ok",
                database: "ok",
                migration,
            }),
        ),
        result => {
            match result {
                Ok(Err(e)) => tracing::warn!(error = %e, "health: database gagal"),
                _ => tracing::warn!("health: database tidak menjawab dalam {DB_CHECK_TIMEOUT:?}"),
            }
            (
                StatusCode::SERVICE_UNAVAILABLE,
                Json(Health {
                    status: "error",
                    database: "unreachable",
                    migration: None,
                }),
            )
        }
    }
}
