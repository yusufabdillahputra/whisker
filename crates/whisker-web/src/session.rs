//! Sesi web: cookie `whisker_session` (id mentah 256-bit; DB menyimpan SHA-256), middleware
//! lookup + perpanjangan sliding yang menerbitkan ulang cookie.

use axum::extract::{Request, State};
use axum::http::{HeaderMap, HeaderValue, header};
use axum::middleware::Next;
use axum::response::Response;
use cookie::{Cookie, SameSite};
use whisker_core::auth::session_id::SessionId;
use whisker_core::session::{SESSION_TTL, lookup_session};
use whisker_core::user::User;

use crate::AppState;
use crate::page::internal_error;

pub const SESSION_COOKIE: &str = "whisker_session";

/// Cookie sesi: HttpOnly, SameSite=Lax, Path=/, Max-Age = `SESSION_TTL` (30 hari).
pub fn session_cookie(id: &SessionId, secure: bool) -> Cookie<'static> {
    cookie_with_value(id.as_str().to_owned(), secure)
}

/// Cookie penghapus (`Max-Age=0`, nilai kosong) dengan atribut yang sama.
pub fn removal_cookie(secure: bool) -> Cookie<'static> {
    let mut c = base_cookie(String::new(), secure);
    c.set_max_age(cookie::time::Duration::ZERO);
    c.set_expires(cookie::time::OffsetDateTime::UNIX_EPOCH);
    c
}

/// Cookie sesi dengan nilai mentah (dipakai juga untuk menerbitkan ulang cookie saat sliding).
fn cookie_with_value(value: String, secure: bool) -> Cookie<'static> {
    let mut c = base_cookie(value, secure);
    c.set_max_age(cookie::time::Duration::seconds(SESSION_TTL.whole_seconds()));
    c
}

fn base_cookie(value: String, secure: bool) -> Cookie<'static> {
    let mut c = Cookie::new(SESSION_COOKIE, value);
    c.set_http_only(true);
    c.set_secure(secure);
    c.set_same_site(SameSite::Lax);
    c.set_path("/");
    c
}

/// Sesi valid request ini (extension dari `session_middleware`).
#[derive(Clone)]
pub struct CurrentSession {
    pub user: User,
    pub session_hash: [u8; 32],
}

impl std::fmt::Debug for CurrentSession {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("CurrentSession")
            .field("user", &self.user)
            .field("session_hash", &"<redacted>")
            .finish()
    }
}

/// Baca cookie `whisker_session`, lookup sesi (kedaluwarsa dihapus, sliding ≤ 1×/jam), pasang
/// `CurrentSession`. Sesi diperpanjang → cookie diterbitkan ulang; cookie tak berlaku → dihapus.
/// Error DB → `500` generik (detail hanya di log).
pub async fn session_middleware(
    State(state): State<AppState>,
    mut req: Request,
    next: Next,
) -> Response {
    let secure = state.config.cookie_secure;
    let mut cookie_update = None;
    if let Some(raw) = read_cookie(req.headers(), SESSION_COOKIE) {
        match lookup_session(&state.pool, &raw).await {
            Ok(Some(found)) => {
                if found.extended {
                    cookie_update = Some(cookie_with_value(raw, secure));
                }
                req.extensions_mut().insert(CurrentSession {
                    user: found.user,
                    session_hash: found.session_hash,
                });
            }
            Ok(None) => cookie_update = Some(removal_cookie(secure)),
            Err(e) => {
                tracing::error!(error = %e, "sesi: lookup gagal");
                return internal_error();
            }
        }
    }
    let mut resp = next.run(req).await;
    // Handler yang sudah menulis cookie sesi (login/logout) didahulukan.
    if let Some(c) = cookie_update
        && !sets_cookie(resp.headers(), SESSION_COOKIE)
    {
        append_cookie(resp.headers_mut(), &c);
    }
    resp
}

/// Tambah header `Set-Cookie`.
pub fn append_cookie(headers: &mut HeaderMap, cookie: &Cookie<'_>) {
    if let Ok(value) = HeaderValue::from_str(&cookie.to_string()) {
        headers.append(header::SET_COOKIE, value);
    }
}

fn sets_cookie(headers: &HeaderMap, name: &str) -> bool {
    headers
        .get_all(header::SET_COOKIE)
        .iter()
        .filter_map(|v| v.to_str().ok())
        .any(|v| v.split_once('=').is_some_and(|(n, _)| n.trim() == name))
}

fn read_cookie(headers: &HeaderMap, name: &str) -> Option<String> {
    headers
        .get_all(header::COOKIE)
        .iter()
        .filter_map(|v| v.to_str().ok())
        .flat_map(|s| s.split(';'))
        .filter_map(|s| Cookie::parse(s.trim().to_owned()).ok())
        .find(|c| c.name() == name)
        .map(|c| c.value().to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;
    use whisker_core::auth::session_id::generate_session_id;

    #[test]
    fn session_cookie_attributes() {
        let id = generate_session_id();
        let c = session_cookie(&id, true);
        assert_eq!(c.name(), "whisker_session");
        assert_eq!(c.value(), id.as_str());
        assert_eq!(c.http_only(), Some(true));
        assert_eq!(c.secure(), Some(true));
        assert_eq!(c.same_site(), Some(SameSite::Lax));
        assert_eq!(c.path(), Some("/"));
        assert_eq!(c.max_age(), Some(cookie::time::Duration::days(30)));
        let header = c.to_string();
        for attr in [
            "HttpOnly",
            "Secure",
            "SameSite=Lax",
            "Path=/",
            "Max-Age=2592000",
        ] {
            assert!(header.contains(attr), "{attr} di {header}");
        }
    }

    #[test]
    fn session_cookie_secure_false_in_dev() {
        let c = session_cookie(&generate_session_id(), false);
        assert_ne!(c.secure(), Some(true));
        assert!(!c.to_string().contains("Secure"));
        assert_eq!(c.http_only(), Some(true));
    }

    #[test]
    fn removal_cookie_expires_immediately() {
        let c = removal_cookie(true);
        assert_eq!(c.name(), "whisker_session");
        assert_eq!(c.value(), "");
        assert_eq!(c.max_age(), Some(cookie::time::Duration::ZERO));
        assert_eq!(c.path(), Some("/"));
        assert_eq!(c.http_only(), Some(true));
        assert_eq!(c.secure(), Some(true));
        assert_eq!(c.same_site(), Some(SameSite::Lax));
    }
}
