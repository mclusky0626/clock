import SwiftUI

@main
struct clockApp: App {
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
