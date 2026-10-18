//! IP klien untuk throttle. `X-Forwarded-For` hanya dipercaya bila peer TCP ada di
//! `WHISKER_TRUSTED_PROXIES` (keputusan owner Q1); daftar kosong = tak pernah dipercaya.

use axum::extract::{ConnectInfo, FromRequestParts};
use axum::http::HeaderMap;
use axum::http::request::Parts;
use axum::response::Response;
use ipnet::IpNet;
use std::net::{IpAddr, SocketAddr};

use crate::AppState;
use crate::page::internal_error;

/// IP klien request ini. Butuh `ConnectInfo<SocketAddr>` (serve dengan
/// `into_make_service_with_connect_info`); tanpa itu → `500` (salah rakit, bukan input klien).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ClientIp(pub IpAddr);

impl FromRequestParts<AppState> for ClientIp {
    type Rejection = Response;

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let ConnectInfo(peer) = ConnectInfo::<SocketAddr>::from_request_parts(parts, state)
            .await
            .map_err(|_| {
                tracing::error!("ConnectInfo<SocketAddr> tidak ada; serve tanpa connect info");
                internal_error()
            })?;
        Ok(ClientIp(resolve_client_ip(
            peer,
            &parts.headers,
            &state.config.trusted_proxies,
        )))
    }
}

/// IP klien dari `peer` dan `X-Forwarded-For` (dibaca dari kanan, proxy tepercaya dilompati).
/// Semua nilai dinormalisasi (`::ffff:a.b.c.d` → IPv4). Header dipecah per koma di level byte;
/// segmen rusak (bukan UTF-8 / bukan IP) hanya berpengaruh bila ditemui **sebelum** hop tak
/// tepercaya pertama dari kanan — saat itu hasilnya IP peer. Segmen di kiri hop itu (bisa dipalsukan
/// klien) tidak pernah disentuh.
pub fn resolve_client_ip(peer: SocketAddr, headers: &HeaderMap, trusted: &[IpNet]) -> IpAddr {
    let peer_ip = peer.ip().to_canonical();
    if !is_trusted(peer_ip, trusted) {
        return peer_ip;
    }
    let hops: Vec<&[u8]> = headers
        .get_all("x-forwarded-for")
        .iter()
        .flat_map(|value| value.as_bytes().split(|b| *b == b','))
        .collect();
    let mut client = peer_ip;
    for hop in hops.iter().rev() {
        let parsed = std::str::from_utf8(hop)
            .ok()
            .and_then(|text| text.trim().parse::<IpAddr>().ok());
        let Some(ip) = parsed.map(|ip| ip.to_canonical()) else {
            return peer_ip;
        };
        client = ip;
        if !is_trusted(ip, trusted) {
            break;
        }
    }
    client
}

fn is_trusted(ip: IpAddr, trusted: &[IpNet]) -> bool {
    trusted.iter().any(|net| net.contains(&ip))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::http::HeaderValue;

    fn peer(s: &str) -> SocketAddr {
        SocketAddr::new(s.parse().unwrap(), 40000)
    }

    fn xff(values: &[&str]) -> HeaderMap {
        let mut h = HeaderMap::new();
        for v in values {
            h.append("x-forwarded-for", HeaderValue::from_str(v).unwrap());
        }
        h
    }

    fn nets(list: &[&str]) -> Vec<IpNet> {
        list.iter().map(|s| s.parse().unwrap()).collect()
    }

    fn ip(s: &str) -> IpAddr {
        s.parse().unwrap()
    }

    #[test]
    fn untrusted_peer_ignores_xff() {
        let got = resolve_client_ip(
            peer("198.51.100.7"),
            &xff(&["1.2.3.4"]),
            &nets(&["10.0.0.0/8"]),
        );
        assert_eq!(got, ip("198.51.100.7"));
    }

    #[test]
    fn trusted_peer_uses_rightmost_untrusted_xff() {
        let got = resolve_client_ip(
            peer("10.0.0.1"),
            &xff(&["9.9.9.9, 1.2.3.4", "10.0.0.2"]),
            &nets(&["10.0.0.0/8"]),
        );
        assert_eq!(got, ip("1.2.3.4"));
    }

    #[test]
    fn trusted_peer_without_xff_uses_peer() {
        let got = resolve_client_ip(peer("10.0.0.1"), &HeaderMap::new(), &nets(&["10.0.0.0/8"]));
        assert_eq!(got, ip("10.0.0.1"));
    }

    #[test]
    fn malformed_xff_falls_back_to_peer() {
        let trusted = nets(&["10.0.0.0/8"]);
        for bad in ["bukan-ip", "1.2.3.4, ", "1.2.3.4:80", ""] {
            let got = resolve_client_ip(peer("10.0.0.1"), &xff(&[bad]), &trusted);
            assert_eq!(got, ip("10.0.0.1"), "XFF {bad:?}");
        }
    }

    #[test]
    fn empty_trusted_list_never_reads_xff() {
        for p in ["127.0.0.1", "10.0.0.1", "::1"] {
            let got = resolve_client_ip(peer(p), &xff(&["1.2.3.4"]), &[]);
            assert_eq!(got, ip(p));
        }
    }

    #[test]
    fn all_xff_hops_trusted_uses_leftmost() {
        let got = resolve_client_ip(
            peer("10.0.0.1"),
            &xff(&["10.0.0.3, 10.0.0.2"]),
            &nets(&["10.0.0.0/8"]),
        );
        assert_eq!(got, ip("10.0.0.3"));
    }

    #[test]
    fn non_utf8_segment_left_of_untrusted_hop_is_ignored() {
        let trusted = nets(&["10.0.0.0/8"]);
        let mut h = HeaderMap::new();
        h.append(
            "x-forwarded-for",
            HeaderValue::from_bytes(b"\xff-sampah, 1.2.3.4").unwrap(),
        );
        assert_eq!(
            resolve_client_ip(peer("10.0.0.1"), &h, &trusted),
            ip("1.2.3.4")
        );

        // Header terpisah berisi byte rusak di kiri juga tidak menjatuhkan ke IP proxy.
        let mut h = HeaderMap::new();
        h.append(
            "x-forwarded-for",
            HeaderValue::from_bytes(b"\xfe\xff").unwrap(),
        );
        h.append(
            "x-forwarded-for",
            HeaderValue::from_static("1.2.3.4, 10.0.0.2"),
        );
        assert_eq!(
            resolve_client_ip(peer("10.0.0.1"), &h, &trusted),
            ip("1.2.3.4")
        );
    }

    #[test]
    fn non_utf8_segment_before_any_untrusted_hop_falls_back_to_peer() {
        let trusted = nets(&["10.0.0.0/8"]);
        let mut h = HeaderMap::new();
        h.append(
            "x-forwarded-for",
            HeaderValue::from_bytes(b"1.2.3.4, \xff").unwrap(),
        );
        assert_eq!(
            resolve_client_ip(peer("10.0.0.1"), &h, &trusted),
            ip("10.0.0.1")
        );
    }

    #[test]
    fn ipv4_mapped_ipv6_normalized() {
        let trusted = nets(&["10.0.0.0/8"]);
        let got = resolve_client_ip(peer("::ffff:10.0.0.1"), &xff(&["::ffff:1.2.3.4"]), &trusted);
        assert_eq!(got, ip("1.2.3.4"));
        let got = resolve_client_ip(peer("::ffff:198.51.100.7"), &HeaderMap::new(), &[]);
        assert_eq!(got, ip("198.51.100.7"));
    }
}
