import SwiftUI
import AppKit

struct PersistedColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }

    init(color: Color) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .black
        self.red = Double(ns.redComponent)
        self.green = Double(ns.greenComponent)
        self.blue = Double(ns.blueComponent)
        self.alpha = Double(ns.alphaComponent)
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

struct PersistedClockStyle: Codable, Equatable {
    var family: ClockFontFamily
    var weight: ClockWeight
    var fontSize: CGFloat
    var tracking: CGFloat
    var stretchY: CGFloat
    var format: ClockFormat
    var color: PersistedColor
    var separator: SeparatorStyle
    var material: DigitMaterial
    var animation: DigitAnimation

    init(
        family: ClockFontFamily,
        weight: ClockWeight,
        fontSize: CGFloat,
        tracking: CGFloat,
        stretchY: CGFloat,
        format: ClockFormat,
        color: PersistedColor,
        separator: SeparatorStyle,
        material: DigitMaterial,
        animation: DigitAnimation
    ) {
        self.family = family; self.weight = weight; self.fontSize = fontSize
        self.tracking = tracking; self.stretchY = stretchY; self.format = format
        self.color = color; self.separator = separator
        self.material = material; self.animation = animation
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        family = try c.decode(ClockFontFamily.self, forKey: .family)
        weight = try c.decode(ClockWeight.self, forKey: .weight)
        fontSize = try c.decode(CGFloat.self, forKey: .fontSize)
        tracking = try c.decode(CGFloat.self, forKey: .tracking)
        stretchY = (try? c.decode(CGFloat.self, forKey: .stretchY)) ?? 1.0
        format = try c.decode(ClockFormat.self, forKey: .format)
        color = try c.decode(PersistedColor.self, forKey: .color)
        separator = try c.decode(SeparatorStyle.self, forKey: .separator)
        material = (try? c.decode(DigitMaterial.self, forKey: .material)) ?? .solid
        animation = (try? c.decode(DigitAnimation.self, forKey: .animation)) ?? .roll
    }
}

struct PersistedTransform: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var scaleX: CGFloat
    var scaleY: CGFloat
    var rotationDegrees: Double
    var opacity: Double
    var zIndex: Double

    enum CodingKeys: String, CodingKey {
        case x, y, scaleX, scaleY, scale, rotationDegrees, opacity, zIndex
    }

    init(x: CGFloat, y: CGFloat, scaleX: CGFloat, scaleY: CGFloat,
         rotationDegrees: Double, opacity: Double, zIndex: Double) {
        self.x = x; self.y = y
        self.scaleX = scaleX; self.scaleY = scaleY
        self.rotationDegrees = rotationDegrees
        self.opacity = opacity; self.zIndex = zIndex
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        x = try c.decode(CGFloat.self, forKey: .x)
        y = try c.decode(CGFloat.self, forKey: .y)
        let legacy = (try? c.decode(CGFloat.self, forKey: .scale)) ?? 1.0
        scaleX = (try? c.decode(CGFloat.self, forKey: .scaleX)) ?? legacy
        scaleY = (try? c.decode(CGFloat.self, forKey: .scaleY)) ?? legacy
        rotationDegrees = try c.decode(Double.self, forKey: .rotationDegrees)
        opacity = try c.decode(Double.self, forKey: .opacity)
        zIndex = try c.decode(Double.self, forKey: .zIndex)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(x, forKey: .x)
        try c.encode(y, forKey: .y)
        try c.encode(scaleX, forKey: .scaleX)
        try c.encode(scaleY, forKey: .scaleY)
        try c.encode(rotationDegrees, forKey: .rotationDegrees)
        try c.encode(opacity, forKey: .opacity)
        try c.encode(zIndex, forKey: .zIndex)
    }
}

enum PersistedItemKind: String, Codable {
    case clock
    case photo
}

struct PersistedItem: Codable, Equatable {
    var id: UUID
    var kind: PersistedItemKind
    var imageID: UUID?
    var transform: PersistedTransform
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat
    var shadowRadius: CGFloat

    static func from(_ item: CanvasItem) -> PersistedItem {
        let imgID: UUID? = {
            if case let .photo(id) = item.kind { return id }
            return nil
        }()
        let kind: PersistedItemKind = {
            switch item.kind {
            case .clock: return .clock
            case .photo: return .photo
            }
        }()
        return PersistedItem(
            id: item.id,
            kind: kind,
            imageID: imgID,
            transform: PersistedTransform(
                x: item.transform.position.x,
                y: item.transform.position.y,
                scaleX: item.transform.scaleX,
                scaleY: item.transform.scaleY,
                rotationDegrees: item.transform.rotation.degrees,
                opacity: item.transform.opacity,
                zIndex: item.transform.zIndex
            ),
            width: item.size.width,
            height: item.size.height,
            cornerRadius: item.cornerRadius,
            shadowRadius: item.shadowRadius
        )
    }

    func toCanvasItem() -> CanvasItem {
        let itemKind: ItemKind = {
            switch kind {
            case .clock: return .clock
            case .photo: return .photo(imageID: imageID ?? UUID())
            }
        }()
        return CanvasItem(
            id: id,
            kind: itemKind,
            transform: Transform(
                position: .init(x: transform.x, y: transform.y),
                scaleX: transform.scaleX,
                scaleY: transform.scaleY,
                rotation: .degrees(transform.rotationDegrees),
                opacity: transform.opacity,
                zIndex: transform.zIndex
            ),
            size: .init(width: width, height: height),
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius
        )
    }
}

struct PersistedState: Codable {
    var mode: CanvasMode
    var clockStyle: PersistedClockStyle
    var items: [PersistedItem]
    var backgroundColor: PersistedColor
    var backgroundImageID: UUID?
    var timerDuration: Int
    var alarmChoice: AlarmChoice
    var alarmVolume: Float
    var customAlarms: [CustomAlarm]
    var alwaysOnTop: Bool = false

    enum CodingKeys: CodingKey {
        case mode, clockStyle, items, backgroundColor, backgroundImageID
        case timerDuration, alarmChoice, alarmVolume, customAlarms, alwaysOnTop
    }

    init(
        mode: CanvasMode,
        clockStyle: PersistedClockStyle,
        items: [PersistedItem],
        backgroundColor: PersistedColor,
        backgroundImageID: UUID?,
        timerDuration: Int,
        alarmChoice: AlarmChoice,
        alarmVolume: Float,
        customAlarms: [CustomAlarm],
        alwaysOnTop: Bool
    ) {
        self.mode = mode; self.clockStyle = clockStyle; self.items = items
        self.backgroundColor = backgroundColor; self.backgroundImageID = backgroundImageID
        self.timerDuration = timerDuration; self.alarmChoice = alarmChoice
        self.alarmVolume = alarmVolume; self.customAlarms = customAlarms
        self.alwaysOnTop = alwaysOnTop
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mode = try c.decode(CanvasMode.self, forKey: .mode)
        clockStyle = try c.decode(PersistedClockStyle.self, forKey: .clockStyle)
        items = try c.decode([PersistedItem].self, forKey: .items)
        backgroundColor = try c.decode(PersistedColor.self, forKey: .backgroundColor)
        backgroundImageID = try c.decodeIfPresent(UUID.self, forKey: .backgroundImageID)
        timerDuration = try c.decode(Int.self, forKey: .timerDuration)
        alarmChoice = try c.decode(AlarmChoice.self, forKey: .alarmChoice)
        alarmVolume = try c.decode(Float.self, forKey: .alarmVolume)
        customAlarms = try c.decode([CustomAlarm].self, forKey: .customAlarms)
        alwaysOnTop = (try? c.decode(Bool.self, forKey: .alwaysOnTop)) ?? false
    }
}
