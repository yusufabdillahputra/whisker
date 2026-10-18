//! Registry vault/project (Task 08) terhadap PostgreSQL nyata (ruling K2).

use std::collections::HashSet;

use sqlx::PgPool;
use whisker_core::error::CoreError;
use whisker_core::user::{NewUser, Role, User, create_user};
use whisker_core::vault::icon::ProjectIcon;
use whisker_core::vault::repo::{
    NewVault, SLUG_MAX_ATTEMPTS, create_vault, find_vault_by_slug, list_vaults,
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

fn new(name: &str) -> NewVault<'_> {
    NewVault {
        name,
        icon: "folder",
    }
}

/// Error validasi per field; panik bila error bukan Validation.
fn validation(err: CoreError) -> std::collections::BTreeMap<String, String> {
    match err {
        CoreError::Validation(v) => v.into_map(),
        other => panic!("bukan Validation: {other:?}"),
    }
}

#[sqlx::test(migrations = "../../migrations")]
async fn create_vault_slugifies_name(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let v = create_vault(
        &pool,
        u.id,
        NewVault {
            name: "  Catatan Kerja ",
            icon: "brain",
        },
    )
    .await
    .unwrap();
    assert_eq!(v.slug, "catatan-kerja");
    assert_eq!(v.name, "Catatan Kerja");
    assert_eq!(v.icon, ProjectIcon::Brain);
    assert_eq!(v.owner_id, u.id);
}

#[sqlx::test(migrations = "../../migrations")]
async fn collision_same_owner_gets_suffix_2_then_3(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let slugs: Vec<String> = [
        create_vault(&pool, u.id, new("Catatan Kerja")).await,
        create_vault(&pool, u.id, new("catatan kerja")).await,
        create_vault(&pool, u.id, new("Catatan-Kerja!")).await,
    ]
    .into_iter()
    .map(|r| r.unwrap().slug)
    .collect();
    assert_eq!(
        slugs,
        ["catatan-kerja", "catatan-kerja-2", "catatan-kerja-3"]
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn same_slug_other_owner_allowed(pool: PgPool) {
    let ani = create(&pool, "ani@example.com").await;
    let budi = create(&pool, "budi@example.com").await;
    let a = create_vault(&pool, ani.id, new("Riset")).await.unwrap();
    let b = create_vault(&pool, budi.id, new("Riset")).await.unwrap();
    assert_eq!(a.slug, "riset");
    assert_eq!(b.slug, "riset");
    assert_ne!(a.id, b.id);
}

#[sqlx::test(migrations = "../../migrations")]
async fn unknown_icon_validation_error(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    let err = create_vault(
        &pool,
        u.id,
        NewVault {
            name: "Riset",
            icon: "skull",
        },
    )
    .await
    .unwrap_err();
    let map = validation(err);
    assert_eq!(map["icon"], "Ikon tidak tersedia");
    assert!(!map.contains_key("name"));
    assert!(list_vaults(&pool, u.id).await.unwrap().is_empty());
}

#[sqlx::test(migrations = "../../migrations")]
async fn blank_name_validation_error(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    // Nama kosong + ikon salah: keduanya dilaporkan per field.
    let err = create_vault(
        &pool,
        u.id,
        NewVault {
            name: "   ",
            icon: "skull",
        },
    )
    .await
    .unwrap_err();
    let map = validation(err);
    assert_eq!(map["name"], "Nama project wajib diisi");
    assert_eq!(map["icon"], "Ikon tidak tersedia");

    let err = create_vault(&pool, u.id, new(&"a".repeat(81)))
        .await
        .unwrap_err();
    assert_eq!(validation(err)["name"], "Nama project maksimal 80 karakter");
    assert!(
        create_vault(&pool, u.id, new(&"a".repeat(80)))
            .await
            .is_ok()
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn list_vaults_only_owner(pool: PgPool) {
    let ani = create(&pool, "ani@example.com").await;
    let budi = create(&pool, "budi@example.com").await;
    let a1 = create_vault(&pool, ani.id, new("Satu")).await.unwrap();
    let a2 = create_vault(&pool, ani.id, new("Dua")).await.unwrap();
    create_vault(&pool, budi.id, new("Milik Budi"))
        .await
        .unwrap();

    // Urut created_at naik.
    assert_eq!(list_vaults(&pool, ani.id).await.unwrap(), vec![a1, a2]);
}

#[sqlx::test(migrations = "../../migrations")]
async fn find_by_slug_scoped_to_owner(pool: PgPool) {
    let ani = create(&pool, "ani@example.com").await;
    let budi = create(&pool, "budi@example.com").await;
    let v = create_vault(&pool, ani.id, new("Riset")).await.unwrap();

    assert_eq!(
        find_vault_by_slug(&pool, ani.id, "riset").await.unwrap(),
        Some(v)
    );
    assert_eq!(
        find_vault_by_slug(&pool, budi.id, "riset").await.unwrap(),
        None
    );
    assert_eq!(
        find_vault_by_slug(&pool, ani.id, "tidak-ada")
            .await
            .unwrap(),
        None
    );
}

#[sqlx::test(migrations = "../../migrations")]
async fn concurrent_create_same_name_yields_distinct_slugs(pool: PgPool) {
    let u = create(&pool, "ani@example.com").await;
    const N: u32 = 8;
    let handles: Vec<_> = (0..N)
        .map(|_| {
            let pool = pool.clone();
            tokio::spawn(async move { create_vault(&pool, u.id, new("Kembar")).await })
        })
        .collect();
    let mut slugs = HashSet::new();
    for h in handles {
        slugs.insert(h.await.unwrap().unwrap().slug);
    }
    let expected: HashSet<String> = std::iter::once("kembar".to_owned())
        .chain((2..=N).map(|n| format!("kembar-{n}")))
        .collect();
    assert_eq!(slugs, expected);
}

#[sqlx::test(migrations = "../../migrations")]
async fn slug_attempts_capped_then_conflict(pool: PgPool) {
    assert_eq!(SLUG_MAX_ATTEMPTS, 1000);
    let u = create(&pool, "ani@example.com").await;
    // Isi `penuh`, `penuh-2` … `penuh-999` langsung di DB.
    sqlx::query(
        "INSERT INTO vaults (owner_id, slug, name, icon)
         SELECT $1, CASE WHEN n = 1 THEN 'penuh' ELSE 'penuh-' || n END, 'Penuh', 'folder'
         FROM generate_series(1, 999) AS n",
    )
    .bind(u.id)
    .execute(&pool)
    .await
    .unwrap();

    // Percobaan ke-1000 (terakhir) masih diterima.
    let last = create_vault(&pool, u.id, new("Penuh")).await.unwrap();
    assert_eq!(last.slug, "penuh-1000");

    // Semua 1000 kandidat terpakai → Conflict, tanpa baris baru.
    let err = create_vault(&pool, u.id, new("Penuh")).await.unwrap_err();
    assert!(matches!(err, CoreError::Conflict(_)), "{err:?}");
    let n: i64 = sqlx::query_scalar("SELECT count(*) FROM vaults WHERE owner_id = $1")
        .bind(u.id)
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(n, 1000);
}
