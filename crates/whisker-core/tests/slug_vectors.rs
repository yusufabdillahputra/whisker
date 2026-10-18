//! Vektor slug bersama Rust ↔ TS (`frontend/src/lib/slugify.test.ts` memakai fixture yang sama).

use serde::Deserialize;
use whisker_core::vault::slug::{is_valid_slug, slug_candidate, slugify};

#[derive(Deserialize)]
struct SlugCase {
    name: String,
    expected: String,
}

#[derive(Deserialize)]
struct CandidateCase {
    base: String,
    attempt: u32,
    expected: String,
}

#[derive(Deserialize)]
struct Vectors {
    slugify: Vec<SlugCase>,
    candidate: Vec<CandidateCase>,
}

fn load() -> Vectors {
    let raw = include_str!("fixtures/slug_vectors.json");
    serde_json::from_str(raw).expect("fixture slug_vectors.json valid")
}

#[test]
fn slugify_matches_shared_vectors() {
    for c in load().slugify {
        let got = slugify(&c.name);
        assert_eq!(got, c.expected, "slugify({:?})", c.name);
        assert!(is_valid_slug(&got), "keluaran tidak valid: {got:?}");
    }
}

#[test]
fn slug_candidate_matches_shared_vectors() {
    for c in load().candidate {
        let got = slug_candidate(&c.base, c.attempt);
        assert_eq!(
            got, c.expected,
            "slug_candidate({:?}, {})",
            c.base, c.attempt
        );
        assert!(is_valid_slug(&got), "keluaran tidak valid: {got:?}");
    }
}
