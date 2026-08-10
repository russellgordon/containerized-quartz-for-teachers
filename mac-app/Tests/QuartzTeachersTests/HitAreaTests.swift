import XCTest
import SwiftUI
@testable import QuartzTeachers

/// The sidebar's +/- buttons must be clickable, not pixel hunts.
///
/// A bare glyph — especially a minus, which is a few pixels tall — gives a
/// target barely worth aiming at. These tests measure what the accessibility
/// tree reports for the real buttons on screen, which is what a click has to
/// land on.
final class HitAreaTests: XCTestCase {

    // MARK: - Stored properties

    /// Apple's Human Interface Guidelines put the comfortable minimum for a
    /// pointer target at roughly this size.
    let smallestComfortableTarget: CGSize = CGSize(width: 20, height: 18)

    // MARK: - Functions

    @MainActor
    func testTheFooterButtonsAreBigEnoughToHit() async throws {
        guard WorkspaceModel.windowModels.first != nil else {
            throw XCTSkip("The interface is not on screen in this run")
        }
        // Let the window settle so the footer has been laid out.
        try await Task.sleep(for: .milliseconds(400))

        for identifier in ["addCourseButton", "removeSelectedButton"] {
            guard let rectangle = AccessibilityInspector.frame(forIdentifier: identifier) else {
                XCTFail("\(identifier) is not in the accessibility tree")
                continue
            }
            XCTAssertGreaterThanOrEqual(
                rectangle.width, smallestComfortableTarget.width,
                "\(identifier) is only \(rectangle.width) points wide — a glyph-sized target"
            )
            XCTAssertGreaterThanOrEqual(
                rectangle.height, smallestComfortableTarget.height,
                "\(identifier) is only \(rectangle.height) points tall — a glyph-sized target"
            )
        }
    }

    @MainActor
    func testTheDeclaredTargetSizeIsComfortable() {
        XCTAssertGreaterThanOrEqual(SidebarView.footerButtonSize.width, smallestComfortableTarget.width)
        XCTAssertGreaterThanOrEqual(SidebarView.footerButtonSize.height, smallestComfortableTarget.height)
    }
}
