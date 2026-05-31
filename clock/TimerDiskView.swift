import SwiftUI

/// A "Time Timer" style disk: a red wedge emanating from the center shows the
/// remaining fraction of the set duration. The wedge fills counterclockwise from
/// the top (12 o'clock) and depletes back toward it as time runs out.
struct TimerDiskView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let fraction = currentFraction

            ZStack {
                face(side: side)
                ticks(side: side)

                DiskWedge(fraction: fraction)
                    .fill(wedgeStyle)
                    .frame(width: side * 0.84, height: side * 0.84)
                    .shadow(color: state.timerDiskColor.opacity(0.35), radius: side * 0.02, x: 0, y: 0)
                    .animation(.linear(duration: state.timerRunning ? 0.95 : 0.25),
                               value: state.timerRemaining)

                hub(side: side)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var currentFraction: Double {
        let dur = max(state.timerDurationSeconds, 1)
        return min(max(Double(state.timerRemaining) / Double(dur), 0), 1)
    }

    private var wedgeStyle: some ShapeStyle {
        LinearGradient(
            colors: [state.timerDiskColor, state.timerDiskColor.opacity(0.88)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Layers

    private func face(side: CGFloat) -> some View {
        Circle()
            .fill(Color.white.opacity(0.045))
            .overlay(Circle().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
            .frame(width: side, height: side)
            .shadow(color: .black.opacity(0.35), radius: side * 0.04, x: 0, y: side * 0.012)
    }

    private func ticks(side: CGFloat) -> some View {
        ZStack {
            ForEach(0..<60, id: \.self) { i in
                let major = i % 5 == 0
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(major ? 0.55 : 0.20))
                    .frame(
                        width:  side * (major ? 0.009 : 0.006),
                        height: side * (major ? 0.046 : 0.026)
                    )
                    .offset(y: -side * 0.452)
                    .rotationEffect(.degrees(Double(i) * 6))
            }
        }
        .frame(width: side, height: side)
    }

    private func hub(side: CGFloat) -> some View {
        let diameter = side * 0.34
        return ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8))
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.30), radius: side * 0.012, x: 0, y: side * 0.004)

            Text(ClockDisplayView.formatTimer(seconds: state.timerRemaining))
                .font(.system(size: side * 0.11, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, side * 0.02)
        }
    }
}

/// A filled pie slice from the center. `fraction` is 0...1; the wedge starts at
/// the top and sweeps counterclockwise, so a full timer is a full disk.
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
