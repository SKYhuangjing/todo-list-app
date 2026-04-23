// 数据模型定义 - 支持 UniFFI 导出
use serde::{Deserialize, Serialize};

/// TODO 项目
#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct Todo {
    pub id: String,
    pub title: String,
    pub content: Option<String>,
    pub screenshot_path: Option<String>,
    pub due_date: Option<String>,
    pub status: String, // "pending", "completed", "overdue"
    pub created_at: String,
    pub updated_at: String,
    pub completed_at: Option<String>,
}

/// 标签
#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct Tag {
    pub id: String,
    pub name: String,
    pub color: String,
    pub created_at: String,
}

/// 快捷键配置
#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct ShortcutConfig {
    pub quick_input: String,
    pub show_list: String,
}

/// 导出数据结构
#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct ExportData {
    pub version: String,
    pub exported_at: String,
    pub todos: Vec<TodoExport>,
    pub tags: Vec<TagExport>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct TodoExport {
    pub title: String,
    pub content: Option<String>,
    pub due_date: Option<String>,
    pub status: String,
    pub tags: Vec<String>,
    pub created_at: String,
    pub completed_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, uniffi::Record)]
pub struct TagExport {
    pub name: String,
    pub color: String,
}
