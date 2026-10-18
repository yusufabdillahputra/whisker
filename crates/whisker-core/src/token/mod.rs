//! Repositori Personal Access Token (ADR-004): tabel `access_tokens`. DB hanya menyimpan SHA-256
//! token + `display_prefix`; token mentah dikembalikan sekali saat dibuat. Revoke permanen.
//! `last_used_at` ditulis paling sering 1× per `LAST_USED_INTERVAL`. Validasi format token
//! (`auth::pat::parse_token`) dilakukan pemanggil sebelum `authenticate_token` — tanpa query DB.

use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use sqlx::postgres::types::PgInterval;
use time::OffsetDateTime;
use ts_rs::TS;
use uuid::Uuid;

use crate::auth::pat::{PlainToken, display_prefix, generate_token, token_hash};
use crate::error::{CoreError, ValidationErrors};
use crate::user::Role;
use crate::user::repo::parse_role;

/// Batas panjang nama token (karakter, setelah trim) — asumsi Q12.
pub const TOKEN_NAME_MAX: usize = 100;

/// Jarak minimum antar penulisan `last_used_at` (membatasi tulis DB per request MCP).
pub const LAST_USED_INTERVAL: time::Duration = time::Duration::minutes(1);

/// `time::Duration` → `interval` PostgreSQL (mikrodetik; konstanta di atas tak punya sisa nano).
fn pg_interval(d: time::Duration) -> PgInterval {
    PgInterval {
        months: 0,
        days: 0,
        microseconds: d.whole_microseconds() as i64,
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "lowercase")]
pub enum TokenStatus {
    Active,
    Revoked,
}

/// Baris `access_tokens` tanpa hash.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AccessToken {
    pub id: Uuid,
    pub name: String,
    pub display_prefix: String,
    pub created_at: OffsetDateTime,
    pub last_used_at: Option<OffsetDateTime>,
    pub revoked_at: Option<OffsetDateTime>,
}

impl AccessToken {
    pub fn status(&self) -> TokenStatus {
        if self.revoked_at.is_some() {
            TokenStatus::Revoked
        } else {
            TokenStatus::Active
        }
    }
}

/// Identitas pemanggil hasil `authenticate_token` (dibungkus `McpPrincipal` di Task 09).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TokenPrincipal {
    pub token_id: Uuid,
    pub user_id: Uuid,
    pub email: String,
    pub role: Role,
}

/// Buat token untuk `user_id`. `name` di-trim, wajib 1..=100 karakter (error ke field `name`).
/// Token mentah dikembalikan sekali; DB hanya menyimpan SHA-256 + 12 karakter pertama.
pub async fn create_token(
    pool: &PgPool,
    user_id: Uuid,
    name: &str,
) -> Result<(AccessToken, PlainToken), CoreError> {
    let name = name.trim();
    let mut errors = ValidationErrors::new();
    if name.is_empty() {
        errors.add("name", "Nama token wajib diisi");
    } else if name.chars().count() > TOKEN_NAME_MAX {
        errors.add("name", "Nama token maksimal 100 karakter");
    }
    if !errors.is_empty() {
        return Err(errors.into());
    }

    let plain = generate_token();
    let hash = token_hash(plain.expose());
    let token = sqlx::query_as!(
        AccessToken,
        r#"INSERT INTO access_tokens (user_id, name, display_prefix, token_hash)
           VALUES ($1, $2, $3, $4)
           RETURNING id, name, display_prefix, created_at, last_used_at, revoked_at"#,
        user_id,
        name,
        display_prefix(&plain),
        hash.as_slice(),
    )
    .fetch_one(pool)
    .await?;
    Ok((token, plain))
}

/// Token milik `user_id` (aktif dan tercabut), urut `created_at` turun (asumsi Q25).
pub async fn list_tokens(pool: &PgPool, user_id: Uuid) -> Result<Vec<AccessToken>, CoreError> {
    Ok(sqlx::query_as!(
        AccessToken,
        r#"SELECT id, name, display_prefix, created_at, last_used_at, revoked_at
           FROM access_tokens WHERE user_id = $1
           ORDER BY created_at DESC, id DESC"#,
        user_id,
    )
    .fetch_all(pool)
    .await?)
}

/// Cabut token milik `user_id`. Permanen dan idempoten (`revoked_at` pertama dipertahankan).
/// Token tak ada atau milik user lain → `NotFound`.
pub async fn revoke_token(pool: &PgPool, user_id: Uuid, token_id: Uuid) -> Result<(), CoreError> {
    let updated = sqlx::query!(
        "UPDATE access_tokens SET revoked_at = COALESCE(revoked_at, now())
         WHERE id = $1 AND user_id = $2",
        token_id,
        user_id,
    )
    .execute(pool)
    .await?
    .rows_affected();
    if updated == 0 {
        return Err(CoreError::NotFound);
    }
    Ok(())
}

/// Cari token dari SHA-256-nya. `None` bila tak ada, tercabut, atau user nonaktif. Bila valid,
/// `last_used_at` ditulis `now()` hanya jika kosong atau sudah > `LAST_USED_INTERVAL` lalu —
/// satu round-trip (CTE).
pub async fn authenticate_token(
    pool: &PgPool,
    hash: &[u8; 32],
) -> Result<Option<TokenPrincipal>, CoreError> {
    let Some(rec) = sqlx::query!(
        r#"WITH hit AS (
               SELECT t.id, t.user_id, u.email::text AS email, u.role
               FROM access_tokens t JOIN users u ON u.id = t.user_id
               WHERE t.token_hash = $1 AND t.revoked_at IS NULL AND u.disabled_at IS NULL
           ), touch AS (
               UPDATE access_tokens SET last_used_at = now()
               WHERE id IN (SELECT id FROM hit)
                 AND (last_used_at IS NULL OR last_used_at < now() - $2::interval)
           )
           SELECT id AS "id!", user_id AS "user_id!", email AS "email!", role AS "role!"
           FROM hit"#,
        hash.as_slice(),
        pg_interval(LAST_USED_INTERVAL),
    )
    .fetch_optional(pool)
    .await?
    else {
        return Ok(None);
    };
    Ok(Some(TokenPrincipal {
        token_id: rec.id,
        user_id: rec.user_id,
        email: rec.email,
        role: parse_role(&rec.role)?,
    }))
}
