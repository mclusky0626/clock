import SwiftUI

enum ClockFontFamily: String, CaseIterable, Identifiable, Codable {
    // System designs
    case sfPro = "SF Pro"
    case sfProRounded = "SF Pro Rounded"
    case sfMono = "SF Mono"
    case newYork = "New York"

    // Sans-serif
    case helveticaNeue = "Helvetica Neue"
    case avenirNext = "Avenir Next"
    case avenir = "Avenir"
    case futura = "Futura"
    case optima = "Optima"
    case geneva = "Geneva"

    // Serif
    case georgia = "Georgia"
    case palatino = "Palatino"
    case bodoni72 = "Bodoni 72"
    case didot = "Didot"
    case americanTypewriter = "American Typewriter"
    case iowanOldStyle = "Iowan Old Style"
    case hoeflerText = "Hoefler Text"
    case bigCaslon = "Big Caslon"
    case copperplate = "Copperplate"
    case baskerville = "Baskerville"
    case timesNewRoman = "Times New Roman"

    // Script / Display
    case snellRoundhand = "Snell Roundhand"
    case zapfino = "Zapfino"
    case savoye = "Savoye LET"
    case markerFelt = "Marker Felt"
    case chalkboardSE = "Chalkboard SE"
    case bradleyHand = "Bradley Hand"
    case papyrus = "Papyrus"

    // Monospace
    case menlo = "Menlo"
    case courier = "Courier"
    case courierNew = "Courier New"

    // Korean
    case appleSDGothic = "Apple SD Gothic Neo"
    case appleGothic = "AppleGothic"
    case appleMyungjo = "AppleMyungjo"

    var id: String { rawValue }
    var displayName: String { rawValue }

    func makeFont(size: CGFloat, weight: ClockWeight) -> Font {
        switch self {
        case .sfPro:
            return .system(size: size, weight: weight.fontWeight, design: .default)
        case .sfProRounded:
            return .system(size: size, weight: weight.fontWeight, design: .rounded)
        case .sfMono:
            return .system(size: size, weight: weight.fontWeight, design: .monospaced)
        case .newYork:
            return .system(size: size, weight: weight.fontWeight, design: .serif)
        default:
            return Font.custom(rawValue, size: size).weight(weight.fontWeight)
        }
    }

    var supportsMonospacedDigits: Bool {
        switch self {
        case .sfPro, .sfProRounded, .sfMono, .newYork,
             .helveticaNeue, .avenirNext, .avenir, .futura, .optima,
             .menlo, .courier, .courierNew:
            return true
        default:
            return false
        }
    }
}

enum ClockFontSection: String, CaseIterable, Identifiable {
    case system = "시스템"
    case sans = "산세리프"
    case serif = "세리프"
    case script = "필기·디스플레이"
    case mono = "모노스페이스"
    case korean = "한글"

    var id: String { rawValue }

    var members: [ClockFontFamily] {
        switch self {
        case .system:
            return [.sfPro, .sfProRounded, .sfMono, .newYork]
        case .sans:
            return [.helveticaNeue, .avenirNext, .avenir, .futura, .optima, .geneva]
        case .serif:
            return [.georgia, .palatino, .bodoni72, .didot, .americanTypewriter,
                    .iowanOldStyle, .hoeflerText, .bigCaslon, .copperplate, .baskerville, .timesNewRoman]
        case .script:
            return [.snellRoundhand, .zapfino, .savoye, .markerFelt, .chalkboardSE, .bradleyHand, .papyrus]
        case .mono:
            return [.menlo, .courier, .courierNew]
        case .korean:
            return [.appleSDGothic, .appleGothic, .appleMyungjo]
        }
    }
}
