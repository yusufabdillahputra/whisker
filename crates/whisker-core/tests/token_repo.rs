//! Repositori PAT (Task 08) terhadap PostgreSQL nyata (ruling K2).

use sqlx::PgPool;
use time::OffsetDateTime;
use uuid::Uuid;
use whisker_core::auth::pat::{DISPLAY_PREFIX_LEN, token_hash};
use whisker_core::error::CoreError;
use whisker_core::token::{
    TokenStatus, authenticate_token, create_token, list_tokens, revoke_token,
};
use whisker_core::user::{NewUser, Role, User, create_user, disable_user};

async fn create(pool: &PgPool, email: &str) -> User {
    create_user(
        pool,
        NewUser {
            email,
            display_name: "Pengguna",
            password_hash: "$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA".to_owned(),
            role: Role::Member,
            must_change_password: false,
        },
    )
    .await
    .unwrap()
}

async fn last_used_at(pool: &PgPool, id: Uuid) -> Option<OffsetDateTime> {
    sqlx::query_scalar("SELECT last_used_at FROM access_tokens WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .unwrap()
}

async fn set_last_used_ago(pool: &PgPool, id: Uuid, ago: &str) {
    sqlx::query("UPDATE access_tokens SET last_used_at = now() - $2::interval WHERE id = $1")
        .bind(id)
        .bind(ago)
        .execute(pool)
        .await
        .unwrap();
}

async fn db_now(pool: &PgPool) -> OffsetDateTime {
    sqlx::query_scalar("SELECT now()")
        .fetch_one(pool)
        .await
        .unwrap()
}

/// Pesan validasi untuk `field`; panik bila error bukan Validation.
fn validation(err: CoreError, field: &str) -> String {
    match err {
        CoreError::Validation(v) => v
            .into_map()
            .remove(field)
            .unwrap_or_else(|| panic!("tak ada error untuk {field}")),
        other => panic!("bukan Validation: {other:?}"),
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_stores_hash_and_prefix_only(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let (tok, plain) = create_token(&pool, u.id, "  Laptop kerja  ").await.unwrap();

    assert_eq!(tok.name, "Laptop kerja");
    assert_eq!(tok.display_prefix, &plain.expose()[..DISPLAY_PREFIX_LEN]);
    assert_eq!(tok.status(), TokenStatus::Active);
    assert!(tok.last_used_at.is_none());
    assert!(tok.revoked_at.is_none());

    let (stored_hash, stored_prefix): (Vec<u8>, String) =
        sqlx::query_as("SELECT token_hash, display_prefix FROM access_tokens WHERE id = $1")
            .bind(tok.id)
            .fetch_one(&pool)
            .await
            .unwrap();
    assert_eq!(stored_hash, token_hash(plain.expose()).to_vec());
    assert_eq!(stored_prefix, tok.display_prefix);

    // Tidak ada kolom yang memuat token mentah (atau badan sesudah prefix tampilan).
    let row: String = sqlx::query_scalar("SELECT to_jsonb(t)::text FROM access_tokens t")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert!(!row.contains(plain.expose()));
    assert!(!row.contains(&plain.expose()[DISPLAY_PREFIX_LEN..]));
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_rejects_blank_and_long_name(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let err = create_token(&pool, u.id, "   ").await.unwrap_err();
    assert_eq!(validation(err, "name"), "Nama token wajib diisi");
    let err = create_token(&pool, u.id, &"a".repeat(101))
        .await
        .unwrap_err();
    assert_eq!(validation(err, "name"), "Nama token maksimal 100 karakter");
    assert!(create_token(&pool, u.id, &"a".repeat(100)).await.is_ok());
}

#[sqlx::test(migrations = "../../migrations")]
async fn authenticate_valid_token(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let (tok, plain) = create_token(&pool, u.id, "CLI").await.unwrap();

    let p = authenticate_token(&pool, &token_hash(plain.expose()))
        .await
        .unwrap()
        .expect("token valid");
    assert_eq!(p.token_id, tok.id);
    assert_eq!(p.user_id, u.id);
    assert_eq!(p.email, "ani@example.com");
    assert_eq!(p.role, Role::Member);

    // Hash tak dikenal → None.
    assert!(
        authenticate_token(&pool, &[0u8; 32])
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn authenticate_revoked_returns_none(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let (tok, plain) = create_token(&pool, u.id, "CLI").await.unwrap();
    revoke_token(&pool, u.id, tok.id).await.unwrap();
    assert!(
        authenticate_token(&pool, &token_hash(plain.expose()))
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn revoke_is_idempotent_and_permanent(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let (tok, plain) = create_token(&pool, u.id, "CLI").await.unwrap();

    revoke_token(&pool, u.id, tok.id).await.unwrap();
    let first = list_tokens(&pool, u.id).await.unwrap()[0].clone();
    assert_eq!(first.status(), TokenStatus::Revoked);
    let first_revoked = first.revoked_at.expect("revoked_at terisi");

    // Revoke ulang: sukses, revoked_at pertama dipertahankan.
    revoke_token(&pool, u.id, tok.id).await.unwrap();
    let again = list_tokens(&pool, u.id).await.unwrap()[0].clone();
    assert_eq!(again.revoked_at, Some(first_revoked));

    // Permanen: tak ada jalur un-revoke; token tetap ditolak.
    assert!(
        authenticate_token(&pool, &token_hash(plain.expose()))
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn revoke_other_users_token_not_found(pool: PgPool) {
    let ani = create(&pool, "ani@example.com").await;
    let budi = create(&pool, "budi@example.com").await;
    let (tok, plain) = create_token(&pool, ani.id, "CLI").await.unwrap();

    assert!(matches!(
        revoke_token(&pool, budi.id, tok.id).await,
        Err(CoreError::NotFound)
    ));
    assert!(matches!(
        revoke_token(&pool, ani.id, Uuid::now_v7()).await,
        Err(CoreError::NotFound)
    ));
    // Token Ani tetap aktif.
    assert!(
        authenticate_token(&pool, &token_hash(plain.expose()))
            .await
            .unwrap()
            .is_some()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn authenticate_disabled_user_returns_none(pool: PgPool) {
    let admin = create(&pool, "admin@example.com").await;
    let u = create(&pool, "ani@example.com").await;
    let (_, plain) = create_token(&pool, u.id, "CLI").await.unwrap();
    disable_user(&pool, admin.id, u.id).await.unwrap();
    assert!(
        authenticate_token(&pool, &token_hash(plain.expose()))
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn last_used_at_set_on_first_use(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let (tok, plain) = create_token(&pool, u.id, "CLI").await.unwrap();
    assert!(last_used_at(&pool, tok.id).await.is_none());

    let before = db_now(&pool).await;
    authenticate_token(&pool, &token_hash(plain.expose()))
        .await
        .unwrap()
        .unwrap();
    let used = last_used_at(&pool, tok.id).await.expect("terisi");
    assert!(used >= before, "{used} < {before}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn last_used_at_not_rewritten_within_minute(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let (tok, plain) = create_token(&pool, u.id, "CLI").await.unwrap();
    set_last_used_ago(&pool, tok.id, "59 seconds").await;
    let prev = last_used_at(&pool, tok.id).await;

    authenticate_token(&pool, &token_hash(plain.expose()))
        .await
        .unwrap()
        .unwrap();
    assert_eq!(last_used_at(&pool, tok.id).await, prev);
}

#[sqlx::test(migrations = "../../migrations")]
async fn last_used_at_rewritten_after_minute(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let (tok, plain) = create_token(&pool, u.id, "CLI").await.unwrap();
    set_last_used_ago(&pool, tok.id, "61 seconds").await;
    let prev = last_used_at(&pool, tok.id).await.unwrap();

    let before = db_now(&pool).await;
    authenticate_token(&pool, &token_hash(plain.expose()))
        .await
        .unwrap()
        .unwrap();
    let used = last_used_at(&pool, tok.id).await.unwrap();
    assert!(used > prev);
    assert!(used >= before, "{used} < {before}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn list_tokens_only_own(pool: PgPool) {
    let ani = create(&pool, "ani@example.com").await;
    let budi = create(&pool, "budi@example.com").await;
    let (a1, _) = create_token(&pool, ani.id, "satu").await.unwrap();
    let (a2, _) = create_token(&pool, ani.id, "dua").await.unwrap();
    create_token(&pool, budi.id, "milik budi").await.unwrap();

    let list = list_tokens(&pool, ani.id).await.unwrap();
    // Urut created_at turun: terbaru dulu.
    let ids: Vec<Uuid> = list.iter().map(|t| t.id).collect();
    assert_eq!(ids, vec![a2.id, a1.id]);
    assert_eq!(list[0], a2);
}
