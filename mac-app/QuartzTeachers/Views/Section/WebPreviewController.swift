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
    ///
    /// **The "if needed" is about SwiftUI, not about the site.** This is
    /// called from `updateNSView`, which SwiftUI may run at any moment for
    /// reasons of its own; without the check, a teacher who had clicked
    /// through to a lesson would be thrown back to the front page on the next
    /// redraw.
    ///
    /// What it must NOT mean is "this address has been seen before, so there
    /// is nothing new there". A preview keeps its port across a stop and a
    /// start, so a rebuilt site has exactly the same address as the old one —
    /// and comparing addresses meant the web view kept showing the pages it
    /// had, silently, no matter how many times the site was rebuilt. Whoever
    /// stops a preview now calls `forgetLoadedPage()`, which is the honest
    /// way to say "whatever is on screen is no longer the truth".
    ///
    /// The request also ignores WebKit's own cache. Everything here is served
    /// from localhost and rebuilt constantly, so a cached copy is never the
    /// one wanted — and a cache hit looks exactly like the bug above.
    func loadIfNeeded(_ url: URL) {
        if url == lastRequestedURL {
            return
        }
        lastRequestedURL = url
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
    }

    /// Says that what the web view is showing is no longer current, so the
    /// next request for the same address loads it again.
    func forgetLoadedPage() {
        lastRequestedURL = nil
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    /// Reload, going past the cache. The Reload button exists precisely
    /// because a teacher thinks the page is out of date, so serving them the
    /// copy they are already unhappy with is the one useless answer.
    func reload() {
        webView.reloadFromOrigin()
    }
}
