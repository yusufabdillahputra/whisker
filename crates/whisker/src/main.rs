//! Binary Whisker: `serve` (default) dan `healthcheck`. Config env fail-fast.

use axum::Router;
use clap::Parser;
use std::process::ExitCode;
use tracing_subscriber::EnvFilter;
use whisker::app::{build_app, inertia_config};
use whisker::cli::{Cli, Command};
use whisker::config::{Config, ProcessEnv, http_addr_from_env};

#[tokio::main]
async fn main() -> ExitCode {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()))
        .init();
    match run(Cli::parse()).await {
        Ok(()) => ExitCode::SUCCESS,
        Err(e) => {
            eprintln!("whisker: {e}");
            ExitCode::FAILURE
        }
    }
}

async fn run(cli: Cli) -> Result<(), Box<dyn std::error::Error>> {
    match cli.command() {
        Command::Serve => serve().await,
        Command::Healthcheck => {
            // Probe `/healthz` = Task 03; sementara hanya validasi alamat.
            let addr = http_addr_from_env(&ProcessEnv)?;
            Err(format!("healthcheck belum diimplementasi (Task 03); alamat {addr}").into())
        }
    }
}

async fn serve() -> Result<(), Box<dyn std::error::Error>> {
    let config = Config::from_env(&ProcessEnv)?;

    // Secret CSRF acak per proses: cookie lama tak berlaku setelah restart (cukup untuk spike).
    let mut csrf_secret = vec![0u8; 32];
    getrandom::fill(&mut csrf_secret).map_err(|e| format!("getrandom: {e}"))?;

    let cfg = inertia_config(config.vite_dev_server.as_deref())?;
    let web = whisker_web::spike::router(cfg, csrf_secret, config.cookie_secure);
    let app = build_app(web, Router::new());

    let listener = tokio::net::TcpListener::bind(config.http_addr).await?;
    tracing::info!(config = ?config, "whisker listening");
    axum::serve(listener, app)
        .with_graceful_shutdown(async {
            let _ = tokio::signal::ctrl_c().await;
        })
        .await?;
    Ok(())
}
