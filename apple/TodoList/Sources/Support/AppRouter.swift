import AppKit
import OSLog

@MainActor
final class AppRouter {
    private let quickAddPanelController: QuickAddPanelController
    private let logger = Logger(subsystem: "com.sky.todolistapp", category: "routing")
    private let settingsWindowIdentifier = NSUserInterfaceItemIdentifier("com_apple_SwiftUI_Settings_window")
    private var dashboardOpener: (() -> Void)?

    init(quickAddPanelController: QuickAddPanelController) {
        self.quickAddPanelController = quickAddPanelController
    }

    func setDashboardOpener(_ opener: @escaping () -> Void) {
        dashboardOpener = opener
    }

    func showDashboard() {
        logger.info("show_dashboard")
        if WindowRegistry.shared.showDashboard() {
            return
        }
        dashboardOpener?()
        DispatchQueue.main.async {
            _ = WindowRegistry.shared.showDashboard()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showQuickAdd(preserveDraft: Bool = false) {
        logger.info("show_quick_add preserve_draft=\(preserveDraft)")
        quickAddPanelController.showPanel(preserveDraft: preserveDraft)
    }

    func hideQuickAdd() {
        logger.info("hide_quick_add")
        quickAddPanelController.hidePanel()
    }

    func openSettings() {
        logger.info("open_settings")
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { [settingsWindowIdentifier] in
            guard let settingsWindow = NSApp.windows.first(where: { $0.identifier == settingsWindowIdentifier }) else {
                return
            }
            settingsWindow.orderFrontRegardless()
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func quit() {
        logger.info("quit")
        NSApp.terminate(nil)
    }
}
