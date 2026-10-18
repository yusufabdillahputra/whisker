//! Shared props: ikut di setiap page (`InertiaConfig::share`), dibaca dari `CurrentSession`.

use serde::Serialize;
use ts_rs::TS;
use whisker_core::user::{AvatarKey, Role, User};

use crate::session::CurrentSession;

/// Shared props semua page. `auth = null` bila tanpa sesi.
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct SharedProps {
    pub auth: Option<AuthProps>,
}

#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct AuthProps {
    pub user: UserProps,
}

/// User yang sedang login (tanpa hash, tanpa data sesi).
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct UserProps {
    /// UUID (string).
    pub id: String,
    pub email: String,
    pub display_name: String,
    pub avatar_key: AvatarKey,
    pub role: Role,
    pub must_change_password: bool,
}

impl From<&User> for UserProps {
    fn from(u: &User) -> Self {
        Self {
            id: u.id.to_string(),
            email: u.email.clone(),
            display_name: u.display_name.clone(),
            avatar_key: u.avatar_key,
            role: u.role,
            must_change_password: u.must_change_password,
        }
    }
}

impl SharedProps {
    pub fn from_session(session: Option<&CurrentSession>) -> Self {
        Self {
            auth: session.map(|s| AuthProps {
                user: UserProps::from(&s.user),
            }),
        }
    }
}
