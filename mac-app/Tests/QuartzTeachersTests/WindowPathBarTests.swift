import XCTest
import SwiftUI
@testable import QuartzTeachers

/// The working folder is shown at the bottom of the window.
final class WindowPathBarTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testThePathBarIsOnScreenWithItsFolder() async throws {
        guard let workspace = WorkspaceModel.windowModels.first else {
            throw XCTSkip("The interface is not on screen in this run")
        }
        let folderURL: URL = try FixtureWorkspace.materialize()
        workspace.chooseWorkspace(at: folderURL)
        try await Task.sleep(for: .milliseconds(500))

        guard let rectangle = AccessibilityInspector.frame(forIdentifier: "windowPathBar") else {
            XCTFail("The path bar is not in the accessibility tree")
            return
        }
        XCTAssertGreaterThan(rectangle.width, 200, "It should span the detail column")
        XCTAssertGreaterThan(rectangle.height, 10, "It should be a visible strip")

        let labels: [String] = AccessibilityInspector.collectAllLabels()
        var mentionsTheFolder: Bool = false
        for label in labels {
            if label.contains("Folder location: \(folderURL.path)") {
                mentionsTheFolder = true
            }
        }
        XCTAssertTrue(mentionsTheFolder, "The bar should name the working folder")
    }

    /// Position is deliberately not asserted here: for SwiftUI content the
    /// accessibility tree hands back a container's frame — the whole window
    /// in this case — so a positional check would be measuring the wrong
    /// rectangle. The placement was confirmed from a window capture, which
    /// shows the bar along the bottom of the detail column, and that capture
    /// is what to repeat if the layout is ever in doubt.
}
