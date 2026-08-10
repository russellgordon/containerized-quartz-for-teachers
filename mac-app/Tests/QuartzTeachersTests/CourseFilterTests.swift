import XCTest
@testable import QuartzTeachers

/// The sidebar's filter field.
final class CourseFilterTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func makeWorkspaceWithCourses() throws -> WorkspaceModel {
        let workspace: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        var courses: [Course] = []
        let entries: [(code: String, name: String)] = [
            (code: "ICS3U", name: "Intro to Comp Sci"),
            (code: "MPM2D", name: "Principles of Mathematics"),
            (code: "CODING", name: "Coding Club"),
        ]
        for entry in entries {
            let values: [String: Any] = ["course_code": entry.code, "course_name": entry.name]
            let data: Data = try JSONSerialization.data(withJSONObject: values)
            let configuration: CourseConfiguration = CourseConfiguration(values: values, lastSavedData: data)
            courses.append(
                Course(
                    code: entry.code,
                    directoryURL: URL(fileURLWithPath: "/tmp/courses/\(entry.code)"),
                    configuration: configuration
                )
            )
        }
        workspace.courses = courses
        return workspace
    }

    @MainActor
    func testEmptyFilterShowsEverything() throws {
        let workspace: WorkspaceModel = try makeWorkspaceWithCourses()
        workspace.filterText = "   "
        XCTAssertEqual(workspace.filteredCourses.count, 3)
    }

    @MainActor
    func testFilterMatchesCodeCaseInsensitively() throws {
        let workspace: WorkspaceModel = try makeWorkspaceWithCourses()
        workspace.filterText = "ics3"
        XCTAssertEqual(workspace.filteredCourses.map(\.code), ["ICS3U"])
    }

    @MainActor
    func testFilterMatchesNamesEvenMidWord() throws {
        // "ics" is inside "Mathematics" — matching names anywhere is
        // deliberate, so a teacher can find a course by subject.
        let workspace: WorkspaceModel = try makeWorkspaceWithCourses()
        workspace.filterText = "ics"
        XCTAssertEqual(workspace.filteredCourses.map(\.code), ["ICS3U", "MPM2D"])
    }

    @MainActor
    func testFilterAlsoMatchesTheCourseName() throws {
        let workspace: WorkspaceModel = try makeWorkspaceWithCourses()
        workspace.filterText = "club"
        XCTAssertEqual(workspace.filteredCourses.map(\.code), ["CODING"])
    }

    @MainActor
    func testFilterWithNoMatchesShowsNothing() throws {
        let workspace: WorkspaceModel = try makeWorkspaceWithCourses()
        workspace.filterText = "zzz"
        XCTAssertTrue(workspace.filteredCourses.isEmpty)
    }
}
