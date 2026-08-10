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
