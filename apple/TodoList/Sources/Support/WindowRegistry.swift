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

    func showDashboard() {
        guard let dashboardWindow else { return }
        dashboardWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
