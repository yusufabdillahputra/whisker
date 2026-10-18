use assert_cmd::Command;

#[test]
fn serve_with_missing_env_exits_non_zero_and_names_variable() {
    let out = Command::cargo_bin("whisker")
        .unwrap()
        .env_clear()
        .arg("serve")
        .assert()
        .failure()
        .get_output()
        .clone();
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(stderr.contains("DATABASE_URL"), "stderr: {stderr}");
}

/// URL database sementara milik `#[sqlx::test]` (host/kredensial dari `DATABASE_URL`, nama DB diganti).
async fn temp_database_url(pool: &sqlx::PgPool) -> String {
    let name: String = sqlx::query_scalar("SELECT current_database()::text")
        .fetch_one(pool)
        .await
        .unwrap();
    let base = std::env::var("DATABASE_URL").expect("DATABASE_URL untuk tes DB");
    let mut url = url::Url::parse(&base).expect("DATABASE_URL valid");
    url.set_path(&name);
    url.to_string()
}

/// B2: tabel `users` kosong tanpa env admin → `serve` keluar non-zero sebelum bind, pesan menyebut env.
#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn serve_on_empty_db_without_admin_env_exits_non_zero(pool: sqlx::PgPool) {
    let db = temp_database_url(&pool).await;
    let out = tokio::task::spawn_blocking(move || {
        Command::cargo_bin("whisker")
            .unwrap()
            .env_clear()
            .env("DATABASE_URL", db)
            .env("WHISKER_PUBLIC_URL", "http://127.0.0.1:8080")
            .env("WHISKER_HTTP_ADDR", "127.0.0.1:0")
            .arg("serve")
            .timeout(std::time::Duration::from_secs(30))
            .assert()
            .failure()
            .get_output()
            .clone()
    })
    .await
    .unwrap();
    let stderr = String::from_utf8_lossy(&out.stderr);
    assert!(
        stderr.contains("WHISKER_ADMIN_EMAIL") && stderr.contains("WHISKER_ADMIN_PASSWORD"),
        "stderr: {stderr}"
    );
    let users: i64 = sqlx::query_scalar("SELECT count(*) FROM users")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(users, 0);
}
