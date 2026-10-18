//! `/mcp` ter-mount di app lengkap (router web + `CsrfLayer`) dengan origin dari `WHISKER_PUBLIC_URL`.

use axum::Router;
use axum::body::Body;
use axum::http::{Request, StatusCode, header};
use http_body_util::BodyExt;
use sqlx::PgPool;
use tower::ServiceExt;
use url::Url;
use whisker::app::{build_app, inertia_config, mcp_config};
use whisker_core::token::create_token;
use whisker_core::user::{NewUser, Role, create_user};
use whisker_mcp::mcp_router;
use whisker_web::{AppState, WebConfig, web_router};

const TOOLS_LIST: &str = r#"{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}"#;

fn app(pool: PgPool) -> Router {
    let public = Url::parse("http://localhost:8080").unwrap();
    let state = AppState::new(
        pool.clone(),
        WebConfig {
            cookie_secure: false,
            public_url: public.clone(),
            trusted_proxies: Vec::new(),
            csrf_secret: vec![9u8; 32],
        },
    );
    let web = web_router(state, inertia_config(None).unwrap());
    build_app(web, mcp_router(pool, mcp_config(&public)))
}

/// `Host` wajib bagi rmcp; `oneshot` tidak menambahkannya sendiri.
async fn post_mcp(app: Router, headers: &[(&str, &str)]) -> (StatusCode, Option<String>, String) {
    let mut req = Request::post("/mcp")
        .header(header::CONTENT_TYPE, "application/json")
        .header(header::HOST, "localhost:8080")
        .header(header::ACCEPT, "application/json, text/event-stream");
    for (k, v) in headers {
        req = req.header(*k, *v);
    }
    let res = app
        .oneshot(req.body(Body::from(TOOLS_LIST)).unwrap())
        .await
        .unwrap();
    let status = res.status();
    let www = res
        .headers()
        .get(header::WWW_AUTHENTICATE)
        .map(|v| v.to_str().unwrap().to_owned());
    let body = res.into_body().collect().await.unwrap().to_bytes();
    (status, www, String::from_utf8_lossy(&body).into_owned())
}

#[test]
fn mcp_config_uses_public_url_origin() {
    let cases = [
        ("http://localhost:8080", "http://localhost:8080"),
        (
            "https://Whisker.Example.com:443/app/",
            "https://whisker.example.com",
        ),
        ("http://10.0.0.5:3000/", "http://10.0.0.5:3000"),
    ];
    for (public, origin) in cases {
        let cfg = mcp_config(&Url::parse(public).unwrap());
        assert_eq!(cfg.allowed_origin.as_deref(), Some(origin), "{public}");
    }
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn mounted_mcp_requires_bearer(pool: PgPool) {
    let (status, www, body) = post_mcp(app(pool), &[]).await;
    assert_eq!(status, StatusCode::UNAUTHORIZED);
    assert_eq!(www.as_deref(), Some("Bearer"));
    assert_eq!(body, r#"{"error":"unauthorized"}"#);
}

#[sqlx::test(migrator = "whisker::startup::MIGRATOR")]
async fn mounted_mcp_serves_valid_token_without_csrf_and_rejects_foreign_origin(pool: PgPool) {
    let user = create_user(
        &pool,
        NewUser {
            email: "ani@example.com",
            display_name: "Ani",
            password_hash: "$argon2id$v=19$m=19456,t=2,p=1$c2FsdA$aGFzaA".to_owned(),
            role: Role::Member,
            must_change_password: false,
        },
    )
    .await
    .unwrap();
    let (_, plain) = create_token(&pool, user.id, "CLI").await.unwrap();
    let bearer = format!("Bearer {}", plain.expose());

    let (status, _, body) = post_mcp(app(pool.clone()), &[("authorization", &bearer)]).await;
    assert_eq!(status, StatusCode::OK, "{body}");
    assert!(body.contains("\"whoami\""), "{body}");

    let (status, _, _) = post_mcp(
        app(pool.clone()),
        &[
            ("authorization", &bearer),
            ("origin", "http://localhost:8080"),
        ],
    )
    .await;
    assert_eq!(status, StatusCode::OK);

    let (status, _, _) = post_mcp(
        app(pool),
        &[
            ("authorization", &bearer),
            ("origin", "https://evil.example"),
        ],
    )
    .await;
    assert_eq!(status, StatusCode::FORBIDDEN);
}
