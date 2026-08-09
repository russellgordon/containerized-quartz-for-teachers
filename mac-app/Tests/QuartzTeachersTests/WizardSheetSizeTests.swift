import SwiftUI
import XCTest
@testable import QuartzTeachers

/// The wizard sheet must never grow with its console content: a huge
/// transcript has to scroll inside the fixed sheet, not inflate it
/// (which pushed the sheet's header off the screen).
final class WizardSheetSizeTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testStartedWizardKeepsItsFixedSizeUnderAHugeTranscript() {
        let creator: NewCourseCreator = NewCourseCreator()
        // Simulate the wizard mid-run with thousands of output lines.
        for lineNumber in 1...3000 {
            creator.runner.transcript.append(rawText: "line \(lineNumber): some fairly long console output text that could stretch the layout\n")
        }
        creator.runner.isRunning = true

        let wizard = NewCourseWizardView(creator: creator, startedForTesting: true)
            .environment(WorkspaceModel.shared)
        let hostingController: NSHostingController = NSHostingController(rootView: wizard)
        let fittingSize: NSSize = hostingController.view.fittingSize

        XCTAssertEqual(fittingSize.width, 680, accuracy: 1, "The sheet's width must not follow console content")
        XCTAssertEqual(fittingSize.height, 620, accuracy: 1, "The sheet's height must not follow console content")

        creator.runner.isRunning = false
    }
}
