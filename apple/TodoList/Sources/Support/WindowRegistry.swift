import AppKit

enum WindowRole {
    case dashboard
}

@MainActor
final class WindowRegistry {
    static let shared = WindowRegistry()

    private weak var dashboardWindow: NSWindow?

    func register(_ window: NSWindow, for role: WindowRole) {
        switch role {
        case .dashboard:
            dashboardWindow = window
        }
    }

    func unregister(window: NSWindow, for role: WindowRole) {
        switch role {
        case .dashboard where dashboardWindow === window:
            dashboardWindow = nil
        default:
            break
        }
    }

    @discardableResult
    func showDashboard() -> Bool {
        guard let dashboardWindow else { return false }
        dashboardWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        return true
    }
}
