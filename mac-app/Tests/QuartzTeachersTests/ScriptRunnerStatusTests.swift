import XCTest
@testable import QuartzTeachers

/// The friendly progress presentation: phase labels derived from output
/// markers, and the stalled-prompt detection behind the "a question
/// needs your attention" notice.
final class ScriptRunnerStatusTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testPhaseLabelFollowsTheLatestMarker() {
        let runner: ScriptRunner = ScriptRunner()
        runner.receiveOutput( "⬇️  Image not found locally. Pulling rwhgrwhg/teaching-quartz …\n")
        XCTAssertEqual(runner.friendlyPhase, "Downloading components (first time can take a few minutes)…")

        runner.receiveOutput( "📦 Installing dependencies...\n")
        XCTAssertEqual(runner.friendlyPhase, "Preparing your site (first time can take a few minutes)…")

        runner.receiveOutput( "🚀 Launching Quartz preview on http://localhost:8081\n")
        XCTAssertEqual(runner.friendlyPhase, "Starting the preview…")
    }

    @MainActor
    func testDefaultPhaseIsWorking() {
        let runner: ScriptRunner = ScriptRunner()
        runner.receiveOutput( "some unremarkable output\n")
        XCTAssertEqual(runner.friendlyPhase, "Working…")
    }

    @MainActor
    func testPublishedSiteLinkIsFoundInDeployOutput() {
        let runner: ScriptRunner = ScriptRunner()
        runner.receiveOutput(" Netlify site created.\n")
        runner.receiveOutput(" Admin: https://app.netlify.com/sites/ics3u-s1-2026-gordon\n")
        runner.receiveOutput(" Live URL: https://ics3u-s1-2026-gordon.netlify.app\n")
        runner.receiveOutput("✅ Deploy complete.\n")
        XCTAssertEqual(runner.publishedSiteURL?.absoluteString, "https://ics3u-s1-2026-gordon.netlify.app", "The teacher's site should be offered, not Netlify's admin page")
    }

    @MainActor
    func testRepeatPublishOfAnExistingSiteStillOffersTheLink() {
        // A site that already exists is quoted from its saved record,
        // which holds a plain-http address rather than the ssl one.
        let runner: ScriptRunner = ScriptRunner()
        runner.receiveOutput(" Using existing Netlify site for this section.\n")
        runner.receiveOutput(" Site: http://ics3u-s1-2025-gordon.netlify.app\n")
        runner.receiveOutput(" Netlify requires 3 file(s) for this deploy.\n")
        runner.receiveOutput("✅ Delta deploy created (production).\n")
        runner.receiveOutput(" Site URL: http://ics3u-s1-2025-gordon.netlify.app\n")
        XCTAssertEqual(runner.publishedSiteURL?.absoluteString, "https://ics3u-s1-2025-gordon.netlify.app")
    }

    @MainActor
    func testACustomAddressIsOfferedWhenAnnounced() {
        let found = ScriptRunner.publishedSiteURL(in: " Site URL: https://cs.example.com\n✅ Deploy complete.")
        XCTAssertEqual(found?.absoluteString, "https://cs.example.com", "A site on its own domain is still the site")
    }

    @MainActor
    func testTheDashboardIsNeverOfferedAsTheSite() {
        let found = ScriptRunner.publishedSiteURL(in: " Admin: https://app.netlify.com/projects/ics3u-s1-2025-gordon\n")
        XCTAssertNil(found)
    }

    @MainActor
    func testNoSiteLinkWhenNothingWasPublished() {
        let runner: ScriptRunner = ScriptRunner()
        runner.receiveOutput("Building your site\n")
        XCTAssertNil(runner.publishedSiteURL)
    }

    @MainActor
    func testDefaultAnswerMovesOutOfTheQuestion() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Enter Netlify site name [ics3u-s3-2026-gordon]:")
        XCTAssertEqual(asked.question, "Enter Netlify site name:")
        XCTAssertEqual(asked.suggestedAnswer, "ics3u-s3-2026-gordon")
    }

    @MainActor
    func testLabelledDefaultAnswerMovesOutOfTheQuestion() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Your name [Default: Russell Gordon]:")
        XCTAssertEqual(asked.question, "Your name:")
        XCTAssertEqual(asked.suggestedAnswer, "Russell Gordon")
    }

    @MainActor
    func testRetryPromptDropsTheTypistsEscapeHatch() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Choose a different Netlify site name (or 'q' to cancel) [ics3u-s3-2026-gordon-01]:")
        XCTAssertEqual(asked.question, "Choose a different Netlify site name:")
        XCTAssertEqual(asked.suggestedAnswer, "ics3u-s3-2026-gordon-01")
    }

    @MainActor
    func testTheScriptsOwnCancelKeyIsRemembered() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Choose a different Netlify site name (or 'q' to cancel) [ics3u-s3-2026-gordon-01]:")
        XCTAssertEqual(asked.cancelToken, "q", "The key the script accepts must survive being hidden from the wording")
    }

    @MainActor
    func testNoCancelKeyWhenTheScriptOffersNone() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Enter your Netlify access token:")
        XCTAssertEqual(asked.cancelToken, "")
    }

    @MainActor
    func testCancellingWithoutAWayOutStopsTheTask() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isAwaitingInput = true
        runner.pendingCancelToken = ""
        runner.cancelPendingQuestion()
        XCTAssertFalse(runner.isAwaitingInput)
        XCTAssertTrue(runner.wasCancelled, "Cancel must always mean the task stops")
    }

    @MainActor
    func testCancellingMarksTheTaskAsCancelled() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isAwaitingInput = true
        runner.pendingCancelToken = "q"
        runner.cancelPendingQuestion()
        XCTAssertTrue(runner.wasCancelled)
        XCTAssertFalse(runner.isAwaitingInput)
    }

    @MainActor
    func testInformativeParentheticalsSurvive() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Overwrite the existing folder (y/n)?")
        XCTAssertEqual(asked.question, "Overwrite the existing folder (y/n)?")
    }

    @MainActor
    func testChoicesStayInTheQuestion() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Continue? [Y/n]")
        XCTAssertEqual(asked.question, "Continue? [Y/n]")
        XCTAssertEqual(asked.suggestedAnswer, "")
    }

    @MainActor
    func testQuestionWithoutADefaultIsUnchanged() {
        let asked = ScriptRunner.separateDefaultAnswer(from: "Enter your Netlify access token:")
        XCTAssertEqual(asked.question, "Enter your Netlify access token:")
        XCTAssertEqual(asked.suggestedAnswer, "")
    }

    @MainActor
    func testQuestionShapesAreRecognised() {
        XCTAssertTrue(ScriptRunner.looksLikeQuestion("Enter Netlify site name [ics3u-s1-2026-gordon]:"))
        XCTAssertTrue(ScriptRunner.looksLikeQuestion("Install the Example Course now? (y/n) [Default: n]"))
        XCTAssertTrue(ScriptRunner.looksLikeQuestion(">"))
        XCTAssertFalse(ScriptRunner.looksLikeQuestion("Emitting files"))
        XCTAssertFalse(ScriptRunner.looksLikeQuestion("Uploaded 42 files"))
    }

    @MainActor
    func testSendingAnAnswerClearsTheQuestion() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isAwaitingInput = true
        runner.pendingQuestion = "Enter Netlify site name:"
        runner.send(line: "my-site")
        XCTAssertFalse(runner.isAwaitingInput, "Answering should dismiss the question")
    }

    @MainActor
    func testNewOutputMeansTheScriptIsNoLongerWaiting() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isRunning = true
        runner.isAwaitingInput = true
        runner.receiveOutput("Uploading your pages\n")
        XCTAssertFalse(runner.isAwaitingInput, "Fresh output means it is working again")
    }

    @MainActor
    func testStalledPromptIsDetectedOnlyWhenQuietAndPromptShaped() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isRunning = true
        runner.receiveOutput( "Paste Netlify token: ")

        // Fresh output: not yet a stall.
        runner.lastOutputAt = Date()
        XCTAssertFalse(runner.mayBeWaitingForInput(asOf: Date()))

        // Quiet for five seconds at a prompt-shaped line: stall.
        runner.lastOutputAt = Date(timeIntervalSinceNow: -5)
        XCTAssertTrue(runner.mayBeWaitingForInput(asOf: Date()))

        // Quiet but mid-build (no prompt shape): not a stall.
        runner.receiveOutput( "\nEmitting files")
        runner.lastOutputAt = Date(timeIntervalSinceNow: -5)
        XCTAssertFalse(runner.mayBeWaitingForInput(asOf: Date()))

        // Not running: never a stall.
        runner.isRunning = false
        XCTAssertFalse(runner.mayBeWaitingForInput(asOf: Date()))
    }

    @MainActor
    func testDefaultAnswerPromptCountsAsPromptShape() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isRunning = true
        runner.receiveOutput( "Install the Example Course now? (y/n) [Default: n]")
        runner.lastOutputAt = Date(timeIntervalSinceNow: -5)
        XCTAssertTrue(runner.mayBeWaitingForInput(asOf: Date()))
    }
}
