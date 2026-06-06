import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import Observation
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

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .dateDay: return "calendar"
        }
    }

    /// Natural (unscaled) size used when first added to the canvas.
    var defaultSize: CGSize {
        switch self {
        case .dateDay: return CGSize(width: 300, height: 176)
        }
    }
}

enum ItemKind: Equatable {
    case clock
    case photo(imageID: UUID)
    case weather(WeatherKind)
    case widget(WidgetKind)
}

struct CanvasItem: Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: ItemKind
    var transform: Transform
    var size: CGSize
    var cornerRadius: CGFloat = 0
    var shadowRadius: CGFloat = 0
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

    var backgroundColor: Color = .black
    var backgroundImageID: UUID?
    var backgroundMode: BackgroundMode = .color
    var autoTheme: Bool = false
    var backgroundOpacity: Double = 0.65   // 반투명 모드 프로스트 농도 (0 = 완전 투명, 1 = 진한 프로스트)

    var inspectorVisible: Bool = true
    var chromeVisible: Bool = true
    var alwaysOnTop: Bool = false

    var alarmChoice: AlarmChoice = .system(SystemAlarm.glass.rawValue)
    var alarmVolume: Float = 0.8
    var customAlarms: [CustomAlarm] = []

    @ObservationIgnored private var alarmPlayer: AVAudioPlayer?
    @ObservationIgnored private var pendingSaveTask: Task<Void, Never>?

    init() {
        let clock = CanvasItem(
            kind: .clock,
            transform: Transform(position: .init(x: 640, y: 380)),
            size: .init(width: 720, height: 240)
        )
        self.items = [clock]
        self.selectedID = clock.id
        load()
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
            size: kind.defaultSize
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

    func presentCustomAlarmPicker() { alarmImporterShown = true }

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

    // MARK: - Photo / background picking

    func presentPhotoPicker() { photoImporterShown = true }

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

    func presentBackgroundImagePicker() { backgroundImporterShown = true }

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

    // MARK: - Persistence

    static let appSupportDir: URL = {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = base.appendingPathComponent("ClockWallpaper", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("images"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: url.appendingPathComponent("audio"), withIntermediateDirectories: true)
        return url
    }()
    static var stateFile: URL { appSupportDir.appendingPathComponent("state.json") }
    static var imageDir: URL { appSupportDir.appendingPathComponent("images") }
    static var audioDir: URL { appSupportDir.appendingPathComponent("audio") }

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
            backgroundOpacity: backgroundOpacity
        )
    }

    func load() {
        guard let data = try? Data(contentsOf: Self.stateFile),
              let snap = try? JSONDecoder().decode(PersistedState.self, from: data)
        else { return }
        apply(snap)
    }

    func apply(_ s: PersistedState) {
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
        timerDurationSeconds = s.timerDuration
        timerRemaining = s.timerDuration
        alarmChoice = s.alarmChoice
        alarmVolume = s.alarmVolume
        customAlarms = s.customAlarms
        alwaysOnTop = s.alwaysOnTop
        timerStyle = s.timerStyle
        timerDiskColor = s.timerDiskColor.color
        language = s.language
        backgroundMode = s.backgroundMode
        autoTheme = s.autoTheme
        backgroundOpacity = s.backgroundOpacity

        items = s.items.map { $0.toCanvasItem() }
        selectedID = nil

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
}
