import SwiftUI

struct CanvasItemView: View {
    @Environment(AppState.self) private var state
    let itemID: UUID

    @State private var dragStartPosition: CGPoint?
    @State private var resizeStartScale: CGFloat?

    var body: some View {
        if let idx = state.index(of: itemID) {
            let item = state.items[idx]
            let isSelected = state.selectedID == itemID
            let showChrome = isSelected && state.chromeVisible

            let scaledW = item.size.width * item.transform.scale
            let scaledH = item.size.height * item.transform.scale

            ZStack {
                content(for: item)
                    .frame(width: item.size.width, height: item.size.height)
                    .scaleEffect(item.transform.scale)
                    .frame(width: scaledW, height: scaledH)

                if showChrome {
                    selectionBorder(width: scaledW, height: scaledH)
                }
            }
            .frame(width: scaledW, height: scaledH)
            .overlay(alignment: .bottomTrailing) {
                if showChrome {
                    resizeHandle(idx: idx, item: item)
                        .offset(x: 8, y: 8)
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
            if let nsImage = state.images[imageID] {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: item.size.width, height: item.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: item.shadowRadius, x: 0, y: item.shadowRadius * 0.3)
                    .contentShape(RoundedRectangle(cornerRadius: item.cornerRadius, style: .continuous))
            } else {
                Color.gray.opacity(0.2)
            }
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

    private func resizeHandle(idx: Int, item: CanvasItem) -> some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.black.opacity(0.7))
            .frame(width: 18, height: 18)
            .background(
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            )
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if resizeStartScale == nil {
                            resizeStartScale = state.items[idx].transform.scale
                        }
                        guard let start = resizeStartScale else { return }
                        let base = state.items[idx].size
                        let startW = base.width * start
                        let newW = max(40, startW + value.translation.width)
                        let newScale = newW / max(base.width, 1)
                        state.items[idx].transform.scale = max(0.1, min(newScale, 6))
                    }
                    .onEnded { _ in
                        resizeStartScale = nil
                        state.scheduleSave()
                    }
            )
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
