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
                        }
                    } else {
                        clockSection
                        Text("캔버스의 사진이나 시계를 선택하면\n속성을 편집할 수 있습니다.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 290)
    }

    private var header: some View {
        let title: String = {
            guard let id = state.selectedID, let idx = state.index(of: id) else {
                return "스타일"
            }
            switch state.items[idx].kind {
            case .clock: return "시계"
            case .photo: return "사진"
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
            .help("패널 닫기")
        }
    }

    // MARK: Timer

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("타이머")
            HStack(spacing: 6) {
                timerField(value: hoursBinding,   range: 0...99, suffix: "시")
                Text(":").font(.system(size: 16, weight: .light)).foregroundStyle(.secondary)
                timerField(value: minutesBinding, range: 0...59, suffix: "분")
                Text(":").font(.system(size: 16, weight: .light)).foregroundStyle(.secondary)
                timerField(value: secondsBinding, range: 0...59, suffix: "초")
            }
            HStack(spacing: 8) {
                Button {
                    if state.timerRunning { state.pauseTimer() } else { state.startTimer() }
                } label: {
                    Label(
                        state.timerRunning ? "일시정지" : "시작",
                        systemImage: state.timerRunning ? "pause.fill" : "play.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle(prominent: true))

                Button {
                    state.resetTimer()
                } label: {
                    Label("리셋", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            divider
        }
    }

    // MARK: Alarm

    private var alarmSection: some View {
        @Bindable var s = state
        return VStack(alignment: .leading, spacing: 10) {
            sectionLabel("알람 사운드")

            Picker("", selection: alarmSelectionBinding()) {
                Text("끄기").tag(AlarmSelection.none)
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
                label: "볼륨",
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
                    Label("미리듣기", systemImage: "play.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())

                Button {
                    state.presentCustomAlarmPicker()
                } label: {
                    Label("MP3 추가", systemImage: "music.note.list")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }

            if case .custom(let id) = state.alarmChoice {
                Button(role: .destructive) {
                    state.deleteCustomAlarm(id)
                } label: {
                    Label("선택된 사용자 사운드 삭제", systemImage: "trash")
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
            sectionLabel("시계 스타일")
            clockPickers(s: s)
            clockSliders(s: s)
            row("색상") {
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
        Group {
            row("형식") {
                Picker("", selection: $s.clockStyle.format) {
                    ForEach(ClockFormat.allCases) { f in Text(f.rawValue).tag(f) }
                }.labelsHidden()
            }
            row("폰트") {
                Picker("", selection: $s.clockStyle.family) {
                    ForEach(ClockFontFamily.allCases) { f in
                        Text(f.displayName).tag(f)
                    }
                }.labelsHidden()
            }
            row("두께") {
                Picker("", selection: $s.clockStyle.weight) {
                    ForEach(ClockWeight.allCases) { w in Text(w.displayName).tag(w) }
                }.labelsHidden()
            }
            row("분리자") {
                Picker("", selection: $s.clockStyle.separator) {
                    ForEach(SeparatorStyle.allCases) { sep in Text(sep.displayName).tag(sep) }
                }.labelsHidden()
            }
            row("재질") {
                Picker("", selection: $s.clockStyle.material) {
                    ForEach(DigitMaterial.allCases) { m in Text(m.rawValue).tag(m) }
                }.labelsHidden()
            }
            row("전환") {
                Picker("", selection: $s.clockStyle.transition) {
                    ForEach(DigitAnimation.allCases) { a in Text(a.rawValue).tag(a) }
                }.labelsHidden()
            }
        }
    }

    @ViewBuilder
    private func clockSliders(s: AppState) -> some View {
        @Bindable var s = s
        Group {
            slider(
                label: "크기",
                value: $s.clockStyle.fontSize,
                range: 60...520,
                step: 1,
                display: { "\(Int($0))" }
            )
            slider(
                label: "세로 늘이기",
                value: $s.clockStyle.stretchY,
                range: 0.6...2.4,
                step: 0.01,
                display: { String(format: "%.2fx", $0) }
            )
            slider(
                label: "자간",
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
            sectionLabel("배치")
            slider(
                label: "가로 크기",
                value: scaleXBinding(id: id),
                range: 0.05...12,
                step: 0.01,
                display: { String(format: "%.0f%%", $0 * 100) }
            )
            slider(
                label: "세로 크기",
                value: scaleYBinding(id: id),
                range: 0.05...12,
                step: 0.01,
                display: { String(format: "%.0f%%", $0 * 100) }
            )
            slider(
                label: "회전",
                value: rotationBinding(id: id),
                range: -180...180,
                step: 1,
                display: { String(format: "%.0f°", $0) }
            )
            slider(
                label: "불투명도",
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
            sectionLabel("사진 모양")
            slider(
                label: "모서리",
                value: cornerBinding(id: id),
                range: 0...200,
                step: 1,
                display: { String(format: "%.0f", $0) }
            )
            slider(
                label: "그림자",
                value: shadowBinding(id: id),
                range: 0...80,
                step: 1,
                display: { String(format: "%.0f", $0) }
            )
            divider
        }
    }

    // MARK: Layer

    private func layerSection(id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("레이어")
            HStack {
                Button {
                    state.placeBehindClock(id)
                } label: {
                    Label("시계 뒤", systemImage: "rectangle.stack.badge.minus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                Button {
                    state.placeInFrontOfClock(id)
                } label: {
                    Label("시계 앞", systemImage: "rectangle.stack.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
            }
            HStack {
                Button {
                    state.sendBackward(id)
                } label: {
                    Label("맨 뒤", systemImage: "square.3.layers.3d.down.left")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                Button {
                    state.bringForward(id)
                } label: {
                    Label("맨 앞", systemImage: "square.3.layers.3d.top.filled")
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
            Label("삭제", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(GlassButtonStyle())
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
