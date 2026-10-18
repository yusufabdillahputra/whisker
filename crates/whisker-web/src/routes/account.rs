//! `GET /account` → `302 /account/profile` .

use axum::http::Method;
use axum::response::Response;

use crate::guard::{CurrentUser, redirect};

pub const PROFILE_PATH: &str = "/account/profile";

pub async fn index(CurrentUser(_session): CurrentUser) -> Response {
    redirect(&Method::GET, PROFILE_PATH)
}
