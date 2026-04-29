import SwiftUI

struct QuickAddPanelView: View {
    @Bindable var store: TodoStore
    let onClose: () -> Void

    @Environment(\.theme) private var theme
    @Environment(LocalizationStore.self) private var localizationStore

    @State private var draft = TodoDraft()
    @State private var showTagInput = false
    @State private var newTagName = ""
    @State private var isCapturing = false
    @State private var hasPermission = ScreenshotService.hasPermission()
    @State private var noticeText: String?
    @FocusState private var titleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Space.xl) {
                    header

                    if let noticeText {
                        notice(text: noticeText)
                    }

                    taskSection

                    scheduleSection

                    tagsSection

                    captureSection
                }
                .padding(Space.xl)
            }
            .scrollIndicators(.hidden)

            actionBar
                .padding(.horizontal, Space.xl)
                .padding(.vertical, Space.md)
                .background(.thinMaterial)
                .overlay(alignment: .top) {
                    Divider().opacity(0.5)
                }
        }
        .frame(width: 580, height: 700)
        .background {
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .fill(SurfaceColor.canvas.opacity(0.70))
                .glassSheet(in: RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.xl, style: .continuous)
                .strokeBorder(SurfaceColor.separatorSoft, lineWidth: 0.8)
        }
        .onAppear {
            hasPermission = ScreenshotService.hasPermission()
            titleFocused = true
        }
        .onExitCommand {
            onClose()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: Space.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedText.string(.newTask, language: localizationStore.resolvedLanguage))
                    .font(theme.type.title)
                    .tracking(theme.type.titleTracking)
            }

            Spacer(minLength: Space.md)

            GlassIconButton(
                systemImage: "xmark",
                help: LocalizedText.string(.close, language: localizationStore.resolvedLanguage)
            ) { onClose() }
        }
    }

    // MARK: - Sections

    private var taskSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            TextField(LocalizedText.string(.titlePlaceholder, language: localizationStore.resolvedLanguage), text: $draft.title, axis: .vertical)
                .lineLimit(1 ... 3)
                .textFieldStyle(.plain)
                .font(theme.type.headline)
                .padding(.horizontal, Space.md)
                .padding(.vertical, 11)
                .background(fieldBackground(focused: titleFocused))
                .focused($titleFocused)
                .onChange(of: draft.title) { _, newValue in
                    inferDueDate(from: newValue)
                }

            TextField(LocalizedText.string(.notesPlaceholder, language: localizationStore.resolvedLanguage), text: $draft.notes, axis: .vertical)
                .lineLimit(4 ... 8)
                .textFieldStyle(.plain)
                .font(theme.type.body)
                .padding(.horizontal, Space.md)
                .padding(.vertical, 11)
                .background(fieldBackground(focused: false))
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionLabel(text: LocalizedText.string(.schedule, language: localizationStore.resolvedLanguage))

            Toggle(LocalizedText.string(.addDeadline, language: localizationStore.resolvedLanguage), isOn: $draft.hasDueDate.animation(Motion.hover))
                .toggleStyle(.switch)
                .font(theme.type.body)

            if draft.hasDueDate {
                DatePicker(LocalizedText.string(.due, language: localizationStore.resolvedLanguage), selection: $draft.dueDate, displayedComponents: [.date])
                    .datePickerStyle(.field)
                    .font(theme.type.body)
            }

            HStack(spacing: Space.sm) {
                Text(LocalizedText.string(.priority, language: localizationStore.resolvedLanguage))
                    .font(theme.type.body)

                Spacer(minLength: Space.sm)

                Picker(LocalizedText.string(.priority, language: localizationStore.resolvedLanguage), selection: $draft.priority) {
                    ForEach(TodoPriority.allCases) { priority in
                        Text("\(priority.title) · \(priority.description)").tag(priority)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionLabel(text: LocalizedText.string(.tags, language: localizationStore.resolvedLanguage))

            if store.availableTags.isEmpty {
                Text(LocalizedText.string(.noTagsYet, language: localizationStore.resolvedLanguage))
                    .font(theme.type.caption)
                    .foregroundStyle(.tertiary)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 110), spacing: Space.sm)],
                    alignment: .leading,
                    spacing: Space.sm
                ) {
                    ForEach(store.availableTags) { tag in
                        tagChip(tag: tag)
                    }
                }
            }

            if showTagInput {
                HStack(spacing: Space.sm) {
                    TextField(LocalizedText.string(.newTag, language: localizationStore.resolvedLanguage), text: $newTagName)
                        .textFieldStyle(.plain)
                        .font(theme.type.body)
                        .padding(.horizontal, Space.md)
                        .padding(.vertical, 9)
                        .background(fieldBackground(focused: false))

                    Button(LocalizedText.string(.add, language: localizationStore.resolvedLanguage)) { createTag() }
                        .buttonStyle(.borderedProminent)
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Button(showTagInput
                ? LocalizedText.string(.cancel, language: localizationStore.resolvedLanguage)
                : LocalizedText.string(.createTagEllipsis, language: localizationStore.resolvedLanguage)) {
                withAnimation(Motion.hover) { showTagInput.toggle() }
            }
            .buttonStyle(.borderless)
            .font(theme.type.callout)
        }
    }

    private func tagChip(tag: TodoTag) -> some View {
        let isOn = draft.selectedTagIDs.contains(tag.id)
        return Button {
            if isOn { draft.selectedTagIDs.remove(tag.id) }
            else { draft.selectedTagIDs.insert(tag.id) }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(tag.tint)
                    .frame(width: 6, height: 6)
                Text(tag.name)
                    .font(theme.type.callout)
                    .foregroundStyle(isOn ? .primary : .secondary)
            }
            .padding(.horizontal, Space.md)
            .padding(.vertical, 7)
            .background {
                Capsule(style: .continuous)
                    .fill(isOn ? tag.tint.opacity(0.14) : Color.primary.opacity(0.04))
            }
            .overlay {
                if isOn {
                    Capsule(style: .continuous)
                        .strokeBorder(tag.tint.opacity(0.45), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var captureSection: some View {
        VStack(alignment: .leading, spacing: Space.md) {
            SectionLabel(text: LocalizedText.string(.reference, language: localizationStore.resolvedLanguage))

            if let screenshotPath = draft.screenshotPath {
                AsyncImage(url: URL(fileURLWithPath: screenshotPath)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                        .frame(height: 160)
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }

            if !hasPermission {
                permissionCallout
            }

            HStack(spacing: Space.sm) {
                Button(captureButtonTitle) {
                    Task { await captureScreenshotOrRequestPermission() }
                }
                .disabled(isCapturing)
                .buttonStyle(.borderedProminent)
                .opacity(isCapturing ? 0.6 : 1)

                if draft.screenshotPath != nil {
                    Button(LocalizedText.string(.remove, language: localizationStore.resolvedLanguage)) {
                        draft.screenshotPath = nil
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var permissionCallout: some View {
        HStack(alignment: .top, spacing: Space.sm) {
            Image(systemName: "lock.shield")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedText.string(.screenRecordingAccessOff, language: localizationStore.resolvedLanguage))
                    .font(theme.type.callout.weight(.semibold))

                Text(LocalizedText.format(.screenRecordingPermissionFormat, language: localizationStore.resolvedLanguage, appDisplayName))
                    .font(theme.type.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Space.md)
        .background {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(Color.orange.opacity(0.08))
        }
    }

    private func notice(text: String) -> some View {
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
                .fill(Color.primary.opacity(0.04))
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: Space.sm) {
            if draft.hasDueDate {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10.5, weight: .medium))
                    Text(LocalizedText.detailDate(draft.dueDate, language: localizationStore.resolvedLanguage))
                        .font(theme.type.caption)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(LocalizedText.string(.cancel, language: localizationStore.resolvedLanguage)) { onClose() }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)

            Button {
                Task { await saveDraft() }
            } label: {
                Label(LocalizedText.string(.saveTask, language: localizationStore.resolvedLanguage), systemImage: "return")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: Radius.sm))
            .keyboardShortcut(.defaultAction)
            .disabled(!isSaveEnabled)
            .opacity(isSaveEnabled ? 1 : 0.42)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldBackground(focused: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .fill(Color.clear)
                .glassSheet(in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .strokeBorder(
                    focused ? theme.accentColor.opacity(0.44) : SurfaceColor.separatorSoft,
                    lineWidth: focused ? 1.1 : 0.8
                )
        }
        .animation(Motion.hover, value: focused)
    }

    private var captureButtonTitle: String {
        if !hasPermission { return LocalizedText.string(.grantScreenRecording, language: localizationStore.resolvedLanguage) }
        return draft.screenshotPath == nil
            ? LocalizedText.string(.captureScreenshot, language: localizationStore.resolvedLanguage)
            : LocalizedText.string(.replaceScreenshot, language: localizationStore.resolvedLanguage)
    }

    private var isSaveEnabled: Bool {
        !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? LocalizedText.string(.appName, language: localizationStore.resolvedLanguage)
    }

    private func inferDueDate(from title: String) {
        let lowerTitle = title.lowercased()
        let today = Date()
        var targetDate: Date?

        if lowerTitle.contains("今天") {
            targetDate = today
        } else if lowerTitle.contains("明天") {
            targetDate = Calendar.current.date(byAdding: .day, value: 1, to: today)
        } else if lowerTitle.contains("后天") {
            targetDate = Calendar.current.date(byAdding: .day, value: 2, to: today)
        }

        if targetDate == nil {
            if lowerTitle.contains("today") {
                targetDate = today
            } else if lowerTitle.contains("tomorrow") {
                targetDate = Calendar.current.date(byAdding: .day, value: 1, to: today)
            } else if lowerTitle.contains("day after tomorrow") || lowerTitle.contains("overmorrow") {
                targetDate = Calendar.current.date(byAdding: .day, value: 2, to: today)
            }
        }

        let dayMap: [String: Int] = ["一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6, "日": 0, "天": 0]
        if let match = lowerTitle.range(of: #"周([一二三四五六日天])"#, options: .regularExpression) {
            let symbol = String(lowerTitle[match]).replacingOccurrences(of: "周", with: "")
            if let targetDay = dayMap[symbol] {
                let currentDay = Calendar.current.component(.weekday, from: today) - 1
                var diff = targetDay - currentDay
                if diff <= 0 { diff += 7 }
                targetDate = Calendar.current.date(byAdding: .day, value: diff, to: today)
            }
        }

        let englishDayMap: [String: Int] = [
            "monday": 1, "mon": 1,
            "tuesday": 2, "tue": 2, "tues": 2,
            "wednesday": 3, "wed": 3,
            "thursday": 4, "thu": 4, "thur": 4, "thurs": 4,
            "friday": 5, "fri": 5,
            "saturday": 6, "sat": 6,
            "sunday": 0, "sun": 0
        ]
        if
            targetDate == nil,
            let match = lowerTitle.range(of: #"\b(mon(day)?|tue(s|sday)?|wed(nesday)?|thu(r|rs|rsday)?|fri(day)?|sat(urday)?|sun(day)?)\b"#, options: .regularExpression)
        {
            let symbol = String(lowerTitle[match])
            if let targetDay = englishDayMap[symbol] {
                let currentDay = Calendar.current.component(.weekday, from: today) - 1
                var diff = targetDay - currentDay
                if diff <= 0 { diff += 7 }
                targetDate = Calendar.current.date(byAdding: .day, value: diff, to: today)
            }
        }

        if let targetDate {
            draft.hasDueDate = true
            draft.dueDate = targetDate
        }
    }

    private func createTag() {
        let pendingName = newTagName
        Task {
            if let tag = await store.createTag(named: pendingName) {
                draft.selectedTagIDs.insert(tag.id)
                newTagName = ""
                showTagInput = false
            }
        }
    }

    private func captureScreenshotOrRequestPermission() async {
        if !hasPermission {
            onClose()
            ScreenRecordingPermissionGuide.shared.present(
                appDisplayName: appDisplayName,
                language: localizationStore.resolvedLanguage,
                onPermissionGranted: {
                    hasPermission = true
                    AppRouterHolder.shared.router?.showQuickAdd(preserveDraft: true)
                }
            )
            hasPermission = ScreenshotService.hasPermission()
            return
        }

        isCapturing = true
        defer { isCapturing = false }

        do {
            onClose()
            try await Task.sleep(for: .milliseconds(180))
            draft.screenshotPath = try await ScreenshotService.captureInteractive()
            hasPermission = true
            AppRouterHolder.shared.router?.showQuickAdd(preserveDraft: true)
        } catch is CancellationError {
            AppRouterHolder.shared.router?.showQuickAdd(preserveDraft: true)
        } catch {
            noticeText = error.localizedDescription
            AppRouterHolder.shared.router?.showQuickAdd(preserveDraft: true)
        }
    }

    private func saveDraft() async {
        guard await store.createTodo(from: draft) != nil else {
            noticeText = LocalizedText.string(.failedToSaveTask, language: localizationStore.resolvedLanguage)
            return
        }

        draft = TodoDraft()
        noticeText = nil
        onClose()
    }
}
