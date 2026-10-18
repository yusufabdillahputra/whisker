//! Page error: `Errors/NotFound` (fallback, ruling K12) dan `Errors/Forbidden`.

use axum::http::StatusCode;
use axum::response::Response;

use crate::page::{InertiaCtx, render_page_status};
use crate::props::ErrorPageProps;

pub const NOT_FOUND_PAGE: &str = "Errors/NotFound";
pub const FORBIDDEN_PAGE: &str = "Errors/Forbidden";

/// Fallback `web_router`: path non-aset yang tak dikenal → `404` `Errors/NotFound`.
pub async fn not_found(ctx: InertiaCtx) -> Response {
    error_page(ctx, StatusCode::NOT_FOUND, NOT_FOUND_PAGE)
}

/// `403` `Errors/Forbidden`.
pub fn forbidden(ctx: InertiaCtx) -> Response {
    error_page(ctx, StatusCode::FORBIDDEN, FORBIDDEN_PAGE)
}

fn error_page(ctx: InertiaCtx, status: StatusCode, component: &'static str) -> Response {
    let props = ErrorPageProps {
        status: status.as_u16(),
    };
    render_page_status(ctx, status, component, props)
}
