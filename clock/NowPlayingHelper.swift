#if os(macOS)
import Foundation

/// Installs and locates the bundled `mediaremote-adapter` helper.
///
/// macOS 15.4+ blocks `MRMediaRemoteGetNowPlayingInfo` for non-Apple binaries, so
/// reading system now-playing (incl. Chrome / YouTube Music) requires running the
/// helper through `/usr/bin/perl` — an Apple platform binary that passes the check.
/// The helper (BSD-3, vendored in `clock/Vendor/mediaremote-adapter.zip`) is
/// extracted to Application Support on first use. Requires the app to be un-sandboxed.
enum NowPlayingHelper {
    struct Paths {
        let perl: URL
        let script: URL      // mediaremote-adapter.pl
        let framework: URL   // MediaRemoteAdapter.framework
    }

    /// Bump when the bundled zip changes, to force re-extraction.
    private static let version = "1"

    private static var installDir: URL {
        let base = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base
            .appendingPathComponent("ClockWallpaper", isDirectory: true)
            .appendingPathComponent("mediaremote-adapter", isDirectory: true)
    }

    /// Ensures the helper is extracted and returns its paths, or nil if unavailable.
    static func ensureInstalled() -> Paths? {
        let perl = URL(fileURLWithPath: "/usr/bin/perl")
        guard FileManager.default.isExecutableFile(atPath: perl.path) else { return nil }

        let dir = installDir
        let script = dir.appendingPathComponent("mediaremote-adapter.pl")
        let framework = dir.appendingPathComponent("MediaRemoteAdapter.framework")
        let marker = dir.appendingPathComponent(".version")

        let upToDate = (try? String(contentsOf: marker, encoding: .utf8)) == version
            && FileManager.default.fileExists(atPath: script.path)
            && FileManager.default.fileExists(atPath: framework.path)

        if !upToDate {
            guard extractBundle(to: dir) else { return nil }
            try? version.write(to: marker, atomically: true, encoding: .utf8)
        }

        guard FileManager.default.fileExists(atPath: script.path),
              FileManager.default.fileExists(atPath: framework.path) else { return nil }
        return Paths(perl: perl, script: script, framework: framework)
    }

    /// Extracts the bundled zip with `ditto` (preserves the framework's symlinks).
    private static func extractBundle(to dir: URL) -> Bool {
        guard let zip = Bundle.main.url(forResource: "mediaremote-adapter", withExtension: "zip") else {
            return false
        }
        let fm = FileManager.default
        try? fm.removeItem(at: dir)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        p.arguments = ["-x", "-k", zip.path, dir.path]
        do {
            try p.run()
            p.waitUntilExit()
            return p.terminationStatus == 0
        } catch {
            return false
        }
    }
}
#endif
