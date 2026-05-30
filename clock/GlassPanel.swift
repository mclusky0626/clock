import SwiftUI

struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 22
    var tint: Color = .white
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.18),
                                        tint.opacity(0.04),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.55),
                                        Color.white.opacity(0.08),
                                        Color.white.opacity(0.25)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .shadow(color: .black.opacity(0.28), radius: 24, x: 0, y: 12)
                    .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct GlassButtonStyle: ButtonStyle {
    var prominent: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(prominent ? Color.black : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(prominent ? AnyShapeStyle(Color.white.opacity(0.95)) : AnyShapeStyle(.ultraThinMaterial))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(prominent ? 0.0 : 0.18), lineWidth: 0.6)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
