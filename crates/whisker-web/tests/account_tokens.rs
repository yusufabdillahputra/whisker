//! Akun: `GET/POST /account/tokens` (page `Account/Tokens`) dan
//! `POST /account/tokens/{id}/revoke` lewat `web_router` nyata; token hasil alur ini diuji ke
//! `/mcp` (router MCP digabung seperti app lengkap).

mod common;

use axum::Router;
use axum::body::Body;
use axum::extract::connect_info::MockConnectInfo;
use axum::http::{Request, StatusCode, header};
use common::*;
use http_body_util::BodyExt;
use serde_json::{Value, json};
use sqlx::PgPool;
use time::OffsetDateTime;
use time::format_description::well_known::Rfc3339;
use tower::ServiceExt;
use whisker_core::auth::pat::token_hash;
use whisker_core::token::{authenticate_token, create_token};
use whisker_core::user::Role;
use whisker_mcp::{McpConfig, mcp_router};
use whisker_web::{AppState, web_router};

const TOKENS_PATH: &str = "/account/tokens";

async fn logged_in_on(router: Router, pool: &PgPool, email: &str, role: Role) -> Client {
    seed_user(pool, email, role, false).await;
    let mut c = Client::new(router);
    let r = c.login(email, PASSWORD).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
    c
}

async fn logged_in(pool: &PgPool, email: &str) -> Client {
    logged_in_on(app(pool.clone()), pool, email, Role::Member).await
}

fn assert_tokens_page(r: &Resp, status: StatusCode) -> Value {
    assert_eq!(r.status, status, "{}", r.text());
    assert_eq!(r.headers["x-inertia"], "true");
    let page = r.json();
    assert_eq!(page["component"], "Account/Tokens");
    assert_eq!(page["url"], TOKENS_PATH);
    page
}

async fn create(c: &mut Client, name: &str) -> Resp {
    c.post(TOKENS_PATH, json!({ "name": name })).await
}

/// Buat token lewat rute; kembalikan `createdToken` dari page `200`.
async fn create_ok(c: &mut Client, name: &str) -> Value {
    let page = assert_tokens_page(&create(c, name).await, StatusCode::OK);
    page["props"]["createdToken"].clone()
}

async fn token_count(pool: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM access_tokens")
        .fetch_one(pool)
        .await
        .unwrap()
}

fn assert_rfc3339(v: &Value) {
    let s = v.as_str().unwrap_or_else(|| panic!("bukan string: {v}"));
    OffsetDateTime::parse(s, &Rfc3339).unwrap_or_else(|e| panic!("{s}: {e}"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn tokens_page_requires_session(pool: PgPool) {
    let mut c = Client::new(app(pool));
    let r = c.get(TOKENS_PATH).await;
    assert_eq!(r.status, StatusCode::FOUND);
    assert_eq!(r.location(), Some("/login"));
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_response_contains_plain_once(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let r = create(&mut c, "  Laptop  ").await;
    let page = assert_tokens_page(&r, StatusCode::OK);
    assert_eq!(page["encryptHistory"], true, "history encryption");

    let created = &page["props"]["createdToken"];
    let plain = created["plain"].as_str().unwrap();
    assert!(plain.starts_with("whk_"));
    assert_eq!(plain.len(), 53);
    assert_eq!(created["name"], "Laptop");
    assert_eq!(
        r.text().matches(plain).count(),
        1,
        "token polos tepat sekali"
    );

    let tokens = page["props"]["tokens"].as_array().unwrap();
    assert_eq!(tokens.len(), 1);
    assert_eq!(tokens[0]["id"], created["id"]);
    assert!(tokens[0].get("plain").is_none());
    assert_eq!(token_count(&pool).await, 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn subsequent_get_has_no_plain(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let created = create_ok(&mut c, "Laptop").await;
    let plain = created["plain"].as_str().unwrap().to_owned();

    let r = c.get(TOKENS_PATH).await;
    let page = assert_tokens_page(&r, StatusCode::OK);
    assert_eq!(page["props"]["createdToken"], Value::Null);
    assert!(!r.text().contains(&plain));
    assert_eq!(page["props"]["tokens"][0]["id"], created["id"]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn list_shows_name_prefix_created_lastused_status(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let first = create_ok(&mut c, "Laptop").await;
    let second = create_ok(&mut c, "Server").await;
    let first_plain = first["plain"].as_str().unwrap();
    authenticate_token(&pool, &token_hash(first_plain))
        .await
        .unwrap()
        .expect("token aktif");
    let id = second["id"].as_str().unwrap();
    let r = c
        .post(&format!("{TOKENS_PATH}/{id}/revoke"), json!({}))
        .await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());

    let page = assert_tokens_page(&c.get(TOKENS_PATH).await, StatusCode::OK);
    let tokens = page["props"]["tokens"].as_array().unwrap();
    assert_eq!(tokens.len(), 2);
    // Terbaru dulu.
    let (server, laptop) = (&tokens[0], &tokens[1]);
    let keys = |t: &Value| {
        let mut k: Vec<String> = t.as_object().unwrap().keys().cloned().collect();
        k.sort();
        k
    };
    assert_eq!(
        keys(laptop),
        [
            "createdAt",
            "displayPrefix",
            "id",
            "lastUsedAt",
            "name",
            "status"
        ]
    );

    assert_eq!(laptop["id"], first["id"]);
    assert_eq!(laptop["name"], "Laptop");
    assert_eq!(laptop["displayPrefix"], &first_plain[..12]);
    assert_rfc3339(&laptop["createdAt"]);
    assert_rfc3339(&laptop["lastUsedAt"]);
    assert_eq!(laptop["status"], "active");

    let second_plain = second["plain"].as_str().unwrap();
    assert_eq!(server["name"], "Server");
    assert_eq!(server["displayPrefix"], &second_plain[..12]);
    assert_rfc3339(&server["createdAt"]);
    assert_eq!(server["lastUsedAt"], Value::Null);
    assert_eq!(server["status"], "revoked");
}

#[sqlx::test(migrations = "../../migrations")]
async fn revoke_other_users_token_404(pool: PgPool) {
    let budi = seed_user(&pool, "budi@example.com", Role::Member, false).await;
    let (budi_token, _) = create_token(&pool, budi.id, "Milik Budi").await.unwrap();
    let mut c = logged_in(&pool, "ani@example.com").await;

    for id in [
        budi_token.id.to_string(),
        "00000000-0000-0000-0000-000000000000".to_owned(),
        "bukan-uuid".to_owned(),
    ] {
        let r = c
            .post(&format!("{TOKENS_PATH}/{id}/revoke"), json!({}))
            .await;
        assert_eq!(r.status, StatusCode::NOT_FOUND, "{id}: {}", r.text());
        assert_eq!(r.json()["component"], "Errors/NotFound");
    }
    let revoked: Option<OffsetDateTime> =
        sqlx::query_scalar("SELECT revoked_at FROM access_tokens WHERE id = $1")
            .bind(budi_token.id)
            .fetch_one(&pool)
            .await
            .unwrap();
    assert!(revoked.is_none(), "token user lain tak tersentuh");
}

#[sqlx::test(migrations = "../../migrations")]
async fn revoke_marks_revoked_status(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let created = create_ok(&mut c, "Laptop").await;
    let uri = format!("{TOKENS_PATH}/{}/revoke", created["id"].as_str().unwrap());

    // Idempoten: revoke kedua tetap 303, tanpa jalur aktivasi ulang.
    for _ in 0..2 {
        let r = c.post(&uri, json!({})).await;
        assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());
        assert_eq!(r.location(), Some(TOKENS_PATH));
    }
    let page = assert_tokens_page(&c.get(TOKENS_PATH).await, StatusCode::OK);
    assert_eq!(page["props"]["tokens"][0]["status"], "revoked");
    let plain = created["plain"].as_str().unwrap();
    assert!(
        authenticate_token(&pool, &token_hash(plain))
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_blank_name_422(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let too_long = "x".repeat(101);
    let emoji_too_long = "😀".repeat(101);
    for bad in ["", "   ", too_long.as_str(), emoji_too_long.as_str()] {
        let page = assert_tokens_page(&create(&mut c, bad).await, StatusCode::UNPROCESSABLE_ENTITY);
        let errors = page["props"]["errors"].as_object().unwrap();
        assert_eq!(errors.len(), 1, "{errors:?}");
        assert!(errors.contains_key("name"), "{errors:?}");
        assert_eq!(page["props"]["createdToken"], Value::Null);
    }
    // Field hilang = string kosong.
    let r = c.post(TOKENS_PATH, json!({})).await;
    let page = assert_tokens_page(&r, StatusCode::UNPROCESSABLE_ENTITY);
    assert!(page["props"]["errors"]["name"].is_string());
    assert_eq!(token_count(&pool).await, 0);

    // Batas server = 100 karakter (code point), juga untuk karakter di luar BMP.
    create_ok(&mut c, &"x".repeat(100)).await;
    create_ok(&mut c, &"😀".repeat(100)).await;
    assert_eq!(token_count(&pool).await, 2);
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_response_no_store_cache_header(pool: PgPool) {
    let mut c = logged_in(&pool, "ani@example.com").await;
    let r = create(&mut c, "Laptop").await;
    assert_eq!(r.status, StatusCode::OK, "{}", r.text());
    assert_eq!(
        r.headers
            .get(header::CACHE_CONTROL)
            .map(|v| v.to_str().unwrap()),
        Some("no-store")
    );
}

// ---- Bukti tingkat protokol: token dari alur ini → `/mcp` ----

/// Router web + `/mcp` digabung seperti `whisker::app::build_app`.
fn app_with_mcp(pool: PgPool) -> Router {
    let state = AppState::new(pool.clone(), web_config(Vec::new()));
    web_router(state, inertia_config())
        .merge(mcp_router(
            pool,
            McpConfig {
                allowed_origin: None,
            },
        ))
        .layer(MockConnectInfo(peer()))
}

/// JSON-RPC ke `/mcp` (stateless, respons JSON). `Host` wajib bagi rmcp.
async fn mcp(app: &Router, bearer: &str, body: Value) -> (StatusCode, Option<String>, Value) {
    let req = Request::post("/mcp")
        .header(header::CONTENT_TYPE, "application/json")
        .header(header::HOST, "localhost:8080")
        .header(header::ACCEPT, "application/json, text/event-stream")
        .header(header::AUTHORIZATION, format!("Bearer {bearer}"))
        .body(Body::from(body.to_string()))
        .unwrap();
    let res = app.clone().oneshot(req).await.unwrap();
    let status = res.status();
    let www = res
        .headers()
        .get(header::WWW_AUTHENTICATE)
        .map(|v| v.to_str().unwrap().to_owned());
    let bytes = res.into_body().collect().await.unwrap().to_bytes();
    let json = serde_json::from_slice(&bytes).unwrap_or(Value::Null);
    (status, www, json)
}

fn initialize() -> Value {
    json!({
        "jsonrpc": "2.0", "id": 1, "method": "initialize",
        "params": {
            "protocolVersion": "2025-06-18",
            "capabilities": {},
            "clientInfo": { "name": "uji-account-tokens", "version": "0" }
        }
    })
}

fn call_whoami() -> Value {
    json!({
        "jsonrpc": "2.0", "id": 2, "method": "tools/call",
        "params": { "name": "whoami", "arguments": {} }
    })
}

#[sqlx::test(migrations = "../../migrations")]
async fn created_token_authenticates_mcp_until_revoked(pool: PgPool) {
    let router = app_with_mcp(pool.clone());
    let mut c = logged_in_on(router.clone(), &pool, "ani@example.com", Role::Admin).await;
    let created = create_ok(&mut c, "Claude Code").await;
    let plain = created["plain"].as_str().unwrap().to_owned();

    let (status, _, body) = mcp(&router, &plain, initialize()).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    assert!(body["result"]["serverInfo"].is_object(), "{body}");

    let (status, _, body) = mcp(&router, &plain, call_whoami()).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    assert_ne!(body["result"]["isError"], true, "{body}");
    assert_eq!(
        body["result"]["structuredContent"],
        json!({ "email": "ani@example.com", "role": "admin" })
    );

    let uri = format!("{TOKENS_PATH}/{}/revoke", created["id"].as_str().unwrap());
    let r = c.post(&uri, json!({})).await;
    assert_eq!(r.status, StatusCode::SEE_OTHER, "{}", r.text());

    for req in [initialize(), call_whoami()] {
        let (status, www, _) = mcp(&router, &plain, req).await;
        assert_eq!(status, StatusCode::UNAUTHORIZED);
        assert_eq!(www.as_deref(), Some("Bearer"));
    }
}
