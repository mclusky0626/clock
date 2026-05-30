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
    var format: ClockFormat
    var color: PersistedColor
    var separator: SeparatorStyle
}

struct PersistedTransform: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var scale: CGFloat
    var rotationDegrees: Double
    var opacity: Double
    var zIndex: Double
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
                scale: item.transform.scale,
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
                scale: transform.scale,
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
}
