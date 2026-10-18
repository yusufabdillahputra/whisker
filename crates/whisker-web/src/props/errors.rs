//! Props page error `Errors/Forbidden` (403) dan `Errors/NotFound` (404).

use serde::Serialize;
use ts_rs::TS;

#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct ErrorPageProps {
    pub status: u16,
}
