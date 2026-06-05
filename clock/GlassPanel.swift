import SwiftUI

/// The floating Liquid Glass layer that hosts navigation/controls above the
/// wallpaper content. Uses the native `glassEffect` so it picks up real-time
/// refraction, lighting and the system's accessibility adaptations.
///
/// Per Apple's "Adopting Liquid Glass" guidance, glass is reserved for this
/// floating layer — controls placed *inside* it should not themselves be glass
/// (that would stack glass on glass). Use `glassControlChip` for those.
struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 22
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

/// A subtle control surface for buttons/segments that live *inside* a glass
/// panel. Solid (not glass) on purpose, so we never layer glass on glass.
extension View {
    @ViewBuilder
    func glassControlChip(cornerRadius: CGFloat = 10, prominent: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(prominent
                          ? AnyShapeStyle(Color.accentColor)
                          : AnyShapeStyle(Color.white.opacity(0.10)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(prominent ? 0.0 : 0.12), lineWidth: 0.6)
            )
    }
}

/// Buttons rendered inside a glass panel. Subtle by default, accent-filled when
/// prominent. Kept as a named style so existing call sites stay unchanged.
struct GlassButtonStyle: ButtonStyle {
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .glassControlChip(prominent: prominent)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
