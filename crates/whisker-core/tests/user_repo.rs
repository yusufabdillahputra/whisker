//! Repositori user (Task 06) terhadap PostgreSQL nyata (ruling K2).

use sqlx::PgPool;
use uuid::Uuid;
use whisker_core::error::CoreError;
use whisker_core::user::{
    AvatarKey, NewUser, Role, User, count_users, create_user, disable_user, find_auth_by_email,
    get_user, list_users, update_profile,
};

fn new_user<'a>(email: &'a str, display_name: &'a str) -> NewUser<'a> {
    NewUser {
        email,
        display_name,
        password_hash: "$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA".to_owned(),
        role: Role::Member,
        must_change_password: false,
    }
}

async fn create(pool: &PgPool, email: &str) -> User {
    create_user(pool, new_user(email, "Pengguna"))
        .await
        .unwrap()
}

/// Pesan validasi untuk `field`; panik bila error bukan Validation.
fn validation(err: CoreError, field: &str) -> String {
    match err {
        CoreError::Validation(v) => v
            .into_map()
            .remove(field)
            .unwrap_or_else(|| panic!("tak ada error untuk field {field}")),
        other => panic!("bukan Validation: {other:?}"),
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_user_assigns_v7_id_and_default_avatar(pool: PgPool) {
    let u = create_user(&pool, new_user("ani@example.com", "Ani"))
        .await
        .unwrap();
    assert_eq!(u.id.get_version_num(), 7);
    assert_eq!(u.avatar_key, AvatarKey::default_for(u.id));
    assert_eq!(u.email, "ani@example.com");
    assert_eq!(u.display_name, "Ani");
    assert_eq!(u.role, Role::Member);
    assert!(!u.must_change_password);
    assert_eq!(u.disabled_at, None);

    let stored: String = sqlx::query_scalar("SELECT avatar_key FROM users WHERE id = $1")
        .bind(u.id)
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(stored, AvatarKey::default_for(u.id).as_str());
    assert_eq!(get_user(&pool, u.id).await.unwrap(), Some(u));
}

#[sqlx::test(migrations = "../../migrations")]
async fn find_by_email_is_case_insensitive(pool: PgPool) {
    let u = create(&pool, "admin@example.com").await;
    let rec = find_auth_by_email(&pool, "Admin@Example.com")
        .await
        .unwrap()
        .expect("ditemukan");
    assert_eq!(rec.user_id, u.id);
    assert!(rec.password_hash.starts_with("$argon2id$"));
    assert!(!rec.disabled);
    assert!(!rec.must_change_password);
    assert!(
        find_auth_by_email(&pool, "lain@example.com")
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn duplicate_email_case_insensitive_rejected(pool: PgPool) {
    create(&pool, "budi@example.com").await;
    let err = create_user(&pool, new_user("BUDI@Example.COM", "Budi"))
        .await
        .unwrap_err();
    assert_eq!(validation(err, "email"), "Email sudah dipakai");
    assert_eq!(count_users(&pool).await.unwrap(), 1);
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_user_validates_display_name_length(pool: PgPool) {
    let err = create_user(&pool, new_user("a@example.com", "   "))
        .await
        .unwrap_err();
    validation(err, "displayName");
    let long = "x".repeat(81);
    let err = create_user(&pool, new_user("a@example.com", &long))
        .await
        .unwrap_err();
    validation(err, "displayName");
    let max = "é".repeat(80);
    let u = create_user(&pool, new_user("a@example.com", &max))
        .await
        .unwrap();
    assert_eq!(u.display_name, max);
}

#[sqlx::test(migrations = "../../migrations")]
async fn disable_user_sets_disabled_and_deletes_sessions(pool: PgPool) {
    let admin = create(&pool, "admin@example.com").await;
    let target = create(&pool, "target@example.com").await;
    for i in 0u8..2 {
        sqlx::query(
            "INSERT INTO sessions (id_hash, user_id, expires_at)
             VALUES ($1, $2, now() + interval '1 day')",
        )
        .bind(vec![i; 32])
        .bind(target.id)
        .execute(&pool)
        .await
        .unwrap();
    }
    sqlx::query(
        "INSERT INTO sessions (id_hash, user_id, expires_at)
         VALUES ($1, $2, now() + interval '1 day')",
    )
    .bind(vec![9u8; 32])
    .bind(admin.id)
    .execute(&pool)
    .await
    .unwrap();

    disable_user(&pool, admin.id, target.id).await.unwrap();

    let t = get_user(&pool, target.id).await.unwrap().unwrap();
    let first = t.disabled_at.expect("disabled_at terisi");
    let sessions = |id: Uuid| {
        sqlx::query_scalar::<_, i64>("SELECT count(*) FROM sessions WHERE user_id = $1").bind(id)
    };
    assert_eq!(sessions(target.id).fetch_one(&pool).await.unwrap(), 0);
    assert_eq!(sessions(admin.id).fetch_one(&pool).await.unwrap(), 1);
    assert!(
        find_auth_by_email(&pool, "target@example.com")
            .await
            .unwrap()
            .unwrap()
            .disabled
    );

    // Idempoten: menonaktifkan ulang tidak menggeser waktu pertama.
    disable_user(&pool, admin.id, target.id).await.unwrap();
    let again = get_user(&pool, target.id).await.unwrap().unwrap();
    assert_eq!(again.disabled_at, Some(first));

    let err = disable_user(&pool, admin.id, Uuid::now_v7())
        .await
        .unwrap_err();
    assert!(matches!(err, CoreError::NotFound), "{err:?}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn admin_cannot_disable_self(pool: PgPool) {
    let admin = create(&pool, "admin@example.com").await;
    let err = disable_user(&pool, admin.id, admin.id).await.unwrap_err();
    assert_eq!(
        validation(err, "user"),
        "Anda tidak dapat menonaktifkan akun sendiri"
    );
    let a = get_user(&pool, admin.id).await.unwrap().unwrap();
    assert_eq!(a.disabled_at, None);
}

#[sqlx::test(migrations = "../../migrations")]
async fn update_profile_changes_name_and_avatar(pool: PgPool) {
    let u = create(&pool, "citra@example.com").await;
    let updated = update_profile(&pool, u.id, "Citra Dewi", "animal-08")
        .await
        .unwrap();
    assert_eq!(updated.display_name, "Citra Dewi");
    assert_eq!(updated.avatar_key, AvatarKey::Animal08);
    assert_eq!(get_user(&pool, u.id).await.unwrap(), Some(updated));

    let err = update_profile(&pool, Uuid::now_v7(), "Siapa", "animal-01")
        .await
        .unwrap_err();
    assert!(matches!(err, CoreError::NotFound), "{err:?}");
}

#[sqlx::test(migrations = "../../migrations")]
async fn update_profile_rejects_unknown_avatar(pool: PgPool) {
    let u = create(&pool, "dodi@example.com").await;
    let err = update_profile(&pool, u.id, "Dodi", "animal-99")
        .await
        .unwrap_err();
    assert_eq!(validation(err, "avatarKey"), "Avatar tidak tersedia");
    let same = get_user(&pool, u.id).await.unwrap().unwrap();
    assert_eq!(same, u);
}

#[sqlx::test(migrations = "../../migrations")]
async fn update_profile_rejects_blank_display_name(pool: PgPool) {
    let u = create(&pool, "eka@example.com").await;
    let err = update_profile(&pool, u.id, "  ", "animal-01")
        .await
        .unwrap_err();
    validation(err, "displayName");
    let err = update_profile(&pool, u.id, &"y".repeat(81), "animal-01")
        .await
        .unwrap_err();
    validation(err, "displayName");
    assert_eq!(get_user(&pool, u.id).await.unwrap().unwrap(), u);
}

#[sqlx::test(migrations = "../../migrations")]
async fn list_users_returns_all(pool: PgPool) {
    assert!(list_users(&pool).await.unwrap().is_empty());
    assert_eq!(count_users(&pool).await.unwrap(), 0);
    let a = create(&pool, "a@example.com").await;
    let b = create(&pool, "b@example.com").await;
    let c = create(&pool, "c@example.com").await;
    let ids: Vec<Uuid> = list_users(&pool)
        .await
        .unwrap()
        .into_iter()
        .map(|u| u.id)
        .collect();
    assert_eq!(ids, vec![a.id, b.id, c.id]);
    assert_eq!(count_users(&pool).await.unwrap(), 3);
}
