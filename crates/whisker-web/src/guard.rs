//! Guard dan extractor akses: `CurrentUser` (wajib login), `RequireAdmin` (admin saja, `403`),
//! `must_change_password_guard` (allowlist persis selama `must_change_password`).

use axum::extract::{FromRequestParts, Request};
use axum::http::request::Parts;
use axum::http::{Method, StatusCode, header};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};
use whisker_core::user::Role;

use crate::page::InertiaCtx;
use crate::routes::errors::forbidden;
use crate::session::CurrentSession;

pub const LOGIN_PATH: &str = "/login";
pub const SECURITY_PATH: &str = "/account/security";
pub const PASSWORD_PATH: &str = "/account/security/password";

/// Redirect: `302` untuk GET/HEAD, `303` untuk method lain (Inertia mengikuti dengan GET).
pub fn redirect(method: &Method, to: &str) -> Response {
    let status = if matches!(*method, Method::GET | Method::HEAD) {
        StatusCode::FOUND
    } else {
        StatusCode::SEE_OTHER
    };
    (status, [(header::LOCATION, to.to_owned())]).into_response()
}

/// Sesi wajib; tanpa sesi → redirect `/login`.
#[derive(Debug, Clone)]
pub struct CurrentUser(pub CurrentSession);

impl<S: Send + Sync> FromRequestParts<S> for CurrentUser {
    type Rejection = Response;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        parts
            .extensions
            .get::<CurrentSession>()
            .cloned()
            .map(CurrentUser)
            .ok_or_else(|| redirect(&parts.method, LOGIN_PATH))
    }
}

/// Admin saja: tanpa sesi → `/login`; bukan admin → `403` page `Errors/Forbidden`.
#[derive(Debug, Clone)]
pub struct RequireAdmin(pub CurrentSession);

impl<S: Send + Sync> FromRequestParts<S> for RequireAdmin {
    type Rejection = Response;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let CurrentUser(session) = CurrentUser::from_request_parts(parts, state).await?;
        if session.user.role == Role::Admin {
            return Ok(RequireAdmin(session));
        }
        let ctx = InertiaCtx::from_request_parts(parts, state)
            .await
            .map_err(IntoResponse::into_response)?;
        Err(forbidden(ctx))
    }
}

/// Selama `must_change_password`, hanya `GET`/`HEAD /account/security`,
/// `PUT /account/security/password`, dan `POST /logout` yang lolos; selain itu → redirect
/// `/account/security`.
pub async fn must_change_password_guard(req: Request, next: Next) -> Response {
    let must_change = req
        .extensions()
        .get::<CurrentSession>()
        .is_some_and(|s| s.user.must_change_password);
    if must_change && !allowed_while_must_change(req.method(), req.uri().path()) {
        return redirect(req.method(), SECURITY_PATH);
    }
    next.run(req).await
}

fn allowed_while_must_change(method: &Method, path: &str) -> bool {
    matches!(
        (method, path),
        (&Method::GET | &Method::HEAD, SECURITY_PATH)
            | (&Method::PUT, PASSWORD_PATH)
            | (&Method::POST, "/logout")
    )
}
