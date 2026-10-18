//! Lapisan web Whisker: render Inertia (veer), sesi cookie, throttle login, guard, dan router page.

pub mod client_ip;
pub mod guard;
pub mod page;
pub mod props;
pub mod routes;
pub mod session;
pub mod spike;
pub mod throttle;

use axum::Router;
use axum::extract::DefaultBodyLimit;
use axum::middleware::{from_fn, from_fn_with_state};
use ipnet::IpNet;
use sqlx::PgPool;
use std::sync::Arc;
use throttle::LoginThrottle;
use url::Url;
use veer::{CsrfLayer, InertiaConfig, InertiaLayer};

use crate::props::SharedProps;
use crate::session::CurrentSession;

/// Batas body request rute web (64 KiB). Form web Plan 02 (login, profil, password, token, project)
/// jauh di bawah ini; sekaligus membatasi panjang password sebelum sampai ke Argon2.
pub const WEB_BODY_LIMIT: usize = 64 * 1024;

/// Konfigurasi lapisan web (dipetakan dari `Config` crate `whisker`).
#[derive(Clone)]
pub struct WebConfig {
    /// Atribut `Secure` cookie sesi + `XSRF-TOKEN` (`WHISKER_COOKIE_SECURE`, default `true`).
    pub cookie_secure: bool,
    pub public_url: Url,
    /// Proxy yang `X-Forwarded-For`-nya dipercaya (`WHISKER_TRUSTED_PROXIES`; kosong = tak ada).
    pub trusted_proxies: Vec<IpNet>,
    /// Secret HMAC token CSRF `veer`, minimal 32 byte.
    pub csrf_secret: Vec<u8>,
}

impl std::fmt::Debug for WebConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("WebConfig")
            .field("cookie_secure", &self.cookie_secure)
            .field("public_url", &self.public_url.as_str())
            .field("trusted_proxies", &self.trusted_proxies)
            .field("csrf_secret", &"***")
            .finish()
    }
}

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub config: Arc<WebConfig>,
    pub throttle: Arc<LoginThrottle>,
}

impl AppState {
    /// State dengan throttle standar (5 gagal / 15 menit).
    pub fn new(pool: PgPool, config: WebConfig) -> Self {
        Self {
            pool,
            config: Arc::new(config),
            throttle: Arc::new(LoginThrottle::standard()),
        }
    }
}

/// Router page web. Urutan lapisan (luar → dalam): `CsrfLayer` (sekali, ruling K15) → batas body →
/// sesi → guard `must_change_password` → slot header → `InertiaLayer` (+ shared props) → rute dan
/// fallback `Errors/NotFound` (ruling K12; guard ikut membungkus fallback).
pub fn web_router(state: AppState, inertia: InertiaConfig) -> Router {
    let inertia = inertia.share(|req| {
        let shared = SharedProps::from_session(req.extension::<CurrentSession>());
        async move { shared }
    });
    let csrf = CsrfLayer::new(state.config.csrf_secret.clone()).secure(state.config.cookie_secure);
    routes::router()
        .layer(InertiaLayer::new(inertia))
        .layer(from_fn(page::response_headers))
        .layer(from_fn(guard::must_change_password_guard))
        .layer(from_fn_with_state(
            state.clone(),
            session::session_middleware,
        ))
        .layer(DefaultBodyLimit::max(WEB_BODY_LIMIT))
        .layer(csrf)
        .with_state(state)
}
