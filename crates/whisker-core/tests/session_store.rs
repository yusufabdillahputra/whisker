//! Store sesi web (Task 07) terhadap PostgreSQL nyata (ruling K2).

use sqlx::PgPool;
use time::OffsetDateTime;
use uuid::Uuid;
use whisker_core::auth::password::hash_password;
use whisker_core::auth::session_id::session_id_hash;
use whisker_core::session::{
    SESSION_TTL, create_login_session, create_session, delete_other_sessions, delete_session,
    delete_user_sessions, lookup_session,
};
use whisker_core::user::{
    ChangePassword, NewUser, Role, User, change_password, create_user, disable_user,
    find_auth_by_email,
};

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

async fn session_count(pool: &PgPool, user_id: Uuid) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM sessions WHERE user_id = $1")
        .bind(user_id)
        .fetch_one(pool)
        .await
        .unwrap()
}

async fn row_exists(pool: &PgPool, hash: &[u8; 32]) -> bool {
    sqlx::query_scalar("SELECT EXISTS (SELECT 1 FROM sessions WHERE id_hash = $1)")
        .bind(hash.as_slice())
        .fetch_one(pool)
        .await
        .unwrap()
}

async fn expires_at(pool: &PgPool, hash: &[u8; 32]) -> OffsetDateTime {
    sqlx::query_scalar("SELECT expires_at FROM sessions WHERE id_hash = $1")
        .bind(hash.as_slice())
        .fetch_one(pool)
        .await
        .unwrap()
}

async fn db_now(pool: &PgPool) -> OffsetDateTime {
    sqlx::query_scalar("SELECT now()")
        .fetch_one(pool)
        .await
        .unwrap()
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_then_lookup_returns_user(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_session(&pool, u.id).await.unwrap();

    let su = lookup_session(&pool, sid.as_str())
        .await
        .unwrap()
        .expect("sesi ditemukan");
    assert_eq!(su.user, u);
    assert_eq!(su.session_hash, session_id_hash(sid.as_str()));
    assert!(!su.extended);

    // Kedaluwarsa awal = now() + 30 hari.
    let delta = expires_at(&pool, &su.session_hash).await - db_now(&pool).await;
    assert!(
        (delta - SESSION_TTL).abs() < time::Duration::minutes(1),
        "{delta}"
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn lookup_unknown_returns_none(pool: PgPool) {
    create(&pool, "ani@example.com").await;
    assert!(
        lookup_session(&pool, "tidak-ada-sesi-seperti-ini")
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn expired_session_rejected_and_deleted(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_session(&pool, u.id).await.unwrap();
    let hash = session_id_hash(sid.as_str());
    sqlx::query("UPDATE sessions SET expires_at = now() - interval '1 second' WHERE id_hash = $1")
        .bind(hash.as_slice())
        .execute(&pool)
        .await
        .unwrap();

    assert!(lookup_session(&pool, sid.as_str()).await.unwrap().is_none());
    assert!(!row_exists(&pool, &hash).await, "baris kedaluwarsa dihapus");
}

#[sqlx::test(migrations = "../../migrations")]
async fn disabled_user_session_rejected(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_session(&pool, u.id).await.unwrap();
    // Nonaktif langsung di DB (tanpa disable_user, yang juga menghapus sesi) untuk menguji join.
    sqlx::query("UPDATE users SET disabled_at = now() WHERE id = $1")
        .bind(u.id)
        .execute(&pool)
        .await
        .unwrap();
    assert!(lookup_session(&pool, sid.as_str()).await.unwrap().is_none());

    // Jalur produksi: disable_user menghapus sesi.
    let admin = create(&pool, "admin@example.com").await;
    let other = create(&pool, "budi@example.com").await;
    let sid2 = create_session(&pool, other.id).await.unwrap();
    disable_user(&pool, admin.id, other.id).await.unwrap();
    assert!(
        lookup_session(&pool, sid2.as_str())
            .await
            .unwrap()
            .is_none()
    );
    assert_eq!(session_count(&pool, other.id).await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn lookup_within_hour_does_not_extend(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_session(&pool, u.id).await.unwrap();
    let hash = session_id_hash(sid.as_str());
    sqlx::query(
        "UPDATE sessions SET last_seen_at = now() - interval '59 minutes',
                             expires_at = now() + interval '1 day'
         WHERE id_hash = $1",
    )
    .bind(hash.as_slice())
    .execute(&pool)
    .await
    .unwrap();
    let before = expires_at(&pool, &hash).await;

    let su = lookup_session(&pool, sid.as_str()).await.unwrap().unwrap();
    assert!(!su.extended);
    assert_eq!(expires_at(&pool, &hash).await, before);
}

#[sqlx::test(migrations = "../../migrations")]
async fn lookup_after_hour_extends_30_days(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_session(&pool, u.id).await.unwrap();
    let hash = session_id_hash(sid.as_str());
    sqlx::query(
        "UPDATE sessions SET last_seen_at = now() - interval '61 minutes',
                             expires_at = now() + interval '1 day'
         WHERE id_hash = $1",
    )
    .bind(hash.as_slice())
    .execute(&pool)
    .await
    .unwrap();

    let su = lookup_session(&pool, sid.as_str()).await.unwrap().unwrap();
    assert!(su.extended);
    let now = db_now(&pool).await;
    let delta = expires_at(&pool, &hash).await - now;
    assert!(
        (delta - SESSION_TTL).abs() < time::Duration::minutes(1),
        "{delta}"
    );
    let last_seen: OffsetDateTime =
        sqlx::query_scalar("SELECT last_seen_at FROM sessions WHERE id_hash = $1")
            .bind(hash.as_slice())
            .fetch_one(&pool)
            .await
            .unwrap();
    assert!((now - last_seen).abs() < time::Duration::minutes(1));

    // Lookup berikutnya dalam jam yang sama tidak memperpanjang lagi.
    let again = lookup_session(&pool, sid.as_str()).await.unwrap().unwrap();
    assert!(!again.extended);
}

#[sqlx::test(migrations = "../../migrations")]
async fn delete_session_logout(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_session(&pool, u.id).await.unwrap();
    let other = create_session(&pool, u.id).await.unwrap();
    let hash = session_id_hash(sid.as_str());

    delete_session(&pool, &hash).await.unwrap();

    assert!(!row_exists(&pool, &hash).await);
    assert!(lookup_session(&pool, sid.as_str()).await.unwrap().is_none());
    assert!(
        lookup_session(&pool, other.as_str())
            .await
            .unwrap()
            .is_some()
    );
    // Idempoten.
    delete_session(&pool, &hash).await.unwrap();
}

#[sqlx::test(migrations = "../../migrations")]
async fn delete_user_sessions_removes_all(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let v = create(&pool, "budi@example.com").await;
    for _ in 0..3 {
        create_session(&pool, u.id).await.unwrap();
    }
    let keep = create_session(&pool, v.id).await.unwrap();

    assert_eq!(delete_user_sessions(&pool, u.id).await.unwrap(), 3);
    assert_eq!(session_count(&pool, u.id).await, 0);
    assert!(
        lookup_session(&pool, keep.as_str())
            .await
            .unwrap()
            .is_some()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn delete_other_sessions_keeps_given(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let v = create(&pool, "budi@example.com").await;
    let keep = create_session(&pool, u.id).await.unwrap();
    create_session(&pool, u.id).await.unwrap();
    create_session(&pool, u.id).await.unwrap();
    let stranger = create_session(&pool, v.id).await.unwrap();

    let n = delete_other_sessions(&pool, u.id, &session_id_hash(keep.as_str()))
        .await
        .unwrap();
    assert_eq!(n, 2);
    assert!(
        lookup_session(&pool, keep.as_str())
            .await
            .unwrap()
            .is_some()
    );
    assert_eq!(session_count(&pool, u.id).await, 1);
    assert!(
        lookup_session(&pool, stranger.as_str())
            .await
            .unwrap()
            .is_some()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_session_purges_expired_of_user(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let v = create(&pool, "budi@example.com").await;
    let old = create_session(&pool, u.id).await.unwrap();
    let live = create_session(&pool, u.id).await.unwrap();
    let other_old = create_session(&pool, v.id).await.unwrap();
    let old_hash = session_id_hash(old.as_str());
    let other_hash = session_id_hash(other_old.as_str());
    sqlx::query(
        "UPDATE sessions SET expires_at = now() - interval '1 second' WHERE id_hash = ANY($1)",
    )
    .bind(vec![old_hash.to_vec(), other_hash.to_vec()])
    .execute(&pool)
    .await
    .unwrap();

    create_session(&pool, u.id).await.unwrap();

    assert!(
        !row_exists(&pool, &old_hash).await,
        "sesi kedaluwarsa user dihapus"
    );
    assert!(row_exists(&pool, &session_id_hash(live.as_str())).await);
    assert!(
        row_exists(&pool, &other_hash).await,
        "sesi kedaluwarsa user lain tidak disentuh"
    );
    assert_eq!(session_count(&pool, u.id).await, 2);
}

#[sqlx::test(migrations = "../../migrations")]
async fn db_stores_only_hash(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_session(&pool, u.id).await.unwrap();

    let stored: Vec<Vec<u8>> =
        sqlx::query_scalar("SELECT id_hash FROM sessions WHERE user_id = $1")
            .bind(u.id)
            .fetch_all(&pool)
            .await
            .unwrap();
    assert_eq!(stored, vec![session_id_hash(sid.as_str()).to_vec()]);
    assert_ne!(stored[0], sid.as_str().as_bytes());
}

// --- Task 10: TOCTOU login vs ganti password (catatan review Task 07). ---

const PLACEHOLDER_HASH: &str = "$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA";

#[sqlx::test(migrations = "../../migrations")]
async fn login_session_created_when_password_hash_unchanged(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let sid = create_login_session(&pool, u.id, PLACEHOLDER_HASH)
        .await
        .unwrap()
        .expect("hash sama -> sesi dibuat");
    assert!(row_exists(&pool, &session_id_hash(sid.as_str())).await);
}

#[sqlx::test(migrations = "../../migrations")]
async fn login_session_refused_after_password_changed_since_verification(pool: PgPool) {
    let old_password = "kata-sandi-lama-123";
    let user = create_user(
        &pool,
        NewUser {
            email: "ani@example.com",
            display_name: "Ani",
            password_hash: hash_password(old_password).unwrap(),
            role: Role::Member,
            must_change_password: false,
        },
    )
    .await
    .unwrap();
    // Login membaca hash lalu memverifikasi password ...
    let seen = find_auth_by_email(&pool, "ani@example.com")
        .await
        .unwrap()
        .unwrap()
        .password_hash;
    // ... ganti password menyelinap sebelum sesi dibuat.
    change_password(
        &pool,
        user.id,
        ChangePassword {
            current_password: old_password.to_owned(),
            new_password: "kata-sandi-baru-456".to_owned(),
            new_password_confirmation: "kata-sandi-baru-456".to_owned(),
        },
        &[0u8; 32],
    )
    .await
    .unwrap();

    let created = create_login_session(&pool, user.id, &seen).await.unwrap();
    assert!(created.is_none(), "sesi tak boleh lahir dari password lama");
    assert_eq!(session_count(&pool, user.id).await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn login_session_waits_for_concurrent_password_update_then_refuses(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let mut tx = pool.begin().await.unwrap();
    sqlx::query("UPDATE users SET password_hash = 'hash-baru', updated_at = now() WHERE id = $1")
        .bind(u.id)
        .execute(&mut *tx)
        .await
        .unwrap();

    let login = tokio::spawn({
        let pool = pool.clone();
        async move { create_login_session(&pool, u.id, PLACEHOLDER_HASH).await }
    });
    tokio::time::sleep(std::time::Duration::from_millis(300)).await;
    assert!(
        !login.is_finished(),
        "pembuatan sesi menunggu kunci baris user yang sedang diubah"
    );
    tx.commit().await.unwrap();

    let created = login.await.unwrap().unwrap();
    assert!(created.is_none());
    assert_eq!(session_count(&pool, u.id).await, 0);
}

#[sqlx::test(migrations = "../../migrations")]
async fn login_session_refused_for_disabled_user(pool: PgPool) {
    let admin = create(&pool, "admin@example.com").await;
    let u = create(&pool, "ani@example.com").await;
    disable_user(&pool, admin.id, u.id).await.unwrap();
    let created = create_login_session(&pool, u.id, PLACEHOLDER_HASH)
        .await
        .unwrap();
    assert!(created.is_none());
    assert_eq!(session_count(&pool, u.id).await, 0);
}
