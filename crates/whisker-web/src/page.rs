//! Pembungkus render Inertia (veer). Handler memakai fungsi di sini, bukan builder veer langsung.

use axum::extract::Request;
use axum::http::{HeaderMap, HeaderName, HeaderValue, StatusCode, header};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use serde::Serialize;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
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
    render_errors_status(
        ctx,
        StatusCode::UNPROCESSABLE_ENTITY,
        component,
        props,
        errors,
    )
}

/// Render page form dengan prop `errors` dan status tertentu (mis. `429`).
pub fn render_errors_status<P: Serialize>(
    ctx: InertiaCtx,
    status: StatusCode,
    component: &'static str,
    props: P,
    errors: ValidationErrors,
) -> Response {
    let errors: HashMap<String, String> = errors.into_map().into_iter().collect();
    ctx.render(component, props)
        .with_errors(errors)
        .status(status)
        .into_response()
}

/// `500` generik. Detail error (sqlx/internal) hanya ke log, tak pernah ke klien.
pub fn internal_error() -> Response {
    (
        StatusCode::INTERNAL_SERVER_ERROR,
        [(header::CONTENT_TYPE, "text/plain; charset=utf-8")],
        "Terjadi kesalahan pada server.",
    )
        .into_response()
}

/// Header tambahan untuk respons page Inertia. `InertiaLayer` membangun ulang respons page,
/// sehingga header dari handler hilang; handler menaruhnya di slot ini (extension request) dan
/// middleware [`response_headers`] di luar `InertiaLayer` menyalinnya ke respons akhir.
#[derive(Clone, Default)]
pub struct ResponseHeaders(Arc<Mutex<HeaderMap>>);

impl ResponseHeaders {
    pub fn insert(&self, name: HeaderName, value: HeaderValue) {
        self.0
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .insert(name, value);
    }
}

/// Pasang slot [`ResponseHeaders`] lalu salin isinya ke respons.
pub async fn response_headers(mut req: Request, next: Next) -> Response {
    let slot = ResponseHeaders::default();
    req.extensions_mut().insert(slot.clone());
    let mut resp = next.run(req).await;
    let extra = std::mem::take(&mut *slot.0.lock().unwrap_or_else(|e| e.into_inner()));
    resp.headers_mut().extend(extra);
    resp
}
