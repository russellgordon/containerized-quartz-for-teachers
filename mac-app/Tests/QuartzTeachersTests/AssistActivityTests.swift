import XCTest
@testable import QuartzTeachers

/// One assistant at a time, across the whole app.
///
/// The downloaded model is shared — one file per Mac — but the RUNNING copy
/// is not: each window loads the weights again. Two windows is twice the
/// memory, which on a 16 GB Mac is most of the machine and undoes the point
/// of sizing the model to the hardware.
@MainActor
final class AssistActivityTests: XCTestCase {

    // MARK: - Functions

    override func tearDown() {
        AssistActivity.store.active = nil
        super.tearDown()
    }

    private let folder: String = "/Users/someone/Class Websites"

    // MARK: - Claiming

    func testNothingOpenMeansAnySectionMayOpen() {
        XCTAssertTrue(AssistActivity.mayOpen(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1))
        XCTAssertTrue(AssistActivity.mayOpen(folderPath: folder, courseCode: "ADA1O", sectionNumber: 2))
        XCTAssertNil(AssistActivity.reasonItIsUnavailable(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1))
    }

    /// The whole point: a second section cannot open one while the first has it.
    func testAnotherSectionIsBlockedWhileOneIsOpen() {
        AssistActivity.begin(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1)

        XCTAssertFalse(AssistActivity.mayOpen(folderPath: folder, courseCode: "ICS3U", sectionNumber: 2),
                       "Another section of the SAME course is still a second engine")
        XCTAssertFalse(AssistActivity.mayOpen(folderPath: folder, courseCode: "ADA1O", sectionNumber: 1),
                       "A different course is still a second engine")
        XCTAssertFalse(AssistActivity.mayOpen(folderPath: "/Users/someone/Other", courseCode: "ICS3U", sectionNumber: 1),
                       "A different working folder is still the same Mac")
    }

    /// Dimmed alone says "no". The line under it has to say what to close.
    func testTheReasonNamesTheSectionHoldingIt() {
        AssistActivity.begin(folderPath: folder, courseCode: "ICS3U", sectionNumber: 2)

        let reason: String? = AssistActivity.reasonItIsUnavailable(
            folderPath: folder, courseCode: "ADA1O", sectionNumber: 1
        )
        let text: String = try! XCTUnwrap(reason)
        XCTAssertTrue(text.contains("ICS3U"), "It must name the course holding the assistant")
        XCTAssertTrue(text.contains("Section 2"), "…and the section, so there is one thing to go and close")
    }

    /// Asking again for the section that already has it is not a second
    /// window — it brings the existing one forward, which is what a teacher
    /// expects from a menu item naming a window they can see.
    func testTheSectionThatHasItMayStillBeChosen() {
        AssistActivity.begin(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1)

        XCTAssertTrue(AssistActivity.mayOpen(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1))
        XCTAssertNil(AssistActivity.reasonItIsUnavailable(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1))
    }

    // MARK: - Releasing

    func testClosingItFreesTheFeature() {
        AssistActivity.begin(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1)
        AssistActivity.end(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1)

        XCTAssertNil(AssistActivity.active)
        XCTAssertTrue(AssistActivity.mayOpen(folderPath: folder, courseCode: "ADA1O", sectionNumber: 1))
    }

    /// A window closing must not clear somebody else's claim. Two windows
    /// shutting down out of order would otherwise leave the survivor
    /// unfindable — and, worse, allow a third.
    func testClosingOneWindowDoesNotClearAnothersClaim() {
        AssistActivity.begin(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1)
        AssistActivity.end(folderPath: folder, courseCode: "ADA1O", sectionNumber: 3)

        XCTAssertEqual(AssistActivity.active?.courseCode, "ICS3U")
        XCTAssertFalse(AssistActivity.mayOpen(folderPath: folder, courseCode: "ADA1O", sectionNumber: 1))
    }

    /// A stale claim from a window that failed to release must not lock the
    /// feature out until the app restarts, so a newer claim wins.
    func testANewerClaimReplacesAStaleOne() {
        AssistActivity.begin(folderPath: folder, courseCode: "ICS3U", sectionNumber: 1)
        AssistActivity.begin(folderPath: folder, courseCode: "ADA1O", sectionNumber: 2)

        XCTAssertEqual(AssistActivity.active?.courseCode, "ADA1O")
        XCTAssertEqual(AssistActivity.active?.sectionNumber, 2)
    }
}
