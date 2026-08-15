import XCTest
@testable import QuartzTeachers

/// Each section's assistant window comes back where it was left.
///
/// Only the NAMING is tested, deliberately. Putting the frame back is one
/// call to AppKit, and exercising it means building and closing real
/// `NSWindow`s in the test bundle, which crashes the runner — a test that
/// takes the suite down is worth less than no test. What is worth pinning is
/// the part with judgement in it: which window counts as which.
@MainActor
final class AssistWindowPlacementTests: XCTestCase {

    // MARK: - Functions

    /// Two sections are two arrangements. A teacher who puts section 1's
    /// assistant on a second monitor and section 2's beside the preview must
    /// not have one overwrite the other.
    func testEachSectionRemembersItsOwnPlace() {
        let one: String = AssistWindowPlacement.autosaveName(courseCode: "ICS3U", sectionNumber: 1)
        let two: String = AssistWindowPlacement.autosaveName(courseCode: "ICS3U", sectionNumber: 2)
        let otherCourse: String = AssistWindowPlacement.autosaveName(courseCode: "ADA1O", sectionNumber: 1)

        XCTAssertNotEqual(one, two)
        XCTAssertNotEqual(one, otherCourse)
    }

    /// The same window, spelled differently, is the same window. Course codes
    /// reach this from the sidebar and from tool arguments a teacher typed,
    /// and those do not always agree about case — two remembered positions
    /// for one window would mean it moved depending on how it was opened.
    func testCaseDoesNotSplitOneWindowIntoTwoRememberedPlaces() {
        XCTAssertEqual(
            AssistWindowPlacement.autosaveName(courseCode: "ics3u", sectionNumber: 1),
            AssistWindowPlacement.autosaveName(courseCode: "ICS3U", sectionNumber: 1)
        )
    }

    /// The name is a `UserDefaults` key, so it has to stay stable across
    /// releases: changing its shape silently forgets where every teacher had
    /// put every assistant window.
    func testTheNameIsTheStableOneAlreadyShipped() {
        XCTAssertEqual(
            AssistWindowPlacement.autosaveName(courseCode: "ICS3U", sectionNumber: 3),
            "AssistantWindow-ICS3U-3"
        )
    }
}
