import SwiftUI

#if canImport(AppKit)
import AppKit
/// The native bitmap image type for the current platform.
typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#endif

// MARK: - Image bridging

extension Image {
    /// Builds a SwiftUI `Image` from the platform-native bitmap type.
    init(platformImage: PlatformImage) {
        #if canImport(AppKit)
        self.init(nsImage: platformImage)
        #else
        self.init(uiImage: platformImage)
        #endif
    }
}

extension PlatformImage {
    /// Loads a bitmap from disk on either platform.
    static func load(contentsOf url: URL) -> PlatformImage? {
        #if canImport(AppKit)
        return NSImage(contentsOf: url)
        #else
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
        #endif
    }

    /// Encodes the image to PNG on either platform.
    func pngDataCompat() -> Data? {
        #if canImport(AppKit)
        guard let tiff = tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
        #else
        return pngData()
        #endif
    }
}

// MARK: - Color components

extension Color {
    /// sRGB components, resolved through the platform color type. Used for
    /// persistence and interpolation so the same code works on macOS and iOS.
    var platformRGBA: (r: Double, g: Double, b: Double, a: Double) {
        #if canImport(AppKit)
        let n = NSColor(self).usingColorSpace(.sRGB) ?? .black
        return (Double(n.redComponent), Double(n.greenComponent),
                Double(n.blueComponent), Double(n.alphaComponent))
        #else
        let u = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        u.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
        #endif
    }
}

// MARK: - Frosted "behind content" background

/// A frosted translucency layer. On macOS this is a true behind-window blur so the
/// desktop shows through; on iOS (no window transparency) it falls back to a system
/// material.
struct FrostedBackground: View {
    var body: some View {
        #if canImport(AppKit)
        VisualEffectBackground(material: .hudWindow, blending: .behindWindow)
        #else
        Rectangle().fill(.ultraThinMaterial)
        #endif
    }
}

// MARK: - Platform-only view chrome (no-ops on the other platform)

extension View {
    /// Applies macOS window configuration (pin level, transparency). No-op on iOS,
    /// where apps can't float above or punch through to the wallpaper.
    @ViewBuilder
    func windowConfigurator(_ state: AppState) -> some View {
        #if os(macOS)
        self.background(
            WindowAccessor { window in
                WindowPinning.apply(state.alwaysOnTop, to: window)
                WindowAppearance.apply(transparent: state.backgroundMode.needsTransparentWindow,
                                       to: window)
            }
        )
        #else
        self
        #endif
    }

    /// macOS borderless menu chrome. No-op on iOS, which uses the default menu look.
    @ViewBuilder
    func macMenuChrome() -> some View {
        #if os(macOS)
        self.menuStyle(.borderlessButton).menuIndicator(.hidden)
        #else
        self
        #endif
    }
}
