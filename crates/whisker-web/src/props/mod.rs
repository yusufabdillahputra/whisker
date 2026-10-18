//! Struct props Inertia (sumber kebenaran kontrak; pasangan TS di-generate `ts-rs` ke
//! `frontend/src/types/generated/`).

pub mod account;
pub mod auth;
pub mod errors;
pub mod projects;
pub mod shared;

pub use account::AccountSecurityProps;
pub use auth::LoginPageProps;
pub use errors::ErrorPageProps;
pub use projects::{ProjectCard, ProjectsIndexProps};
pub use shared::{AuthProps, SharedProps, UserProps};
