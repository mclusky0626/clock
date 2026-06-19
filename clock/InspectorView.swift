import SwiftUI

struct InspectorView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        GlassPanel(cornerRadius: 24) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if state.mode == .timer {
                        timerSection
                        alarmSection
                    }
                    if let id = state.selectedID, let idx = state.index(of: id) {
                        let item = state.items[idx]
                        switch item.kind {
                        case .clock:
                            clockSection
                            transformSection(itemID: id)
                        case .photo:
                            transformSection(itemID: id)
                            photoSection(itemID: id)
                            layerSection(id: id)
                            deleteSection
                        case .weather:
                            transformSection(itemID: id)
                            layerSection(id: id)
                            deleteSection
                        case .widget(let kind):
                            widgetSection(itemID: id, kind: kind)
                            transformSection(itemID: id)
                            layerSection(id: id)
                            deleteSection
                        case .html:
                            htmlSection(itemID: id)
                            transformSection(itemID: id)
                            photoSection(itemID: id)
                            layerSection(id: id)
                            deleteSection
                        }
                    } else {
                        clockSection
                        Text(state.t(.selectHint))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    backgroundSection
                    effectSection
                    presetSection
                    languageSection
                }
                .padding(18)
            }
        }
        .frame(width: 290)
    }

    private var header: some View {
        let title: String = {
            guard let id = state.selectedID, let idx = state.index(of: id) else {
                return state.t(.style)
            }
            switch state.items[idx].kind {
            case .clock:   return state.t(.clock)
            case .photo:   return state.t(.photo)
            case .weather: return state.t(.sticker)
            case .widget:  return state.t(.widget)
            case .html:    return "HTML"
            }
        }()
        return HStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
            Spacer()
            Button {
                state.inspectorVisible = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.6))
                    )
                    .foregroundStyle(.primary.opacity(0.8))
            }
            .buttonStyle(.plain)
            .help(state.t(.closePanel))
        }
    }

    // MARK: Timer

    private var timerSection: some View {
        @Bindable var s = state
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel(state.t(.timer))

            Picker("", selection: $s.timerStyle) {
                ForEach(TimerStyle.allCases) { st in
                    Label(timerStyleName(st), systemImage: st.symbol).tag(st)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            HStack(spacing: 6) {
                timerField(value: hoursBinding,   range: 0...99, suffix: state.t(.hourSuffix))
                Text(":").font(.system(size: 16, weight: .light)).foregroundStyle(.secondary)
                timerField(value: minutesBinding, range: 0...59, suffix: state.t(.minuteSuffix))
                Text(":").font(.system(size: 16, weight: .light)).foregroundStyle(.secondary)
                timerField(value: secondsBinding, range: 0...59, suffix: state.t(.secondSuffix))
            }
            HStack(spacing: 8) {
                Button {
                    if state.timerRunning { state.pauseTimer() } else { state.startTimer() }
                } label: {
                    Label(
                        state.timerRunning ? state.t(.pause) : state.t(.start),
                        systemImage: state.timerRunning ? "pause.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(prominent: true))

                Button {
                    state.resetTimer()
                } label: {
                    Label(state.t(.reset), systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }

            if state.timerStyle == .disk {
                row(state.t(.diskColor)) {
                    ColorPicker("", selection: $s.timerDiskColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 40)
                }
            }
            divider
        }
    }

    private func timerStyleName(_ style: TimerStyle) -> String {
        switch style {
        case .digital: return state.t(.styleDigital)
        case .disk:    return state.t(.styleDisk)
        }
    }

    // MARK: Alarm

    private var alarmSection: some View {
        @Bindable var s = state
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel(state.t(.alarmSound))

            Picker("", selection: alarmSelectionBinding()) {
                Text(state.t(.off)).tag(AlarmSelection.none)
                Divider()
                ForEach(SystemAlarm.allCases) { sound in
                    Text(sound.rawValue).tag(AlarmSelection.system(sound.rawValue))
                }
                if !state.customAlarms.isEmpty {
                    Divider()
                    ForEach(state.customAlarms) { a in
                        Text(a.name).tag(AlarmSelection.custom(a.id))
                    }
                }
            }
            .labelsHidden()

            slider(
                label: state.t(.volume),
                value: Binding(
                    get: { Double(s.alarmVolume) },
                    set: { s.alarmVolume = Float($0) }
                ),
                range: 0...1,
                step: 0.01,
                display: { String(format: "%.0f%%", $0 * 100) }
            )

            HStack {
                Button {
                    state.playAlarm()
                } label: {
                    Label(state.t(.preview), systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())

                Button {
                    state.presentCustomAlarmPicker()
                } label: {
                    Label(state.t(.addMP3), systemImage: "music.note.list")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }

            if case .custom(let id) = state.alarmChoice {
                Button(role: .destructive) {
                    state.deleteCustomAlarm(id)
                } label: {
                    Label(state.t(.deleteCustomSound), systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            divider
        }
    }

    // MARK: Clock

    private var clockSection: some View {
        @Bindable var s = state
        return VStack(alignment: .leading, spacing: 12) {
            sectionLabel(state.t(.clockStyle))
            clockPickers(s: s)
            clockSliders(s: s)
            row(state.t(.color)) {
                ColorPicker("", selection: $s.clockStyle.color, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 40)
            }
            divider
        }
    }

    @ViewBuilder
    private func clockPickers(s: AppState) -> some View {
        @Bindable var s = s
        let lang = s.language
        Group {
            row(state.t(.numeralStyle)) {
                Picker("", selection: $s.clockStyle.numeralStyle) {
                    Text(state.t(.font)).tag(NumeralStyle.font)
                    Text(state.t(.numeralSegment)).tag(NumeralStyle.segment)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            row(state.t(.format)) {
                Picker("", selection: $s.clockStyle.format) {
                    ForEach(ClockFormat.allCases) { f in Text(f.rawValue).tag(f) }
                }.labelsHidden()
            }
            row(state.t(.font)) {
                Picker("", selection: $s.clockStyle.family) {
                    ForEach(ClockFontFamily.allCases) { f in
                        Text(f.displayName).tag(f)
                    }
                }.labelsHidden()
            }
            row(state.t(.weight)) {
                Picker("", selection: $s.clockStyle.weight) {
                    ForEach(ClockWeight.allCases) { w in Text(w.displayName).tag(w) }
                }.labelsHidden()
            }
            row(state.t(.separator)) {
                Picker("", selection: $s.clockStyle.separator) {
                    ForEach(SeparatorStyle.allCases) { sep in Text(sep.display(lang)).tag(sep) }
                }.labelsHidden()
            }
            row(state.t(.material)) {
                Picker("", selection: $s.clockStyle.material) {
                    ForEach(DigitMaterial.allCases) { m in Text(m.display(lang)).tag(m) }
                }.labelsHidden()
            }
            row(state.t(.transition)) {
                Picker("", selection: $s.clockStyle.transition) {
                    ForEach(DigitAnimation.allCases) { a in Text(a.display(lang)).tag(a) }
                }.labelsHidden()
            }
        }
    }

    @ViewBuilder
    private func clockSliders(s: AppState) -> some View {
        @Bindable var s = s
        Group {
            slider(
                label: state.t(.size),
                value: $s.clockStyle.fontSize,
                range: 60...520,
                step: 1,
                display: { "\(Int($0))" }
            )
            slider(
                label: state.t(.stretchY),
                value: $s.clockStyle.stretchY,
                range: 0.6...2.4,
                step: 0.01,
                display: { String(format: "%.2fx", $0) }
            )
            slider(
                label: state.t(.tracking),
                value: $s.clockStyle.tracking,
                range: -20...40,
                step: 0.5,
                display: { String(format: "%.1f", $0) }
            )
        }
    }

    // MARK: Transform

    private func transformSection(itemID id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(state.t(.arrange))
            slider(
                label: state.t(.width),
                value: scaleXBinding(id: id),
                range: 0.05...12,
                step: 0.01,
                display: { String(format: "%.0f%%", $0 * 100) }
            )
            slider(
                label: state.t(.height),
                value: scaleYBinding(id: id),
                range: 0.05...12,
                step: 0.01,
                display: { String(format: "%.0f%%", $0 * 100) }
            )
            slider(
                label: state.t(.rotation),
                value: rotationBinding(id: id),
                range: -180...180,
                step: 1,
                display: { String(format: "%.0f°", $0) }
            )
            slider(
                label: state.t(.opacity),
                value: opacityBinding(id: id),
                range: 0...1,
                step: 0.01,
                display: { String(format: "%.0f%%", $0 * 100) }
            )
            divider
        }
    }

    // MARK: Photo

    private func photoSection(itemID id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(state.t(.photoShape))
            slider(
                label: state.t(.corner),
                value: cornerBinding(id: id),
                range: 0...200,
                step: 1,
                display: { String(format: "%.0f", $0) }
            )
            slider(
                label: state.t(.shadow),
                value: shadowBinding(id: id),
                range: 0...80,
                step: 1,
                display: { String(format: "%.0f", $0) }
            )
            divider
        }
    }

    // MARK: HTML

    private func htmlSection(itemID id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("HTML")

            Text(htmlSettings(id: id).displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(1)

            Toggle(isOn: htmlNetworkBinding(id: id)) {
                Text(widgetText(ko: "인터넷 허용", en: "Allow Internet"))
                    .font(.system(size: 13))
            }
            .toggleStyle(.switch)
            .tint(.blue)

            Button {
                state.reloadHTMLWidget(id)
            } label: {
                Label(widgetText(ko: "다시 불러오기", en: "Reload"), systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())

            divider
        }
    }

    // MARK: Widget

    private func widgetSection(itemID id: UUID, kind: WidgetKind) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(widgetText(ko: "위젯 설정", en: "Widget Settings"))

            row(widgetText(ko: "강조색", en: "Accent")) {
                ColorPicker("", selection: widgetAccentBinding(id: id), supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 40)
            }

            if kind == .timerMini {
                HStack(spacing: 6) {
                    timerField(value: widgetTimerHoursBinding(id: id), range: 0...99, suffix: state.t(.hourSuffix))
                    Text(":").font(.system(size: 16, weight: .light)).foregroundStyle(.secondary)
                    timerField(value: widgetTimerMinutesBinding(id: id), range: 0...59, suffix: state.t(.minuteSuffix))
                    Text(":").font(.system(size: 16, weight: .light)).foregroundStyle(.secondary)
                    timerField(value: widgetTimerSecondsBinding(id: id), range: 0...59, suffix: state.t(.secondSuffix))
                }

                HStack(spacing: 8) {
                    Button {
                        if widgetSettings(id: id).timerRunning {
                            state.pauseWidgetTimer(id)
                        } else {
                            state.startWidgetTimer(id)
                        }
                    } label: {
                        Label(
                            widgetSettings(id: id).timerRunning ? state.t(.pause) : state.t(.start),
                            systemImage: widgetSettings(id: id).timerRunning ? "pause.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(prominent: true))

                    Button {
                        state.resetWidgetTimer(id)
                    } label: {
                        Label(state.t(.reset), systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle())
                }
            }

            if kind == .monthCalendar {
                HStack(spacing: 8) {
                    timerField(value: calendarYearBinding(id: id), range: 1970...2100, suffix: widgetText(ko: "년", en: "Y"))
                    timerField(value: calendarMonthBinding(id: id), range: 1...12, suffix: widgetText(ko: "월", en: "M"))
                }

                Button {
                    setCalendarToCurrentMonth(id: id)
                } label: {
                    Label(widgetText(ko: "현재 달", en: "Current Month"), systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())

                Toggle(isOn: calendarEventsBinding(id: id)) {
                    Text(widgetText(ko: "Apple Calendar 일정", en: "Apple Calendar Events"))
                        .font(.system(size: 13))
                }
                .toggleStyle(.switch)
                .tint(.blue)

                if state.calendarPermissionDenied {
                    Text(widgetText(ko: "캘린더 권한이 꺼져 있습니다.", en: "Calendar access is disabled."))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            if kind == .worldClock {
                TextField(widgetText(ko: "표시 이름", en: "Display Name"), text: worldClockTitleBinding(id: id))
                    .textFieldStyle(.roundedBorder)

                row(widgetText(ko: "시간대", en: "Zone")) {
                    Picker("", selection: timeZoneBinding(id: id)) {
                        ForEach(worldClockTimeZones, id: \.identifier) { option in
                            Text(option.name).tag(option.identifier)
                        }
                    }
                    .labelsHidden()
                }
            }

            if kind == .dDay {
                TextField("D-Day", text: dDayTitleBinding(id: id))
                    .textFieldStyle(.roundedBorder)

                DatePicker(
                    widgetText(ko: "목표일", en: "Target"),
                    selection: dDayDateBinding(id: id),
                    displayedComponents: .date
                )
                .font(.system(size: 13))
            }

            if kind == .todaySchedule {
                Button {
                    state.refreshCalendarEvents(forMonthContaining: .now)
                } label: {
                    Label(widgetText(ko: "일정 새로고침", en: "Refresh Events"), systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())

                if state.calendarPermissionDenied {
                    Text(widgetText(ko: "캘린더 권한이 꺼져 있습니다.", en: "Calendar access is disabled."))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            divider
        }
    }

    // MARK: Layer

    private func layerSection(id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(state.t(.layer))
            HStack {
                Button {
                    state.placeBehindClock(id)
                } label: {
                    Label(state.t(.behindClock), systemImage: "rectangle.stack.badge.minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                Button {
                    state.placeInFrontOfClock(id)
                } label: {
                    Label(state.t(.frontClock), systemImage: "rectangle.stack.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            HStack {
                Button {
                    state.sendBackward(id)
                } label: {
                    Label(state.t(.toBack), systemImage: "square.3.layers.3d.down.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                Button {
                    state.bringForward(id)
                } label: {
                    Label(state.t(.toFront), systemImage: "square.3.layers.3d.top.filled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            divider
        }
    }

    private var deleteSection: some View {
        Button(role: .destructive) {
            state.deleteSelected()
        } label: {
            Label(state.t(.delete), systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
    }

    // MARK: Background

    private var backgroundSection: some View {
        @Bindable var s = state
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel(state.t(.bgMode))
            Picker("", selection: $s.backgroundMode) {
                ForEach(BackgroundMode.allCases) { m in
                    Label(m.display(state.language), systemImage: m.symbol).tag(m)
                }
            }
            .labelsHidden()

            if state.backgroundMode == .color {
                Toggle(isOn: $s.autoTheme) {
                    Text(state.t(.autoTheme)).font(.system(size: 13))
                }
                .toggleStyle(.switch)
                .tint(.blue)

                if !state.autoTheme {
                    row(state.t(.color)) {
                        ColorPicker("", selection: $s.backgroundColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 40)
                    }
                }
            }

            if state.backgroundMode == .translucent {
                slider(
                    label: state.t(.opacity),
                    value: $s.backgroundOpacity,
                    range: 0...1,
                    step: 0.01,
                    display: { String(format: "%.0f%%", $0 * 100) }
                )
            }
            divider
        }
    }

    // MARK: Effects

    private var effectSection: some View {
        @Bindable var s = state
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel(widgetText(ko: "효과", en: "Effects"))

            Toggle(isOn: $s.rippleSettings.enabled) {
                Text(widgetText(ko: "클릭 글래스 파동", en: "Click Ripple"))
                    .font(.system(size: 13))
            }
            .toggleStyle(.switch)
            .tint(.blue)

            if state.rippleSettings.enabled {
                slider(
                    label: widgetText(ko: "강도", en: "Power"),
                    value: $s.rippleSettings.intensity,
                    range: 0.1...1,
                    step: 0.01,
                    display: { String(format: "%.0f%%", $0 * 100) }
                )
                slider(
                    label: widgetText(ko: "반경", en: "Radius"),
                    value: $s.rippleSettings.radius,
                    range: 80...520,
                    step: 1,
                    display: { String(format: "%.0f", $0) }
                )
                slider(
                    label: widgetText(ko: "시간", en: "Time"),
                    value: $s.rippleSettings.duration,
                    range: 0.25...1.8,
                    step: 0.01,
                    display: { String(format: "%.2fs", $0) }
                )
            }
            divider
        }
    }

    // MARK: Language

    private var languageSection: some View {
        @Bindable var s = state
        return VStack(alignment: .leading, spacing: 8) {
            sectionLabel(state.t(.language))
            Picker("", selection: $s.language) {
                ForEach(AppLanguage.allCases) { l in
                    Text(l.displayName).tag(l)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    // MARK: Presets

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel(state.t(.presets))

            Button {
                state.saveCurrentAsPreset()
            } label: {
                Label(state.t(.savePreset), systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle(prominent: true))

            if state.presets.isEmpty {
                Text(state.t(.noPresets))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            } else {
                ForEach(state.presets) { preset in
                    presetRow(preset)
                }
            }
            divider
        }
    }

    private func presetRow(_ preset: Preset) -> some View {
        HStack(spacing: 10) {
            presetPreview(preset)

            TextField("", text: presetNameBinding(preset))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))

            Spacer(minLength: 2)

            Button {
                state.applyPreset(preset.id)
            } label: {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .help(state.t(.applyPreset))

            Button {
                state.deletePreset(preset.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(state.t(.delete))
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 8)
        .glassControlChip(cornerRadius: 12)
    }

    /// A tiny snapshot of the preset's look: its background with the clock-color time.
    @ViewBuilder
    private func presetPreview(_ preset: Preset) -> some View {
        let s = preset.state
        ZStack {
            Group {
                if s.backgroundMode == .color && s.autoTheme {
                    let c = TimeTheme.colors(for: Date())
                    LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
                } else if s.backgroundMode == .transparent || s.backgroundMode == .glassOutline {
                    Color.white.opacity(0.08)
                } else {
                    s.backgroundColor.color
                }
            }
            Text("12:00")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(s.clockStyle.color.color)
        }
        .frame(width: 44, height: 28)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func presetNameBinding(_ preset: Preset) -> Binding<String> {
        Binding(
            get: { state.presets.first(where: { $0.id == preset.id })?.name ?? "" },
            set: { state.renamePreset(preset.id, to: $0) }
        )
    }

    // MARK: Helpers

    private var divider: some View {
        Rectangle().fill(.white.opacity(0.1)).frame(height: 1)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.6)
    }

    private func row<V: View>(_ label: String, @ViewBuilder content: () -> V) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).frame(width: 56, alignment: .leading)
            content()
        }
    }

    private func slider(
        label: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>,
        step: CGFloat,
        display: @escaping (CGFloat) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 12))
                Spacer()
                Text(display(value.wrappedValue))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func slider(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        display: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 12))
                Spacer()
                Text(display(value.wrappedValue))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    // Item bindings — all use UUID lookup to avoid stale integer index crashes
    private func scaleXBinding(id: UUID) -> Binding<CGFloat> {
        Binding(
            get: { guard let i = state.index(of: id) else { return 1 }; return state.items[i].transform.scaleX },
            set: { guard let i = state.index(of: id) else { return }; state.items[i].transform.scaleX = $0 }
        )
    }
    private func scaleYBinding(id: UUID) -> Binding<CGFloat> {
        Binding(
            get: { guard let i = state.index(of: id) else { return 1 }; return state.items[i].transform.scaleY },
            set: { guard let i = state.index(of: id) else { return }; state.items[i].transform.scaleY = $0 }
        )
    }
    private func rotationBinding(id: UUID) -> Binding<Double> {
        Binding(
            get: { guard let i = state.index(of: id) else { return 0 }; return state.items[i].transform.rotation.degrees },
            set: { guard let i = state.index(of: id) else { return }; state.items[i].transform.rotation = .degrees($0) }
        )
    }
    private func opacityBinding(id: UUID) -> Binding<Double> {
        Binding(
            get: { guard let i = state.index(of: id) else { return 1 }; return state.items[i].transform.opacity },
            set: { guard let i = state.index(of: id) else { return }; state.items[i].transform.opacity = $0 }
        )
    }
    private func cornerBinding(id: UUID) -> Binding<CGFloat> {
        Binding(
            get: { guard let i = state.index(of: id) else { return 0 }; return state.items[i].cornerRadius },
            set: { guard let i = state.index(of: id) else { return }; state.items[i].cornerRadius = $0 }
        )
    }
    private func shadowBinding(id: UUID) -> Binding<CGFloat> {
        Binding(
            get: { guard let i = state.index(of: id) else { return 0 }; return state.items[i].shadowRadius },
            set: { guard let i = state.index(of: id) else { return }; state.items[i].shadowRadius = $0 }
        )
    }

    private func widgetText(ko: String, en: String) -> String {
        state.language == .korean ? ko : en
    }

    private func widgetSettings(id: UUID) -> WidgetSettings {
        guard let i = state.index(of: id) else { return WidgetSettings() }
        return state.items[i].widgetSettings
    }

    private func htmlSettings(id: UUID) -> HTMLWidgetSettings {
        guard let i = state.index(of: id) else { return HTMLWidgetSettings() }
        return state.items[i].htmlSettings
    }

    private func htmlNetworkBinding(id: UUID) -> Binding<Bool> {
        Binding(
            get: { htmlSettings(id: id).allowsNetwork },
            set: {
                guard let i = state.index(of: id) else { return }
                state.items[i].htmlSettings.allowsNetwork = $0
                state.items[i].htmlSettings.reloadNonce += 1
                state.scheduleSave()
            }
        )
    }

    private func widgetAccentBinding(id: UUID) -> Binding<Color> {
        Binding(
            get: { widgetSettings(id: id).accentColor },
            set: {
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.accentColor = $0
                state.scheduleSave()
            }
        )
    }

    private var worldClockTimeZones: [(identifier: String, name: String)] {
        let base: [(identifier: String, name: String)] = [
            ("Asia/Seoul", "Seoul"),
            ("Asia/Tokyo", "Tokyo"),
            ("Asia/Shanghai", "Shanghai"),
            ("Europe/London", "London"),
            ("Europe/Paris", "Paris"),
            ("America/New_York", "New York"),
            ("America/Chicago", "Chicago"),
            ("America/Denver", "Denver"),
            ("America/Los_Angeles", "Los Angeles"),
            ("UTC", "UTC")
        ]
        guard let id = state.selectedID else { return base }
        let current = widgetSettings(id: id).timeZoneIdentifier
        if base.contains(where: { $0.0 == current }) { return base }
        let name = current.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? current
        return [(current, name)] + base
    }

    private func timeZoneBinding(id: UUID) -> Binding<String> {
        Binding(
            get: { widgetSettings(id: id).timeZoneIdentifier },
            set: {
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.timeZoneIdentifier = $0
                state.scheduleSave()
            }
        )
    }

    private func worldClockTitleBinding(id: UUID) -> Binding<String> {
        Binding(
            get: { widgetSettings(id: id).worldClockTitle },
            set: {
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.worldClockTitle = $0
                state.scheduleSave()
            }
        )
    }

    private func dDayTitleBinding(id: UUID) -> Binding<String> {
        Binding(
            get: { widgetSettings(id: id).dDayTitle },
            set: {
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.dDayTitle = $0
                state.scheduleSave()
            }
        )
    }

    private func dDayDateBinding(id: UUID) -> Binding<Date> {
        Binding(
            get: { widgetSettings(id: id).dDayDate },
            set: {
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.dDayDate = $0
                state.scheduleSave()
            }
        )
    }

    private func widgetTimerHoursBinding(id: UUID) -> Binding<Int> {
        Binding(
            get: { widgetSettings(id: id).timerDurationSeconds / 3600 },
            set: { newH in
                let s = widgetSettings(id: id)
                applyWidgetTimer(id: id, h: newH, m: (s.timerDurationSeconds % 3600) / 60, s: s.timerDurationSeconds % 60)
            }
        )
    }

    private func widgetTimerMinutesBinding(id: UUID) -> Binding<Int> {
        Binding(
            get: { (widgetSettings(id: id).timerDurationSeconds % 3600) / 60 },
            set: { newM in
                let s = widgetSettings(id: id)
                applyWidgetTimer(id: id, h: s.timerDurationSeconds / 3600, m: newM, s: s.timerDurationSeconds % 60)
            }
        )
    }

    private func widgetTimerSecondsBinding(id: UUID) -> Binding<Int> {
        Binding(
            get: { widgetSettings(id: id).timerDurationSeconds % 60 },
            set: { newS in
                let s = widgetSettings(id: id)
                applyWidgetTimer(id: id, h: s.timerDurationSeconds / 3600, m: (s.timerDurationSeconds % 3600) / 60, s: newS)
            }
        )
    }

    private func applyWidgetTimer(id: UUID, h: Int, m: Int, s: Int) {
        guard let i = state.index(of: id) else { return }
        let total = max(1, h * 3600 + m * 60 + s)
        state.items[i].widgetSettings.timerDurationSeconds = total
        if !state.items[i].widgetSettings.timerRunning {
            state.items[i].widgetSettings.timerRemaining = total
        }
        state.scheduleSave()
    }

    private func calendarYearBinding(id: UUID) -> Binding<Int> {
        Binding(
            get: {
                let date = calendarDisplayDate(id: id)
                return Calendar.current.component(.year, from: date)
            },
            set: { year in
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.calendarYear = year
                if state.items[i].widgetSettings.calendarMonth == nil {
                    state.items[i].widgetSettings.calendarMonth = Calendar.current.component(.month, from: .now)
                }
                state.scheduleSave()
                if state.items[i].widgetSettings.showsCalendarEvents {
                    state.refreshCalendarEvents(forMonthContaining: calendarDisplayDate(id: id))
                }
            }
        )
    }

    private func calendarMonthBinding(id: UUID) -> Binding<Int> {
        Binding(
            get: {
                let date = calendarDisplayDate(id: id)
                return Calendar.current.component(.month, from: date)
            },
            set: { month in
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.calendarMonth = month
                if state.items[i].widgetSettings.calendarYear == nil {
                    state.items[i].widgetSettings.calendarYear = Calendar.current.component(.year, from: .now)
                }
                state.scheduleSave()
                if state.items[i].widgetSettings.showsCalendarEvents {
                    state.refreshCalendarEvents(forMonthContaining: calendarDisplayDate(id: id))
                }
            }
        )
    }

    private func calendarEventsBinding(id: UUID) -> Binding<Bool> {
        Binding(
            get: { widgetSettings(id: id).showsCalendarEvents },
            set: { enabled in
                guard let i = state.index(of: id) else { return }
                state.items[i].widgetSettings.showsCalendarEvents = enabled
                state.scheduleSave()
                if enabled { state.refreshCalendarEvents(forMonthContaining: calendarDisplayDate(id: id)) }
            }
        )
    }

    private func setCalendarToCurrentMonth(id: UUID) {
        guard let i = state.index(of: id) else { return }
        state.items[i].widgetSettings.calendarYear = nil
        state.items[i].widgetSettings.calendarMonth = nil
        state.scheduleSave()
        if state.items[i].widgetSettings.showsCalendarEvents {
            state.refreshCalendarEvents(forMonthContaining: .now)
        }
    }

    private func calendarDisplayDate(id: UUID) -> Date {
        let settings = widgetSettings(id: id)
        let cal = Calendar.current
        if let year = settings.calendarYear, let month = settings.calendarMonth,
           let date = cal.date(from: DateComponents(year: year, month: month, day: 1)) {
            return date
        }
        return .now
    }

    // Timer H/M/S fields
    private func timerField(value: Binding<Int>, range: ClosedRange<Int>, suffix: String) -> some View {
        VStack(spacing: 2) {
            TextField("", value: clampedBinding(value, range: range), format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .frame(width: 54, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6)
                        )
                )
            Text(suffix).font(.system(size: 9, weight: .medium)).foregroundStyle(.secondary)
        }
    }

    private func clampedBinding(_ source: Binding<Int>, range: ClosedRange<Int>) -> Binding<Int> {
        Binding(
            get: { source.wrappedValue },
            set: { source.wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
        )
    }

    private var hoursBinding: Binding<Int> {
        Binding(
            get: { state.timerDurationSeconds / 3600 },
            set: { newH in
                let h = newH
                let total = state.timerDurationSeconds
                let m = (total % 3600) / 60
                let s = total % 60
                applyTimer(h: h, m: m, s: s)
            }
        )
    }
    private var minutesBinding: Binding<Int> {
        Binding(
            get: { (state.timerDurationSeconds % 3600) / 60 },
            set: { newM in
                let total = state.timerDurationSeconds
                let h = total / 3600
                let s = total % 60
                applyTimer(h: h, m: newM, s: s)
            }
        )
    }
    private var secondsBinding: Binding<Int> {
        Binding(
            get: { state.timerDurationSeconds % 60 },
            set: { newS in
                let total = state.timerDurationSeconds
                let h = total / 3600
                let m = (total % 3600) / 60
                applyTimer(h: h, m: m, s: newS)
            }
        )
    }

    private func applyTimer(h: Int, m: Int, s: Int) {
        let total = max(1, h * 3600 + m * 60 + s)
        state.timerDurationSeconds = total
        if !state.timerRunning {
            state.timerRemaining = total
        }
    }

    // Alarm selection tag wrapper (Picker needs Hashable tags)
    private enum AlarmSelection: Hashable {
        case none
        case system(String)
        case custom(UUID)
    }

    private func alarmSelectionBinding() -> Binding<AlarmSelection> {
        Binding(
            get: {
                switch state.alarmChoice {
                case .none: return .none
                case .system(let name): return .system(name)
                case .custom(let id): return .custom(id)
                }
            },
            set: { sel in
                switch sel {
                case .none: state.alarmChoice = .none
                case .system(let n): state.alarmChoice = .system(n)
                case .custom(let id): state.alarmChoice = .custom(id)
                }
            }
        )
    }
}
