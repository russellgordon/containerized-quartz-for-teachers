import SwiftUI
import XCTest
@testable import QuartzTeachers

/// The progress view must never demand more height than it is given.
/// When it did, the window's SwiftUI content grew past the window and
/// slid out of view — a responsive app drawing a blank window.
final class ProgressViewSizeTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func makeRunnerWithOutput(lineCount: Int) -> ScriptRunner {
        let runner: ScriptRunner = ScriptRunner()
        runner.milestones = TaskMilestones.deploy
        runner.isRunning = true
        for lineNumber in 1...lineCount {
            runner.receiveOutput("  …uploaded \(lineNumber)/\(lineCount) required files to the site\n")
        }
        return runner
    }

    /// Lays the view out at a fixed window size and reports the height
    /// its content actually claims.
    @MainActor
    func measuredHeight(of view: some View, width: CGFloat, height: CGFloat) -> CGFloat {
        // NOTE: do NOT force a frame on the view itself — that would
        // clamp the very thing under test. Give the HOST a window-sized
        // frame and ask what height the content claims.
        let hostingView: NSHostingView = NSHostingView(rootView: AnyView(view))
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        hostingView.layoutSubtreeIfNeeded()
        return hostingView.fittingSize.height
    }

    @MainActor
    func testCollapsedProgressViewFitsItsWindow() {
        let runner: ScriptRunner = makeRunnerWithOutput(lineCount: 3000)
        let measured: CGFloat = measuredHeight(
            of: TaskProgressView(runner: runner, title: "Publishing"),
            width: 800,
            height: 720
        )
        XCTAssertLessThanOrEqual(measured, 721, "Collapsed, the progress view claimed \(measured) points in a 720-point window")
    }

    /// Deploy is the only step that PAUSES for input, which shows the
    /// "a question needs your attention" notice. That notice must not
    /// make the header balloon.
    @MainActor
    func testWaitingForInputNoticeDoesNotBalloonTheHeader() {
        let runner: ScriptRunner = ScriptRunner()
        runner.milestones = TaskMilestones.deploy
        runner.isRunning = true
        runner.receiveOutput("Enter Netlify site name [ics3u-s4-2026-gordon]: ")
        runner.lastOutputAt = Date(timeIntervalSinceNow: -10)
        XCTAssertTrue(runner.mayBeWaitingForInput(asOf: Date()), "The notice should be showing for this test to mean anything")

        let measured: CGFloat = measuredHeight(
            of: TaskProgressView(runner: runner, title: "Publishing ICS3U-S4"),
            width: 800,
            height: 720
        )
        XCTAssertLessThanOrEqual(measured, 721, "While waiting for input, the header claimed \(measured) points in a 720-point window")
    }

    /// The header must not balloon even if it is briefly offered a
    /// narrow width — long text wrapping in a vertically fixed-size
    /// container is what made the content taller than the window.
    @MainActor
    func testHeaderDoesNotBalloonAtNarrowWidths() {
        let runner: ScriptRunner = ScriptRunner()
        runner.milestones = TaskMilestones.deploy
        runner.isRunning = true
        runner.receiveOutput("Enter Netlify site name [ics3u-s4-2026-gordon]: ")
        runner.lastOutputAt = Date(timeIntervalSinceNow: -10)

        let measured: CGFloat = measuredHeight(
            of: TaskProgressView(runner: runner, title: "Publishing ICS3U-S4"),
            width: 120,
            height: 720
        )
        XCTAssertLessThanOrEqual(measured, 721, "At a narrow width the header claimed \(measured) points")
    }

    @MainActor
    func testExpandedDetailsFitTheirWindow() {
        let runner: ScriptRunner = makeRunnerWithOutput(lineCount: 3000)
        let measured: CGFloat = measuredHeight(
            of: TaskProgressView(runner: runner, title: "Publishing", showingDetailsForTesting: true),
            width: 800,
            height: 720
        )
        XCTAssertLessThanOrEqual(measured, 721, "With details open, the progress view claimed \(measured) points in a 720-point window")
    }
}
