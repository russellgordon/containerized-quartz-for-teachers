import XCTest
@testable import QuartzTeachers

/// Adding a brand-new section to an existing course — the reverse of
/// removing one.
final class SectionAdderTests: XCTestCase {

    // MARK: - Functions

    /// A working folder holding one course with sections 1 and 3 — a gap on
    /// purpose, since a teacher's section numbers need not be contiguous.
    @MainActor
    func makeWorkspace() throws -> (root: URL, course: Course) {
        let root: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("add-section-\(UUID().uuidString)")
        let courseURL: URL = root.appendingPathComponent("courses/ICS3U")
        try FileManager.default.createDirectory(at: courseURL.appendingPathComponent("section1"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: courseURL.appendingPathComponent("section3"), withIntermediateDirectories: true)

        let configuration: [String: Any] = [
            "course_code": "ICS3U",
            "course_name": "Introduction to Computer Science",
            "section_numbers": [1, 3],
            "num_sections": 2,
            "per_section_folders": ["All Classes", "Notes"],
            "per_section_files": ["Snippets.md", "Private Notes.md"],
        ]
        let data: Data = try JSONSerialization.data(withJSONObject: configuration, options: [.prettyPrinted])
        try data.write(to: courseURL.appendingPathComponent("course_config.json"))

        let loaded: CourseConfiguration = try CourseConfiguration(contentsOf: courseURL.appendingPathComponent("course_config.json"))
        let course: Course = Course(code: "ICS3U", directoryURL: courseURL, configuration: loaded)
        return (root, course)
    }

    @MainActor
    func testAddingASectionScaffoldsWhatTheWizardWould() throws {
        let (root, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: root) }

        try SectionAdder.addSection(2, to: course)

        let sectionURL: URL = course.sectionDirectoryURL(forSection: 2)
        let indexText: String = try String(contentsOf: sectionURL.appendingPathComponent("index.md"), encoding: .utf8)
        XCTAssertTrue(indexText.contains("title: Grade 11 Introduction to Computer Science, Section 2"),
                      "The landing page is titled the way the wizard titles one")
        XCTAssertTrue(indexText.contains("draft: false"))

        for folderName in ["All Classes", "Notes"] {
            let folderIndex: URL = sectionURL.appendingPathComponent(folderName).appendingPathComponent("index.md")
            XCTAssertTrue(FileManager.default.fileExists(atPath: folderIndex.path),
                          "\(folderName) should be scaffolded with its own index")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: sectionURL.appendingPathComponent("Snippets.md").path),
                      "Per-section files should be scaffolded too")

        // Even with no sibling to imitate (the fixture's sections are bare
        // folders), the teacher's private pages start as drafts — that is
        // what keeps them from being published.
        let privateNotes: String = try String(contentsOf: sectionURL.appendingPathComponent("Private Notes.md"), encoding: .utf8)
        XCTAssertTrue(privateNotes.contains("draft: true"),
                      "Private Notes.md must start unpublished")
        let snippets: String = try String(contentsOf: sectionURL.appendingPathComponent("Snippets.md"), encoding: .utf8)
        XCTAssertTrue(snippets.contains("draft: false"),
                      "An ordinary per-section file still starts published")

        let reloaded: CourseConfiguration = try CourseConfiguration(contentsOf: course.configFileURL)
        XCTAssertEqual(reloaded.sectionNumbers, [1, 2, 3], "The new number joins the settings, in order")
    }

    @MainActor
    func testAClubGetsNoGradeInItsTitle() throws {
        let (root, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: root) }

        // Rename the course a club: the code has no grade digit.
        course.configuration.courseName = "Coding Club"
        XCTAssertEqual(SectionAdder.gradeLabel(forCourseCode: "CODING"), "")
        XCTAssertEqual(SectionAdder.gradeLabel(forCourseCode: "SNC1W"), "Grade 9")
        XCTAssertEqual(SectionAdder.gradeLabel(forCourseCode: "ICS3U"), "Grade 11")
        XCTAssertEqual(SectionAdder.gradeLabel(forCourseCode: "ABC5X"), "Grade ?")
    }

    @MainActor
    func testAnExistingSectionIsRefused() throws {
        let (root, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertThrowsError(try SectionAdder.addSection(3, to: course)) { error in
            XCTAssertTrue(error.localizedDescription.contains("already exists"),
                          "The refusal should say the section already exists")
        }
        let reloaded: CourseConfiguration = try CourseConfiguration(contentsOf: course.configFileURL)
        XCTAssertEqual(reloaded.sectionNumbers, [1, 3], "A refused add changes nothing")
    }

    @MainActor
    func testALeftoverFolderIsNeverWrittenOver() throws {
        let (root, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: root) }

        // A section2 folder on disk but not in the settings — perhaps put
        // there by hand. Its content must survive an attempted add.
        let strayURL: URL = course.sectionDirectoryURL(forSection: 2)
        try FileManager.default.createDirectory(at: strayURL, withIntermediateDirectories: true)
        try "precious work".write(to: strayURL.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)

        XCTAssertThrowsError(try SectionAdder.addSection(2, to: course))
        let preserved: String = try String(contentsOf: strayURL.appendingPathComponent("notes.md"), encoding: .utf8)
        XCTAssertEqual(preserved, "precious work")
    }

    /// The Exemplar bug: a course whose sections keep some pages as
    /// unpublished drafts grew a new section whose copies of those pages
    /// were suddenly published. A new section must behave like the sections
    /// beside it, so each scaffolded file carries its sibling's frontmatter.
    @MainActor
    func testANewSectionKeepsItsSiblingsDraftsAndFlags() throws {
        let (root, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: root) }

        let siblingSnippets: String = """
        ---
        title: Snippets
        draft: true
        created: 2026-09-08T07:00:00.000-0400
        transcludeTitleSize: h2
        ---
        Kept out of the published site on purpose.
        """
        try siblingSnippets.write(to: course.sectionDirectoryURL(forSection: 1).appendingPathComponent("Snippets.md"), atomically: true, encoding: .utf8)

        let siblingIndex: String = """
        ---
        title: Grade 11 Introduction to Computer Science, Section 1
        created: 2026-09-08T07:00:00.000-0400
        enableToc: false
        excludeBacklinks: true
        draft: false
        ---
        # Most Recent Class
        """
        try siblingIndex.write(to: course.sectionDirectoryURL(forSection: 1).appendingPathComponent("index.md"), atomically: true, encoding: .utf8)

        try SectionAdder.addSection(2, to: course)

        let newSnippets: String = try String(contentsOf: course.sectionDirectoryURL(forSection: 2).appendingPathComponent("Snippets.md"), encoding: .utf8)
        XCTAssertTrue(newSnippets.contains("draft: true"),
                      "A page the siblings keep as a draft must start as a draft here too")
        XCTAssertTrue(newSnippets.contains("transcludeTitleSize: h2"),
                      "Display flags the teacher set should carry over")
        XCTAssertFalse(newSnippets.contains("2026-09-08"),
                       "created: should be freshened, not copied")

        let newIndex: String = try String(contentsOf: course.sectionDirectoryURL(forSection: 2).appendingPathComponent("index.md"), encoding: .utf8)
        XCTAssertTrue(newIndex.contains("title: Grade 11 Introduction to Computer Science, Section 2"),
                      "The landing page takes its sibling's title with the number swapped")
        XCTAssertTrue(newIndex.contains("enableToc: false"))
        XCTAssertTrue(newIndex.contains("excludeBacklinks: true"))
    }

    /// The other Exemplar bug: SNC1W is named "Grade 9 Science", and the
    /// scaffolded title read "Grade 9 Grade 9 Science, Section 3".
    @MainActor
    func testTheGradeIsNotDoubledWhenTheNameAlreadyCarriesIt() throws {
        let (root, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: root) }

        course.configuration.courseName = "Grade 11 Computer Science"
        XCTAssertEqual(SectionAdder.sectionTitle(for: course, sectionNumber: 2),
                       "Grade 11 Computer Science, Section 2")

        course.configuration.courseName = "Introduction to Computer Science"
        XCTAssertEqual(SectionAdder.sectionTitle(for: course, sectionNumber: 2),
                       "Grade 11 Introduction to Computer Science, Section 2")

        // A grade EMBEDDED in the name (the Ontario catalog's style) must
        // not be doubled either.
        course.configuration.courseName = "Computer Science, Grade 11, U"
        XCTAssertEqual(SectionAdder.sectionTitle(for: course, sectionNumber: 2),
                       "Computer Science, Grade 11, U, Section 2")

        // And the switch turns the grade off entirely.
        course.configuration.showGradeInTitle = false
        course.configuration.courseName = "Introduction to Computer Science"
        XCTAssertEqual(SectionAdder.sectionTitle(for: course, sectionNumber: 2),
                       "Introduction to Computer Science, Section 2")
    }

    @MainActor
    func testTheSuggestionIsTheSmallestFreeNumber() {
        XCTAssertEqual(SectionAdder.suggestedNumber(existing: [1, 3]), 2)
        XCTAssertEqual(SectionAdder.suggestedNumber(existing: [1, 2, 3]), 4)
        XCTAssertEqual(SectionAdder.suggestedNumber(existing: [2, 4, 5]), 1,
                       "Sections need not start at 1, so 1 can be the one that is missing")
        XCTAssertEqual(SectionAdder.suggestedNumber(existing: []), 1)
    }

    @MainActor
    func testTypedEntriesAreJudgedLikeTheWizardJudgesThem() {
        // Nothing typed yet: no warning, but nothing to add either.
        XCTAssertNil(SectionAdder.entryProblem("", existing: [1], courseCode: "ICS3U"))
        XCTAssertFalse(SectionAdder.entryIsAddable("", existing: [1]))

        // A duplicate is called out by name.
        XCTAssertEqual(SectionAdder.entryProblem("1", existing: [1], courseCode: "ICS3U"),
                       "Section 1 of ICS3U already exists.")
        XCTAssertFalse(SectionAdder.entryIsAddable("1", existing: [1]))

        // Zero is not a section, said the same careful way the wizard says it.
        XCTAssertEqual(SectionAdder.entryProblem("0", existing: [1], courseCode: "ICS3U"),
                       "“0” isn’t a section number — sections are 1 or higher.")

        // A fresh number passes without comment.
        XCTAssertNil(SectionAdder.entryProblem("2", existing: [1], courseCode: "ICS3U"))
        XCTAssertTrue(SectionAdder.entryIsAddable("2", existing: [1]))
    }

    @MainActor
    func testTheTimestampMatchesTheWizardsForm() {
        let stamp: String = SectionAdder.timestamp(for: Date(timeIntervalSince1970: 1_754_800_000))
        // e.g. 2026-08-10T14:26:40.000-0400 — digits, T, and a zone offset
        // with no colon, exactly as the wizard writes it.
        let pattern: String = #"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.000[+-]\d{4}$"#
        XCTAssertNotNil(stamp.range(of: pattern, options: .regularExpression),
                        "\(stamp) should match the wizard's created: form")
    }
}
