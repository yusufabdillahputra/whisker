//! Store sesi web (ADR-011 c): tabel `sessions`, id mentah hanya di cookie, DB menyimpan SHA-256.
//! Sliding `SESSION_TTL`; perpanjangan paling sering 1× per `SESSION_TOUCH_INTERVAL`.

use sqlx::PgPool;
use sqlx::postgres::types::PgInterval;
use uuid::Uuid;

use crate::auth::session_id::{SessionId, generate_session_id, session_id_hash};
use crate::error::CoreError;
use crate::user::User;
use crate::user::repo::UserRow;

/// Umur sesi sejak aktivitas terakhir yang tercatat (sliding).
pub const SESSION_TTL: time::Duration = time::Duration::days(30);

/// Jarak minimum antar perpanjangan `expires_at` (membatasi tulis DB per request).
pub const SESSION_TOUCH_INTERVAL: time::Duration = time::Duration::hours(1);

/// `time::Duration` → `interval` PostgreSQL (mikrodetik; konstanta di atas tak punya sisa nano).
fn pg_interval(d: time::Duration) -> PgInterval {
    PgInterval {
        months: 0,
        days: 0,
        microseconds: d.whole_microseconds() as i64,
    }
}

/// Hasil `lookup_session` yang valid. `extended = true` → `expires_at` baru saja digeser; lapisan
/// web menerbitkan ulang cookie (Task 10).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SessionUser {
    pub session_hash: [u8; 32],
    pub user: User,
    pub extended: bool,
}

/// Buat sesi baru untuk `user_id` (saat login) dan hapus sesi kedaluwarsa milik user tersebut
/// dalam satu transaksi. Id mentah dikembalikan sekali untuk cookie; DB hanya menyimpan hash.
pub async fn create_session(pool: &PgPool, user_id: Uuid) -> Result<SessionId, CoreError> {
    let sid = generate_session_id();
    let hash = session_id_hash(sid.as_str());
    let mut tx = pool.begin().await?;
    sqlx::query!(
        "DELETE FROM sessions WHERE user_id = $1 AND expires_at <= now()",
        user_id,
    )
    .execute(&mut *tx)
    .await?;
    sqlx::query!(
        "INSERT INTO sessions (id_hash, user_id, expires_at) VALUES ($1, $2, now() + $3::interval)",
        hash.as_slice(),
        user_id,
        pg_interval(SESSION_TTL),
    )
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(sid)
}

/// Cari sesi dari id mentah cookie. `None` bila tak ada, kedaluwarsa (baris dihapus), atau user
/// nonaktif. Bila `last_seen_at` sudah ≥ `SESSION_TOUCH_INTERVAL` lalu, `expires_at` digeser ke
/// `now() + SESSION_TTL` dan `extended = true`.
pub async fn lookup_session(pool: &PgPool, raw_id: &str) -> Result<Option<SessionUser>, CoreError> {
    let hash = session_id_hash(raw_id);
    let Some(rec) = sqlx::query!(
        r#"SELECT s.expires_at <= now() AS "expired!",
                  s.last_seen_at <= now() - $2::interval AS "stale!",
                  u.id, u.email::text AS "email!", u.display_name, u.avatar_key, u.role,
                  u.must_change_password, u.created_at, u.disabled_at
           FROM sessions s JOIN users u ON u.id = s.user_id
           WHERE s.id_hash = $1 AND u.disabled_at IS NULL"#,
        hash.as_slice(),
        pg_interval(SESSION_TOUCH_INTERVAL),
    )
    .fetch_optional(pool)
    .await?
    else {
        return Ok(None);
    };

    if rec.expired {
        delete_session(pool, &hash).await?;
        return Ok(None);
    }

    let extended = rec.stale
        && sqlx::query!(
            "UPDATE sessions SET expires_at = now() + $2::interval, last_seen_at = now()
             WHERE id_hash = $1 AND last_seen_at <= now() - $3::interval",
            hash.as_slice(),
            pg_interval(SESSION_TTL),
            pg_interval(SESSION_TOUCH_INTERVAL),
        )
        .execute(pool)
        .await?
        .rows_affected()
            > 0;

    let user = User::try_from(UserRow {
        id: rec.id,
        email: rec.email,
        display_name: rec.display_name,
        avatar_key: rec.avatar_key,
        role: rec.role,
        must_change_password: rec.must_change_password,
        created_at: rec.created_at,
        disabled_at: rec.disabled_at,
    })?;
    Ok(Some(SessionUser {
        session_hash: hash,
        user,
        extended,
    }))
}

/// Hapus satu sesi (logout). Idempoten.
pub async fn delete_session(pool: &PgPool, session_hash: &[u8; 32]) -> Result<(), CoreError> {
    sqlx::query!(
        "DELETE FROM sessions WHERE id_hash = $1",
        session_hash.as_slice()
    )
    .execute(pool)
    .await?;
    Ok(())
}

/// Hapus semua sesi user; mengembalikan jumlah baris terhapus.
pub async fn delete_user_sessions(pool: &PgPool, user_id: Uuid) -> Result<u64, CoreError> {
    Ok(
        sqlx::query!("DELETE FROM sessions WHERE user_id = $1", user_id)
            .execute(pool)
            .await?
            .rows_affected(),
    )
}

/// Hapus semua sesi user kecuali `keep`; mengembalikan jumlah baris terhapus.
pub async fn delete_other_sessions(
    pool: &PgPool,
    user_id: Uuid,
    keep: &[u8; 32],
) -> Result<u64, CoreError> {
    Ok(sqlx::query!(
        "DELETE FROM sessions WHERE user_id = $1 AND id_hash <> $2",
        user_id,
        keep.as_slice(),
    )
    .execute(pool)
    .await?
    .rows_affected())
}
