//! Konfigurasi dari env (fail-fast).

use ipnet::IpNet;
use std::collections::HashMap;
use std::fmt;
use std::net::SocketAddr;
use url::Url;

const DEFAULT_HTTP_ADDR: &str = "0.0.0.0:8080";

/// Sumber nilai env; dapat diganti `HashMap` pada tes.
pub trait EnvSource {
    fn get(&self, key: &str) -> Option<String>;
}

pub struct ProcessEnv;

impl EnvSource for ProcessEnv {
    fn get(&self, key: &str) -> Option<String> {
        std::env::var(key).ok()
    }
}

impl EnvSource for HashMap<String, String> {
    fn get(&self, key: &str) -> Option<String> {
        HashMap::get(self, key).cloned()
    }
}

#[derive(Debug, PartialEq, Eq)]
pub enum ConfigError {
    Missing(&'static str),
    Placeholder(&'static str),
    Invalid { name: &'static str, reason: String },
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Missing(n) => write!(f, "variabel env {n} wajib diisi (kosong atau tidak ada)"),
            Self::Placeholder(n) => {
                write!(
                    f,
                    "variabel env {n} masih berisi placeholder (<...>); isi nilai sebenarnya"
                )
            }
            Self::Invalid { name, reason } => {
                write!(f, "variabel env {name} tidak valid: {reason}")
            }
        }
    }
}

impl std::error::Error for ConfigError {}

/// Nilai memuat `<` atau `>` dianggap placeholder dari `.env.example`.
pub fn is_placeholder(value: &str) -> bool {
    value.contains('<') || value.contains('>')
}

/// Placeholder untuk nilai rahasia (password): hanya bila seluruh nilai (ter-trim) berbentuk `<...>`.
/// `<`/`>` di tengah password sah — kebijakan password tanpa aturan komposisi.
pub fn is_whole_placeholder(value: &str) -> bool {
    let v = value.trim();
    v.starts_with('<') && v.ends_with('>')
}

/// Nilai env ter-trim; kosong dianggap absen.
fn optional(env: &impl EnvSource, name: &'static str) -> Option<String> {
    env.get(name)
        .map(|v| v.trim().to_owned())
        .filter(|v| !v.is_empty())
}

/// Nilai env apa adanya (tanpa trim, untuk rahasia seperti password); hanya kosong yang dianggap absen.
fn optional_raw(env: &impl EnvSource, name: &'static str) -> Option<String> {
    env.get(name).filter(|v| !v.is_empty())
}

fn required(env: &impl EnvSource, name: &'static str) -> Result<String, ConfigError> {
    let v = optional(env, name).ok_or(ConfigError::Missing(name))?;
    if is_placeholder(&v) {
        return Err(ConfigError::Placeholder(name));
    }
    Ok(v)
}

fn invalid(name: &'static str, reason: impl ToString) -> ConfigError {
    ConfigError::Invalid {
        name,
        reason: reason.to_string(),
    }
}

/// Alamat bind HTTP; terpisah agar `healthcheck` tak butuh `DATABASE_URL`.
pub fn http_addr_from_env(env: &impl EnvSource) -> Result<SocketAddr, ConfigError> {
    const NAME: &str = "WHISKER_HTTP_ADDR";
    optional(env, NAME)
        .unwrap_or_else(|| DEFAULT_HTTP_ADDR.to_owned())
        .parse()
        .map_err(|e| invalid(NAME, format!("{e} (contoh 0.0.0.0:8080)")))
}

/// Env bootstrap admin pertama (logikanya = Task 06). Opsional di level config.
#[derive(Clone, PartialEq, Eq)]
pub struct BootstrapEnv {
    pub email: Option<String>,
    pub password: Option<String>,
}

impl fmt::Debug for BootstrapEnv {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("BootstrapEnv")
            .field("email", &self.email)
            .field("password", &self.password.as_ref().map(|_| "***"))
            .finish()
    }
}

#[derive(Clone)]
pub struct Config {
    pub http_addr: SocketAddr,
    pub public_url: Url,
    pub database_url: String,
    pub cookie_secure: bool,
    pub trusted_proxies: Vec<IpNet>,
    pub admin: BootstrapEnv,
    /// Hanya dev: URL Vite dev server (HMR). Kosong = pakai aset ter-embed.
    pub vite_dev_server: Option<String>,
}

impl fmt::Debug for Config {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("Config")
            .field("http_addr", &self.http_addr)
            .field("public_url", &self.public_url.as_str())
            .field("database_url", &redact_url(&self.database_url))
            .field("cookie_secure", &self.cookie_secure)
            .field("trusted_proxies", &self.trusted_proxies)
            .field("admin", &self.admin)
            .field("vite_dev_server", &self.vite_dev_server)
            .finish()
    }
}

/// Ganti password di URL dengan `***` untuk log/Debug.
fn redact_url(raw: &str) -> String {
    match Url::parse(raw) {
        Ok(mut u) => {
            if u.password().is_some() {
                let _ = u.set_password(Some("***"));
            }
            u.to_string()
        }
        Err(_) => "<tidak ter-parse>".to_owned(),
    }
}

impl Config {
    pub fn from_env(env: &impl EnvSource) -> Result<Self, ConfigError> {
        let database_url = required(env, "DATABASE_URL")?;
        let public_raw = required(env, "WHISKER_PUBLIC_URL")?;
        let public_url = Url::parse(&public_raw).map_err(|e| invalid("WHISKER_PUBLIC_URL", e))?;
        if !matches!(public_url.scheme(), "http" | "https") {
            return Err(invalid("WHISKER_PUBLIC_URL", "harus http:// atau https://"));
        }
        let http_addr = http_addr_from_env(env)?;

        let cookie_secure = match optional(env, "WHISKER_COOKIE_SECURE").as_deref() {
            None | Some("true") => true,
            Some("false") => false,
            Some(other) => {
                return Err(invalid(
                    "WHISKER_COOKIE_SECURE",
                    format!("`{other}` bukan true/false"),
                ));
            }
        };

        let trusted_proxies = match optional(env, "WHISKER_TRUSTED_PROXIES") {
            None => Vec::new(),
            Some(list) => list
                .split(',')
                .map(str::trim)
                .filter(|s| !s.is_empty())
                .map(|s| {
                    s.parse::<IpNet>()
                        .map_err(|e| invalid("WHISKER_TRUSTED_PROXIES", format!("`{s}`: {e}")))
                })
                .collect::<Result<_, _>>()?,
        };

        Ok(Self {
            http_addr,
            public_url,
            database_url,
            cookie_secure,
            trusted_proxies,
            admin: BootstrapEnv {
                email: optional(env, "WHISKER_ADMIN_EMAIL"),
                password: optional_raw(env, "WHISKER_ADMIN_PASSWORD"),
            },
            vite_dev_server: optional(env, "WHISKER_VITE_DEV_SERVER"),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    const DB: &str = "postgres://u:s3cret@localhost:5432/db-whisker";

    fn env(pairs: &[(&str, &str)]) -> HashMap<String, String> {
        pairs
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect()
    }

    fn minimal() -> HashMap<String, String> {
        env(&[
            ("DATABASE_URL", DB),
            ("WHISKER_PUBLIC_URL", "http://localhost:8080"),
        ])
    }

    #[test]
    fn missing_database_url_names_variable() {
        let e = env(&[("WHISKER_PUBLIC_URL", "http://localhost:8080")]);
        let err = Config::from_env(&e).unwrap_err();
        assert!(matches!(err, ConfigError::Missing("DATABASE_URL")));
        assert!(err.to_string().contains("DATABASE_URL"));
    }

    #[test]
    fn placeholder_database_url_rejected() {
        let mut e = minimal();
        e.insert(
            "DATABASE_URL".into(),
            "postgres://<user>:<password>@host.docker.internal:5432/db-whisker".into(),
        );
        let err = Config::from_env(&e).unwrap_err();
        assert!(matches!(err, ConfigError::Placeholder("DATABASE_URL")));
        assert!(err.to_string().contains("DATABASE_URL"));
        assert!(is_placeholder("a<b") && is_placeholder("a>b") && !is_placeholder("ab"));
        // Rahasia (password): hanya bentuk utuh `<...>` yang placeholder.
        assert!(is_whole_placeholder("<isi-password-admin>"));
        assert!(is_whole_placeholder("  <isi>  "));
        assert!(!is_whole_placeholder("ab<cd>ef1234xyz"));
        assert!(!is_whole_placeholder("<awal-saja"));
        assert!(!is_whole_placeholder("akhir-saja>"));
    }

    #[test]
    fn empty_value_treated_as_missing() {
        let mut e = minimal();
        e.insert("DATABASE_URL".into(), "   ".into());
        assert!(matches!(
            Config::from_env(&e).unwrap_err(),
            ConfigError::Missing("DATABASE_URL")
        ));
    }

    #[test]
    fn valid_minimal_env_parses() {
        let c = Config::from_env(&minimal()).unwrap();
        assert_eq!(c.http_addr, "0.0.0.0:8080".parse().unwrap());
        assert!(c.cookie_secure);
        assert!(c.trusted_proxies.is_empty());
        assert_eq!(c.vite_dev_server, None);
        assert_eq!(c.admin.email, None);
    }

    #[test]
    fn cookie_secure_false_parses() {
        let mut e = minimal();
        e.insert("WHISKER_COOKIE_SECURE".into(), "false".into());
        assert!(!Config::from_env(&e).unwrap().cookie_secure);
    }

    #[test]
    fn cookie_secure_invalid_rejected() {
        let mut e = minimal();
        e.insert("WHISKER_COOKIE_SECURE".into(), "yes".into());
        let err = Config::from_env(&e).unwrap_err();
        assert!(matches!(
            err,
            ConfigError::Invalid {
                name: "WHISKER_COOKIE_SECURE",
                ..
            }
        ));
        assert!(err.to_string().contains("WHISKER_COOKIE_SECURE"));
    }

    #[test]
    fn public_url_invalid_rejected() {
        let mut e = minimal();
        e.insert("WHISKER_PUBLIC_URL".into(), "bukan url".into());
        let err = Config::from_env(&e).unwrap_err();
        assert!(matches!(
            err,
            ConfigError::Invalid {
                name: "WHISKER_PUBLIC_URL",
                ..
            }
        ));
    }

    #[test]
    fn http_addr_invalid_rejected_and_healthcheck_helper_needs_no_database() {
        let e = env(&[("WHISKER_HTTP_ADDR", "9999")]);
        assert!(matches!(
            http_addr_from_env(&e).unwrap_err(),
            ConfigError::Invalid {
                name: "WHISKER_HTTP_ADDR",
                ..
            }
        ));
        assert_eq!(
            http_addr_from_env(&env(&[])).unwrap(),
            "0.0.0.0:8080".parse().unwrap()
        );
    }

    #[test]
    fn trusted_proxies_parses_cidr_list() {
        let mut e = minimal();
        e.insert(
            "WHISKER_TRUSTED_PROXIES".into(),
            "127.0.0.1/32,::1/128".into(),
        );
        assert_eq!(Config::from_env(&e).unwrap().trusted_proxies.len(), 2);
    }

    #[test]
    fn trusted_proxies_empty_means_none() {
        let mut e = minimal();
        assert!(Config::from_env(&e).unwrap().trusted_proxies.is_empty());
        e.insert("WHISKER_TRUSTED_PROXIES".into(), "".into());
        assert!(Config::from_env(&e).unwrap().trusted_proxies.is_empty());
    }

    #[test]
    fn trusted_proxies_invalid_cidr_rejected() {
        let mut e = minimal();
        e.insert("WHISKER_TRUSTED_PROXIES".into(), "127.0.0.1/32,nope".into());
        assert!(matches!(
            Config::from_env(&e).unwrap_err(),
            ConfigError::Invalid {
                name: "WHISKER_TRUSTED_PROXIES",
                ..
            }
        ));
    }

    #[test]
    fn bootstrap_env_reads_both() {
        let mut e = minimal();
        e.insert("WHISKER_ADMIN_EMAIL".into(), "a@b.id".into());
        e.insert("WHISKER_ADMIN_PASSWORD".into(), "pw-rahasia".into());
        let c = Config::from_env(&e).unwrap();
        assert_eq!(c.admin.email.as_deref(), Some("a@b.id"));
        assert_eq!(c.admin.password.as_deref(), Some("pw-rahasia"));
    }

    #[test]
    fn bootstrap_password_taken_raw_email_trimmed() {
        let mut e = minimal();
        e.insert("WHISKER_ADMIN_EMAIL".into(), "  a@b.id \n".into());
        e.insert("WHISKER_ADMIN_PASSWORD".into(), "  pw rahasia  ".into());
        let c = Config::from_env(&e).unwrap();
        assert_eq!(c.admin.email.as_deref(), Some("a@b.id"));
        assert_eq!(c.admin.password.as_deref(), Some("  pw rahasia  "));

        // Hanya nilai kosong yang dianggap absen; spasi saja tetap nilai (ditolak kebijakan password).
        e.insert("WHISKER_ADMIN_PASSWORD".into(), "".into());
        assert_eq!(Config::from_env(&e).unwrap().admin.password, None);
        e.insert("WHISKER_ADMIN_PASSWORD".into(), "   ".into());
        assert_eq!(
            Config::from_env(&e).unwrap().admin.password.as_deref(),
            Some("   ")
        );
    }

    #[test]
    fn bootstrap_env_debug_redacts_password() {
        let b = BootstrapEnv {
            email: Some("a@b.id".into()),
            password: Some("pw-rahasia".into()),
        };
        let s = format!("{b:?}");
        assert!(!s.contains("pw-rahasia") && s.contains("a@b.id"));
    }

    #[test]
    fn config_debug_redacts_database_password() {
        let s = format!("{:?}", Config::from_env(&minimal()).unwrap());
        assert!(!s.contains("s3cret"));
    }

    #[test]
    fn vite_dev_server_is_optional_dev_setting() {
        let mut e = minimal();
        e.insert(
            "WHISKER_VITE_DEV_SERVER".into(),
            "http://localhost:5173".into(),
        );
        assert_eq!(
            Config::from_env(&e).unwrap().vite_dev_server.as_deref(),
            Some("http://localhost:5173")
        );
    }
}
