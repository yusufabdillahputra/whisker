//! Alur login/logout, sesi cookie, dan throttle lewat `web_router` nyata (ruling K2).

mod common;

use axum::http::{Method, StatusCode};
use common::*;
use serde_json::json;
use sqlx::PgPool;
use whisker_core::user::{Role, disable_user};

#[sqlx::test(migrations = "../../migrations")]
async fn login_page_renders_for_guest(pool: PgPool) {
    let mut c = Client::new(app(pool));
    let r = c.get("/login").await;
    assert_eq!(r.status, StatusCode::OK);
    let page = r.json();
    assert_eq!(page["component"], "Auth/Login");
    assert_eq!(page["props"]["auth"], serde_json::Value::Null);
}

#[sqlx::test(migrations = "../../migrations")]
async fn login_success_sets_cookie_and_redirects_home(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool.clone()));
    let r = c.login("ani@example.com", PASSWORD).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER);
    assert_eq!(r.location(), Some("/"));
    let cookie = r.set_cookie("whisker_session").expect("cookie sesi");
    for attr in [
        "HttpOnly",
        "Secure",
        "SameSite=Lax",
        "Path=/",
        "Max-Age=2592000",
    ] {
        assert!(cookie.contains(attr), "{attr} di {cookie}");
    }
    let raw = c.cookie("whisker_session").unwrap();
    assert_eq!(raw.len(), 43, "id 256-bit base64url");
    assert_eq!(session_count(&pool).await, 1);

    let home = c.get("/").await;
    assert_eq!(home.status, StatusCode::OK);
    let page = home.json();
    assert_eq!(page["component"], "Projects/Index");
    assert_eq!(page["props"]["projects"], json!([]));
    let user = &page["props"]["auth"]["user"];
    assert_eq!(user["email"], "ani@example.com");
    assert_eq!(user["displayName"], "Pengguna Uji");
    assert_eq!(user["role"], "member");
    assert_eq!(user["mustChangePassword"], false);
    assert!(user["avatarKey"].is_string() && user["id"].is_string());
}

#[sqlx::test(migrations = "../../migrations")]
async fn login_email_is_case_insensitive_and_trimmed(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool));
    let r = c.login("  ANI@Example.com ", PASSWORD).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER);
}

#[sqlx::test(migrations = "../../migrations")]
async fn login_bootstrap_admin_redirects_security(pool: PgPool) {
    seed_user(&pool, "admin@example.com", Role::Admin, true).await;
    let mut c = Client::new(app(pool));
    let r = c.login("admin@example.com", PASSWORD).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER);
    assert_eq!(r.location(), Some("/account/security"));
    assert!(r.set_cookie("whisker_session").is_some());
}

async fn assert_generic_failure(r: &Resp) {
    assert_eq!(r.status, StatusCode::UNPROCESSABLE_ENTITY, "{}", r.text());
    assert_eq!(r.headers["x-inertia"], "true");
    let page = r.json();
    assert_eq!(page["component"], "Auth/Login");
    assert_eq!(page["props"]["errors"]["email"], GENERIC_ERROR);
    assert_eq!(page["props"]["errors"].as_object().unwrap().len(), 1);
    assert!(r.set_cookie("whisker_session").is_none());
}

#[sqlx::test(migrations = "../../migrations")]
async fn wrong_password_generic_error_422(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool.clone()));
    let r = c.login("ani@example.com", "password-salah-sekali").await;
    assert_generic_failure(&r).await;
    assert_eq!(session_count(&pool).await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_email_same_generic_error(pool: PgPool) {
    let mut c = Client::new(app(pool));
    let r = c.login("tidak-ada@example.com", PASSWORD).await;
    assert_generic_failure(&r).await;
    let r = c.post("/login", json!({})).await;
    assert_generic_failure(&r).await;
}

#[sqlx::test(migrations = "../../migrations")]
async fn disabled_user_same_generic_error(pool: PgPool) {
    let admin = seed_user(&pool, "admin@example.com", Role::Admin, false).await;
    let ani = seed_user(&pool, "ani@example.com", Role::Member, false).await;
    disable_user(&pool, admin.id, ani.id).await.unwrap();
    let mut c = Client::new(app(pool.clone()));
    let r = c.login("ani@example.com", PASSWORD).await;
    assert_generic_failure(&r).await;
    assert_eq!(session_count(&pool).await, 0);
}

fn assert_throttled(r: &Resp) {
    assert_eq!(r.status, StatusCode::TOO_MANY_REQUESTS, "{}", r.text());
    assert_eq!(r.headers["x-inertia"], "true");
    let retry: u64 = r.headers["retry-after"].to_str().unwrap().parse().unwrap();
    assert!(retry > 0 && retry <= 15 * 60, "Retry-After {retry}");
    let page = r.json();
    assert_eq!(page["component"], "Auth/Login");
    assert_eq!(page["props"]["errors"]["email"], THROTTLE_ERROR);
    assert!(r.set_cookie("whisker_session").is_none());
}

#[sqlx::test(migrations = "../../migrations")]
async fn sixth_failed_login_returns_429(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool));
    for _ in 0..5 {
        let r = c.login("ani@example.com", "password-salah-sekali").await;
        assert_eq!(r.status, StatusCode::UNPROCESSABLE_ENTITY);
    }
    assert_throttled(&c.login("ani@example.com", "password-salah-sekali").await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn sixth_failed_login_per_ip_across_emails_returns_429(pool: PgPool) {
    let mut c = Client::new(app(pool));
    for i in 0..5 {
        let r = c
            .login(&format!("u{i}@example.com"), "password-salah-sekali")
            .await;
        assert_eq!(r.status, StatusCode::UNPROCESSABLE_ENTITY);
    }
    assert_throttled(&c.login("baru@example.com", "password-salah-sekali").await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn parallel_burst_cannot_exceed_throttle_quota(pool: PgPool) {
    const K: usize = 12;
    let app = app(pool);
    let mut c = Client::new(app.clone());
    c.get("/login").await;
    let token = c.cookie("XSRF-TOKEN").unwrap().to_owned();

    let tasks: Vec<_> = (0..K)
        .map(|_| {
            let app = app.clone();
            let token = token.clone();
            tokio::spawn(async move {
                let req = axum::http::Request::post("/login")
                    .header("X-Inertia", "true")
                    .header("X-Inertia-Version", VERSION)
                    .header(axum::http::header::CONTENT_TYPE, "application/json")
                    .header(axum::http::header::COOKIE, format!("XSRF-TOKEN={token}"))
                    .header("X-XSRF-TOKEN", token)
                    .body(axum::body::Body::from(
                        json!({"email": "ani@example.com", "password": "password-salah-sekali"})
                            .to_string(),
                    ))
                    .unwrap();
                tower::ServiceExt::oneshot(app, req).await.unwrap().status()
            })
        })
        .collect();
    let mut statuses = Vec::new();
    for t in tasks {
        statuses.push(t.await.unwrap());
    }
    let failed = statuses
        .iter()
        .filter(|s| **s == StatusCode::UNPROCESSABLE_ENTITY)
        .count();
    let throttled = statuses
        .iter()
        .filter(|s| **s == StatusCode::TOO_MANY_REQUESTS)
        .count();
    assert!(
        failed <= 5,
        "maks 5 percobaan mencapai Argon2, dapat {failed}: {statuses:?}"
    );
    assert!(failed >= 1);
    assert_eq!(failed + throttled, K, "{statuses:?}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn throttled_login_returns_429_even_with_correct_password(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool.clone()));
    for _ in 0..5 {
        c.login("ani@example.com", "password-salah-sekali").await;
    }
    assert_throttled(&c.login("ani@example.com", PASSWORD).await);
    assert_eq!(session_count(&pool).await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn successful_login_does_not_count_as_failure(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool));
    for _ in 0..4 {
        c.login("ani@example.com", "password-salah-sekali").await;
    }
    assert_eq!(
        c.login("ani@example.com", PASSWORD).await.status,
        StatusCode::SEE_OTHER
    );
    // Kegagalan ke-5 (sukses tidak dihitung) masih 422; baru percobaan berikutnya 429.
    let r = c.login("ani@example.com", "password-salah-sekali").await;
    assert_eq!(r.status, StatusCode::UNPROCESSABLE_ENTITY);
    assert_throttled(&c.login("ani@example.com", "password-salah-sekali").await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn forwarded_for_ignored_without_trusted_proxies(pool: PgPool) {
    let mut c = Client::new(app(pool));
    for i in 0..5 {
        c.forwarded_for = Some(format!("198.51.100.{i}"));
        c.login(&format!("u{i}@example.com"), "password-salah-sekali")
            .await;
    }
    // XFF palsu berganti-ganti tidak memberi kuota baru: kunci IP = peer TCP.
    c.forwarded_for = Some("198.51.100.99".into());
    assert_throttled(&c.login("baru@example.com", "password-salah-sekali").await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn forwarded_for_used_when_peer_is_trusted_proxy(pool: PgPool) {
    let trusted = vec!["203.0.113.10/32".parse().unwrap()];
    let mut c = Client::new(app_with(pool, trusted));
    c.forwarded_for = Some("198.51.100.1".into());
    for i in 0..5 {
        c.login(&format!("u{i}@example.com"), "password-salah-sekali")
            .await;
    }
    assert_throttled(&c.login("baru@example.com", "password-salah-sekali").await);
    c.forwarded_for = Some("198.51.100.2".into());
    let r = c.login("lain@example.com", "password-salah-sekali").await;
    assert_eq!(
        r.status,
        StatusCode::UNPROCESSABLE_ENTITY,
        "IP klien lain tidak terkena"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn logout_deletes_session_row_and_cookie_invalid(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool.clone()));
    c.login("ani@example.com", PASSWORD).await;
    let old = c.cookie("whisker_session").unwrap().to_owned();
    assert_eq!(session_count(&pool).await, 1);

    let r = c.post("/logout", json!({})).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER);
    assert_eq!(r.location(), Some("/login"));
    let removal = r.set_cookie("whisker_session").expect("cookie penghapus");
    assert!(removal.contains("Max-Age=0"), "{removal}");
    assert_eq!(session_count(&pool).await, 0);

    // Cookie lama dipakai ulang → tak berlaku.
    c.jar.insert("whisker_session".into(), old);
    let r = c.get("/").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn protected_route_without_session_redirects_login(pool: PgPool) {
    let mut c = Client::new(app(pool));
    let r = c.get("/").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_session_cookie_is_cleared(pool: PgPool) {
    let mut c = Client::new(app(pool));
    c.jar.insert("whisker_session".into(), "bukan-sesi".into());
    let r = c.get("/").await;
    assert_eq!(r.status, StatusCode::FOUND);
    let removal = r
        .set_cookie("whisker_session")
        .expect("cookie basi dihapus");
    assert!(removal.contains("Max-Age=0"), "{removal}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn authenticated_get_login_redirects_home(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool));
    c.login("ani@example.com", PASSWORD).await;
    let r = c.get("/login").await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn extended_session_reissues_cookie(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool.clone()));
    c.login("ani@example.com", PASSWORD).await;
    let raw = c.cookie("whisker_session").unwrap().to_owned();

    // Dalam 1 jam: tidak diperpanjang, cookie tidak diterbitkan ulang.
    let r = c.get("/").await;
    assert_eq!(r.status, StatusCode::OK);
    assert!(r.set_cookie("whisker_session").is_none());

    sqlx::query("UPDATE sessions SET last_seen_at = now() - interval '2 hours'")
        .execute(&pool)
        .await
        .unwrap();
    let r = c.get("/").await;
    assert_eq!(r.status, StatusCode::OK);
    let cookie = r
        .set_cookie("whisker_session")
        .expect("cookie diterbitkan ulang");
    assert!(
        cookie.starts_with(&format!("whisker_session={raw};")),
        "{cookie}"
    );
    for attr in [
        "HttpOnly",
        "Secure",
        "SameSite=Lax",
        "Path=/",
        "Max-Age=2592000",
    ] {
        assert!(cookie.contains(attr), "{attr} di {cookie}");
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn oversized_body_rejected_413(pool: PgPool) {
    let mut c = Client::new(app(pool));
    let huge = "a".repeat(whisker_web::WEB_BODY_LIMIT + 1);
    let r = c.login("ani@example.com", &huge).await;
    assert_eq!(r.status, StatusCode::PAYLOAD_TOO_LARGE);
}

#[sqlx::test(migrations = "../../migrations")]
async fn database_error_is_generic_500(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool.clone()));
    c.login("ani@example.com", PASSWORD).await;
    c.get("/login").await;
    pool.close().await;

    // Lookup sesi (middleware) gagal.
    let with_session = c.get("/").await;
    // Login tanpa cookie sesi: query user (handler) gagal.
    c.jar.remove("whisker_session");
    let login = c
        .send(
            Method::POST,
            "/login",
            Some(json!({"email": "a@b.c", "password": "x"})),
            true,
        )
        .await;
    for r in [with_session, login] {
        assert_eq!(r.status, StatusCode::INTERNAL_SERVER_ERROR);
        let body = r.text().to_lowercase();
        assert!(
            !body.contains("pool") && !body.contains("database") && !body.contains("sqlx"),
            "detail internal bocor: {body}"
        );
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_path_renders_not_found_page(pool: PgPool) {
    seed_user(&pool, "ani@example.com", Role::Member, false).await;
    let mut c = Client::new(app(pool));
    let r = c.get("/tidak-ada/sama-sekali").await;
    assert_eq!(r.status, StatusCode::NOT_FOUND);
    let page = r.json();
    assert_eq!(page["component"], "Errors/NotFound");
    assert_eq!(page["props"]["status"], 404);
    assert_eq!(page["props"]["auth"], serde_json::Value::Null);

    c.login("ani@example.com", PASSWORD).await;
    let page = c.get("/tidak-ada").await.json();
    assert_eq!(page["component"], "Errors/NotFound");
    assert_eq!(page["props"]["auth"]["user"]["email"], "ani@example.com");
}
