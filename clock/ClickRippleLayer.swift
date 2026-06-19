import SwiftUI

struct ClickRippleEvent: Identifiable, Equatable {
    let id = UUID()
    var point: CGPoint
}

struct ClickRippleLayer: View {
    let ripples: [ClickRippleEvent]
    let settings: ClickRippleSettings

    var body: some View {
        ZStack {
            ForEach(ripples) { ripple in
                ClickRippleView(ripple: ripple, settings: settings)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct ClickRippleView: View {
    let ripple: ClickRippleEvent
    let settings: ClickRippleSettings

    @State private var progress: CGFloat = 0

    var body: some View {
        let intensity = CGFloat(settings.intensity)
        let eased = max(0.001, progress)
        let fade = max(0, 1 - progress)
        let diameter = max(12, settings.radius * 2 * eased)

        ZStack {
            Circle()
                .fill(Color.white.opacity(0.08 * Double(intensity) * Double(fade)))
                .glassEffect(.regular, in: Circle())
                .blur(radius: 10 * intensity * eased)

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.75 * Double(fade)),
                            Color.white.opacity(0.16 * Double(fade)),
                            Color.white.opacity(0.42 * Double(fade))
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1, 4 * intensity * fade)
                )

            Circle()
                .strokeBorder(Color.white.opacity(0.22 * Double(fade)), lineWidth: max(0.8, 1.4 * intensity))
                .scaleEffect(0.66)
                .blur(radius: 4 * intensity)
        }
        .frame(width: diameter, height: diameter)
        .opacity(Double(fade))
        .position(ripple.point)
        .onAppear {
            withAnimation(.easeOut(duration: settings.duration)) {
                progress = 1
            }
        }
    }
}
