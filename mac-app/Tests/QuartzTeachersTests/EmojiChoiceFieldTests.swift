import XCTest
@testable import QuartzTeachers

/// The emoji field's judgement: one emoji at a time, the most recent wins,
/// and things that are not emoji never sneak in.
final class EmojiChoiceFieldTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testTheMostRecentlyEnteredEmojiWins() {
        // The palette inserts beside what is already there, so a field
        // reading "📚🔬" means the teacher just chose the microscope.
        XCTAssertEqual(EmojiChoiceField.latestEmoji(in: "📚🔬"), "🔬")
        XCTAssertEqual(EmojiChoiceField.latestEmoji(in: "🔬"), "🔬")
    }

    @MainActor
    func testTextThatIsNotAnEmojiIsIgnored() {
        XCTAssertNil(EmojiChoiceField.latestEmoji(in: "abc"))
        XCTAssertNil(EmojiChoiceField.latestEmoji(in: "3"))
        XCTAssertNil(EmojiChoiceField.latestEmoji(in: ""))
        // Typed letters around an emoji do not hide it.
        XCTAssertEqual(EmojiChoiceField.latestEmoji(in: "a📚b"), "📚")
    }

    @MainActor
    func testTheHardEmojiFamiliesAllCount() {
        // Variation selector (text-default scalars shown as emoji).
        XCTAssertTrue(EmojiChoiceField.isEmoji(Character("✏️")))
        // Skin-tone modifier.
        XCTAssertTrue(EmojiChoiceField.isEmoji(Character("👍🏽")))
        // Zero-width-joiner sequence — one emoji made of several.
        XCTAssertTrue(EmojiChoiceField.isEmoji(Character("🧑‍🚀")))
        // Flag (a pair of regional indicators).
        XCTAssertTrue(EmojiChoiceField.isEmoji(Character("🇨🇦")))
        // Plain single-scalar emoji.
        XCTAssertTrue(EmojiChoiceField.isEmoji(Character("📚")))
    }

    @MainActor
    func testLettersAndDigitsAreNotEmoji() {
        // Unicode says digits ARE emoji (they can wear a keycap), so the
        // check must be stricter than the standard's own flag.
        XCTAssertFalse(EmojiChoiceField.isEmoji(Character("3")))
        XCTAssertFalse(EmojiChoiceField.isEmoji(Character("A")))
        XCTAssertFalse(EmojiChoiceField.isEmoji(Character("é")))
        XCTAssertFalse(EmojiChoiceField.isEmoji(Character("#")))
    }

    @MainActor
    func testEveryPresetPassesTheCheck() {
        for preset in EmojiCatalog.presets {
            XCTAssertEqual(preset.count, 1, "\(preset) should be one emoji")
            XCTAssertTrue(EmojiChoiceField.isEmoji(Character(preset)),
                          "\(preset) is offered as a preset, so the field must accept it")
        }
    }
}
