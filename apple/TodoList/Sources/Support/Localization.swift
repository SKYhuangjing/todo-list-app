import Foundation
import Observation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english
    case simplifiedChinese

    static let userDefaultsKey = "app.language"

    var id: String { rawValue }

    func title(for language: ResolvedLanguage) -> String {
        switch self {
        case .system:
            switch language {
            case .english: "System"
            case .simplifiedChinese: "跟随系统"
            }
        case .english:
            "English"
        case .simplifiedChinese:
            "简体中文"
        }
    }

    static func persisted() -> AppLanguage {
        guard
            let rawValue = UserDefaults.standard.string(forKey: userDefaultsKey),
            let language = AppLanguage(rawValue: rawValue)
        else {
            return .system
        }
        return language
    }
}

enum ResolvedLanguage: Sendable {
    case english
    case simplifiedChinese

    var localeIdentifier: String {
        switch self {
        case .english: "en"
        case .simplifiedChinese: "zh-Hans"
        }
    }
}

enum LocalizedKey: String, CaseIterable {
    case appName
    case settingsAppearanceTab
    case settingsShortcutsTab
    case settingsTagsTab
    case settingsDataTab
    case settingsSidebarTitle
    case liquidGlass
    case liquidGlassSubtitle
    case liquidGlassClear
    case liquidGlassTinted
    case liquidGlassClearTagline
    case liquidGlassTintedTagline
    case language
    case languageSubtitle
    case theme
    case themeSubtitle
    case accent
    case accentSubtitle
    case lightTheme
    case lightThemeSubtitle
    case darkTheme
    case darkThemeSubtitle
    case customAccent
    case customAccentFormat
    case reset
    case typography
    case typographySubtitle
    case density
    case densitySubtitle
    case appearanceMode
    case appearanceModeSubtitle
    case mode
    case shortcutGlobal
    case shortcutGlobalSubtitle
    case shortcutQuickInput
    case shortcutShowDashboard
    case shortcutExamples
    case shortcutPlaceholder
    case save
    case tags
    case tagsSubtitle
    case noTagsYet
    case newTag
    case add
    case delete
    case backupRestore
    case backupRestoreSubtitle
    case exportJSON
    case importJSON
    case app
    case appSubtitle
    case hideDockIcon
    case hideDockIconSubtitle
    case openQuickAdd
    case openDashboard
    case appearanceModeSystem
    case appearanceModeLight
    case appearanceModeDark
    case sectionInboxTitle
    case sectionTodayTitle
    case sectionUpcomingTitle
    case sectionCompletedTitle
    case sectionInboxSubtitle
    case sectionTodaySubtitle
    case sectionUpcomingSubtitle
    case sectionCompletedSubtitle
    case taggedOpenWorkFormat
    case metricDueToday
    case metricUpcoming
    case metricClosed
    case noDeadline
    case today
    case tomorrow
    case none
    case priorityCritical
    case priorityToday
    case priorityPlanned
    case prioritySomeday
    case sidebarTags
    case collapseSidebar
    case expandSidebar
    case settings
    case newTask
    case searchPlaceholder
    case noSearchMatches
    case emptySectionFormat
    case selectTaskForDetails
    case reopen
    case complete
    case statusCompleted
    case statusOpen
    case priority
    case deadline
    case created
    case deleteTask
    case markOpen
    case markComplete
    case quickAddTitle
    case close
    case titlePlaceholder
    case notesPlaceholder
    case schedule
    case addDeadline
    case due
    case createTag
    case createTagEllipsis
    case cancel
    case reference
    case remove
    case screenRecordingAccessOff
    case screenRecordingPermissionFormat
    case saveTask
    case grantScreenRecording
    case screenRecordingGuideTitle
    case screenRecordingGuideSubtitle
    case screenRecordingGuideDragHint
    case screenRecordingGuideStepOpen
    case screenRecordingGuideStepDrag
    case screenRecordingGuideStepReturn
    case screenRecordingGuideOpenSettings
    case screenRecordingGuideWaiting
    case captureScreenshot
    case replaceScreenshot
    case failedToSaveTask
    case menuBarAttentionSummaryFormat
    case open
    case quit
    case quitHelpFormat
    case themePorcelain
    case themeEmber
    case themeSumi
    case themeCustom
    case themePorcelainTagline
    case themeEmberTagline
    case themeSumiTagline
    case themeCustomTagline
    case accentInkNavy
    case accentGraphite
    case accentCypress
    case accentPorcelainBlue
    case accentWarmOrange
    case accentForestGreen
    case accentViolet
    case accentSystem
    case accentInkNavyTagline
    case accentGraphiteTagline
    case accentCypressTagline
    case accentPorcelainBlueTagline
    case accentWarmOrangeTagline
    case accentForestGreenTagline
    case accentVioletTagline
    case accentSystemTagline
    case typographySFProTagline
    case typographyRoundedTagline
    case typographyNewYorkTagline
    case densityCompact
    case densityBalanced
    case densityComfortable
    case densityCompactTagline
    case densityBalancedTagline
    case densityComfortableTagline
    case exportedToFormat
    case importedSummaryFormat
    case duplicateTagNameFormat
    case shortcutEmpty
    case shortcutUnsupportedFormat
    case shortcutRegisterFailedFormat
    case screenshotPermissionRequired
}

enum LocalizedText {
    private static let tables: [ResolvedLanguage: [LocalizedKey: String]] = [
        .english: [
            .appName: "Todo",
            .settingsAppearanceTab: "Appearance",
            .settingsShortcutsTab: "Shortcuts",
            .settingsTagsTab: "Tags",
            .settingsDataTab: "Data",
            .settingsSidebarTitle: "Settings",
            .liquidGlass: "Liquid Glass",
            .liquidGlassSubtitle: "Choose the preferred look for glass surfaces.",
            .liquidGlassClear: "Clear",
            .liquidGlassTinted: "Tinted",
            .liquidGlassClearTagline: "System glass with minimal color.",
            .liquidGlassTintedTagline: "Glass subtly follows the theme accent.",
            .language: "Language",
            .languageSubtitle: "Choose the app language or follow the system.",
            .theme: "Theme",
            .themeSubtitle: "One click recipes. Fine-tune any dimension below.",
            .accent: "Accent",
            .accentSubtitle: "Brand tint for selected state and primary actions.",
            .lightTheme: "Light theme",
            .lightThemeSubtitle: "Used when the app is in Light or System Light.",
            .darkTheme: "Dark theme",
            .darkThemeSubtitle: "Used when the app is in Dark or System Dark.",
            .customAccent: "Custom accent",
            .customAccentFormat: "Custom accent %@",
            .reset: "Reset",
            .typography: "Typography",
            .typographySubtitle: "Display and title family.",
            .density: "Density",
            .densitySubtitle: "Row height and spacing across the list.",
            .appearanceMode: "Appearance Mode",
            .appearanceModeSubtitle: "Sync with the system or force a mode.",
            .mode: "Mode",
            .shortcutGlobal: "Global Shortcuts",
            .shortcutGlobalSubtitle: "System-wide hotkeys so you can reach the app without clicking.",
            .shortcutQuickInput: "Quick input",
            .shortcutShowDashboard: "Show dashboard",
            .shortcutExamples: "Examples: `F2`, `Command+Shift+K`, `Ctrl+Alt+1`",
            .shortcutPlaceholder: "Shortcut",
            .save: "Save",
            .tags: "Tags",
            .tagsSubtitle: "Manage the secondary slices visible in the sidebar.",
            .noTagsYet: "No tags yet. Create one below.",
            .newTag: "New tag",
            .add: "Add",
            .delete: "Delete",
            .backupRestore: "Backup & Restore",
            .backupRestoreSubtitle: "Portable JSON round-trips with the earlier Tauri backup shape.",
            .exportJSON: "Export JSON",
            .importJSON: "Import JSON",
            .app: "App",
            .appSubtitle: "Window and Dock visibility.",
            .hideDockIcon: "Hide Dock icon",
            .hideDockIconSubtitle: "Stay reachable from the menu bar and shortcuts without a Dock presence.",
            .openQuickAdd: "Open Quick Add",
            .openDashboard: "Open Dashboard",
            .appearanceModeSystem: "System",
            .appearanceModeLight: "Light",
            .appearanceModeDark: "Dark",
            .sectionInboxTitle: "Inbox",
            .sectionTodayTitle: "Today",
            .sectionUpcomingTitle: "Upcoming",
            .sectionCompletedTitle: "Completed",
            .sectionInboxSubtitle: "Everything open and unscheduled.",
            .sectionTodaySubtitle: "What actually needs attention now.",
            .sectionUpcomingSubtitle: "Scheduled work that can wait.",
            .sectionCompletedSubtitle: "Recently closed loops.",
            .taggedOpenWorkFormat: "Open work tagged %@.",
            .metricDueToday: "Due today",
            .metricUpcoming: "Upcoming",
            .metricClosed: "Closed",
            .noDeadline: "No deadline",
            .today: "Today",
            .tomorrow: "Tomorrow",
            .none: "None",
            .priorityCritical: "Critical",
            .priorityToday: "Today",
            .priorityPlanned: "Planned",
            .prioritySomeday: "Someday",
            .sidebarTags: "Tags",
            .collapseSidebar: "Collapse sidebar",
            .expandSidebar: "Expand sidebar",
            .settings: "Settings",
            .newTask: "New Task",
            .searchPlaceholder: "Search tasks, notes, or tags",
            .noSearchMatches: "No tasks match this search.",
            .emptySectionFormat: "Nothing in %@ yet.",
            .selectTaskForDetails: "Select a task to inspect its details.",
            .reopen: "Reopen",
            .complete: "Complete",
            .statusCompleted: "Completed",
            .statusOpen: "Open",
            .priority: "Priority",
            .deadline: "Deadline",
            .created: "Created",
            .deleteTask: "Delete task",
            .markOpen: "Mark open",
            .markComplete: "Mark complete",
            .quickAddTitle: "Quick Add",
            .close: "Close",
            .titlePlaceholder: "What must happen next?",
            .notesPlaceholder: "Notes (optional)",
            .schedule: "Schedule",
            .addDeadline: "Add deadline",
            .due: "Due",
            .createTag: "Create tag",
            .createTagEllipsis: "Create tag…",
            .cancel: "Cancel",
            .reference: "Reference",
            .remove: "Remove",
            .screenRecordingAccessOff: "Screen Recording access is off",
            .screenRecordingPermissionFormat: "Enable access for %@ in System Settings, then try capturing again.",
            .saveTask: "Save Task",
            .grantScreenRecording: "Grant Screen Recording",
            .screenRecordingGuideTitle: "Screen Recording Permission",
            .screenRecordingGuideSubtitle: "%@ needs this permission to attach screenshots to tasks.",
            .screenRecordingGuideDragHint: "Drag the app icon into System Settings",
            .screenRecordingGuideStepOpen: "Open Privacy & Security in System Settings.",
            .screenRecordingGuideStepDrag: "Drop it into the Screen & System Audio Recording list if the app is not listed.",
            .screenRecordingGuideStepReturn: "Turn on the toggle for this app.",
            .screenRecordingGuideOpenSettings: "Open Settings",
            .screenRecordingGuideWaiting: "SYSTEM SETTINGS",
            .captureScreenshot: "Capture Screenshot",
            .replaceScreenshot: "Replace Screenshot",
            .failedToSaveTask: "Failed to save task.",
            .menuBarAttentionSummaryFormat: "%d %@ need attention",
            .open: "Open",
            .quit: "Quit",
            .quitHelpFormat: "Quit %@",
            .themePorcelain: "Porcelain",
            .themeEmber: "Ember",
            .themeSumi: "Sumi",
            .themeCustom: "Custom",
            .themePorcelainTagline: "Clean · Restrained · Default",
            .themeEmberTagline: "Warm · Magazine-y",
            .themeSumiTagline: "Mono · Dense",
            .themeCustomTagline: "Your combination",
            .accentInkNavy: "Ink Navy",
            .accentGraphite: "Graphite",
            .accentCypress: "Cypress",
            .accentPorcelainBlue: "Porcelain Blue",
            .accentWarmOrange: "Warm Orange",
            .accentForestGreen: "Forest Green",
            .accentViolet: "Violet Glass",
            .accentSystem: "System",
            .accentInkNavyTagline: "Editorial · Classic",
            .accentGraphiteTagline: "Quiet · Refined",
            .accentCypressTagline: "Library · Grounded",
            .accentPorcelainBlueTagline: "Clean · Friendly",
            .accentWarmOrangeTagline: "Warm · Approachable",
            .accentForestGreenTagline: "Productive · Grounded",
            .accentVioletTagline: "Refractive · Expressive",
            .accentSystemTagline: "Follows System",
            .typographySFProTagline: "Clean · Default",
            .typographyRoundedTagline: "Friendly · Rounded",
            .typographyNewYorkTagline: "Editorial · Serif",
            .densityCompact: "Compact",
            .densityBalanced: "Balanced",
            .densityComfortable: "Comfortable",
            .densityCompactTagline: "~15 rows / screen",
            .densityBalancedTagline: "~10 rows / screen",
            .densityComfortableTagline: "~7 rows / screen",
            .exportedToFormat: "Exported to %@.",
            .importedSummaryFormat: "Imported %d tasks and %d tags.",
            .duplicateTagNameFormat: "Tag %@ already exists.",
            .shortcutEmpty: "Shortcut cannot be empty.",
            .shortcutUnsupportedFormat: "Unsupported shortcut key: %@",
            .shortcutRegisterFailedFormat: "Unable to register global shortcut: %@",
            .screenshotPermissionRequired: "Screen Recording access is required before capture can start."
        ],
        .simplifiedChinese: [
            .appName: "Todo",
            .settingsAppearanceTab: "外观",
            .settingsShortcutsTab: "快捷键",
            .settingsTagsTab: "标签",
            .settingsDataTab: "数据",
            .settingsSidebarTitle: "设置",
            .liquidGlass: "Liquid Glass",
            .liquidGlassSubtitle: "选择玻璃界面的偏好外观。",
            .liquidGlassClear: "清透",
            .liquidGlassTinted: "染色",
            .liquidGlassClearTagline: "尽量使用系统清透玻璃。",
            .liquidGlassTintedTagline: "玻璃轻微跟随主题强调色。",
            .language: "语言",
            .languageSubtitle: "选择应用语言，或跟随系统。",
            .theme: "主题",
            .themeSubtitle: "一键套用预设，也可以继续细调下面每个维度。",
            .accent: "强调色",
            .accentSubtitle: "控制选中态和主要操作的品牌色。",
            .lightTheme: "浅色主题",
            .lightThemeSubtitle: "应用处于浅色或系统浅色时使用。",
            .darkTheme: "深色主题",
            .darkThemeSubtitle: "应用处于深色或系统深色时使用。",
            .customAccent: "自定义强调色",
            .customAccentFormat: "自定义强调色 %@",
            .reset: "重置",
            .typography: "字体",
            .typographySubtitle: "控制展示标题和正文的字体风格。",
            .density: "密度",
            .densitySubtitle: "控制列表行高和整体间距。",
            .appearanceMode: "显示模式",
            .appearanceModeSubtitle: "跟随系统，或强制使用指定模式。",
            .mode: "模式",
            .shortcutGlobal: "全局快捷键",
            .shortcutGlobalSubtitle: "无需点击应用，也能从系统任意位置直接唤起。",
            .shortcutQuickInput: "快速输入",
            .shortcutShowDashboard: "打开主面板",
            .shortcutExamples: "示例：`F2`、`Command+Shift+K`、`Ctrl+Alt+1`",
            .shortcutPlaceholder: "快捷键",
            .save: "保存",
            .tags: "标签",
            .tagsSubtitle: "管理侧边栏里作为二级切片展示的标签。",
            .noTagsYet: "还没有标签，下面可以新建一个。",
            .newTag: "新标签",
            .add: "添加",
            .delete: "删除",
            .backupRestore: "备份与恢复",
            .backupRestoreSubtitle: "通过 JSON 做可迁移的数据导入导出，兼容旧版 Tauri 备份结构。",
            .exportJSON: "导出 JSON",
            .importJSON: "导入 JSON",
            .app: "应用",
            .appSubtitle: "窗口与 Dock 图标显示控制。",
            .hideDockIcon: "隐藏 Dock 图标",
            .hideDockIconSubtitle: "不在 Dock 中显示，仍可通过菜单栏和快捷键访问应用。",
            .openQuickAdd: "打开快速新增",
            .openDashboard: "打开主面板",
            .appearanceModeSystem: "跟随系统",
            .appearanceModeLight: "浅色",
            .appearanceModeDark: "深色",
            .sectionInboxTitle: "收集箱",
            .sectionTodayTitle: "今天",
            .sectionUpcomingTitle: "接下来",
            .sectionCompletedTitle: "已完成",
            .sectionInboxSubtitle: "所有未完成且未安排日期的事项。",
            .sectionTodaySubtitle: "当前真正需要处理的事项。",
            .sectionUpcomingSubtitle: "已经排期，但还可以稍后处理的事项。",
            .sectionCompletedSubtitle: "最近已经闭环的事项。",
            .taggedOpenWorkFormat: "当前展示标签“%@”下的未完成事项。",
            .metricDueToday: "今天到期",
            .metricUpcoming: "接下来",
            .metricClosed: "已关闭",
            .noDeadline: "无截止日期",
            .today: "今天",
            .tomorrow: "明天",
            .none: "无",
            .priorityCritical: "紧急",
            .priorityToday: "今日处理",
            .priorityPlanned: "已规划",
            .prioritySomeday: "以后再说",
            .sidebarTags: "标签",
            .collapseSidebar: "收起侧边栏",
            .expandSidebar: "展开侧边栏",
            .settings: "设置",
            .newTask: "新建任务",
            .searchPlaceholder: "搜索任务、备注或标签",
            .noSearchMatches: "没有匹配当前搜索的任务。",
            .emptySectionFormat: "%@ 里还没有任务。",
            .selectTaskForDetails: "选择一个任务查看详情。",
            .reopen: "重新打开",
            .complete: "完成",
            .statusCompleted: "已完成",
            .statusOpen: "进行中",
            .priority: "优先级",
            .deadline: "截止日期",
            .created: "创建时间",
            .deleteTask: "删除任务",
            .markOpen: "标记为未完成",
            .markComplete: "标记为已完成",
            .quickAddTitle: "快速新增",
            .close: "关闭",
            .titlePlaceholder: "下一步必须做什么？",
            .notesPlaceholder: "备注（可选）",
            .schedule: "时间安排",
            .addDeadline: "添加截止日期",
            .due: "截止",
            .createTag: "创建标签",
            .createTagEllipsis: "创建标签…",
            .cancel: "取消",
            .reference: "参考资料",
            .remove: "移除",
            .screenRecordingAccessOff: "未开启屏幕录制权限",
            .screenRecordingPermissionFormat: "请在系统设置里为 %@ 开启屏幕录制权限，然后再试一次。",
            .saveTask: "保存任务",
            .grantScreenRecording: "授权屏幕录制",
            .screenRecordingGuideTitle: "屏幕录制权限",
            .screenRecordingGuideSubtitle: "%@ 需要该权限后，才能把截图附加到任务里。",
            .screenRecordingGuideDragHint: "把应用图标拖到系统设置",
            .screenRecordingGuideStepOpen: "打开系统设置里的“隐私与安全性”。",
            .screenRecordingGuideStepDrag: "如果录屏列表里没有该应用，把图标拖进去。",
            .screenRecordingGuideStepReturn: "打开该应用右侧开关。",
            .screenRecordingGuideOpenSettings: "打开设置",
            .screenRecordingGuideWaiting: "系统设置",
            .captureScreenshot: "截取截图",
            .replaceScreenshot: "替换截图",
            .failedToSaveTask: "保存任务失败。",
            .menuBarAttentionSummaryFormat: "%d 个任务需要处理",
            .open: "打开",
            .quit: "退出",
            .quitHelpFormat: "退出 %@",
            .themePorcelain: "瓷白",
            .themeEmber: "余烬",
            .themeSumi: "墨色",
            .themeCustom: "自定义",
            .themePorcelainTagline: "干净 · 克制 · 默认",
            .themeEmberTagline: "温暖 · 杂志感",
            .themeSumiTagline: "单色 · 高密度",
            .themeCustomTagline: "你的组合",
            .accentInkNavy: "墨海军蓝",
            .accentGraphite: "石墨灰",
            .accentCypress: "柏木绿",
            .accentPorcelainBlue: "瓷蓝",
            .accentWarmOrange: "暖橙",
            .accentForestGreen: "森林绿",
            .accentViolet: "紫晶",
            .accentSystem: "系统色",
            .accentInkNavyTagline: "经典 · 编辑感",
            .accentGraphiteTagline: "安静 · 精致",
            .accentCypressTagline: "沉稳 · 书卷气",
            .accentPorcelainBlueTagline: "清爽 · 友好",
            .accentWarmOrangeTagline: "温暖 · 亲近",
            .accentForestGreenTagline: "高效 · 稳定",
            .accentVioletTagline: "折射感 · 表现力",
            .accentSystemTagline: "跟随系统",
            .typographySFProTagline: "干净 · 默认",
            .typographyRoundedTagline: "友好 · 圆润",
            .typographyNewYorkTagline: "编辑感 · 衬线",
            .densityCompact: "紧凑",
            .densityBalanced: "平衡",
            .densityComfortable: "舒适",
            .densityCompactTagline: "约 15 行 / 屏",
            .densityBalancedTagline: "约 10 行 / 屏",
            .densityComfortableTagline: "约 7 行 / 屏",
            .exportedToFormat: "已导出到 %@。",
            .importedSummaryFormat: "已导入 %d 个任务，%d 个标签。",
            .duplicateTagNameFormat: "标签“%@”已存在。",
            .shortcutEmpty: "快捷键不能为空。",
            .shortcutUnsupportedFormat: "不支持的快捷键：%@",
            .shortcutRegisterFailedFormat: "无法注册全局快捷键：%@",
            .screenshotPermissionRequired: "开始截图前需要先授予屏幕录制权限。"
        ]
    ]

    static func resolvedLanguage(from preference: AppLanguage = AppLanguage.persisted()) -> ResolvedLanguage {
        switch preference {
        case .english:
            return .english
        case .simplifiedChinese:
            return .simplifiedChinese
        case .system:
            let preferredIdentifier = Locale.preferredLanguages.first?.lowercased() ?? ""
            return preferredIdentifier.hasPrefix("zh") ? .simplifiedChinese : .english
        }
    }

    static func currentLanguage() -> ResolvedLanguage {
        resolvedLanguage(from: AppLanguage.persisted())
    }

    static func currentLocale() -> Locale {
        Locale(identifier: currentLanguage().localeIdentifier)
    }

    static func persist(language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: AppLanguage.userDefaultsKey)
    }

    static func string(_ key: LocalizedKey, language: ResolvedLanguage = currentLanguage()) -> String {
        tables[language]?[key] ?? tables[.english]?[key] ?? key.rawValue
    }

    static func format(_ key: LocalizedKey, language: ResolvedLanguage = currentLanguage(), _ arguments: CVarArg...) -> String {
        format(key, language: language, arguments: arguments)
    }

    static func format(_ key: LocalizedKey, language: ResolvedLanguage = currentLanguage(), arguments: [CVarArg]) -> String {
        String(format: string(key, language: language), locale: Locale(identifier: language.localeIdentifier), arguments: arguments)
    }

    static func taskCountSummary(_ count: Int, language: ResolvedLanguage = currentLanguage()) -> String {
        switch language {
        case .english:
            return "\(count) \(count == 1 ? "task" : "tasks")"
        case .simplifiedChinese:
            return "\(count) 个任务"
        }
    }

    static func menuBarAttentionSummary(_ count: Int, language: ResolvedLanguage = currentLanguage()) -> String {
        switch language {
        case .english:
            let noun = count == 1 ? "task" : "tasks"
            return format(.menuBarAttentionSummaryFormat, language: language, count, noun)
        case .simplifiedChinese:
            return format(.menuBarAttentionSummaryFormat, language: language, count)
        }
    }

    static func dueLabelDate(_ date: Date, language: ResolvedLanguage = currentLanguage()) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(Locale(identifier: language.localeIdentifier))
        )
    }

    static func detailDate(_ date: Date, language: ResolvedLanguage = currentLanguage()) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted)
                .locale(Locale(identifier: language.localeIdentifier))
        )
    }

    static func dateTime(_ date: Date, language: ResolvedLanguage = currentLanguage()) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(Locale(identifier: language.localeIdentifier))
        )
    }
}

@MainActor
@Observable
final class LocalizationStore {
    var language: AppLanguage {
        didSet {
            LocalizedText.persist(language: language)
        }
    }

    init(language: AppLanguage = AppLanguage.persisted()) {
        self.language = language
        LocalizedText.persist(language: language)
    }

    var resolvedLanguage: ResolvedLanguage {
        LocalizedText.resolvedLanguage(from: language)
    }

    var locale: Locale {
        Locale(identifier: resolvedLanguage.localeIdentifier)
    }

    func apply(_ language: AppLanguage) {
        self.language = language
    }

    func text(_ key: LocalizedKey) -> String {
        LocalizedText.string(key, language: resolvedLanguage)
    }

    func format(_ key: LocalizedKey, _ arguments: CVarArg...) -> String {
        LocalizedText.format(key, language: resolvedLanguage, arguments: arguments)
    }
}
