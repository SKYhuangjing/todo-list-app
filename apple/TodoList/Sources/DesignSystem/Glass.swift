import SwiftUI

enum GlassStyle: Equatable {
    case chrome
    case sheet
}

extension View {
    @ViewBuilder
    func glassChrome<S: InsettableShape>(
        in shape: S,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassChromeModifier(shape: shape, tint: tint, interactive: interactive, style: .chrome))
    }

    @ViewBuilder
    func glassSheet<S: InsettableShape>(in shape: S, tint: Color? = nil) -> some View {
        modifier(GlassChromeModifier(shape: shape, tint: tint, interactive: false, style: .sheet))
    }

    @ViewBuilder
    func glassInteractive<S: InsettableShape>(in shape: S, tint: Color? = nil) -> some View {
        modifier(GlassChromeModifier(shape: shape, tint: tint, interactive: true, style: .chrome))
    }
}

private struct GlassChromeModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    let tint: Color?
    let interactive: Bool
    let style: GlassStyle

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(makeGlass(), in: shape)
        } else {
            content
                .background(fallbackMaterial, in: shape)
                .overlay(shape.strokeBorder(strokeColor, lineWidth: 0.8))
                .shadow(
                    color: fallbackShadowColor,
                    radius: fallbackShadowRadius,
                    x: 0,
                    y: fallbackShadowY
                )
        }
    }

    @available(macOS 26.0, *)
    private func makeGlass() -> Glass {
        var glass: Glass = style == .sheet ? .regular : (interactive ? .regular.interactive() : .regular)
        if let tint {
            glass = glass.tint(tint.opacity(colorScheme == .dark ? 0.22 : 0.18))
        }
        return glass
    }

    private var fallbackMaterial: Material {
        switch style {
        case .sheet: return .thickMaterial
        case .chrome: return .regularMaterial
        }
    }

    private var strokeColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(style == .sheet ? 0.14 : 0.10)
        }
        return Color.black.opacity(style == .sheet ? 0.08 : 0.06)
    }

    private var fallbackShadowColor: Color {
        switch style {
        case .sheet: return Elevation.modal.shadowColor(for: colorScheme)
        case .chrome: return Elevation.chrome.shadowColor(for: colorScheme)
        }
    }

    private var fallbackShadowRadius: CGFloat {
        switch style {
        case .sheet: return Elevation.modal.blur
        case .chrome: return Elevation.chrome.blur
        }
    }

    private var fallbackShadowY: CGFloat {
        switch style {
        case .sheet: return Elevation.modal.yOffset
        case .chrome: return Elevation.chrome.yOffset
        }
    }
}

struct GlassChromeCluster<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer {
                content()
            }
        } else {
            content()
        }
    }
}

extension View {
    @ViewBuilder
    func canvasBackground() -> some View {
        self.background(SurfaceColor.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    func sheetCanvasBackground() -> some View {
        self.background(SurfaceColor.canvasElevated.ignoresSafeArea())
    }

    @ViewBuilder
    func adaptiveWindowBackground() -> some View {
        if #available(macOS 26.0, *) {
            self
                .containerBackground(.regularMaterial, for: .window)
                .background {
                    StableWindowBackdrop()
                        .ignoresSafeArea()
                }
        } else {
            self.background(SurfaceColor.canvas.ignoresSafeArea())
        }
    }
}

private struct StableWindowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                SurfaceColor.canvas
                    .opacity(colorScheme == .dark ? 0.54 : 0.76)
            }
    }
}
