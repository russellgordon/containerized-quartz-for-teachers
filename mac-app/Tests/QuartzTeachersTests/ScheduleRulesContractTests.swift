import XCTest
@testable import QuartzTeachers

/// Runs `contracts/schedule-rules.json` — how a teacher's own list of class
/// dates is read.
///
/// All of it is pure input to output, which is why all of it is portable: a
/// date form that reads as the 8th of September on a Mac has to read as the
/// 8th of September on Windows, and neither app is entitled to its own answer.
/// The stakes are why it is worth pinning as data rather than as prose — a
/// date read the wrong way round does not fail, it dates a class wrongly and
/// waits for a teacher to notice.
@MainActor
final class ScheduleRulesContractTests: XCTestCase {

    // MARK: - The forms a teacher writes

    func testEveryAcceptedFormReadsToTheSameDay() throws {
        let section: [String: Any] = try ScheduleRulesContractTests.section("acceptedDateForms")
        let expected: String = try XCTUnwrap(section["expectDate"] as? String)

        for written in try XCTUnwrap(section["inputs"] as? [String]) {
            let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromTypedText: written)
            guard case .dates(let reading) = outcome else {
                XCTFail("“\(written)” did not read as a date at all")
                continue
            }
            XCTAssertEqual(reading.datesText, [expected], "“\(written)”")
        }
    }

    // MARK: - The ambiguity that is settled, and the one that is asked about

    func testSlashOrderingIsSettledByTheColumnOrAsked() throws {
        let section: [String: Any] = try ScheduleRulesContractTests.section("slashOrdering")

        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let name: String = try XCTUnwrap(testCase["name"] as? String)
            let rows: [String] = try XCTUnwrap(testCase["input"] as? [String])
            let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(
                fromTypedText: rows.joined(separator: "\n")
            )
            let asks: Bool = try XCTUnwrap(testCase["expectAsksTheTeacher"] as? Bool)

            switch outcome {
            case .dates(let reading):
                XCTAssertFalse(asks, "\(name): the contract says this asks, and it did not")
                if let expected = testCase["expectDates"] as? [String] {
                    XCTAssertEqual(reading.datesText, expected, name)
                }
                XCTAssertNil(reading.chosenOrdering, "\(name): nobody was asked, so nothing was chosen")
            case .question(let question):
                XCTAssertTrue(asks, "\(name): the contract says this is settled, and it asked")
                if let quoted = testCase["expectQuestionQuotes"] as? String {
                    XCTAssertEqual(question.written, quoted, "\(name): the question quotes the teacher's own value")
                }
                // Both readings offered in words, never as a format string.
                XCTAssertFalse(question.dayFirstSpoken.isEmpty)
                XCTAssertFalse(question.monthFirstSpoken.isEmpty)
                XCTAssertNotEqual(question.dayFirstSpoken, question.monthFirstSpoken)
            }
        }
    }

    // MARK: - The address a teacher pastes

    func testGoogleSheetLinksBecomeTheirCSVAddress() throws {
        let section: [String: Any] = try ScheduleRulesContractTests.section("googleSheetLinks")

        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let link: String = try XCTUnwrap(testCase["input"] as? String)
            if let expected = testCase["expectCSVURL"] as? String {
                XCTAssertEqual(
                    try SectionScheduleSource.csvURL(forGoogleSheetLink: link).absoluteString, expected, link
                )
                continue
            }
            let expectedProblem: String = try XCTUnwrap(testCase["expectProblem"] as? String)
            do {
                _ = try SectionScheduleSource.csvURL(forGoogleSheetLink: link)
                XCTFail("\(link) should have been refused as \(expectedProblem)")
            } catch let problem as SectionScheduleSource.Problem {
                XCTAssertEqual(
                    ScheduleRulesContractTests.name(of: problem), expectedProblem,
                    "\(link): refused, but not for the reason the contract names"
                )
            }
        }
    }

    func testTheTabIdentifierIsCarriedAcross() throws {
        let section: [String: Any] = try ScheduleRulesContractTests.section("tabIdentifier")
        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let link: String = try XCTUnwrap(testCase["input"] as? String)
            XCTAssertEqual(
                SectionScheduleSource.tabIdentifier(inGoogleSheetLink: link),
                testCase["expectTab"] as? String, link
            )
        }
    }

    // MARK: - The words that arrive literally

    func testTheRelativeDaysAreUnderstoodOrRefused() throws {
        let section: [String: Any] = try ScheduleRulesContractTests.section("relativeDays")
        let today: CalendarDay = try XCTUnwrap(
            CalendarDay(text: try XCTUnwrap(section["today"] as? String))
        )
        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let written: String = try XCTUnwrap(testCase["input"] as? String)
            XCTAssertEqual(
                AssistToolRunner.day(named: written, today: today)?.text,
                testCase["expectDate"] as? String,
                "“\(written)” read against \(today.text)"
            )
        }
    }

    // MARK: - Private

    /// The contract names problems by case, not by message: the MESSAGE is a
    /// sentence a teacher reads and belongs to the wording contract, while
    /// WHICH refusal it is has to be the same on both platforms.
    private static func name(of problem: SectionScheduleSource.Problem) -> String {
        switch problem {
        case .notAGoogleSheetLink:
            return "notAGoogleSheetLink"
        case .aPublishedSheetLink:
            return "aPublishedSheetLink"
        case .sheetIsNotShared:
            return "sheetIsNotShared"
        case .nothingToRead:
            return "nothingToRead"
        case .unreadableEntries:
            return "unreadableEntries"
        case .contradictoryOrdering:
            return "contradictoryOrdering"
        case .couldNotFetch:
            return "couldNotFetch"
        case .unsupportedFile:
            return "unsupportedFile"
        case .couldNotReadFile:
            return "couldNotReadFile"
        case .noStartDatesInCalendar:
            return "noStartDatesInCalendar"
        }
    }

    private static func section(_ name: String) throws -> [String: Any] {
        let url: URL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("contracts/schedule-rules.json")
        let all: [String: Any] = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]
        )
        return try XCTUnwrap(all[name] as? [String: Any], "No \(name) in schedule-rules.json")
    }
}
