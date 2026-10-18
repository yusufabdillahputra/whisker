//! Guard `must_change_password` (allowlist persis) dan extractor `RequireAdmin`.

mod common;

use axum::Router;
use axum::http::{Method, StatusCode};
use axum::middleware::from_fn_with_state;
use axum::routing::get;
use common::*;
use serde_json::json;
use sqlx::PgPool;
use veer::InertiaLayer;
use whisker_core::user::Role;
use whisker_web::AppState;
use whisker_web::guard::RequireAdmin;
use whisker_web::session::session_middleware;

async fn must_change_client(pool: &PgPool) -> Client {
    seed_user(pool, "admin@example.com", Role::Admin, true).await;
    let mut c = Client::new(app(pool.clone()));
    let r = c.login("admin@example.com", PASSWORD).await;
    assert_eq!(r.location(), Some("/account/security"));
    c
}

fn assert_to_security(r: &Resp, status: StatusCode) {
    assert_eq!(r.status, status, "{}", r.text());
    assert_eq!(r.location(), Some("/account/security"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn must_change_user_redirected_to_security_from_home(pool: PgPool) {
    let mut c = must_change_client(&pool).await;
    assert_to_security(&c.get("/").await, StatusCode::FOUND);
    assert_to_security(&c.get("/login").await, StatusCode::FOUND);
}

#[sqlx::test(migrations = "../../migrations")]
async fn must_change_user_post_elsewhere_redirected(pool: PgPool) {
    let mut c = must_change_client(&pool).await;
    assert_to_security(&c.post("/projects", json!({})).await, StatusCode::SEE_OTHER);
    assert_to_security(
        &c.send(Method::DELETE, "/logout", None, true).await,
        StatusCode::SEE_OTHER,
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn must_change_user_can_open_security(pool: PgPool) {
    let mut c = must_change_client(&pool).await;
    // Lolos guard; halaman keamanan baru ada di Task 13, jadi kini jatuh ke fallback 404.
    let r = c.get("/account/security").await;
    assert_eq!(r.status, StatusCode::NOT_FOUND);
    assert_eq!(r.json()["component"], "Errors/NotFound");
    let r = c
        .send(
            Method::PUT,
            "/account/security/password",
            Some(json!({})),
            true,
        )
        .await;
    assert!(
        r.location().is_none(),
        "PUT password lolos guard: {}",
        r.status
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn must_change_user_can_logout(pool: PgPool) {
    let mut c = must_change_client(&pool).await;
    let r = c.post("/logout", json!({})).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER);
    assert_eq!(r.location(), Some("/login"));
    assert_eq!(session_count(&pool).await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn must_change_allowlist_is_exact(pool: PgPool) {
    let mut c = must_change_client(&pool).await;
    for path in [
        "/account/security/",
        "/account/security/password",
        "/account/security/sessions",
        "/account/securityx",
        "/account",
        "/account/profile",
    ] {
        assert_to_security(&c.get(path).await, StatusCode::FOUND);
    }
    assert_to_security(
        &c.post("/account/security", json!({})).await,
        StatusCode::SEE_OTHER,
    );
    assert_to_security(
        &c.send(Method::PUT, "/account/security", Some(json!({})), true)
            .await,
        StatusCode::SEE_OTHER,
    );
    assert_to_security(
        &c.post("/account/security/password", json!({})).await,
        StatusCode::SEE_OTHER,
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn guard_wraps_not_found_fallback(pool: PgPool) {
    let mut c = must_change_client(&pool).await;
    assert_to_security(&c.get("/tidak-ada").await, StatusCode::FOUND);
}

/// Router uji: satu rute `RequireAdmin` di balik middleware sesi + `InertiaLayer` nyata.
fn admin_app(pool: PgPool) -> Router {
    let state = AppState::new(pool, web_config(Vec::new()));
    Router::new()
        .route(
            "/admin-only",
            get(|RequireAdmin(s): RequireAdmin| async move { s.user.email }),
        )
        .layer(InertiaLayer::new(inertia_config()))
        .layer(from_fn_with_state(state, session_middleware))
}

async fn session_cookie_for(pool: &PgPool, email: &str, role: Role) -> String {
    seed_user(pool, email, role, false).await;
    let mut c = Client::new(app(pool.clone()));
    c.login(email, PASSWORD).await;
    c.cookie("whisker_session").unwrap().to_owned()
}

#[sqlx::test(migrations = "../../migrations")]
async fn member_gets_403_on_require_admin_route(pool: PgPool) {
    let member = session_cookie_for(&pool, "ani@example.com", Role::Member).await;
    let admin = session_cookie_for(&pool, "admin@example.com", Role::Admin).await;
    let mut c = Client::new(admin_app(pool));

    c.jar.insert("whisker_session".into(), member);
    let r = c.get("/admin-only").await;
    assert_eq!(r.status, StatusCode::FORBIDDEN);
    let page = r.json();
    assert_eq!(page["component"], "Errors/Forbidden");
    assert_eq!(page["props"]["status"], 403);

    c.jar.insert("whisker_session".into(), admin);
    let r = c.get("/admin-only").await;
    assert_eq!(r.status, StatusCode::OK);
    assert_eq!(r.text(), "admin@example.com");

    c.jar.remove("whisker_session");
    let r = c.get("/admin-only").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
}
