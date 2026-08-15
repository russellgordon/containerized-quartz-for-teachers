import XCTest
@testable import QuartzTeachers

/// Walking back through what has been asked before, with the arrow keys.
///
/// The comparison a teacher will make is to a Terminal, so the things a
/// Terminal gets right are what is pinned here — most of all that a
/// half-typed line survives the walk, which is the detail people notice only
/// by losing a sentence to it.
final class AssistPromptHistoryTests: XCTestCase {

    // MARK: - Walking back and forward

    func testUpWalksBackwardsNewestFirst() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Publish Unit 2, Day 3")
        history.remember("Rebuild the preview")
        history.remember("Deploy now")

        XCTAssertEqual(history.earlier(startingFrom: ""), "Deploy now")
        XCTAssertEqual(history.earlier(startingFrom: ""), "Rebuild the preview")
        XCTAssertEqual(history.earlier(startingFrom: ""), "Publish Unit 2, Day 3")
    }

    /// Nothing, rather than wrapping round to the newest — which would look
    /// like the keyboard had misfired.
    func testUpAtTheOldestEntryStaysPut() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Deploy now")

        XCTAssertEqual(history.earlier(startingFrom: ""), "Deploy now")
        XCTAssertNil(history.earlier(startingFrom: ""))
    }

    func testDownWalksForwardAgain() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Publish Unit 2, Day 3")
        history.remember("Deploy now")

        _ = history.earlier(startingFrom: "")
        _ = history.earlier(startingFrom: "")
        XCTAssertEqual(history.later(), "Deploy now")
    }

    /// Down with no walk under way is not a request for the newest entry —
    /// it is somebody moving the caret, and it must not overwrite the box.
    func testDownDoesNothingWhenNotWalking() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Deploy now")

        XCTAssertNil(history.later())
    }

    func testUpDoesNothingWithAnEmptyHistory() {
        var history: AssistPromptHistory = AssistPromptHistory()

        XCTAssertNil(history.earlier(startingFrom: "half a sentence"))
        XCTAssertFalse(history.isBrowsing)
    }

    // MARK: - The half-typed line

    /// The detail people notice by losing a sentence to it: press Up with
    /// something already typed, walk back, then walk forward — and the
    /// half-written sentence is handed back exactly as it was.
    func testTheHalfTypedLineComesBackAtTheEndOfTheWalk() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Publish Unit 2, Day 3")
        history.remember("Deploy now")

        XCTAssertEqual(history.earlier(startingFrom: "Unpub"), "Deploy now")
        XCTAssertEqual(history.earlier(startingFrom: "ignored once walking"), "Publish Unit 2, Day 3")
        XCTAssertEqual(history.later(), "Deploy now")
        XCTAssertEqual(history.later(), "Unpub", "The teacher's own half-typed line, not an entry")
        XCTAssertFalse(history.isBrowsing, "…and the walk is over")
    }

    /// The line in the box is only kept on the FIRST press. Keeping it on
    /// every press would mean walking back overwrote it with a recalled
    /// entry, and the teacher would never see their own words again.
    func testTheDraftIsKeptOnlyOnce() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Deploy now")
        history.remember("Rebuild the preview")

        _ = history.earlier(startingFrom: "mine")
        _ = history.earlier(startingFrom: "Rebuild the preview")
        _ = history.later()

        XCTAssertEqual(history.later(), "mine")
    }

    /// Typing ends the walk: an edited line is a new line, and Down must not
    /// replace what has just been typed.
    func testTypingEndsTheWalk() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Deploy now")

        _ = history.earlier(startingFrom: "")
        history.stopBrowsing()

        XCTAssertNil(history.later())
        XCTAssertFalse(history.isBrowsing)
    }

    // MARK: - What is remembered

    /// Testing something by running it five times should not cost five
    /// presses of Up to get past.
    func testTheSameThingTwiceInARowIsRememberedOnce() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Deploy now")
        history.remember("Deploy now")

        XCTAssertEqual(history.entries, ["Deploy now"])
    }

    /// But an earlier, non-adjacent repeat is left alone. The order things
    /// were done in is the thing being scrolled through.
    func testAnEarlierRepeatIsKeptWhereItHappened() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Deploy now")
        history.remember("Rebuild the preview")
        history.remember("Deploy now")

        XCTAssertEqual(history.entries, ["Deploy now", "Rebuild the preview", "Deploy now"])
    }

    func testBlankPromptsAreNotRemembered() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("   \n ")

        XCTAssertTrue(history.entries.isEmpty)
    }

    func testSendingSomethingEndsTheWalk() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Deploy now")
        _ = history.earlier(startingFrom: "")

        history.remember("Rebuild the preview")

        XCTAssertFalse(history.isBrowsing)
        XCTAssertNil(history.later())
    }

    func testTheOldestFallOffOnceItIsFull() {
        var history: AssistPromptHistory = AssistPromptHistory()
        for number in 1...(AssistPromptHistory.mostRemembered + 5) {
            history.remember("Publish Unit 1, Day \(number)")
        }

        XCTAssertEqual(history.entries.count, AssistPromptHistory.mostRemembered)
        XCTAssertEqual(history.entries.first, "Publish Unit 1, Day 6")
        XCTAssertEqual(history.entries.last, "Publish Unit 1, Day \(AssistPromptHistory.mostRemembered + 5)")
    }

    // MARK: - Surviving a relaunch

    /// Stored as JSON rather than with a separator, because a prompt is free
    /// text: any character chosen as a separator is one a teacher may type.
    func testItSurvivesBeingStoredAndReadBack() {
        var history: AssistPromptHistory = AssistPromptHistory()
        history.remember("Publish “Unit 2, Day 3”; and the rest")
        history.remember("What would students see in this section right now?")

        let readBack: AssistPromptHistory = AssistPromptHistory.read(fromStored: history.stored)

        XCTAssertEqual(readBack.entries, history.entries)
    }

    /// Losing the list is a small thing; refusing to open the assistant over
    /// it would not be.
    func testUnreadableStorageBecomesAnEmptyHistory() {
        let history: AssistPromptHistory = AssistPromptHistory.read(fromStored: "{ not json")

        XCTAssertTrue(history.entries.isEmpty)
    }
}
