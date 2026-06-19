import Foundation
import Combine
import SwiftUI

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct NowPlayingSnapshot {
    var title: String = ""
    var artist: String = ""
    var album: String = ""
    var artwork: PlatformImage?
    var duration: TimeInterval = 0
    var elapsed: TimeInterval = 0
    var isPlaying: Bool = false
    var updatedAt: Date = .now

    var hasContent: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || !artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || artwork != nil
    }
}

/// Streams system now-playing info. On macOS this runs the bundled `mediaremote-adapter`
/// through `/usr/bin/perl` (see `NowPlayingHelper`), which is the only way to read
/// now-playing on macOS 15.4+ from a third-party app — it captures Music, Spotify,
/// and browser media such as YouTube Music in Chrome. No-op on other platforms.
@MainActor
final class NowPlayingService: ObservableObject {
    static let shared = NowPlayingService()

    @Published private(set) var snapshot = NowPlayingSnapshot()

    private init() {}

    #if os(macOS)
    private var process: Process?
    private var wantsRunning = false
    private var buffer = Data()
    private var restartWorkItem: DispatchWorkItem?
    #endif

    func start() {
        #if os(macOS)
        wantsRunning = true
        guard process == nil else { return }
        launch()
        #endif
    }

    func stop() {
        #if os(macOS)
        wantsRunning = false
        restartWorkItem?.cancel()
        if let p = process {
            p.terminationHandler = nil
            p.terminate()
        }
        process = nil
        #endif
    }

    #if os(macOS)
    private func launch() {
        guard let paths = NowPlayingHelper.ensureInstalled() else { return }

        let p = Process()
        p.executableURL = paths.perl
        // --no-diff: every emission is the full current state (simpler to consume).
        p.arguments = [paths.script.path, paths.framework.path, "stream", "--no-diff"]

        let outPipe = Pipe()
        p.standardOutput = outPipe
        p.standardError = Pipe()   // discard helper logging

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let chunk = handle.availableData
            guard !chunk.isEmpty else { return }
            Task { @MainActor in self?.ingest(chunk) }
        }

        p.terminationHandler = { [weak self] _ in
            Task { @MainActor in self?.handleTermination() }
        }

        do {
            try p.run()
            process = p
        } catch {
            process = nil
            scheduleRestart()
        }
    }

    private func handleTermination() {
        process = nil
        buffer.removeAll(keepingCapacity: false)
        if wantsRunning { scheduleRestart() }
    }

    private func scheduleRestart() {
        guard wantsRunning else { return }
        restartWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                guard let self, self.wantsRunning, self.process == nil else { return }
                self.launch()
            }
        }
        restartWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
    }

    /// Buffers stdout and parses each complete newline-delimited JSON object.
    private func ingest(_ chunk: Data) {
        buffer.append(chunk)
        while let nl = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer[buffer.startIndex..<nl]
            buffer.removeSubrange(buffer.startIndex...nl)
            guard !lineData.isEmpty,
                  let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any]
            else { continue }
            // `stream` wraps the data as {type, diff, payload}; `get` is flat.
            let payload = (obj["payload"] as? [String: Any]) ?? obj
            apply(payload: payload)
        }
    }

    private func apply(payload: [String: Any]) {
        // An empty payload means no player is reporting now-playing info.
        guard !payload.isEmpty else {
            snapshot = NowPlayingSnapshot(updatedAt: .now)
            return
        }

        let title = payload["title"] as? String ?? ""
        let artist = payload["artist"] as? String ?? ""
        let album = payload["album"] as? String ?? ""
        let playing = (payload["playing"] as? Bool) ?? false
        let duration = (payload["duration"] as? NSNumber)?.doubleValue ?? 0
        let elapsed = (payload["elapsedTime"] as? NSNumber)?.doubleValue ?? 0
        let rate = (payload["playbackRate"] as? NSNumber)?.doubleValue ?? (playing ? 1 : 0)
        let timestamp = Self.parseTimestamp(payload["timestamp"] as? String)

        let now = Date()
        let correctedElapsed: TimeInterval = {
            guard rate > 0, let timestamp else { return elapsed }
            return min(max(elapsed + now.timeIntervalSince(timestamp) * rate, 0), max(duration, elapsed))
        }()

        // Artwork loads lazily and isn't always present; keep the previous image
        // while the same track is playing, and clear it when the track changes.
        var artwork = snapshot.artwork
        if let b64 = payload["artworkData"] as? String,
           let data = Data(base64Encoded: b64.filter { !$0.isWhitespace }),
           let image = PlatformImage.load(data: data) {
            artwork = image
        } else if title != snapshot.title {
            artwork = nil
        }

        snapshot = NowPlayingSnapshot(
            title: title,
            artist: artist,
            album: album,
            artwork: artwork,
            duration: duration,
            elapsed: correctedElapsed,
            isPlaying: playing,
            updatedAt: now
        )
    }

    private static func parseTimestamp(_ string: String?) -> Date? {
        guard let string else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }
    #endif
}

private extension PlatformImage {
    static func load(data: Data) -> PlatformImage? {
        #if canImport(AppKit)
        return NSImage(data: data)
        #elseif canImport(UIKit)
        return UIImage(data: data)
        #else
        return nil
        #endif
    }
}
