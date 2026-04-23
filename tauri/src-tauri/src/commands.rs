// 简化的 Tauri 命令 - 使用前端 SQL API
use crate::models::*;
use tauri::Manager;

// ============ TODO 命令 ============

#[tauri::command]
pub fn generate_uuid() -> String {
    uuid::Uuid::new_v4().to_string()
}

#[tauri::command]
pub fn get_current_timestamp() -> String {
    chrono::Utc::now().format("%Y-%m-%d %H:%M:%S").to_string()
}

#[tauri::command]
pub fn get_today_date() -> String {
    chrono::Local::now().format("%Y-%m-%d").to_string()
}

// ============ 设置命令 ============

#[tauri::command]
pub fn get_default_shortcuts() -> ShortcutConfig {
    ShortcutConfig {
        quick_input: "F2".to_string(),
        show_list: "F3".to_string(),
    }
}

// ============ 导入导出命令 ============

#[tauri::command]
pub fn parse_export_json(json_content: String) -> Result<ExportData, String> {
    serde_json::from_str(&json_content)
        .map_err(|e| format!("无效的 JSON 格式: {}", e))
}

#[tauri::command]
pub fn create_export_json(data: ExportData) -> Result<String, String> {
    serde_json::to_string_pretty(&data).map_err(|e| e.to_string())
}

// ============ 截图命令 ============

#[tauri::command]
pub async fn capture_screenshot(app_handle: tauri::AppHandle) -> Result<String, String> {
    use std::process::Command;
    use tauri::Manager;
    
    // 获取应用数据目录
    let app_data_dir = app_handle
        .path()
        .app_data_dir()
        .map_err(|e| format!("获取应用数据目录失败: {}", e))?;
    
    // 创建截图目录
    let screenshots_dir = app_data_dir.join("screenshots");
    std::fs::create_dir_all(&screenshots_dir)
        .map_err(|e| format!("创建截图目录失败: {}", e))?;
    
    // 生成唯一文件名
    let filename = format!("{}.png", uuid::Uuid::new_v4());
    let filepath = screenshots_dir.join(&filename);
    let filepath_str = filepath.to_string_lossy().to_string();
    
    // 调用 macOS screencapture 命令进行交互式截图
    // -i: 交互式模式（用户选择区域）
    // -x: 不播放声音
    let output = Command::new("screencapture")
        .args(["-i", "-x", &filepath_str])
        .output()
        .map_err(|e| format!("调用截图命令失败: {}", e))?;
    
    if !output.status.success() {
        return Err("截图被取消或失败".to_string());
    }
    
    // 检查文件是否存在（用户可能取消了截图）
    if !filepath.exists() {
        return Err("截图被取消".to_string());
    }
    
    Ok(filepath_str)
}

#[tauri::command]
pub fn check_screenshot_permission() -> bool {
    #[cfg(target_os = "macos")]
    {
        use std::process::Command;
        // 在 macOS 上，我们可以尝试运行 screencapture -c (截图到剪贴板) 
        // 但这可能会弹窗。更好的方式是检查系统的 TCC 数据库，但这需要 root。
        // 一个实用的方法是检查是否有权限读取屏幕内容。
        // 这里我们使用一个简单的命令来测试：screencapture -x -R0,0,1,1 /dev/null
        // 如果没有权限，它通常会返回非零退出码或者虽然成功但结果是空的。
        // 注意：这只是一个近似检查。
        let output = Command::new("screencapture")
            .args(["-x", "-R0,0,1,1", "/dev/null"])
            .output();
        
        match output {
            Ok(out) => out.status.success(),
            Err(_) => false,
        }
    }
    #[cfg(not(target_os = "macos"))]
    {
        true
    }
}

#[tauri::command]
pub fn request_screenshot_permission() {
    #[cfg(target_os = "macos")]
    {
        use std::process::Command;
        // 打开系统隐私设置中的屏幕录制页面
        let _ = Command::new("open")
            .arg("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
            .spawn();
    }
}

#[tauri::command]
pub fn update_shortcuts(app_handle: tauri::AppHandle, config: ShortcutConfig) -> Result<(), String> {
    use tauri_plugin_global_shortcut::{GlobalShortcutExt, Shortcut};
    use std::str::FromStr;

    // 注销所有现有快捷键
    let _ = app_handle.global_shortcut().unregister_all();

    // 注册新快捷键 - 快速输入
    if let Ok(shortcut) = Shortcut::from_str(&config.quick_input) {
        let _ = app_handle.global_shortcut().on_shortcut(shortcut, |app, _shortcut, _event| {
            if let Some(window) = app.get_webview_window("quick-input") {
                let _ = window.show().map_err(|e| e.to_string());
                let _ = window.set_focus().map_err(|e| e.to_string());
            }
        });
    }

    // 注册新快捷键 - 显示列表
    if let Ok(shortcut) = Shortcut::from_str(&config.show_list) {
        let _ = app_handle.global_shortcut().on_shortcut(shortcut, |app, _shortcut, _event| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.show().map_err(|e| e.to_string());
                let _ = window.set_focus().map_err(|e| e.to_string());
            }
        });
    }

    Ok(())
}
