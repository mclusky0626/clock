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

/// A behind-window blur so the desktop/apps behind the (transparent) window show
/// through frosted — the real macOS translucency that SwiftUI materials don't give.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .active
        v.isEmphasized = false
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
        v.blendingMode = blending
    }
}

enum WindowAppearance {
    /// Makes the window itself transparent so the desktop/apps behind show through.
    static func apply(transparent: Bool, to window: NSWindow?) {
        guard let window else { return }
        if transparent {
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
        } else {
            window.isOpaque = true
            window.backgroundColor = .windowBackgroundColor
            window.hasShadow = true
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
