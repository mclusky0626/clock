import SwiftUI

#if canImport(WebKit)
import WebKit
#endif

struct HTMLWidgetView: View {
    let settings: HTMLWidgetSettings
    let language: AppLanguage

    var body: some View {
        #if os(macOS)
        MacHTMLWidgetView(settings: settings, language: language)
            .background(Color.black.opacity(0.001))
        #else
        VStack(spacing: 8) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 30, weight: .semibold))
            Text("HTML")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
            Text(settings.displayName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        #endif
    }
}

#if os(macOS)
private struct MacHTMLWidgetView: NSViewRepresentable {
    let settings: HTMLWidgetSettings
    let language: AppLanguage

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let pagePreferences = WKWebpagePreferences()
        pagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = pagePreferences
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.attach(webView)
        context.coordinator.update(settings: settings, language: language)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.update(settings: settings, language: language)
    }

    static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        coordinator.stop()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private weak var webView: WKWebView?
        private var timer: Timer?
        private var currentSignature: Signature?
        private var language: AppLanguage = .korean
        private let encoder = JSONEncoder()
        private let isoFormatter = ISO8601DateFormatter()

        func attach(_ webView: WKWebView) {
            self.webView = webView
            start()
        }

        func update(settings: HTMLWidgetSettings, language: AppLanguage) {
            self.language = language
            let signature = Signature(settings: settings)
            if signature != currentSignature {
                currentSignature = signature
                load(settings: settings)
            }
            sendTick()
        }

        func stop() {
            timer?.invalidate()
            timer = nil
        }

        private func start() {
            stop()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.sendTick()
            }
        }

        private func load(settings: HTMLWidgetSettings) {
            guard let webView else { return }
            let root = AppState.htmlBundleURL(id: settings.resourceID)
            let entry = root.appendingPathComponent(settings.entryFileName)
            let userContent = webView.configuration.userContentController
            userContent.removeAllUserScripts()
            userContent.addUserScript(WKUserScript(
                source: Self.clockBridgeScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            ))
            if !settings.allowsNetwork {
                userContent.addUserScript(WKUserScript(
                    source: Self.networkBlockScript,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: false
                ))
            }

            if FileManager.default.fileExists(atPath: entry.path) {
                webView.loadFileURL(entry, allowingReadAccessTo: root)
            } else {
                webView.loadHTMLString(Self.missingHTML(name: settings.displayName), baseURL: nil)
            }
        }

        private func sendTick() {
            guard let webView else { return }
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute, .second], from: date)
            let payload = HTMLClockPayload(
                iso: isoFormatter.string(from: date),
                timestamp: date.timeIntervalSince1970,
                hours: components.hour ?? 0,
                minutes: components.minute ?? 0,
                seconds: components.second ?? 0,
                locale: language == .korean ? "ko_KR" : "en_US",
                timezone: TimeZone.current.identifier
            )
            guard let data = try? encoder.encode(payload),
                  let json = String(data: data, encoding: .utf8) else { return }
            webView.evaluateJavaScript("window.__clockApply && window.__clockApply(\(json));", completionHandler: nil)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard currentSignature?.allowsNetwork == false,
                  let scheme = navigationAction.request.url?.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                decisionHandler(.allow)
                return
            }
            decisionHandler(.cancel)
        }

        private struct Signature: Equatable {
            var resourceID: UUID
            var entryFileName: String
            var allowsNetwork: Bool
            var reloadNonce: Int

            init(settings: HTMLWidgetSettings) {
                resourceID = settings.resourceID
                entryFileName = settings.entryFileName
                allowsNetwork = settings.allowsNetwork
                reloadNonce = settings.reloadNonce
            }
        }

        private struct HTMLClockPayload: Encodable {
            var iso: String
            var timestamp: Double
            var hours: Int
            var minutes: Int
            var seconds: Int
            var locale: String
            var timezone: String
        }

        private static let clockBridgeScript = """
        window.clock = window.clock || {};
        window.__clockApply = function(detail) {
          window.clock = Object.assign({}, detail);
          window.dispatchEvent(new CustomEvent('clock-tick', { detail: detail }));
        };
        """

        private static let networkBlockScript = """
        window.fetch = function() {
          return Promise.reject(new Error('Network access is disabled for this HTML widget.'));
        };
        window.XMLHttpRequest = function() {
          throw new Error('Network access is disabled for this HTML widget.');
        };
        """

        private static func missingHTML(name: String) -> String {
            """
            <!doctype html>
            <html>
              <body style="margin:0;background:transparent;color:white;font:16px -apple-system;display:grid;place-items:center;height:100vh;">
                <div>Missing HTML: \(name)</div>
              </body>
            </html>
            """
        }
    }
}
#endif
