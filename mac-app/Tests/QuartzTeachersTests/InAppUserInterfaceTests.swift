import XCTest
@testable import QuartzTeachers

/// Drives the app's REAL user interface from inside the app process:
/// manipulates the shared workspace model the way clicks would, lets
/// SwiftUI render, captures screenshots, and verifies effects on disk.
///
/// (The separate XCUITest suite does the same via synthesized clicks, but
/// needs a one-time macOS automation approval to run.)
final class InAppUserInterfaceTests: XCTestCase {

    // MARK: - Functions

    /// Where screenshots land for review.
    var screenshotDirectory: String {
        let environment: [String: String] = ProcessInfo.processInfo.environment
        if let stored = environment["UITEST_SCREENSHOT_DIR"] {
            return stored
        }
        return NSTemporaryDirectory()
    }

    /// The fixture workspace path supplied by the test invocation.
    var fixtureWorkspacePath: String? {
        let environment: [String: String] = ProcessInfo.processInfo.environment
        return environment["UITEST_WORKSPACE"]
    }

    /// Waits for SwiftUI to process pending updates and render.
    @MainActor
    func settle(seconds: Double = 0.7) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    @MainActor
    func testWalkThroughRealInterface() async throws {
        guard let fixturePath = fixtureWorkspacePath else {
            throw XCTSkip("Set UITEST_WORKSPACE to run the in-app UI walk-through.")
        }
        let fixtureURL: URL = URL(fileURLWithPath: fixturePath)
        let workspace: WorkspaceModel = WorkspaceModel.shared

        // Make the window a predictable size for screenshots.
        if let window = NSApp.windows.first {
            window.setFrame(NSRect(x: 100, y: 100, width: 1100, height: 720), display: true)
        }

        // 1. Adopt the fixture workspace, as the folder picker would.
        workspace.chooseWorkspace(at: fixtureURL)
        await settle()
        XCTAssertNil(workspace.workspaceProblem, "Fixture workspace should validate")
        XCTAssertFalse(workspace.courses.isEmpty, "Fixture should contain the EXC2O course")

        var foundExample: Bool = false
        for course in workspace.courses {
            if course.code == "EXC2O" {
                foundExample = true
            }
        }
        XCTAssertTrue(foundExample, "EXC2O should be listed")
        try WindowCapture.captureMainWindow(to: screenshotDirectory + "/01-sidebar-no-selection.png")

        // The window capture cannot draw the sidebar's vibrancy material,
        // so prove the rows exist by walking the REAL window's
        // accessibility tree (the same thing VoiceOver reads).
        let visibleLabels: [String] = AccessibilityInspector.collectAllLabels()
        XCTAssertTrue(visibleLabels.contains("EXC2O"), "Sidebar should expose the EXC2O row; found \(visibleLabels.count) labels: \(visibleLabels.prefix(40))")

        // The bundled colour schemes must have loaded for the pickers.
        XCTAssertFalse(ColourSchemeCatalog.schemes.isEmpty, "colour_schemes.json should be bundled and loaded")

        // 2. Select the course — the settings form should appear.
        workspace.selection = .course("EXC2O")
        await settle()
        try WindowCapture.captureMainWindow(to: screenshotDirectory + "/02-course-settings.png")

        // 3. Edit a setting the way the form would, then Save.
        guard let course = workspace.selectedCourse else {
            XCTFail("Selected course should resolve")
            return
        }
        let originalValue: Bool = course.configuration.showReadingTime
        course.configuration.showReadingTime = !originalValue
        XCTAssertTrue(course.configuration.hasUnsavedChanges)
        await settle(seconds: 0.3)

        try course.configuration.write(to: course.configFileURL)
        XCTAssertFalse(course.configuration.hasUnsavedChanges)

        // The file on disk must reflect the change.
        let savedData: Data = try Data(contentsOf: course.configFileURL)
        let savedObject: Any = try JSONSerialization.jsonObject(with: savedData)
        let savedDictionary: [String: Any] = savedObject as? [String: Any] ?? [:]
        XCTAssertEqual(savedDictionary["show_reading_time"] as? Bool, !originalValue)

        // 4. Cancel path: edit again, discard, confirm the value reverts.
        course.configuration.showReadingTime = originalValue
        try course.configuration.discardChanges()
        XCTAssertEqual(course.configuration.showReadingTime, !originalValue, "Cancel reverts to last SAVE, not the original file")

        // Restore the fixture's original value for repeatable runs.
        course.configuration.showReadingTime = originalValue
        try course.configuration.write(to: course.configFileURL)

        // 5. Select a section — preview/deploy view should appear.
        workspace.selection = .section("EXC2O", 1)
        await settle()
        try WindowCapture.captureMainWindow(to: screenshotDirectory + "/03-section-view.png")

        // 6. Open the New Course wizard sheet.
        workspace.isShowingNewCourseWizard = true
        await settle(seconds: 1.2)
        try WindowCapture.captureMainWindow(to: screenshotDirectory + "/04-new-course-wizard.png")
        workspace.isShowingNewCourseWizard = false
        await settle(seconds: 0.5)
    }
}
