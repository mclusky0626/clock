import SwiftUI
import UniformTypeIdentifiers

struct TopToolbar: View {
    @Environment(AppState.self) private var state

    private let elementHeight: CGFloat = 30

    var body: some View {
        @Bindable var bindableState = state

        GlassPanel(cornerRadius: 20) {
            HStack(alignment: .center, spacing: 10) {
                ModeSegment(elementHeight: elementHeight)
                    .environment(state)

                Divider().frame(height: 18).opacity(0.4)

                Button {
                    state.presentPhotoPicker()
                } label: {
                    Label("사진 추가", systemImage: "photo.badge.plus")
                }
                .buttonStyle(GlassButtonStyle())
                .frame(height: elementHeight)

                Button {
                    state.presentBackgroundImagePicker()
                } label: {
                    Label("배경", systemImage: "photo.fill.on.rectangle.fill")
                }
                .buttonStyle(GlassButtonStyle())
                .frame(height: elementHeight)

                if state.backgroundImageID != nil {
                    Button {
                        state.clearBackgroundImage()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(GlassButtonStyle())
                    .frame(height: elementHeight)
                    .help("배경 이미지 제거")
                }

                ColorPicker("", selection: $bindableState.backgroundColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(height: elementHeight)
                    .help("배경 색상")

                Spacer(minLength: 8)

                Button {
                    state.alwaysOnTop.toggle()
                } label: {
                    Image(systemName: state.alwaysOnTop ? "pin.fill" : "pin")
                        .rotationEffect(.degrees(state.alwaysOnTop ? 0 : -30))
                }
                .buttonStyle(GlassButtonStyle(prominent: state.alwaysOnTop))
                .frame(height: elementHeight)
                .help(state.alwaysOnTop ? "모든 앱 위에 고정 됨 — 다시 누르면 해제" : "모든 앱 위에 고정")

                Button {
                    state.inspectorVisible.toggle()
                } label: {
                    Image(systemName: state.inspectorVisible
                          ? "sidebar.trailing"
                          : "sidebar.right")
                }
                .buttonStyle(GlassButtonStyle())
                .frame(height: elementHeight)
                .help(state.inspectorVisible ? "스타일 패널 닫기" : "스타일 패널 열기")

                Button {
                    state.chromeVisible = false
                } label: {
                    Label("집중", systemImage: "eye.slash")
                }
                .buttonStyle(GlassButtonStyle(prominent: true))
                .frame(height: elementHeight)
                .help("전체 UI 숨기기 (ESC로 토글)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ModeSegment: View {
    @Environment(AppState.self) private var state
    let elementHeight: CGFloat

    var body: some View {
        HStack(spacing: 4) {
            ForEach(CanvasMode.allCases) { mode in
                let isOn = state.mode == mode
                Button {
                    state.mode = mode
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.symbol)
                            .font(.system(size: 12, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: elementHeight - 4)
                    .padding(.horizontal, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(isOn ? AnyShapeStyle(Color.white.opacity(0.95)) : AnyShapeStyle(Color.white.opacity(0.001)))
                    )
                    .foregroundStyle(isOn ? Color.black : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .frame(width: 200, height: elementHeight)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.6)
                )
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: state.mode)
    }
}
