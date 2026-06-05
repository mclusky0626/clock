import SwiftUI

/// A single 7-segment numeral. Bar *thickness* depends only on the cell width, so
/// stretching the cell vertically elongates just the straight vertical bars — the
/// proportions never distort (iPhone-style ratio-preserving stretch).
struct SegmentDigit: Shape {
    var digit: Character

    // Segment layout:   a (top)
    //                 f      b
    //                   g (mid)
    //                 e      c
    //                   d (bottom)
    static let map: [Character: Set<Character>] = [
        "0": ["a", "b", "c", "d", "e", "f"],
        "1": ["b", "c"],
        "2": ["a", "b", "g", "e", "d"],
        "3": ["a", "b", "g", "c", "d"],
        "4": ["f", "g", "b", "c"],
        "5": ["a", "f", "g", "c", "d"],
        "6": ["a", "f", "g", "e", "c", "d"],
        "7": ["a", "b", "c"],
        "8": ["a", "b", "c", "d", "e", "f", "g"],
        "9": ["a", "b", "c", "d", "f", "g"]
    ]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let t = w * 0.18                 // bar thickness — width-driven, so stretch keeps it constant
        let g = t * 0.30                 // gap between segments
        let segs = Self.map[digit] ?? []
        let hLen = w - 2 * t             // horizontal bar length (between the verticals)
        let vLen = (h - 3 * t) / 2       // vertical bar length (grows when stretched)

        func bar(_ x: CGFloat, _ y: CGFloat, _ bw: CGFloat, _ bh: CGFloat) {
            guard bw > 0.5, bh > 0.5 else { return }
            let r = min(bw, bh) / 2
            p.addRoundedRect(
                in: CGRect(x: rect.minX + x, y: rect.minY + y, width: bw, height: bh),
                cornerSize: CGSize(width: r, height: r),
                style: .continuous
            )
        }

        // Horizontal bars (inset along x for gaps)
        if segs.contains("a") { bar(t + g, 0,             hLen - 2 * g, t) }
        if segs.contains("g") { bar(t + g, (h - t) / 2,   hLen - 2 * g, t) }
        if segs.contains("d") { bar(t + g, h - t,         hLen - 2 * g, t) }
        // Vertical bars (inset along y for gaps)
        if segs.contains("f") { bar(0,     t + g,         t, vLen - 2 * g) }
        if segs.contains("b") { bar(w - t, t + g,         t, vLen - 2 * g) }
        if segs.contains("e") { bar(0,     (h + t) / 2 + g, t, vLen - 2 * g) }
        if segs.contains("c") { bar(w - t, (h + t) / 2 + g, t, vLen - 2 * g) }
        return p
    }
}

/// The two-dot separator for segment numerals.
struct SegmentColon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let d = min(rect.width, rect.height * 0.16)
        let cx = rect.midX
        for fy in [0.36, 0.64] {
            let cy = rect.minY + rect.height * fy
            p.addEllipse(in: CGRect(x: cx - d / 2, y: cy - d / 2, width: d, height: d))
        }
        return p
    }
}

/// Lays out a time string as 7-segment numerals.
struct SegmentTimeView: View {
    let text: String
    let color: Color
    let fontSize: CGFloat
    let stretchY: CGFloat
    let tracking: CGFloat
    let separator: SeparatorStyle

    private var cellHeight: CGFloat { fontSize * 1.05 * stretchY }
    private var digitWidth: CGFloat { fontSize * 0.55 }
    private var colonWidth: CGFloat { fontSize * separator.widthRatio() }

    var body: some View {
        HStack(spacing: tracking) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, ch in
                cell(ch)
            }
        }
        .foregroundStyle(
            LinearGradient(colors: [color, color.opacity(0.78)], startPoint: .top, endPoint: .bottom)
        )
        .shadow(color: .black.opacity(0.25), radius: fontSize * 0.04, x: 0, y: fontSize * 0.018)
    }

    @ViewBuilder
    private func cell(_ ch: Character) -> some View {
        if ch == ":" {
            SegmentColon()
                .frame(width: colonWidth, height: cellHeight)
        } else if ch.isNumber {
            SegmentDigit(digit: ch)
                .frame(width: digitWidth, height: cellHeight)
        } else {
            Color.clear.frame(width: digitWidth * 0.5, height: cellHeight)
        }
    }

    static func naturalSize(
        text: String,
        fontSize: CGFloat,
        stretchY: CGFloat,
        separator: SeparatorStyle,
        tracking: CGFloat
    ) -> CGSize {
        let digitW = fontSize * 0.55
        let colonW = fontSize * separator.widthRatio()
        var w: CGFloat = 0
        let chars = Array(text)
        for (i, c) in chars.enumerated() {
            w += (c == ":") ? colonW : (c.isNumber ? digitW : digitW * 0.5)
            if i < chars.count - 1 { w += tracking }
        }
        return CGSize(width: max(w, 40), height: fontSize * 1.05 * stretchY)
    }
}
