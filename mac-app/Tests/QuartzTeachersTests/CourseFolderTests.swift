import XCTest
@testable import QuartzTeachers

final class CourseFolderTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testSectionDirectoryURLPointsInsideTheCourse() throws {
        let dictionary: [String: Any] = ["course_code": "ICS3U", "section_numbers": [1, 3]]
        let configuration: CourseConfiguration = CourseConfiguration(
            values: dictionary,
            lastSavedData: try JSONSerialization.data(withJSONObject: dictionary)
        )
        let course: Course = Course(
            code: "ICS3U",
            directoryURL: URL(fileURLWithPath: "/tmp/workspace/courses/ICS3U"),
            configuration: configuration
        )
        XCTAssertEqual(
            course.sectionDirectoryURL(forSection: 3).path,
            "/tmp/workspace/courses/ICS3U/section3"
        )
    }
}
