//! `GET /account/profile` (page `Account/Profile`) dan `PUT /account/profile`.

use axum::extract::State;
use axum::http::Method;
use axum::response::Response;
use serde::Deserialize;
use ts_rs::TS;
use veer::InertiaForm;
use whisker_core::error::CoreError;
use whisker_core::user::update_profile;

use crate::AppState;
use crate::guard::{CurrentUser, LOGIN_PATH, redirect};
use crate::page::{InertiaCtx, internal_error, render_page, render_validation};
use crate::props::AccountProfileProps;
use crate::routes::account::PROFILE_PATH;

pub const PROFILE_PAGE: &str = "Account/Profile";

/// Form profil. Field `email` (bila dikirim) diabaikan; field hilang = string kosong → `422`.
#[derive(Debug, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct ProfileForm {
    #[serde(default)]
    pub display_name: String,
    #[serde(default)]
    pub avatar_key: String,
}

/// `GET /account/profile`: tanpa sesi → `/login`.
pub async fn show(ctx: InertiaCtx, CurrentUser(_session): CurrentUser) -> Response {
    render_page(ctx, PROFILE_PAGE, AccountProfileProps::new())
}

/// `PUT /account/profile`: sukses → `303 /account/profile`; gagal → `422` per field
/// (`displayName`, `avatarKey`), URL page tetap `/account/profile`.
pub async fn update(
    State(state): State<AppState>,
    CurrentUser(session): CurrentUser,
    ctx: InertiaCtx,
    InertiaForm(form): InertiaForm<ProfileForm>,
) -> Response {
    match update_profile(
        &state.pool,
        session.user.id,
        &form.display_name,
        &form.avatar_key,
    )
    .await
    {
        Ok(_) => redirect(&Method::PUT, PROFILE_PATH),
        Err(CoreError::Validation(errors)) => render_validation(
            ctx,
            Some(PROFILE_PATH),
            PROFILE_PAGE,
            AccountProfileProps::new(),
            errors,
        ),
        // User dinonaktifkan bersamaan: sesi tak lagi berlaku.
        Err(CoreError::NotFound) => redirect(&Method::PUT, LOGIN_PATH),
        Err(e) => {
            tracing::error!(error = %e, "ubah profil gagal");
            internal_error()
        }
    }
}
