//! Binary Whisker. Konfigurasi env sementara (spike Task 01); config fail-fast = Task 02.

use axum::Router;
use tracing_subscriber::EnvFilter;
use whisker::app::{build_app, inertia_config};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()))
        .init();

    let addr = std::env::var("WHISKER_HTTP_ADDR").unwrap_or_else(|_| "127.0.0.1:8080".into());
    let vite_dev = std::env::var("WHISKER_VITE_DEV_SERVER").ok();
    let secure_cookie =
        std::env::var("WHISKER_PUBLIC_URL").is_ok_and(|u| u.starts_with("https://"));

    // Secret CSRF acak per proses: cookie lama tak berlaku setelah restart (cukup untuk spike).
    let mut csrf_secret = vec![0u8; 32];
    getrandom::fill(&mut csrf_secret).map_err(|e| format!("getrandom: {e}"))?;

    let cfg = inertia_config(vite_dev.as_deref())?;
    let web = whisker_web::spike::router(cfg, csrf_secret, secure_cookie);
    let app = build_app(web, Router::new());

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!(%addr, vite_dev = vite_dev.as_deref().unwrap_or("-"), "whisker listening");
    axum::serve(listener, app)
        .with_graceful_shutdown(async {
            let _ = tokio::signal::ctrl_c().await;
        })
        .await?;
    Ok(())
}
