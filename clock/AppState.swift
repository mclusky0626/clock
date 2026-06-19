import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import Observation
#if canImport(EventKit)
import EventKit
#endif
#if canImport(AppKit)
import AppKit
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

enum CanvasMode: String, CaseIterable, Identifiable, Codable {
    case clock = "시계"
    case timer = "타이머"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .clock: return "clock"
        case .timer: return "timer"
        }
    }
}

enum TimerStyle: String, CaseIterable, Identifiable, Codable {
    case digital
    case disk
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .digital: return "textformat.123"
        case .disk:    return "circle.righthalf.filled"
        }
    }
}

enum BackgroundMode: String, CaseIterable, Identifiable, Codable {
    case color          // 단색/그라데이션 (또는 시간별 테마)
    case transparent    // 완전 투명 — 바탕화면 그대로 비침
    case translucent    // 반투명 — 바탕화면이 흐릿하게 비침
    case glassOutline   // 투명 + 리퀴드 글래스 윤곽선
    var id: String { rawValue }
    /// 윈도우 자체를 투명하게 만들어야 하는 모드인지
    var needsTransparentWindow: Bool {
        switch self {
        case .color: return false
        case .transparent, .translucent, .glassOutline: return true
        }
    }
}

enum ClockFormat: String, CaseIterable, Identifiable, Codable {
    case hm24 = "24h · HH:MM"
    case hms24 = "24h · HH:MM:SS"
    case hm12 = "12h · h:MM"
    case hms12 = "12h · h:MM:SS"
    var id: String { rawValue }
}

enum ClockWeight: String, CaseIterable, Identifiable, Codable {
    case ultraLight, thin, light, regular, medium, semibold, bold, heavy
    var id: String { rawValue }
    var fontWeight: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin:       return .thin
        case .light:      return .light
        case .regular:    return .regular
        case .medium:     return .medium
        case .semibold:   return .semibold
        case .bold:       return .bold
        case .heavy:      return .heavy
        }
    }
    var displayName: String {
        switch self {
        case .ultraLight: return "Ultra Light"
        case .thin:       return "Thin"
        case .light:      return "Light"
        case .regular:    return "Regular"
        case .medium:     return "Medium"
        case .semibold:   return "Semibold"
        case .bold:       return "Bold"
        case .heavy:      return "Heavy"
        }
    }
}

enum DigitMaterial: String, CaseIterable, Identifiable, Codable {
    case solid = "단색"
    case gradient = "그라데이션"
    case glass = "글래스 (배경 비침)"
    case liquidGlass = "리퀴드 글래스"
    case overlay = "오버레이 (배경과 어우러짐)"
    var id: String { rawValue }
}

enum DigitAnimation: String, CaseIterable, Identifiable, Codable {
    case none = "없음"
    case fade = "페이드"
    case roll = "롤"
    case slideUp = "위로 슬라이드"
    case slideDown = "아래로 슬라이드"
    case scale = "스케일"
    case flip = "플립 (3D)"
    case depth = "뎁스"
    case blur = "블러"
    var id: String { rawValue }
}

enum NumeralStyle: String, CaseIterable, Identifiable, Codable {
    case font       // 일반 폰트 글리프
    case segment    // 7-세그먼트 (세로 늘려도 비율 안 깨짐)
    var id: String { rawValue }
}

struct ClockStyle: Equatable {
    var family: ClockFontFamily = .sfPro
    var weight: ClockWeight = .ultraLight
    var fontSize: CGFloat = 240
    var tracking: CGFloat = 0
    var stretchY: CGFloat = 1.4
    var format: ClockFormat = .hm24
    var color: Color = .white
    var separator: SeparatorStyle = .colon
    var material: DigitMaterial = .solid
    var transition: DigitAnimation = .roll
    var numeralStyle: NumeralStyle = .font
}

struct Transform: Equatable {
    var position: CGPoint
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var rotation: Angle = .zero
    var opacity: Double = 1
    var zIndex: Double = 0
}

struct WidgetSettings: Equatable {
    var accentColor: Color = .white
    var timerDurationSeconds: Int = 5 * 60
    var timerRemaining: Int = 5 * 60
    var timerRunning: Bool = false
    var calendarYear: Int?
    var calendarMonth: Int?
    var showsCalendarEvents: Bool = false
    var timeZoneIdentifier: String = TimeZone.current.identifier
    var worldClockTitle: String = ""
    var dDayTitle: String = "D-Day"
    var dDayDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now

    static func defaults(for kind: WidgetKind) -> WidgetSettings {
        switch kind {
        case .timerMini:
            return WidgetSettings(accentColor: Color(.sRGB, red: 1.0, green: 0.231, blue: 0.188, opacity: 1))
        case .monthCalendar:
            return WidgetSettings(accentColor: .white)
        case .worldClock:
            return WidgetSettings(timeZoneIdentifier: TimeZone.current.identifier, worldClockTitle: "")
        case .dDay:
            return WidgetSettings(dDayTitle: "D-Day")
        case .systemMonitor:
            return WidgetSettings(accentColor: Color(.sRGB, red: 0.36, green: 0.86, blue: 0.66, opacity: 1))
        case .todaySchedule:
            return WidgetSettings(accentColor: Color(.sRGB, red: 0.48, green: 0.68, blue: 1.0, opacity: 1))
        case .nowPlayingMini, .nowPlayingCompact, .nowPlayingCover:
            return WidgetSettings(accentColor: Color(.sRGB, red: 1.0, green: 0.235, blue: 0.325, opacity: 1))
        case .dateDay, .dayProgress, .weekStrip:
            return WidgetSettings()
        }
    }
}

struct CalendarEventSummary: Identifiable, Equatable {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
}

struct HTMLWidgetSettings: Equatable {
    var resourceID: UUID = UUID()
    var entryFileName: String = "index.html"
    var displayName: String = "HTML"
    var allowsNetwork: Bool = true
    var reloadNonce: Int = 0
}

struct ClickRippleSettings: Equatable {
    var enabled: Bool = true
    var intensity: Double = 0.55
    var radius: CGFloat = 260
    var duration: Double = 0.8
}

enum WeatherKind: String, CaseIterable, Identifiable, Codable {
    case sunny, partlyCloudy, cloudy, windy, rainy, sunshower, snowy, rainbow
    case auto   // 현재 위치 날씨를 API로 자동 반영

    var id: String { rawValue }

    /// 메뉴에 직접 노출하는 수동 항목 (auto 제외)
    static let manualCases: [WeatherKind] = [
        .sunny, .partlyCloudy, .cloudy, .windy, .rainy, .sunshower, .snowy, .rainbow
    ]

    var sfSymbol: String {
        switch self {
        case .sunny:        return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy:       return "cloud.fill"
        case .windy:        return "wind"
        case .rainy:        return "cloud.rain.fill"
        case .sunshower:    return "cloud.sun.rain.fill"
        case .snowy:        return "cloud.snow.fill"
        case .rainbow:      return "rainbow"
        case .auto:         return "location.fill"
        }
    }
}

/// Floating "glass widgets" that live on the canvas (date, etc.). Each renders
/// inside a native Liquid Glass card and is draggable / resizable like any item.
enum WidgetKind: String, CaseIterable, Identifiable, Codable {
    case dateDay   // 날짜 · 요일
    case monthCalendar
    case timerMini
    case dayProgress
    case weekStrip
    case worldClock
    case dDay
    case systemMonitor
    case todaySchedule
    case nowPlayingMini
    case nowPlayingCompact
    case nowPlayingCover

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .dateDay: return "calendar"
        case .monthCalendar: return "calendar.circle"
        case .timerMini: return "timer"
        case .dayProgress: return "sun.max"
        case .weekStrip: return "calendar.day.timeline.left"
        case .worldClock: return "globe"
        case .dDay: return "flag.checkered"
        case .systemMonitor: return "waveform.path.ecg"
        case .todaySchedule: return "list.bullet.rectangle"
        case .nowPlayingMini: return "music.note"
        case .nowPlayingCompact: return "music.note.list"
        case .nowPlayingCover: return "music.quarternote.3"
        }
    }

    /// Natural (unscaled) size used when first added to the canvas.
    var defaultSize: CGSize {
        switch self {
        case .dateDay: return CGSize(width: 300, height: 176)
        case .monthCalendar: return CGSize(width: 360, height: 300)
        case .timerMini: return CGSize(width: 280, height: 180)
        case .dayProgress: return CGSize(width: 360, height: 140)
        case .weekStrip: return CGSize(width: 340, height: 128)
        case .worldClock: return CGSize(width: 340, height: 180)
        case .dDay: return CGSize(width: 340, height: 180)
        case .systemMonitor: return CGSize(width: 360, height: 260)
        case .todaySchedule: return CGSize(width: 380, height: 260)
        case .nowPlayingMini: return CGSize(width: 380, height: 92)
        case .nowPlayingCompact: return CGSize(width: 440, height: 180)
        case .nowPlayingCover: return CGSize(width: 320, height: 420)
        }
    }
}

enum ItemKind: Equatable {
    case clock
    case photo(imageID: UUID)
    case weather(WeatherKind)
    case widget(WidgetKind)
    case html
}

struct CanvasItem: Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: ItemKind
    var transform: Transform
    var size: CGSize
    var cornerRadius: CGFloat = 0
    var shadowRadius: CGFloat = 0
    var widgetSettings = WidgetSettings()
    var htmlSettings = HTMLWidgetSettings()
}

struct CustomAlarm: Identifiable, Equatable, Codable {
    var id: UUID
    var name: String
    var fileExtension: String
}

enum AlarmChoice: Equatable, Codable {
    case none
    case system(String)
    case custom(UUID)

    var displayName: String {
        switch self {
        case .none: return "끄기"
        case .system(let name): return name
        case .custom: return "사용자"
        }
    }
}

enum SystemAlarm: String, CaseIterable, Identifiable {
    case glass = "Glass"
    case ping = "Ping"
    case hero = "Hero"
    case submarine = "Submarine"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case tink = "Tink"
    case morse = "Morse"
    case funk = "Funk"
    case blow = "Blow"
    var id: String { rawValue }
}

@MainActor
@Observable
final class AppState {
    static let logicalCanvasSize = CGSize(width: 1280, height: 800)
    static let timerDiskSide: CGFloat = 440

    var mode: CanvasMode = .clock
    var clockStyle = ClockStyle()

    var timerDurationSeconds: Int = 5 * 60
    var timerRemaining: Int = 5 * 60
    var timerRunning: Bool = false
    var timerStyle: TimerStyle = .digital
    var timerDiskColor: Color = Color(.sRGB, red: 1.0, green: 0.231, blue: 0.188, opacity: 1)

    var language: AppLanguage = .korean

    var items: [CanvasItem]
    var images: [UUID: PlatformImage] = [:]
    var selectedID: UUID?

    // SwiftUI file-importer presentation flags (cross-platform replacement for NSOpenPanel)
    var photoImporterShown = false
    var backgroundImporterShown = false
    var alarmImporterShown = false
    var htmlImporterShown = false

    var backgroundColor: Color = .black
    var backgroundImageID: UUID?
    var backgroundMode: BackgroundMode = .color
    var autoTheme: Bool = false
    var backgroundOpacity: Double = 0.65   // 반투명 모드 프로스트 농도 (0 = 완전 투명, 1 = 진한 프로스트)
    var rippleSettings = ClickRippleSettings()

    var inspectorVisible: Bool = true
    var chromeVisible: Bool = true
    var alwaysOnTop: Bool = false

    var alarmChoice: AlarmChoice = .system(SystemAlarm.glass.rawValue)
    var alarmVolume: Float = 0.8
    var customAlarms: [CustomAlarm] = []

    var presets: [Preset] = []

    var calendarPermissionDenied = false
    var calendarEventsByDay: [String: [CalendarEventSummary]] = [:]

    @ObservationIgnored private var alarmPlayer: AVAudioPlayer?
    @ObservationIgnored private var pendingSaveTask: Task<Void, Never>?
    #if canImport(EventKit)
    @ObservationIgnored private let eventStore = EKEventStore()
    #endif

    init() {
        let clock = CanvasItem(
            kind: .clock,
            transform: Transform(position: .init(x: 640, y: 380)),
            size: .init(width: 720, height: 240)
        )
        self.items = [clock]
        self.selectedID = clock.id
        load()
        loadPresets()
        recomputeClockSize()
    }

    // MARK: - Derived

    var clockItemID: UUID? {
        items.first(where: { if case .clock = $0.kind { true } else { false } })?.id
    }

    func index(of id: UUID) -> Int? {
        items.firstIndex(where: { $0.id == id })
    }

    func t(_ key: LKey) -> String { Localization.string(key, language) }

    func recomputeClockSize() {
        guard let id = clockItemID, let idx = index(of: id) else { return }
        if mode == .timer && timerStyle == .disk {
            let target = CGSize(width: Self.timerDiskSide, height: Self.timerDiskSide)
            if items[idx].size != target { items[idx].size = target }
            return
        }
        let sample = ClockDisplayView.sampleLabel(for: self)
        let natural: CGSize = clockStyle.numeralStyle == .segment
            ? SegmentTimeView.naturalSize(
                text: sample,
                fontSize: clockStyle.fontSize,
                stretchY: clockStyle.stretchY,
                separator: clockStyle.separator,
                tracking: clockStyle.tracking
              )
            : TimeText.naturalSize(
                text: sample,
                fontSize: clockStyle.fontSize,
                extraTracking: clockStyle.tracking,
                stretchY: clockStyle.stretchY,
                separator: clockStyle.separator
              )
        if items[idx].size != natural {
            items[idx].size = natural
        }
    }

    // MARK: - Mutations

    func addPhoto(_ image: PlatformImage) {
        let imageID = UUID()
        images[imageID] = image
        writeImage(image, id: imageID)

        let nat = image.size == .zero ? CGSize(width: 320, height: 320) : image.size
        let maxDim: CGFloat = 360
        let k = min(maxDim / max(nat.width, 1), maxDim / max(nat.height, 1), 1)
        let size = CGSize(width: nat.width * k, height: nat.height * k)
        let item = CanvasItem(
            kind: .photo(imageID: imageID),
            transform: Transform(
                position: .init(x: 480, y: 360),
                zIndex: nextZIndex()
            ),
            size: size,
            cornerRadius: 18,
            shadowRadius: 24
        )
        items.append(item)
        selectedID = item.id
        scheduleSave()
    }

    func addWeather(_ kind: WeatherKind) {
        let item = CanvasItem(
            kind: .weather(kind),
            transform: Transform(
                position: .init(x: 480, y: 360),
                zIndex: nextZIndex()
            ),
            size: .init(width: 240, height: 240)
        )
        items.append(item)
        selectedID = item.id
        scheduleSave()
    }

    func addWidget(_ kind: WidgetKind) {
        let item = CanvasItem(
            kind: .widget(kind),
            transform: Transform(
                position: .init(x: 480, y: 360),
                zIndex: nextZIndex()
            ),
            size: kind.defaultSize,
            widgetSettings: WidgetSettings.defaults(for: kind)
        )
        items.append(item)
        selectedID = item.id
        scheduleSave()
    }

    func addHTMLWidget(settings: HTMLWidgetSettings) {
        let item = CanvasItem(
            kind: .html,
            transform: Transform(
                position: .init(x: 480, y: 360),
                zIndex: nextZIndex()
            ),
            size: .init(width: 420, height: 260),
            cornerRadius: 18,
            shadowRadius: 18,
            htmlSettings: settings
        )
        items.append(item)
        selectedID = item.id
        scheduleSave()
    }

    func deleteSelected() {
        guard let id = selectedID, let item = items.first(where: { $0.id == id }) else { return }
        if case .clock = item.kind { return }
        if case let .photo(imageID) = item.kind {
            images.removeValue(forKey: imageID)
            deleteImageFile(id: imageID)
        }
        if case .html = item.kind {
            deleteHTMLBundle(id: item.htmlSettings.resourceID)
        }
        items.removeAll { $0.id == id }
        selectedID = nil
        scheduleSave()
    }

    func nextZIndex() -> Double {
        (items.map { $0.transform.zIndex }.max() ?? 0) + 1
    }
    func minZIndex() -> Double {
        (items.map { $0.transform.zIndex }.min() ?? 0) - 1
    }

    func bringForward(_ id: UUID) {
        guard let i = index(of: id) else { return }
        items[i].transform.zIndex = nextZIndex()
        scheduleSave()
    }
    func sendBackward(_ id: UUID) {
        guard let i = index(of: id) else { return }
        items[i].transform.zIndex = minZIndex()
        scheduleSave()
    }
    func placeBehindClock(_ id: UUID) {
        guard let i = index(of: id), let cid = clockItemID, let ci = index(of: cid) else { return }
        items[i].transform.zIndex = items[ci].transform.zIndex - 0.5
        scheduleSave()
    }
    func placeInFrontOfClock(_ id: UUID) {
        guard let i = index(of: id), let cid = clockItemID, let ci = index(of: cid) else { return }
        items[i].transform.zIndex = items[ci].transform.zIndex + 0.5
        scheduleSave()
    }

    // MARK: - Timer

    func tickTimer() {
        guard timerRunning else { return }
        if timerRemaining > 0 {
            timerRemaining -= 1
            if timerRemaining == 0 {
                timerRunning = false
                playAlarm()
            }
        }
    }

    func startTimer() {
        if timerRemaining == 0 { timerRemaining = max(timerDurationSeconds, 1) }
        timerRunning = true
    }
    func pauseTimer() { timerRunning = false }
    func resetTimer() {
        timerRunning = false
        timerRemaining = timerDurationSeconds
        alarmPlayer?.stop()
    }

    func tickWidgetTimers() {
        var changed = false
        for idx in items.indices {
            guard case .widget(.timerMini) = items[idx].kind,
                  items[idx].widgetSettings.timerRunning else { continue }

            if items[idx].widgetSettings.timerRemaining > 0 {
                items[idx].widgetSettings.timerRemaining -= 1
                changed = true
            }
            if items[idx].widgetSettings.timerRemaining == 0 {
                items[idx].widgetSettings.timerRunning = false
                changed = true
            }
        }
        if changed { scheduleSave() }
    }

    func startWidgetTimer(_ id: UUID) {
        guard let idx = index(of: id) else { return }
        if items[idx].widgetSettings.timerRemaining == 0 {
            items[idx].widgetSettings.timerRemaining = max(items[idx].widgetSettings.timerDurationSeconds, 1)
        }
        items[idx].widgetSettings.timerRunning = true
        scheduleSave()
    }

    func pauseWidgetTimer(_ id: UUID) {
        guard let idx = index(of: id) else { return }
        items[idx].widgetSettings.timerRunning = false
        scheduleSave()
    }

    func resetWidgetTimer(_ id: UUID) {
        guard let idx = index(of: id) else { return }
        items[idx].widgetSettings.timerRunning = false
        items[idx].widgetSettings.timerRemaining = items[idx].widgetSettings.timerDurationSeconds
        scheduleSave()
    }

    func calendarEvents(on date: Date) -> [CalendarEventSummary] {
        calendarEventsByDay[Self.dayKey(for: date)] ?? []
    }

    func refreshCalendarEvents(forMonthContaining date: Date) {
        #if canImport(EventKit)
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .notDetermined {
            let requestedDate = date
            let handleResult: @Sendable (Bool, Error?) -> Void = { [weak self] granted, _ in
                Task { @MainActor [weak self, requestedDate] in
                    guard let state = self else { return }
                    state.calendarPermissionDenied = !granted
                    if granted { state.loadCalendarEvents(forMonthContaining: requestedDate) }
                }
            }
            if #available(macOS 14.0, iOS 17.0, *) {
                eventStore.requestFullAccessToEvents(completion: handleResult)
            } else {
                eventStore.requestAccess(to: .event, completion: handleResult)
            }
            return
        }

        if Self.hasCalendarAccess(status) {
            calendarPermissionDenied = false
            loadCalendarEvents(forMonthContaining: date)
        } else {
            calendarPermissionDenied = true
        }
        #else
        calendarPermissionDenied = true
        #endif
    }

    static func dayKey(for date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    #if canImport(EventKit)
    private static func hasCalendarAccess(_ status: EKAuthorizationStatus) -> Bool {
        if #available(macOS 14.0, iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    private func loadCalendarEvents(forMonthContaining date: Date) {
        let cal = Calendar.current
        guard let month = cal.dateInterval(of: .month, for: date) else { return }
        let predicate = eventStore.predicateForEvents(withStart: month.start, end: month.end, calendars: nil)
        let events = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        var grouped: [String: [CalendarEventSummary]] = [:]
        for event in events {
            let key = Self.dayKey(for: event.startDate)
            grouped[key, default: []].append(
                CalendarEventSummary(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay
                )
            )
        }
        calendarEventsByDay.merge(grouped) { _, new in new }
    }
    #endif

    // MARK: - Alarm

    func playAlarm() {
        alarmPlayer?.stop()
        switch alarmChoice {
        case .none:
            return
        case .system(let name):
            #if os(macOS)
            let sound = NSSound(named: NSSound.Name(name))
            sound?.volume = alarmVolume
            sound?.play()
            #else
            // iOS has no named system-sound catalog; play a default alert tone.
            _ = name
            AudioServicesPlaySystemSound(1007)
            #endif
        case .custom(let id):
            guard let alarm = customAlarms.first(where: { $0.id == id }) else { return }
            let url = Self.audioURL(for: alarm)
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.volume = alarmVolume
                player.prepareToPlay()
                player.play()
                alarmPlayer = player
            }
        }
    }

    func stopAlarmPreview() {
        alarmPlayer?.stop()
    }

    func presentCustomAlarmPicker() {
        #if os(macOS)
        presentOpenPanel(
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { [weak self] urls in
            self?.handleAlarmImport(.success(urls))
        }
        #else
        alarmImporterShown = true
        #endif
    }

    func handleAlarmImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result else { return }
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let id = UUID()
            let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension
            let dest = Self.audioDir.appendingPathComponent("\(id.uuidString).\(ext)")
            do {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: url, to: dest)
                let alarm = CustomAlarm(
                    id: id,
                    name: url.deletingPathExtension().lastPathComponent,
                    fileExtension: ext
                )
                customAlarms.append(alarm)
                alarmChoice = .custom(id)
            } catch {
                NSLog("Failed to copy alarm: \(error)")
            }
        }
        scheduleSave()
    }

    func deleteCustomAlarm(_ id: UUID) {
        if let alarm = customAlarms.first(where: { $0.id == id }) {
            let url = Self.audioURL(for: alarm)
            try? FileManager.default.removeItem(at: url)
        }
        customAlarms.removeAll { $0.id == id }
        if case .custom(let cid) = alarmChoice, cid == id {
            alarmChoice = .system(SystemAlarm.glass.rawValue)
        }
        scheduleSave()
    }

    // MARK: - HTML / photo / background picking

    func presentHTMLPicker() {
        #if os(macOS)
        presentOpenPanel(
            allowedContentTypes: Self.htmlContentTypes,
            allowsMultipleSelection: true
        ) { [weak self] urls in
            self?.handleHTMLImport(.success(urls))
        }
        #else
        htmlImporterShown = true
        #endif
    }

    func handleHTMLImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result else { return }
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let settings = try importHTMLBundle(from: url)
                addHTMLWidget(settings: settings)
            } catch {
                NSLog("Failed to import HTML widget: \(error)")
            }
        }
    }

    func reloadHTMLWidget(_ id: UUID) {
        guard let i = index(of: id) else { return }
        items[i].htmlSettings.reloadNonce += 1
    }

    func presentPhotoPicker() {
        #if os(macOS)
        presentOpenPanel(
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { [weak self] urls in
            self?.handlePhotoImport(.success(urls))
        }
        #else
        photoImporterShown = true
        #endif
    }

    func handlePhotoImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result else { return }
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            if let img = PlatformImage.load(contentsOf: url) {
                addPhoto(img)
            }
        }
    }

    func presentBackgroundImagePicker() {
        #if os(macOS)
        presentOpenPanel(
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { [weak self] urls in
            self?.handleBackgroundImport(.success(urls))
        }
        #else
        backgroundImporterShown = true
        #endif
    }

    func handleBackgroundImport(_ result: Result<[URL], Error>) {
        guard case let .success(urls) = result, let url = urls.first else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let img = PlatformImage.load(contentsOf: url) else { return }
        let id = UUID()
        images[id] = img
        writeImage(img, id: id)
        if let old = backgroundImageID {
            images.removeValue(forKey: old)
            deleteImageFile(id: old)
        }
        backgroundImageID = id
        backgroundMode = .color
        scheduleSave()
    }

    func clearBackgroundImage() {
        if let id = backgroundImageID {
            images.removeValue(forKey: id)
            deleteImageFile(id: id)
        }
        backgroundImageID = nil
        scheduleSave()
    }

    #if os(macOS)
    private func presentOpenPanel(
        allowedContentTypes: [UTType],
        allowsMultipleSelection: Bool,
        completion: @escaping ([URL]) -> Void
    ) {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.resolvesAliases = true
        panel.allowedContentTypes = allowedContentTypes

        let response = panel.runModal()
        guard response == .OK else { return }
        completion(panel.urls)
    }
    #endif

    private static var htmlContentTypes: [UTType] {
        [
            UTType(filenameExtension: "html") ?? .plainText,
            UTType(filenameExtension: "htm") ?? .plainText
        ]
    }

    private func importHTMLBundle(from url: URL) throws -> HTMLWidgetSettings {
        let id = UUID()
        let destination = Self.htmlBundleURL(id: id)
        let sourceRoot = url.deletingLastPathComponent()

        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

        do {
            try copyDirectoryContents(from: sourceRoot, to: destination)
        } catch {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            try FileManager.default.copyItem(
                at: url,
                to: destination.appendingPathComponent(url.lastPathComponent)
            )
        }

        return HTMLWidgetSettings(
            resourceID: id,
            entryFileName: url.lastPathComponent,
            displayName: url.deletingPathExtension().lastPathComponent,
            allowsNetwork: true
        )
    }

    private func copyDirectoryContents(from source: URL, to destination: URL) throws {
        let sourceComponents = source.standardizedFileURL.pathComponents
        let keys: [URLResourceKey] = [.isDirectoryKey]
        guard let enumerator = FileManager.default.enumerator(
            at: source,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return }

        for case let fileURL as URL in enumerator {
            let relativeComponents = Array(fileURL.standardizedFileURL.pathComponents.dropFirst(sourceComponents.count))
            guard !relativeComponents.isEmpty else { continue }
            let target = relativeComponents.reduce(destination) { partial, component in
                partial.appendingPathComponent(component)
            }
            let values = try fileURL.resourceValues(forKeys: Set(keys))
            if values.isDirectory == true {
                try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
            } else {
                try FileManager.default.createDirectory(
                    at: target.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try? FileManager.default.removeItem(at: target)
                try FileManager.default.copyItem(at: fileURL, to: target)
            }
        }
    }

    // MARK: - Persistence

    static let appSupportDir: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = base.appendingPathComponent("ClockWallpaper", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("images"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("audio"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("html"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("presets"), withIntermediateDirectories: true)
        return url
    }()
    static var stateFile: URL { appSupportDir.appendingPathComponent("state.json") }
    static var imageDir: URL { appSupportDir.appendingPathComponent("images") }
    static var audioDir: URL { appSupportDir.appendingPathComponent("audio") }
    static var htmlDir: URL { appSupportDir.appendingPathComponent("html", isDirectory: true) }
    static var presetsFile: URL { appSupportDir.appendingPathComponent("presets.json") }
    static var presetsDir: URL { appSupportDir.appendingPathComponent("presets") }
    static func presetDir(_ id: UUID) -> URL { presetsDir.appendingPathComponent(id.uuidString, isDirectory: true) }
    static func presetImageDir(_ id: UUID) -> URL { presetDir(id).appendingPathComponent("images", isDirectory: true) }
    static func presetHTMLDir(_ id: UUID) -> URL { presetDir(id).appendingPathComponent("html", isDirectory: true) }
    static func htmlBundleURL(id: UUID) -> URL { htmlDir.appendingPathComponent(id.uuidString, isDirectory: true) }

    static func imageURL(id: UUID) -> URL {
        imageDir.appendingPathComponent("\(id.uuidString).png")
    }
    static func audioURL(for alarm: CustomAlarm) -> URL {
        audioDir.appendingPathComponent("\(alarm.id.uuidString).\(alarm.fileExtension)")
    }

    func writeImage(_ image: PlatformImage, id: UUID) {
        guard let data = image.pngDataCompat() else { return }
        try? data.write(to: Self.imageURL(id: id))
    }
    func deleteImageFile(id: UUID) {
        try? FileManager.default.removeItem(at: Self.imageURL(id: id))
    }
    func deleteHTMLBundle(id: UUID) {
        try? FileManager.default.removeItem(at: Self.htmlBundleURL(id: id))
    }

    func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        let snap = makeSnapshot()
        do {
            let data = try JSONEncoder().encode(snap)
            try data.write(to: Self.stateFile, options: .atomic)
        } catch {
            NSLog("State save failed: \(error)")
        }
    }

    func makeSnapshot() -> PersistedState {
        PersistedState(
            mode: mode,
            clockStyle: PersistedClockStyle(
                family: clockStyle.family,
                weight: clockStyle.weight,
                fontSize: clockStyle.fontSize,
                tracking: clockStyle.tracking,
                stretchY: clockStyle.stretchY,
                format: clockStyle.format,
                color: PersistedColor(color: clockStyle.color),
                separator: clockStyle.separator,
                material: clockStyle.material,
                animation: clockStyle.transition,
                numeralStyle: clockStyle.numeralStyle
            ),
            items: items.map(PersistedItem.from),
            backgroundColor: PersistedColor(color: backgroundColor),
            backgroundImageID: backgroundImageID,
            timerDuration: timerDurationSeconds,
            alarmChoice: alarmChoice,
            alarmVolume: alarmVolume,
            customAlarms: customAlarms,
            alwaysOnTop: alwaysOnTop,
            timerStyle: timerStyle,
            timerDiskColor: PersistedColor(color: timerDiskColor),
            language: language,
            backgroundMode: backgroundMode,
            autoTheme: autoTheme,
            backgroundOpacity: backgroundOpacity,
            rippleSettings: PersistedClickRippleSettings(settings: rippleSettings)
        )
    }

    func load() {
        guard let data = try? Data(contentsOf: Self.stateFile),
              let snap = try? JSONDecoder().decode(PersistedState.self, from: data)
        else { return }
        apply(snap)
    }

    func apply(_ s: PersistedState) {
        applyVisual(s)
        // Global preferences (intentionally not part of a visual preset).
        alarmChoice = s.alarmChoice
        alarmVolume = s.alarmVolume
        customAlarms = s.customAlarms
        alwaysOnTop = s.alwaysOnTop
        language = s.language
        loadImagesFromSharedStore()
    }

    /// Restores only the visual look — clock style, background, item/widget layout,
    /// timer style. Shared by full state restore and preset application.
    func applyVisual(_ s: PersistedState) {
        mode = s.mode
        clockStyle = ClockStyle(
            family: s.clockStyle.family,
            weight: s.clockStyle.weight,
            fontSize: s.clockStyle.fontSize,
            tracking: s.clockStyle.tracking,
            stretchY: s.clockStyle.stretchY,
            format: s.clockStyle.format,
            color: s.clockStyle.color.color,
            separator: s.clockStyle.separator,
            material: s.clockStyle.material,
            transition: s.clockStyle.animation,
            numeralStyle: s.clockStyle.numeralStyle
        )
        backgroundColor = s.backgroundColor.color
        backgroundImageID = s.backgroundImageID
        backgroundMode = s.backgroundMode
        autoTheme = s.autoTheme
        backgroundOpacity = s.backgroundOpacity
        rippleSettings = s.rippleSettings.settings
        timerStyle = s.timerStyle
        timerDiskColor = s.timerDiskColor.color
        timerDurationSeconds = s.timerDuration
        timerRemaining = s.timerDuration
        items = s.items.map { $0.toCanvasItem() }
        selectedID = nil
    }

    /// Loads photo/background bitmaps for the current items from the shared image store.
    func loadImagesFromSharedStore() {
        for item in items {
            if case let .photo(imageID) = item.kind {
                if let img = PlatformImage.load(contentsOf: Self.imageURL(id: imageID)) {
                    images[imageID] = img
                }
            }
        }
        if let bgID = backgroundImageID {
            if let img = PlatformImage.load(contentsOf: Self.imageURL(id: bgID)) {
                images[bgID] = img
            } else {
                backgroundImageID = nil
            }
        }
    }

    // MARK: - Presets

    /// Image UUIDs a snapshot depends on (photo items + background image).
    private func referencedImageIDs(in s: PersistedState) -> [UUID] {
        var ids: [UUID] = []
        for item in s.items where item.kind == .photo {
            if let iid = item.imageID { ids.append(iid) }
        }
        if let bg = s.backgroundImageID { ids.append(bg) }
        return ids
    }

    private func referencedHTMLIDs(in s: PersistedState) -> [UUID] {
        s.items.compactMap { item in
            guard item.kind == .html else { return nil }
            return item.htmlSettings?.resourceID
        }
    }

    /// Captures the current look as a new named preset, copying referenced images so
    /// the preset stays intact even if those items are later deleted.
    func saveCurrentAsPreset(name: String? = nil) {
        let id = UUID()
        let snap = makeSnapshot()
        let dir = Self.presetImageDir(id)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for imgID in referencedImageIDs(in: snap) {
            let src = Self.imageURL(id: imgID)
            let dst = dir.appendingPathComponent("\(imgID.uuidString).png")
            try? FileManager.default.copyItem(at: src, to: dst)
        }
        let htmlDir = Self.presetHTMLDir(id)
        try? FileManager.default.createDirectory(at: htmlDir, withIntermediateDirectories: true)
        for htmlID in referencedHTMLIDs(in: snap) {
            let src = Self.htmlBundleURL(id: htmlID)
            let dst = htmlDir.appendingPathComponent(htmlID.uuidString, isDirectory: true)
            try? FileManager.default.removeItem(at: dst)
            try? FileManager.default.createDirectory(at: dst, withIntermediateDirectories: true)
            try? copyDirectoryContents(from: src, to: dst)
        }
        let preset = Preset(
            id: id,
            name: name ?? "\(t(.preset)) \(presets.count + 1)",
            createdAt: Date(),
            state: snap
        )
        presets.append(preset)
        savePresets()
    }

    func applyPreset(_ id: UUID) {
        guard let preset = presets.first(where: { $0.id == id }) else { return }
        // Restore the preset's images into the shared store (and memory).
        let dir = Self.presetImageDir(id)
        for imgID in referencedImageIDs(in: preset.state) {
            let shared = Self.imageURL(id: imgID)
            if !FileManager.default.fileExists(atPath: shared.path) {
                let copy = dir.appendingPathComponent("\(imgID.uuidString).png")
                try? FileManager.default.copyItem(at: copy, to: shared)
            }
            if let img = PlatformImage.load(contentsOf: shared) { images[imgID] = img }
        }
        let htmlDir = Self.presetHTMLDir(id)
        for htmlID in referencedHTMLIDs(in: preset.state) {
            let shared = Self.htmlBundleURL(id: htmlID)
            if !FileManager.default.fileExists(atPath: shared.path) {
                let copy = htmlDir.appendingPathComponent(htmlID.uuidString, isDirectory: true)
                try? FileManager.default.createDirectory(at: shared, withIntermediateDirectories: true)
                try? copyDirectoryContents(from: copy, to: shared)
            }
        }
        applyVisual(preset.state)
        recomputeClockSize()
        scheduleSave()
    }

    func renamePreset(_ id: UUID, to name: String) {
        guard let i = presets.firstIndex(where: { $0.id == id }) else { return }
        presets[i].name = name
        savePresets()
    }

    func deletePreset(_ id: UUID) {
        presets.removeAll { $0.id == id }
        try? FileManager.default.removeItem(at: Self.presetDir(id))
        savePresets()
    }

    func savePresets() {
        do {
            let data = try JSONEncoder().encode(presets)
            try data.write(to: Self.presetsFile, options: .atomic)
        } catch {
            NSLog("Preset save failed: \(error)")
        }
    }

    func loadPresets() {
        guard let data = try? Data(contentsOf: Self.presetsFile),
              let arr = try? JSONDecoder().decode([Preset].self, from: data)
        else { return }
        presets = arr
    }
}
