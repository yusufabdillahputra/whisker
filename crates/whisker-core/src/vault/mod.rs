//! Nilai domain vault (ikon project, slug) dan registry tabel `vaults`.

pub mod icon;
pub mod repo;
pub mod slug;

pub use repo::{NewVault, Vault, create_vault, find_vault_by_slug, list_vaults};
