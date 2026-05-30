import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { [weak v] in
            onResolve(v?.window)
        }
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            onResolve(nsView?.window)
        }
    }
}

enum WindowPinning {
    static func apply(_ pinned: Bool, to window: NSWindow?) {
        guard let window else { return }
        if pinned {
            window.level = .floating
            window.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary,
                .stationary
            ]
        } else {
            window.level = .normal
            window.collectionBehavior = [.fullScreenAuxiliary]
        }
    }
}
