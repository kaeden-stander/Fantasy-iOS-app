import SwiftUI
import WebKit

/// Shows ESPN's own login page in a WKWebView and watches its cookie store for the SWID
/// and espn_s2 cookies ESPN sets once sign-in succeeds. There's no OAuth flow for ESPN's
/// fantasy API, so this is the standard way third-party apps get session cookies without
/// ever handling the user's ESPN password themselves.
///
/// ESPN's login widget authenticates in the background rather than doing a full page
/// navigation, so we can't rely solely on WKNavigationDelegate callbacks to know when
/// sign-in finished — this polls the cookie store on a timer as well.
struct ESPNAuthWebView: View {
    let onCredentialsCaptured: (ESPNCredentials) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ESPNAuthWebViewRepresentable(onCredentialsCaptured: onCredentialsCaptured)
                .navigationTitle("Log in to ESPN")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
    }
}

private struct ESPNAuthWebViewRepresentable: UIViewRepresentable {
    let onCredentialsCaptured: (ESPNCredentials) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "https://www.espn.com/login")!))
        context.coordinator.startPolling(webView: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCredentialsCaptured: onCredentialsCaptured)
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.stopPolling()
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onCredentialsCaptured: (ESPNCredentials) -> Void
        private var didCapture = false
        private var pollTimer: Timer?

        init(onCredentialsCaptured: @escaping (ESPNCredentials) -> Void) {
            self.onCredentialsCaptured = onCredentialsCaptured
        }

        func startPolling(webView: WKWebView) {
            pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self, weak webView] _ in
                guard let self, let webView else { return }
                self.checkForCredentials(in: webView)
            }
        }

        func stopPolling() {
            pollTimer?.invalidate()
            pollTimer = nil
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            checkForCredentials(in: webView)
        }

        private func checkForCredentials(in webView: WKWebView) {
            guard !didCapture else { return }
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                guard let self, !self.didCapture else { return }
                guard
                    let swid = cookies.first(where: { $0.name == "SWID" }),
                    let espnS2 = cookies.first(where: { $0.name == "espn_s2" })
                else { return }
                self.didCapture = true
                self.stopPolling()
                let credentials = ESPNCredentials(swid: swid.value, espnS2: espnS2.value)
                DispatchQueue.main.async {
                    self.onCredentialsCaptured(credentials)
                }
            }
        }
    }
}
