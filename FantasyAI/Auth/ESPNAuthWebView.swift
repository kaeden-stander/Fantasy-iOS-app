import SwiftUI
import WebKit

/// Shows ESPN's own login page in a WKWebView and watches the web view's cookie store for
/// the SWID and espn_s2 cookies ESPN sets once sign-in succeeds. There's no OAuth flow for
/// ESPN's fantasy API, so this is the standard way third-party apps get session cookies
/// without ever handling the user's ESPN password themselves.
struct ESPNAuthWebView: UIViewRepresentable {
    let onCredentialsCaptured: (ESPNCredentials) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: URL(string: "https://www.espn.com/login")!))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCredentialsCaptured: onCredentialsCaptured)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onCredentialsCaptured: (ESPNCredentials) -> Void
        private var didCapture = false

        init(onCredentialsCaptured: @escaping (ESPNCredentials) -> Void) {
            self.onCredentialsCaptured = onCredentialsCaptured
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !didCapture else { return }
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
                guard let self else { return }
                guard
                    let swid = cookies.first(where: { $0.name == "SWID" }),
                    let espnS2 = cookies.first(where: { $0.name == "espn_s2" })
                else { return }
                self.didCapture = true
                let credentials = ESPNCredentials(swid: swid.value, espnS2: espnS2.value)
                DispatchQueue.main.async {
                    self.onCredentialsCaptured(credentials)
                }
            }
        }
    }
}
