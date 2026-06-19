import SwiftUI

struct TimerTicker: View {
    @Environment(AppState.self) private var state
    @State private var lastTick: Date = .now

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            Color.clear
                .frame(width: 0, height: 0)
                .onChange(of: context.date) { _, newDate in
                    if newDate.timeIntervalSince(lastTick) >= 0.95 {
                        if state.mode == .timer, state.timerRunning {
                            state.tickTimer()
                        }
                        state.tickWidgetTimers()
                        lastTick = newDate
                    }
                }
        }
        .allowsHitTesting(false)
    }
}
