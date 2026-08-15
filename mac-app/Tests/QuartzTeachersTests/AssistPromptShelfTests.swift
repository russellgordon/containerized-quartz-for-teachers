import XCTest
import SwiftUI
@testable import QuartzTeachers

/// The shelf of things a teacher can ask for: what it offers, and that its
/// shape is remembered.
@MainActor
final class AssistPromptShelfTests: XCTestCase {

    // MARK: - Functions

    private let key: String = "AssistPromptShelfOpenGroups"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    /// Remembered across windows and launches, not per window.
    ///
    /// `@SceneStorage` would restore THIS window when it came back, but
    /// opening the assistant on another section is a different scene — so a
    /// teacher who opened a group would find it shut again, which is the
    /// opposite of remembering it.
    func testTheOpenGroupsAreRememberedAppWide() {
        UserDefaults.standard.set("Checking|Taking it back", forKey: key)

        let stored: String = UserDefaults.standard.string(forKey: key) ?? ""
        var titles: Set<String> = []
        for piece in stored.split(separator: "|") {
            titles.insert(String(piece))
        }
        XCTAssertEqual(titles, ["Checking", "Taking it back"])
    }

    /// Nothing stored means everything shut — the shelf costs four lines
    /// until a teacher asks for more.
    func testNothingStoredMeansEverythingIsShut() {
        UserDefaults.standard.removeObject(forKey: key)
        let stored: String = UserDefaults.standard.string(forKey: key) ?? ""
        XCTAssertTrue(stored.split(separator: "|").isEmpty)
    }

    /// The shelf's wording and the phrasings matched in CODE have to stay in
    /// step. "Deploy this section now" became "Deploy now" on the shelf, and a
    /// card whose wording no longer matches is a button that quietly goes to
    /// the model on a shape the model was measured getting wrong.
    func testTheShelfsShortcutPhrasingsStillFire() {
        XCTAssertEqual(AssistCardCommand.matching("Deploy now")?.toolName, "deploy_section")
        XCTAssertEqual(
            AssistCardCommand.matching("What would students see in this section right now?")?.toolName,
            "check_section"
        )
        XCTAssertEqual(AssistCardCommand.matching("Rebuild the preview")?.toolName, "rebuild_preview")
        XCTAssertEqual(AssistCardCommand.matching("Undo that")?.toolName, "undo_last_change")
        XCTAssertEqual(
            AssistCardCommand.matching("Publish tomorrow's class")?.toolName, "publish_class_on"
        )
    }

    /// The separator has to survive the real titles. None contains a "|",
    /// and this fails if somebody adds one that does.
    func testNoGroupTitleContainsTheSeparator() {
        for title in AssistPromptShelfTests.groupTitles {
            XCTAssertFalse(title.contains("|"), "\(title) would corrupt the stored preference")
            XCTAssertFalse(title.isEmpty)
        }
    }

    /// Publishing is not the act that reaches students — deploying is.
    ///
    /// The publish group was called "Showing work to students", which taught
    /// exactly the wrong lesson: that pressing Publish is the moment of no
    /// return. It is the opposite — publishing is the safe, undoable half, and
    /// the deploy group is the one that says what it does. A teacher who
    /// believes otherwise hesitates over the wrong button.
    func testNoGroupTitleClaimsPublishingReachesStudents() {
        for title in AssistPromptShelfTests.groupTitles {
            if title == "Putting the site online" {
                continue
            }
            XCTAssertFalse(title.lowercased().contains("student"),
                           "“\(title)” promises what only a deploy does")
        }
    }

    /// The titles as they appear in `AssistPromptShelfView.groups`. Listed
    /// rather than read out of the view, which would make the test agree with
    /// whatever the view said.
    private static let groupTitles: [String] = [
        "Making pages visible",
        "Taking it back",
        "Checking",
        "Putting the site online",
    ]
}
