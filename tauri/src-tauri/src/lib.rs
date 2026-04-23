// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
mod commands;
mod database;
mod models;

use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    Manager, Emitter,
};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .plugin(
            tauri_plugin_sql::Builder::default()
                .add_migrations("sqlite:todo.db", vec![
                    tauri_plugin_sql::Migration {
                        version: 1,
                        description: "Initial schema",
                        sql: database::INIT_SQL,
                        kind: tauri_plugin_sql::MigrationKind::Up,
                    },
                    tauri_plugin_sql::Migration {
                        version: 2,
                        description: "Add priority column",
                        sql: "ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 1;",
                        kind: tauri_plugin_sql::MigrationKind::Up,
                    }
                ])
                .build()
        )
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_fs::init())
        .setup(|app| {
            // macOS: 设置为后台应用（隐藏 Dock 图标）
            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);

            // 创建托盘菜单
            let show_i = MenuItem::with_id(app, "show", "主页面", true, None::<&str>)?;
            let new_i = MenuItem::with_id(app, "new", "新建", true, None::<&str>)?;
            let settings_i = MenuItem::with_id(app, "settings", "设置", true, None::<&str>)?;
            let quit_i = MenuItem::with_id(app, "quit", "退出", true, None::<&str>)?;
            
            let menu = Menu::with_items(app, &[&show_i, &new_i, &settings_i, &quit_i])?;
            
            // 加载托盘专用图标（单色模板图标）
            let tray_icon_bytes = include_bytes!("../icons/tray-icon@2x.png");
            let tray_icon = tauri::image::Image::from_bytes(tray_icon_bytes)
                .expect("Failed to load tray icon");
            
            // 创建托盘图标
            let _tray = TrayIconBuilder::new()
                .icon(tray_icon)
                .icon_as_template(true)  // macOS 模板图标模式
                .menu(&menu)
                .show_menu_on_left_click(false)
                .on_menu_event(|app, event| {
                    match event.id.as_ref() {
                        "show" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let _ = window.show();
                                let _ = window.set_focus();
                            }
                        }
                        "new" => {
                            if let Some(window) = app.get_webview_window("quick-input") {
                                let _ = window.show();
                                let _ = window.set_focus();
                            }
                        }
                        "settings" => {
                            if let Some(window) = app.get_webview_window("main") {
                                let _ = window.show();
                                let _ = window.set_focus();
                                let _ = window.emit("open-settings", ());
                            }
                        }
                        "quit" => {
                            std::process::exit(0);
                        }
                        _ => {}
                    }
                })
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        let app = tray.app_handle();
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.center();
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                })
                .build(app)?;
            
            // 注册全局快捷键
            use tauri_plugin_global_shortcut::{GlobalShortcutExt, Shortcut};
            use std::str::FromStr;
            
            // F2 - 快捷输入
            if let Ok(shortcut) = Shortcut::from_str("F2") {
                let _ = app.global_shortcut().on_shortcut(shortcut, |app_handle, _shortcut, _event| {
                    if let Some(window) = app_handle.get_webview_window("quick-input") {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                });
            }
            
            // F3 - 显示列表
            if let Ok(shortcut) = Shortcut::from_str("F3") {
                let _ = app.global_shortcut().on_shortcut(shortcut, |app_handle, _shortcut, _event| {
                    if let Some(window) = app_handle.get_webview_window("main") {
                        let _ = window.show();
                        let _ = window.set_focus();
                    }
                });
            }
            
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::generate_uuid,
            commands::get_current_timestamp,
            commands::get_today_date,
            commands::get_default_shortcuts,
            commands::parse_export_json,
            commands::create_export_json,
            commands::capture_screenshot,
            commands::check_screenshot_permission,
            commands::request_screenshot_permission,
            commands::update_shortcuts,
        ])
        .on_window_event(|window, event| {
            match event {
                // 拦截窗口关闭请求，让窗口隐藏而不是退出程序
                tauri::WindowEvent::CloseRequested { api, .. } => {
                    api.prevent_close();
                    let _ = window.hide();
                }
                // 主窗口失去焦点时自动隐藏
                tauri::WindowEvent::Focused(false) => {
                    if window.label() == "main" {
                        let _ = window.hide();
                    }
                }
                _ => {}
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
