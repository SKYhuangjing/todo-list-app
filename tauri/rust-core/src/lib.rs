// TODO Core - 核心业务逻辑库
// 可被 Tauri (Windows) 和 UniFFI (Swift/Apple) 共享

pub mod models;
pub mod database;
pub mod utils;

// UniFFI 脚手架
uniffi::setup_scaffolding!();

// 重新导出核心类型
pub use models::*;
pub use database::INIT_SQL;
pub use utils::*;
