//! Props page `Auth/Login`.

use serde::Serialize;
use ts_rs::TS;

/// Props page `Auth/Login` (kosong; error form lewat prop `errors`).
#[derive(Debug, Clone, Default, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct LoginPageProps {}
veer::register_page!(LoginPageProps, "Auth/Login");
