import SwiftUI

/// A classic "Time Timer": a white 60-minute dial with a red wedge that shows the
/// set/remaining time on an *absolute* hour scale. 1 minute = a thin sliver,
/// 60 minutes = the full disk. The disk caps at one hour.
struct TimerDiskView: View {
    @Environment(AppState.self) private var state

    private static let fullScaleSeconds: Double = 3600   // disk represents at most 1 hour

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let R = side / 2
            let fraction = currentFraction

            ZStack {
                face(side: side)
                ticks(side: side, R: R)
                numbers(side: side, R: R)

                DiskWedge(fraction: fraction)
                    .fill(wedgeStyle)
                    .frame(width: side * 0.84, height: side * 0.84)
                    .animation(.linear(duration: state.timerRunning ? 0.95 : 0.25),
                               value: state.timerRemaining)

                hub(side: side)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Remaining time as a fraction of the absolute 60-minute scale (0...1).
    private var currentFraction: Double {
        min(max(Double(state.timerRemaining) / Self.fullScaleSeconds, 0), 1)
    }

    private var wedgeStyle: some ShapeStyle {
        LinearGradient(
            colors: [state.timerDiskColor, state.timerDiskColor.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Layers

    private func face(side: CGFloat) -> some View {
        Circle()
            .fill(Color.white)
            .overlay(Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 1))
            .frame(width: side, height: side)
            .shadow(color: .black.opacity(0.28), radius: side * 0.035, x: 0, y: side * 0.01)
    }

    private func ticks(side: CGFloat, R: CGFloat) -> some View {
        ZStack {
            ForEach(0..<60, id: \.self) { i in
                let major = i % 5 == 0
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(major ? 0.55 : 0.22))
                    .frame(
                        width:  side * (major ? 0.009 : 0.005),
                        height: side * (major ? 0.045 : 0.024)
                    )
                    .offset(y: -R * 0.965)
                    .rotationEffect(.degrees(Double(i) * 6))
            }
        }
        .frame(width: side, height: side)
    }

    private func numbers(side: CGFloat, R: CGFloat) -> some View {
        let radius = R * 0.83
        return ZStack {
            ForEach(Array(stride(from: 5, through: 60, by: 5)), id: \.self) { n in
                let a = Double(n) / 60.0 * 2 * .pi      // counterclockwise from top
                let dx = -CGFloat(sin(a)) * radius
                let dy = -CGFloat(cos(a)) * radius
                Text("\(n)")
                    .font(.system(size: side * 0.052, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.72))
                    .offset(x: dx, y: dy)
            }
        }
        .frame(width: side, height: side)
    }

    private func hub(side: CGFloat) -> some View {
        let diameter = side * 0.30
        return ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.8))
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.18), radius: side * 0.01, x: 0, y: side * 0.003)

            Text(ClockDisplayView.formatTimer(seconds: state.timerRemaining))
                .font(.system(size: side * 0.092, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black.opacity(0.85))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, side * 0.02)
        }
    }
}

/// A filled pie slice from the center. `fraction` is 0...1; the wedge starts at
/// the top and sweeps counterclockwise so its leading edge lands on the matching
/// minute mark (e.g. 45 min → 3 o'clock).
struct DiskWedge: Shape {
    var fraction: Double

    var animatableData: Double {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let f = max(0, min(fraction, 1))
        guard f > 0 else { return p }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        p.move(to: center)
        let steps = max(2, Int(ceil(f * 240)))
        for i in 0...steps {
            let t = Double(i) / Double(steps) * f
            let theta = -2 * Double.pi * t          // counterclockwise from top
            let x = center.x + radius * CGFloat(sin(theta))
            let y = center.y - radius * CGFloat(cos(theta))
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.closeSubpath()
        return p
    }
}
