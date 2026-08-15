import XCTest
@testable import QuartzTeachers

/// Where the tails go, which is what makes a column of bubbles read as turns
/// rather than as a pile of interruptions.
@MainActor
final class AssistChatLayoutTests: XCTestCase {

    // MARK: - Functions

    /// One tail per run, on the LAST thing that participant said before the
    /// other one answered. A tail on every bubble makes three sentences look
    /// like three separate attempts to get a word in.
    func testOnlyTheLastOfARunWearsTheTail() {
        let speakers: [AssistAgent.Entry.Speaker] = [.assistant, .assistant, .teacher]

        XCTAssertFalse(AssistChatLayout.showsTail(at: 0, in: speakers))
        XCTAssertTrue(AssistChatLayout.showsTail(at: 1, in: speakers), "The end of the assistant's turn")
        XCTAssertTrue(AssistChatLayout.showsTail(at: 2, in: speakers), "Nothing said after it yet")
    }

    /// The newest message always has a tail, because the turn has not been
    /// answered yet. Waiting for a reply before drawing it would make the
    /// conversation twitch every time one arrived.
    func testTheLastMessageAlwaysWearsOne() {
        XCTAssertTrue(AssistChatLayout.showsTail(at: 0, in: [.teacher]))
        XCTAssertTrue(AssistChatLayout.showsTail(at: 1, in: [.teacher, .assistant]))
    }

    /// A tool result between two things the assistant said does NOT end its
    /// turn: nobody spoke, something merely happened. Counting it would break
    /// one answer into two and put a tail in the middle of a sentence.
    func testSomethingHappeningDoesNotEndATurn() {
        let speakers: [AssistAgent.Entry.Speaker] = [
            .assistant, .toolResult(name: "publish_pages"), .assistant, .teacher,
        ]

        XCTAssertFalse(AssistChatLayout.showsTail(at: 0, in: speakers),
                       "The assistant is still talking after the tool ran")
        XCTAssertTrue(AssistChatLayout.showsTail(at: 2, in: speakers),
                      "This is where its turn actually ends")
    }

    /// Things nobody said never wear one. A bubble is a claim that somebody
    /// spoke, and a note about what happened is not that.
    func testResultsAndProblemsNeverWearATail() {
        let speakers: [AssistAgent.Entry.Speaker] = [.toolResult(name: "check_section"), .problem]

        XCTAssertFalse(AssistChatLayout.showsTail(at: 0, in: speakers))
        XCTAssertFalse(AssistChatLayout.showsTail(at: 1, in: speakers))
    }

    func testAlternatingTurnsEachWearOne() {
        let speakers: [AssistAgent.Entry.Speaker] = [.teacher, .assistant, .teacher]

        for index in speakers.indices {
            XCTAssertTrue(AssistChatLayout.showsTail(at: index, in: speakers), "index \(index)")
        }
    }

    /// An index off the end is not a crash. The transcript and the speaker
    /// list are built separately, and a mismatch must degrade to "no tail".
    func testAnIndexPastTheEndIsSafe() {
        XCTAssertFalse(AssistChatLayout.showsTail(at: 9, in: [.teacher]))
        XCTAssertFalse(AssistChatLayout.showsTail(at: 0, in: []))
    }

    // MARK: - Sides

    func testTheTeacherIsOnOneSideAndTheAssistantTheOther() {
        XCTAssertEqual(AssistChatLayout.side(of: .teacher), .teacher)
        XCTAssertEqual(AssistChatLayout.side(of: .assistant), .assistant)
        XCTAssertEqual(AssistChatLayout.side(of: .problem), .neither)
        XCTAssertEqual(AssistChatLayout.side(of: .toolResult(name: "undo_last_change")), .neither)
    }
}
