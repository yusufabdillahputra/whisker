//! Props page `Projects/Index` (pemilih Project). Sementara di Task 10; dilengkapi Task 17
//! (`lastOpenedSlug`, `iconOptions`, isi `projects`).

use serde::Serialize;
use ts_rs::TS;
use whisker_core::vault::icon::ProjectIcon;

#[derive(Debug, Clone, Default, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct ProjectsIndexProps {
    pub projects: Vec<ProjectCard>,
}
veer::register_page!(ProjectsIndexProps, "Projects/Index");

/// Kartu project di pemilih (bentuk sesuai Task 17).
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct ProjectCard {
    pub slug: String,
    pub name: String,
    pub icon: ProjectIcon,
    pub created_at: String,
}
