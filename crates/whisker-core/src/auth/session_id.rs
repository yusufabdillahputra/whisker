//! Id sesi: 32 byte acak OS, base64url tanpa padding; disimpan sebagai SHA-256.

use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use sha2::{Digest, Sha256};

/// Id sesi mentah (hanya ke cookie); `Debug` tidak membocorkan nilai.
pub struct SessionId(String);

impl SessionId {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl std::fmt::Debug for SessionId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("SessionId(<redacted>)")
    }
}

pub fn generate_session_id() -> SessionId {
    let mut buf = [0u8; 32];
    getrandom::fill(&mut buf).expect("OS RNG tidak tersedia");
    SessionId(URL_SAFE_NO_PAD.encode(buf))
}

/// SHA-256 id sesi mentah (yang disimpan di DB).
pub fn session_id_hash(raw: &str) -> [u8; 32] {
    Sha256::digest(raw.as_bytes()).into()
}

#[cfg(test)]
mod tests {
    use super::*;
    use sha2::{Digest, Sha256};

    #[test]
    fn session_id_is_43_chars_base64url() {
        let id = generate_session_id();
        assert_eq!(id.as_str().len(), 43);
        assert!(
            id.as_str()
                .bytes()
                .all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
        );
        assert_ne!(id.as_str(), generate_session_id().as_str());
    }

    #[test]
    fn session_id_hash_is_sha256() {
        let expected: [u8; 32] = Sha256::digest(b"abc").into();
        assert_eq!(session_id_hash("abc"), expected);
    }
}
