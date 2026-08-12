import XCTest
@testable import QuartzTeachers

/// Reading what a teacher has archived.
final class ArchivedItemTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testAnArchivedCourseIsRecognised() {
        let url: URL = URL(fileURLWithPath: "/w/courses/_backups/IZN2O/IZN2O_2026-08-10_143005.zip")
        let item = ArchivedItem.from(fileURL: url, courseCode: "IZN2O")
        XCTAssertNotNil(item)
        XCTAssertNil(item?.sectionNumber, "The whole course was archived")
        XCTAssertEqual(item?.title, "IZN2O")
    }

    @MainActor
    func testAnArchivedSectionIsRecognised() {
        let url: URL = URL(fileURLWithPath: "/w/courses/_backups/IZN2O/IZN2O-section2_2026-08-10_143005.zip")
        let item = ArchivedItem.from(fileURL: url, courseCode: "IZN2O")
        XCTAssertEqual(item?.sectionNumber, 2)
        XCTAssertEqual(item?.title, "IZN2O — Section 2")
    }

    @MainActor
    func testTheWizardsAutomaticBackupIsNotListedAsArchived() {
        // The setup wizard backs a course up before changing it, naming the
        // file by timestamp alone. That is not something a teacher put away.
        let url: URL = URL(fileURLWithPath: "/w/courses/_backups/IZN2O/2026-08-10_143005.zip")
        XCTAssertNil(ArchivedItem.from(fileURL: url, courseCode: "IZN2O"))
    }

    @MainActor
    func testUnrelatedFilesAreIgnored() {
        XCTAssertNil(ArchivedItem.from(fileURL: URL(fileURLWithPath: "/w/courses/_backups/IZN2O/notes.txt"), courseCode: "IZN2O"))
        XCTAssertNil(ArchivedItem.from(fileURL: URL(fileURLWithPath: "/w/courses/_backups/IZN2O/OTHER_2026-08-10_143005.zip"), courseCode: "IZN2O"))
    }

    @MainActor
    func testTheDateIsReadFromTheName() {
        let url: URL = URL(fileURLWithPath: "/w/courses/_backups/IZN2O/IZN2O_2026-08-10_143005.zip")
        let item = ArchivedItem.from(fileURL: url, courseCode: "IZN2O")
        let components = Calendar.current.dateComponents([.year, .month, .day], from: item!.archivedAt)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 8)
        XCTAssertEqual(components.day, 10)
    }

    @MainActor
    func testTheSidebarListsArchivesNewestFirst() throws {
        let root: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("arch-\(UUID().uuidString)")
        let courseArchives: URL = root.appendingPathComponent("_backups/IZN2O")
        try FileManager.default.createDirectory(at: courseArchives, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        for name in ["IZN2O-section1_2026-08-09_090000.zip",
                     "IZN2O-section2_2026-08-10_143005.zip",
                     "2026-08-01_120000.zip"] {
            try Data().write(to: courseArchives.appendingPathComponent(name))
        }

        let found = WorkspaceModel.findArchivedItems(in: root)
        XCTAssertEqual(found.count, 2, "The wizard's automatic backup must not be listed")
        XCTAssertEqual(found.first?.sectionNumber, 2, "Newest first")
        XCTAssertEqual(found.last?.sectionNumber, 1)
    }

    @MainActor
    func testTheDeleteWarningKnowsWhenAnArchiveIsTheOnlyCopy() {
        // One live course, ICS3U, with sections 1 and 2.
        let configuration: CourseConfiguration = CourseConfiguration(
            values: ["course_code": "ICS3U", "section_numbers": [1, 2]],
            lastSavedData: Data()
        )
        let liveCourses: [Course] = [
            Course(code: "ICS3U", directoryURL: URL(fileURLWithPath: "/w/courses/ICS3U"), configuration: configuration)
        ]
        let stamp: Date = Date()
        let zipURL: URL = URL(fileURLWithPath: "/w/courses/_backups/ICS3U/x.zip")

        let liveCourseArchive: ArchivedItem = ArchivedItem(
            courseCode: "ICS3U", sectionNumber: nil, archivedAt: stamp, fileURL: zipURL
        )
        XCTAssertFalse(WorkspaceModel.archiveIsOnlyRemainingCopy(liveCourseArchive, among: liveCourses),
                       "The course is still live, so the archive is a spare copy")

        let liveSectionArchive: ArchivedItem = ArchivedItem(
            courseCode: "ICS3U", sectionNumber: 2, archivedAt: stamp, fileURL: zipURL
        )
        XCTAssertFalse(WorkspaceModel.archiveIsOnlyRemainingCopy(liveSectionArchive, among: liveCourses))

        let goneSectionArchive: ArchivedItem = ArchivedItem(
            courseCode: "ICS3U", sectionNumber: 3, archivedAt: stamp, fileURL: zipURL
        )
        XCTAssertTrue(WorkspaceModel.archiveIsOnlyRemainingCopy(goneSectionArchive, among: liveCourses),
                      "The live course no longer has section 3, so its archive is the only copy")

        let goneCourseArchive: ArchivedItem = ArchivedItem(
            courseCode: "MPM2D", sectionNumber: nil, archivedAt: stamp, fileURL: zipURL
        )
        XCTAssertTrue(WorkspaceModel.archiveIsOnlyRemainingCopy(goneCourseArchive, among: liveCourses))
    }
}
