//! Komposisi app lengkap (`compose_app`) dan `serve` dengan `ConnectInfo` — yang dipanggil `main.rs`.

use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use http_body_util::BodyExt;
use sqlx::PgPool;
use std::collections::HashMap;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tower::ServiceExt;
use whisker::app::{compose_app, serve};
use whisker::config::Config;

fn config() -> Config {
    let env: HashMap<String, String> = [
        ("DATABASE_URL", "postgres://tidak-dipakai@localhost/db"),
        ("WHISKER_PUBLIC_URL", "http://localhost:8080"),
        ("WHISKER_COOKIE_SECURE", "false"),
    ]
    .into_iter()
    .map(|(k, v)| (k.to_owned(), v.to_owned()))
    .collect();
    Config::from_env(&env).unwrap()
}

fn app(pool: PgPool) -> Router {
    compose_app(pool, &config(), vec![9u8; 32]).expect("app terakit")
}

async fn send(app: &Router, req: Request<Body>) -> (StatusCode, axum::http::HeaderMap, String) {
    let resp = app.clone().oneshot(req).await.unwrap();
    let status = resp.status();
    let headers = resp.headers().clone();
    let body = resp.into_body().collect().await.unwrap().to_bytes();
    (status, headers, String::from_utf8_lossy(&body).into_owned())
}

fn get(uri: &str) -> Request<Body> {
    Request::get(uri).body(Body::empty()).unwrap()
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn composed_app_mounts_web_health_mcp_and_assets(pool: PgPool) {
    let app = app(pool);

    let (status, _, body) = send(&app, get("/health")).await;
    assert_eq!(status, StatusCode::OK, "{body}");

    // `/mcp` tanpa CSRF (bukan 419) dan tanpa guard sesi: Bearer wajib.
    let mcp = Request::post("/mcp")
        .header(header::CONTENT_TYPE, "application/json")
        .header(header::HOST, "localhost:8080")
        .header(header::ACCEPT, "application/json, text/event-stream")
        .body(Body::from(
            r#"{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}"#,
        ))
        .unwrap();
    let (status, _, _) = send(&app, mcp).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);

    let (status, headers, html) = send(&app, get("/login")).await;
    assert_eq!(status, StatusCode::OK);
    assert!(
        html.contains("Auth\\/Login") || html.contains("Auth/Login"),
        "{html}"
    );
    assert!(
        headers
            .get_all(header::SET_COOKIE)
            .iter()
            .any(|c| c.to_str().unwrap().starts_with("XSRF-TOKEN=")),
        "CsrfLayer web_router aktif"
    );
    let start = html
        .find(r#"<script type="module" src="/build/"#)
        .expect("entri JS")
        + r#"<script type="module" src=""#.len();
    let js = &html[start..start + html[start..].find('"').unwrap()];
    assert_eq!(send(&app, get(js)).await.0, StatusCode::OK);
    assert_eq!(
        send(&app, get("/build/tidak-ada.js")).await.0,
        StatusCode::NOT_FOUND
    );

    let (status, headers, _) = send(&app, get("/")).await;
    assert_eq!(status, StatusCode::FOUND);
    assert_eq!(headers[header::LOCATION], "/login");

    let (status, _, html) = send(&app, get("/tidak-ada")).await;
    assert_eq!(status, StatusCode::NOT_FOUND);
    assert!(
        html.contains("Errors\\/NotFound") || html.contains("Errors/NotFound"),
        "{html}"
    );

    // Router spike dihapus di Task 11 (ruling K3, K15): sisa rutenya jatuh ke fallback 404.
    for path in ["/spike/forbidden", "/spike/echo"] {
        assert_eq!(
            send(&app, get(path)).await.0,
            StatusCode::NOT_FOUND,
            "{path}"
        );
    }
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn root_view_has_theme_script_and_svg_favicon(pool: PgPool) {
    let app = app(pool);
    let (status, _, html) = send(&app, get("/login")).await;
    assert_eq!(status, StatusCode::OK);
    // Skrip tema inline memakai kunci yang sama dengan `frontend/src/lib/theme.ts`.
    assert!(
        html.contains(r#"localStorage.getItem("whisker-theme")"#),
        "{html}"
    );
    assert!(!html.contains(r#"getItem("theme")"#), "kunci lama: {html}");
    assert!(
        html.contains(r#"<link rel="icon" type="image/svg+xml" href="data:image/svg+xml,"#),
        "{html}"
    );
    assert!(
        !html.contains(r#"href="data:,""#),
        "favicon kosong lama: {html}"
    );
}

/// Satu request HTTP/1.1 polos; mengembalikan (status, head, body).
async fn raw_http(addr: std::net::SocketAddr, request: String) -> (u16, String, String) {
    let mut stream = TcpStream::connect(addr).await.unwrap();
    stream.write_all(request.as_bytes()).await.unwrap();
    let mut buf = Vec::new();
    stream.read_to_end(&mut buf).await.unwrap();
    let text = String::from_utf8_lossy(&buf).into_owned();
    let (head, body) = text.split_once("\r\n\r\n").unwrap_or((&text, ""));
    let status = head.split(' ').nth(1).unwrap().parse().unwrap();
    (status, head.to_owned(), body.to_owned())
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn serve_provides_connect_info_for_login_throttle(pool: PgPool) {
    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    let (stop, stopped) = tokio::sync::oneshot::channel::<()>();
    let server = tokio::spawn(serve(listener, app(pool), async {
        let _ = stopped.await;
    }));

    let (status, head, _) = raw_http(
        addr,
        format!("GET /login HTTP/1.1\r\nHost: {addr}\r\nConnection: close\r\n\r\n"),
    )
    .await;
    assert_eq!(status, 200);
    let token = head
        .lines()
        .find_map(|l| l.strip_prefix("set-cookie: XSRF-TOKEN="))
        .and_then(|v| v.split(';').next())
        .expect("XSRF-TOKEN")
        .to_owned();

    let body = r#"{"email":"tidak-ada@example.com","password":"salah-salah-salah"}"#;
    let (status, _, body) = raw_http(
        addr,
        format!(
            "POST /login HTTP/1.1\r\nHost: {addr}\r\nConnection: close\r\nX-Inertia: true\r\n\
             Content-Type: application/json\r\nCookie: XSRF-TOKEN={token}\r\n\
             X-XSRF-TOKEN: {token}\r\nContent-Length: {}\r\n\r\n{body}",
            body.len()
        ),
    )
    .await;
    assert_eq!(status, 422, "login butuh ConnectInfo (IP klien): {body}");
    assert!(body.contains("email atau password salah"), "{body}");

    stop.send(()).unwrap();
    server.await.unwrap().unwrap();
}
