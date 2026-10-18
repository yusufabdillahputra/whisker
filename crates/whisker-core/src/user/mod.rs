//! Nilai domain user (avatar preset, role) dan repositori tabel `users`.

pub mod avatar;
pub mod password_change;
pub mod repo;

pub use avatar::{AvatarGroup, AvatarKey, Role};
pub use password_change::{ChangePassword, change_password};
pub use repo::{
    count_users, create_user, disable_user, find_auth_by_email, get_user, list_users,
    update_profile,
};

use time::OffsetDateTime;
use uuid::Uuid;

/// Baris `users` tanpa hash password.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct User {
    pub id: Uuid,
    pub email: String,
    pub display_name: String,
    pub avatar_key: AvatarKey,
    pub role: Role,
    pub must_change_password: bool,
    pub created_at: OffsetDateTime,
    pub disabled_at: Option<OffsetDateTime>,
}

/// Data minimum untuk login (verifikasi password + status akun).
#[derive(Clone, PartialEq, Eq)]
pub struct AuthRecord {
    pub user_id: Uuid,
    pub password_hash: String,
    pub disabled: bool,
    pub must_change_password: bool,
}

impl std::fmt::Debug for AuthRecord {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("AuthRecord")
            .field("user_id", &self.user_id)
            .field("password_hash", &"***")
            .field("disabled", &self.disabled)
            .field("must_change_password", &self.must_change_password)
            .finish()
    }
}

/// Input `create_user`; `password_hash` sudah berupa PHC Argon2id.
#[derive(Clone)]
pub struct NewUser<'a> {
    pub email: &'a str,
    pub display_name: &'a str,
    pub password_hash: String,
    pub role: Role,
    pub must_change_password: bool,
}
