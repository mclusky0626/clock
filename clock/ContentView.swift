import SwiftUI

struct ContentView: View {
    @State private var state = AppState()
    @State private var restorePillHover = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            CanvasView()
                .environment(state)

            if state.chromeVisible {
                VStack {
                    HStack {
                        Spacer()
                        TopToolbar()
                            .environment(state)
                            .padding(.top, 14)
                        Spacer()
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))

                HStack {
                    Spacer()
                    if state.inspectorVisible {
                        InspectorView()
                            .environment(state)
                            .padding(.trailing, 14)
                            .padding(.vertical, 14)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
            } else {
                restorePill
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: state.chromeVisible)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: state.inspectorVisible)
        .frame(minWidth: 900, minHeight: 600)
        .preferredColorScheme(.dark)
        .background(
            WindowAccessor { window in
                WindowPinning.apply(state.alwaysOnTop, to: window)
            }
        )
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(.escape) {
            state.chromeVisible.toggle()
            return .handled
        }
        .onChange(of: state.alwaysOnTop) { _, _ in
            state.scheduleSave()
        }
        .onChange(of: state.clockStyle) { _, _ in
            state.recomputeClockSize()
            state.scheduleSave()
        }
        .onChange(of: state.mode) { _, _ in
            state.recomputeClockSize()
            state.scheduleSave()
        }
        .onChange(of: state.backgroundColor) { _, _ in state.scheduleSave() }
        .onChange(of: state.timerDurationSeconds) { _, _ in state.scheduleSave() }
        .onChange(of: state.alarmVolume) { _, _ in state.scheduleSave() }
        .onChange(of: state.alarmChoice) { _, _ in state.scheduleSave() }
        .onChange(of: state.inspectorVisible) { _, _ in state.scheduleSave() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { state.saveNow() }
        }
    }

    private var restorePill: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    state.chromeVisible = true
                } label: {
                    Image(systemName: "eye")
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 0.6))
                                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                        .opacity(restorePillHover ? 1.0 : 0.35)
                }
                .buttonStyle(.plain)
                .onHover { restorePillHover = $0 }
                .help("UI 다시 보기 (ESC)")
                .padding(.top, 12)
                .padding(.trailing, 14)
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.18), value: restorePillHover)
    }
}

#Preview {
    ContentView()
        .frame(width: 1200, height: 760)
}
