//! `whisker healthcheck`: GET `/health` ke server sendiri lewat HTTP/1.1 polos di atas TCP,
//! tanpa curl atau klien HTTP tambahan (image runtime tanpa curl). 200 → exit 0, selain itu → 1.

use std::net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr};
use std::process::ExitCode;
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;

/// Batas baca status line (cukup untuk `HTTP/1.1 503 Service Unavailable\r\n`).
const MAX_HEAD: usize = 1024;

pub async fn run(addr: SocketAddr, timeout: Duration) -> ExitCode {
    let target = probe_addr(addr);
    match tokio::time::timeout(timeout, probe(target)).await {
        Ok(Ok(200)) => ExitCode::SUCCESS,
        Ok(Ok(status)) => {
            eprintln!("whisker healthcheck: http://{target}/health menjawab {status}");
            ExitCode::FAILURE
        }
        Ok(Err(e)) => {
            eprintln!("whisker healthcheck: http://{target}/health tak terjangkau: {e}");
            ExitCode::FAILURE
        }
        Err(_) => {
            eprintln!("whisker healthcheck: http://{target}/health tak menjawab dalam {timeout:?}");
            ExitCode::FAILURE
        }
    }
}

/// Alamat bind tak spesifik (`0.0.0.0`, `::`) → loopback keluarga yang sama; alamat spesifik dipakai apa adanya.
fn probe_addr(addr: SocketAddr) -> SocketAddr {
    let ip = match addr.ip() {
        IpAddr::V4(ip) if ip.is_unspecified() => IpAddr::V4(Ipv4Addr::LOCALHOST),
        IpAddr::V6(ip) if ip.is_unspecified() => IpAddr::V6(Ipv6Addr::LOCALHOST),
        ip => ip,
    };
    SocketAddr::new(ip, addr.port())
}

async fn probe(target: SocketAddr) -> std::io::Result<u16> {
    let mut stream = TcpStream::connect(target).await?;
    let request = format!(
        "GET /health HTTP/1.1\r\nHost: {target}\r\nUser-Agent: whisker-healthcheck\r\nConnection: close\r\n\r\n"
    );
    stream.write_all(request.as_bytes()).await?;

    let mut head = Vec::with_capacity(MAX_HEAD);
    let mut buf = [0u8; 256];
    while !head.windows(2).any(|w| w == b"\r\n") && head.len() < MAX_HEAD {
        let n = stream.read(&mut buf).await?;
        if n == 0 {
            break;
        }
        head.extend_from_slice(&buf[..n]);
    }
    parse_status(&head).ok_or_else(|| {
        std::io::Error::new(
            std::io::ErrorKind::InvalidData,
            "respons bukan HTTP/1.x yang valid",
        )
    })
}

/// `HTTP/1.1 200 OK\r\n…` → `200`.
fn parse_status(head: &[u8]) -> Option<u16> {
    let line = head.split(|b| *b == b'\n').next()?;
    let line = std::str::from_utf8(line).ok()?;
    let mut parts = line.split_whitespace();
    if !parts.next()?.starts_with("HTTP/1.") {
        return None;
    }
    parts.next()?.parse().ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_status_line() {
        assert_eq!(parse_status(b"HTTP/1.1 200 OK\r\n"), Some(200));
        assert_eq!(
            parse_status(b"HTTP/1.1 503 Service Unavailable\r\ncontent-type: x\r\n"),
            Some(503)
        );
        assert_eq!(parse_status(b"SSH-2.0-OpenSSH\r\n"), None);
        assert_eq!(parse_status(b""), None);
    }

    #[test]
    fn unspecified_bind_maps_to_loopback() {
        let a = |s: &str| s.parse::<SocketAddr>().unwrap();
        assert_eq!(probe_addr(a("0.0.0.0:8080")), a("127.0.0.1:8080"));
        assert_eq!(probe_addr(a("[::]:8080")), a("[::1]:8080"));
        assert_eq!(probe_addr(a("10.0.0.5:9000")), a("10.0.0.5:9000"));
    }
}
