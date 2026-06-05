import SwiftUI

// MARK: - Entry point

/// Renders a floating "glass widget" for the given kind. Each widget sits inside a
/// native Liquid Glass card so it reads as a translucent pane drifting above the
/// wallpaper, regardless of the canvas background mode.
struct WidgetView: View {
    let kind: WidgetKind

    var body: some View {
        switch kind {
        case .dateDay: DateWidgetView()
        }
    }
}

// MARK: - Date · Day

/// A minimal date card: the weekday on top, the full date beneath. Localized to the
/// app language and refreshed every minute so it always shows the correct day.
struct DateWidgetView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let r = h * 0.18

            TimelineView(.everyMinute) { context in
                VStack(spacing: max(2, h * 0.03)) {
                    Text(weekdayString(context.date))
                        .font(.system(size: h * 0.30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(dateString(context.date))
                        .font(.system(size: h * 0.135, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .shadow(color: .black.opacity(0.22), radius: h * 0.012, y: h * 0.006)
                .padding(.horizontal, h * 0.14)
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }

    // MARK: Formatting

    private var locale: Locale {
        Locale(identifier: state.language == .korean ? "ko_KR" : "en_US")
    }

    private func weekdayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        f.setLocalizedDateFormatFromTemplate("EEEE")
        return f.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = locale
        if state.language == .korean {
            f.dateFormat = "yyyy년 M월 d일"
        } else {
            f.dateStyle = .long
            f.timeStyle = .none
        }
        return f.string(from: date)
    }
}
