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
        runner.transcript.append(rawText: "⬇️  Image not found locally. Pulling rwhgrwhg/teaching-quartz …\n")
        XCTAssertEqual(runner.friendlyPhase, "Downloading components (first time can take a few minutes)…")

        runner.transcript.append(rawText: "📦 Installing dependencies...\n")
        XCTAssertEqual(runner.friendlyPhase, "Preparing your site (first time can take a few minutes)…")

        runner.transcript.append(rawText: "🚀 Launching Quartz preview on http://localhost:8081\n")
        XCTAssertEqual(runner.friendlyPhase, "Starting the preview…")
    }

    @MainActor
    func testDefaultPhaseIsWorking() {
        let runner: ScriptRunner = ScriptRunner()
        runner.transcript.append(rawText: "some unremarkable output\n")
        XCTAssertEqual(runner.friendlyPhase, "Working…")
    }

    @MainActor
    func testStalledPromptIsDetectedOnlyWhenQuietAndPromptShaped() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isRunning = true
        runner.transcript.append(rawText: "Paste Netlify token: ")

        // Fresh output: not yet a stall.
        runner.lastOutputAt = Date()
        XCTAssertFalse(runner.mayBeWaitingForInput(asOf: Date()))

        // Quiet for five seconds at a prompt-shaped line: stall.
        runner.lastOutputAt = Date(timeIntervalSinceNow: -5)
        XCTAssertTrue(runner.mayBeWaitingForInput(asOf: Date()))

        // Quiet but mid-build (no prompt shape): not a stall.
        runner.transcript.append(rawText: "\nEmitting files")
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
        runner.transcript.append(rawText: "Install the Example Course now? (y/n) [Default: n]")
        runner.lastOutputAt = Date(timeIntervalSinceNow: -5)
        XCTAssertTrue(runner.mayBeWaitingForInput(asOf: Date()))
    }
}
