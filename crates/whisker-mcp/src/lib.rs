//! Server MCP Whisker (rmcp, ADR-011): `/mcp` stateless ber-Bearer PAT.

pub mod auth;
pub mod server;

use std::sync::Arc;

use axum::Router;
use axum::middleware::from_fn_with_state;
use rmcp::transport::streamable_http_server::session::never::NeverSessionManager;
use rmcp::transport::streamable_http_server::{StreamableHttpServerConfig, StreamableHttpService};
use sqlx::PgPool;

pub use auth::{
    McpConfig, McpPrincipal, PgTokenAuthenticator, TokenAuthenticator, bearer_auth, origin_guard,
};
pub use server::{ListVaultsOutput, VaultItem, WhiskerMcp, WhoamiOutput};

/// Router `/mcp`: cek `Origin` → Bearer PAT → `StreamableHttpService` stateless
/// (`NeverSessionManager`, `legacy_session_mode = false`, respons `application/json`).
///
/// Validasi `Host` bawaan rmcp (default hanya loopback) dimatikan: deployment publik memakai host
/// `WHISKER_PUBLIC_URL`, dan proteksi DNS rebinding sudah dipenuhi cek `Origin` + Bearer PAT wajib.
pub fn mcp_router(pool: PgPool, cfg: McpConfig) -> Router {
    let service_pool = pool.clone();
    let service = StreamableHttpService::new(
        move || Ok(WhiskerMcp::new(service_pool.clone())),
        Arc::new(NeverSessionManager::default()),
        StreamableHttpServerConfig::default()
            .with_legacy_session_mode(false)
            .with_json_response(true)
            .with_sse_keep_alive(None)
            .disable_allowed_hosts(),
    );
    Router::new()
        .route_service("/mcp", service)
        .layer(from_fn_with_state(
            PgTokenAuthenticator::new(pool),
            bearer_auth::<PgTokenAuthenticator>,
        ))
        .layer(from_fn_with_state(cfg, origin_guard))
}
