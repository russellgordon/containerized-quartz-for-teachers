import XCTest
@testable import QuartzTeachers

/// Getting a teacher's class dates IN — from a Google Sheet, from a file they
/// exported, or from a column they pasted.
///
/// Two rules these exist to hold. First, the reading happens in Swift, so no
/// model ever gets the chance to invent a date. Second, `08/09/2026` is never
/// GUESSED: the column settles it where it can, and where it cannot the
/// teacher is asked — one question, applied to every row.
final class SectionScheduleSourceTests: XCTestCase {

    // MARK: - Types

    /// A stand-in for the network: hands back a fixed body and remembers what
    /// was asked for. No test in here ever reaches Google — a test that did
    /// would start failing the day somebody unshared a sheet.
    final class FakeFetch: @unchecked Sendable {

        // MARK: - Stored properties

        let body: Data
        var lastURL: URL?
        var count: Int = 0

        // MARK: - Initializer

        init(body: Data) {
            self.body = body
        }

        // MARK: - Functions

        func answer(_ url: URL) -> Data {
            lastURL = url
            count += 1
            return body
        }
    }

    // MARK: - Functions

    /// The dates out of an outcome, failing the test if a question came back
    /// where dates were expected.
    func dates(
        from outcome: SectionScheduleSource.Outcome,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> [String] {
        guard case .dates(let reading) = outcome else {
            XCTFail("Expected dates, not a question", file: file, line: line)
            return []
        }
        return reading.datesText
    }

    func question(
        from outcome: SectionScheduleSource.Outcome,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> SectionScheduleSource.OrderingQuestion {
        guard case .question(let raised) = outcome else {
            XCTFail("Expected the ordering question", file: file, line: line)
            throw CocoaError(.featureUnsupported)
        }
        return raised
    }

    /// A throwaway file with these contents, cleaned up by the caller.
    func writeFile(named name: String, contents: String) throws -> URL {
        let folder: URL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("schedule-source-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url: URL = folder.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Every date form a teacher plausibly produces

    func testTheAcceptedDateFormsAllReadToTheSameDay() throws {
        // Each of these is the 8th of September 2026, written the way some
        // teacher somewhere actually writes it.
        let forms: [String] = [
            "2026-09-08",
            "Sep 8, 2026",
            "September 8 2026",
            "8 September 2026",
            "8 Sept. 2026",
            "2026/09/08",
        ]
        for form in forms {
            let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromTypedText: form)
            XCTAssertEqual(try dates(from: outcome), ["2026-09-08"],
                           "“\(form)” should read as the 8th of September 2026")
        }
    }

    /// The two slash forms, each settled by the column they sit in rather
    /// than by a guess.
    func testTheTwoSlashFormsAreSettledByTheirColumn() throws {
        let dayFirst: String = """
        08/09/2026
        22/09/2026
        """
        XCTAssertEqual(
            try dates(from: try SectionScheduleSource.read(fromTypedText: dayFirst)),
            ["2026-09-08", "2026-09-22"]
        )

        let monthFirst: String = """
        09/08/2026
        09/22/2026
        """
        XCTAssertEqual(
            try dates(from: try SectionScheduleSource.read(fromTypedText: monthFirst)),
            ["2026-09-08", "2026-09-22"]
        )
    }

    // MARK: - Ordering: settled where it can be, asked where it cannot

    /// One value with a day past 12, anywhere in the column, settles every
    /// row — and the teacher is not asked.
    func testADayPastTwelveSettlesTheWholeColumnWithoutAsking() throws {
        let column: String = """
        08/09/2026
        10/09/2026
        24/09/2026
        """
        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromTypedText: column)
        guard case .dates(let reading) = outcome else {
            XCTFail("A column containing 24/09/2026 can only be day/month/year — there is nothing to ask")
            return
        }
        XCTAssertEqual(reading.datesText, ["2026-09-08", "2026-09-10", "2026-09-24"],
                       "And 08/09 must be read the same way round as the value that settled it")
        XCTAssertNil(reading.chosenOrdering, "Nobody was asked, so nothing was chosen")
    }

    /// The same, the other way round.
    func testAMonthFirstColumnIsAlsoSettledWithoutAsking() throws {
        let column: String = """
        09/08/2026
        09/24/2026
        """
        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromTypedText: column)
        XCTAssertEqual(try dates(from: outcome), ["2026-09-08", "2026-09-24"])
    }

    /// Nothing in the column can settle it, so the teacher is ASKED rather
    /// than turned away — their spreadsheet is not wrong, it just does not
    /// say. And the question quotes one of their own dates, expanded both
    /// ways, so it is answerable in a second.
    func testAFullyAmbiguousColumnRaisesTheQuestionRatherThanFailing() throws {
        let column: String = """
        08/09/2026
        10/09/2026
        """
        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromTypedText: column)
        let raised: SectionScheduleSource.OrderingQuestion = try question(from: outcome)

        XCTAssertEqual(raised.written, "08/09/2026", "The question quotes their own value")
        XCTAssertEqual(raised.dayFirstSpoken, "the 8th of September")
        XCTAssertEqual(raised.monthFirstSpoken, "the 9th of August")
        XCTAssertEqual(raised.dayFirstShort, "8 September")
        XCTAssertEqual(raised.monthFirstShort, "9 August")
        XCTAssertTrue(raised.prompt.contains("08/09/2026"))
        XCTAssertTrue(raised.prompt.contains("the 8th of September"))
        XCTAssertTrue(raised.prompt.contains("the 9th of August"))
    }

    /// The answer applies to EVERY row, including the ones that would have
    /// read fine either way. A column read two different ways down its length
    /// is the failure this whole mechanism exists to prevent.
    func testTheAnswerAppliesToEveryRowIncludingTheOnesThatWouldParseEitherWay() throws {
        let column: String = """
        08/09/2026
        09/09/2026
        01/10/2026
        """
        let raised: SectionScheduleSource.OrderingQuestion = try question(
            from: try SectionScheduleSource.read(fromTypedText: column)
        )

        let dayFirst: SectionScheduleSource.Reading = try raised.answered(.dayThenMonth)
        XCTAssertEqual(dayFirst.datesText, ["2026-09-08", "2026-09-09", "2026-10-01"])

        let monthFirst: SectionScheduleSource.Reading = try raised.answered(.monthThenDay)
        XCTAssertEqual(monthFirst.datesText, ["2026-01-10", "2026-08-09", "2026-09-09"],
                       "Every row moves, not only the ones that were ambiguous")
    }

    /// What they chose is written into the source, so months later a teacher
    /// squinting at a date can see which way it was read.
    func testTheChosenOrderingIsRecordedInTheSource() throws {
        let raised: SectionScheduleSource.OrderingQuestion = try question(
            from: try SectionScheduleSource.read(fromTypedText: "08/09/2026\n10/09/2026")
        )
        let reading: SectionScheduleSource.Reading = try raised.answered(.dayThenMonth)
        XCTAssertEqual(reading.suggestedSource, "pasted by hand, day first")
        XCTAssertEqual(reading.chosenOrdering, .dayThenMonth)

        let other: SectionScheduleSource.Reading = try raised.answered(.monthThenDay)
        XCTAssertEqual(other.suggestedSource, "pasted by hand, month first")
    }

    /// `09/09/2026` means one day whichever way round it is read, so a column
    /// of nothing but those is not a question anybody needs to answer.
    func testAColumnThatMeansTheSameEitherWayIsNotAQuestion() throws {
        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(
            fromTypedText: "09/09/2026\n11/11/2026"
        )
        XCTAssertEqual(try dates(from: outcome), ["2026-09-09", "2026-11-11"])
    }

    /// A column written both ways round cannot be fixed by one answer, so it
    /// is still refused — naming the two values that contradict each other.
    func testAColumnWrittenBothWaysRoundIsRefused() throws {
        let column: String = """
        24/09/2026
        09/24/2026
        """
        XCTAssertThrowsError(try SectionScheduleSource.read(fromTypedText: column)) { error in
            XCTAssertTrue(error.localizedDescription.contains("both ways round"))
            XCTAssertTrue(error.localizedDescription.contains("24/09/2026"))
            XCTAssertTrue(error.localizedDescription.contains("09/24/2026"))
        }
    }

    // MARK: - A partial list is refused whole

    func testOneUnreadableEntryRefusesTheWholeColumn() throws {
        let column: String = """
        2026-09-08
        sometime in October
        2026-09-14
        """
        XCTAssertThrowsError(try SectionScheduleSource.read(fromTypedText: column)) { error in
            XCTAssertTrue(error.localizedDescription.contains("sometime in October"),
                          "The refusal names what stopped it")
            XCTAssertTrue(error.localizedDescription.contains("whole list is refused"))
        }
    }

    /// A two-digit year is a guess about the century on top of a guess about
    /// the ordering, so it is not read at all.
    func testATwoDigitYearIsRefusedRatherThanAssumed() throws {
        XCTAssertThrowsError(try SectionScheduleSource.read(fromTypedText: "08/09/26"))
    }

    // MARK: - What a copied column actually looks like

    /// A heading row and blank lines come along with any column a teacher
    /// selects in a spreadsheet and copies. They should not have to tidy up.
    func testAHeaderRowAndBlankLinesAreForgiven() throws {
        let column: String = """
        Class dates

        2026-09-08

        2026-09-10
        2026-09-14

        """
        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromTypedText: column)
        XCTAssertEqual(try dates(from: outcome), ["2026-09-08", "2026-09-10", "2026-09-14"])
    }

    /// Only the FIRST line is forgiven. A heading in the middle of a column
    /// is a sign something is wrong with the list, not a tidying job.
    func testAnUnreadableLineLaterInTheColumnIsStillRefused() throws {
        let column: String = """
        Class dates
        2026-09-08
        Term 2
        2027-01-05
        """
        XCTAssertThrowsError(try SectionScheduleSource.read(fromTypedText: column)) { error in
            XCTAssertTrue(error.localizedDescription.contains("Term 2"))
        }
    }

    /// Out of order, with a repeat — which is what a spreadsheet looks like
    /// when somebody has copied a week down twice. Not an error.
    func testDatesComeBackSortedAndWithoutRepeats() throws {
        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(
            fromTypedText: "2026-09-14\n2026-09-08\n2026-09-14\n2026-09-10"
        )
        XCTAssertEqual(try dates(from: outcome), ["2026-09-08", "2026-09-10", "2026-09-14"])
    }

    // MARK: - Files

    func testACSVFileReadsItsFirstColumn() throws {
        let url: URL = try writeFile(named: "timetable.csv", contents: """
        Class dates,Notes
        2026-09-08,first day
        2026-09-10,
        2026-09-14,"quiz, unit 1"
        """)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromFileAt: url)
        guard case .dates(let reading) = outcome else {
            XCTFail("These are ISO dates — there is nothing to ask")
            return
        }
        XCTAssertEqual(reading.datesText, ["2026-09-08", "2026-09-10", "2026-09-14"])
        XCTAssertEqual(reading.suggestedSource, "timetable.csv",
                       "The file's name is the first suggestion at where these came from")
    }

    /// A calendar export is mostly things that are not the date a class
    /// meets. Only DTSTART says when an event begins, so only DTSTART is read.
    func testACalendarExportReadsItsStartDatesAndIgnoresEverythingElse() throws {
        let url: URL = try writeFile(named: "block-H.ics", contents: """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//Test//EN
        BEGIN:VEVENT
        UID:one@example.com
        DTSTAMP:20260814T120000Z
        DTSTART;TZID=America/Toronto:20260908T090000
        DTEND;TZID=America/Toronto:20260908T101500
        SUMMARY:ICS3U block H
        END:VEVENT
        BEGIN:VEVENT
        UID:two@example.com
        DTSTAMP:20260814T120000Z
        DTSTART;VALUE=DATE:20260910
        SUMMARY:ICS3U block H
        END:VEVENT
        BEGIN:VEVENT
        UID:three@example.com
        LAST-MODIFIED:20260101T000000Z
        DTSTART:20260914T090000Z
        DTEND:20260914T101500Z
        END:VEVENT
        END:VCALENDAR
        """)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let outcome: SectionScheduleSource.Outcome = try SectionScheduleSource.read(fromFileAt: url)
        XCTAssertEqual(try dates(from: outcome), ["2026-09-08", "2026-09-10", "2026-09-14"],
                       "Three DTSTARTs, and none of the DTSTAMPs or LAST-MODIFIEDs around them")
    }

    func testACalendarWithNoEventsIsRefusedInThoseWords() throws {
        let url: URL = try writeFile(named: "empty.ics", contents: """
        BEGIN:VCALENDAR
        VERSION:2.0
        END:VCALENDAR
        """)
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        XCTAssertThrowsError(try SectionScheduleSource.read(fromFileAt: url)) { error in
            XCTAssertTrue(error.localizedDescription.contains("no events"))
        }
    }

    func testAFileOfTheWrongKindIsRefusedByName() throws {
        let url: URL = try writeFile(named: "timetable.xlsx", contents: "not really a spreadsheet")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        XCTAssertThrowsError(try SectionScheduleSource.read(fromFileAt: url)) { error in
            XCTAssertTrue(error.localizedDescription.contains("timetable.xlsx"))
            XCTAssertTrue(error.localizedDescription.contains(".csv"))
        }
    }

    // MARK: - A Google Sheet

    /// The address a teacher pastes is the one in their browser. The address
    /// that hands back CSV is a different one, derived here so nobody has to
    /// know that.
    func testAPastedSheetAddressBecomesItsCSVAddress() throws {
        let edit: String = "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/edit?usp=sharing"
        XCTAssertEqual(
            try SectionScheduleSource.csvURL(forGoogleSheetLink: edit).absoluteString,
            "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/export?format=csv"
        )

        // The tab they were looking at comes across too, so they get the
        // column they had on screen.
        let withTab: String = "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/edit#gid=845210"
        XCTAssertEqual(
            try SectionScheduleSource.csvURL(forGoogleSheetLink: withTab).absoluteString,
            "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/export?format=csv&gid=845210"
        )

        XCTAssertThrowsError(try SectionScheduleSource.csvURL(forGoogleSheetLink: "https://example.com/timetable"))
    }

    /// The single most likely thing to go wrong. A sheet that has not been
    /// link-shared does not fail the fetch — Google answers cheerfully with a
    /// sign-in page. Unnamed, that is a baffling afternoon; named, it is
    /// thirty seconds in the Share menu.
    func testAnHTMLResponseIsRecognisedAsASheetThatIsNotShared() async throws {
        let signInPage: Data = Data("""
        <!DOCTYPE html><html><head><title>Sign in - Google Accounts</title></head>
        <body>Sign in to continue to Google Sheets</body></html>
        """.utf8)

        let network: FakeFetch = FakeFetch(body: signInPage)
        do {
            _ = try await SectionScheduleSource.read(
                fromGoogleSheetLink: "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/edit",
                fetch: { url in return network.answer(url) }
            )
            XCTFail("A sign-in page is not a timetable")
        } catch {
            XCTAssertTrue(
                error.localizedDescription.contains("that sheet is not shared, so Plantoir cannot read it"),
                "The teacher must be told exactly this, because it is the fix — got: \(error.localizedDescription)"
            )
        }
    }

    /// The happy path, with the fetch injected so no test ever touches the
    /// network.
    func testASharedSheetReadsItsColumn() async throws {
        let csv: Data = Data("""
        Class dates
        2026-09-08
        2026-09-10

        2026-09-14
        """.utf8)
        let network: FakeFetch = FakeFetch(body: csv)

        let outcome: SectionScheduleSource.Outcome = try await SectionScheduleSource.read(
            fromGoogleSheetLink: "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/edit#gid=0",
            fetch: { url in return network.answer(url) }
        )
        guard case .dates(let reading) = outcome else {
            XCTFail("These are ISO dates — there is nothing to ask")
            return
        }
        XCTAssertEqual(reading.datesText, ["2026-09-08", "2026-09-10", "2026-09-14"])
        XCTAssertEqual(reading.suggestedSource, "a Google Sheet")
        XCTAssertEqual(
            network.lastURL?.absoluteString,
            "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/export?format=csv&gid=0",
            "The CSV address is what gets fetched, not the /edit one that was pasted"
        )
    }

    /// A sheet whose column cannot settle its own ordering asks the same
    /// question as any other route — the fetched column is carried in the
    /// question, so answering does not go back to Google.
    func testAnAmbiguousSheetAsksWithoutFetchingTwice() async throws {
        let csv: Data = Data("08/09/2026\n10/09/2026".utf8)
        let network: FakeFetch = FakeFetch(body: csv)

        let outcome: SectionScheduleSource.Outcome = try await SectionScheduleSource.read(
            fromGoogleSheetLink: "https://docs.google.com/spreadsheets/d/1AbC_dEf-123/edit",
            fetch: { url in return network.answer(url) }
        )
        let raised: SectionScheduleSource.OrderingQuestion = try question(from: outcome)
        let reading: SectionScheduleSource.Reading = try raised.answered(.dayThenMonth)

        XCTAssertEqual(reading.datesText, ["2026-09-08", "2026-09-10"])
        XCTAssertEqual(reading.suggestedSource, "a Google Sheet, day first")
        XCTAssertEqual(network.count, 1, "Answering re-reads the column already in hand")
    }

    // MARK: - Straight through to the store

    /// Whatever route the dates came in by, they go out through the same
    /// door — so `SectionTimetable`'s own rules, above all "a partial list is
    /// refused whole", apply to all three.
    @MainActor
    func testDatesReadFromAColumnGoThroughTheExistingStore() throws {
        let root: URL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("schedule-store-\(UUID().uuidString)")
        let courseURL: URL = root.appendingPathComponent("courses/ICS3U")
        try FileManager.default.createDirectory(at: courseURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let configuration: [String: Any] = [
            "course_code": "ICS3U",
            "course_name": "Introduction to Computer Science",
            "section_numbers": [1],
            "num_sections": 1,
        ]
        let data: Data = try JSONSerialization.data(withJSONObject: configuration, options: [])
        try data.write(to: courseURL.appendingPathComponent("course_config.json"))
        let loaded: CourseConfiguration = try CourseConfiguration(
            contentsOf: courseURL.appendingPathComponent("course_config.json")
        )
        let course: Course = Course(code: "ICS3U", directoryURL: courseURL, configuration: loaded)

        let raised: SectionScheduleSource.OrderingQuestion = try question(
            from: try SectionScheduleSource.read(fromTypedText: "Dates\n08/09/2026\n10/09/2026")
        )
        let reading: SectionScheduleSource.Reading = try raised.answered(.dayThenMonth)

        let plan: RememberTimetablePlan = try SectionTimetableStore.planRememberTimetable(
            dates: reading.datesText,
            source: reading.suggestedSource,
            forSection: 1,
            in: course
        )
        try SectionTimetableStore.applyRememberTimetable(plan)

        let stored: SectionTimetable = try XCTUnwrap(
            try SectionTimetableStore.read(forSection: 1, in: course)
        )
        XCTAssertEqual(stored.datesText, ["2026-09-08", "2026-09-10"])
        XCTAssertEqual(stored.source, "pasted by hand, day first",
                       "Which way the column was read is part of where it came from")
    }
}
