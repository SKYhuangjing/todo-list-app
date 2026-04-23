import AppKit
import SwiftUI

struct WindowBridge: NSViewRepresentable {
    let role: WindowRole
    let title: String

    func makeNSView(context: Context) -> BridgeView {
        let view = BridgeView()
        view.role = role
        view.title = title
        return view
    }

    func updateNSView(_ nsView: BridgeView, context: Context) {
        nsView.role = role
        nsView.title = title
        nsView.applyConfigurationIfNeeded()
    }
}

final class BridgeView: NSView {
    var role: WindowRole = .dashboard
    var title = LocalizedText.string(.appName)
    private var lastWindowNumber: Int?
    private var delegateProxy: BridgeWindowDelegate?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyConfigurationIfNeeded()
    }

    override func removeFromSuperview() {
        if let window {
            WindowRegistry.shared.unregister(window: window, for: role)
        }
        super.removeFromSuperview()
    }

    func applyConfigurationIfNeeded() {
        guard let window else { return }
        guard lastWindowNumber != window.windowNumber || window.title != title else { return }

        delegateProxy = BridgeWindowDelegate(role: role)
        window.delegate = delegateProxy
        window.title = title
        window.titleVisibility = .visible
        window.identifier = NSUserInterfaceItemIdentifier(title)
        window.tabbingMode = .disallowed
        WindowRegistry.shared.register(window, for: role)

        lastWindowNumber = window.windowNumber
    }
}

final class BridgeWindowDelegate: NSObject, NSWindowDelegate {
    let role: WindowRole

    init(role: WindowRole) {
        self.role = role
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        switch role {
        case .dashboard:
            sender.orderOut(nil)
            return false
        }
    }
}
