import SwiftUI
import AppKit
import AVFoundation
import UniformTypeIdentifiers
import Observation

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
}

struct Transform: Equatable {
    var position: CGPoint
    var scaleX: CGFloat = 1
    var scaleY: CGFloat = 1
    var rotation: Angle = .zero
    var opacity: Double = 1
    var zIndex: Double = 0
}

enum ItemKind: Equatable {
    case clock
    case photo(imageID: UUID)
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

    var mode: CanvasMode = .clock
    var clockStyle = ClockStyle()

    var timerDurationSeconds: Int = 5 * 60
    var timerRemaining: Int = 5 * 60
    var timerRunning: Bool = false

    var items: [CanvasItem]
    var images: [UUID: NSImage] = [:]
    var selectedID: UUID?

    var backgroundColor: Color = .black
    var backgroundImageID: UUID?

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

    func recomputeClockSize() {
        guard let id = clockItemID, let idx = index(of: id) else { return }
        let sample = ClockDisplayView.sampleLabel(for: self)
        let natural = TimeText.naturalSize(
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

    func addPhoto(_ image: NSImage) {
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
            let sound = NSSound(named: NSSound.Name(name))
            sound?.volume = alarmVolume
            sound?.play()
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
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        panel.title = "알람 사운드 추가"
        if panel.runModal() == .OK {
            for url in panel.urls {
                let id = UUID()
                let ext = url.pathExtension.isEmpty ? "mp3" : url.pathExtension
                let dest = Self.audioDir.appendingPathComponent("\(id.uuidString).\(ext)")
                do {
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

    func presentPhotoPicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image, .png, .jpeg, .tiff, .heic, .webP]
        panel.title = "사진 선택"
        if panel.runModal() == .OK {
            for url in panel.urls {
                if let img = NSImage(contentsOf: url) {
                    addPhoto(img)
                }
            }
        }
    }

    func presentBackgroundImagePicker() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image, .png, .jpeg, .tiff, .heic, .webP]
        panel.title = "배경 이미지 선택"
        if panel.runModal() == .OK, let url = panel.urls.first, let img = NSImage(contentsOf: url) {
            let id = UUID()
            images[id] = img
            writeImage(img, id: id)
            if let old = backgroundImageID {
                images.removeValue(forKey: old)
                deleteImageFile(id: old)
            }
            backgroundImageID = id
            scheduleSave()
        }
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

    func writeImage(_ image: NSImage, id: UUID) {
        guard let data = image.pngData() else { return }
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
                animation: clockStyle.transition
            ),
            items: items.map(PersistedItem.from),
            backgroundColor: PersistedColor(color: backgroundColor),
            backgroundImageID: backgroundImageID,
            timerDuration: timerDurationSeconds,
            alarmChoice: alarmChoice,
            alarmVolume: alarmVolume,
            customAlarms: customAlarms,
            alwaysOnTop: alwaysOnTop
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
            transition: s.clockStyle.animation
        )
        backgroundColor = s.backgroundColor.color
        backgroundImageID = s.backgroundImageID
        timerDurationSeconds = s.timerDuration
        timerRemaining = s.timerDuration
        alarmChoice = s.alarmChoice
        alarmVolume = s.alarmVolume
        customAlarms = s.customAlarms
        alwaysOnTop = s.alwaysOnTop

        items = s.items.map { $0.toCanvasItem() }
        selectedID = nil

        for item in items {
            if case let .photo(imageID) = item.kind {
                if let img = NSImage(contentsOf: Self.imageURL(id: imageID)) {
                    images[imageID] = img
                }
            }
        }
        if let bgID = backgroundImageID {
            if let img = NSImage(contentsOf: Self.imageURL(id: bgID)) {
                images[bgID] = img
            } else {
                backgroundImageID = nil
            }
        }
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiff = self.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }
}
