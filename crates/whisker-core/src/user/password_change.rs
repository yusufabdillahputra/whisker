//! Ganti password oleh pemilik akun (keputusan owner 2026-10-17, Plan R8): sesi web lain dihapus,
//! sesi saat ini tetap, PAT tetap berlaku.

use sqlx::PgPool;
use uuid::Uuid;

use crate::auth::password::{
    check_password_policy, hash_password_blocking, verify_password_blocking,
};
use crate::error::{CoreError, ValidationErrors};

/// Input form ganti password. `Debug` tidak membocorkan isi.
///
/// Tak ada batas panjang maksimum di sini: panjang input dibatasi oleh limit body HTTP di
/// lapisan web (Task 10) sebelum sampai ke Argon2.
#[derive(Clone, PartialEq, Eq)]
pub struct ChangePassword {
    pub current_password: String,
    pub new_password: String,
    pub new_password_confirmation: String,
}

impl std::fmt::Debug for ChangePassword {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("ChangePassword(<redacted>)")
    }
}

/// Ganti password `user_id`. Semua error validasi dikumpulkan per field (`currentPassword`,
/// `password`, `passwordConfirmation`). Sukses, dalam satu transaksi: hash baru,
/// `must_change_password = false`, `updated_at = now()`, sesi lain milik user dihapus kecuali
/// `current_session`; `access_tokens` tidak disentuh. User tak ada / nonaktif → `NotFound`.
pub async fn change_password(
    pool: &PgPool,
    user_id: Uuid,
    input: ChangePassword,
    current_session: &[u8; 32],
) -> Result<(), CoreError> {
    let stored = sqlx::query_scalar!(
        "SELECT password_hash FROM users WHERE id = $1 AND disabled_at IS NULL",
        user_id,
    )
    .fetch_optional(pool)
    .await?
    .ok_or(CoreError::NotFound)?;

    let mut errors = ValidationErrors::new();
    if !verify_password_blocking(input.current_password, Some(stored)).await {
        errors.add("currentPassword", "Password saat ini salah");
    }
    if check_password_policy(&input.new_password).is_err() {
        errors.add("password", "Password minimal 12 karakter");
    }
    if input.new_password != input.new_password_confirmation {
        errors.add("passwordConfirmation", "Ulangan password tidak cocok");
    }
    if !errors.is_empty() {
        return Err(errors.into());
    }

    let new_hash = hash_password_blocking(input.new_password).await?;
    let mut tx = pool.begin().await?;
    let updated = sqlx::query!(
        "UPDATE users SET password_hash = $2, must_change_password = false, updated_at = now()
         WHERE id = $1 AND disabled_at IS NULL",
        user_id,
        new_hash,
    )
    .execute(&mut *tx)
    .await?
    .rows_affected();
    if updated == 0 {
        return Err(CoreError::NotFound);
    }
    sqlx::query!(
        "DELETE FROM sessions WHERE user_id = $1 AND id_hash <> $2",
        user_id,
        current_session.as_slice(),
    )
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(())
}
