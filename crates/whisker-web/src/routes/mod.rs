//! Rute page web (di balik sesi, guard, CSRF — dirakit `web_router`).

pub mod account;
pub mod account_security;
pub mod auth;
pub mod errors;
pub mod home;

use axum::Router;
use axum::routing::{get, post, put};

use crate::AppState;
use crate::guard::{PASSWORD_PATH, SECURITY_PATH};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(home::index))
        .route("/login", get(auth::login_page).post(auth::login))
        .route("/logout", post(auth::logout))
        .route("/account", get(account::index))
        .route(SECURITY_PATH, get(account_security::show))
        .route(PASSWORD_PATH, put(account_security::update_password))
        .fallback(errors::not_found)
}
