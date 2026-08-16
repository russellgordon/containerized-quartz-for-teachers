import XCTest
@testable import QuartzTeachers

/// Runs `contracts/course-management.json` — the names a course's files carry,
/// and the rules for adding a section.
///
/// **Why the naming grammar has to be shared rather than described.** The two
/// apps list each other's files. A course backed up on a Mac and opened on
/// Windows must appear in the Backups list; a parser rewritten from memory on
/// the other side makes it vanish, and a teacher looking for the copy they
/// made before a risky edit finds nothing. Worse in the other direction: an
/// archive that reads as a backup is a teacher restoring the wrong thing.
@MainActor
final class CourseManagementContractTests: XCTestCase {

    // MARK: - Three kinds of zip, told apart by name

    func testTheZipNamesAreReadAsTheContractSays() throws {
        let section: [String: Any] = try CourseManagementContractTests.section("zipNames")
        let code: String = try XCTUnwrap(section["courseCode"] as? String)
        let folder: URL = FileManager.default.temporaryDirectory.appendingPathComponent("names")

        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let name: String = try XCTUnwrap(testCase["name"] as? String)
            let kind: String = try XCTUnwrap(testCase["kind"] as? String)
            let url: URL = folder.appendingPathComponent(name)

            let backup: BackupItem? = BackupItem.from(fileURL: url, courseCode: code)
            let archive: ArchivedItem? = ArchivedItem.from(fileURL: url, courseCode: code)

            switch kind {
            case "backup":
                XCTAssertNotNil(backup, "\(name) should be read as a backup")
                XCTAssertNil(archive, "\(name) must NOT also read as an archive")
                if let expectedSection = testCase["section"] as? Int {
                    XCTAssertEqual(
                        backup?.maker, .assistant(sectionNumber: expectedSection),
                        "\(name): the assistant's own backups say so in the name"
                    )
                } else if testCase["maker"] as? String == "teacher" {
                    XCTAssertEqual(backup?.maker, .teacher, name)
                }
            case "archive":
                XCTAssertNotNil(archive, "\(name) should be read as an archive")
                XCTAssertNil(backup, "\(name) must NOT also read as a backup")
                XCTAssertEqual(archive?.sectionNumber, testCase["section"] as? Int, name)
            default:
                XCTAssertNil(backup, "\(name) must not be read as a backup")
                XCTAssertNil(archive, "\(name) must not be read as an archive")
            }
        }
    }

    // MARK: - Adding a section

    func testTheSuggestedSectionNumberIsTheSmallestFree() throws {
        let section: [String: Any] = try CourseManagementContractTests.section("sectionNumbers")
        for testCase in try XCTUnwrap(section["suggested"] as? [[String: Any]]) {
            let existing: [Int] = try XCTUnwrap(testCase["existing"] as? [Int])
            XCTAssertEqual(
                SectionAdder.suggestedNumber(existing: existing),
                testCase["expect"] as? Int,
                "existing \(existing)"
            )
        }
    }

    func testTheEntryProblemsAreWordedAsTheContractSays() throws {
        let section: [String: Any] = try CourseManagementContractTests.section("sectionNumbers")
        for testCase in try XCTUnwrap(section["entryProblems"] as? [[String: Any]]) {
            let entry: String = try XCTUnwrap(testCase["entry"] as? String)
            XCTAssertEqual(
                SectionAdder.entryProblem(
                    entry, existing: try XCTUnwrap(testCase["existing"] as? [Int]), courseCode: "ICS3U"
                ),
                testCase["expectProblem"] as? String,
                "entry “\(entry)”"
            )
        }
        for testCase in try XCTUnwrap(section["addable"] as? [[String: Any]]) {
            let entry: String = try XCTUnwrap(testCase["entry"] as? String)
            XCTAssertEqual(
                SectionAdder.entryIsAddable(
                    entry, existing: try XCTUnwrap(testCase["existing"] as? [Int])
                ),
                testCase["expect"] as? Bool,
                "entry “\(entry)”"
            )
        }
    }

    // MARK: - What a course code says about the grade

    func testTheGradeLabelsAreWhatTheContractSays() throws {
        let section: [String: Any] = try CourseManagementContractTests.section("gradeLabels")
        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let code: String = try XCTUnwrap(testCase["code"] as? String)
            XCTAssertEqual(SectionAdder.gradeLabel(forCourseCode: code), testCase["expect"] as? String, code)
        }
    }

    // MARK: - The stamp new pages carry

    /// Matched exactly so a page added in March sits beside a page made at
    /// setup without a teacher ever seeing two forms of the same field.
    func testTheTimestampMatchesTheWizardsForm() throws {
        let section: [String: Any] = try CourseManagementContractTests.section("timestampFormat")
        let written: String = SectionAdder.timestamp(for: Date(timeIntervalSince1970: 1_786_000_000))

        // Shape rather than value: the offset is this machine's.
        XCTAssertEqual(written.count, try XCTUnwrap(section["example"] as? String).count)
        XCTAssertTrue(written.contains("T"), written)
        XCTAssertTrue(written.contains(".000"), written)
        let head: String = String(written.prefix(10))
        XCTAssertNotNil(CalendarDay(text: head), "\(head) should be a yyyy-MM-dd date")
    }

    // MARK: - Private

    private static func section(_ name: String) throws -> [String: Any] {
        let url: URL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("contracts/course-management.json")
        let all: [String: Any] = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]
        )
        return try XCTUnwrap(all[name] as? [String: Any], "No \(name) in course-management.json")
    }
}
