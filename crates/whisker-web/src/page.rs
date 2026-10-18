//! Pembungkus render Inertia (veer). Handler memakai fungsi di sini, bukan builder veer langsung.

use axum::http::StatusCode;
use axum::response::{IntoResponse, Response};
use serde::Serialize;
use std::collections::HashMap;
use whisker_core::error::ValidationErrors;

/// Extractor konteks Inertia per request (veer). Butuh `veer::InertiaLayer` di router.
pub type InertiaCtx = veer::Inertia;

/// Render page Inertia berstatus `200`.
pub fn render_page<P: Serialize>(ctx: InertiaCtx, component: &'static str, props: P) -> Response {
    ctx.render(component, props).into_response()
}

/// Render page Inertia dengan status HTTP tertentu (mis. `403`, `404`, `429`).
pub fn render_page_status<P: Serialize>(
    ctx: InertiaCtx,
    status: StatusCode,
    component: &'static str,
    props: P,
) -> Response {
    ctx.render(component, props).status(status).into_response()
}

/// Render ulang page form berstatus `422` dengan prop `errors` (`{ field: pesan }`).
pub fn render_validation<P: Serialize>(
    ctx: InertiaCtx,
    component: &'static str,
    props: P,
    errors: ValidationErrors,
) -> Response {
    let errors: HashMap<String, String> = errors.into_map().into_iter().collect();
    ctx.render(component, props)
        .with_errors(errors)
        .status(StatusCode::UNPROCESSABLE_ENTITY)
        .into_response()
}
