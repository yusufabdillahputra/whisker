//! Pool PostgreSQL + migration saat startup (ADR-007).
//!
//! Konvensi tes DB (ruling K2): `MIGRATOR` hanya ada di crate bin ini. Tes `#[sqlx::test]` di crate
//! lain (`whisker-core`, `whisker-web`, `whisker-mcp`) memakai
//! `#[sqlx::test(migrations = "../../migrations")]`, karena default-nya mencari `./migrations` per crate.

use sqlx::PgPool;
use sqlx::migrate::{MigrateError, Migrator};
use sqlx::postgres::PgPoolOptions;
use std::time::Duration;

/// Migration ter-embed dari `migrations/` root workspace.
/// `build.rs` memicu kompilasi ulang bila folder itu berubah.
pub static MIGRATOR: Migrator = sqlx::migrate!("../../migrations");

const MAX_CONNECTIONS: u32 = 10;
const ACQUIRE_TIMEOUT: Duration = Duration::from_secs(5);

/// Buka pool dan pastikan DB terjangkau (koneksi pertama dibuat sekarang, bukan lazily).
pub async fn connect_pool(database_url: &str) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(MAX_CONNECTIONS)
        .acquire_timeout(ACQUIRE_TIMEOUT)
        .connect(database_url)
        .await
}

/// Jalankan migration yang belum diterapkan. Locking default sqlx = `pg_advisory_lock`, jadi beberapa
/// proses yang start bersamaan tidak menerapkan migration ganda; tiap migration dalam transaksinya sendiri.
pub async fn run_migrations(pool: &PgPool) -> Result<(), MigrateError> {
    MIGRATOR.run(pool).await
}

/// Versi migration sukses terbaru; `None` bila belum ada migration (termasuk tabel
/// `_sqlx_migrations` belum dibuat).
pub async fn latest_migration_version(pool: &PgPool) -> Result<Option<i64>, sqlx::Error> {
    let exists =
        sqlx::query_scalar!(r#"SELECT to_regclass('_sqlx_migrations') IS NOT NULL AS "exists!""#)
            .fetch_one(pool)
            .await?;
    if !exists {
        return Ok(None);
    }
    sqlx::query_scalar!("SELECT max(version) FROM _sqlx_migrations WHERE success")
        .fetch_one(pool)
        .await
}
