//! `frontend/dist` di-embed saat kompilasi (rust-embed), jadi harus sudah dibangun.

use std::path::Path;

fn main() {
    let dist = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../frontend/dist");
    // Kompilasi ulang bila hasil `vite build` berubah (proc-macro rust-embed tak melacaknya).
    println!("cargo:rerun-if-changed={}", dist.display());
    if !dist.join(".vite/manifest.json").is_file() {
        panic!(
            "frontend/dist belum dibangun ({} tidak ada). Jalankan dulu: npm --prefix frontend ci && npm --prefix frontend run build",
            dist.join(".vite/manifest.json").display()
        );
    }
}
