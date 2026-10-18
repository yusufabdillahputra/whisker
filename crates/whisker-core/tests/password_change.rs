//! Ganti password (Task 07) terhadap PostgreSQL nyata (ruling K2).

use sqlx::PgPool;
use uuid::Uuid;
use whisker_core::auth::password::{hash_password, verify_password};
use whisker_core::auth::session_id::session_id_hash;
use whisker_core::error::CoreError;
use whisker_core::session::{create_session, lookup_session};
use whisker_core::user::{ChangePassword, NewUser, Role, User, change_password, create_user};

const CURRENT: &str = "password-lama-123";
const NEW: &str = "password-baru-456";

async fn create(pool: &PgPool, must_change_password: bool) -> User {
    create_user(
        pool,
        NewUser {
            email: "ani@example.com",
            display_name: "Ani",
            password_hash: hash_password(CURRENT).unwrap(),
            role: Role::Member,
            must_change_password,
        },
    )
    .await
    .unwrap()
}

fn input(current: &str, new: &str, confirmation: &str) -> ChangePassword {
    ChangePassword {
        current_password: current.to_owned(),
        new_password: new.to_owned(),
        new_password_confirmation: confirmation.to_owned(),
    }
}

/// Semua error validasi; panik bila error bukan Validation.
fn fields(err: CoreError) -> std::collections::BTreeMap<String, String> {
    match err {
        CoreError::Validation(v) => v.into_map(),
        other => panic!("bukan Validation: {other:?}"),
    }
}

async fn stored_hash(pool: &PgPool, id: Uuid) -> String {
    sqlx::query_scalar("SELECT password_hash FROM users WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .unwrap()
}

#[sqlx::test(migrations = "../../migrations")]
async fn wrong_current_password_field_error(pool: PgPool) {
    let u = create(&pool, false).await;
    let sid = create_session(&pool, u.id).await.unwrap();
    let before = stored_hash(&pool, u.id).await;

    let err = change_password(
        &pool,
        u.id,
        input("salah-sekali-123", NEW, NEW),
        &session_id_hash(sid.as_str()),
    )
    .await
    .unwrap_err();

    let map = fields(err);
    assert_eq!(map.len(), 1, "{map:?}");
    assert_eq!(map["currentPassword"], "Password saat ini salah");
    assert_eq!(stored_hash(&pool, u.id).await, before);
}

#[sqlx::test(migrations = "../../migrations")]
async fn short_new_password_field_error(pool: PgPool) {
    let u = create(&pool, false).await;
    let sid = create_session(&pool, u.id).await.unwrap();
    let short = "a".repeat(11);

    let err = change_password(
        &pool,
        u.id,
        input(CURRENT, &short, &short),
        &session_id_hash(sid.as_str()),
    )
    .await
    .unwrap_err();

    let map = fields(err);
    assert_eq!(map.len(), 1, "{map:?}");
    assert_eq!(map["password"], "Password minimal 12 karakter");
    assert!(verify_password(CURRENT, &stored_hash(&pool, u.id).await));
}

#[sqlx::test(migrations = "../../migrations")]
async fn confirmation_mismatch_field_error(pool: PgPool) {
    let u = create(&pool, false).await;
    let sid = create_session(&pool, u.id).await.unwrap();

    let err = change_password(
        &pool,
        u.id,
        input(CURRENT, NEW, "password-lain-789"),
        &session_id_hash(sid.as_str()),
    )
    .await
    .unwrap_err();

    let map = fields(err);
    assert_eq!(map.len(), 1, "{map:?}");
    assert_eq!(map["passwordConfirmation"], "Ulangan password tidak cocok");
    assert!(verify_password(CURRENT, &stored_hash(&pool, u.id).await));

    // Semua field salah sekaligus -> tiga error.
    let short = "pendek";
    let err = change_password(
        &pool,
        u.id,
        input("salah-sekali-123", short, "lain"),
        &session_id_hash(sid.as_str()),
    )
    .await
    .unwrap_err();
    assert_eq!(fields(err).len(), 3);
}

#[sqlx::test(migrations = "../../migrations")]
async fn success_clears_must_change_and_verifies_new(pool: PgPool) {
    let u = create(&pool, true).await;
    let sid = create_session(&pool, u.id).await.unwrap();
    let updated_before: time::OffsetDateTime =
        sqlx::query_scalar("SELECT updated_at FROM users WHERE id = $1")
            .bind(u.id)
            .fetch_one(&pool)
            .await
            .unwrap();

    change_password(
        &pool,
        u.id,
        input(CURRENT, NEW, NEW),
        &session_id_hash(sid.as_str()),
    )
    .await
    .unwrap();

    let (hash, must_change, updated_after): (String, bool, time::OffsetDateTime) = sqlx::query_as(
        "SELECT password_hash, must_change_password, updated_at FROM users WHERE id = $1",
    )
    .bind(u.id)
    .fetch_one(&pool)
    .await
    .unwrap();
    assert!(verify_password(NEW, &hash));
    assert!(!verify_password(CURRENT, &hash));
    assert!(hash.starts_with("$argon2id$"));
    assert!(!must_change);
    assert!(updated_after > updated_before);
}

#[sqlx::test(migrations = "../../migrations")]
async fn success_deletes_other_sessions_keeps_current(pool: PgPool) {
    let u = create(&pool, false).await;
    let current = create_session(&pool, u.id).await.unwrap();
    let other1 = create_session(&pool, u.id).await.unwrap();
    let other2 = create_session(&pool, u.id).await.unwrap();
    let stranger = create_user(
        &pool,
        NewUser {
            email: "budi@example.com",
            display_name: "Budi",
            password_hash: hash_password(CURRENT).unwrap(),
            role: Role::Member,
            must_change_password: false,
        },
    )
    .await
    .unwrap();
    let stranger_sid = create_session(&pool, stranger.id).await.unwrap();

    change_password(
        &pool,
        u.id,
        input(CURRENT, NEW, NEW),
        &session_id_hash(current.as_str()),
    )
    .await
    .unwrap();

    assert!(
        lookup_session(&pool, current.as_str())
            .await
            .unwrap()
            .is_some()
    );
    assert!(
        lookup_session(&pool, other1.as_str())
            .await
            .unwrap()
            .is_none()
    );
    assert!(
        lookup_session(&pool, other2.as_str())
            .await
            .unwrap()
            .is_none()
    );
    assert!(
        lookup_session(&pool, stranger_sid.as_str())
            .await
            .unwrap()
            .is_some()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn success_keeps_pats_valid(pool: PgPool) {
    let u = create(&pool, false).await;
    let sid = create_session(&pool, u.id).await.unwrap();
    for (i, name) in ["laptop", "ci"].iter().enumerate() {
        sqlx::query(
            "INSERT INTO access_tokens (user_id, name, display_prefix, token_hash)
             VALUES ($1, $2, 'whk_abcd', $3)",
        )
        .bind(u.id)
        .bind(name)
        .bind(vec![i as u8; 32])
        .execute(&pool)
        .await
        .unwrap();
    }

    change_password(
        &pool,
        u.id,
        input(CURRENT, NEW, NEW),
        &session_id_hash(sid.as_str()),
    )
    .await
    .unwrap();

    let active: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM access_tokens WHERE user_id = $1 AND revoked_at IS NULL",
    )
    .bind(u.id)
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(active, 2);
}
