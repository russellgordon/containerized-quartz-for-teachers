import XCTest
@testable import QuartzTeachers

/// Bringing an archived course or section back.
final class CourseRestorerTests: XCTestCase {

    // MARK: - Functions

    /// A working folder holding one course with two sections.
    @MainActor
    func makeWorkspace() throws -> (courses: URL, course: Course) {
        let root: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("restore-\(UUID().uuidString)")
        let coursesURL: URL = root.appendingPathComponent("courses")
        let courseURL: URL = coursesURL.appendingPathComponent("IZN2O")
        try FileManager.default.createDirectory(at: courseURL.appendingPathComponent("section1"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: courseURL.appendingPathComponent("section2"), withIntermediateDirectories: true)
        try "# one".write(to: courseURL.appendingPathComponent("section1/index.md"), atomically: true, encoding: .utf8)

        let configuration: [String: Any] = [
            "course_code": "IZN2O",
            "course_name": "Test Course",
            "section_numbers": [1, 2],
            "num_sections": 2,
        ]
        let data: Data = try JSONSerialization.data(withJSONObject: configuration, options: [.prettyPrinted])
        try data.write(to: courseURL.appendingPathComponent("course_config.json"))

        let loaded: CourseConfiguration = try CourseConfiguration(contentsOf: courseURL.appendingPathComponent("course_config.json"))
        let course: Course = Course(code: "IZN2O", directoryURL: courseURL, configuration: loaded)
        return (coursesURL, course)
    }

    @MainActor
    func testASectionComesBackAndIsListedAgain() throws {
        let (coursesURL, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: coursesURL.deletingLastPathComponent()) }

        let archiveURL: URL = try CourseArchiver.archiveAndRemoveSection(1, from: course, coursesDirectoryURL: coursesURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: course.sectionDirectoryURL(forSection: 1).path))
        XCTAssertEqual(course.sectionNumbers, [2], "Archiving takes the section out of the settings")

        let item = try XCTUnwrap(ArchivedItem.from(fileURL: archiveURL, courseCode: "IZN2O"))
        try CourseRestorer.restore(item, coursesDirectoryURL: coursesURL, courses: [course])

        XCTAssertTrue(FileManager.default.fileExists(atPath: course.sectionDirectoryURL(forSection: 1).appendingPathComponent("index.md").path),
                      "The section's content should be back")
        let reloaded: CourseConfiguration = try CourseConfiguration(contentsOf: course.configFileURL)
        XCTAssertEqual(reloaded.sectionNumbers, [1, 2], "The section must be listed again, in order")
        XCTAssertFalse(FileManager.default.fileExists(atPath: archiveURL.path), "A restored item is no longer archived")
    }

    @MainActor
    func testAWholeCourseComesBack() throws {
        let (coursesURL, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: coursesURL.deletingLastPathComponent()) }

        let archiveURL: URL = try CourseArchiver.archiveAndRemoveCourse(course, coursesDirectoryURL: coursesURL)
        XCTAssertFalse(FileManager.default.fileExists(atPath: course.directoryURL.path))

        let item = try XCTUnwrap(ArchivedItem.from(fileURL: archiveURL, courseCode: "IZN2O"))
        try CourseRestorer.restore(item, coursesDirectoryURL: coursesURL, courses: [])

        XCTAssertTrue(FileManager.default.fileExists(atPath: course.directoryURL.appendingPathComponent("course_config.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: course.directoryURL.appendingPathComponent("section1/index.md").path))
    }

    @MainActor
    func testASectionWillNotRestoreWithoutItsCourse() throws {
        let (coursesURL, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: coursesURL.deletingLastPathComponent()) }

        let archiveURL: URL = try CourseArchiver.archiveAndRemoveSection(1, from: course, coursesDirectoryURL: coursesURL)
        let item = try XCTUnwrap(ArchivedItem.from(fileURL: archiveURL, courseCode: "IZN2O"))

        XCTAssertThrowsError(try CourseRestorer.restore(item, coursesDirectoryURL: coursesURL, courses: [])) { error in
            let message: String = (error as? LocalizedError)?.errorDescription ?? ""
            XCTAssertTrue(message.contains("Restore the course first"), "Got: \(message)")
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: archiveURL.path), "A refused restore must leave the archive alone")
    }

    @MainActor
    func testNothingIsWrittenOverAnExistingSection() throws {
        let (coursesURL, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: coursesURL.deletingLastPathComponent()) }

        let archiveURL: URL = try CourseArchiver.archiveAndRemoveSection(1, from: course, coursesDirectoryURL: coursesURL)
        // The teacher makes a new section 1 before restoring the old one.
        try FileManager.default.createDirectory(at: course.sectionDirectoryURL(forSection: 1), withIntermediateDirectories: true)
        try "# new work".write(to: course.sectionDirectoryURL(forSection: 1).appendingPathComponent("index.md"), atomically: true, encoding: .utf8)

        let item = try XCTUnwrap(ArchivedItem.from(fileURL: archiveURL, courseCode: "IZN2O"))
        XCTAssertThrowsError(try CourseRestorer.restore(item, coursesDirectoryURL: coursesURL, courses: [course]))

        let survived: String = try String(contentsOf: course.sectionDirectoryURL(forSection: 1).appendingPathComponent("index.md"), encoding: .utf8)
        XCTAssertEqual(survived, "# new work", "Newer work must not be overwritten")
    }

    @MainActor
    func testACourseWillNotRestoreOverOneThatIsBack() throws {
        let (coursesURL, course) = try makeWorkspace()
        defer { try? FileManager.default.removeItem(at: coursesURL.deletingLastPathComponent()) }

        let archiveURL: URL = try CourseArchiver.archiveAndRemoveCourse(course, coursesDirectoryURL: coursesURL)
        try FileManager.default.createDirectory(at: course.directoryURL, withIntermediateDirectories: true)

        let item = try XCTUnwrap(ArchivedItem.from(fileURL: archiveURL, courseCode: "IZN2O"))
        XCTAssertThrowsError(try CourseRestorer.restore(item, coursesDirectoryURL: coursesURL, courses: [])) { error in
            let message: String = (error as? LocalizedError)?.errorDescription ?? ""
            XCTAssertTrue(message.contains("already in Courses & Clubs"), "Got: \(message)")
        }
    }
}
