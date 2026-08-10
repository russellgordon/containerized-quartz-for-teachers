import XCTest
@testable import QuartzTeachers

final class FailureExplainerTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testRateLimitIsExplainedWithTheWait() {
        let output: String = """
        ❌ Failed to create Netlify site.
         Details: Netlify API error 429: {"code":429,"message":"API Deploy rate limit surpassed for application"}
        Now: 2026-08-09 22:07:56 UTC-04:00
        Window resets at: 2026-08-09 22:08:56 UTC-04:00 (in ~59s).
        """
        let explanation: String? = FailureExplainer.explanation(in: output)
        XCTAssertEqual(explanation, "Netlify is limiting how often websites can be published right now. Try publishing again in about a minute.")
    }

    @MainActor
    func testALongerWaitIsGivenInMinutes() {
        let output: String = "Netlify API error 429: rate limit\nWindow resets at: later (in ~200s)."
        XCTAssertEqual(FailureExplainer.waitDescription(in: output), "in about 4 minutes")
    }

    @MainActor
    func testAnUnknownWaitStillReads() {
        let output: String = "Netlify API error 429: rate limit"
        XCTAssertEqual(FailureExplainer.waitDescription(in: output), "in a few minutes")
    }

    @MainActor
    func testMissingAccountIsExplained() {
        let explanation: String? = FailureExplainer.explanation(in: "❌ Netlify token missing.")
        XCTAssertEqual(explanation, "Your Netlify account isn't connected yet. Add your Netlify access token, then publish again.")
    }

    @MainActor
    func testRefusedTokenIsExplained() {
        let explanation: String? = FailureExplainer.explanation(in: "Netlify API error 401: {\"message\":\"Unauthorized\"}")
        XCTAssertNotNil(explanation)
        XCTAssertTrue(explanation?.contains("didn't accept your access token") == true)
    }

    @MainActor
    func testNoInternetIsExplained() {
        let explanation: String? = FailureExplainer.explanation(in: "urlopen error [Errno 8] nodename nor servname provided")
        XCTAssertEqual(explanation, "Your computer couldn't reach the internet. Check your connection, then try again.")
    }

    @MainActor
    func testMissingBuildIsExplained() {
        let explanation: String? = FailureExplainer.explanation(in: "❌ Built site not found at: /teaching/courses/ICS3U/.merged_output/section3/public")
        XCTAssertEqual(explanation, "This website hasn't been built yet. Preview it once, then publish.")
    }

    @MainActor
    func testUnrecognisedTroubleStaysUnexplained() {
        let explanation: String? = FailureExplainer.explanation(in: "Traceback (most recent call last):\n  File \"deploy.py\", line 12\nKeyError: 'sections'")
        XCTAssertNil(explanation, "Guessing would be worse than showing the output")
    }
}
