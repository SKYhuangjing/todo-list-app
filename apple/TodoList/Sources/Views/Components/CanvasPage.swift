import SwiftUI

extension View {
    func canvasPage() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(SurfaceColor.canvas.ignoresSafeArea())
    }
}
