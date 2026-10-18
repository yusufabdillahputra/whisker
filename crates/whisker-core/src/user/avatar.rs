//! Avatar preset (40 kunci) dan `Role`. Kunci disimpan di `users.avatar_key`; aset SVG dibuat saat build
//! (Task 12). Urutan `ALL` = urutan pewarnaan preset.

use std::str::FromStr;

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use ts_rs::TS;
use uuid::Uuid;

use crate::error::ParseValueError;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, TS)]
#[ts(export)]
#[serde(rename_all = "lowercase")]
pub enum AvatarGroup {
    Female,
    Male,
    Animal,
}

// `JsonSchema`: dipakai langsung di output tool MCP `whoami` (ruling K13). Komentar biasa agar
// tidak ikut ke TS hasil ts-rs.
#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, TS, schemars::JsonSchema,
)]
#[ts(export)]
#[serde(rename_all = "lowercase")]
pub enum Role {
    Admin,
    Member,
}

macro_rules! avatar_keys {
    ($($variant:ident => $name:literal, $group:expr),+ $(,)?) => {
        /// Kunci preset avatar, mis. `"human-f-01"`.
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, TS)]
        #[ts(export)]
        pub enum AvatarKey {
            $(#[serde(rename = $name)] #[ts(rename = $name)] $variant,)+
        }

        impl AvatarKey {
            pub const ALL: [AvatarKey; 40] = [$(AvatarKey::$variant),+];

            pub fn as_str(&self) -> &'static str {
                match self { $(AvatarKey::$variant => $name),+ }
            }

            pub fn group(&self) -> AvatarGroup {
                match self { $(AvatarKey::$variant => $group),+ }
            }
        }

        impl FromStr for AvatarKey {
            type Err = ParseValueError;
            fn from_str(s: &str) -> Result<Self, Self::Err> {
                match s {
                    $($name => Ok(AvatarKey::$variant),)+
                    _ => Err(ParseValueError { kind: "kunci avatar" }),
                }
            }
        }
    };
}

avatar_keys! {
        HumanF01 => "human-f-01", AvatarGroup::Female,
        HumanF02 => "human-f-02", AvatarGroup::Female,
        HumanF03 => "human-f-03", AvatarGroup::Female,
        HumanF04 => "human-f-04", AvatarGroup::Female,
        HumanF05 => "human-f-05", AvatarGroup::Female,
        HumanF06 => "human-f-06", AvatarGroup::Female,
        HumanF07 => "human-f-07", AvatarGroup::Female,
        HumanF08 => "human-f-08", AvatarGroup::Female,
        HumanF09 => "human-f-09", AvatarGroup::Female,
        HumanF10 => "human-f-10", AvatarGroup::Female,
        HumanF11 => "human-f-11", AvatarGroup::Female,
        HumanF12 => "human-f-12", AvatarGroup::Female,
        HumanF13 => "human-f-13", AvatarGroup::Female,
        HumanF14 => "human-f-14", AvatarGroup::Female,
        HumanF15 => "human-f-15", AvatarGroup::Female,
        HumanF16 => "human-f-16", AvatarGroup::Female,
        HumanM01 => "human-m-01", AvatarGroup::Male,
        HumanM02 => "human-m-02", AvatarGroup::Male,
        HumanM03 => "human-m-03", AvatarGroup::Male,
        HumanM04 => "human-m-04", AvatarGroup::Male,
        HumanM05 => "human-m-05", AvatarGroup::Male,
        HumanM06 => "human-m-06", AvatarGroup::Male,
        HumanM07 => "human-m-07", AvatarGroup::Male,
        HumanM08 => "human-m-08", AvatarGroup::Male,
        HumanM09 => "human-m-09", AvatarGroup::Male,
        HumanM10 => "human-m-10", AvatarGroup::Male,
        HumanM11 => "human-m-11", AvatarGroup::Male,
        HumanM12 => "human-m-12", AvatarGroup::Male,
        HumanM13 => "human-m-13", AvatarGroup::Male,
        HumanM14 => "human-m-14", AvatarGroup::Male,
        HumanM15 => "human-m-15", AvatarGroup::Male,
        HumanM16 => "human-m-16", AvatarGroup::Male,
        Animal01 => "animal-01", AvatarGroup::Animal,
        Animal02 => "animal-02", AvatarGroup::Animal,
        Animal03 => "animal-03", AvatarGroup::Animal,
        Animal04 => "animal-04", AvatarGroup::Animal,
        Animal05 => "animal-05", AvatarGroup::Animal,
        Animal06 => "animal-06", AvatarGroup::Animal,
        Animal07 => "animal-07", AvatarGroup::Animal,
        Animal08 => "animal-08", AvatarGroup::Animal,
}

impl AvatarKey {
    /// Default deterministik: SHA-256 atas 16 byte id, 8 byte pertama (big-endian) mod 40.
    pub fn default_for(user_id: Uuid) -> AvatarKey {
        let digest = Sha256::digest(user_id.as_bytes());
        let n = u64::from_be_bytes(digest[..8].try_into().expect("8 byte"));
        Self::ALL[(n % 40) as usize]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    #[test]
    fn avatar_all_has_40_unique_keys_in_order() {
        let keys: Vec<&str> = AvatarKey::ALL.iter().map(|k| k.as_str()).collect();
        assert_eq!(keys.len(), 40);
        assert_eq!(keys.iter().collect::<HashSet<_>>().len(), 40);
        assert_eq!(keys[0], "human-f-01");
        assert_eq!(keys[15], "human-f-16");
        assert_eq!(keys[16], "human-m-01");
        assert_eq!(keys[31], "human-m-16");
        assert_eq!(keys[32], "animal-01");
        assert_eq!(keys[39], "animal-08");
    }

    #[test]
    fn avatar_groups_16_16_8() {
        let n = |g| AvatarKey::ALL.iter().filter(|k| k.group() == g).count();
        assert_eq!(n(AvatarGroup::Female), 16);
        assert_eq!(n(AvatarGroup::Male), 16);
        assert_eq!(n(AvatarGroup::Animal), 8);
    }

    #[test]
    fn avatar_from_str_roundtrip_and_rejects_unknown() {
        for k in AvatarKey::ALL {
            assert_eq!(k.as_str().parse::<AvatarKey>().unwrap(), k);
        }
        for s in [
            "human-f-17",
            "animal-00",
            "animal-09",
            "human-f-1",
            "Human-F-01",
            "",
        ] {
            assert!(s.parse::<AvatarKey>().is_err(), "{s:?}");
        }
    }

    #[test]
    fn avatar_serde_matches_as_str_and_role_lowercase() {
        for k in AvatarKey::ALL {
            assert_eq!(
                serde_json::to_string(&k).unwrap(),
                format!("\"{}\"", k.as_str())
            );
        }
        assert_eq!(serde_json::to_string(&Role::Admin).unwrap(), "\"admin\"");
        assert_eq!(serde_json::to_string(&Role::Member).unwrap(), "\"member\"");
        assert_eq!(
            serde_json::to_string(&AvatarGroup::Animal).unwrap(),
            "\"animal\""
        );
    }

    /// Vektor terkunci: `users.avatar_key` tersimpan bergantung pada pemetaan ini (Task 06 pertama kali
    /// menyimpannya). Nilai diverifikasi independen (SHA-256 Python, 8 byte BE mod 40). Mengubah formula
    /// berarti avatar default user lama tak lagi cocok — tes ini harus gagal keras.
    #[test]
    fn default_for_pinned_vectors() {
        assert_eq!(AvatarKey::default_for(Uuid::nil()), AvatarKey::HumanM14);
        assert_eq!(
            AvatarKey::default_for(Uuid::from_u128(0x0199_f0a2_7c4e_7d3a_8b1f_2c3d_4e5f_6a7b)),
            AvatarKey::Animal06
        );
        assert_eq!(
            AvatarKey::default_for(Uuid::from_u128(0x1234_5678_9abc_def0_1234_5678_9abc_def0)),
            AvatarKey::HumanM15
        );
    }

    #[test]
    fn default_for_is_deterministic() {
        let id = Uuid::from_u128(0x1234_5678_9abc_def0_1234_5678_9abc_def0);
        assert_eq!(AvatarKey::default_for(id), AvatarKey::default_for(id));
    }

    #[test]
    fn default_for_always_in_allowlist() {
        let mut seen = HashSet::new();
        for _ in 0..10_000 {
            let mut b = [0u8; 16];
            getrandom::fill(&mut b).unwrap();
            let k = AvatarKey::default_for(Uuid::from_bytes(b));
            assert!(AvatarKey::ALL.contains(&k));
            seen.insert(k);
        }
        // Sebaran wajar: hampir semua kunci muncul pada 10.000 sampel.
        assert!(seen.len() >= 35, "hanya {} kunci muncul", seen.len());
    }

    /// Menulis `avatar-keys.json` (`[{key, group}]`, urut `ALL`) ke `TS_RS_EXPORT_DIR`.
    #[test]
    fn export_bindings_avatar_keys_json() {
        let rows: Vec<serde_json::Value> = AvatarKey::ALL
            .iter()
            .map(|k| serde_json::json!({ "key": k.as_str(), "group": k.group() }))
            .collect();
        let json = serde_json::to_string_pretty(&rows).unwrap() + "\n";
        crate::export::write_generated("avatar-keys.json", &json);
    }
}
