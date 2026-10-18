//! Bootstrap admin pertama via env saat startup (ADR-011 e): `users` kosong → buat admin dari
//! `WHISKER_ADMIN_EMAIL`/`WHISKER_ADMIN_PASSWORD` (`must_change_password = true`); env tak lengkap →
//! gagal cepat. `users` berisi → env diabaikan (peringatan bila password masih terisi).
//! Diserialkan `pg_advisory_xact_lock` agar dua container yang start bersamaan tak membuat admin ganda.

use std::fmt;

use sqlx::PgPool;
use uuid::Uuid;
use whisker_core::auth::password::{check_password_policy, hash_password_blocking};
use whisker_core::error::CoreError;
use whisker_core::user::{NewUser, Role, count_users, create_user};

use crate::config::{BootstrapEnv, is_placeholder};

/// Kunci advisory lock bootstrap (ASCII "WHKBOOT1"); berbeda dari kunci migration sqlx.
const BOOTSTRAP_LOCK_KEY: i64 = 0x5748_4B42_4F4F_5431;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum BootstrapOutcome {
    CreatedAdmin { user_id: Uuid },
    Skipped,
    SkippedWithLingeringPassword,
}

#[derive(Debug)]
pub enum BootstrapError {
    /// `users` kosong dan email/password admin kosong, tidak ada, atau masih placeholder `<...>`.
    MissingAdminEnv,
    /// Password admin di bawah kebijakan minimum (asumsi Q13).
    WeakPassword,
    Core(CoreError),
}

impl fmt::Display for BootstrapError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::MissingAdminEnv => f.write_str(
                "tabel users kosong: isi WHISKER_ADMIN_EMAIL dan WHISKER_ADMIN_PASSWORD \
                 (tidak boleh kosong atau placeholder <...>) untuk membuat admin pertama",
            ),
            Self::WeakPassword => f.write_str(
                "WHISKER_ADMIN_PASSWORD terlalu pendek: password admin minimal 12 karakter",
            ),
            Self::Core(e) => write!(f, "bootstrap admin gagal: {e}"),
        }
    }
}

impl std::error::Error for BootstrapError {}

impl From<CoreError> for BootstrapError {
    fn from(e: CoreError) -> Self {
        Self::Core(e)
    }
}

impl From<sqlx::Error> for BootstrapError {
    fn from(e: sqlx::Error) -> Self {
        Self::Core(CoreError::Database(e))
    }
}

/// Bagian lokal email (sebelum `@` terakhir); tanpa `@` → seluruh string.
pub fn email_local_part(email: &str) -> &str {
    email.rsplit_once('@').map_or(email, |(local, _)| local)
}

/// Jalankan bootstrap admin di bawah advisory lock transaksi.
pub async fn bootstrap_admin(
    pool: &PgPool,
    env: &BootstrapEnv,
) -> Result<BootstrapOutcome, BootstrapError> {
    // Lock dipegang koneksi transaksi ini sampai commit/rollback (drop); insert lewat pool sudah
    // ter-commit sebelum lock lepas, jadi peserta berikutnya melihat `users` berisi.
    let mut tx = pool.begin().await?;
    sqlx::query("SELECT pg_advisory_xact_lock($1)")
        .bind(BOOTSTRAP_LOCK_KEY)
        .execute(&mut *tx)
        .await?;

    let outcome = if count_users(pool).await? > 0 {
        if env.password.is_some() {
            tracing::warn!(
                "tabel users sudah berisi: WHISKER_ADMIN_PASSWORD diabaikan — hapus password dari panel env"
            );
            BootstrapOutcome::SkippedWithLingeringPassword
        } else {
            BootstrapOutcome::Skipped
        }
    } else {
        let (Some(email), Some(password)) = (env.email.as_deref(), env.password.as_deref()) else {
            return Err(BootstrapError::MissingAdminEnv);
        };
        if is_placeholder(email) || is_placeholder(password) {
            return Err(BootstrapError::MissingAdminEnv);
        }
        check_password_policy(password).map_err(|_| BootstrapError::WeakPassword)?;
        let password_hash = hash_password_blocking(password.to_owned()).await?;
        let user = create_user(
            pool,
            NewUser {
                email,
                display_name: email_local_part(email),
                password_hash,
                role: Role::Admin,
                must_change_password: true,
            },
        )
        .await?;
        tracing::info!(user_id = %user.id, email = %user.email, "admin pertama dibuat dari env (wajib ganti password)");
        BootstrapOutcome::CreatedAdmin { user_id: user.id }
    };
    tx.commit().await?;
    Ok(outcome)
}
