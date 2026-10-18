//! Akun: `GET/PUT /account/profile` (page `Account/Profile`) lewat `web_router` nyata.

mod common;

use axum::http::StatusCode;
use common::*;
use serde_json::{Value, json};
use sqlx::PgPool;
use whisker_core::user::Role;

async fn logged_in(pool: &PgPool, email: &str) -> Client {
    seed_user(pool, email, Role::Member, false).await;
    let mut c = Client::new(app(pool.clone()));
    let r = c.login(email, PASSWORD).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    c
}

fn assert_profile_page(r: &Resp, status: StatusCode) -> Value {
    assert_eq!(r.status, status, "{}", r.text());
    assert_eq!(r.headers["x-inertia"], "true");
    let page = r.json();
    assert_eq!(page["component"], "Account/Profile");
    assert_eq!(page["url"], "/account/profile");
    page
}

fn assert_single_field_error(r: &Resp, field: &str) {
    let page = assert_profile_page(r, StatusCode::UNPROCESSABLE_ENTITY);
    let errors = page["props"]["errors"].as_object().unwrap();
    assert_eq!(errors.len(), 1, "{errors:?}");
    assert!(errors.contains_key(field), "{errors:?}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn profile_page_lists_40_avatar_options(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let page = assert_profile_page(&c.get("/account/profile").await, StatusCode::OK);
    let options = page["props"]["avatarOptions"].as_array().unwrap();
    assert_eq!(options.len(), 40);
    assert_eq!(options[0], json!({"key": "human-f-01", "group": "female"}));
    assert_eq!(options[39], json!({"key": "animal-08", "group": "animal"}));
    let count = |g: &str| options.iter().filter(|o| o["group"] == g).count();
    assert_eq!(
        (count("female"), count("male"), count("animal")),
        (16, 16, 8)
    );
    assert_eq!(page["props"]["auth"]["user"]["email"], "ani@example.com");

    c.post("/logout", json!({})).await;
    let r = c.get("/account/profile").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn update_profile_saves_and_shared_props_reflect(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let r = c
        .put(
            "/account/profile",
            json!({"displayName": "  Ani Baru  ", "avatarKey": "animal-03"}),
        )
        .await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    assert_eq!(r.location(), Some("/account/profile"));

    let page = assert_profile_page(&c.get("/account/profile").await, StatusCode::OK);
    let user = &page["props"]["auth"]["user"];
    assert_eq!(user["displayName"], "Ani Baru");
    assert_eq!(user["avatarKey"], "animal-03");

    let (name, key): (String, String) = sqlx::query_as(
        "SELECT display_name, avatar_key FROM users WHERE email = 'ani@example.com'",
    )
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!((name.as_str(), key.as_str()), ("Ani Baru", "animal-03"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_avatar_key_422_field_avatar_key(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    for bad in ["human-f-99", "evil", ""] {
        let r = c
            .put(
                "/account/profile",
                json!({"displayName": "Ani", "avatarKey": bad}),
            )
            .await;
        assert_single_field_error(&r, "avatarKey");
    }
    let r = c
        .put("/account/profile", json!({"displayName": "Ani"}))
        .await;
    assert_single_field_error(&r, "avatarKey");
}

#[sqlx::test(migrations = "../../migrations")]
async fn blank_display_name_422(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    for bad in ["", "   ", &"x".repeat(81)] {
        let r = c
            .put(
                "/account/profile",
                json!({"displayName": bad, "avatarKey": "animal-01"}),
            )
            .await;
        assert_single_field_error(&r, "displayName");
    }
    let ok = c
        .put(
            "/account/profile",
            json!({"displayName": "x".repeat(80), "avatarKey": "animal-01"}),
        )
        .await;
    assert_eq!(ok.status, StatusCode::SEE_OTHER);
}

#[sqlx::test(migrations = "../../migrations")]
async fn email_not_updatable_via_profile(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let r = c
        .put(
            "/account/profile",
            json!({"displayName": "Ani", "avatarKey": "animal-01", "email": "evil@example.com"}),
        )
        .await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    let page = assert_profile_page(&c.get("/account/profile").await, StatusCode::OK);
    assert_eq!(page["props"]["auth"]["user"]["email"], "ani@example.com");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM users WHERE email = 'evil@example.com'")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(n, 0);
}
