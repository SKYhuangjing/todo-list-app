// 工具函数 - 支持 UniFFI 导出
use crate::models::*;

/// 自定义错误类型
#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum CoreError {
    #[error("解析错误")]
    ParseError,
    #[error("序列化错误")]
    SerializeError,
}

/// 生成 UUID
#[uniffi::export]
pub fn generate_uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}

/// 获取当前时间戳
#[uniffi::export]
pub fn get_current_timestamp() -> String {
    chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()
}

/// 获取今天日期
#[uniffi::export]
pub fn get_today_date() -> String {
    chrono::Local::now().format("%Y-%m-%d").to_string()
}

/// 获取默认快捷键配置
#[uniffi::export]
pub fn get_default_shortcuts() -> ShortcutConfig {
    ShortcutConfig {
        quick_input: "F2".to_string(),
        show_list: "F3".to_string(),
    }
}

/// 解析导出 JSON
#[uniffi::export]
pub fn parse_export_json(json_content: String) -> Result<ExportData, CoreError> {
    serde_json::from_str(&json_content).map_err(|_| CoreError::ParseError)
}

/// 创建导出 JSON
#[uniffi::export]
pub fn create_export_json(data: ExportData) -> Result<String, CoreError> {
    serde_json::to_string_pretty(&data).map_err(|_| CoreError::SerializeError)
}
