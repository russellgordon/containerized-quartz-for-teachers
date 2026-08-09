import XCTest
@testable import QuartzTeachers

/// Opening the preview in a real browser must not depend on "localhost"
/// resolving to IPv4: Safari tries ::1 first, which the container's port
/// publish does not serve.
final class BrowserSafeURLTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testLocalhostBecomesNumericAddressAndPathSurvives() {
        let original: URL = URL(string: "http://localhost:8081/Concepts/Applying-Abstraction.html")!
        let rewritten: URL = SectionDetailView.browserSafeURL(for: original)
        XCTAssertEqual(rewritten.absoluteString, "http://127.0.0.1:8081/Concepts/Applying-Abstraction.html")
    }

    @MainActor
    func testOtherHostsAreLeftAlone() {
        let original: URL = URL(string: "http://127.0.0.1:8081/")!
        let rewritten: URL = SectionDetailView.browserSafeURL(for: original)
        XCTAssertEqual(rewritten, original)
    }
}
