import XCTest
@testable import QuartzTeachers

/// Backups: saved copies of whole courses, made on purpose before risky
/// editing, listed in their own sidebar group, restorable, and deletable
/// for good.
final class BackupTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testABackupNameIsRecognizedAndOthersAreNot() {
        let folder: URL = URL(fileURLWithPath: "/folder/_backups/ICS3U")

        let backup: BackupItem? = BackupItem.from(
            fileURL: folder.appendingPathComponent("ICS3U_backup_2026-08-11_221530.zip"),
            courseCode: "ICS3U"
        )
        XCTAssertNotNil(backup)
        XCTAssertEqual(backup?.courseCode, "ICS3U")
        XCTAssertEqual(backup?.title, "ICS3U")

        // An archive is not a backup…
        XCTAssertNil(BackupItem.from(
            fileURL: folder.appendingPathComponent("ICS3U_2026-08-11_221530.zip"),
            courseCode: "ICS3U"
        ))
        // …nor is the wizard's automatic zip…
        XCTAssertNil(BackupItem.from(
            fileURL: folder.appendingPathComponent("2026-08-11_221530.zip"),
            courseCode: "ICS3U"
        ))
        // …nor anything that merely resembles one.
        XCTAssertNil(BackupItem.from(
            fileURL: folder.appendingPathComponent("ICS3U_backup_notadate.zip"),
            courseCode: "ICS3U"
        ))
    }

    @MainActor
    func testABackupNameIsInvisibleToTheArchivedList() {
        // The two lists share a folder; only the name separates them.
        let fileURL: URL = URL(fileURLWithPath: "/folder/_backups/ICS3U/ICS3U_backup_2026-08-11_221530.zip")
        XCTAssertNil(ArchivedItem.from(fileURL: fileURL, courseCode: "ICS3U"),
                     "A backup must never appear among archived items")
    }

    @MainActor
    func testBackingUpCopiesTheCourseAndLeavesItInPlace() throws {
        let fixture: BackupFixture = try BackupFixture()
        defer { fixture.tearDown() }

        let backupURL: URL = try CourseArchiver.backUpCourse(
            fixture.course, coursesDirectoryURL: fixture.coursesDirectoryURL
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        XCTAssertTrue(backupURL.lastPathComponent.hasPrefix("ICS3U_backup_"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixture.pageURL.path),
                      "Backing up must not move or remove the course")

        let items: [BackupItem] = WorkspaceModel.findBackupItems(in: fixture.coursesDirectoryURL)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].courseCode, "ICS3U")
    }

    @MainActor
    func testRestoringABackupBringsTheOldContentBackAndKeepsTheZip() throws {
        let fixture: BackupFixture = try BackupFixture()
        defer { fixture.tearDown() }

        _ = try CourseArchiver.backUpCourse(
            fixture.course, coursesDirectoryURL: fixture.coursesDirectoryURL
        )

        // The LLM makes a mess of the page…
        try Data("ruined".utf8).write(to: fixture.pageURL)

        // …the teacher clears the course (the app archives it first)…
        try CourseArchiver.archiveAndRemoveCourse(
            fixture.course, coursesDirectoryURL: fixture.coursesDirectoryURL
        )

        // …and restores the backup.
        let items: [BackupItem] = WorkspaceModel.findBackupItems(in: fixture.coursesDirectoryURL)
        XCTAssertEqual(items.count, 1)
        try CourseRestorer.restoreBackup(items[0], coursesDirectoryURL: fixture.coursesDirectoryURL)

        let restored: String = try String(contentsOf: fixture.pageURL, encoding: .utf8)
        XCTAssertEqual(restored, "original", "The backup's content is back")
        XCTAssertTrue(FileManager.default.fileExists(atPath: items[0].fileURL.path),
                      "Restoring keeps the backup — only deleting removes it")
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: fixture.courseURL.appendingPathComponent(".merged_output").path),
            "Rebuildable output stays out of backups"
        )
    }

    @MainActor
    func testRestoringDeclinesWhenTheCourseIsStillInPlace() throws {
        let fixture: BackupFixture = try BackupFixture()
        defer { fixture.tearDown() }

        _ = try CourseArchiver.backUpCourse(
            fixture.course, coursesDirectoryURL: fixture.coursesDirectoryURL
        )
        let items: [BackupItem] = WorkspaceModel.findBackupItems(in: fixture.coursesDirectoryURL)
        XCTAssertThrowsError(
            try CourseRestorer.restoreBackup(items[0], coursesDirectoryURL: fixture.coursesDirectoryURL),
            "The caller must clear (archive) the current course first"
        )
    }
}

/// A throwaway courses folder holding one small course with one page and
/// some rebuildable output that must stay out of backups.
@MainActor
struct BackupFixture {

    // MARK: - Stored properties

    let coursesDirectoryURL: URL
    let courseURL: URL
    let pageURL: URL
    let course: Course

    // MARK: - Initializer

    init() throws {
        let fileManager: FileManager = FileManager.default
        coursesDirectoryURL = fileManager.temporaryDirectory
            .appendingPathComponent("backup-tests-\(UUID().uuidString)")
        courseURL = coursesDirectoryURL.appendingPathComponent("ICS3U")
        try fileManager.createDirectory(
            at: courseURL.appendingPathComponent("section1"),
            withIntermediateDirectories: true
        )
        pageURL = courseURL.appendingPathComponent("section1/index.md")
        try Data("original".utf8).write(to: pageURL)

        let configValues: [String: Any] = [
            "course_code": "ICS3U",
            "course_name": "Backup Test Course",
            "section_numbers": [1],
        ]
        let configData: Data = try JSONSerialization.data(withJSONObject: configValues)
        try configData.write(to: courseURL.appendingPathComponent("course_config.json"))

        // Rebuildable output, which backups must leave out.
        let mergedURL: URL = courseURL.appendingPathComponent(".merged_output/section1")
        try fileManager.createDirectory(at: mergedURL, withIntermediateDirectories: true)
        try Data("built".utf8).write(to: mergedURL.appendingPathComponent("site.html"))

        let configuration: CourseConfiguration = CourseConfiguration(
            values: configValues, lastSavedData: configData
        )
        course = Course(code: "ICS3U", directoryURL: courseURL, configuration: configuration)
    }

    // MARK: - Functions

    func tearDown() {
        try? FileManager.default.removeItem(at: coursesDirectoryURL)
    }
}
