//! Rute page web (di balik sesi, guard, CSRF — dirakit `web_router`).

pub mod auth;
pub mod errors;
pub mod home;

use axum::Router;
use axum::routing::{get, post};

use crate::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(home::index))
        .route("/login", get(auth::login_page).post(auth::login))
        .route("/logout", post(auth::logout))
        .fallback(errors::not_found)
}
