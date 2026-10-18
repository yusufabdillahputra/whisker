//! Isi migration awal Fondasi (S5, A7): kolom, default, konstrain, aturan FK.

use sqlx::PgPool;

/// (kolom, udt_name, is_nullable, column_default), urut nama kolom.
type Column = (String, String, String, Option<String>);

async fn columns(pool: &PgPool, table: &str) -> Vec<Column> {
    sqlx::query_as(
        "SELECT column_name::text, udt_name::text, is_nullable::text, column_default::text
         FROM information_schema.columns
         WHERE table_schema = current_schema() AND table_name = $1
         ORDER BY column_name",
    )
    .bind(table)
    .fetch_all(pool)
    .await
    .unwrap()
}

fn expected(cols: &[(&str, &str, bool, Option<&str>)]) -> Vec<Column> {
    let mut v: Vec<Column> = cols
        .iter()
        .map(|(n, t, nullable, d)| {
            (
                n.to_string(),
                t.to_string(),
                if *nullable { "YES" } else { "NO" }.to_string(),
                d.map(str::to_string),
            )
        })
        .collect();
    v.sort();
    v
}

fn sqlstate(err: sqlx::Error) -> String {
    err.as_database_error()
        .and_then(|e| e.code())
        .map(|c| c.into_owned())
        .unwrap_or_else(|| panic!("bukan error database: {err}"))
}

async fn insert_user(pool: &PgPool, email: &str) -> Result<String, sqlx::Error> {
    sqlx::query_scalar(
        "INSERT INTO users (email, password_hash, role, display_name, avatar_key)
         VALUES ($1, 'hash', 'member', 'Nama', 'avatar-01')
         RETURNING id::text",
    )
    .bind(email)
    .fetch_one(pool)
    .await
}

async fn insert_vault(pool: &PgPool, owner: &str, slug: &str) -> Result<String, sqlx::Error> {
    sqlx::query_scalar(
        "INSERT INTO vaults (owner_id, slug, name, icon)
         VALUES ($1::uuid, $2, 'Vault', 'book')
         RETURNING id::text",
    )
    .bind(owner)
    .bind(slug)
    .fetch_one(pool)
    .await
}

async fn count(pool: &PgPool, sql: &'static str, user: &str) -> i64 {
    sqlx::query_scalar(sql)
        .bind(user)
        .fetch_one(pool)
        .await
        .unwrap()
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn users_columns_match_entity(pool: PgPool) {
    let ts = "timestamptz";
    assert_eq!(
        columns(&pool, "users").await,
        expected(&[
            ("id", "uuid", false, Some("uuidv7()")),
            ("email", "citext", false, None),
            ("password_hash", "text", false, None),
            ("role", "text", false, None),
            ("must_change_password", "bool", false, Some("false")),
            ("display_name", "text", false, None),
            ("avatar_key", "text", false, None),
            ("created_at", ts, false, Some("now()")),
            ("updated_at", ts, false, Some("now()")),
            ("disabled_at", ts, true, None),
        ])
    );
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn sessions_columns_match_entity(pool: PgPool) {
    let ts = "timestamptz";
    assert_eq!(
        columns(&pool, "sessions").await,
        expected(&[
            ("id_hash", "bytea", false, None),
            ("user_id", "uuid", false, None),
            ("created_at", ts, false, Some("now()")),
            ("last_seen_at", ts, false, Some("now()")),
            ("expires_at", ts, false, None),
        ])
    );
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn access_tokens_columns_match_entity(pool: PgPool) {
    let ts = "timestamptz";
    assert_eq!(
        columns(&pool, "access_tokens").await,
        expected(&[
            ("id", "uuid", false, Some("uuidv7()")),
            ("user_id", "uuid", false, None),
            ("name", "text", false, None),
            ("display_prefix", "text", false, None),
            ("token_hash", "bytea", false, None),
            ("created_at", ts, false, Some("now()")),
            ("last_used_at", ts, true, None),
            ("revoked_at", ts, true, None),
        ])
    );
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn vaults_columns_match_entity(pool: PgPool) {
    let ts = "timestamptz";
    assert_eq!(
        columns(&pool, "vaults").await,
        expected(&[
            ("id", "uuid", false, Some("uuidv7()")),
            ("owner_id", "uuid", false, None),
            ("slug", "text", false, None),
            ("name", "text", false, None),
            ("icon", "text", false, None),
            ("created_at", ts, false, Some("now()")),
            ("updated_at", ts, false, Some("now()")),
        ])
    );
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn vaults_icon_not_null(pool: PgPool) {
    let owner = insert_user(&pool, "icon@example.com").await.unwrap();
    let err = sqlx::query(
        "INSERT INTO vaults (owner_id, slug, name, icon) VALUES ($1::uuid, 'v', 'Vault', NULL)",
    )
    .bind(&owner)
    .execute(&pool)
    .await
    .unwrap_err();
    assert_eq!(sqlstate(err), "23502");
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn fk_delete_rules(pool: PgPool) {
    let rules: Vec<(String, String)> = sqlx::query_as(
        "SELECT conrelid::regclass::text, confdeltype::text
         FROM pg_constraint
         WHERE contype = 'f' AND confrelid = 'users'::regclass
         ORDER BY 1",
    )
    .fetch_all(&pool)
    .await
    .unwrap();
    let rules: Vec<(&str, &str)> = rules
        .iter()
        .map(|(t, r)| (t.as_str(), r.as_str()))
        .collect();
    assert_eq!(
        rules,
        [("access_tokens", "c"), ("sessions", "c"), ("vaults", "r")]
    );
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn user_id_indexes_exist(pool: PgPool) {
    // Index pada FK `user_id`: hapus semua sesi/token milik user tanpa memindai tabel.
    let defs: Vec<String> = sqlx::query_scalar(
        "SELECT indexdef FROM pg_indexes
         WHERE schemaname = current_schema() AND tablename IN ('sessions', 'access_tokens')
         ORDER BY indexdef",
    )
    .fetch_all(&pool)
    .await
    .unwrap();
    for table in ["sessions", "access_tokens"] {
        assert!(
            defs.iter()
                .any(|d| d.contains(&format!("ON public.{table} ")) && d.ends_with("(user_id)")),
            "index user_id {table} tidak ada: {defs:?}"
        );
    }
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn delete_user_cascades_sessions_and_tokens(pool: PgPool) {
    let user = insert_user(&pool, "cascade@example.com").await.unwrap();
    sqlx::query(
        "INSERT INTO sessions (id_hash, user_id, expires_at)
         VALUES ('\\x01'::bytea, $1::uuid, now() + interval '30 days')",
    )
    .bind(&user)
    .execute(&pool)
    .await
    .unwrap();
    sqlx::query(
        "INSERT INTO access_tokens (user_id, name, display_prefix, token_hash)
         VALUES ($1::uuid, 'laptop', 'whk_abcd', '\\x02'::bytea)",
    )
    .bind(&user)
    .execute(&pool)
    .await
    .unwrap();

    sqlx::query("DELETE FROM users WHERE id = $1::uuid")
        .bind(&user)
        .execute(&pool)
        .await
        .unwrap();

    let sql_s = "SELECT count(*) FROM sessions WHERE user_id = $1::uuid";
    let sql_t = "SELECT count(*) FROM access_tokens WHERE user_id = $1::uuid";
    assert_eq!(count(&pool, sql_s, &user).await, 0);
    assert_eq!(count(&pool, sql_t, &user).await, 0);
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn delete_user_with_vault_is_restricted(pool: PgPool) {
    let user = insert_user(&pool, "restrict@example.com").await.unwrap();
    insert_vault(&pool, &user, "riset").await.unwrap();
    let err = sqlx::query("DELETE FROM users WHERE id = $1::uuid")
        .bind(&user)
        .execute(&pool)
        .await
        .unwrap_err();
    // `ON DELETE RESTRICT` → `restrict_violation` (23001); `NO ACTION` yang memberi 23503.
    assert_eq!(sqlstate(err), "23001");
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn uuidv7_default_generates_ids(pool: PgPool) {
    let user = insert_user(&pool, "v7@example.com").await.unwrap();
    let vault = insert_vault(&pool, &user, "v7").await.unwrap();
    let token: String = sqlx::query_scalar(
        "INSERT INTO access_tokens (user_id, name, display_prefix, token_hash)
         VALUES ($1::uuid, 't', 'whk_x', '\\x03'::bytea) RETURNING id::text",
    )
    .bind(&user)
    .fetch_one(&pool)
    .await
    .unwrap();
    for id in [&user, &vault, &token] {
        let version: i16 = sqlx::query_scalar("SELECT uuid_extract_version($1::uuid)")
            .bind(id)
            .fetch_one(&pool)
            .await
            .unwrap();
        assert_eq!(version, 7, "id {id}");
    }
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn email_unique_case_insensitive(pool: PgPool) {
    insert_user(&pool, "Admin@Example.com").await.unwrap();
    let err = insert_user(&pool, "admin@example.COM").await.unwrap_err();
    assert_eq!(sqlstate(err), "23505");
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn vault_slug_unique_per_owner(pool: PgPool) {
    let a = insert_user(&pool, "a@example.com").await.unwrap();
    let b = insert_user(&pool, "b@example.com").await.unwrap();
    insert_vault(&pool, &a, "riset").await.unwrap();
    let err = insert_vault(&pool, &a, "riset").await.unwrap_err();
    assert_eq!(sqlstate(err), "23505");
    insert_vault(&pool, &b, "riset").await.unwrap();
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn vault_slug_check_rejects_invalid(pool: PgPool) {
    let owner = insert_user(&pool, "slug@example.com").await.unwrap();
    let max = format!("a{}", "b".repeat(62));
    insert_vault(&pool, &owner, &max).await.unwrap();
    insert_vault(&pool, &owner, "0-riset-2").await.unwrap();
    let too_long = format!("a{}", "b".repeat(63));
    for bad in ["Riset", "-riset", "riset_1", "", too_long.as_str()] {
        let err = insert_vault(&pool, &owner, bad).await.unwrap_err();
        assert_eq!(sqlstate(err), "23514", "slug {bad:?}");
    }
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn access_token_hash_unique(pool: PgPool) {
    let user = insert_user(&pool, "token@example.com").await.unwrap();
    let sql = "INSERT INTO access_tokens (user_id, name, display_prefix, token_hash)
               VALUES ($1::uuid, 't', 'whk_x', '\\x04'::bytea)";
    sqlx::query(sql).bind(&user).execute(&pool).await.unwrap();
    let err = sqlx::query(sql)
        .bind(&user)
        .execute(&pool)
        .await
        .unwrap_err();
    assert_eq!(sqlstate(err), "23505");
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn role_check_rejects_unknown(pool: PgPool) {
    let err = sqlx::query(
        "INSERT INTO users (email, password_hash, role, display_name, avatar_key)
         VALUES ('role@example.com', 'hash', 'owner', 'Nama', 'avatar-01')",
    )
    .execute(&pool)
    .await
    .unwrap_err();
    assert_eq!(sqlstate(err), "23514");
}
