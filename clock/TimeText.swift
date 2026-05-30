import SwiftUI

enum SeparatorStyle: String, CaseIterable, Identifiable, Codable {
    case colon = "콜론  ( : )"
    case dot   = "점  ( · )"
    case space = "공백"
    case dash  = "대시  ( - )"
    var id: String { rawValue }
    var displayName: String { rawValue }

    func widthRatio() -> CGFloat {
        switch self {
        case .colon: return 0.30
        case .dot:   return 0.22
        case .space: return 0.18
        case .dash:  return 0.36
        }
    }
}

// MARK: - TimeText

struct TimeSlot: Identifiable, Equatable {
    enum Kind { case digit, separator, other }
    let id: String
    let position: Int
    let char: Character
    let kind: Kind

    init(position: Int, char: Character) {
        self.position = position
        self.char = char
        if char.isNumber {
            self.kind = .digit
            self.id = "d-\(position)-\(char)"
        } else if char == ":" {
            self.kind = .separator
            self.id = "s-\(position)"
        } else {
            self.kind = .other
            self.id = "o-\(position)-\(char)"
        }
    }
}

struct TimeText: View {
    let text: String
    let family: ClockFontFamily
    let weight: ClockWeight
    let fontSize: CGFloat
    let color: Color
    let extraTracking: CGFloat
    let stretchY: CGFloat
    let separator: SeparatorStyle
    let material: DigitMaterial
    let animation: DigitAnimation

    private var slots: [TimeSlot] {
        Array(text.enumerated()).map { TimeSlot(position: $0.offset, char: $0.element) }
    }

    var body: some View {
        let unscaledHeight = fontSize * 1.05
        HStack(spacing: extraTracking) {
            ForEach(slots) { slot in
                cell(for: slot)
                    .transition(animation.transition)
            }
        }
        .frame(height: unscaledHeight)
        .scaleEffect(x: 1, y: stretchY, anchor: .center)
        .frame(height: unscaledHeight * stretchY)
        .modifier(MaterialModifier(material: material, color: color, fontSize: fontSize))
        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: text)
    }

    @ViewBuilder
    private func cell(for slot: TimeSlot) -> some View {
        switch slot.kind {
        case .digit:
            digitCell(slot.char)
        case .separator:
            separatorCell
        case .other:
            otherCell(slot.char)
        }
    }

    private func digitCell(_ ch: Character) -> some View {
        Text(String(ch))
            .font(family.makeFont(size: fontSize, weight: weight))
            .lineLimit(1)
            .fixedSize()
            .frame(width: digitCellWidth, height: cellHeight, alignment: .center)
    }

    private func otherCell(_ ch: Character) -> some View {
        Text(String(ch))
            .font(family.makeFont(size: fontSize * 0.55, weight: weight))
            .lineLimit(1)
            .fixedSize()
            .frame(width: digitCellWidth, height: cellHeight, alignment: .bottom)
            .padding(.bottom, fontSize * 0.04)
    }

    @ViewBuilder
    private var separatorCell: some View {
        switch separator {
        case .colon:
            Text(":")
                .font(family.makeFont(size: fontSize, weight: weight))
                .lineLimit(1)
                .fixedSize()
                .frame(width: colonCellWidth, height: cellHeight)
                .offset(y: -fontSize * 0.04)
        case .dot:
            Circle()
                .frame(width: fontSize * 0.12, height: fontSize * 0.12)
                .frame(width: colonCellWidth, height: cellHeight, alignment: .center)
        case .space:
            Color.clear
                .frame(width: colonCellWidth, height: cellHeight)
        case .dash:
            RoundedRectangle(cornerRadius: fontSize * 0.04, style: .continuous)
                .frame(width: fontSize * 0.32, height: fontSize * 0.07)
                .frame(width: colonCellWidth, height: cellHeight, alignment: .center)
        }
    }

    var digitCellWidth: CGFloat { fontSize * 0.55 }
    var colonCellWidth: CGFloat { fontSize * separator.widthRatio() }
    var cellHeight: CGFloat { fontSize * 1.05 }

    // MARK: - Natural size

    static func naturalSize(
        text: String,
        fontSize: CGFloat,
        extraTracking: CGFloat,
        stretchY: CGFloat,
        separator: SeparatorStyle
    ) -> CGSize {
        let digitW = fontSize * 0.55
        let colonW = fontSize * separator.widthRatio()
        let otherW = fontSize * 0.55
        var w: CGFloat = 0
        let chars = Array(text)
        for (i, c) in chars.enumerated() {
            switch c {
            case ":":              w += colonW
            case "0"..."9":        w += digitW
            case " ":              w += digitW * 0.4
            default:               w += otherW
            }
            if i < chars.count - 1 { w += extraTracking }
        }
        return CGSize(width: max(w, 40), height: fontSize * 1.05 * stretchY)
    }
}

// MARK: - Material

struct MaterialModifier: ViewModifier {
    let material: DigitMaterial
    let color: Color
    let fontSize: CGFloat

    func body(content: Content) -> some View {
        switch material {
        case .solid:
            content
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.22), radius: fontSize * 0.05, x: 0, y: fontSize * 0.02)
        case .gradient:
            content
                .foregroundStyle(
                    LinearGradient(
                        colors: [color, color.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.25), radius: fontSize * 0.05, x: 0, y: fontSize * 0.02)
        case .glass:
            content
                .foregroundStyle(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.18), radius: fontSize * 0.04, x: 0, y: fontSize * 0.02)
        case .overlay:
            content
                .foregroundStyle(color)
                .blendMode(.overlay)
                .compositingGroup()
        }
    }
}

// MARK: - Transitions

extension DigitAnimation {
    var transition: AnyTransition {
        switch self {
        case .none:
            return .identity
        case .fade:
            return .opacity
        case .roll:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            )
        case .slideUp:
            return .asymmetric(
                insertion: .offset(y: 60).combined(with: .opacity),
                removal: .offset(y: -60).combined(with: .opacity)
            )
        case .slideDown:
            return .asymmetric(
                insertion: .offset(y: -60).combined(with: .opacity),
                removal: .offset(y: 60).combined(with: .opacity)
            )
        case .scale:
            return .scale(scale: 0.5, anchor: .center).combined(with: .opacity)
        case .flip:
            return .asymmetric(
                insertion: .modifier(
                    active: FlipModifier(degrees: 90),
                    identity: FlipModifier(degrees: 0)
                ).combined(with: .opacity),
                removal: .modifier(
                    active: FlipModifier(degrees: -90),
                    identity: FlipModifier(degrees: 0)
                ).combined(with: .opacity)
            )
        case .depth:
            return .asymmetric(
                insertion: .scale(scale: 1.3, anchor: .center).combined(with: .opacity),
                removal: .scale(scale: 0.7, anchor: .center).combined(with: .opacity)
            )
        case .blur:
            return .modifier(
                active: BlurModifier(radius: 12, opacity: 0),
                identity: BlurModifier(radius: 0, opacity: 1)
            )
        }
    }
}

struct FlipModifier: ViewModifier {
    let degrees: Double
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(degrees),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: 0.6
            )
    }
}

struct BlurModifier: ViewModifier {
    let radius: CGFloat
    let opacity: Double
    func body(content: Content) -> some View {
        content
            .blur(radius: radius)
            .opacity(opacity)
    }
}
