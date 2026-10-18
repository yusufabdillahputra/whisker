//! `frontend/dist` di-embed saat kompilasi (rust-embed), jadi harus sudah dibangun.
//! `migrations/` di-embed oleh `sqlx::migrate!` (ADR-007).

use std::path::Path;

fn main() {
    let dist = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../frontend/dist");
    // Kompilasi ulang bila hasil `vite build` berubah (proc-macro rust-embed tak melacaknya).
    println!("cargo:rerun-if-changed={}", dist.display());
    // `sqlx::migrate!` meng-embed `migrations/` root workspace; kompilasi ulang bila berubah.
    println!("cargo:rerun-if-changed=../../migrations");
    if !dist.join(".vite/manifest.json").is_file() {
        panic!(
            "frontend/dist belum dibangun ({} tidak ada). Jalankan dulu: npm --prefix frontend ci && npm --prefix frontend run build",
            dist.join(".vite/manifest.json").display()
        );
    }
}
