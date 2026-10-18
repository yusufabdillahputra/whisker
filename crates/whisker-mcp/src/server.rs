//! Server MCP `WhiskerMcp`: tool `whoami` dan `list_vaults`. Identitas pemanggil diambil dari
//! extension `McpPrincipal` (dipasang `bearer_auth`) di `http::request::Parts` yang disuntikkan rmcp.

use rmcp::handler::server::router::tool::ToolRouter;
use rmcp::handler::server::tool::Extension;
use rmcp::model::{Implementation, ServerCapabilities, ServerConfig};
use rmcp::{ErrorData as McpError, Json, ServerHandler, tool, tool_handler, tool_router};
use serde::Serialize;
use sqlx::PgPool;
use uuid::Uuid;
use whisker_core::token::TokenPrincipal;
use whisker_core::user::Role;

use crate::auth::McpPrincipal;

/// Output `whoami` (asumsi Q21).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, schemars::JsonSchema)]
pub struct WhoamiOutput {
    pub email: String,
    pub role: Role,
}

/// Satu project milik pemilik token.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, schemars::JsonSchema)]
pub struct VaultItem {
    pub id: Uuid,
    pub slug: String,
    pub name: String,
}

/// Output `list_vaults` (asumsi Q21).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, schemars::JsonSchema)]
pub struct ListVaultsOutput {
    pub vaults: Vec<VaultItem>,
}

#[derive(Clone)]
pub struct WhiskerMcp {
    pool: PgPool,
    tool_router: ToolRouter<Self>,
}

/// Principal dari `Parts`; tak ada = `bearer_auth` tidak terpasang (bug perakitan router).
fn principal(parts: &http::request::Parts) -> Result<&TokenPrincipal, McpError> {
    parts
        .extensions
        .get::<McpPrincipal>()
        .map(|p| &p.0)
        .ok_or_else(|| McpError::internal_error("principal tidak tersedia", None))
}

#[tool_router]
impl WhiskerMcp {
    pub fn new(pool: PgPool) -> Self {
        Self {
            pool,
            tool_router: Self::tool_router(),
        }
    }

    #[tool(description = "Identitas pemilik token akses: email dan role akun Whisker.")]
    async fn whoami(
        &self,
        Extension(parts): Extension<http::request::Parts>,
    ) -> Result<Json<WhoamiOutput>, McpError> {
        let p = principal(&parts)?;
        Ok(Json(WhoamiOutput {
            email: p.email.clone(),
            role: p.role,
        }))
    }

    #[tool(description = "Daftar project (vault) milik pemilik token akses.")]
    async fn list_vaults(
        &self,
        Extension(parts): Extension<http::request::Parts>,
    ) -> Result<Json<ListVaultsOutput>, McpError> {
        let owner = principal(&parts)?.user_id;
        let vaults = whisker_core::vault::list_vaults(&self.pool, owner)
            .await
            .map_err(|e| {
                tracing::error!(error = %e, "mcp: list_vaults gagal");
                McpError::internal_error("gagal memuat project", None)
            })?;
        Ok(Json(ListVaultsOutput {
            vaults: vaults
                .into_iter()
                .map(|v| VaultItem {
                    id: v.id,
                    slug: v.slug,
                    name: v.name,
                })
                .collect(),
        }))
    }
}

#[tool_handler(router = self.tool_router)]
impl ServerHandler for WhiskerMcp {
    fn get_info(&self) -> ServerConfig {
        ServerConfig::new(ServerCapabilities::builder().enable_tools().build())
            .with_server_info(Implementation::new("whisker", env!("CARGO_PKG_VERSION")))
    }
}
