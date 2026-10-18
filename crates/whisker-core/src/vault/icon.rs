//! Allowlist ikon project (Q7, provisional — owner meninjau). Tiap nama harus ada di Lucide
//! (dijaga tes kontrak frontend `project-icons.test.ts`). Nama serde = nama Lucide.

use std::str::FromStr;

use serde::{Deserialize, Serialize};
use ts_rs::TS;

use crate::error::ParseValueError;

macro_rules! project_icons {
    ($($variant:ident => $name:literal),+ $(,)?) => {
        /// Ikon project; nilai serialisasi = nama ikon Lucide (kebab-case).
        #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, TS)]
        #[ts(export)]
        pub enum ProjectIcon {
            $(#[serde(rename = $name)] #[ts(rename = $name)] $variant,)+
        }

        impl ProjectIcon {
            /// Semua ikon, urutan deklarasi (urutan ini juga isi `project-icons.json`).
            pub const ALL: &'static [ProjectIcon] = &[$(ProjectIcon::$variant),+];

            pub fn as_str(&self) -> &'static str {
                match self { $(ProjectIcon::$variant => $name),+ }
            }
        }

        impl FromStr for ProjectIcon {
            type Err = ParseValueError;
            fn from_str(s: &str) -> Result<Self, Self::Err> {
                match s {
                    $($name => Ok(ProjectIcon::$variant),)+
                    _ => Err(ParseValueError { kind: "ikon project" }),
                }
            }
        }
    };
}

project_icons! {
    Folder => "folder", Book => "book", BookOpen => "book-open", Notebook => "notebook",
    FileText => "file-text", Brain => "brain", Lightbulb => "lightbulb", Rocket => "rocket",
    Code => "code", Terminal => "terminal", Database => "database", Server => "server",
    Cloud => "cloud", Globe => "globe", Briefcase => "briefcase", Building => "building",
    House => "house", GraduationCap => "graduation-cap", FlaskConical => "flask-conical",
    Microscope => "microscope", Atom => "atom", Cpu => "cpu", Smartphone => "smartphone",
    Laptop => "laptop", Palette => "palette", PenTool => "pen-tool", Camera => "camera",
    Music => "music", Film => "film", Gamepad2 => "gamepad-2", Heart => "heart", Star => "star",
    Flag => "flag", Target => "target", Compass => "compass", Map => "map",
    Calendar => "calendar", Clock => "clock", Bell => "bell", Mail => "mail",
    MessageSquare => "message-square", Users => "users", User => "user", Shield => "shield",
    Lock => "lock", Key => "key", Wallet => "wallet", ShoppingCart => "shopping-cart",
    ChartLine => "chart-line", ChartPie => "chart-pie", Layers => "layers", Package => "package",
    Puzzle => "puzzle", Wrench => "wrench", Settings => "settings", Leaf => "leaf", Sun => "sun",
    Moon => "moon", Coffee => "coffee", Cat => "cat", Library => "library",
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;

    #[test]
    fn icon_from_str_accepts_allowlisted() {
        for i in ProjectIcon::ALL {
            assert_eq!(i.as_str().parse::<ProjectIcon>().unwrap(), *i);
        }
        assert_eq!(
            "gamepad-2".parse::<ProjectIcon>().unwrap(),
            ProjectIcon::Gamepad2
        );
    }

    #[test]
    fn icon_from_str_rejects_unknown() {
        for s in ["not-an-icon", "Folder", "", "folder ", "gamepad2"] {
            assert!(s.parse::<ProjectIcon>().is_err(), "{s:?}");
        }
    }

    #[test]
    fn icon_all_has_n_unique_entries() {
        assert_eq!(ProjectIcon::ALL.len(), 61);
        let set: HashSet<_> = ProjectIcon::ALL.iter().map(|i| i.as_str()).collect();
        assert_eq!(set.len(), 61);
    }

    #[test]
    fn icon_serde_matches_as_str() {
        for i in ProjectIcon::ALL {
            assert_eq!(
                serde_json::to_string(i).unwrap(),
                format!("\"{}\"", i.as_str())
            );
        }
    }

    /// Menulis `project-icons.json` ke `TS_RS_EXPORT_DIR` (urut `ALL`); CI memeriksa diff-nya.
    #[test]
    fn export_bindings_project_icons_json() {
        let names: Vec<&str> = ProjectIcon::ALL.iter().map(|i| i.as_str()).collect();
        let json = serde_json::to_string_pretty(&names).unwrap() + "\n";
        crate::export::write_generated("project-icons.json", &json);
    }
}
