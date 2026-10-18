//! Migration saat startup: start pertama menerapkan migration awal, start berikutnya no-op (S4).

use sqlx::PgPool;
use whisker::startup::{MIGRATOR, latest_migration_version, run_migrations};

#[sqlx::test(migrations = false)]
async fn first_run_applies_init_then_noop(pool: PgPool) {
    assert_eq!(latest_migration_version(&pool).await.unwrap(), None);

    run_migrations(&pool).await.unwrap();
    run_migrations(&pool).await.unwrap();

    let rows: Vec<(i64, String, bool)> =
        sqlx::query_as("SELECT version, description, success FROM _sqlx_migrations")
            .fetch_all(&pool)
            .await
            .unwrap();
    assert_eq!(rows.len(), 1, "migration: {rows:?}");
    let (version, description, success) = &rows[0];
    assert_eq!(description, "fondasi init");
    assert!(success);

    let expected = MIGRATOR.iter().map(|m| m.version).max();
    assert_eq!(Some(*version), expected);
    assert_eq!(latest_migration_version(&pool).await.unwrap(), expected);
}

#[sqlx::test(migrations = false)]
async fn concurrent_starts_apply_init_once(pool: PgPool) {
    // Dua proses start bersamaan: advisory lock sqlx menyerialkan, migration tetap satu kali.
    let (a, b) = tokio::join!(run_migrations(&pool), run_migrations(&pool));
    a.unwrap();
    b.unwrap();
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM _sqlx_migrations")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(n, 1);
}
