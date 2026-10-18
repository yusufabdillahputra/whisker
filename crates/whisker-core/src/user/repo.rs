//! Repositori tabel `users` (PostgreSQL). `email` bertipe `citext`: dibaca sebagai `email::text`,
//! dibandingkan sebagai `($1::text)::citext` agar case-insensitive.

use sqlx::PgPool;
use time::OffsetDateTime;
use uuid::Uuid;

use super::{AuthRecord, AvatarKey, NewUser, Role, User};
use crate::error::{CoreError, ValidationErrors};

/// Batas panjang `display_name` (karakter, setelah trim) — asumsi Q12.
pub const DISPLAY_NAME_MAX: usize = 80;

/// Baris mentah `users` (tanpa hash); juga dipakai join `session::lookup_session`.
pub(crate) struct UserRow {
    pub(crate) id: Uuid,
    pub(crate) email: String,
    pub(crate) display_name: String,
    pub(crate) avatar_key: String,
    pub(crate) role: String,
    pub(crate) must_change_password: bool,
    pub(crate) created_at: OffsetDateTime,
    pub(crate) disabled_at: Option<OffsetDateTime>,
}

impl TryFrom<UserRow> for User {
    type Error = CoreError;

    fn try_from(r: UserRow) -> Result<Self, CoreError> {
        let avatar_key = r.avatar_key.parse().map_err(|_| {
            CoreError::Internal(format!("avatar_key tak dikenal: {}", r.avatar_key))
        })?;
        Ok(User {
            id: r.id,
            email: r.email,
            display_name: r.display_name,
            avatar_key,
            role: parse_role(&r.role)?,
            must_change_password: r.must_change_password,
            created_at: r.created_at,
            disabled_at: r.disabled_at,
        })
    }
}

fn role_str(role: Role) -> &'static str {
    match role {
        Role::Admin => "admin",
        Role::Member => "member",
    }
}

pub(crate) fn parse_role(s: &str) -> Result<Role, CoreError> {
    match s {
        "admin" => Ok(Role::Admin),
        "member" => Ok(Role::Member),
        other => Err(CoreError::Internal(format!("role tak dikenal: {other}"))),
    }
}

/// Validasi + trim `display_name` (wajib, 1..=80 karakter); error ke field `displayName`.
fn check_display_name<'a>(raw: &'a str, errors: &mut ValidationErrors) -> &'a str {
    let name = raw.trim();
    if name.is_empty() {
        errors.add("displayName", "Nama tampilan wajib diisi");
    } else if name.chars().count() > DISPLAY_NAME_MAX {
        errors.add("displayName", "Nama tampilan maksimal 80 karakter");
    }
    name
}

/// Buat user. `id` UUIDv7 dibuat di Rust agar avatar default (`AvatarKey::default_for(id)`) dapat
/// dihitung sebelum INSERT (`avatar_key` NOT NULL tanpa default).
pub async fn create_user(pool: &PgPool, new: NewUser<'_>) -> Result<User, CoreError> {
    let mut errors = ValidationErrors::new();
    let email = new.email.trim();
    if email.is_empty() {
        errors.add("email", "Email wajib diisi");
    }
    let display_name = check_display_name(new.display_name, &mut errors);
    if !errors.is_empty() {
        return Err(errors.into());
    }

    let id = Uuid::now_v7();
    let avatar_key = AvatarKey::default_for(id);
    let row = sqlx::query_as!(
        UserRow,
        r#"INSERT INTO users (id, email, password_hash, role, must_change_password, display_name, avatar_key)
           VALUES ($1, $2::text, $3, $4, $5, $6, $7)
           RETURNING id, email::text AS "email!", display_name, avatar_key, role,
                     must_change_password, created_at, disabled_at"#,
        id,
        email,
        new.password_hash,
        role_str(new.role),
        new.must_change_password,
        display_name,
        avatar_key.as_str(),
    )
    .fetch_one(pool)
    .await
    .map_err(|e| {
        if e.as_database_error()
            .is_some_and(|d| d.is_unique_violation())
        {
            let mut errors = ValidationErrors::new();
            errors.add("email", "Email sudah dipakai");
            CoreError::Validation(errors)
        } else {
            CoreError::Database(e)
        }
    })?;
    row.try_into()
}

/// Data login berdasarkan email (case-insensitive).
pub async fn find_auth_by_email(
    pool: &PgPool,
    email: &str,
) -> Result<Option<AuthRecord>, CoreError> {
    let rec = sqlx::query!(
        r#"SELECT id, password_hash, disabled_at IS NOT NULL AS "disabled!", must_change_password
           FROM users WHERE email = ($1::text)::citext"#,
        email.trim(),
    )
    .fetch_optional(pool)
    .await?;
    Ok(rec.map(|r| AuthRecord {
        user_id: r.id,
        password_hash: r.password_hash,
        disabled: r.disabled,
        must_change_password: r.must_change_password,
    }))
}

pub async fn get_user(pool: &PgPool, id: Uuid) -> Result<Option<User>, CoreError> {
    sqlx::query_as!(
        UserRow,
        r#"SELECT id, email::text AS "email!", display_name, avatar_key, role,
                  must_change_password, created_at, disabled_at
           FROM users WHERE id = $1"#,
        id,
    )
    .fetch_optional(pool)
    .await?
    .map(User::try_from)
    .transpose()
}

/// Semua user, urut `created_at` naik (id v7 sebagai pemutus seri).
pub async fn list_users(pool: &PgPool) -> Result<Vec<User>, CoreError> {
    sqlx::query_as!(
        UserRow,
        r#"SELECT id, email::text AS "email!", display_name, avatar_key, role,
                  must_change_password, created_at, disabled_at
           FROM users ORDER BY created_at, id"#,
    )
    .fetch_all(pool)
    .await?
    .into_iter()
    .map(User::try_from)
    .collect()
}

pub async fn count_users(pool: &PgPool) -> Result<i64, CoreError> {
    Ok(
        sqlx::query_scalar!(r#"SELECT count(*) AS "count!" FROM users"#)
            .fetch_one(pool)
            .await?,
    )
}

/// Nonaktifkan `target_id` dan hapus semua sesinya dalam satu transaksi. Idempoten
/// (`disabled_at` pertama dipertahankan). Actor = target ditolak.
pub async fn disable_user(pool: &PgPool, actor_id: Uuid, target_id: Uuid) -> Result<(), CoreError> {
    if actor_id == target_id {
        let mut errors = ValidationErrors::new();
        errors.add("user", "Anda tidak dapat menonaktifkan akun sendiri");
        return Err(errors.into());
    }
    let mut tx = pool.begin().await?;
    let updated = sqlx::query!(
        "UPDATE users SET disabled_at = COALESCE(disabled_at, now()), updated_at = now()
         WHERE id = $1",
        target_id,
    )
    .execute(&mut *tx)
    .await?
    .rows_affected();
    if updated == 0 {
        return Err(CoreError::NotFound);
    }
    sqlx::query!("DELETE FROM sessions WHERE user_id = $1", target_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(())
}

/// Ubah nama tampilan + avatar (kunci harus ada di allowlist preset).
pub async fn update_profile(
    pool: &PgPool,
    user_id: Uuid,
    display_name: &str,
    avatar_key: &str,
) -> Result<User, CoreError> {
    let mut errors = ValidationErrors::new();
    let display_name = check_display_name(display_name, &mut errors);
    let avatar = avatar_key.parse::<AvatarKey>().ok();
    if avatar.is_none() {
        errors.add("avatarKey", "Avatar tidak tersedia");
    }
    let Some(avatar) = avatar.filter(|_| errors.is_empty()) else {
        return Err(errors.into());
    };
    sqlx::query_as!(
        UserRow,
        r#"UPDATE users SET display_name = $2, avatar_key = $3, updated_at = now()
           WHERE id = $1
           RETURNING id, email::text AS "email!", display_name, avatar_key, role,
                     must_change_password, created_at, disabled_at"#,
        user_id,
        display_name,
        avatar.as_str(),
    )
    .fetch_optional(pool)
    .await?
    .ok_or(CoreError::NotFound)?
    .try_into()
}
