import SwiftUI
import AppKit

extension Color {
    init(hex: UInt) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    static func lerp(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let na = NSColor(a).usingColorSpace(.sRGB) ?? .black
        let nb = NSColor(b).usingColorSpace(.sRGB) ?? .black
        let tt = max(0, min(t, 1))
        func mix(_ x: CGFloat, _ y: CGFloat) -> Double { Double(x) + (Double(y) - Double(x)) * tt }
        return Color(.sRGB,
                     red:   mix(na.redComponent, nb.redComponent),
                     green: mix(na.greenComponent, nb.greenComponent),
                     blue:  mix(na.blueComponent, nb.blueComponent),
                     opacity: 1)
    }
}

/// Smoothly interpolated all-day background gradient. Kept dark/muted enough that
/// white digits stay readable at every hour.
enum TimeTheme {
    // (hour-of-day, topColor, bottomColor)
    private static let keys: [(h: Double, top: Color, bottom: Color)] = [
        (0,  Color(hex: 0x0B1022), Color(hex: 0x05070D)),   // deep night
        (6,  Color(hex: 0x1B2240), Color(hex: 0x3A2A55)),   // dawn indigo/plum
        (9,  Color(hex: 0x1E3A5F), Color(hex: 0x2E6F9E)),   // morning blue
        (13, Color(hex: 0x235A8C), Color(hex: 0x3E8FB0)),   // midday brighter
        (17, Color(hex: 0x3A3550), Color(hex: 0x6E5A52)),   // afternoon warm grey
        (20, Color(hex: 0x3B2B4A), Color(hex: 0x8A4A52)),   // evening sunset
        (24, Color(hex: 0x0B1022), Color(hex: 0x05070D)),   // wrap to midnight
    ]

    static func colors(for date: Date) -> (top: Color, bottom: Color) {
        let cal = Calendar.current
        let hour = Double(cal.component(.hour, from: date))
                 + Double(cal.component(.minute, from: date)) / 60.0
        for i in 0..<(keys.count - 1) {
            let a = keys[i], b = keys[i + 1]
            if hour >= a.h && hour <= b.h {
                let t = (hour - a.h) / (b.h - a.h)
                return (Color.lerp(a.top, b.top, t), Color.lerp(a.bottom, b.bottom, t))
            }
        }
        return (keys[0].top, keys[0].bottom)
    }
}
