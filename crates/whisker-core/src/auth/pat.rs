//! PAT `whk_` + base62(32 byte) lebar 43 + checksum CRC32 (IEEE) base62 lebar 6.
//! Disimpan sebagai SHA-256; validasi format murni (tanpa I/O).

use sha2::{Digest, Sha256};
use subtle::ConstantTimeEq;

pub const PAT_PREFIX: &str = "whk_";
pub const PAT_BODY_LEN: usize = 43;
pub const PAT_CHECKSUM_LEN: usize = 6;
pub const PAT_LEN: usize = 53;
pub const DISPLAY_PREFIX_LEN: usize = 12;

const ALPHABET: &[u8; 62] = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

/// Token mentah; `Debug` di-redaksi, jangan pernah di-log.
pub struct PlainToken(String);

impl PlainToken {
    pub fn expose(&self) -> &str {
        &self.0
    }
}

impl std::fmt::Debug for PlainToken {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("PlainToken(<redacted>)")
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PatFormatError {
    Prefix,
    Length,
    Alphabet,
    Checksum,
}

/// Encode big-endian `bytes` ke base62 lebar tetap `width` (padding `0` di depan).
fn base62_fixed(bytes: &[u8], width: usize) -> String {
    // Aritmatika big-number sederhana: pembagian berulang dengan 62.
    let mut num: Vec<u8> = bytes.to_vec();
    let mut out = vec![b'0'; width];
    let mut pos = width;
    while num.iter().any(|&b| b != 0) && pos > 0 {
        let mut rem: u32 = 0;
        for b in num.iter_mut() {
            let cur = (rem << 8) | u32::from(*b);
            *b = (cur / 62) as u8;
            rem = cur % 62;
        }
        pos -= 1;
        out[pos] = ALPHABET[rem as usize];
    }
    String::from_utf8(out).expect("alfabet ASCII")
}

fn checksum_str(crc: u32) -> String {
    base62_fixed(&crc.to_be_bytes(), PAT_CHECKSUM_LEN)
}

pub fn generate_token() -> PlainToken {
    let mut raw = [0u8; 32];
    getrandom::fill(&mut raw).expect("OS RNG tidak tersedia");
    let body = base62_fixed(&raw, PAT_BODY_LEN);
    let crc = crc32fast::hash(body.as_bytes());
    PlainToken(format!("{PAT_PREFIX}{body}{}", checksum_str(crc)))
}

/// Validasi format tanpa I/O. Urutan: prefix -> panjang -> alfabet -> checksum.
pub fn parse_token(candidate: &str) -> Result<&str, PatFormatError> {
    if !candidate.starts_with(PAT_PREFIX) {
        return Err(PatFormatError::Prefix);
    }
    if candidate.len() != PAT_LEN {
        return Err(PatFormatError::Length);
    }
    if !candidate
        .bytes()
        .skip(PAT_PREFIX.len())
        .all(|b| b.is_ascii_alphanumeric())
    {
        return Err(PatFormatError::Alphabet);
    }
    let (body, checksum) = candidate[PAT_PREFIX.len()..].split_at(PAT_BODY_LEN);
    let expected = checksum_str(crc32fast::hash(body.as_bytes()));
    if bool::from(expected.as_bytes().ct_eq(checksum.as_bytes())) {
        Ok(candidate)
    } else {
        Err(PatFormatError::Checksum)
    }
}

/// SHA-256 token (yang disimpan di DB).
pub fn token_hash(token: &str) -> [u8; 32] {
    Sha256::digest(token.as_bytes()).into()
}

/// 12 karakter pertama untuk tampilan (tanpa membocorkan sisa token).
pub fn display_prefix(token: &PlainToken) -> String {
    token.0[..DISPLAY_PREFIX_LEN].to_owned()
}

#[cfg(test)]
mod tests {
    use super::*;
    use sha2::{Digest, Sha256};
    use std::collections::HashSet;

    fn body_of(t: &str) -> &str {
        &t[PAT_PREFIX.len()..PAT_PREFIX.len() + PAT_BODY_LEN]
    }

    #[test]
    fn generated_token_has_prefix_and_length_53() {
        let t = generate_token();
        assert!(t.expose().starts_with("whk_"));
        assert_eq!(t.expose().len(), 53);
        assert_eq!(PAT_LEN, 53);
    }

    #[test]
    fn generated_token_body_is_base62() {
        let t = generate_token();
        assert!(t.expose()[4..].bytes().all(|b| b.is_ascii_alphanumeric()));
    }

    #[test]
    fn generated_token_parses_ok() {
        let t = generate_token();
        assert_eq!(parse_token(t.expose()), Ok(t.expose()));
    }

    #[test]
    fn flipped_char_fails_checksum() {
        let t = generate_token();
        let mut b = t.expose().as_bytes().to_vec();
        let i = 10;
        b[i] = if b[i] == b'a' { b'b' } else { b'a' };
        let s = String::from_utf8(b).unwrap();
        assert_eq!(parse_token(&s), Err(PatFormatError::Checksum));
    }

    #[test]
    fn wrong_prefix_rejected() {
        let t = generate_token();
        let s = format!("ghp_{}", &t.expose()[4..]);
        assert_eq!(parse_token(&s), Err(PatFormatError::Prefix));
    }

    #[test]
    fn wrong_length_rejected() {
        let t = generate_token();
        assert_eq!(parse_token(&t.expose()[..52]), Err(PatFormatError::Length));
        let s = format!("{}a", t.expose());
        assert_eq!(parse_token(&s), Err(PatFormatError::Length));
    }

    #[test]
    fn non_base62_char_rejected() {
        let t = generate_token();
        let mut s = t.expose().to_string();
        s.replace_range(10..11, "-");
        assert_eq!(parse_token(&s), Err(PatFormatError::Alphabet));
    }

    #[test]
    fn tokens_unique_over_1000_draws() {
        let set: HashSet<String> = (0..1000)
            .map(|_| generate_token().expose().to_string())
            .collect();
        assert_eq!(set.len(), 1000);
    }

    #[test]
    fn base62_fixed_width_pads_leading_zeros() {
        assert_eq!(base62_fixed(&[0u8; 32], PAT_BODY_LEN), "0".repeat(43));
        assert_eq!(base62_fixed(&[0, 0, 0, 0, 61], 5).len(), 5);
        assert_eq!(base62_fixed(&[61], 3), "00z");
    }

    #[test]
    fn checksum_of_max_crc_fits_6_chars() {
        // 62^6 = 56_800_235_584 > u32::MAX
        let c = checksum_str(u32::MAX);
        assert_eq!(c.len(), PAT_CHECKSUM_LEN);
        assert_eq!(checksum_str(0), "000000");
    }

    #[test]
    fn token_hash_matches_sha256_vector() {
        let expected: [u8; 32] = Sha256::digest(b"whk_test").into();
        assert_eq!(token_hash("whk_test"), expected);
        assert_eq!(token_hash("abc")[..4], [0xba, 0x78, 0x16, 0xbf]);
    }

    #[test]
    fn display_prefix_is_first_12_chars() {
        let t = generate_token();
        assert_eq!(display_prefix(&t), t.expose()[..12]);
        assert_eq!(display_prefix(&t).len(), DISPLAY_PREFIX_LEN);
    }

    #[test]
    fn debug_does_not_leak_token() {
        let t = generate_token();
        let d = format!("{t:?}");
        assert!(!d.contains(body_of(t.expose())));
        assert!(!d.contains(t.expose()));
    }

    #[test]
    fn parse_checks_in_order_prefix_length_alphabet_checksum() {
        // salah prefix + panjang + alfabet -> Prefix
        assert_eq!(parse_token("ghp_-"), Err(PatFormatError::Prefix));
        // prefix benar, panjang salah, alfabet salah -> Length
        assert_eq!(parse_token("whk_-"), Err(PatFormatError::Length));
        // prefix + panjang benar, alfabet salah + checksum salah -> Alphabet
        let s = format!("whk_{}", "-".repeat(49));
        assert_eq!(parse_token(&s), Err(PatFormatError::Alphabet));
        // semua benar kecuali checksum
        let s = format!("whk_{}", "0".repeat(49));
        assert_eq!(parse_token(&s), Err(PatFormatError::Checksum));
        // non-ASCII tidak panic
        assert!(parse_token("whk_é").is_err());
    }
}
