import XCTest
@testable import QuartzTeachers

/// Installing the example course from the app.
final class ExampleCourseTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testTheInstalledCodeIsReadFromTheOutput() {
        let output: String = """
        ✅ Example Course installed to: /teaching/courses/EXC2O
        EXAMPLE_COURSE_CODE=EXC2O
        """
        XCTAssertEqual(NewCourseCreator.exampleCourseCode(in: output), "EXC2O")
    }

    @MainActor
    func testAnAlternateCodeIsReadWhenTheUsualOneWasTaken() {
        let output: String = """
        ℹ️ A course named EXC2O already exists. Using QRS2O instead.
        ✅ Example Course installed to: /teaching/courses/QRS2O
        EXAMPLE_COURSE_CODE=QRS2O
        """
        XCTAssertEqual(NewCourseCreator.exampleCourseCode(in: output), "QRS2O")
    }

    @MainActor
    func testNoCodeWhenTheInstallDidNotReportOne() {
        XCTAssertNil(NewCourseCreator.exampleCourseCode(in: "❌ Could not find the example course content."))
    }

    @MainActor
    func testTheExampleInstallHasItsOwnMilestones() {
        XCTAssertFalse(TaskMilestones.exampleCourse.isEmpty)
        for milestone in TaskMilestones.exampleCourse {
            XCTAssertTrue(milestone.label.hasSuffix("…"), "Milestone labels end with an ellipsis: \(milestone.label)")
            XCTAssertFalse(milestone.marker.isEmpty)
        }
    }
}
