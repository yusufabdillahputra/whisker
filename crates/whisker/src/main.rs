//! Binary Whisker: `serve` (default) dan `healthcheck`. Config env fail-fast.
//! `serve`: config → pool → migrate (advisory lock) → serve.

use clap::Parser;
use std::process::ExitCode;
use std::time::Duration;
use tracing_subscriber::EnvFilter;
use whisker::app::{build_app, inertia_config};
use whisker::cli::{Cli, Command};
use whisker::config::{Config, ProcessEnv, http_addr_from_env};
use whisker::health::health_router;
use whisker::startup::{connect_pool, latest_migration_version, run_migrations};

/// Batas waktu probe `whisker healthcheck` (di atas batas cek DB `/health` = 3 detik).
const HEALTHCHECK_TIMEOUT: Duration = Duration::from_secs(5);

#[tokio::main]
async fn main() -> ExitCode {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()))
        .init();
    let result = match Cli::parse().command() {
        Command::Serve => serve().await,
        Command::Healthcheck => match http_addr_from_env(&ProcessEnv) {
            Ok(addr) => return whisker::healthcheck::run(addr, HEALTHCHECK_TIMEOUT).await,
            Err(e) => Err(e.into()),
        },
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("whisker: {e}");
            ExitCode::FAILURE
        }
    }
}

async fn serve() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_env(&ProcessEnv)?;
    let pool = connect_pool(&config.database_url)
        .await
        .map_err(|e| format!("koneksi database gagal: {e}"))?;
    run_migrations(&pool)
        .await
        .map_err(|e| format!("migration gagal: {e}"))?;
    let migration = latest_migration_version(&pool).await?;
    tracing::info!(migration = ?migration, "migration database terkini");

    // Secret CSRF acak per proses: cookie lama tak berlaku setelah restart (cukup untuk spike).
    let mut csrf_secret = vec![0u8; 32];
    getrandom::fill(&mut csrf_secret).map_err(|e| format!("getrandom: {e}"))?;

    let cfg = inertia_config(config.vite_dev_server.as_deref())?;
    let web = whisker_web::spike::router(cfg, csrf_secret, config.cookie_secure);
    let app = build_app(web, health_router(pool));

    let listener = tokio::net::TcpListener::bind(config.http_addr).await?;
    tracing::info!(config = ?config, "whisker listening");
    axum::serve(listener, app)
        .with_graceful_shutdown(async {
            let _ = tokio::signal::ctrl_c().await;
        })
        .await?;
    Ok(())
}
