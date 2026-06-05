import SwiftUI

// MARK: - Palette

private enum WX {
    static let sun      = Color(hex: 0xFFC83D)
    static let sunRay   = Color(hex: 0xFFD773)
    static let cloud    = Color(hex: 0xEDF2F8)
    static let cloudDim = Color(hex: 0xC9D5E3)
    static let rain     = Color(hex: 0x6FB1E3)
    static let snow     = Color(hex: 0xFFFFFF)
    static let wind     = Color(hex: 0xD3DCE6)
    static let softShadow = Color.black.opacity(0.22)
}

// MARK: - Shapes

/// A soft cloud silhouette built from a rounded base plus three puffs.
struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let x = rect.minX, y = rect.minY
        func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGRect {
            CGRect(x: x + cx * w - r * h, y: y + cy * h - r * h, width: 2 * r * h, height: 2 * r * h)
        }
        var p = Path()
        p.addRoundedRect(
            in: CGRect(x: x + 0.07 * w, y: y + 0.54 * h, width: 0.86 * w, height: 0.40 * h),
            cornerSize: CGSize(width: 0.20 * h, height: 0.20 * h),
            style: .continuous
        )
        p.addEllipse(in: ellipse(0.30, 0.60, 0.24))
        p.addEllipse(in: ellipse(0.52, 0.42, 0.32))
        p.addEllipse(in: ellipse(0.74, 0.58, 0.26))
        return p
    }
}

/// Top semicircle arc (for the rainbow), drawn from left to right.
struct SemiArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(360),
            clockwise: false
        )
        return p
    }
}

// MARK: - Reusable parts

private struct CloudView: View {
    var side: CGFloat
    var scale: CGFloat = 1
    var color: Color = WX.cloud
    var body: some View {
        CloudShape()
            .fill(color)
            .frame(width: side * 0.72 * scale, height: side * 0.46 * scale)
            .shadow(color: WX.softShadow, radius: side * 0.02, x: 0, y: side * 0.012)
    }
}

private struct SunView: View {
    var side: CGFloat
    var radius: CGFloat
    @State private var spin = 0.0
    var body: some View {
        ZStack {
            ZStack {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(WX.sunRay)
                        .frame(width: radius * 0.18, height: radius * 0.52)
                        .offset(y: -radius * 1.45)
                        .rotationEffect(.degrees(Double(i) / 12 * 360))
                }
            }
            .rotationEffect(.degrees(spin))

            Circle()
                .fill(WX.sun)
                .frame(width: radius * 2, height: radius * 2)
                .shadow(color: WX.sun.opacity(0.45), radius: radius * 0.3)
        }
        .onAppear {
            withAnimation(.linear(duration: 13).repeatForever(autoreverses: false)) { spin = 360 }
        }
    }
}

private struct RainDrops: View {
    var side: CGFloat
    var color: Color = WX.rain
    @State private var falling = false
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: side * 0.035, height: side * 0.13)
                    .offset(x: side * (CGFloat(i) - 1) * 0.17,
                            y: falling ? side * 0.20 : -side * 0.06)
                    .opacity(falling ? 0 : 1)
                    .animation(
                        .easeIn(duration: 1.1).repeatForever(autoreverses: false).delay(Double(i) * 0.32),
                        value: falling
                    )
            }
        }
        .onAppear { falling = true }
    }
}

private struct SnowFlakes: View {
    var side: CGFloat
    @State private var falling = false
    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "snowflake")
                    .font(.system(size: side * 0.13, weight: .light))
                    .foregroundStyle(WX.snow)
                    .shadow(color: WX.softShadow, radius: side * 0.01)
                    .offset(x: side * (CGFloat(i) - 1) * 0.18,
                            y: falling ? side * 0.20 : -side * 0.06)
                    .rotationEffect(.degrees(falling ? 160 : 0))
                    .opacity(falling ? 0 : 1)
                    .animation(
                        .easeIn(duration: 1.4).repeatForever(autoreverses: false).delay(Double(i) * 0.4),
                        value: falling
                    )
            }
        }
        .onAppear { falling = true }
    }
}

// MARK: - Stickers

private struct SunnySticker: View {
    var side: CGFloat
    var body: some View {
        SunView(side: side, radius: side * 0.19)
    }
}

private struct PartlyCloudySticker: View {
    var side: CGFloat
    var body: some View {
        ZStack {
            SunView(side: side, radius: side * 0.15)
                .offset(x: -side * 0.17, y: -side * 0.17)
            CloudView(side: side, scale: 0.96)
                .offset(x: side * 0.07, y: side * 0.12)
        }
    }
}

private struct CloudySticker: View {
    var side: CGFloat
    @State private var drift = false
    var body: some View {
        ZStack {
            CloudView(side: side, scale: 0.5, color: WX.cloudDim)
                .offset(x: drift ? side * 0.24 : -side * 0.30, y: -side * 0.16)
                .opacity(drift ? 0 : 0.9)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: false), value: drift)
            CloudView(side: side, scale: 1.05)
                .offset(y: side * 0.05)
        }
        .onAppear { drift = true }
    }
}

private struct WindySticker: View {
    var side: CGFloat
    @State private var sweep = false
    var body: some View {
        ZStack {
            CloudView(side: side, scale: 1.0)
                .offset(y: -side * 0.08)
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(WX.wind)
                    .frame(width: side * (i == 1 ? 0.46 : 0.34), height: side * 0.035)
                    .offset(x: sweep ? side * 0.16 : -side * 0.10,
                            y: side * (0.18 + 0.12 * CGFloat(i)))
                    .opacity(sweep ? 0.15 : 1)
                    .animation(
                        .easeInOut(duration: 1.7).repeatForever(autoreverses: false).delay(Double(i) * 0.22),
                        value: sweep
                    )
            }
        }
        .onAppear { sweep = true }
    }
}

private struct RainySticker: View {
    var side: CGFloat
    var body: some View {
        ZStack {
            CloudView(side: side, scale: 1.0)
                .offset(y: -side * 0.10)
            RainDrops(side: side)
                .offset(y: side * 0.26)
        }
    }
}

private struct SunshowerSticker: View {
    var side: CGFloat
    var body: some View {
        ZStack {
            SunView(side: side, radius: side * 0.13)
                .offset(x: -side * 0.18, y: -side * 0.20)
            CloudView(side: side, scale: 0.92)
                .offset(x: side * 0.06, y: -side * 0.02)
            RainDrops(side: side)
                .offset(x: side * 0.06, y: side * 0.28)
        }
    }
}

private struct SnowySticker: View {
    var side: CGFloat
    var body: some View {
        ZStack {
            CloudView(side: side, scale: 1.0)
                .offset(y: -side * 0.10)
            SnowFlakes(side: side)
                .offset(y: side * 0.26)
        }
    }
}

private struct RainbowSticker: View {
    var side: CGFloat
    @State private var draw = false
    private let colors: [Color] = [
        Color(hex: 0xE5564E), Color(hex: 0xE8893C), Color(hex: 0xF2C94C), Color(hex: 0x7BAE54)
    ]
    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                ForEach(0..<colors.count, id: \.self) { i in
                    SemiArc()
                        .trim(from: 0, to: draw ? 1 : 0)
                        .stroke(colors[i], style: StrokeStyle(lineWidth: side * 0.05, lineCap: .round))
                        .frame(width: side * (0.82 - CGFloat(i) * 0.14),
                               height: side * (0.41 - CGFloat(i) * 0.07))
                }
            }
            .frame(width: side, height: side * 0.5, alignment: .bottom)
            .offset(y: side * 0.06)
            .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: draw)

            CloudView(side: side, scale: 0.46).offset(x: -side * 0.30, y: side * 0.16)
            CloudView(side: side, scale: 0.46).offset(x: side * 0.30, y: side * 0.16)
        }
        .onAppear { draw = true }
    }
}

/// Live sticker that mirrors the current local weather fetched via OpenWeather.
private struct AutoWeatherSticker: View {
    var side: CGFloat
    @ObservedObject private var service = WeatherService.shared
    @State private var pulse = false

    var body: some View {
        Group {
            if let cond = service.condition {
                weatherSticker(cond, side: side)
            } else {
                Image(systemName: (service.status == .denied || service.status == .failed)
                      ? "exclamationmark.icloud" : "location.fill")
                    .font(.system(size: side * 0.2, weight: .light))
                    .foregroundStyle(WX.cloudDim)
                    .opacity(pulse ? 0.4 : 0.9)
                    .shadow(color: WX.softShadow, radius: side * 0.01)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
            }
        }
        .onAppear {
            service.start()
            pulse = true
        }
    }
}

@ViewBuilder
private func weatherSticker(_ kind: WeatherKind, side: CGFloat) -> some View {
    switch kind {
    case .sunny:        SunnySticker(side: side)
    case .partlyCloudy: PartlyCloudySticker(side: side)
    case .cloudy:       CloudySticker(side: side)
    case .windy:        WindySticker(side: side)
    case .rainy:        RainySticker(side: side)
    case .sunshower:    SunshowerSticker(side: side)
    case .snowy:        SnowySticker(side: side)
    case .rainbow:      RainbowSticker(side: side)
    case .auto:         AutoWeatherSticker(side: side)
    }
}

// MARK: - Entry point

struct WeatherStickerView: View {
    let kind: WeatherKind

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            weatherSticker(kind, side: side)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
