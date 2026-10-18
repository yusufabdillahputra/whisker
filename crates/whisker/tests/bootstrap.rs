//! Bootstrap admin via env (Task 06; B1–B3, A8, Review Focus dua container).

use sqlx::PgPool;
use whisker::bootstrap::{BootstrapError, BootstrapOutcome, bootstrap_admin, email_local_part};
use whisker::config::BootstrapEnv;
use whisker_core::auth::password::verify_password_blocking;
use whisker_core::user::{
    AvatarKey, NewUser, Role, count_users, create_user, find_auth_by_email, get_user,
};

const PASSWORD: &str = "kata-sandi-admin-123";

fn env(email: Option<&str>, password: Option<&str>) -> BootstrapEnv {
    BootstrapEnv {
        email: email.map(str::to_owned),
        password: password.map(str::to_owned),
    }
}

async fn seed_member(pool: &PgPool) {
    create_user(
        pool,
        NewUser {
            email: "sudah-ada@example.com",
            display_name: "Sudah Ada",
            password_hash: "$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA".to_owned(),
            role: Role::Member,
            must_change_password: false,
        },
    )
    .await
    .unwrap();
}

#[test]
fn email_local_part_takes_text_before_last_at() {
    assert_eq!(email_local_part("admin@example.com"), "admin");
    assert_eq!(email_local_part("ani.w+tag@contoh.id"), "ani.w+tag");
    assert_eq!(email_local_part("\"a@b\"@example.com"), "\"a@b\"");
    assert_eq!(email_local_part("tanpa-at"), "tanpa-at");
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn empty_table_with_env_creates_admin(pool: PgPool) {
    let out = bootstrap_admin(&pool, &env(Some("admin@example.com"), Some(PASSWORD)))
        .await
        .unwrap();
    let BootstrapOutcome::CreatedAdmin { user_id } = out else {
        panic!("harus CreatedAdmin: {out:?}");
    };
    let u = get_user(&pool, user_id).await.unwrap().expect("admin ada");
    assert_eq!(u.email, "admin@example.com");
    assert_eq!(u.display_name, "admin");
    assert_eq!(u.role, Role::Admin);
    assert!(u.must_change_password);
    assert_eq!(u.avatar_key, AvatarKey::default_for(user_id));
    assert_eq!(u.disabled_at, None);

    let rec = find_auth_by_email(&pool, "admin@example.com")
        .await
        .unwrap()
        .unwrap();
    assert!(rec.must_change_password);
    assert!(verify_password_blocking(PASSWORD.to_owned(), Some(rec.password_hash)).await);
    assert_eq!(count_users(&pool).await.unwrap(), 1);
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn empty_table_without_env_errors(pool: PgPool) {
    for e in [
        env(None, None),
        env(Some("admin@example.com"), None),
        env(None, Some(PASSWORD)),
        // Placeholder `.env.example` (K5): dianggap belum diisi saat tabel kosong.
        env(Some("<email-admin>"), Some(PASSWORD)),
        env(Some("admin@example.com"), Some("<password-admin>")),
    ] {
        let err = bootstrap_admin(&pool, &e).await.unwrap_err();
        assert!(
            matches!(err, BootstrapError::MissingAdminEnv),
            "{e:?}: {err:?}"
        );
        let msg = err.to_string();
        assert!(
            msg.contains("WHISKER_ADMIN_EMAIL") && msg.contains("WHISKER_ADMIN_PASSWORD"),
            "{msg}"
        );
    }
    assert_eq!(count_users(&pool).await.unwrap(), 0);
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn populated_table_ignores_env_and_flags_lingering_password(pool: PgPool) {
    seed_member(&pool).await;
    let out = bootstrap_admin(&pool, &env(Some("admin@example.com"), Some(PASSWORD)))
        .await
        .unwrap();
    assert_eq!(out, BootstrapOutcome::SkippedWithLingeringPassword);
    // Placeholder password pun tidak menggagalkan start saat tabel berisi (K5).
    let out = bootstrap_admin(&pool, &env(None, Some("<password-admin>")))
        .await
        .unwrap();
    assert_eq!(out, BootstrapOutcome::SkippedWithLingeringPassword);
    assert_eq!(count_users(&pool).await.unwrap(), 1);
    assert!(
        find_auth_by_email(&pool, "admin@example.com")
            .await
            .unwrap()
            .is_none()
    );
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn populated_table_without_password_skips(pool: PgPool) {
    seed_member(&pool).await;
    for e in [env(None, None), env(Some("admin@example.com"), None)] {
        assert_eq!(
            bootstrap_admin(&pool, &e).await.unwrap(),
            BootstrapOutcome::Skipped
        );
    }
    assert_eq!(count_users(&pool).await.unwrap(), 1);
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn concurrent_bootstrap_creates_single_admin(pool: PgPool) {
    // Dua container start bersamaan dengan env yang sama: tepat satu admin dibuat, tanpa error.
    let e = env(Some("admin@example.com"), Some(PASSWORD));
    let (a, b) = tokio::join!(bootstrap_admin(&pool, &e), bootstrap_admin(&pool, &e));
    let outcomes = [a.unwrap(), b.unwrap()];
    let created = outcomes
        .iter()
        .filter(|o| matches!(o, BootstrapOutcome::CreatedAdmin { .. }))
        .count();
    assert_eq!(created, 1, "{outcomes:?}");
    assert!(
        outcomes.contains(&BootstrapOutcome::SkippedWithLingeringPassword),
        "{outcomes:?}"
    );
    assert_eq!(count_users(&pool).await.unwrap(), 1);
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn weak_bootstrap_password_rejected(pool: PgPool) {
    let err = bootstrap_admin(&pool, &env(Some("admin@example.com"), Some("12345678901")))
        .await
        .unwrap_err();
    assert!(matches!(err, BootstrapError::WeakPassword), "{err:?}");
    let msg = err.to_string();
    assert!(
        msg.contains("WHISKER_ADMIN_PASSWORD") && msg.contains("12"),
        "{msg}"
    );
    assert_eq!(count_users(&pool).await.unwrap(), 0);
}

/// Fix round 1: `<`/`>` di tengah password sah (tanpa aturan komposisi); hanya bentuk utuh `<...>`
/// yang dianggap placeholder.
#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn password_with_angle_brackets_accepted_whole_placeholder_rejected(pool: PgPool) {
    let err = bootstrap_admin(
        &pool,
        &env(Some("admin@example.com"), Some("<isi-password-admin>")),
    )
    .await
    .unwrap_err();
    assert!(matches!(err, BootstrapError::MissingAdminEnv), "{err:?}");
    assert_eq!(count_users(&pool).await.unwrap(), 0);

    let pw = "ab<cd>ef1234xyz";
    let out = bootstrap_admin(&pool, &env(Some("admin@example.com"), Some(pw)))
        .await
        .unwrap();
    assert!(
        matches!(out, BootstrapOutcome::CreatedAdmin { .. }),
        "{out:?}"
    );
    let rec = find_auth_by_email(&pool, "admin@example.com")
        .await
        .unwrap()
        .unwrap();
    assert!(verify_password_blocking(pw.to_owned(), Some(rec.password_hash)).await);
}
