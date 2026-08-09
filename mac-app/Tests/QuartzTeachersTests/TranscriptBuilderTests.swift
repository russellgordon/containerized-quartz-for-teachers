import XCTest
@testable import QuartzTeachers

final class TranscriptBuilderTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testStripsAnsiColourCodes() {
        var builder: TranscriptBuilder = TranscriptBuilder()
        builder.append(rawText: "\u{1B}[32mGreen text\u{1B}[0m\n")
        XCTAssertEqual(builder.lines, ["Green text"])
    }

    @MainActor
    func testCarriageReturnRestartsLine() {
        var builder: TranscriptBuilder = TranscriptBuilder()
        builder.append(rawText: "Progress 10%\rProgress 50%\rProgress 100%\n")
        XCTAssertEqual(builder.lines, ["Progress 100%"])
    }

    @MainActor
    func testCarriageReturnNewlinePairsAreOrdinaryLineEndings() {
        var builder: TranscriptBuilder = TranscriptBuilder()
        builder.append(rawText: "First line\r\nSecond line\r\n")
        XCTAssertEqual(builder.lines, ["First line", "Second line"])
    }

    @MainActor
    func testCarriageReturnSplitAcrossChunks() {
        var builder: TranscriptBuilder = TranscriptBuilder()
        builder.append(rawText: "First line\r")
        builder.append(rawText: "\nSecond line\r\n")
        XCTAssertEqual(builder.lines, ["First line", "Second line"])
    }

    @MainActor
    func testKeepsEmojiAndPlainText() {
        var builder: TranscriptBuilder = TranscriptBuilder()
        builder.append(rawText: "✅ Static build complete.\n")
        XCTAssertEqual(builder.lines, ["✅ Static build complete."])
    }

    @MainActor
    func testPartialLineAppearsInDisplayText() {
        var builder: TranscriptBuilder = TranscriptBuilder()
        builder.append(rawText: "Enter the course code: ")
        XCTAssertEqual(builder.displayText, "Enter the course code: ")
    }
}
