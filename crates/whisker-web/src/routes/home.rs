//! `GET /` sementara → `Projects/Index` (menggantikan spike, ruling K3; dilengkapi Task 17).

use axum::response::Response;

use crate::guard::CurrentUser;
use crate::page::{InertiaCtx, render_page};
use crate::props::ProjectsIndexProps;

pub async fn index(ctx: InertiaCtx, CurrentUser(_session): CurrentUser) -> Response {
    render_page(ctx, "Projects/Index", ProjectsIndexProps::default())
}
