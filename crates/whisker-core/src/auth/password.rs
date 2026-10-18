//! Password: Argon2id `Argon2::default()` (m=19456, t=2, p=1), PHC string.

use argon2::Argon2;
use argon2::password_hash::phc::PasswordHash;
use argon2::password_hash::{PasswordHasher, PasswordVerifier};

use crate::error::CoreError;

/// Panjang minimum password (dihitung `chars()`); tanpa aturan komposisi.
pub const MIN_PASSWORD_LEN: usize = 12;

/// Hash dummy valid (param default) untuk menyamakan waktu saat user tak ada.
pub const DUMMY_HASH: &str = "$argon2id$v=19$m=19456,t=2,p=1$IBmwhtrBABuqbxM62apzzA$J9+J2mmjKCyIAtG+uiHA5+s2HOgEnSd+hOYaA2krOIE";

/// Hash `plain` ke string PHC dengan salt acak.
pub fn hash_password(plain: &str) -> Result<String, CoreError> {
    Argon2::default()
        .hash_password(plain.as_bytes())
        .map(|h| h.to_string())
        .map_err(|_| CoreError::Internal("hash password gagal".into()))
}

/// Verifikasi `plain` terhadap PHC; PHC rusak -> `false`.
pub fn verify_password(plain: &str, phc: &str) -> bool {
    let Ok(parsed) = phc.parse::<PasswordHash>() else {
        return false;
    };
    Argon2::default()
        .verify_password(plain.as_bytes(), &parsed)
        .is_ok()
}

/// `hash_password` di `spawn_blocking` (Argon2 berat CPU).
pub async fn hash_password_blocking(plain: String) -> Result<String, CoreError> {
    tokio::task::spawn_blocking(move || hash_password(&plain))
        .await
        .map_err(|_| CoreError::Internal("task hash password gagal".into()))?
}

/// Verifikasi di `spawn_blocking`. `None` (user tak ada) memverifikasi `DUMMY_HASH`
/// agar waktu respons sama; hasil selalu `false`.
pub async fn verify_password_blocking(plain: String, phc: Option<String>) -> bool {
    let found = phc.is_some();
    let phc = phc.unwrap_or_else(|| DUMMY_HASH.to_owned());
    let ok = tokio::task::spawn_blocking(move || verify_password(&plain, &phc))
        .await
        .unwrap_or(false);
    found && ok
}

/// Kebijakan password: minimal `MIN_PASSWORD_LEN` karakter (`chars()`).
pub fn check_password_policy(plain: &str) -> Result<(), &'static str> {
    if plain.chars().count() < MIN_PASSWORD_LEN {
        Err("password minimal 12 karakter")
    } else {
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hash_then_verify_ok() {
        let phc = hash_password("kata-sandi-panjang").unwrap();
        assert!(verify_password("kata-sandi-panjang", &phc));
    }

    #[test]
    fn verify_wrong_password_false() {
        let phc = hash_password("kata-sandi-panjang").unwrap();
        assert!(!verify_password("kata-sandi-salah!", &phc));
        assert!(!verify_password("x", "bukan-phc"));
    }

    #[test]
    fn phc_uses_argon2id_default_params() {
        let phc = hash_password("kata-sandi-panjang").unwrap();
        assert!(phc.starts_with("$argon2id$v=19$m=19456,t=2,p=1$"), "{phc}");
    }

    #[tokio::test]
    async fn dummy_path_returns_false_and_dummy_is_valid_phc() {
        assert!(!verify_password_blocking("apa-saja-12345".into(), None).await);
        assert!(DUMMY_HASH.starts_with("$argon2id$v=19$m=19456,t=2,p=1$"));
        assert!(DUMMY_HASH.parse::<PasswordHash>().is_ok());
        assert!(!verify_password("apa-saja-12345", DUMMY_HASH));
        let phc = hash_password_blocking("kata-sandi-panjang".into())
            .await
            .unwrap();
        assert!(verify_password_blocking("kata-sandi-panjang".into(), Some(phc)).await);
    }

    #[test]
    fn policy_rejects_11_chars_accepts_12() {
        assert!(check_password_policy("12345678901").is_err());
        assert!(check_password_policy("123456789012").is_ok());
        // 11 karakter multibyte (> 11 byte) tetap ditolak.
        let s = "ééééééééééé";
        assert_eq!(s.chars().count(), 11);
        assert!(s.len() > 12);
        assert!(check_password_policy(s).is_err());
        assert!(check_password_policy("éééééééééééé").is_ok());
    }
}
