//! Rute spike sementara (Task 01, ADR-001) — dihapus di Task 11. `GET /` sudah diganti
//! `Projects/Index` di `web_router` (Task 10, ruling K3); sisa rute di router terpisah tanpa guard.

use crate::page::{InertiaCtx, render_page, render_page_status, render_validation};
use axum::Router;
use axum::http::StatusCode;
use axum::response::Response;
use axum::routing::{get, post};
use serde::{Deserialize, Serialize};
use ts_rs::TS;
use veer::{CsrfLayer, InertiaConfig, InertiaForm, InertiaLayer};
use whisker_core::error::ValidationErrors;

const PING: &str = "Spike/Ping";

/// Props page `Spike/Ping`. Pasangan TS: `frontend/src/types/generated/PingPageProps.ts`.
#[derive(Debug, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct PingPageProps {
    pub message: String,
}
veer::register_page!(PingPageProps, "Spike/Ping");

#[derive(Debug, Deserialize)]
pub struct EchoForm {
    #[serde(default)]
    pub text: String,
}

/// Router spike: rute + `InertiaLayer` + `CsrfLayer` sendiri (paling luar, ruling K15).
/// `csrf_secret` minimal 32 byte (pakai secret yang sama dengan `web_router`);
/// `secure_cookie = false` hanya untuk HTTP lokal.
pub fn router(cfg: InertiaConfig, csrf_secret: Vec<u8>, secure_cookie: bool) -> Router {
    Router::new()
        .route("/spike/echo", post(echo))
        .route("/spike/forbidden", get(forbidden))
        .layer(InertiaLayer::new(cfg))
        .layer(CsrfLayer::new(csrf_secret).secure(secure_cookie))
}

async fn echo(ctx: InertiaCtx, InertiaForm(form): InertiaForm<EchoForm>) -> Response {
    let text = form.text.trim();
    if text.is_empty() {
        let mut errors = ValidationErrors::new();
        errors.add("text", "Teks wajib diisi.");
        let props = PingPageProps {
            message: "pong dari Axum + veer".to_owned(),
        };
        return render_validation(ctx, PING, props, errors);
    }
    let props = PingPageProps {
        message: format!("echo: {text}"),
    };
    render_page(ctx, PING, props)
}

async fn forbidden(ctx: InertiaCtx) -> Response {
    let props = PingPageProps {
        message: "akses ditolak".to_owned(),
    };
    render_page_status(ctx, StatusCode::FORBIDDEN, PING, props)
}
