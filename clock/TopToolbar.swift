import SwiftUI
import UniformTypeIdentifiers

struct TopToolbar: View {
    @Environment(AppState.self) private var state

    var body: some View {
        @Bindable var bindableState = state

        GlassPanel(cornerRadius: 20) {
            HStack(spacing: 12) {
                Picker("", selection: $bindableState.mode) {
                    ForEach(CanvasMode.allCases) { mode in
                        Label(mode.rawValue, systemImage: mode.symbol).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .labelsHidden()

                Divider().frame(height: 18).opacity(0.4)

                Button {
                    state.presentPhotoPicker()
                } label: {
                    Label("사진 추가", systemImage: "photo.badge.plus")
                }
                .buttonStyle(GlassButtonStyle())

                Button {
                    state.presentBackgroundImagePicker()
                } label: {
                    Label("배경", systemImage: "photo.fill.on.rectangle.fill")
                }
                .buttonStyle(GlassButtonStyle())

                if state.backgroundImageID != nil {
                    Button {
                        state.clearBackgroundImage()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(GlassButtonStyle())
                    .help("배경 이미지 제거")
                }

                ColorPicker("", selection: $bindableState.backgroundColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 22, height: 22)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.6)
                            )
                    )
                    .help("배경 색상")

                Spacer(minLength: 8)

                Button {
                    state.inspectorVisible.toggle()
                } label: {
                    Image(systemName: state.inspectorVisible
                          ? "sidebar.trailing"
                          : "sidebar.right")
                }
                .buttonStyle(GlassButtonStyle())
                .help(state.inspectorVisible ? "스타일 패널 닫기" : "스타일 패널 열기")

                Button {
                    state.chromeVisible = false
                } label: {
                    Label("집중", systemImage: "eye.slash")
                }
                .buttonStyle(GlassButtonStyle(prominent: true))
                .help("전체 UI 숨기기 (ESC로 토글)")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
