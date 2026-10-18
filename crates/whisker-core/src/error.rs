//! Error domain bersama.

use std::collections::BTreeMap;

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
}
