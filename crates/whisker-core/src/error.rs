//! Error domain bersama.

use std::collections::BTreeMap;

/// Error domain inti; dipetakan ke respons HTTP di lapisan web.
#[derive(Debug)]
pub enum CoreError {
    NotFound,
    Validation(ValidationErrors),
    Conflict(&'static str),
    Database(sqlx::Error),
    Internal(String),
}

impl std::fmt::Display for CoreError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::NotFound => f.write_str("tidak ditemukan"),
            Self::Validation(_) => f.write_str("validasi gagal"),
            Self::Conflict(m) => write!(f, "konflik: {m}"),
            Self::Database(e) => write!(f, "database: {e}"),
            Self::Internal(m) => write!(f, "internal: {m}"),
        }
    }
}

impl std::error::Error for CoreError {}

impl From<sqlx::Error> for CoreError {
    fn from(e: sqlx::Error) -> Self {
        Self::Database(e)
    }
}

impl From<ValidationErrors> for CoreError {
    fn from(e: ValidationErrors) -> Self {
        Self::Validation(e)
    }
}

/// Error validasi per field form. Kunci = nama field form (camelCase), nilai = pesan pertama.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ValidationErrors {
    fields: BTreeMap<String, String>,
}

impl ValidationErrors {
    pub fn new() -> Self {
        Self::default()
    }

    /// Catat error untuk `field`. Pesan pertama per field yang dipertahankan.
    pub fn add(&mut self, field: &'static str, msg: impl Into<String>) {
        self.fields
            .entry(field.to_owned())
            .or_insert_with(|| msg.into());
    }

    pub fn is_empty(&self) -> bool {
        self.fields.is_empty()
    }

    /// Ada error untuk `field`?
    pub fn contains(&self, field: &str) -> bool {
        self.fields.contains_key(field)
    }

    pub fn into_map(self) -> BTreeMap<String, String> {
        self.fields
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_is_empty() {
        assert!(ValidationErrors::new().is_empty());
    }

    #[test]
    fn add_keeps_first_message_per_field() {
        let mut errors = ValidationErrors::new();
        errors.add("text", "wajib diisi");
        errors.add("text", "terlalu pendek");
        errors.add("projectName", "sudah dipakai");
        assert!(!errors.is_empty());
        let map = errors.into_map();
        assert_eq!(map.len(), 2);
        assert_eq!(map["text"], "wajib diisi");
        assert_eq!(map["projectName"], "sudah dipakai");
    }

    #[test]
    fn contains_reports_field_presence() {
        let mut errors = ValidationErrors::new();
        errors.add("currentPassword", "salah");
        assert!(errors.contains("currentPassword"));
        assert!(!errors.contains("password"));
    }
}

/// Nilai string di luar allowlist saat `FromStr` (ikon project, kunci avatar).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ParseValueError {
    pub kind: &'static str,
}

impl std::fmt::Display for ParseValueError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{} tidak ada di allowlist", self.kind)
    }
}

impl std::error::Error for ParseValueError {}
