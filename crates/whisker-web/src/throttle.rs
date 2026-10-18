//! Throttle login in-memory per proses (A2): `max_failures` kegagalan dalam `window` per email
//! **dan** per IP → `429`. Jendela bergeser; hanya kegagalan yang dicatat.
//!
//! Login memakai reservasi atomik [`LoginThrottle::try_begin`]: percobaan yang sedang berjalan
//! (belum selesai verifikasi Argon2) dihitung sebagai kegagalan sementara di bawah mutex yang sama,
//! sehingga burst paralel tidak bisa melampaui kuota (dan tak memicu ratusan Argon2 serentak).

use std::collections::{HashMap, VecDeque};
use std::net::IpAddr;
use std::sync::{Arc, Mutex};
use std::time::{Duration, Instant};

/// Kunci throttle. `email` sudah trim + lowercase (pakai [`ThrottleKey::new`]).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ThrottleKey {
    pub email: String,
    pub ip: IpAddr,
}

impl ThrottleKey {
    pub fn new(email: &str, ip: IpAddr) -> Self {
        Self {
            email: email.trim().to_lowercase(),
            ip,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ThrottleDecision {
    Allowed,
    Limited { retry_after: Duration },
}

/// Batas standar Plan 02: 5 gagal / 15 menit.
pub const STANDARD_MAX_FAILURES: u32 = 5;
pub const STANDARD_WINDOW: Duration = Duration::from_secs(15 * 60);

/// Jarak minimum antar pemangkasan penuh entri basi (dijalankan saat mencatat kegagalan).
const PRUNE_INTERVAL: Duration = Duration::from_secs(60);

/// Throttle login. Tiap kunci menyimpan paling banyak `max_failures` waktu kegagalan terbaru
/// (cukup untuk keputusan), dan kunci yang semua kegagalannya sudah di luar jendela dipangkas
/// paling lambat `PRUNE_INTERVAL` setelahnya, sehingga memori tidak tumbuh tanpa batas.
pub struct LoginThrottle {
    max_failures: u32,
    window: Duration,
    state: Mutex<State>,
}

#[derive(Default)]
struct State {
    by_email: HashMap<String, VecDeque<Instant>>,
    by_ip: HashMap<IpAddr, VecDeque<Instant>>,
    /// Reservasi yang belum selesai (dihitung sebagai kegagalan sementara).
    in_flight_email: HashMap<String, u32>,
    in_flight_ip: HashMap<IpAddr, u32>,
    last_prune: Option<Instant>,
}

impl LoginThrottle {
    pub fn new(max_failures: u32, window: Duration) -> Self {
        Self {
            max_failures,
            window,
            state: Mutex::new(State::default()),
        }
    }

    /// 5 gagal / 15 menit.
    pub fn standard() -> Self {
        Self::new(STANDARD_MAX_FAILURES, STANDARD_WINDOW)
    }

    /// `Limited` bila email **atau** IP sudah mencapai `max_failures` kegagalan dalam jendela.
    /// Dipanggil sebelum verifikasi password.
    pub fn check(&self, key: &ThrottleKey, now: Instant) -> ThrottleDecision {
        let state = self.lock();
        match self.limited_locked(&state, key, now) {
            Some(retry_after) => ThrottleDecision::Limited { retry_after },
            None => ThrottleDecision::Allowed,
        }
    }

    /// Reservasi atomik satu percobaan login: `Err` bila email atau IP (kegagalan tercatat +
    /// percobaan yang sedang berjalan) sudah mencapai `max_failures`. `Attempt` yang di-drop tanpa
    /// [`Attempt::succeeded`] / [`Attempt::abandon`] dicatat sebagai kegagalan.
    pub fn try_begin(
        self: &Arc<Self>,
        key: &ThrottleKey,
        now: Instant,
    ) -> Result<Attempt, Limited> {
        let mut state = self.lock();
        if let Some(retry_after) = self.limited_locked(&state, key, now) {
            return Err(Limited { retry_after });
        }
        *state.in_flight_email.entry(key.email.clone()).or_default() += 1;
        *state.in_flight_ip.entry(key.ip).or_default() += 1;
        Ok(Attempt {
            throttle: Arc::clone(self),
            key: key.clone(),
            settled: false,
        })
    }

    fn limited_locked(&self, state: &State, key: &ThrottleKey, now: Instant) -> Option<Duration> {
        let email = self.retry_after(
            state.by_email.get(&key.email),
            state.in_flight_email.get(&key.email).copied().unwrap_or(0),
            now,
        );
        let ip = self.retry_after(
            state.by_ip.get(&key.ip),
            state.in_flight_ip.get(&key.ip).copied().unwrap_or(0),
            now,
        );
        email.into_iter().chain(ip).max()
    }

    /// Lepas reservasi `key` (tanpa mencatat apa pun).
    fn release(&self, state: &mut State, key: &ThrottleKey) {
        fn dec<K: std::hash::Hash + Eq>(map: &mut HashMap<K, u32>, k: &K) {
            if let Some(n) = map.get_mut(k) {
                *n = n.saturating_sub(1);
                if *n == 0 {
                    map.remove(k);
                }
            }
        }
        dec(&mut state.in_flight_email, &key.email);
        dec(&mut state.in_flight_ip, &key.ip);
    }

    /// Catat satu kegagalan login untuk email dan IP pada `key`.
    pub fn record_failure(&self, key: &ThrottleKey, now: Instant) {
        let mut state = self.lock();
        self.record_failure_locked(&mut state, key, now);
    }

    fn record_failure_locked(&self, state: &mut State, key: &ThrottleKey, now: Instant) {
        if state
            .last_prune
            .is_none_or(|last| now.saturating_duration_since(last) >= PRUNE_INTERVAL)
        {
            self.prune_locked(state, now);
        }
        let cap = self.max_failures as usize;
        push_capped(
            state.by_email.entry(key.email.clone()).or_default(),
            now,
            cap,
        );
        push_capped(state.by_ip.entry(key.ip).or_default(), now, cap);
    }

    /// Buang semua kegagalan di luar jendela dan kunci yang kosong.
    pub fn prune(&self, now: Instant) {
        let mut state = self.lock();
        self.prune_locked(&mut state, now);
    }

    fn prune_locked(&self, state: &mut State, now: Instant) {
        let window = self.window;
        let live = |failures: &mut VecDeque<Instant>| {
            while failures
                .front()
                .is_some_and(|t| now.saturating_duration_since(*t) >= window)
            {
                failures.pop_front();
            }
            !failures.is_empty()
        };
        state.by_email.retain(|_, f| live(f));
        state.by_ip.retain(|_, f| live(f));
        state.last_prune = Some(now);
    }

    /// Sisa waktu sampai kunci bebas, bila kegagalan dalam jendela + reservasi berjalan (dihitung
    /// sebagai kegagalan pada `now`) sudah `>= max_failures`.
    fn retry_after(
        &self,
        failures: Option<&VecDeque<Instant>>,
        in_flight: u32,
        now: Instant,
    ) -> Option<Duration> {
        let mut active: Vec<Instant> = failures
            .into_iter()
            .flatten()
            .copied()
            .filter(|t| now.saturating_duration_since(*t) < self.window)
            .collect();
        active.extend(std::iter::repeat_n(now, in_flight as usize));
        if active.len() < self.max_failures as usize {
            return None;
        }
        // Kunci bebas begitu kegagalan aktif ke-(n - max + 1) dari belakang keluar jendela.
        let pivot = active[active.len() - self.max_failures as usize];
        Some((pivot + self.window).saturating_duration_since(now))
    }

    fn lock(&self) -> std::sync::MutexGuard<'_, State> {
        self.state.lock().unwrap_or_else(|e| e.into_inner())
    }

    #[cfg(test)]
    fn tracked_keys(&self) -> usize {
        let state = self.lock();
        state.by_email.len()
            + state.by_ip.len()
            + state.in_flight_email.len()
            + state.in_flight_ip.len()
    }
}

/// Reservasi ditolak throttle.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Limited {
    pub retry_after: Duration,
}

/// Reservasi satu percobaan login (lihat [`LoginThrottle::try_begin`]). Drop tanpa penyelesaian
/// eksplisit = kegagalan tercatat (gagal verifikasi, atau handler berhenti di tengah jalan).
pub struct Attempt {
    throttle: Arc<LoginThrottle>,
    key: ThrottleKey,
    settled: bool,
}

impl Attempt {
    /// Login sukses: lepas reservasi, tidak dihitung kegagalan.
    pub fn succeeded(mut self) {
        self.settle(false);
    }

    /// Percobaan batal karena sebab di luar tebakan password (error server, password berubah
    /// bersamaan): lepas reservasi tanpa mencatat kegagalan.
    pub fn abandon(mut self) {
        self.settle(false);
    }

    fn settle(&mut self, failed: bool) {
        if self.settled {
            return;
        }
        self.settled = true;
        let mut state = self.throttle.lock();
        self.throttle.release(&mut state, &self.key);
        if failed {
            self.throttle
                .record_failure_locked(&mut state, &self.key, Instant::now());
        }
    }
}

impl Drop for Attempt {
    fn drop(&mut self) {
        self.settle(true);
    }
}

fn push_capped(failures: &mut VecDeque<Instant>, now: Instant, cap: usize) {
    failures.push_back(now);
    while failures.len() > cap.max(1) {
        failures.pop_front();
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::net::Ipv4Addr;

    const MIN: Duration = Duration::from_secs(60);

    fn ip(n: u8) -> IpAddr {
        IpAddr::V4(Ipv4Addr::new(203, 0, 113, n))
    }

    fn key(email: &str, n: u8) -> ThrottleKey {
        ThrottleKey::new(email, ip(n))
    }

    fn limited(d: ThrottleDecision) -> bool {
        matches!(d, ThrottleDecision::Limited { .. })
    }

    #[test]
    fn allows_first_five_failures() {
        let t = LoginThrottle::standard();
        let now = Instant::now();
        let k = key("ani@example.com", 1);
        for i in 0..5 {
            assert_eq!(
                t.check(&k, now),
                ThrottleDecision::Allowed,
                "percobaan ke-{}",
                i + 1
            );
            t.record_failure(&k, now);
        }
    }

    #[test]
    fn sixth_attempt_limited_after_five_failures_same_email() {
        let t = LoginThrottle::standard();
        let now = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..5 {
            t.record_failure(&k, now);
        }
        assert!(limited(t.check(&k, now)));
        // Per email juga berlaku dari IP lain.
        assert!(limited(t.check(&key("ani@example.com", 2), now)));
    }

    #[test]
    fn limited_per_ip_across_different_emails() {
        let t = LoginThrottle::standard();
        let now = Instant::now();
        for i in 0..5 {
            t.record_failure(&key(&format!("u{i}@example.com"), 1), now);
        }
        assert!(limited(t.check(&key("baru@example.com", 1), now)));
    }

    #[test]
    fn different_email_and_ip_unaffected() {
        let t = LoginThrottle::standard();
        let now = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..5 {
            t.record_failure(&k, now);
        }
        assert_eq!(
            t.check(&key("budi@example.com", 2), now),
            ThrottleDecision::Allowed
        );
    }

    #[test]
    fn sliding_window_releases_after_15_minutes() {
        let t = LoginThrottle::standard();
        let t0 = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..5 {
            t.record_failure(&k, t0);
        }
        assert!(limited(t.check(&k, t0 + 15 * MIN - Duration::from_secs(1))));
        assert_eq!(
            t.check(&k, t0 + 15 * MIN + Duration::from_secs(1)),
            ThrottleDecision::Allowed
        );
    }

    #[test]
    fn oldest_failure_expires_first() {
        let t = LoginThrottle::standard();
        let t0 = Instant::now();
        let k = key("ani@example.com", 1);
        for i in 0..5 {
            t.record_failure(&k, t0 + i * MIN);
        }
        let now = t0 + 15 * MIN + Duration::from_secs(1);
        assert_eq!(t.check(&k, now), ThrottleDecision::Allowed);
        t.record_failure(&k, now);
        // Yang tertua kini t0+1m → bebas di t0+16m.
        assert_eq!(
            t.check(&k, now),
            ThrottleDecision::Limited {
                retry_after: Duration::from_secs(59)
            }
        );
    }

    #[test]
    fn retry_after_reported() {
        let t = LoginThrottle::standard();
        let t0 = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..5 {
            t.record_failure(&k, t0);
        }
        assert_eq!(
            t.check(&k, t0 + 5 * MIN),
            ThrottleDecision::Limited {
                retry_after: 10 * MIN
            }
        );
    }

    #[test]
    fn prunes_expired_entries() {
        let t = LoginThrottle::standard();
        let t0 = Instant::now();
        for i in 0..100u8 {
            t.record_failure(&key(&format!("u{i}@example.com"), i), t0);
        }
        assert_eq!(t.tracked_keys(), 200);
        // Pencatatan berikutnya setelah jendela lewat memangkas semua entri basi.
        t.record_failure(&key("baru@example.com", 200), t0 + 16 * MIN);
        assert_eq!(t.tracked_keys(), 2);
        t.prune(t0 + 32 * MIN);
        assert_eq!(t.tracked_keys(), 0);
    }

    fn shared() -> std::sync::Arc<LoginThrottle> {
        std::sync::Arc::new(LoginThrottle::standard())
    }

    #[test]
    fn in_flight_attempts_count_toward_limit() {
        let t = shared();
        let now = Instant::now();
        let k = key("ani@example.com", 1);
        let held: Vec<Attempt> = (0..5)
            .map(|_| t.try_begin(&k, now).expect("kuota"))
            .collect();
        assert!(
            t.try_begin(&k, now).is_err(),
            "percobaan ke-6 selagi 5 berjalan"
        );
        // Per IP juga: email lain dari IP yang sama tertahan.
        assert!(t.try_begin(&key("budi@example.com", 1), now).is_err());
        assert!(t.try_begin(&key("budi@example.com", 2), now).is_ok());
        drop(held);
    }

    #[test]
    fn dropped_attempt_records_failure() {
        let t = shared();
        let now = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..5 {
            drop(t.try_begin(&k, now).unwrap());
        }
        assert!(limited(t.check(&k, now)));
        assert!(t.try_begin(&k, now).is_err());
    }

    #[test]
    fn succeeded_attempt_not_counted() {
        let t = shared();
        let now = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..10 {
            t.try_begin(&k, now).unwrap().succeeded();
        }
        assert_eq!(t.check(&k, now), ThrottleDecision::Allowed);
        assert_eq!(t.tracked_keys(), 0, "reservasi dilepas tanpa jejak");
    }

    #[test]
    fn abandoned_attempt_not_counted() {
        let t = shared();
        let now = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..10 {
            t.try_begin(&k, now).unwrap().abandon();
        }
        assert_eq!(t.check(&k, now), ThrottleDecision::Allowed);
    }

    #[test]
    fn limited_reservation_reports_retry_after() {
        let t = shared();
        let t0 = Instant::now();
        let k = key("ani@example.com", 1);
        for _ in 0..5 {
            t.record_failure(&k, t0);
        }
        let err = t.try_begin(&k, t0 + 5 * MIN).err().expect("limited");
        assert_eq!(err.retry_after, 10 * MIN);
    }

    #[test]
    fn email_key_trimmed_and_lowercased() {
        let k = ThrottleKey::new("  Ani@Example.COM \n", ip(1));
        assert_eq!(k.email, "ani@example.com");
        let t = LoginThrottle::standard();
        let now = Instant::now();
        for _ in 0..5 {
            t.record_failure(&ThrottleKey::new("ANI@example.com", ip(1)), now);
        }
        assert!(limited(
            t.check(&ThrottleKey::new(" ani@EXAMPLE.com", ip(9)), now)
        ));
    }
}
