import SwiftUI

struct CanvasView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        GeometryReader { geo in
            let logical = AppState.logicalCanvasSize
            let scale = min(geo.size.width / logical.width, geo.size.height / logical.height)

            ZStack {
                ForEach(state.items.sorted(by: { $0.transform.zIndex < $1.transform.zIndex })) { item in
                    CanvasItemView(itemID: item.id)
                }
                TimerTicker()
            }
            .frame(width: logical.width, height: logical.height)
            .scaleEffect(scale)
            .frame(width: geo.size.width, height: geo.size.height)
            .background(backgroundLayer.ignoresSafeArea())
            .overlay {
                if state.backgroundMode == .glassOutline {
                    glassOutline.ignoresSafeArea()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                state.selectedID = nil
            }
            .focusable()
            .focusEffectDisabled()
            .onKeyPress(.delete) {
                state.deleteSelected()
                return .handled
            }
            .onKeyPress(.deleteForward) {
                state.deleteSelected()
                return .handled
            }
            .onKeyPress(.leftArrow)  { nudge(dx: -1, dy:  0) }
            .onKeyPress(.rightArrow) { nudge(dx:  1, dy:  0) }
            .onKeyPress(.upArrow)    { nudge(dx:  0, dy: -1) }
            .onKeyPress(.downArrow)  { nudge(dx:  0, dy:  1) }
        }
    }

    private func nudge(dx: CGFloat, dy: CGFloat) -> KeyPress.Result {
        guard let id = state.selectedID, let i = state.index(of: id) else { return .ignored }
        state.items[i].transform.position.x += dx * 4
        state.items[i].transform.position.y += dy * 4
        return .handled
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch state.backgroundMode {
        case .color:
            if let bgID = state.backgroundImageID, let img = state.images[bgID] {
                Image(platformImage: img)
                    .resizable()
                    .scaledToFill()
            } else if state.autoTheme {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    let c = TimeTheme.colors(for: context.date)
                    LinearGradient(colors: [c.top, c.bottom], startPoint: .top, endPoint: .bottom)
                }
            } else {
                LinearGradient(
                    colors: [
                        state.backgroundColor,
                        state.backgroundColor.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        case .transparent:
            Color.clear
        case .translucent:
            FrostedBackground()
                .opacity(state.backgroundOpacity)
        case .glassOutline:
            Color.clear
        }
    }

    /// A liquid-glass border framing the window for the transparent "glass outline" mode.
    private var glassOutline: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.75),
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.45)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .shadow(color: .white.opacity(0.25), radius: 6)
            .padding(7)
            .allowsHitTesting(false)
    }
}
