import SwiftUI

// MARK: - Entry point

/// Renders a floating "glass widget" for the given kind. Each widget sits inside a
/// native Liquid Glass card so it reads as a translucent pane drifting above the
/// wallpaper, regardless of the canvas background mode.
struct WidgetView: View {
    let kind: WidgetKind
    let itemID: UUID

    var body: some View {
        switch kind {
        case .dateDay: DateWidgetView(itemID: itemID)
        case .monthCalendar: MonthCalendarWidgetView(itemID: itemID)
        case .timerMini: TimerMiniWidgetView(itemID: itemID)
        case .dayProgress: DayProgressWidgetView(itemID: itemID)
        case .weekStrip: WeekStripWidgetView(itemID: itemID)
        case .worldClock: WorldClockWidgetView(itemID: itemID)
        case .dDay: DDayWidgetView(itemID: itemID)
        case .systemMonitor: SystemMonitorWidgetView(itemID: itemID)
        case .todaySchedule: TodayScheduleWidgetView(itemID: itemID)
        case .nowPlayingMini: NowPlayingMiniWidgetView(itemID: itemID)
        case .nowPlayingCompact: NowPlayingCompactWidgetView(itemID: itemID)
        case .nowPlayingCover: NowPlayingCoverWidgetView(itemID: itemID)
        }
    }
}

// MARK: - Date · Day

/// A minimal date card: the weekday on top, the full date beneath. Localized to the
/// app language and refreshed every minute so it always shows the correct day.
struct DateWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.18

            TimelineView(.everyMinute) { context in
                VStack(spacing: max(2, h * 0.03)) {
                    Text(weekdayString(context.date))
                        .font(.system(size: h * 0.30, weight: .semibold, design: .rounded))
                        .foregroundStyle(settings.accentColor)

                    Text(dateString(context.date))
                        .font(.system(size: h * 0.135, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.22), radius: h * 0.012, y: h * 0.006)
                .padding(.horizontal, h * 0.14)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    // MARK: Formatting

    private var locale: Locale {
        Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .dateDay) }
        return state.items[idx].widgetSettings
    }

    private func weekdayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("EEEE")
        return f.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        if state.language == .korean {
            f.dateFormat = "yyyy년 M월 d일"
        } else {
            f.dateStyle = .long
            f.timeStyle = .none
        }
        return f.string(from: date)
    }
}

// MARK: - Month Calendar

struct MonthCalendarWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.12

            TimelineView(.everyMinute) { context in
                let targetDate = displayDate(fallback: context.date)
                let days = monthGrid(for: targetDate)
                VStack(alignment: .leading, spacing: h * 0.045) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(monthTitle(targetDate))
                            .font(.system(size: h * 0.085, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(yearTitle(targetDate))
                            .font(.system(size: h * 0.055, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    HStack(spacing: 0) {
                        ForEach(weekdaySymbols(), id: \.self) { symbol in
                            Text(symbol)
                                .font(.system(size: h * 0.043, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.48))
                                .frame(maxWidth: .infinity)
                        }
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: h * 0.016) {
                        ForEach(days.indices, id: \.self) { i in
                            if let day = days[i] {
                                let isToday = isSameDay(day.date, context.date)
                                VStack(spacing: h * 0.003) {
                                    Text("\(day.number)")
                                        .font(.system(size: h * 0.052, weight: isToday ? .semibold : .medium, design: .rounded))
                                        .foregroundStyle(isToday ? .black : .white.opacity(0.82))
                                        .monospacedDigit()
                                    if showsEvents, !state.calendarEvents(on: day.date).isEmpty {
                                        Circle()
                                            .fill(isToday ? Color.black.opacity(0.45) : settings.accentColor.opacity(0.9))
                                            .frame(width: h * 0.014, height: h * 0.014)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: h * 0.075)
                                .background {
                                    if isToday {
                                        Circle().fill(Color.white.opacity(0.95))
                                    }
                                }
                                .overlay(alignment: .bottom) {
                                    if showsEvents, let first = state.calendarEvents(on: day.date).first, geo.size.height > 260 {
                                        Text(first.title)
                                            .font(.system(size: h * 0.021, weight: .medium, design: .rounded))
                                            .foregroundStyle(isToday ? .black.opacity(0.55) : .white.opacity(0.42))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.45)
                                            .offset(y: h * 0.021)
                                        }
                                    }
                            } else {
                                Color.clear.frame(height: h * 0.075)
                            }
                        }
                    }
                }
                .padding(.horizontal, h * 0.08)
                .padding(.vertical, h * 0.07)
                .frame(width: geo.size.width, height: geo.size.height)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: h * 0.01, y: h * 0.005)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .onAppear {
                if showsEvents { state.refreshCalendarEvents(forMonthContaining: displayDate(fallback: .now)) }
            }
            .onChange(of: settings.calendarYear) { _, _ in
                if showsEvents { state.refreshCalendarEvents(forMonthContaining: displayDate(fallback: .now)) }
            }
            .onChange(of: settings.calendarMonth) { _, _ in
                if showsEvents { state.refreshCalendarEvents(forMonthContaining: displayDate(fallback: .now)) }
            }
            .onChange(of: settings.showsCalendarEvents) { _, enabled in
                if enabled { state.refreshCalendarEvents(forMonthContaining: displayDate(fallback: .now)) }
            }
        }
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .monthCalendar) }
        return state.items[idx].widgetSettings
    }

    private var showsEvents: Bool { settings.showsCalendarEvents }

    private func displayDate(fallback: Date) -> Date {
        let s = settings
        let cal = Calendar.current
        if let year = s.calendarYear, let month = s.calendarMonth {
            return cal.date(from: DateComponents(year: year, month: month, day: 1)) ?? fallback
        }
        return fallback
    }

    private struct DayCell {
        var number: Int
        var date: Date
    }

    private var locale: Locale {
        Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
    }

    private func monthTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("MMMM")
        return f.string(from: date)
    }

    private func yearTitle(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("yyyy")
        return f.string(from: date)
    }

    private func weekdaySymbols() -> [String] {
        let symbols = Calendar.current.shortWeekdaySymbols
        let rotated = Array(symbols[1...]) + [symbols[0]]
        if state.language == .korean {
            return ["월", "화", "수", "목", "금", "토", "일"]
        }
        return rotated.map { String($0.prefix(1)).uppercased() }
    }

    private func monthGrid(for date: Date) -> [DayCell?] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let interval = cal.dateInterval(of: .month, for: date),
              let range = cal.range(of: .day, in: .month, for: date) else {
            return Array(repeating: nil, count: 42)
        }

        let firstWeekday = cal.component(.weekday, from: interval.start)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        var cells: [DayCell?] = Array(repeating: nil, count: leading)
        for day in range {
            if let cellDate = cal.date(byAdding: .day, value: day - 1, to: interval.start) {
                cells.append(DayCell(number: day, date: cellDate))
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }
}

// MARK: - Timer Mini

struct TimerMiniWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.18

            TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                HStack(spacing: h * 0.11) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: max(4, h * 0.055))
                        Circle()
                            .trim(from: 0, to: timerProgress)
                            .stroke(
                                settings.accentColor,
                                style: StrokeStyle(lineWidth: max(4, h * 0.055), lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: timerProgress)
                        Image(systemName: settings.timerRunning ? "pause.fill" : "timer")
                            .font(.system(size: h * 0.13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .frame(width: h * 0.46, height: h * 0.46)

                    VStack(alignment: .leading, spacing: h * 0.025) {
                        Text(state.language == .korean ? "타이머" : "Timer")
                            .font(.system(size: h * 0.082, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.62))
                        Text(ClockDisplayView.formatTimer(seconds: settings.timerRemaining))
                            .font(.system(size: h * 0.19, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, h * 0.14)
                .frame(width: geo.size.width, height: geo.size.height)
                .shadow(color: .black.opacity(0.22), radius: h * 0.012, y: h * 0.006)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .timerMini) }
        return state.items[idx].widgetSettings
    }

    private var timerProgress: CGFloat {
        guard settings.timerDurationSeconds > 0 else { return 0 }
        return CGFloat(min(max(Double(settings.timerRemaining) / Double(settings.timerDurationSeconds), 0), 1))
    }
}

// MARK: - Day Progress

struct DayProgressWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.22

            TimelineView(.periodic(from: .now, by: 30)) { context in
                VStack(alignment: .leading, spacing: h * 0.095) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(state.language == .korean ? "하루" : "Today")
                            .font(.system(size: h * 0.15, weight: .semibold, design: .rounded))
                        Spacer()
                        Text(timeString(context.date))
                            .font(.system(size: h * 0.12, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.68))
                            .monospacedDigit()
                    }

                    GeometryReader { barGeo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.16))
                            Capsule()
                                .fill(settings.accentColor.opacity(0.9))
                                .frame(width: barGeo.size.width * dayProgress(context.date))
                            Circle()
                                .fill(settings.accentColor)
                                .frame(width: h * 0.1, height: h * 0.1)
                                .shadow(color: .black.opacity(0.18), radius: h * 0.025, y: h * 0.01)
                                .offset(x: max(0, barGeo.size.width * dayProgress(context.date) - h * 0.05))
                        }
                    }
                    .frame(height: max(6, h * 0.055))

                    HStack {
                        Text("00:00")
                        Spacer()
                        Text("24:00")
                    }
                    .font(.system(size: h * 0.072, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.46))
                    .monospacedDigit()
                }
                .padding(.horizontal, h * 0.14)
                .padding(.vertical, h * 0.13)
                .frame(width: geo.size.width, height: geo.size.height)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: h * 0.012, y: h * 0.006)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    private func dayProgress(_ date: Date) -> CGFloat {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute, .second], from: date)
        let seconds = Double((comps.hour ?? 0) * 3600 + (comps.minute ?? 0) * 60 + (comps.second ?? 0))
        return CGFloat(min(max(seconds / 86400, 0), 1))
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .dayProgress) }
        return state.items[idx].widgetSettings
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Week Strip

struct WeekStripWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.22

            TimelineView(.everyMinute) { context in
                HStack(spacing: max(4, h * 0.025)) {
                    ForEach(weekDays(containing: context.date), id: \.date) { day in
                        let isToday = Calendar.current.isDate(day.date, inSameDayAs: context.date)
                        VStack(spacing: h * 0.045) {
                            Text(day.symbol)
                                .font(.system(size: h * 0.105, weight: .semibold, design: .rounded))
                                .foregroundStyle(isToday ? .black : .white.opacity(0.48))
                            Text("\(day.number)")
                                .font(.system(size: h * 0.16, weight: .semibold, design: .rounded))
                                .foregroundStyle(isToday ? .black : .white.opacity(0.86))
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: h * 0.58)
                        .background {
                            if isToday {
                                RoundedRectangle(cornerRadius: h * 0.14, style: .continuous)
                                    .fill(settings.accentColor.opacity(0.95))
                            }
                        }
                    }
                }
                .padding(.horizontal, h * 0.11)
                .frame(width: geo.size.width, height: geo.size.height)
                .shadow(color: .black.opacity(0.2), radius: h * 0.012, y: h * 0.006)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    private struct WeekDay {
        var date: Date
        var symbol: String
        var number: Int
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .weekStrip) }
        return state.items[idx].widgetSettings
    }

    private func weekDays(containing date: Date) -> [WeekDay] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        let weekday = cal.component(.weekday, from: date)
        let offset = (weekday - cal.firstWeekday + 7) % 7
        let start = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: date)) ?? date
        let koSymbols = ["월", "화", "수", "목", "금", "토", "일"]
        let enSymbols = ["M", "T", "W", "T", "F", "S", "S"]

        return (0..<7).compactMap { index in
            guard let d = cal.date(byAdding: .day, value: index, to: start) else { return nil }
            return WeekDay(
                date: d,
                symbol: state.language == .korean ? koSymbols[index] : enSymbols[index],
                number: cal.component(.day, from: d)
            )
        }
    }
}

// MARK: - World Clock

struct WorldClockWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.18
            let timeZone = TimeZone(identifier: settings.timeZoneIdentifier) ?? .current

            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: h * 0.055) {
                    HStack {
                        Text(title(for: timeZone))
                            .font(.system(size: h * 0.105, weight: .semibold, design: .rounded))
                            .foregroundStyle(settings.accentColor)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "globe")
                            .font(.system(size: h * 0.105, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Text(timeString(context.date, timeZone: timeZone))
                        .font(.system(size: h * 0.255, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)

                    Text(dateString(context.date, timeZone: timeZone))
                        .font(.system(size: h * 0.075, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                }
                .padding(.horizontal, h * 0.14)
                .frame(width: geo.size.width, height: geo.size.height)
                .shadow(color: .black.opacity(0.22), radius: h * 0.012, y: h * 0.006)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .worldClock) }
        return state.items[idx].widgetSettings
    }

    private func title(for timeZone: TimeZone) -> String {
        if !settings.worldClockTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return settings.worldClockTitle
        }
        return timeZone.identifier.split(separator: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timeZone.identifier
    }

    private func timeString(_ date: Date, timeZone: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
        f.timeZone = timeZone
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }

    private func dateString(_ date: Date, timeZone: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
        f.timeZone = timeZone
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

// MARK: - D-Day

struct DDayWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.18

            TimelineView(.everyMinute) { context in
                VStack(alignment: .leading, spacing: h * 0.06) {
                    HStack {
                        Text(settings.dDayTitle.isEmpty ? "D-Day" : settings.dDayTitle)
                            .font(.system(size: h * 0.105, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "flag.checkered")
                            .font(.system(size: h * 0.105, weight: .semibold))
                            .foregroundStyle(settings.accentColor.opacity(0.8))
                    }

                    Text(dDayText(from: context.date))
                        .font(.system(size: h * 0.31, weight: .bold, design: .rounded))
                        .foregroundStyle(settings.accentColor)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.45)

                    Text(targetDateString())
                        .font(.system(size: h * 0.075, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                }
                .padding(.horizontal, h * 0.14)
                .frame(width: geo.size.width, height: geo.size.height)
                .shadow(color: .black.opacity(0.22), radius: h * 0.012, y: h * 0.006)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .dDay) }
        return state.items[idx].widgetSettings
    }

    private func dDayText(from date: Date) -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)
        let target = cal.startOfDay(for: settings.dDayDate)
        let days = cal.dateComponents([.day], from: today, to: target).day ?? 0
        if days == 0 { return "D-Day" }
        return days > 0 ? "D-\(days)" : "D+\(-days)"
    }

    private func targetDateString() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: settings.dDayDate)
    }
}

// MARK: - System Monitor

struct SystemMonitorWidgetView: View {
    @Environment(AppState.self) private var state
    @StateObject private var monitor = SystemMonitorModel()
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.11
            let snapshot = monitor.snapshot

            VStack(alignment: .leading, spacing: h * 0.045) {
                HStack {
                    Text(state.language == .korean ? "시스템" : "System")
                        .font(.system(size: h * 0.075, weight: .semibold, design: .rounded))
                        .foregroundStyle(settings.accentColor)
                    Spacer()
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: h * 0.07, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.52))
                }

                monitorRow(symbol: "cpu", label: "CPU", value: snapshot.cpuText, height: h)
                monitorRow(symbol: "memorychip", label: state.language == .korean ? "메모리" : "Memory", value: snapshot.memoryText, height: h)
                monitorRow(symbol: "battery.75percent", label: state.language == .korean ? "배터리" : "Battery", value: snapshot.batteryText, height: h)
                monitorRow(symbol: "arrow.up.arrow.down", label: state.language == .korean ? "네트워크" : "Network", value: snapshot.networkText, height: h)
            }
            .padding(.horizontal, h * 0.085)
            .padding(.vertical, h * 0.07)
            .frame(width: geo.size.width, height: geo.size.height)
            .shadow(color: .black.opacity(0.22), radius: h * 0.01, y: h * 0.005)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .onAppear { monitor.start() }
            .onDisappear { monitor.stop() }
        }
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .systemMonitor) }
        return state.items[idx].widgetSettings
    }

    private func monitorRow(symbol: String, label: String, value: String, height: CGFloat) -> some View {
        HStack(spacing: height * 0.035) {
            Image(systemName: symbol)
                .font(.system(size: height * 0.055, weight: .semibold))
                .frame(width: height * 0.085)
                .foregroundStyle(settings.accentColor.opacity(0.9))
            Text(label)
                .font(.system(size: height * 0.055, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.62))
            Spacer()
            Text(value)
                .font(.system(size: height * 0.058, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
    }
}

// MARK: - Today Schedule

struct TodayScheduleWidgetView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.11

            TimelineView(.everyMinute) { context in
                let events = state.calendarEvents(on: context.date)
                let maxItems = max(1, Int((geo.size.height - h * 0.26) / max(24, h * 0.14)))
                VStack(alignment: .leading, spacing: h * 0.045) {
                    HStack {
                        Text(state.language == .korean ? "오늘 일정" : "Today")
                            .font(.system(size: h * 0.075, weight: .semibold, design: .rounded))
                            .foregroundStyle(settings.accentColor)
                        Spacer()
                        Text(shortDate(context.date))
                            .font(.system(size: h * 0.052, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.52))
                    }

                    if state.calendarPermissionDenied {
                        emptyState(
                            icon: "lock",
                            text: state.language == .korean ? "캘린더 권한이 필요합니다" : "Calendar access needed",
                            height: h
                        )
                    } else if events.isEmpty {
                        emptyState(
                            icon: "checkmark.circle",
                            text: state.language == .korean ? "오늘 일정 없음" : "No events today",
                            height: h
                        )
                    } else {
                        VStack(alignment: .leading, spacing: h * 0.035) {
                            ForEach(events.prefix(maxItems)) { event in
                                eventRow(event, height: h)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, h * 0.085)
                .padding(.vertical, h * 0.07)
                .frame(width: geo.size.width, height: geo.size.height)
                .shadow(color: .black.opacity(0.22), radius: h * 0.01, y: h * 0.005)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
            .onAppear { state.refreshCalendarEvents(forMonthContaining: .now) }
        }
    }

    private var settings: WidgetSettings {
        guard let idx = state.index(of: itemID) else { return WidgetSettings.defaults(for: .todaySchedule) }
        return state.items[idx].widgetSettings
    }

    private func eventRow(_ event: CalendarEventSummary, height: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: height * 0.035) {
            Text(event.isAllDay ? (state.language == .korean ? "종일" : "All") : timeString(event.startDate))
                .font(.system(size: height * 0.048, weight: .semibold, design: .monospaced))
                .foregroundStyle(settings.accentColor.opacity(0.95))
                .frame(width: height * 0.18, alignment: .leading)
            Text(event.title.isEmpty ? (state.language == .korean ? "제목 없음" : "Untitled") : event.title)
                .font(.system(size: height * 0.055, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func emptyState(icon: String, text: String, height: CGFloat) -> some View {
        HStack(spacing: height * 0.04) {
            Image(systemName: icon)
                .font(.system(size: height * 0.075, weight: .semibold))
            Text(text)
                .font(.system(size: height * 0.06, weight: .medium, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .foregroundStyle(.white.opacity(0.55))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Now Playing

struct NowPlayingMiniWidgetView: View {
    @Environment(AppState.self) private var state
    @ObservedObject private var service = NowPlayingService.shared
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let snapshot = service.snapshot

            HStack(spacing: h * 0.13) {
                NowPlayingArtwork(snapshot: snapshot, cornerRadius: h * 0.18)
                    .frame(width: h * 0.62, height: h * 0.62)

                VStack(alignment: .leading, spacing: h * 0.035) {
                    Text(title(snapshot))
                        .font(.system(size: h * 0.17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(snapshot.hasContent ? 0.94 : 0.58))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                    Text(subtitle(snapshot))
                        .font(.system(size: h * 0.115, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                Spacer(minLength: 0)

                Image(systemName: snapshot.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: h * 0.14, weight: .semibold))
                    .foregroundStyle(.white.opacity(snapshot.hasContent ? 0.7 : 0.32))
                    .frame(width: h * 0.34, height: h * 0.34)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, h * 0.17)
            .frame(width: geo.size.width, height: geo.size.height)
            .nowPlayingGlass(snapshot: snapshot, cornerRadius: h * 0.22)
            .onAppear { service.start() }
        }
    }

    private func title(_ snapshot: NowPlayingSnapshot) -> String {
        snapshot.hasContent ? (snapshot.title.isEmpty ? "Now Playing" : snapshot.title) : (state.language == .korean ? "재생 중 없음" : "Not Playing")
    }

    private func subtitle(_ snapshot: NowPlayingSnapshot) -> String {
        if !snapshot.artist.isEmpty { return snapshot.artist }
        if snapshot.hasContent { return snapshot.album }
        return state.language == .korean ? "YouTube Music" : "YouTube Music"
    }
}

struct NowPlayingCompactWidgetView: View {
    @Environment(AppState.self) private var state
    @ObservedObject private var service = NowPlayingService.shared
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let snapshot = service.snapshot

            HStack(spacing: h * 0.12) {
                NowPlayingArtwork(snapshot: snapshot, cornerRadius: h * 0.105)
                    .frame(width: h * 0.68, height: h * 0.68)

                VStack(alignment: .leading, spacing: h * 0.045) {
                    HStack(spacing: h * 0.035) {
                        Image(systemName: snapshot.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: h * 0.07, weight: .bold))
                            .foregroundStyle(.white.opacity(snapshot.hasContent ? 0.7 : 0.34))
                        Text(snapshot.hasContent ? "Now Playing" : (state.language == .korean ? "재생 중 없음" : "Not Playing"))
                            .font(.system(size: h * 0.06, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.46))
                            .lineLimit(1)
                    }

                    Text(snapshot.title.isEmpty ? (state.language == .korean ? "음악 없음" : "No Track") : snapshot.title)
                        .font(.system(size: h * 0.15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(snapshot.hasContent ? 0.94 : 0.56))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)

                    Text(compactSubtitle(snapshot))
                        .font(.system(size: h * 0.075, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.54))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    NowPlayingProgress(snapshot: snapshot)
                        .frame(height: max(4, h * 0.026))
                        .padding(.top, h * 0.015)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, h * 0.12)
            .frame(width: geo.size.width, height: geo.size.height)
            .nowPlayingGlass(snapshot: snapshot, cornerRadius: h * 0.14)
            .onAppear { service.start() }
        }
    }

    private func compactSubtitle(_ snapshot: NowPlayingSnapshot) -> String {
        let pieces = [snapshot.artist, snapshot.album].filter { !$0.isEmpty }
        if !pieces.isEmpty { return pieces.joined(separator: "  -  ") }
        return snapshot.hasContent ? "YouTube Music" : (state.language == .korean ? "시스템 미디어 정보 대기 중" : "Waiting for system media")
    }
}

struct NowPlayingCoverWidgetView: View {
    @Environment(AppState.self) private var state
    @ObservedObject private var service = NowPlayingService.shared
    let itemID: UUID

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let snapshot = service.snapshot
            let artSide = min(w * 0.76, h * 0.58)

            VStack(spacing: h * 0.045) {
                NowPlayingArtwork(snapshot: snapshot, cornerRadius: artSide * 0.08)
                    .frame(width: artSide, height: artSide)
                    .shadow(color: .black.opacity(0.24), radius: h * 0.035, y: h * 0.018)

                VStack(spacing: h * 0.018) {
                    Text(snapshot.title.isEmpty ? (state.language == .korean ? "음악 없음" : "No Track") : snapshot.title)
                        .font(.system(size: h * 0.052, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(snapshot.hasContent ? 0.94 : 0.56))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(snapshot.artist.isEmpty ? "YouTube Music" : snapshot.artist)
                        .font(.system(size: h * 0.036, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.56))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .padding(.horizontal, h * 0.04)

                NowPlayingProgress(snapshot: snapshot)
                    .frame(height: max(4, h * 0.014))
                    .padding(.horizontal, w * 0.12)

                Image(systemName: snapshot.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: h * 0.03, weight: .semibold))
                    .foregroundStyle(.white.opacity(snapshot.hasContent ? 0.72 : 0.32))
                    .frame(width: h * 0.08, height: h * 0.08)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .nowPlayingGlass(snapshot: snapshot, cornerRadius: h * 0.065)
            .onAppear { service.start() }
        }
    }
}

private struct NowPlayingArtwork: View {
    let snapshot: NowPlayingSnapshot
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            if let artwork = snapshot.artwork {
                Image(platformImage: artwork)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.system(size: max(16, cornerRadius * 1.5), weight: .semibold))
                        .foregroundStyle(.white.opacity(0.48))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.7)
        )
    }
}

private struct NowPlayingProgress: View {
    let snapshot: NowPlayingSnapshot

    var body: some View {
        GeometryReader { geo in
            if snapshot.duration > 0 {
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.14))
                    Capsule()
                        .fill(Color.white.opacity(snapshot.hasContent ? 0.74 : 0.28))
                        .frame(width: geo.size.width * progress)
                }
            } else {
                Capsule().fill(Color.white.opacity(0.1))
            }
        }
    }

    private var progress: CGFloat {
        guard snapshot.duration > 0 else { return 0 }
        return CGFloat(min(max(snapshot.elapsed / snapshot.duration, 0), 1))
    }
}

private extension View {
    func nowPlayingGlass(snapshot: NowPlayingSnapshot, cornerRadius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return self
            .background {
                ZStack {
                    if let artwork = snapshot.artwork {
                        Image(platformImage: artwork)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 28)
                            .saturation(1.15)
                            .opacity(0.32)
                    }
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.18),
                            Color.black.opacity(0.38)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                // Contain the blurred-art halo before it bleeds past the corners.
                .clipShape(shape)
            }
            .glassEffect(.regular, in: shape)
            // Clip the whole card (content overflow + glass/blur rim) to the rounded box.
            .clipShape(shape)
    }
}
