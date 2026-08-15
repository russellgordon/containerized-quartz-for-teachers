import WebKit
import XCTest
@testable import QuartzTeachers

final class WebPreviewControllerTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testFreshControllerHasNoHistoryAndGesturesEnabled() {
        let controller: WebPreviewController = WebPreviewController()
        XCTAssertFalse(controller.canGoBack)
        XCTAssertFalse(controller.canGoForward)
        XCTAssertTrue(controller.webView.allowsBackForwardNavigationGestures, "Trackpad swipe navigation should be enabled")
    }

    @MainActor
    func testLoadIfNeededIgnoresRepeatedRequestsForTheSameURL() {
        let controller: WebPreviewController = WebPreviewController()
        let url: URL = URL(string: "http://localhost:8081/")!
        controller.loadIfNeeded(url)
        let firstNavigationURL: URL? = controller.webView.url
        // A second identical request must not restart the load (which
        // would interrupt a teacher's navigation on SwiftUI updates).
        controller.loadIfNeeded(url)
        XCTAssertEqual(controller.webView.url, firstNavigationURL)
    }

    /// The trap this guards was watched happening: between a stop and a
    /// restart, a stray SwiftUI update re-requested the OLD site — and the
    /// fresh build, arriving at the SAME address because a section keeps its
    /// port, then looked "already loaded" to `loadIfNeeded`, which skipped.
    /// The teacher kept the page from before their change with no reload
    /// coming. `showFreshBuild` must start a navigation anyway.
    @MainActor
    func testShowFreshBuildLoadsEvenWhenTheAddressWasAlreadyRequested() {
        let controller: WebPreviewController = WebPreviewController()
        let url: URL = URL(string: "http://127.0.0.1:8081/")!

        // The phantom load that re-arms the last-requested address.
        controller.loadIfNeeded(url)

        // Let that first navigation actually begin, so a navigation seen
        // below can only belong to showFreshBuild.
        let firstLoadBegan: XCTestExpectation = expectation(description: "first navigation begins")
        pollUntil(deadline: Date().addingTimeInterval(5), expectation: firstLoadBegan) {
            return controller.webView.url != nil
        }
        wait(for: [firstLoadBegan], timeout: 6)

        let recorder: NavigationStartRecorder = NavigationStartRecorder()
        controller.webView.navigationDelegate = recorder
        let freshNavigationBegan: XCTestExpectation = expectation(description: "showFreshBuild begins a navigation")
        recorder.onStart = {
            freshNavigationBegan.fulfill()
        }

        controller.showFreshBuild(url)
        wait(for: [freshNavigationBegan], timeout: 6)

        // And the mounting view's own loadIfNeeded is then the no-op, so
        // this stays a single load per rebuild.
        recorder.onStart = {
            XCTFail("loadIfNeeded after showFreshBuild must not start another navigation")
        }
        controller.loadIfNeeded(url)
    }

    /// Checks the condition on a timer until it holds or the deadline
    /// passes, fulfilling the expectation when it holds.
    @MainActor
    private func pollUntil(
        deadline: Date, expectation: XCTestExpectation, condition: @escaping () -> Bool
    ) {
        if condition() {
            expectation.fulfill()
            return
        }
        if Date() > deadline {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else {
                return
            }
            Task { @MainActor in
                self.pollUntil(deadline: deadline, expectation: expectation, condition: condition)
            }
        }
    }
}

/// Reports when the web view begins a provisional navigation.
private final class NavigationStartRecorder: NSObject, WKNavigationDelegate {

    // MARK: - Stored properties

    var onStart: () -> Void = {}

    // MARK: - Functions

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        onStart()
    }
}
