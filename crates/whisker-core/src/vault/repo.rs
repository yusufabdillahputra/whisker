//! Registry project/vault (tabel `vaults`). Slug otomatis dari nama, tidak bisa diedit; bentrok
//! milik owner yang sama → `-2`, `-3`, … Server otoritas akhir atas `UNIQUE (owner_id, slug)`.

use sqlx::PgPool;
use time::OffsetDateTime;
use uuid::Uuid;

use super::icon::ProjectIcon;
use super::slug::{slug_candidate, slugify};
use crate::error::{CoreError, ValidationErrors};

/// Batas panjang nama project (karakter, setelah trim) — asumsi Q12.
pub const VAULT_NAME_MAX: usize = 80;

/// Batas percobaan kandidat slug (`base`, `base-2` … `base-1000`). Habis → `CoreError::Conflict`.
pub const SLUG_MAX_ATTEMPTS: u32 = 1000;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Vault {
    pub id: Uuid,
    pub owner_id: Uuid,
    pub slug: String,
    pub name: String,
    pub icon: ProjectIcon,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}

/// Input `create_vault` (nilai mentah form).
#[derive(Debug, Clone, Copy)]
pub struct NewVault<'a> {
    pub name: &'a str,
    pub icon: &'a str,
}

struct VaultRow {
    id: Uuid,
    owner_id: Uuid,
    slug: String,
    name: String,
    icon: String,
    created_at: OffsetDateTime,
    updated_at: OffsetDateTime,
}

impl TryFrom<VaultRow> for Vault {
    type Error = CoreError;

    fn try_from(r: VaultRow) -> Result<Self, CoreError> {
        let icon = r
            .icon
            .parse()
            .map_err(|_| CoreError::Internal(format!("ikon tak dikenal: {}", r.icon)))?;
        Ok(Vault {
            id: r.id,
            owner_id: r.owner_id,
            slug: r.slug,
            name: r.name,
            icon,
            created_at: r.created_at,
            updated_at: r.updated_at,
        })
    }
}

/// Buat project milik `owner_id`. `name` di-trim, wajib 1..=80 karakter; `icon` harus ada di
/// allowlist (error per field `name` / `icon`). Kandidat slug dicoba berurutan dengan
/// `INSERT … ON CONFLICT (owner_id, slug) DO NOTHING` — aman terhadap pembuatan bersamaan —
/// maksimal `SLUG_MAX_ATTEMPTS` kali, lalu `CoreError::Conflict`.
pub async fn create_vault(
    pool: &PgPool,
    owner_id: Uuid,
    input: NewVault<'_>,
) -> Result<Vault, CoreError> {
    let mut errors = ValidationErrors::new();
    let name = input.name.trim();
    if name.is_empty() {
        errors.add("name", "Nama project wajib diisi");
    } else if name.chars().count() > VAULT_NAME_MAX {
        errors.add("name", "Nama project maksimal 80 karakter");
    }
    let icon = input.icon.parse::<ProjectIcon>().ok();
    if icon.is_none() {
        errors.add("icon", "Ikon tidak tersedia");
    }
    let Some(icon) = icon.filter(|_| errors.is_empty()) else {
        return Err(errors.into());
    };

    let base = slugify(name);
    for attempt in 1..=SLUG_MAX_ATTEMPTS {
        let slug = slug_candidate(&base, attempt);
        let row = sqlx::query_as!(
            VaultRow,
            r#"INSERT INTO vaults (owner_id, slug, name, icon)
               VALUES ($1, $2, $3, $4)
               ON CONFLICT (owner_id, slug) DO NOTHING
               RETURNING id, owner_id, slug, name, icon, created_at, updated_at"#,
            owner_id,
            slug,
            name,
            icon.as_str(),
        )
        .fetch_optional(pool)
        .await?;
        if let Some(row) = row {
            return row.try_into();
        }
    }
    Err(CoreError::Conflict("kandidat slug project habis"))
}

/// Project milik `owner_id`, urut `created_at` naik (asumsi Q25; id v7 pemutus seri).
pub async fn list_vaults(pool: &PgPool, owner_id: Uuid) -> Result<Vec<Vault>, CoreError> {
    sqlx::query_as!(
        VaultRow,
        r#"SELECT id, owner_id, slug, name, icon, created_at, updated_at
           FROM vaults WHERE owner_id = $1 ORDER BY created_at, id"#,
        owner_id,
    )
    .fetch_all(pool)
    .await?
    .into_iter()
    .map(Vault::try_from)
    .collect()
}

/// Project milik `owner_id` dengan `slug` tertentu (slug owner lain tak terlihat).
pub async fn find_vault_by_slug(
    pool: &PgPool,
    owner_id: Uuid,
    slug: &str,
) -> Result<Option<Vault>, CoreError> {
    sqlx::query_as!(
        VaultRow,
        r#"SELECT id, owner_id, slug, name, icon, created_at, updated_at
           FROM vaults WHERE owner_id = $1 AND slug = $2"#,
        owner_id,
        slug,
    )
    .fetch_optional(pool)
    .await?
    .map(Vault::try_from)
    .transpose()
}
