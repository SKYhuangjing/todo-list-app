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
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(makeGlass(), in: shape)
        } else {
            content
                .background(fallbackMaterial, in: shape)
                .overlay {
                    shape.fill(fallbackTintOverlay)
                }
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
            glass = glass.tint(tint.opacity(colorScheme == .dark ? 0.34 : 0.26))
        } else if theme.liquidGlass == .tinted {
            glass = glass.tint(theme.accentColor.opacity(colorScheme == .dark ? 0.52 : 0.42))
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
            return Color.white.opacity(theme.liquidGlass == .tinted ? 0.20 : (style == .sheet ? 0.14 : 0.10))
        }
        return theme.liquidGlass == .tinted
            ? theme.accentColor.opacity(0.28)
            : Color.black.opacity(style == .sheet ? 0.08 : 0.06)
    }

    private var fallbackTintOverlay: Color {
        if let tint {
            return tint.opacity(colorScheme == .dark ? 0.16 : 0.10)
        }
        guard theme.liquidGlass == .tinted else {
            return Color.white.opacity(colorScheme == .dark ? 0.02 : 0.04)
        }
        return theme.accentColor.opacity(colorScheme == .dark ? 0.24 : 0.16)
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
        modifier(ThemedCanvasBackgroundModifier(elevated: false))
    }

    @ViewBuilder
    func sheetCanvasBackground() -> some View {
        modifier(ThemedCanvasBackgroundModifier(elevated: true))
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
            modifier(ThemedCanvasBackgroundModifier(elevated: false))
        }
    }
}

private struct ThemedCanvasBackgroundModifier: ViewModifier {
    let elevated: Bool

    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let palette = theme.palette(for: colorScheme)
        content.background((elevated ? palette.canvasElevated : palette.canvas).ignoresSafeArea())
    }
}

private struct StableWindowBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    var body: some View {
        let palette = theme.palette(for: colorScheme)
        Rectangle()
            .fill(.regularMaterial)
            .overlay {
                palette.canvas
                    .opacity(theme.liquidGlass == .tinted ? (colorScheme == .dark ? 0.72 : 0.78) : (colorScheme == .dark ? 0.84 : 0.90))
            }
            .overlay {
                if theme.liquidGlass == .tinted {
                    theme.accentColor
                        .opacity(colorScheme == .dark ? 0.12 : 0.08)
                }
            }
    }
}
