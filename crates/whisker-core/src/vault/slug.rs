//! Slug project (A3): `^[a-z0-9][a-z0-9-]{0,62}$`. Server adalah otoritas akhir; pratinjau TS
//! (`frontend/src/lib/slugify.ts`) mengikuti vektor bersama `tests/fixtures/slug_vectors.json`.

use unicode_normalization::{UnicodeNormalization, char::is_combining_mark};

pub const SLUG_MAX_LEN: usize = 63;
pub const SLUG_FALLBACK: &str = "project";

/// `^[a-z0-9][a-z0-9-]{0,62}$`
pub fn is_valid_slug(s: &str) -> bool {
    let b = s.as_bytes();
    if b.is_empty() || b.len() > SLUG_MAX_LEN {
        return false;
    }
    let alnum = |c: u8| c.is_ascii_lowercase() || c.is_ascii_digit();
    alnum(b[0]) && b[1..].iter().all(|&c| alnum(c) || c == b'-')
}

/// NFKD, buang tanda diakritik, lowercase, non-`[a-z0-9]` jadi `-`, rapatkan, pangkas `-` di tepi,
/// potong 63, kosong -> `SLUG_FALLBACK`.
pub fn slugify(name: &str) -> String {
    let mut out = String::with_capacity(name.len());
    for c in name.nfkd().filter(|c| !is_combining_mark(*c)) {
        for l in c.to_lowercase() {
            if l.is_ascii_lowercase() || l.is_ascii_digit() {
                out.push(l);
            } else if !out.ends_with('-') {
                out.push('-');
            }
        }
    }
    let trimmed = out.trim_matches('-');
    let cut = truncate_trim(trimmed, SLUG_MAX_LEN);
    if cut.is_empty() {
        SLUG_FALLBACK.to_owned()
    } else {
        cut.to_owned()
    }
}

/// Potong ke `max` byte (slug murni ASCII) lalu buang `-` di ujung.
fn truncate_trim(s: &str, max: usize) -> &str {
    let end = s.len().min(max);
    s[..end].trim_end_matches('-')
}

/// Percobaan ke-`attempt`: 1 -> `base`; n>=2 -> `base-n` dengan base dipotong agar total <= 63.
pub fn slug_candidate(base: &str, attempt: u32) -> String {
    if attempt <= 1 {
        return base.to_owned();
    }
    let suffix = format!("-{attempt}");
    let room = SLUG_MAX_LEN.saturating_sub(suffix.len());
    let head = truncate_trim(base, room);
    if head.is_empty() {
        // base habis terpotong: pakai fallback agar tetap diawali [a-z0-9].
        let fb = truncate_trim(SLUG_FALLBACK, room);
        return format!("{fb}{suffix}");
    }
    format!("{head}{suffix}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_slug_examples() {
        assert!(is_valid_slug("a"));
        assert!(is_valid_slug("catatan-kerja"));
        assert!(is_valid_slug("0a"));
        assert!(is_valid_slug(&"a".repeat(63)));
    }

    #[test]
    fn invalid_slug_examples() {
        for s in ["", "-a", "A", "a_b", "é", "a b"] {
            assert!(!is_valid_slug(s), "{s:?}");
        }
        assert!(!is_valid_slug(&"a".repeat(64)));
    }

    #[test]
    fn candidate_2_appends_suffix() {
        assert_eq!(slug_candidate("catatan", 2), "catatan-2");
        assert_eq!(slug_candidate("catatan", 1), "catatan");
    }

    #[test]
    fn candidate_truncates_base_to_fit_63() {
        let c = slug_candidate(&"a".repeat(63), 2);
        assert_eq!(c.len(), 63);
        assert!(c.ends_with("-2") && is_valid_slug(&c));
        let c = slug_candidate(&format!("{}-bb", "a".repeat(60)), 2);
        assert_eq!(c, format!("{}-2", "a".repeat(60)));
    }

    #[test]
    fn slugify_output_always_valid() {
        let mut seed: u64 = 0x9E37_79B9_7F4A_7C15;
        let pool: Vec<char> = "aZ09 -_é日🚀!ñÅ\t".chars().collect();
        for _ in 0..2000 {
            let mut s = String::new();
            for _ in 0..(seed % 90) {
                seed = seed
                    .wrapping_mul(6364136223846793005)
                    .wrapping_add(1442695040888963407);
                s.push(pool[(seed >> 33) as usize % pool.len()]);
            }
            seed = seed.wrapping_add(1);
            let out = slugify(&s);
            assert!(is_valid_slug(&out), "{s:?} -> {out:?}");
        }
    }
}
