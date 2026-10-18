//! Props page akun: `Account/Security`, `Account/Profile`, `Account/Tokens`.

use serde::Serialize;
use time::OffsetDateTime;
use time::format_description::well_known::Rfc3339;
use ts_rs::TS;
use whisker_core::auth::pat::PlainToken;
use whisker_core::token::{AccessToken, TokenStatus};
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

/// Props page `Account/Tokens`. `created_token` hanya terisi pada respons `POST /account/tokens`
/// yang sukses (token polos tampil sekali); `GET` selalu `null`.
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct AccountTokensProps {
    pub tokens: Vec<TokenRow>,
    pub created_token: Option<CreatedToken>,
}
veer::register_page!(AccountTokensProps, "Account/Tokens");

/// Satu baris daftar token (tanpa hash, tanpa token polos). Timestamp = RFC 3339 (UTC).
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct TokenRow {
    /// UUID (string).
    pub id: String,
    pub name: String,
    /// 12 karakter pertama token (`whk_` + 8).
    pub display_prefix: String,
    pub created_at: String,
    pub last_used_at: Option<String>,
    pub status: TokenStatus,
}

impl From<&AccessToken> for TokenRow {
    fn from(t: &AccessToken) -> Self {
        Self {
            id: t.id.to_string(),
            name: t.name.clone(),
            display_prefix: t.display_prefix.clone(),
            created_at: rfc3339(t.created_at),
            last_used_at: t.last_used_at.map(rfc3339),
            status: t.status(),
        }
    }
}

/// Token yang baru dibuat; `plain` = token mentah `whk_…`, hanya di respons pembuatan.
#[derive(Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct CreatedToken {
    /// UUID (string).
    pub id: String,
    pub name: String,
    pub plain: String,
}

impl CreatedToken {
    pub fn new(token: &AccessToken, plain: &PlainToken) -> Self {
        Self {
            id: token.id.to_string(),
            name: token.name.clone(),
            plain: plain.expose().to_owned(),
        }
    }
}

impl std::fmt::Debug for CreatedToken {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("CreatedToken")
            .field("id", &self.id)
            .field("name", &self.name)
            .field("plain", &"<redacted>")
            .finish()
    }
}

/// Timestamp → RFC 3339 di UTC (mis. `2026-10-18T03:04:05.123456Z`).
fn rfc3339(t: OffsetDateTime) -> String {
    t.to_offset(time::UtcOffset::UTC)
        .format(&Rfc3339)
        .unwrap_or_else(|_| t.unix_timestamp().to_string())
}
