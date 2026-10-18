//! CLI bin `whisker`: `serve` (default) dan `healthcheck`.

use clap::{Parser, Subcommand};

#[derive(Debug, Parser)]
#[command(name = "whisker", version, about = "Whisker — Second Brain monolith")]
pub struct Cli {
    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Subcommand)]
pub enum Command {
    /// Jalankan server (default bila tanpa subcommand).
    Serve,
    /// Probe `/healthz` pada alamat HTTP sendiri; exit 0 bila sehat.
    Healthcheck,
}

impl Cli {
    pub fn command(&self) -> Command {
        self.command.unwrap_or(Command::Serve)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::Parser;

    #[test]
    fn cli_defaults_to_serve() {
        let cli = Cli::try_parse_from(["whisker"]).unwrap();
        assert_eq!(cli.command(), Command::Serve);
        let cli = Cli::try_parse_from(["whisker", "serve"]).unwrap();
        assert_eq!(cli.command(), Command::Serve);
    }

    #[test]
    fn cli_parses_healthcheck() {
        let cli = Cli::try_parse_from(["whisker", "healthcheck"]).unwrap();
        assert_eq!(cli.command(), Command::Healthcheck);
    }
}
