import SwiftUI
import WebKit

/// Wraps a WebKit web view to show the Quartz preview served by
/// `preview.sh` on localhost.
struct WebPreviewView: NSViewRepresentable {

    // MARK: - Stored properties

    let url: URL

    // MARK: - Functions

    func makeNSView(context: Context) -> WKWebView {
        let webView: WKWebView = WKWebView()
        webView.setAccessibilityIdentifier("previewWebViewNative")
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}
