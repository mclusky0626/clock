import SwiftUI
import UniformTypeIdentifiers

struct TopToolbar: View {
    @Environment(AppState.self) private var state

    private let elementHeight: CGFloat = 30

    var body: some View {
        @Bindable var bindableState = state

        GlassPanel(cornerRadius: 20) {
            HStack(alignment: .center, spacing: 8) {
                ModeSegment(elementHeight: elementHeight)
                    .environment(state)

                Divider().frame(height: 18).opacity(0.4)

                Menu {
                    Button {
                        state.presentPhotoPicker()
                    } label: {
                        Label(state.t(.photo), systemImage: "photo")
                    }
                    Menu {
                        Button {
                            state.addWeather(.auto)
                        } label: {
                            Label(WeatherKind.auto.displayName(state.language), systemImage: WeatherKind.auto.sfSymbol)
                        }
                        Divider()
                        ForEach(WeatherKind.manualCases) { k in
                            Button {
                                state.addWeather(k)
                            } label: {
                                Label(k.displayName(state.language), systemImage: k.sfSymbol)
                            }
                        }
                    } label: {
                        Label(state.t(.weather), systemImage: "cloud.sun.fill")
                    }
                    Menu {
                        ForEach(WidgetKind.allCases) { w in
                            Button {
                                state.addWidget(w)
                            } label: {
                                Label(w.displayName(state.language), systemImage: w.sfSymbol)
                            }
                        }
                    } label: {
                        Label(state.t(.widget), systemImage: "rectangle.on.rectangle.angled")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primary)
                        .frame(height: elementHeight)
                        .padding(.horizontal, 12)
                        .glassControlChip(cornerRadius: 10)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help(state.t(.add))

                Button {
                    state.presentBackgroundImagePicker()
                } label: {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                }
                .buttonStyle(GlassButtonStyle())
                .frame(height: elementHeight)
                .help(state.t(.background))

                if state.backgroundImageID != nil {
                    Button {
                        state.clearBackgroundImage()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(GlassButtonStyle())
                    .frame(height: elementHeight)
                    .help(state.t(.removeBgImage))
                }

                ColorPicker("", selection: $bindableState.backgroundColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(height: elementHeight)
                    .help(state.t(.bgColor))

                Spacer(minLength: 8)

                Button {
                    state.alwaysOnTop.toggle()
                } label: {
                    Image(systemName: state.alwaysOnTop ? "pin.fill" : "pin")
                        .rotationEffect(.degrees(state.alwaysOnTop ? 0 : -30))
                }
                .buttonStyle(GlassButtonStyle(prominent: state.alwaysOnTop))
                .frame(height: elementHeight)
                .help(state.alwaysOnTop ? state.t(.pinOn) : state.t(.pinOff))

                Button {
                    state.inspectorVisible.toggle()
                } label: {
                    Image(systemName: state.inspectorVisible
                          ? "sidebar.trailing"
                          : "sidebar.right")
                }
                .buttonStyle(GlassButtonStyle())
                .frame(height: elementHeight)
                .help(state.inspectorVisible ? state.t(.closeStylePanel) : state.t(.openStylePanel))

                Button {
                    state.chromeVisible = false
                } label: {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(GlassButtonStyle(prominent: true))
                .frame(height: elementHeight)
                .help(state.t(.hideUI))
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
                        Text(mode.display(state.language))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: elementHeight - 4)
                    .padding(.horizontal, 8)
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
        .frame(width: 150, height: elementHeight)
        .glassControlChip(cornerRadius: 11)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: state.mode)
    }
}
