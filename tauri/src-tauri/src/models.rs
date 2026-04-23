// 数据模型定义
use serde::{Deserialize, Serialize};

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Tag {
    pub id: String,
    pub name: String,
    pub color: String,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TodoWithTags {
    #[serde(flatten)]
    pub todo: Todo,
    pub tags: Vec<Tag>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTodoInput {
    pub title: String,
    pub content: Option<String>,
    pub screenshot_path: Option<String>,
    pub due_date: Option<String>,
    pub tag_ids: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdateTodoInput {
    pub id: String,
    pub title: Option<String>,
    pub content: Option<String>,
    pub screenshot_path: Option<String>,
    pub due_date: Option<String>,
    pub status: Option<String>,
    pub tag_ids: Option<Vec<String>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CreateTagInput {
    pub name: String,
    pub color: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShortcutConfig {
    pub quick_input: String,
    pub show_list: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExportData {
    pub version: String,
    pub exported_at: String,
    pub todos: Vec<TodoExport>,
    pub tags: Vec<TagExport>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TodoExport {
    pub title: String,
    pub content: Option<String>,
    pub due_date: Option<String>,
    pub status: String,
    pub tags: Vec<String>,
    pub created_at: String,
    pub completed_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TagExport {
    pub name: String,
    pub color: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ImportResult {
    pub imported_todos: i32,
    pub imported_tags: i32,
}
