//! `whisker healthcheck` (Infra-2 bagian bin): GET `/health` ke alamat sendiri tanpa curl.

use axum::Router;
use axum::http::StatusCode;
use axum::routing::get;
use sqlx::PgPool;
use sqlx::postgres::PgPoolOptions;
use std::net::SocketAddr;
use std::process::ExitCode;
use std::time::{Duration, Instant};
use tokio::net::TcpListener;
use whisker::health::health_router;
use whisker::healthcheck;

const TIMEOUT: Duration = Duration::from_secs(2);

async fn serve(app: Router) -> SocketAddr {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move { axum::serve(listener, app).await.unwrap() });
    addr
}

async fn closed_port() -> u16 {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    listener.local_addr().unwrap().port()
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn exit_zero_when_health_200(pool: PgPool) {
    let addr = serve(health_router(pool)).await;
    assert_eq!(healthcheck::run(addr, TIMEOUT).await, ExitCode::SUCCESS);
}

#[tokio::test]
async fn exit_non_zero_when_unreachable() {
    let addr: SocketAddr = format!("127.0.0.1:{}", closed_port().await)
        .parse()
        .unwrap();
    assert_eq!(healthcheck::run(addr, TIMEOUT).await, ExitCode::FAILURE);
}

#[tokio::test]
async fn exit_non_zero_when_health_503() {
    let url = format!(
        "postgres://whisker:x@127.0.0.1:{}/none",
        closed_port().await
    );
    let pool = PgPoolOptions::new()
        .acquire_timeout(Duration::from_millis(300))
        .connect_lazy(&url)
        .unwrap();
    let addr = serve(health_router(pool)).await;
    assert_eq!(healthcheck::run(addr, TIMEOUT).await, ExitCode::FAILURE);
}

#[tokio::test]
async fn exit_non_zero_when_server_never_answers() {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    // Terima koneksi lalu diam: probe harus berhenti di batas waktu, bukan menggantung.
    tokio::spawn(async move {
        let mut held = Vec::new();
        while let Ok((sock, _)) = listener.accept().await {
            held.push(sock);
        }
    });
    let started = Instant::now();
    let code = healthcheck::run(addr, Duration::from_millis(300)).await;
    assert_eq!(code, ExitCode::FAILURE);
    assert!(started.elapsed() < Duration::from_secs(2));
}

#[tokio::test]
async fn unspecified_bind_address_probes_loopback() {
    // `WHISKER_HTTP_ADDR=0.0.0.0:<port>` (default container) → probe ke 127.0.0.1:<port>.
    let app = Router::new().route("/health", get(|| async { StatusCode::OK }));
    let served = serve(app).await;
    let addr: SocketAddr = format!("0.0.0.0:{}", served.port()).parse().unwrap();
    assert_eq!(healthcheck::run(addr, TIMEOUT).await, ExitCode::SUCCESS);
}
