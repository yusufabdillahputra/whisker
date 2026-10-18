//! Kontrak `/mcp` (Task 09) terhadap PostgreSQL nyata (ruling K2) dan server axum di `127.0.0.1:0`,
//! diakses lewat client `rmcp` ber-Bearer dan HTTP mentah.

use rmcp::ServiceExt;
use rmcp::model::{CallToolRequestParams, ClientConfig};
use rmcp::service::{RoleClient, RunningService};
use rmcp::transport::StreamableHttpClientTransport;
use rmcp::transport::streamable_http_client::StreamableHttpClientTransportConfig;
use serde_json::{Value, json};
use sqlx::PgPool;
use time::OffsetDateTime;
use uuid::Uuid;
use whisker_core::token::{create_token, revoke_token};
use whisker_core::user::{NewUser, Role, User, create_user, disable_user};
use whisker_core::vault::{NewVault, create_vault};
use whisker_mcp::{McpConfig, mcp_router};

const ORIGIN: &str = "http://localhost:8080";
const ACCEPT: &str = "application/json, text/event-stream";
const TOOLS_LIST: &str = r#"{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}"#;

async fn create(pool: &PgPool, email: &str, role: Role) -> User {
    create_user(
        pool,
        NewUser {
            email,
            display_name: "Pengguna",
            password_hash: "$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA".to_owned(),
            role,
            must_change_password: false,
        },
    )
    .await
    .unwrap()
}

/// Token mentah baru untuk `user_id` (hanya di memori tes).
async fn token_for(pool: &PgPool, user_id: Uuid) -> (Uuid, String) {
    let (tok, plain) = create_token(pool, user_id, "CLI").await.unwrap();
    (tok.id, plain.expose().to_owned())
}

/// Jalankan `mcp_router` di port acak; kembalikan URL `/mcp`.
async fn spawn(pool: PgPool) -> String {
    let app = mcp_router(
        pool,
        McpConfig {
            allowed_origin: Some(ORIGIN.to_owned()),
        },
    );
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });
    format!("http://{addr}/mcp")
}

async fn client(url: &str, token: &str) -> RunningService<RoleClient, ClientConfig> {
    let transport = StreamableHttpClientTransport::from_config(
        StreamableHttpClientTransportConfig::with_uri(url).auth_header(token),
    );
    ClientConfig::default().serve(transport).await.unwrap()
}

async fn call(c: &RunningService<RoleClient, ClientConfig>, tool: &'static str) -> Value {
    let res = c.call_tool(CallToolRequestParams::new(tool)).await.unwrap();
    assert_ne!(res.is_error, Some(true), "tool {tool} error: {res:?}");
    res.structured_content.expect("structured_content")
}

fn post(url: &str) -> reqwest::RequestBuilder {
    reqwest::Client::new()
        .post(url)
        .header("content-type", "application/json")
        .header("accept", ACCEPT)
        .body(TOOLS_LIST)
}

async fn last_used_at(pool: &PgPool, id: Uuid) -> Option<OffsetDateTime> {
    sqlx::query_scalar("SELECT last_used_at FROM access_tokens WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .unwrap()
}

fn assert_401(res: &reqwest::Response) {
    assert_eq!(res.status(), 401);
    assert_eq!(
        res.headers()
            .get("www-authenticate")
            .map(|v| v.to_str().unwrap()),
        Some("Bearer")
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn no_bearer_gets_401(pool: PgPool) {
    let url = spawn(pool).await;
    let res = post(&url).send().await.unwrap();
    assert_401(&res);
    assert_eq!(res.text().await.unwrap(), r#"{"error":"unauthorized"}"#);
}

#[sqlx::test(migrations = "../../migrations")]
async fn revoked_token_gets_401(pool: PgPool) {
    let u = create(&pool, "ani@example.com", Role::Member).await;
    let (id, token) = token_for(&pool, u.id).await;
    revoke_token(&pool, u.id, id).await.unwrap();
    let url = spawn(pool).await;
    let res = post(&url).bearer_auth(&token).send().await.unwrap();
    assert_401(&res);
}

#[sqlx::test(migrations = "../../migrations")]
async fn disabled_user_token_gets_401(pool: PgPool) {
    let admin = create(&pool, "admin@example.com", Role::Admin).await;
    let u = create(&pool, "ani@example.com", Role::Member).await;
    let (_, token) = token_for(&pool, u.id).await;
    disable_user(&pool, admin.id, u.id).await.unwrap();
    let url = spawn(pool).await;
    let res = post(&url).bearer_auth(&token).send().await.unwrap();
    assert_401(&res);
}

#[sqlx::test(migrations = "../../migrations")]
async fn foreign_origin_gets_403(pool: PgPool) {
    let u = create(&pool, "ani@example.com", Role::Member).await;
    let (_, token) = token_for(&pool, u.id).await;
    let url = spawn(pool).await;
    let res = post(&url)
        .bearer_auth(&token)
        .header("origin", "https://evil.example")
        .send()
        .await
        .unwrap();
    assert_eq!(res.status(), 403);

    let res = post(&url)
        .bearer_auth(&token)
        .header("origin", ORIGIN)
        .send()
        .await
        .unwrap();
    assert_eq!(res.status(), 200);
}

#[sqlx::test(migrations = "../../migrations")]
async fn whoami_returns_owner_email_and_role(pool: PgPool) {
    let u = create(&pool, "ani@example.com", Role::Admin).await;
    let (_, token) = token_for(&pool, u.id).await;
    let url = spawn(pool).await;
    let c = client(&url, &token).await;

    let tools = c.list_all_tools().await.unwrap();
    let mut names: Vec<&str> = tools.iter().map(|t| t.name.as_ref()).collect();
    names.sort();
    assert_eq!(names, ["list_vaults", "whoami"]);
    assert!(tools.iter().all(|t| t.output_schema.is_some()));

    assert_eq!(
        call(&c, "whoami").await,
        json!({ "email": "ani@example.com", "role": "admin" })
    );
    c.cancel().await.unwrap();
}

#[sqlx::test(migrations = "../../migrations")]
async fn list_vaults_returns_only_owner_vaults(pool: PgPool) {
    let ani = create(&pool, "ani@example.com", Role::Member).await;
    let budi = create(&pool, "budi@example.com", Role::Member).await;
    let a1 = create_vault(
        &pool,
        ani.id,
        NewVault {
            name: "Riset",
            icon: "brain",
        },
    )
    .await
    .unwrap();
    let a2 = create_vault(
        &pool,
        ani.id,
        NewVault {
            name: "Catatan Harian",
            icon: "book",
        },
    )
    .await
    .unwrap();
    create_vault(
        &pool,
        budi.id,
        NewVault {
            name: "Rahasia Budi",
            icon: "folder",
        },
    )
    .await
    .unwrap();
    let (_, token) = token_for(&pool, ani.id).await;
    let url = spawn(pool).await;
    let c = client(&url, &token).await;

    assert_eq!(
        call(&c, "list_vaults").await,
        json!({ "vaults": [
            { "id": a1.id, "slug": "riset", "name": "Riset" },
            { "id": a2.id, "slug": "catatan-harian", "name": "Catatan Harian" },
        ] })
    );
    c.cancel().await.unwrap();
}

#[sqlx::test(migrations = "../../migrations")]
async fn stateless_sequential_requests_without_session_header(pool: PgPool) {
    let u = create(&pool, "ani@example.com", Role::Member).await;
    let (_, token) = token_for(&pool, u.id).await;
    let url = spawn(pool).await;
    for _ in 0..2 {
        let res = post(&url).bearer_auth(&token).send().await.unwrap();
        assert_eq!(res.status(), 200);
        assert!(res.headers().get("mcp-session-id").is_none());
        let body: Value = res.json().await.unwrap();
        let names: Vec<&str> = body["result"]["tools"]
            .as_array()
            .expect("result.tools")
            .iter()
            .map(|t| t["name"].as_str().unwrap())
            .collect();
        assert!(names.contains(&"whoami"), "{body}");
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn last_used_at_updated_after_call(pool: PgPool) {
    let u = create(&pool, "ani@example.com", Role::Member).await;
    let (id, token) = token_for(&pool, u.id).await;
    assert!(last_used_at(&pool, id).await.is_none());
    let url = spawn(pool.clone()).await;
    let c = client(&url, &token).await;
    call(&c, "whoami").await;
    c.cancel().await.unwrap();
    assert!(last_used_at(&pool, id).await.is_some());
}
