//! Pembungkus render Inertia (veer). Handler memakai fungsi di sini, bukan builder veer langsung.

use axum::body::Body;
use axum::extract::Request;
use axum::http::{HeaderMap, HeaderName, HeaderValue, StatusCode, header};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use serde::Serialize;
use std::collections::HashMap;
use std::sync::{Arc, Mutex, MutexGuard};
use whisker_core::error::ValidationErrors;

/// Extractor konteks Inertia per request (veer). Butuh `veer::InertiaLayer` di router.
pub type InertiaCtx = veer::Inertia;

/// Render page Inertia berstatus `200`.
pub fn render_page<P: Serialize>(ctx: InertiaCtx, component: &'static str, props: P) -> Response {
    ctx.render(component, props).into_response()
}

/// Render page Inertia `200` dengan `encryptHistory: true` (props sensitif, mis. token polos
/// sekali tampil: riwayat browser tak menyimpannya dalam bentuk terbaca).
pub fn render_page_encrypted<P: Serialize>(
    ctx: InertiaCtx,
    component: &'static str,
    props: P,
) -> Response {
    ctx.render(component, props)
        .encrypt_history()
        .into_response()
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
///
/// `page_url` = URL page GET tempat form berada (mis. `/account/security` untuk
/// `PUT /account/security/password`), dilaporkan sebagai `url` page Inertia agar browser tidak
/// mendarat di path request. `None` = path request (benar bila form dikirim ke path page-nya
/// sendiri, mis. `POST /login`).
pub fn render_validation<P: Serialize>(
    ctx: InertiaCtx,
    page_url: Option<&str>,
    component: &'static str,
    props: P,
    errors: ValidationErrors,
) -> Response {
    render_errors_status(
        ctx,
        page_url,
        StatusCode::UNPROCESSABLE_ENTITY,
        component,
        props,
        errors,
    )
}

/// Render page form dengan prop `errors` dan status tertentu (mis. `429`). `page_url`: lihat
/// [`render_validation`].
pub fn render_errors_status<P: Serialize>(
    ctx: InertiaCtx,
    page_url: Option<&str>,
    status: StatusCode,
    component: &'static str,
    props: P,
    errors: ValidationErrors,
) -> Response {
    if let Some(url) = page_url {
        match ctx.request().extension::<ResponseHeaders>() {
            Some(slot) => slot.set_page_url(url),
            None => tracing::warn!("render: slot ResponseHeaders tak ada; url page tidak diganti"),
        }
    }
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

/// Header tambahan (dan `url` page pengganti) untuk respons page Inertia. `InertiaLayer`
/// membangun ulang respons page, sehingga header dari handler hilang, dan `url` page selalu path
/// request (veer tak punya override); handler menaruhnya di slot ini (extension request) dan
/// middleware [`response_headers`] di luar `InertiaLayer` menerapkannya ke respons akhir.
#[derive(Clone, Default)]
pub struct ResponseHeaders(Arc<Mutex<ResponseExtras>>);

#[derive(Default)]
struct ResponseExtras {
    headers: HeaderMap,
    page_url: Option<String>,
}

impl ResponseHeaders {
    pub fn insert(&self, name: HeaderName, value: HeaderValue) {
        self.lock().headers.insert(name, value);
    }

    /// Ganti `url` page Inertia (respons JSON `X-Inertia: true`) dengan `url`.
    pub fn set_page_url(&self, url: &str) {
        self.lock().page_url = Some(url.to_owned());
    }

    fn lock(&self) -> MutexGuard<'_, ResponseExtras> {
        self.0.lock().unwrap_or_else(|e| e.into_inner())
    }
}

/// Batas body page yang ditulis ulang `url`-nya (jauh di atas ukuran page form).
const PAGE_REWRITE_LIMIT: usize = 4 * 1024 * 1024;

/// Pasang slot [`ResponseHeaders`] lalu terapkan isinya ke respons.
pub async fn response_headers(mut req: Request, next: Next) -> Response {
    let slot = ResponseHeaders::default();
    req.extensions_mut().insert(slot.clone());
    let mut resp = next.run(req).await;
    let extras = std::mem::take(&mut *slot.lock());
    resp.headers_mut().extend(extras.headers);
    match extras.page_url {
        Some(url) => rewrite_page_url(resp, &url).await,
        None => resp,
    }
}

/// Tulis ulang `url` page object pada respons Inertia JSON. Respons lain (HTML kunjungan pertama,
/// redirect) dibiarkan: form Inertia selalu dikirim sebagai XHR `X-Inertia`.
async fn rewrite_page_url(resp: Response, url: &str) -> Response {
    if resp.headers().get("x-inertia").is_none_or(|v| v != "true") {
        return resp;
    }
    let (mut parts, body) = resp.into_parts();
    let bytes = match axum::body::to_bytes(body, PAGE_REWRITE_LIMIT).await {
        Ok(bytes) => bytes,
        Err(e) => {
            tracing::error!(error = %e, "render: baca body page gagal");
            return internal_error();
        }
    };
    let mut page: serde_json::Value = match serde_json::from_slice(&bytes) {
        Ok(page) => page,
        Err(_) => return Response::from_parts(parts, Body::from(bytes)),
    };
    let Some(obj) = page.as_object_mut() else {
        return Response::from_parts(parts, Body::from(bytes));
    };
    obj.insert("url".into(), url.into());
    let body = serde_json::to_vec(&page).unwrap_or_else(|_| bytes.to_vec());
    parts
        .headers
        .insert(header::CONTENT_LENGTH, HeaderValue::from(body.len()));
    Response::from_parts(parts, Body::from(body))
}
