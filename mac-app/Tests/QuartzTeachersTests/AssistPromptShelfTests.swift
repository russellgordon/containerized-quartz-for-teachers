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
        let titles: [String] = [
            "Showing work to students",
            "Taking it back",
            "Checking",
            "Putting the site online",
        ]
        for title in titles {
            XCTAssertFalse(title.contains("|"), "\(title) would corrupt the stored preference")
            XCTAssertFalse(title.isEmpty)
        }
    }
}
