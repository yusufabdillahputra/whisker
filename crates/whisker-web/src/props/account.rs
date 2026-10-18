//! Props page akun: `Account/Security`.

use serde::Serialize;
use ts_rs::TS;

/// Props page `Account/Security`. `forced` = user wajib ganti password (`must_change_password`);
/// sukses ganti password lalu dialihkan ke `/` alih-alih kembali ke halaman ini.
#[derive(Debug, Clone, Serialize, TS)]
#[ts(export)]
#[serde(rename_all = "camelCase")]
pub struct AccountSecurityProps {
    pub forced: bool,
}
veer::register_page!(AccountSecurityProps, "Account/Security");
