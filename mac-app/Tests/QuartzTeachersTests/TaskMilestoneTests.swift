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

        XCTAssertEqual(runner.milestonesReached, 0)
        XCTAssertEqual(runner.progressFraction, 0, accuracy: 0.001)
        XCTAssertEqual(runner.currentMilestoneLabel, "Starting up…")
        XCTAssertEqual(runner.stepDescription, "Step 1 of 6")

        runner.transcript.append(rawText: "🚀 Starting container if needed...\n")
        XCTAssertEqual(runner.milestonesReached, 1)
        XCTAssertEqual(runner.currentMilestoneLabel, "Gathering your content…")
        XCTAssertEqual(runner.stepDescription, "Step 2 of 6")

        runner.transcript.append(rawText: "📥 Copying shared folders into content...\n")
        runner.transcript.append(rawText: "✅ Updated pageTitle to '📚 EXC2O S1'\n")
        XCTAssertEqual(runner.milestonesReached, 3)
        XCTAssertEqual(runner.progressFraction, 0.5, accuracy: 0.001)

        runner.transcript.append(rawText: "Quartz v4.5.0\n")
        runner.transcript.append(rawText: "🚀 Launching Quartz preview on http://localhost:8081\n")
        XCTAssertEqual(runner.milestonesReached, 6)
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
        runner.transcript.append(rawText: "Quartz v4.5.0\n")
        XCTAssertEqual(runner.milestonesReached, 5, "A late marker implies the earlier steps")
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
        runner.transcript.append(rawText: "📦 Installing dependencies...\n")
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
