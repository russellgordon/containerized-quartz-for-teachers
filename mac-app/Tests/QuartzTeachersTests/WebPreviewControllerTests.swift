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
}
