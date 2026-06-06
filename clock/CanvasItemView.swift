import SwiftUI

struct CanvasItemView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    @State private var dragStartPosition: CGPoint?
    // Stored as (startScaleX, startScaleY) for all resize gestures
    @State private var resizeStart: CGPoint?   // x = scaleX, y = scaleY at drag start

    var body: some View {
        if let idx = state.index(of: itemID) {
            let item = state.items[idx]
            let isSelected = state.selectedID == itemID
            let showChrome = isSelected && state.chromeVisible

            let sx = item.transform.scaleX
            let sy = item.transform.scaleY
            let scaledW = item.size.width  * sx
            let scaledH = item.size.height * sy

            ZStack {
                content(for: item)
                    .frame(width: item.size.width, height: item.size.height)
                    .scaleEffect(x: sx, y: sy)
                    .frame(width: scaledW, height: scaledH)

                if showChrome {
                    selectionBorder(width: scaledW, height: scaledH)
                }
            }
            .frame(width: scaledW, height: scaledH)
            // Corner — proportional (both axes)
            .overlay(alignment: .bottomTrailing) {
                if showChrome {
                    resizeHandle(symbol: "arrow.up.left.and.arrow.down.right")
                        .gesture(cornerDrag(naturalSize: item.size))
                        .offset(x: 8, y: 8)
                }
            }
            // Right edge — horizontal only
            .overlay(alignment: .trailing) {
                if showChrome {
                    resizeHandle(symbol: "arrow.left.and.right")
                        .gesture(edgeDrag(axis: .horizontal, naturalSize: item.size))
                        .offset(x: 8, y: 0)
                }
            }
            // Bottom edge — vertical only
            .overlay(alignment: .bottom) {
                if showChrome {
                    resizeHandle(symbol: "arrow.up.and.down")
                        .gesture(edgeDrag(axis: .vertical, naturalSize: item.size))
                        .offset(x: 0, y: 8)
                }
            }
            .rotationEffect(item.transform.rotation)
            .opacity(item.transform.opacity)
            .position(item.transform.position)
            .zIndex(item.transform.zIndex)
            .gesture(dragGesture(currentPosition: item.transform.position))
            .onTapGesture {
                state.selectedID = itemID
            }
        }
    }

    @ViewBuilder
    private func content(for item: CanvasItem) -> some View {
        switch item.kind {
        case .clock:
            ClockDisplayView()
                .frame(width: item.size.width, height: item.size.height)
                .contentShape(Rectangle())
        case .photo(let imageID):
            if let img = state.images[imageID] {
                Image(platformImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: item.size.width, height: item.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: item.shadowRadius, x: 0, y: item.shadowRadius * 0.3)
                    .contentShape(RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous))
            } else {
                Color.gray.opacity(0.2)
            }
        case .weather(let kind):
            WeatherStickerView(kind: kind)
                .frame(width: item.size.width, height: item.size.height)
                .contentShape(Rectangle())
        case .widget(let kind):
            WidgetView(kind: kind)
                .frame(width: item.size.width, height: item.size.height)
                .contentShape(Rectangle())
        }
    }

    private func selectionBorder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.25), lineWidth: 2)
                    .blur(radius: 1)
            )
            .frame(width: width, height: height)
            .allowsHitTesting(false)
    }

    private func resizeHandle(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(.black.opacity(0.7))
            .frame(width: 18, height: 18)
            .background(
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            )
            .contentShape(Circle())
    }

    // MARK: - Gestures

    /// Bottom-right corner: scales both X and Y proportionally from current ratio
    private func cornerDrag(naturalSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard let idx = state.index(of: itemID) else { return }
                if resizeStart == nil {
                    let t = state.items[idx].transform
                    resizeStart = CGPoint(x: t.scaleX, y: t.scaleY)
                }
                guard let start = resizeStart else { return }
                let startX = start.x, startY = start.y
                let visW = naturalSize.width  * startX
                let visH = naturalSize.height * startY
                let diagLen = max(1, sqrt(visW * visW + visH * visH))
                let ux = visW / diagLen, uy = visH / diagLen
                let delta = value.translation.width * ux + value.translation.height * uy
                let factor = max(0.05, (diagLen + delta) / diagLen)
                state.items[idx].transform.scaleX = max(0.05, min(startX * factor, 12))
                state.items[idx].transform.scaleY = max(0.05, min(startY * factor, 12))
            }
            .onEnded { _ in resizeStart = nil; state.scheduleSave() }
    }

    enum ResizeAxis { case horizontal, vertical }

    /// Side handles: change only one axis
    private func edgeDrag(axis: ResizeAxis, naturalSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard let idx = state.index(of: itemID) else { return }
                if resizeStart == nil {
                    let t = state.items[idx].transform
                    resizeStart = CGPoint(x: t.scaleX, y: t.scaleY)
                }
                guard let start = resizeStart else { return }
                switch axis {
                case .horizontal:
                    let startW = naturalSize.width * start.x
                    let newW = max(20, startW + value.translation.width)
                    state.items[idx].transform.scaleX = max(0.05, min(newW / max(naturalSize.width, 1), 12))
                case .vertical:
                    let startH = naturalSize.height * start.y
                    let newH = max(20, startH + value.translation.height)
                    state.items[idx].transform.scaleY = max(0.05, min(newH / max(naturalSize.height, 1), 12))
                }
            }
            .onEnded { _ in resizeStart = nil; state.scheduleSave() }
    }

    private func dragGesture(currentPosition: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if dragStartPosition == nil {
                    dragStartPosition = currentPosition
                    state.selectedID = itemID
                }
                guard let start = dragStartPosition, let idx = state.index(of: itemID) else { return }
                state.items[idx].transform.position = CGPoint(
                    x: start.x + value.translation.width,
                    y: start.y + value.translation.height
                )
            }
            .onEnded { _ in
                dragStartPosition = nil
                state.scheduleSave()
            }
    }
}
