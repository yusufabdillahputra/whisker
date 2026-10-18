//! Props page akun: `Account/Security`, `Account/Profile`.

use serde::Serialize;
use ts_rs::TS;
use whisker_core::user::{AvatarGroup, AvatarKey};

/// Props page `Account/Security`. `forced` = user wajib ganti password (`must_change_password`);
/// sukses ganti password lalu dialihkan ke `/` alih-alih kembali ke halaman ini.
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct AccountSecurityProps {
    pub forced: bool,
}
veer::register_page!(AccountSecurityProps, "Account/Security");

/// Satu pilihan avatar di pemilih: kunci preset + kelompoknya (untuk filter).
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct AvatarOption {
    pub key: AvatarKey,
    pub group: AvatarGroup,
}

/// Props page `Account/Profile`: seluruh 40 preset avatar, urutan `AvatarKey::ALL`.
/// Nama/avatar/email user saat ini ada di shared props `auth.user`.
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct AccountProfileProps {
    pub avatar_options: Vec<AvatarOption>,
}
veer::register_page!(AccountProfileProps, "Account/Profile");

impl AccountProfileProps {
    pub fn new() -> Self {
        Self {
            avatar_options: AvatarKey::ALL
                .iter()
                .map(|k| AvatarOption {
                    key: *k,
                    group: k.group(),
                })
                .collect(),
        }
    }
}

impl Default for AccountProfileProps {
    fn default() -> Self {
        Self::new()
    }
}
