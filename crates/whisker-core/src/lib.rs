//! Domain inti Whisker — tanpa dependensi web/IO.

pub mod auth;
pub mod error;
pub mod user;
pub mod vault;

#[cfg(test)]
mod export {
    use std::path::PathBuf;

    /// Tulis file data generated ke `TS_RS_EXPORT_DIR` (diset `.cargo/config.toml`).
    pub fn write_generated(file: &str, content: &str) {
        let dir = std::env::var_os("TS_RS_EXPORT_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|| {
                PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../frontend/src/types/generated")
            });
        std::fs::create_dir_all(&dir).expect("buat direktori generated");
        std::fs::write(dir.join(file), content).expect("tulis file generated");
    }
}
