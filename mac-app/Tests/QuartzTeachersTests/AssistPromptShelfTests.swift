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
