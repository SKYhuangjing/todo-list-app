import AppKit
import SwiftUI

enum AppWindow {
    static let dashboard = "dashboard"
}

@main
struct TodoListApp: App {
    @State private var store: TodoStore
    @State private var settingsStore: AppSettingsStore
    @State private var themeStore: ThemeStore
    @State private var localizationStore: LocalizationStore
    private let router: AppRouter

    init() {
        Self.migrateSidebarLayoutIfNeeded()

        let database = TodoDatabase()
        let store = TodoStore(database: database)
        let settingsStore = AppSettingsStore(database: database)
        let themeStore = ThemeStore()
        let localizationStore = LocalizationStore()
        let quickAddPanelController = QuickAddPanelController(
            store: store,
            themeStore: themeStore,
            localizationStore: localizationStore
        )
        let router = AppRouter(quickAddPanelController: quickAddPanelController)

        self._store = State(initialValue: store)
        self._settingsStore = State(initialValue: settingsStore)
        self._themeStore = State(initialValue: themeStore)
        self._localizationStore = State(initialValue: localizationStore)
        self.router = router
        AppRouterHolder.shared.router = router
    }

    private static func migrateSidebarLayoutIfNeeded() {
        let defaults = UserDefaults.standard
        let migrationKey = "sidebar.compactDefault.migrated.v3"
        guard !defaults.bool(forKey: migrationKey) else { return }
        for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix("NSSplitView Subview Frames") {
            defaults.removeObject(forKey: key)
        }
        defaults.set(true, forKey: migrationKey)
    }

    var body: some Scene {
        WindowGroup(LocalizedText.string(.appName, language: localizationStore.resolvedLanguage), id: AppWindow.dashboard) {
            RootView(store: store, router: router)
                .frame(
                    minWidth: 1240,
                    idealWidth: 1320,
                    maxWidth: .infinity,
                    minHeight: 780,
                    idealHeight: 840,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .environment(themeStore)
                .theme(themeStore.theme)
                .environment(localizationStore)
                .environment(\.locale, localizationStore.locale)
                .id(localizationStore.language)
                .task {
                    await settingsStore.bootstrap(router: router, localizationStore: localizationStore)
                }
        }
        .defaultSize(width: 1320, height: 840)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
        .defaultWindowPlacement { content, context in
            let ideal = content.sizeThatFits(.unspecified)
            let visibleRect = context.defaultDisplay.visibleRect
            let width = min(max(ideal.width, 1240), visibleRect.width)
            let height = min(max(ideal.height, 780), visibleRect.height)
            let x = visibleRect.midX - (width / 2)
            let y = visibleRect.midY - (height / 2)
            return WindowPlacement(CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
        }

        MenuBarExtra {
            MenuBarDashboardView(store: store, router: router)
                .environment(themeStore)
                .theme(themeStore.theme)
                .environment(localizationStore)
                .environment(\.locale, localizationStore.locale)
                .id(localizationStore.language)
        } label: {
            Image(systemName: "checkmark.circle")
                .symbolRenderingMode(.monochrome)
                .accessibilityLabel(LocalizedText.string(.appName, language: localizationStore.resolvedLanguage))
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(store: store, settingsStore: settingsStore, router: router)
                .environment(themeStore)
                .theme(themeStore.theme)
                .environment(localizationStore)
                .environment(\.locale, localizationStore.locale)
                .id(localizationStore.language)
        }
    }
}
