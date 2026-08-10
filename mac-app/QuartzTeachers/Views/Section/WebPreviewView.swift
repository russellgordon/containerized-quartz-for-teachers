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

    /// Take exactly the space offered — never dictate size.
    ///
    /// A web view can report its DOCUMENT height as its natural size. In
    /// a layout that sizes to its children, that makes the window's
    /// content taller than the window itself, which slides the whole
    /// interface (sidebar included) out of view.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: WKWebView, context: Context) -> CGSize? {
        return CGSize(
            width: proposal.width ?? 600,
            height: proposal.height ?? 400
        )
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        controller.loadIfNeeded(url)
    }
}
