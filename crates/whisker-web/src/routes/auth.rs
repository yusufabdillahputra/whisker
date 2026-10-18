//! `GET /login`, `POST /login`, `POST /logout`.

use std::time::{Duration, Instant};

use axum::Extension;
use axum::extract::State;
use axum::http::header::RETRY_AFTER;
use axum::http::{HeaderValue, Method, StatusCode};
use axum::response::Response;
use serde::Deserialize;
use veer::InertiaForm;
use whisker_core::auth::password::verify_password_blocking;
use whisker_core::error::ValidationErrors;
use whisker_core::session::{create_login_session, delete_session};
use whisker_core::user::find_auth_by_email;

use crate::AppState;
use crate::client_ip::ClientIp;
use crate::guard::{SECURITY_PATH, redirect};
use crate::page::{InertiaCtx, ResponseHeaders, internal_error, render_errors_status, render_page};
use crate::props::LoginPageProps;
use crate::session::{CurrentSession, append_cookie, removal_cookie, session_cookie};
use crate::throttle::{ThrottleDecision, ThrottleKey};

pub const LOGIN_PAGE: &str = "Auth/Login";
/// Pesan sama untuk semua penyebab gagal login (B4).
pub const LOGIN_FAILED: &str = "email atau password salah";
pub const LOGIN_THROTTLED: &str = "Terlalu banyak percobaan. Coba lagi nanti.";

/// Form login. Field hilang = string kosong (tetap jalur gagal generik). `Debug` tanpa password.
#[derive(Deserialize)]
pub struct LoginForm {
    #[serde(default)]
    pub email: String,
    #[serde(default)]
    pub password: String,
}

impl std::fmt::Debug for LoginForm {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("LoginForm")
            .field("email", &self.email)
            .field("password", &"***")
            .finish()
    }
}

/// `GET /login`: tamu → `Auth/Login`; sudah login → `302 /`.
pub async fn login_page(ctx: InertiaCtx, session: Option<Extension<CurrentSession>>) -> Response {
    if session.is_some() {
        return redirect(&Method::GET, "/");
    }
    render_page(ctx, LOGIN_PAGE, LoginPageProps {})
}

/// `POST /login`: throttle dicek sebelum Argon2; hanya kegagalan yang dicatat.
pub async fn login(
    State(state): State<AppState>,
    ClientIp(ip): ClientIp,
    previous: Option<Extension<CurrentSession>>,
    Extension(extra): Extension<ResponseHeaders>,
    ctx: InertiaCtx,
    InertiaForm(form): InertiaForm<LoginForm>,
) -> Response {
    let key = ThrottleKey::new(&form.email, ip);
    if let ThrottleDecision::Limited { retry_after } = state.throttle.check(&key, Instant::now()) {
        extra.insert(
            RETRY_AFTER,
            HeaderValue::from(retry_after_secs(retry_after)),
        );
        return form_error(ctx, StatusCode::TOO_MANY_REQUESTS, LOGIN_THROTTLED);
    }

    let record = match find_auth_by_email(&state.pool, &form.email).await {
        Ok(record) => record,
        Err(e) => {
            tracing::error!(error = %e, "login: baca user gagal");
            return internal_error();
        }
    };
    // User tak ada → hash dummy (waktu sama); user nonaktif tetap diverifikasi lalu ditolak.
    let verified = verify_password_blocking(
        form.password,
        record.as_ref().map(|r| r.password_hash.clone()),
    )
    .await;
    let Some(record) = record.filter(|r| verified && !r.disabled) else {
        state.throttle.record_failure(&key, Instant::now());
        return form_error(ctx, StatusCode::UNPROCESSABLE_ENTITY, LOGIN_FAILED);
    };

    // Hash dicek ulang di dalam transaksi INSERT sesi (TOCTOU vs ganti password bersamaan).
    let sid = match create_login_session(&state.pool, record.user_id, &record.password_hash).await {
        Ok(Some(sid)) => sid,
        Ok(None) => return form_error(ctx, StatusCode::UNPROCESSABLE_ENTITY, LOGIN_FAILED),
        Err(e) => {
            tracing::error!(error = %e, "login: buat sesi gagal");
            return internal_error();
        }
    };
    if let Some(Extension(prev)) = previous
        && let Err(e) = delete_session(&state.pool, &prev.session_hash).await
    {
        tracing::warn!(error = %e, "login: hapus sesi lama gagal");
    }

    let to = if record.must_change_password {
        SECURITY_PATH
    } else {
        "/"
    };
    let mut resp = redirect(&Method::POST, to);
    append_cookie(
        resp.headers_mut(),
        &session_cookie(&sid, state.config.cookie_secure),
    );
    resp
}

/// `POST /logout`: hapus baris sesi, kirim cookie penghapus, `303 /login`.
pub async fn logout(
    State(state): State<AppState>,
    session: Option<Extension<CurrentSession>>,
) -> Response {
    if let Some(Extension(s)) = session
        && let Err(e) = delete_session(&state.pool, &s.session_hash).await
    {
        tracing::error!(error = %e, "logout: hapus sesi gagal");
        return internal_error();
    }
    let mut resp = redirect(&Method::POST, "/login");
    append_cookie(
        resp.headers_mut(),
        &removal_cookie(state.config.cookie_secure),
    );
    resp
}

fn form_error(ctx: InertiaCtx, status: StatusCode, message: &'static str) -> Response {
    let mut errors = ValidationErrors::new();
    errors.add("email", message);
    render_errors_status(ctx, status, LOGIN_PAGE, LoginPageProps {}, errors)
}

/// Detik dibulatkan ke atas, minimal 1.
fn retry_after_secs(d: Duration) -> u64 {
    (d.as_secs() + u64::from(d.subsec_nanos() > 0)).max(1)
}
