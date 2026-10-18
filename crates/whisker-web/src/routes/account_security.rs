//! `GET /account/security` (page `Account/Security`) dan `PUT /account/security/password`.

use std::time::Instant;

use axum::Extension;
use axum::extract::State;
use axum::http::header::RETRY_AFTER;
use axum::http::{HeaderValue, Method, StatusCode};
use axum::response::Response;
use serde::Deserialize;
use ts_rs::TS;
use veer::InertiaForm;
use whisker_core::error::{CoreError, ValidationErrors};
use whisker_core::user::{ChangePassword, change_password};

use crate::AppState;
use crate::guard::{CurrentUser, LOGIN_PATH, SECURITY_PATH, redirect};
use crate::page::{
    InertiaCtx, ResponseHeaders, internal_error, render_errors_status, render_page,
    render_validation,
};
use crate::props::AccountSecurityProps;
use crate::routes::auth::{LOGIN_THROTTLED, retry_after_secs};
use crate::throttle::{Limited, ThrottleKey};

pub const SECURITY_PAGE: &str = "Account/Security";
/// Field form untuk error password saat ini (juga pesan throttle).
const CURRENT_PASSWORD_FIELD: &str = "currentPassword";

/// Form ganti password. Field hilang = string kosong (jalur error per field). `Debug` tanpa isi.
#[derive(Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct ChangePasswordForm {
    #[serde(default)]
    pub current_password: String,
    #[serde(default)]
    pub password: String,
    #[serde(default)]
    pub password_confirmation: String,
}

impl std::fmt::Debug for ChangePasswordForm {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("ChangePasswordForm(<redacted>)")
    }
}

impl From<ChangePasswordForm> for ChangePassword {
    fn from(f: ChangePasswordForm) -> Self {
        Self {
            current_password: f.current_password,
            new_password: f.password,
            new_password_confirmation: f.password_confirmation,
        }
    }
}

/// `GET /account/security`: tanpa sesi → `/login`.
pub async fn show(ctx: InertiaCtx, CurrentUser(session): CurrentUser) -> Response {
    let props = AccountSecurityProps {
        forced: session.user.must_change_password,
    };
    render_page(ctx, SECURITY_PAGE, props)
}

/// `PUT /account/security/password`: sukses → `303 /` bila `forced`, selain itu
/// `303 /account/security` (sesi lain dihapus, sesi ini + PAT tetap). Gagal → `422` per field.
/// Password saat ini salah dibatasi per user (5 gagal / 15 menit → `429`), dicek sebelum Argon2.
pub async fn update_password(
    State(state): State<AppState>,
    CurrentUser(session): CurrentUser,
    Extension(extra): Extension<ResponseHeaders>,
    ctx: InertiaCtx,
    InertiaForm(form): InertiaForm<ChangePasswordForm>,
) -> Response {
    let forced = session.user.must_change_password;
    let props = AccountSecurityProps { forced };

    let key = ThrottleKey::account(session.user.id);
    let attempt = match state.password_throttle.try_begin(&key, Instant::now()) {
        Ok(attempt) => attempt,
        Err(Limited { retry_after }) => {
            extra.insert(
                RETRY_AFTER,
                HeaderValue::from(retry_after_secs(retry_after)),
            );
            let mut errors = ValidationErrors::new();
            errors.add(CURRENT_PASSWORD_FIELD, LOGIN_THROTTLED);
            return render_errors_status(
                ctx,
                Some(SECURITY_PATH),
                StatusCode::TOO_MANY_REQUESTS,
                SECURITY_PAGE,
                props,
                errors,
            );
        }
    };

    match change_password(
        &state.pool,
        session.user.id,
        form.into(),
        &session.session_hash,
    )
    .await
    {
        Ok(()) => {
            attempt.succeeded();
            redirect(&Method::PUT, if forced { "/" } else { SECURITY_PATH })
        }
        Err(CoreError::Validation(errors)) => {
            if errors.contains(CURRENT_PASSWORD_FIELD) {
                drop(attempt); // kegagalan tercatat
            } else {
                attempt.abandon();
            }
            render_validation(ctx, Some(SECURITY_PATH), SECURITY_PAGE, props, errors)
        }
        // User dinonaktifkan bersamaan: sesi tak lagi berlaku.
        Err(CoreError::NotFound) => {
            attempt.abandon();
            redirect(&Method::PUT, LOGIN_PATH)
        }
        Err(e) => {
            attempt.abandon();
            tracing::error!(error = %e, "ganti password gagal");
            internal_error()
        }
    }
}
