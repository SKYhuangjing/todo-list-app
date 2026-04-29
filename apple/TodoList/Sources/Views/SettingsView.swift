import SwiftUI

struct SettingsView: View {
    @Bindable var store: TodoStore
    @Bindable var settingsStore: AppSettingsStore
    let router: AppRouter

    @Environment(\.theme) private var theme
    @Environment(ThemeStore.self) private var themeStore
    @Environment(LocalizationStore.self) private var localizationStore
    @State private var selection: SettingsSection = .appearance

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selection) { section in
                Label(section.title(localizationStore), systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle(localizationStore.text(.settingsSidebarTitle))
            .listStyle(.sidebar)
            .frame(minWidth: 170)
        } detail: {
            Group {
                switch selection {
                case .appearance:
                    AppearanceSettingsTab(settingsStore: settingsStore, themeStore: themeStore)
                case .shortcuts:
                    ShortcutsSettingsTab(settingsStore: settingsStore, router: router)
                case .tags:
                    TagsSettingsTab(store: store)
                case .data:
                    DataSettingsTab(store: store, settingsStore: settingsStore, router: router)
                }
            }
            .id(selection)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(Motion.settingsSection, value: selection)
        .frame(width: 760, height: 620)
        .adaptiveWindowBackground()
        .background {
            SettingsWindowBridge()
                .frame(width: 0, height: 0)
        }
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case appearance
    case shortcuts
    case tags
    case data

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .appearance: "paintpalette"
        case .shortcuts: "command"
        case .tags: "tag"
        case .data: "externaldrive"
        }
    }

    @MainActor
    func title(_ localizationStore: LocalizationStore) -> String {
        switch self {
        case .appearance: localizationStore.text(.settingsAppearanceTab)
        case .shortcuts: localizationStore.text(.settingsShortcutsTab)
        case .tags: localizationStore.text(.settingsTagsTab)
        case .data: localizationStore.text(.settingsDataTab)
        }
    }
}

private struct AnimatedSettingsCardModifier: ViewModifier {
    let isSelected: Bool
    let selectedTint: Color
    let cornerRadius: CGFloat

    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? 1.018 : 1)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? SurfaceColor.selectedControl : SurfaceColor.recessedControl)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? selectedTint.opacity(0.78)
                            : Color.primary.opacity(isHovering ? 0.16 : 0.05),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .shadow(
                color: isHovering ? selectedTint.opacity(0.14) : Color.clear,
                radius: isHovering ? 10 : 0,
                y: isHovering ? 3 : 0
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onHover { hovering in
                withAnimation(Motion.hover) {
                    isHovering = hovering
                }
            }
            .animation(Motion.glassMorph, value: isSelected)
    }
}

private struct SettingsCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(Motion.cardPress, value: configuration.isPressed)
    }
}

private extension View {
    func animatedSettingsCard(
        isSelected: Bool,
        selectedTint: Color,
        cornerRadius: CGFloat = Radius.md
    ) -> some View {
        modifier(
            AnimatedSettingsCardModifier(
                isSelected: isSelected,
                selectedTint: selectedTint,
                cornerRadius: cornerRadius
            )
        )
    }
}

// MARK: - Appearance

private struct AppearanceSettingsTab: View {
    @Bindable var settingsStore: AppSettingsStore
    let themeStore: ThemeStore

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    private let cardColumns = [GridItem(.adaptive(minimum: 150), spacing: Space.md, alignment: .top)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xl) {
                modeSection

                Divider().opacity(0.5)

                liquidGlassSection

                Divider().opacity(0.5)

                presetSection

                Divider().opacity(0.5)

                ThemeToneSection(
                    title: localizationStore.text(.lightTheme),
                    subtitle: localizationStore.text(.lightThemeSubtitle),
                    colorScheme: .light,
                    tone: themeStore.theme.light,
                    themeStore: themeStore
                )

                ThemeToneSection(
                    title: localizationStore.text(.darkTheme),
                    subtitle: localizationStore.text(.darkThemeSubtitle),
                    colorScheme: .dark,
                    tone: themeStore.theme.dark,
                    themeStore: themeStore
                )

                Divider().opacity(0.5)

                typographySection
                densitySection

                Divider().opacity(0.5)

                languageSection
            }
            .padding(.horizontal, Space.xxl)
            .padding(.vertical, Space.xl)
        }
        .scrollIndicators(.hidden)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            SettingsHeading(title: localizationStore.text(.theme), subtitle: localizationStore.text(.themeSubtitle))

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: Space.md) {
                ForEach([ThemePreset.porcelain, .ember, .sumi], id: \.self) { preset in
                    PresetCard(
                        preset: preset,
                        isSelected: themeStore.theme.preset == preset
                    ) {
                        withAnimation(Motion.glassMorph) {
                            themeStore.applyPreset(preset)
                        }
                    }
                }

                if themeStore.theme.preset == .custom {
                    PresetCard(
                        preset: .custom,
                        isSelected: true,
                        action: {}
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SettingsHeading(title: localizationStore.text(.typography), subtitle: localizationStore.text(.typographySubtitle))

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: Space.md) {
                ForEach(TypographyToken.allCases) { token in
                    TypographyCard(
                        token: token,
                        isSelected: themeStore.theme.typography == token
                    ) {
                        withAnimation(Motion.glassMorph) {
                            themeStore.setTypography(token)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var densitySection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SettingsHeading(title: localizationStore.text(.density), subtitle: localizationStore.text(.densitySubtitle))

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: Space.md) {
                ForEach(DensityToken.allCases) { token in
                    DensityCard(
                        token: token,
                        isSelected: themeStore.theme.density == token
                    ) {
                        withAnimation(Motion.glassMorph) {
                            themeStore.setDensity(token)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SettingsHeading(title: localizationStore.text(.appearanceMode), subtitle: localizationStore.text(.appearanceModeSubtitle))

            Picker(
                localizationStore.text(.mode),
                selection: Binding(
                    get: { settingsStore.appearanceMode },
                    set: { newValue in
                        Task {
                            try? await settingsStore.saveAppearance(newValue)
                        }
                    }
                )
            ) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 320)
        }
    }

    private var liquidGlassSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SettingsHeading(title: localizationStore.text(.liquidGlass), subtitle: localizationStore.text(.liquidGlassSubtitle))

            HStack(spacing: Space.md) {
                ForEach(LiquidGlassToken.allCases) { token in
                    LiquidGlassCard(
                        token: token,
                        isSelected: themeStore.theme.liquidGlass == token
                    ) {
                        withAnimation(Motion.glassMorph) {
                            themeStore.setLiquidGlass(token)
                        }
                    }
                }
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SettingsHeading(title: localizationStore.text(.language), subtitle: localizationStore.text(.languageSubtitle))

            Picker(
                localizationStore.text(.language),
                selection: Binding(
                    get: { settingsStore.appLanguage },
                    set: { newValue in
                        Task {
                            try? await settingsStore.saveLanguage(newValue)
                        }
                    }
                )
            ) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.title(for: localizationStore.resolvedLanguage)).tag(language)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 360)
        }
    }
}

// MARK: - Preset Card

private struct PresetCard: View {
    let preset: ThemePreset
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.theme) private var theme

    private var previewAccent: Color {
        preset == .custom ? theme.accentColor : Theme(preset: preset).accentColor
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.sm) {
                HStack(spacing: 4) {
                    Circle().fill(previewAccent).frame(width: 10, height: 10)
                    Circle().fill(Color.primary.opacity(0.10)).frame(width: 10, height: 10)
                    Circle().fill(Color.primary.opacity(0.05)).frame(width: 10, height: 10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.displayName)
                        .font(theme.type.headline)
                    Text(preset.tagline)
                        .font(theme.type.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 68, alignment: .leading)
            .padding(Space.md)
            .animatedSettingsCard(isSelected: isSelected, selectedTint: previewAccent)
        }
        .buttonStyle(SettingsCardButtonStyle())
    }
}

// MARK: - Liquid Glass Card

private struct LiquidGlassCard: View {
    let token: LiquidGlassToken
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.sm) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(previewBackground)
                        .frame(height: 58)
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 5) {
                                Capsule()
                                    .fill(Color.white.opacity(0.82))
                                    .frame(width: 68, height: 8)
                                Capsule()
                                    .fill(Color.white.opacity(0.46))
                                    .frame(width: 42, height: 7)
                            }
                            .padding(10)
                        }

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.regularMaterial)
                        .overlay {
                            if token == .tinted {
                                theme.accentColor.opacity(colorScheme == .dark ? 0.44 : 0.34)
                            } else {
                                Color.white.opacity(colorScheme == .dark ? 0.08 : 0.22)
                            }
                        }
                        .frame(width: 92, height: 34)
                        .overlay {
                            Capsule()
                                .fill(Color.white.opacity(0.55))
                                .frame(width: 54, height: 12)
                        }
                        .padding(8)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(token.displayName)
                        .font(theme.type.callout.weight(.semibold))
                    Text(token.tagline)
                        .font(theme.type.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(width: 170, alignment: .topLeading)
            .frame(minHeight: 124, alignment: .topLeading)
            .padding(Space.md)
            .animatedSettingsCard(isSelected: isSelected, selectedTint: theme.accentColor)
        }
        .buttonStyle(SettingsCardButtonStyle())
    }

    private var previewBackground: LinearGradient {
        let tint = token == .tinted ? theme.accentColor : Color.blue
        return LinearGradient(
            colors: [
                tint.opacity(token == .tinted ? (colorScheme == .dark ? 0.82 : 0.62) : (colorScheme == .dark ? 0.52 : 0.34)),
                (token == .tinted ? theme.accentColor : Color.primary).opacity(colorScheme == .dark ? 0.34 : 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Theme tone

private struct ThemeToneSection: View {
    let title: String
    let subtitle: String
    let colorScheme: ColorScheme
    let tone: ThemeTone
    let themeStore: ThemeStore

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    private let swatchColumns = [GridItem(.adaptive(minimum: 58), spacing: Space.sm, alignment: .top)]

    var body: some View {
        VStack(alignment: .leading, spacing: Space.sm) {
            HStack(alignment: .firstTextBaseline) {
                SettingsHeading(title: title, subtitle: subtitle)

                Spacer()

                ColorPicker(
                    localizationStore.text(.customAccent),
                    selection: Binding(
                        get: { tone.accentColor(for: colorScheme) },
                        set: { newColor in
                            withAnimation(Motion.glassMorph) {
                                themeStore.setCustomAccent(newColor, for: colorScheme)
                            }
                        }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()

                Button(localizationStore.text(.reset)) {
                    withAnimation(Motion.glassMorph) {
                        themeStore.clearCustomAccent(for: colorScheme)
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .disabled(!tone.usesCustomAccent)
            }
            .padding(.bottom, Space.xs)

            if let customAccentHex = tone.customAccentHex {
                HStack(spacing: Space.sm) {
                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(tone.accentColor(for: colorScheme))
                    Text(LocalizedText.format(.customAccentFormat, language: localizationStore.resolvedLanguage, customAccentHex))
                        .font(theme.type.caption)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: swatchColumns, alignment: .leading, spacing: Space.md) {
                ForEach(AccentToken.allCases) { token in
                    AccentSwatch(
                        token: token,
                        colorScheme: colorScheme,
                        isSelected: !tone.usesCustomAccent && tone.accent == token
                    ) {
                        withAnimation(Motion.glassMorph) {
                            themeStore.setAccent(token, for: colorScheme)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Space.md)
            .padding(.vertical, Space.sm)
            .background {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .fill(SurfaceColor.recessedControl)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
            }
            .animation(Motion.glassMorph, value: tone.accent)
            .animation(Motion.glassMorph, value: tone.customAccentHex)
        }
    }
}

// MARK: - Accent swatch

private struct AccentSwatch: View {
    let token: AccentToken
    let colorScheme: ColorScheme
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    private var swatchColor: Color { token.color(for: colorScheme) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: Space.xs) {
                ZStack {
                    Circle()
                        .fill(swatchColor)
                        .frame(width: 30, height: 30)

                    if isSelected {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                            .frame(width: 30, height: 30)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? swatchColor : Color.clear, lineWidth: 2)
                        .frame(width: isHovering || isSelected ? 40 : 38, height: isHovering || isSelected ? 40 : 38)
                }
                .frame(width: 42, height: 42)
                .scaleEffect(isHovering ? 1.07 : 1)

                Text(token.displayName)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
        }
        .buttonStyle(SettingsCardButtonStyle())
        .onHover { hovering in
            withAnimation(Motion.hover) {
                isHovering = hovering
            }
        }
        .animation(Motion.glassMorph, value: isSelected)
        .help(token.tagline)
    }
}

// MARK: - Typography card

private struct TypographyCard: View {
    let token: TypographyToken
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    private var sampleScale: TypeScale { TypeScale.resolve(for: token) }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.sm) {
                Text(LocalizedText.string(.today, language: localizationStore.resolvedLanguage))
                    .font(sampleScale.title)
                    .tracking(sampleScale.titleTracking)

                Text(token.displayName)
                    .font(theme.type.callout.weight(.semibold))
                Text(token.tagline)
                    .font(theme.type.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .padding(Space.md)
            .animatedSettingsCard(isSelected: isSelected, selectedTint: theme.accentColor)
        }
        .buttonStyle(SettingsCardButtonStyle())
    }
}

// MARK: - Density card

private struct DensityCard: View {
    let token: DensityToken
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.theme) private var theme

    private var lineCount: Int {
        switch token {
        case .compact: 5
        case .balanced: 4
        case .comfortable: 3
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.sm) {
                VStack(spacing: token == .comfortable ? 6 : token == .balanced ? 4 : 2) {
                    ForEach(0..<lineCount, id: \.self) { _ in
                        HStack(spacing: 4) {
                            Capsule().fill(Color.primary.opacity(0.35)).frame(width: 2, height: 10)
                            Capsule().fill(Color.primary.opacity(0.14)).frame(height: token == .comfortable ? 10 : token == .balanced ? 8 : 6)
                        }
                    }
                }
                .frame(height: 50, alignment: .top)
                .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(token.displayName)
                        .font(theme.type.callout.weight(.semibold))
                    Text(token.tagline)
                        .font(theme.type.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 114, alignment: .leading)
            .padding(Space.md)
            .animatedSettingsCard(isSelected: isSelected, selectedTint: theme.accentColor)
        }
        .buttonStyle(SettingsCardButtonStyle())
    }
}

// MARK: - Shortcuts

private struct ShortcutsSettingsTab: View {
    @Bindable var settingsStore: AppSettingsStore
    let router: AppRouter

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    @State private var quickInputDraft = ""
    @State private var showListDraft = ""
    @State private var notice: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                SettingsHeading(
                    title: localizationStore.text(.shortcutGlobal),
                    subtitle: localizationStore.text(.shortcutGlobalSubtitle)
                )

                VStack(spacing: Space.md) {
                    shortcutRow(title: localizationStore.text(.shortcutQuickInput), text: $quickInputDraft, role: .quickInput)
                    shortcutRow(title: localizationStore.text(.shortcutShowDashboard), text: $showListDraft, role: .showList)
                }

                Text(localizationStore.text(.shortcutExamples))
                    .font(theme.type.caption)
                    .foregroundStyle(.tertiary)

                if let notice {
                    noticeView(text: notice)
                }
            }
            .padding(Space.xxl)
        }
        .onAppear {
            quickInputDraft = settingsStore.shortcuts.quickInput
            showListDraft = settingsStore.shortcuts.showList
        }
    }

    private func shortcutRow(title: String, text: Binding<String>, role: ShortcutRole) -> some View {
        HStack(spacing: Space.md) {
            Text(title)
                .font(theme.type.body)
                .frame(width: 140, alignment: .leading)

            TextField(localizationStore.text(.shortcutPlaceholder), text: text)
                .textFieldStyle(.plain)
                .font(theme.type.body)
                .padding(.horizontal, Space.md)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(SurfaceColor.recessedControl)
                }
                .frame(maxWidth: 200)

            Button(localizationStore.text(.save)) {
                Task { await saveShortcut(role: role, value: text.wrappedValue) }
            }
            .buttonStyle(.bordered)

            Spacer()
        }
    }

    private func saveShortcut(role: ShortcutRole, value: String) async {
        do {
            try await settingsStore.saveShortcut(role: role, value: value, router: router)
            notice = nil
        } catch {
            notice = error.localizedDescription
        }
    }

    private func noticeView(text: String) -> some View {
        HStack(spacing: Space.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.secondary)
            Text(text)
                .font(theme.type.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Space.md)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(SurfaceColor.recessedControl)
        }
    }
}

// MARK: - Tags

private struct TagsSettingsTab: View {
    @Bindable var store: TodoStore

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore
    @State private var newTagName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Space.lg) {
            SettingsHeading(
                title: localizationStore.text(.tags),
                subtitle: localizationStore.text(.tagsSubtitle)
            )

            ScrollView {
                VStack(spacing: Space.xs) {
                    if store.availableTags.isEmpty {
                        EmptyState(
                            systemImage: "tag",
                            message: localizationStore.text(.noTagsYet)
                        )
                        .frame(height: 140)
                    } else {
                        ForEach(store.availableTags) { tag in
                            tagRow(tag: tag)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(maxHeight: .infinity)

            HStack(spacing: Space.sm) {
                TextField(localizationStore.text(.newTag), text: $newTagName)
                    .textFieldStyle(.plain)
                    .font(theme.type.body)
                    .padding(.horizontal, Space.md)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(SurfaceColor.recessedControl)
                    }

                Button(localizationStore.text(.add)) {
                    Task {
                        if await store.createTag(named: newTagName) != nil {
                            newTagName = ""
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(Space.xxl)
    }

    private func tagRow(tag: TodoTag) -> some View {
        HStack(spacing: Space.md) {
            Circle()
                .fill(tag.tint)
                .frame(width: 10, height: 10)

            Text(tag.name)
                .font(theme.type.body)

            Spacer()

            Button(localizationStore.text(.delete)) {
                Task { _ = await store.deleteTag(id: tag.id) }
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Space.md)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(SurfaceColor.recessedControl)
        }
    }
}

// MARK: - Data

private struct DataSettingsTab: View {
    @Bindable var store: TodoStore
    @Bindable var settingsStore: AppSettingsStore
    let router: AppRouter

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    @State private var notice: String?
    @State private var isBusy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Space.xxl) {
                SettingsHeading(
                    title: localizationStore.text(.backupRestore),
                    subtitle: localizationStore.text(.backupRestoreSubtitle)
                )

                HStack(spacing: Space.sm) {
                    Button(localizationStore.text(.exportJSON)) {
                        Task { await exportData() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isBusy)

                    Button(localizationStore.text(.importJSON)) {
                        Task { await importData() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isBusy)
                }

                Divider().opacity(0.5)

                SettingsHeading(
                    title: localizationStore.text(.app),
                    subtitle: localizationStore.text(.appSubtitle)
                )

                Toggle(
                    isOn: Binding(
                        get: { settingsStore.hideDockIcon },
                        set: { newValue in
                            Task {
                                try? await settingsStore.saveDockVisibility(hidden: newValue)
                            }
                        }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(localizationStore.text(.hideDockIcon))
                            .font(theme.type.body)
                        Text(localizationStore.text(.hideDockIconSubtitle))
                            .font(theme.type.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                HStack(spacing: Space.sm) {
                    Button(localizationStore.text(.openQuickAdd)) { router.showQuickAdd() }
                        .buttonStyle(.bordered)
                    Button(localizationStore.text(.openDashboard)) { router.showDashboard() }
                        .buttonStyle(.bordered)
                }

                if let notice {
                    HStack(spacing: Space.sm) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.secondary)
                        Text(notice)
                            .font(theme.type.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Space.md)
                    .background {
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(SurfaceColor.recessedControl)
                    }
                }
            }
            .padding(Space.xxl)
        }
        .scrollIndicators(.hidden)
    }

    private func exportData() async {
        isBusy = true; defer { isBusy = false }
        do {
            let url = try await DataTransferService.exportData(using: store.database)
            notice = LocalizedText.format(.exportedToFormat, language: localizationStore.resolvedLanguage, url.lastPathComponent)
        } catch is CancellationError {
            notice = nil
        } catch {
            notice = error.localizedDescription
        }
    }

    private func importData() async {
        isBusy = true; defer { isBusy = false }
        do {
            let summary = try await DataTransferService.importData(using: store.database)
            await store.reloadFromDatabase()
            notice = LocalizedText.format(
                .importedSummaryFormat,
                language: localizationStore.resolvedLanguage,
                summary.importedTodos,
                summary.importedTags
            )
        } catch is CancellationError {
            notice = nil
        } catch {
            notice = error.localizedDescription
        }
    }
}

// MARK: - Common heading

private struct SettingsHeading: View {
    let title: String
    let subtitle: String

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(theme.type.headline)
            Text(subtitle)
                .font(theme.type.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
