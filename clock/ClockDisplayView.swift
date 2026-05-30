import SwiftUI

struct ClockDisplayView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { context in
            let label: String = {
                switch state.mode {
                case .clock: return Self.format(date: context.date, format: state.clockStyle.format)
                case .timer: return Self.formatTimer(seconds: state.timerRemaining)
                }
            }()
            TimeText(
                text: label,
                fontSize: state.clockStyle.fontSize,
                weight: state.clockStyle.weight.fontWeight,
                design: state.clockStyle.family.design,
                color: state.clockStyle.color,
                extraTracking: state.clockStyle.tracking,
                separator: state.clockStyle.separator
            )
            .animation(.snappy(duration: 0.18), value: label)
        }
    }

    static func format(date: Date, format: ClockFormat) -> String {
        let cal = Calendar.current
        let h = cal.component(.hour, from: date)
        let m = cal.component(.minute, from: date)
        let s = cal.component(.second, from: date)
        switch format {
        case .hm24:  return String(format: "%02d:%02d", h, m)
        case .hms24: return String(format: "%02d:%02d:%02d", h, m, s)
        case .hm12:
            let h12 = ((h % 12) == 0) ? 12 : h % 12
            return String(format: "%d:%02d", h12, m)
        case .hms12:
            let h12 = ((h % 12) == 0) ? 12 : h % 12
            return String(format: "%d:%02d:%02d", h12, m, s)
        }
    }

    static func formatTimer(seconds: Int) -> String {
        let s = max(seconds, 0)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, sec) }
        return String(format: "%02d:%02d", m, sec)
    }

    static func sampleLabel(for state: AppState) -> String {
        switch state.mode {
        case .clock: return format(date: .now, format: state.clockStyle.format)
        case .timer: return formatTimer(seconds: state.timerDurationSeconds)
        }
    }
}
