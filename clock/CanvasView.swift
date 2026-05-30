import SwiftUI

struct CanvasView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ZStack {
            ForEach(state.items.sorted(by: { $0.transform.zIndex < $1.transform.zIndex })) { item in
                CanvasItemView(itemID: item.id)
            }
            TimerTicker()
        }
        .background(backgroundLayer.ignoresSafeArea())
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

    private func nudge(dx: CGFloat, dy: CGFloat) -> KeyPress.Result {
        guard let id = state.selectedID, let i = state.index(of: id) else { return .ignored }
        state.items[i].transform.position.x += dx * 4
        state.items[i].transform.position.y += dy * 4
        return .handled
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        if let bgID = state.backgroundImageID, let img = state.images[bgID] {
            Image(nsImage: img)
                .resizable()
                .scaledToFill()
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
    }
}
