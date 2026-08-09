import Foundation
import Observation
import WebKit

/// Owns the preview's web view and exposes its navigation state to
/// SwiftUI, so toolbar Back/Forward/Reload buttons can drive it and
/// enable/disable themselves correctly.
@Observable
class WebPreviewController {

    // MARK: - Stored properties

    /// The web view itself (created once and reused across page loads).
    let webView: WKWebView

    /// Mirrors the web view's navigation state for SwiftUI.
    var canGoBack: Bool = false
    var canGoForward: Bool = false

    /// The URL most recently asked for, so SwiftUI updates never reload
    /// a page the user has navigated away from.
    private var lastRequestedURL: URL?

    /// KVO subscriptions watching the web view's navigation state.
    private var observations: [NSKeyValueObservation] = []

    // MARK: - Initializer

    init() {
        let webView: WKWebView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.setAccessibilityIdentifier("previewWebViewNative")
        self.webView = webView

        let backObservation = webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.canGoBack = self.webView.canGoBack
            }
        }
        let forwardObservation = webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.canGoForward = self.webView.canGoForward
            }
        }
        observations.append(backObservation)
        observations.append(forwardObservation)
    }

    // MARK: - Functions

    /// Loads the URL if it is a new request (SwiftUI may call repeatedly).
    func loadIfNeeded(_ url: URL) {
        if url == lastRequestedURL {
            return
        }
        lastRequestedURL = url
        webView.load(URLRequest(url: url))
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func reload() {
        webView.reload()
    }
}
