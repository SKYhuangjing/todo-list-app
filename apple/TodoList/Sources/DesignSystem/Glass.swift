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
    func neutralGlassSheet<S: InsettableShape>(in shape: S) -> some View {
        modifier(GlassChromeModifier(shape: shape, tint: nil, interactive: false, style: .sheet, forceNeutral: true))
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
    var forceNeutral = false

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
        let glassProfile = forceNeutral ? .clear : theme.effectiveLiquidGlass
        if let tint {
            glass = glass.tint(tint.opacity(colorScheme == .dark ? 0.34 : 0.26))
        } else if glassProfile == .tinted {
            glass = glass.tint(theme.accentColor.opacity(colorScheme == .dark ? 0.52 : 0.42))
        } else if glassProfile == .vivid {
            glass = glass.tint(theme.accentColor.opacity(colorScheme == .dark ? 0.68 : 0.56))
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
        let glassProfile = forceNeutral ? .clear : theme.effectiveLiquidGlass
        if glassProfile == .reduced {
            return theme.palette(for: colorScheme).separator
        }
        if colorScheme == .dark {
            return Color.white.opacity(glassProfile == .vivid ? 0.26 : glassProfile == .tinted ? 0.20 : (style == .sheet ? 0.14 : 0.10))
        }
        return glassProfile == .vivid
            ? theme.accentColor.opacity(0.40)
            : glassProfile == .tinted
            ? theme.accentColor.opacity(0.28)
            : Color.black.opacity(style == .sheet ? 0.08 : 0.06)
    }

    private var fallbackTintOverlay: Color {
        let glassProfile = forceNeutral ? .clear : theme.effectiveLiquidGlass
        if let tint {
            return tint.opacity(colorScheme == .dark ? 0.16 : 0.10)
        }
        if glassProfile == .reduced {
            return theme.palette(for: colorScheme).canvasElevated.opacity(colorScheme == .dark ? 0.62 : 0.54)
        }
        guard glassProfile == .tinted || glassProfile == .vivid else {
            return Color.white.opacity(colorScheme == .dark ? 0.02 : 0.04)
        }
        return theme.accentColor.opacity(glassProfile == .vivid ? (colorScheme == .dark ? 0.34 : 0.20) : (colorScheme == .dark ? 0.24 : 0.10))
    }

    private var fallbackShadowColor: Color {
        switch style {
        case .sheet: return Elevation.modal.shadowColor(for: colorScheme)
        case .chrome: return Elevation.chrome.shadowColor(for: colorScheme)
        }
    }

    private var fallbackShadowRadius: CGFloat {
        if !forceNeutral && theme.effectiveLiquidGlass == .reduced {
            return 0
        }
        switch style {
        case .sheet: return Elevation.modal.blur
        case .chrome: return Elevation.chrome.blur
        }
    }

    private var fallbackShadowY: CGFloat {
        if !forceNeutral && theme.effectiveLiquidGlass == .reduced {
            return 0
        }
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
                    .opacity(windowCanvasOpacity)
            }
            .overlay {
                if theme.effectiveLiquidGlass == .tinted || theme.effectiveLiquidGlass == .vivid {
                    theme.accentColor
                        .opacity(theme.effectiveLiquidGlass == .vivid ? (colorScheme == .dark ? 0.18 : 0.10) : (colorScheme == .dark ? 0.12 : 0.05))
                }
            }
    }

    private var windowCanvasOpacity: Double {
        switch theme.effectiveLiquidGlass {
        case .reduced:
            return 1
        case .clear:
            return colorScheme == .dark ? 0.84 : 0.90
        case .tinted:
            return colorScheme == .dark ? 0.72 : 0.84
        case .vivid:
            return colorScheme == .dark ? 0.62 : 0.76
        }
    }
}
