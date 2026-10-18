//! Perkakas tes integrasi `whisker-web`: router web nyata + klien ber-cookie-jar.

#![allow(dead_code)]

use axum::Router;
use axum::body::Body;
use axum::extract::connect_info::MockConnectInfo;
use axum::http::{HeaderMap, Method, Request, StatusCode, header};
use http_body_util::BodyExt;
use ipnet::IpNet;
use serde_json::Value;
use sqlx::PgPool;
use std::collections::BTreeMap;
use std::net::SocketAddr;
use tower::ServiceExt;
use url::Url;
use veer::{InertiaConfig, MinimalRootView};
use whisker_core::auth::password::hash_password;
use whisker_core::user::{NewUser, Role, User, create_user};
use whisker_web::{AppState, WebConfig, web_router};

pub const VERSION: &str = "test-v1";
pub const PASSWORD: &str = "kata-sandi-uji-123";
pub const GENERIC_ERROR: &str = "email atau password salah";
pub const THROTTLE_ERROR: &str = "Terlalu banyak percobaan. Coba lagi nanti.";

/// Peer TCP tiruan (tanpa server nyata `ConnectInfo` tidak ada).
pub fn peer() -> SocketAddr {
    "203.0.113.10:50000".parse().unwrap()
}

pub fn inertia_config() -> InertiaConfig {
    InertiaConfig::new()
        .root_view(MinimalRootView::new().title("Whisker"))
        .version_str(VERSION)
}

pub fn web_config(trusted_proxies: Vec<IpNet>) -> WebConfig {
    WebConfig {
        cookie_secure: true,
        public_url: Url::parse("http://localhost:8080").unwrap(),
        trusted_proxies,
        csrf_secret: vec![7u8; 32],
    }
}

pub fn app_with(pool: PgPool, trusted_proxies: Vec<IpNet>) -> Router {
    let state = AppState::new(pool, web_config(trusted_proxies));
    web_router(state, inertia_config()).layer(MockConnectInfo(peer()))
}

pub fn app(pool: PgPool) -> Router {
    app_with(pool, Vec::new())
}

pub async fn seed_user(pool: &PgPool, email: &str, role: Role, must_change: bool) -> User {
    create_user(
        pool,
        NewUser {
            email,
            display_name: "Pengguna Uji",
            password_hash: hash_password(PASSWORD).unwrap(),
            role,
            must_change_password: must_change,
        },
    )
    .await
    .unwrap()
}

pub async fn session_count(pool: &PgPool) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM sessions")
        .fetch_one(pool)
        .await
        .unwrap()
}

pub struct Resp {
    pub status: StatusCode,
    pub headers: HeaderMap,
    pub body: Vec<u8>,
}

impl Resp {
    pub fn text(&self) -> String {
        String::from_utf8_lossy(&self.body).into_owned()
    }

    pub fn json(&self) -> Value {
        serde_json::from_slice(&self.body).unwrap_or_else(|e| panic!("{e}: {}", self.text()))
    }

    pub fn location(&self) -> Option<&str> {
        self.headers
            .get(header::LOCATION)
            .map(|v| v.to_str().unwrap())
    }

    /// Header `Set-Cookie` untuk cookie `name` (utuh, dengan atribut).
    pub fn set_cookie(&self, name: &str) -> Option<String> {
        self.headers
            .get_all(header::SET_COOKIE)
            .iter()
            .map(|v| v.to_str().unwrap().to_owned())
            .find(|c| c.starts_with(&format!("{name}=")))
    }
}

/// Klien uji: menyimpan cookie dari `Set-Cookie`, mengirim header Inertia + `X-XSRF-TOKEN`.
pub struct Client {
    pub app: Router,
    pub jar: BTreeMap<String, String>,
    pub forwarded_for: Option<String>,
}

impl Client {
    pub fn new(app: Router) -> Self {
        Self {
            app,
            jar: BTreeMap::new(),
            forwarded_for: None,
        }
    }

    pub fn cookie(&self, name: &str) -> Option<&str> {
        self.jar.get(name).map(String::as_str)
    }

    pub async fn send(
        &mut self,
        method: Method,
        uri: &str,
        json: Option<Value>,
        xsrf: bool,
    ) -> Resp {
        if xsrf && !self.jar.contains_key("XSRF-TOKEN") {
            self.raw(Method::GET, "/login", None, false).await;
        }
        self.raw(method, uri, json, xsrf).await
    }

    async fn raw(&mut self, method: Method, uri: &str, json: Option<Value>, xsrf: bool) -> Resp {
        let mut req = Request::builder()
            .method(method)
            .uri(uri)
            .header("X-Inertia", "true")
            .header("X-Inertia-Version", VERSION);
        if !self.jar.is_empty() {
            let cookies: Vec<String> = self.jar.iter().map(|(k, v)| format!("{k}={v}")).collect();
            req = req.header(header::COOKIE, cookies.join("; "));
        }
        if xsrf {
            req = req.header("X-XSRF-TOKEN", self.jar["XSRF-TOKEN"].clone());
        }
        if let Some(ip) = &self.forwarded_for {
            req = req.header("X-Forwarded-For", ip.clone());
        }
        let body = match json {
            Some(v) => {
                req = req.header(header::CONTENT_TYPE, "application/json");
                Body::from(v.to_string())
            }
            None => Body::empty(),
        };
        let resp = self
            .app
            .clone()
            .oneshot(req.body(body).unwrap())
            .await
            .unwrap();
        let status = resp.status();
        let headers = resp.headers().clone();
        let body = resp
            .into_body()
            .collect()
            .await
            .unwrap()
            .to_bytes()
            .to_vec();
        for raw in headers.get_all(header::SET_COOKIE) {
            let raw = raw.to_str().unwrap();
            let pair = raw.split(';').next().unwrap();
            let (k, v) = pair.split_once('=').unwrap();
            if raw.contains("Max-Age=0") {
                self.jar.remove(k);
            } else {
                self.jar.insert(k.to_owned(), v.to_owned());
            }
        }
        Resp {
            status,
            headers,
            body,
        }
    }

    pub async fn get(&mut self, uri: &str) -> Resp {
        self.send(Method::GET, uri, None, false).await
    }

    pub async fn post(&mut self, uri: &str, json: Value) -> Resp {
        self.send(Method::POST, uri, Some(json), true).await
    }

    pub async fn login(&mut self, email: &str, password: &str) -> Resp {
        self.post(
            "/login",
            serde_json::json!({ "email": email, "password": password }),
        )
        .await
    }
}
