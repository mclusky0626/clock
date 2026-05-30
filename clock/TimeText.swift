import SwiftUI

enum SeparatorStyle: String, CaseIterable, Identifiable, Codable {
    case colon
    case dot
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .colon: return "콜론 ( : )"
        case .dot:   return "점 ( · )"
        }
    }
}

struct TimeText: View {
    let text: String
    let fontSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let color: Color
    let extraTracking: CGFloat
    let separator: SeparatorStyle

    var body: some View {
        HStack(spacing: extraTracking) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                cell(for: ch)
            }
        }
        .foregroundStyle(color)
        .shadow(color: .black.opacity(0.22), radius: fontSize * 0.06, x: 0, y: fontSize * 0.02)
    }

    @ViewBuilder
    private func cell(for ch: Character) -> some View {
        switch ch {
        case ":":
            separatorCell
                .frame(width: colonCellWidth, height: cellHeight)
        case "0"..."9":
            Text(String(ch))
                .font(.system(size: fontSize, weight: weight, design: design))
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize()
                .frame(width: digitCellWidth, height: cellHeight)
        case " ":
            Color.clear.frame(width: digitCellWidth * 0.4, height: cellHeight)
        default:
            Text(String(ch))
                .font(.system(size: fontSize * 0.55, weight: weight, design: design))
                .lineLimit(1)
                .fixedSize()
                .frame(height: cellHeight, alignment: .bottom)
                .padding(.bottom, fontSize * 0.04)
        }
    }

    @ViewBuilder
    private var separatorCell: some View {
        switch separator {
        case .colon:
            Text(":")
                .font(.system(size: fontSize, weight: weight, design: design))
                .lineLimit(1)
                .fixedSize()
                .offset(y: -fontSize * 0.04)
        case .dot:
            VStack(spacing: fontSize * 0.16) {
                Circle().frame(width: fontSize * 0.10, height: fontSize * 0.10)
                Circle().frame(width: fontSize * 0.10, height: fontSize * 0.10)
            }
            .offset(y: -fontSize * 0.06)
        }
    }

    var digitCellWidth: CGFloat { fontSize * 0.55 }
    var colonCellWidth: CGFloat { fontSize * 0.30 }
    var cellHeight: CGFloat { fontSize * 1.05 }

    static func naturalSize(
        text: String,
        fontSize: CGFloat,
        extraTracking: CGFloat
    ) -> CGSize {
        let digitW = fontSize * 0.55
        let colonW = fontSize * 0.30
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
        return CGSize(width: max(w, 40), height: fontSize * 1.05)
    }
}
