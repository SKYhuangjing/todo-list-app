import AppKit
import SwiftUI

struct SettingsWindowBridge: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.styleMask.remove(.fullSizeContentView)
            window.toolbarStyle = .unifiedCompact
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.styleMask.remove(.fullSizeContentView)
            window.toolbarStyle = .unifiedCompact
        }
    }
}
