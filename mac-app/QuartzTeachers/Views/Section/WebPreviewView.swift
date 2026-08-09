import SwiftUI
import WebKit

/// Wraps the preview controller's WebKit web view to show the Quartz
/// preview served by `preview.sh` on localhost.
struct WebPreviewView: NSViewRepresentable {

    // MARK: - Stored properties

    let controller: WebPreviewController
    let url: URL

    // MARK: - Functions

    func makeNSView(context: Context) -> WKWebView {
        controller.loadIfNeeded(url)
        return controller.webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        controller.loadIfNeeded(url)
    }
}
