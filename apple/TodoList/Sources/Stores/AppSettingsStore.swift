import AppKit
import Observation

@MainActor
@Observable
final class AppSettingsStore {
    var appearanceMode: AppearanceMode = .system
    var appLanguage: AppLanguage = AppLanguage.persisted()
    var shortcuts: ShortcutConfiguration = .default
    var hideDockIcon = false

    private let database: TodoDatabase
    private let globalShortcutManager = GlobalShortcutManager.shared
    private var localizationStore: LocalizationStore?

    init(database: TodoDatabase = TodoDatabase()) {
        self.database = database
    }

    func bootstrap(router: AppRouter, localizationStore: LocalizationStore) async {
        self.localizationStore = localizationStore
        do {
            let snapshot = try await database.loadSettingsSnapshot()
            appearanceMode = snapshot.appearanceMode
            appLanguage = snapshot.appLanguage
            shortcuts = snapshot.shortcuts
            hideDockIcon = snapshot.hideDockIcon
        } catch {
            print("Failed to load settings: \(error.localizedDescription)")
        }

        localizationStore.apply(appLanguage)

        applyAppearance()
        applyDockVisibility()
        do {
            try globalShortcutManager.update(shortcuts: shortcuts, router: router)
        } catch {
            print("Failed to register global shortcuts: \(error.localizedDescription)")
        }
    }

    func saveAppearance(_ mode: AppearanceMode) async throws {
        try await database.upsertSetting(key: .appearanceMode, value: mode.rawValue)
        appearanceMode = mode
        applyAppearance()
    }

    func saveLanguage(_ language: AppLanguage) async throws {
        try await database.upsertSetting(key: .appLanguage, value: language.rawValue)
        appLanguage = language
        localizationStore?.apply(language)
    }

    func saveShortcut(role: ShortcutRole, value: String, router: AppRouter) async throws {
        _ = try ShortcutParser.parse(value)

        switch role {
        case .quickInput:
            try await database.upsertSetting(key: .quickInputShortcut, value: value)
            shortcuts.quickInput = value
        case .showList:
            try await database.upsertSetting(key: .showListShortcut, value: value)
            shortcuts.showList = value
        }

        try globalShortcutManager.update(shortcuts: shortcuts, router: router)
    }

    func saveDockVisibility(hidden: Bool) async throws {
        try await database.upsertSetting(key: .hideDockIcon, value: hidden ? "true" : "false")
        hideDockIcon = hidden
        applyDockVisibility()
    }

    private func applyAppearance() {
        switch appearanceMode {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func applyDockVisibility() {
        let policy: NSApplication.ActivationPolicy = hideDockIcon ? .accessory : .regular
        if NSApp.activationPolicy() != policy {
            NSApp.setActivationPolicy(policy)
        }

        if !hideDockIcon {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
