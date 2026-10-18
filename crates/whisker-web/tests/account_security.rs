//! Akun: `/account` → `/account/profile`, page `Account/Security`, dan
//! `PUT /account/security/password` (ganti password + throttle) lewat `web_router` nyata.

mod common;

use axum::Router;
use axum::http::{Method, StatusCode};
use common::*;
use serde_json::{Value, json};
use sqlx::PgPool;
use whisker_core::token::{create_token, list_tokens};
use whisker_core::user::Role;

const NEW_PASSWORD: &str = "kata-sandi-baru-456";
const PASSWORD_PATH: &str = "/account/security/password";

async fn logged_in(pool: &PgPool, email: &str, must_change: bool) -> Client {
    logged_in_on(app(pool.clone()), pool, email, must_change).await
}

/// Login di router tertentu (state throttle bersama antar klien).
async fn logged_in_on(router: Router, pool: &PgPool, email: &str, must_change: bool) -> Client {
    seed_user(pool, email, Role::Member, must_change).await;
    let mut c = Client::new(router);
    let r = c.login(email, PASSWORD).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    c
}

fn change(current: &str, password: &str, confirmation: &str) -> Value {
    json!({
        "currentPassword": current,
        "password": password,
        "passwordConfirmation": confirmation,
    })
}

fn assert_security_page(r: &Resp, status: StatusCode, forced: bool) -> Value {
    assert_eq!(r.status, status, "{}", r.text());
    assert_eq!(r.headers["x-inertia"], "true");
    let page = r.json();
    assert_eq!(page["component"], "Account/Security");
    assert_eq!(page["props"]["forced"], forced);
    // URL page = page GET tempat form berada, juga untuk 422/429 dari PUT (pre-review fix).
    assert_eq!(page["url"], "/account/security");
    page
}

/// `422` dengan tepat satu error, di `field`.
fn assert_single_field_error(r: &Resp, field: &str, message: &str) {
    let page = assert_security_page(r, StatusCode::UNPROCESSABLE_ENTITY, false);
    let errors = page["props"]["errors"].as_object().unwrap();
    assert_eq!(errors.len(), 1, "{errors:?}");
    assert_eq!(errors[field], message);
}

#[sqlx::test(migrations = "../../migrations")]
async fn security_page_renders_for_user(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com", false).await;
    let page = assert_security_page(&c.get("/account/security").await, StatusCode::OK, false);
    assert_eq!(page["props"]["auth"]["user"]["email"], "ani@example.com");

    c.post("/logout", json!({})).await;
    let r = c.get("/account/security").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
}

/// Catatan review Task 10: user `must_change_password` mendapat page, bukan `404`.
#[sqlx::test(migrations = "../../migrations")]
async fn must_change_user_gets_security_page_200(pool: PgPool) {
    let mut c = logged_in(&pool, "admin@example.com", true).await;
    let page = assert_security_page(&c.get("/account/security").await, StatusCode::OK, true);
    assert_eq!(page["props"]["auth"]["user"]["mustChangePassword"], true);
}

/// Catatan review Task 10: `HEAD /account/security` lolos guard (tanpa loop redirect).
#[sqlx::test(migrations = "../../migrations")]
async fn must_change_user_head_security_not_redirected(pool: PgPool) {
    let mut c = logged_in(&pool, "admin@example.com", true).await;
    let r = c.send(Method::HEAD, "/account/security", None, false).await;
    assert_eq!(r.status, StatusCode::OK);
    assert!(r.location().is_none(), "{:?}", r.location());
    // HEAD ke path lain tetap dialihkan.
    let r = c.send(Method::HEAD, "/", None, false).await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/account/security"));
}

#[allow(non_snake_case)]
#[sqlx::test(migrations = "../../migrations")]
async fn wrong_current_422_field_currentPassword(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com", false).await;
    let r = c
        .put(
            PASSWORD_PATH,
            change("password-salah-sekali", NEW_PASSWORD, NEW_PASSWORD),
        )
        .await;
    assert_single_field_error(&r, "currentPassword", "Password saat ini salah");
    // Password lama masih berlaku.
    let mut other = Client::new(app(pool));
    assert_eq!(
        other.login("ani@example.com", PASSWORD).await.status,
        StatusCode::SEE_OTHER
    );
}

/// Pre-review fix: 422 dari `PUT /account/security/password` melaporkan `url` page Keamanan,
/// bukan path request (browser tak boleh mendarat di `/account/security/password`).
#[sqlx::test(migrations = "../../migrations")]
async fn validation_422_reports_security_page_url(pool: PgPool) {
    for forced in [false, true] {
        let email = if forced {
            "wajib@example.com"
        } else {
            "ani@example.com"
        };
        let mut c = logged_in(&pool, email, forced).await;
        let r = c
            .put(PASSWORD_PATH, change(PASSWORD, "pendek", "pendek"))
            .await;
        assert_eq!(r.status, StatusCode::UNPROCESSABLE_ENTITY, "{}", r.text());
        let page = r.json();
        assert_eq!(page["url"], "/account/security", "forced={forced}");
        assert_eq!(page["component"], "Account/Security");
        assert_eq!(
            page["props"]["errors"]["password"],
            "Password minimal 12 karakter"
        );
        let len: usize = r.headers["content-length"]
            .to_str()
            .unwrap()
            .parse()
            .unwrap();
        assert_eq!(
            len,
            r.body.len(),
            "Content-Length sesuai body yang ditulis ulang"
        );
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn short_422_field_password(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com", false).await;
    let r = c
        .put(PASSWORD_PATH, change(PASSWORD, "pendek", "pendek"))
        .await;
    assert_single_field_error(&r, "password", "Password minimal 12 karakter");
}

#[allow(non_snake_case)]
#[sqlx::test(migrations = "../../migrations")]
async fn mismatch_422_field_passwordConfirmation(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com", false).await;
    let r = c
        .put(
            PASSWORD_PATH,
            change(PASSWORD, NEW_PASSWORD, "kata-sandi-lain-789"),
        )
        .await;
    assert_single_field_error(&r, "passwordConfirmation", "Ulangan password tidak cocok");
}

#[sqlx::test(migrations = "../../migrations")]
async fn forced_change_success_redirects_home_and_clears_flag(pool: PgPool) {
    let mut c = logged_in(&pool, "admin@example.com", true).await;
    let r = c
        .put(PASSWORD_PATH, change(PASSWORD, NEW_PASSWORD, NEW_PASSWORD))
        .await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    assert_eq!(r.location(), Some("/"));

    let home = c.get("/").await;
    assert_eq!(home.status, StatusCode::OK, "guard tak lagi mengalihkan");
    let page = home.json();
    assert_eq!(page["component"], "Projects/Index");
    assert_eq!(page["props"]["auth"]["user"]["mustChangePassword"], false);
    let flag: bool = sqlx::query_scalar(
        "SELECT must_change_password FROM users WHERE email = 'admin@example.com'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    assert!(!flag);
}

#[sqlx::test(migrations = "../../migrations")]
async fn change_success_deletes_other_sessions_keeps_current(pool: PgPool) {
    let mut a = logged_in(&pool, "ani@example.com", false).await;
    let mut b = Client::new(app(pool.clone()));
    b.login("ani@example.com", PASSWORD).await;
    assert_eq!(session_count(&pool).await, 2);
    let user_id = sqlx::query_scalar("SELECT id FROM users WHERE email = 'ani@example.com'")
        .fetch_one(&pool)
        .await
        .unwrap();
    create_token(&pool, user_id, "Claude Code").await.unwrap();

    let r = a
        .put(PASSWORD_PATH, change(PASSWORD, NEW_PASSWORD, NEW_PASSWORD))
        .await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    assert_eq!(r.location(), Some("/account/security"));

    assert_eq!(session_count(&pool).await, 1);
    let r = b.get("/").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
    assert_security_page(&a.get("/account/security").await, StatusCode::OK, false);

    let tokens = list_tokens(&pool, user_id).await.unwrap();
    assert_eq!(tokens.len(), 1);
    assert!(tokens[0].revoked_at.is_none(), "PAT tetap berlaku");

    let mut c = Client::new(app(pool));
    assert_eq!(
        c.login("ani@example.com", PASSWORD).await.status,
        StatusCode::UNPROCESSABLE_ENTITY
    );
    assert_eq!(
        c.login("ani@example.com", NEW_PASSWORD).await.status,
        StatusCode::SEE_OTHER
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn account_root_redirects_profile(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com", false).await;
    let r = c.get("/account").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/account/profile"));

    let mut guest = Client::new(app(pool));
    let r = guest.get("/account").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
}

/// Keputusan Task 13: password saat ini salah dibatasi per user (5 gagal / 15 menit → `429`).
#[sqlx::test(migrations = "../../migrations")]
async fn wrong_current_password_throttled_after_five_failures(pool: PgPool) {
    let router = app(pool.clone());
    let mut c = logged_in_on(router.clone(), &pool, "ani@example.com", false).await;
    let wrong = change("password-salah-sekali", NEW_PASSWORD, NEW_PASSWORD);
    // Kesalahan field lain (password saat ini benar) tidak dihitung.
    let r = c
        .put(PASSWORD_PATH, change(PASSWORD, "pendek", "pendek"))
        .await;
    assert_eq!(r.status, StatusCode::UNPROCESSABLE_ENTITY);
    for i in 0..5 {
        let r = c.put(PASSWORD_PATH, wrong.clone()).await;
        assert_eq!(
            r.status,
            StatusCode::UNPROCESSABLE_ENTITY,
            "percobaan {}",
            i + 1
        );
    }
    // Percobaan ke-6 ditolak sebelum Argon2, walau password saat ini benar.
    let r = c
        .put(PASSWORD_PATH, change(PASSWORD, NEW_PASSWORD, NEW_PASSWORD))
        .await;
    let page = assert_security_page(&r, StatusCode::TOO_MANY_REQUESTS, false);
    assert_eq!(page["props"]["errors"]["currentPassword"], THROTTLE_ERROR);
    let retry: u64 = r.headers["retry-after"].to_str().unwrap().parse().unwrap();
    assert!(retry > 0 && retry <= 15 * 60, "Retry-After {retry}");

    // Password tidak berubah; user lain (IP sama) tidak terkena.
    let mut other = logged_in_on(router, &pool, "budi@example.com", false).await;
    let r = other
        .put(PASSWORD_PATH, change(PASSWORD, NEW_PASSWORD, NEW_PASSWORD))
        .await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    let mut fresh = Client::new(app(pool));
    assert_eq!(
        fresh.login("ani@example.com", PASSWORD).await.status,
        StatusCode::SEE_OTHER
    );
}
