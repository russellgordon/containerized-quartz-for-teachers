import XCTest
@testable import QuartzTeachers

/// The deterministic progress bar: milestones must advance in order,
/// never go backwards, and finish full on success.
final class TaskMilestoneTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testPreviewProgressAdvancesThroughItsMilestones() {
        let runner: ScriptRunner = ScriptRunner()
        runner.milestones = TaskMilestones.preview
        runner.isRunning = true

        // Eight steps: host setup and the local image build lead, both
        // skipped (and implied) on every run after the first.
        XCTAssertEqual(runner.milestonesReached, 0)
        XCTAssertEqual(runner.progressFraction, 0, accuracy: 0.001)
        XCTAssertEqual(runner.currentMilestoneLabel, "Getting this Mac ready…")
        XCTAssertEqual(runner.stepDescription, "Step 1 of 8")

        runner.receiveOutput( "🚀 Starting container if needed...\n")
        XCTAssertEqual(runner.milestonesReached, 3)
        XCTAssertEqual(runner.currentMilestoneLabel, "Gathering your content…")
        XCTAssertEqual(runner.stepDescription, "Step 4 of 8")

        runner.receiveOutput( "📥 Copying shared folders into content...\n")
        runner.receiveOutput( "✅ Updated pageTitle to '📚 EXC2O S1'\n")
        XCTAssertEqual(runner.milestonesReached, 5)
        XCTAssertEqual(runner.progressFraction, 5.0 / 8.0, accuracy: 0.001)

        runner.receiveOutput( "Quartz v4.5.0\n")
        runner.receiveOutput( "🚀 Launching Quartz preview on http://localhost:8081\n")
        XCTAssertEqual(runner.milestonesReached, 8)
        XCTAssertEqual(runner.progressFraction, 1.0, accuracy: 0.001)
        XCTAssertEqual(runner.currentMilestoneLabel, "Opening the preview…")
    }

    @MainActor
    func testALaterMarkerImpliesEarlierStepsAreDone() {
        // Output varies between runs; a skipped marker must not stall
        // the bar or make it go backwards.
        let runner: ScriptRunner = ScriptRunner()
        runner.milestones = TaskMilestones.preview
        runner.isRunning = true
        runner.receiveOutput( "Quartz v4.5.0\n")
        XCTAssertEqual(runner.milestonesReached, 7, "A late marker implies the earlier steps")
    }

    @MainActor
    func testSuccessfulCompletionFillsTheBar() {
        let runner: ScriptRunner = ScriptRunner()
        runner.milestones = TaskMilestones.courseCreation
        runner.isRunning = false
        runner.lastExitCode = 0
        XCTAssertEqual(runner.progressFraction, 1.0, accuracy: 0.001)
    }

    @MainActor
    func testWithoutMilestonesTheViewFallsBackToPhaseText() {
        let runner: ScriptRunner = ScriptRunner()
        runner.isRunning = true
        runner.receiveOutput( "📦 Installing dependencies...\n")
        XCTAssertTrue(runner.milestones.isEmpty)
        XCTAssertEqual(runner.progressFraction, 0, accuracy: 0.001)
        XCTAssertEqual(runner.currentMilestoneLabel, runner.friendlyPhase)
    }

    @MainActor
    func testEveryMilestoneListIsOrderedAndBriefEnough() {
        let lists: [[TaskMilestone]] = [
            TaskMilestones.courseCreation,
            TaskMilestones.preview,
            TaskMilestones.deploy,
        ]
        for list in lists {
            XCTAssertGreaterThan(list.count, 2, "A useful milestone list needs several steps")
            for milestone in list {
                XCTAssertFalse(milestone.label.isEmpty)
                XCTAssertTrue(milestone.label.hasSuffix("…"), "Milestone labels end with an ellipsis: \(milestone.label)")
                XCTAssertLessThanOrEqual(milestone.label.count, 32, "Milestone labels must stay brief: \(milestone.label)")
                XCTAssertFalse(milestone.marker.isEmpty)
            }
        }
    }
}

/// Showing how far through a long step a task has got.
final class StepDetailTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testUploadCountIsRead() {
        let progress = ScriptRunner.uploadProgress(in: " …uploaded 125/234 required files\n")
        XCTAssertEqual(progress?.done, 125)
        XCTAssertEqual(progress?.total, 234)
    }

    @MainActor
    func testTheLatestCountInAChunkWins() {
        let chunk: String = " …uploaded 25/234 required files\n …uploaded 50/234 required files\n"
        XCTAssertEqual(ScriptRunner.uploadProgress(in: chunk)?.done, 50)
    }

    @MainActor
    func testTheTotalIsKnownBeforeTheFirstBatch() {
        XCTAssertEqual(ScriptRunner.uploadTotal(in: " Netlify requires 234 file(s) for this deploy.\n"), 234)
    }

    @MainActor
    func testOrdinaryOutputCarriesNoCount() {
        XCTAssertNil(ScriptRunner.uploadProgress(in: "Preparing delta deploy manifest…\n"))
        XCTAssertNil(ScriptRunner.uploadTotal(in: "Preparing delta deploy manifest…\n"))
    }

    @MainActor
    func testTheCountShowsBesideTheStepAndClearsWhenTheStepChanges() {
        let runner: ScriptRunner = ScriptRunner()
        runner.milestones = TaskMilestones.deploy
        runner.receiveOutput(" Netlify requires 234 file(s) for this deploy.\n")
        XCTAssertEqual(runner.stepDetail, "0 of 234")
        runner.receiveOutput(" …uploaded 125/234 required files\n")
        XCTAssertEqual(runner.stepDetail, "125 of 234")
        runner.receiveOutput("✅ Delta deploy created (production).\n")
        XCTAssertEqual(runner.stepDetail, "", "A finished step must not keep showing its count")
    }
}
