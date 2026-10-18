//! `GET /account/tokens` (page `Account/Tokens`), `POST /account/tokens` (buat), dan
//! `POST /account/tokens/{id}/revoke`.
//!
//! Token polos tampil sekali tanpa flash di store sesi: `POST` sukses me-render page (`200`, bukan
//! redirect) dengan `createdToken`, `Cache-Control: no-store`, dan `encryptHistory`.

use axum::Extension;
use axum::extract::{Path, State};
use axum::http::header::CACHE_CONTROL;
use axum::http::{HeaderValue, Method};
use axum::response::Response;
use serde::Deserialize;
use ts_rs::TS;
use uuid::Uuid;
use veer::InertiaForm;
use whisker_core::error::CoreError;
use whisker_core::token::{create_token, list_tokens, revoke_token};

use crate::AppState;
use crate::guard::{CurrentUser, redirect};
use crate::page::{
    InertiaCtx, ResponseHeaders, internal_error, render_page, render_page_encrypted,
    render_validation,
};
use crate::props::{AccountTokensProps, CreatedToken, TokenRow};
use crate::routes::errors;

pub const TOKENS_PATH: &str = "/account/tokens";
pub const TOKEN_REVOKE_PATH: &str = "/account/tokens/{id}/revoke";
pub const TOKENS_PAGE: &str = "Account/Tokens";

/// Form buat token. Field hilang = string kosong → `422` di `name`.
#[derive(Debug, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct CreateTokenForm {
    #[serde(default)]
    pub name: String,
}

/// Props page dengan daftar token user saat ini.
async fn props_for(
    state: &AppState,
    user_id: Uuid,
    created_token: Option<CreatedToken>,
) -> Result<AccountTokensProps, CoreError> {
    let tokens = list_tokens(&state.pool, user_id).await?;
    Ok(AccountTokensProps {
        tokens: tokens.iter().map(TokenRow::from).collect(),
        created_token,
    })
}

/// `GET /account/tokens`: tanpa sesi → `/login`. `createdToken` selalu `null`.
pub async fn index(
    State(state): State<AppState>,
    CurrentUser(session): CurrentUser,
    ctx: InertiaCtx,
) -> Response {
    match props_for(&state, session.user.id, None).await {
        Ok(props) => render_page(ctx, TOKENS_PAGE, props),
        Err(e) => {
            tracing::error!(error = %e, "daftar token gagal");
            internal_error()
        }
    }
}

/// `POST /account/tokens`: sukses → `200` page dengan `createdToken` (token polos sekali),
/// `Cache-Control: no-store`, `encryptHistory`. Gagal → `422` di `name`, URL page tetap.
pub async fn store(
    State(state): State<AppState>,
    CurrentUser(session): CurrentUser,
    Extension(extra): Extension<ResponseHeaders>,
    ctx: InertiaCtx,
    InertiaForm(form): InertiaForm<CreateTokenForm>,
) -> Response {
    let user_id = session.user.id;
    let created = match create_token(&state.pool, user_id, &form.name).await {
        Ok((token, plain)) => CreatedToken::new(&token, &plain),
        Err(CoreError::Validation(errors)) => {
            return match props_for(&state, user_id, None).await {
                Ok(props) => render_validation(ctx, Some(TOKENS_PATH), TOKENS_PAGE, props, errors),
                Err(e) => {
                    tracing::error!(error = %e, "daftar token gagal");
                    internal_error()
                }
            };
        }
        Err(e) => {
            tracing::error!(error = %e, "buat token gagal");
            return internal_error();
        }
    };
    let props = match props_for(&state, user_id, Some(created)).await {
        Ok(props) => props,
        Err(e) => {
            tracing::error!(error = %e, "daftar token gagal");
            return internal_error();
        }
    };
    // `InertiaLayer` membangun ulang respons page; header lewat slot `ResponseHeaders`.
    extra.insert(CACHE_CONTROL, HeaderValue::from_static("no-store"));
    render_page_encrypted(ctx, TOKENS_PAGE, props)
}

/// `POST /account/tokens/{id}/revoke`: → `303 /account/tokens` (idempoten). Token tak ada, milik
/// user lain, atau `id` bukan UUID → `404` `Errors/NotFound`.
pub async fn revoke(
    State(state): State<AppState>,
    CurrentUser(session): CurrentUser,
    Path(id): Path<String>,
    ctx: InertiaCtx,
) -> Response {
    let Ok(token_id) = Uuid::parse_str(&id) else {
        return errors::not_found(ctx).await;
    };
    match revoke_token(&state.pool, session.user.id, token_id).await {
        Ok(()) => redirect(&Method::POST, TOKENS_PATH),
        Err(CoreError::NotFound) => errors::not_found(ctx).await,
        Err(e) => {
            tracing::error!(error = %e, "revoke token gagal");
            internal_error()
        }
    }
}
