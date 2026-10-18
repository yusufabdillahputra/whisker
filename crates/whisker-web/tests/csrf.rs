//! CSRF `veer` (double-submit `XSRF-TOKEN` → `X-XSRF-TOKEN`) di `web_router`; penolakan = `419`.

mod common;

use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use common::*;
use serde_json::json;
use sqlx::PgPool;
use tower::ServiceExt;
use whisker_core::user::Role;

/// Token `XSRF-TOKEN` segar dari GET tanpa cookie.
async fn fresh_token(app: &Router) -> String {
    let mut c = Client::new(app.clone());
    c.get("/login").await;
    c.cookie("XSRF-TOKEN")
        .expect("XSRF-TOKEN diterbitkan")
        .to_owned()
}

async fn post(
    app: &Router,
    uri: &str,
    cookie: Option<&str>,
    header_token: Option<&str>,
) -> StatusCode {
    let mut req = Request::post(uri)
        .header("X-Inertia", "true")
        .header("X-Inertia-Version", VERSION)
        .header(header::CONTENT_TYPE, "application/json");
    if let Some(c) = cookie {
        req = req.header(header::COOKIE, c);
    }
    if let Some(t) = header_token {
        req = req.header("X-XSRF-TOKEN", t);
    }
    let body = json!({ "email": "ani@example.com", "password": PASSWORD }).to_string();
    app.clone()
        .oneshot(req.body(Body::from(body)).unwrap())
        .await
        .unwrap()
        .status()
}

const CSRF_REJECTED: u16 = 419;

#[sqlx::test(migrations = "../../migrations")]
async fn post_login_without_xsrf_header_rejected(pool: PgPool) {
    let app = app(pool);
    let token = fresh_token(&app).await;
    let cookie = format!("XSRF-TOKEN={token}");
    assert_eq!(
        post(&app, "/login", Some(&cookie), None).await.as_u16(),
        CSRF_REJECTED
    );
    assert_eq!(
        post(&app, "/login", None, None).await.as_u16(),
        CSRF_REJECTED
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn post_with_mismatched_xsrf_rejected(pool: PgPool) {
    let app = app(pool);
    let a = fresh_token(&app).await;
    let b = fresh_token(&app).await;
    assert_ne!(a, b);
    let cookie = format!("XSRF-TOKEN={a}");
    assert_eq!(
        post(&app, "/login", Some(&cookie), Some(&b)).await.as_u16(),
        CSRF_REJECTED
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn forged_or_tampered_xsrf_rejected(pool: PgPool) {
    let app = app(pool);
    // Token karangan, dikirim identik di cookie dan header.
    let forged = "Zm9yZ2Vk.c2lnbmF0dXJl";
    let cookie = format!("XSRF-TOKEN={forged}");
    assert_eq!(
        post(&app, "/login", Some(&cookie), Some(forged))
            .await
            .as_u16(),
        CSRF_REJECTED
    );

    // Token asli dengan tanda tangan diubah satu karakter.
    let token = fresh_token(&app).await;
    let (rand, sig) = token.split_once('.').unwrap();
    let mut sig: Vec<u8> = sig.bytes().collect();
    sig[0] = if sig[0] == b'A' { b'B' } else { b'A' };
    let tampered = format!("{rand}.{}", String::from_utf8(sig).unwrap());
    let cookie = format!("XSRF-TOKEN={tampered}");
    assert_eq!(
        post(&app, "/login", Some(&cookie), Some(&tampered))
            .await
            .as_u16(),
        CSRF_REJECTED
    );

    // Token dari secret lain (proses/instansi lain).
    let other = fresh_token(&{
        let state = whisker_web::AppState::new(
            sqlx::PgPool::connect_lazy("postgres://localhost/tidak-dipakai").unwrap(),
            whisker_web::WebConfig {
                csrf_secret: vec![9u8; 32],
                ..web_config(Vec::new())
            },
        );
        whisker_web::web_router(state, inertia_config())
    })
    .await;
    let cookie = format!("XSRF-TOKEN={other}");
    assert_eq!(
        post(&app, "/login", Some(&cookie), Some(&other))
            .await
            .as_u16(),
        CSRF_REJECTED
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn xsrf_header_without_cookie_rejected(pool: PgPool) {
    let app = app(pool);
    let token = fresh_token(&app).await;
    assert_eq!(
        post(&app, "/login", None, Some(&token)).await.as_u16(),
        CSRF_REJECTED
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn post_logout_without_xsrf_rejected(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let app = app(pool.clone());
    let mut c = Client::new(app.clone());
    c.login("ani@example.com", PASSWORD).await;
    let cookie = format!(
        "whisker_session={}; XSRF-TOKEN={}",
        c.cookie("whisker_session").unwrap(),
        c.cookie("XSRF-TOKEN").unwrap()
    );
    assert_eq!(
        post(&app, "/logout", Some(&cookie), None).await.as_u16(),
        CSRF_REJECTED
    );
    assert_eq!(session_count(&pool).await, 1, "sesi tetap ada");
}

#[sqlx::test(migrations = "../../migrations")]
async fn post_with_valid_xsrf_reaches_handler(pool: PgPool) {
    let app = app(pool);
    let token = fresh_token(&app).await;
    let cookie = format!("XSRF-TOKEN={token}");
    assert_eq!(
        post(&app, "/login", Some(&cookie), Some(&token)).await,
        StatusCode::UNPROCESSABLE_ENTITY
    );
}
