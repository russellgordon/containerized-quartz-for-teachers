import XCTest
@testable import QuartzTeachers

/// Saying what is wrong with the timetable sections, as typed.
final class SectionNumbersValidationTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testGoodInputPassesQuietly() {
        XCTAssertNil(NewCourseWizardView.sectionNumbersProblem("1"))
        XCTAssertNil(NewCourseWizardView.sectionNumbersProblem("1,3"))
        XCTAssertNil(NewCourseWizardView.sectionNumbersProblem(" 1 , 3 , 5 "), "Spaces around commas are fine")
    }

    @MainActor
    func testSpacesInsteadOfCommasGetTheCommaHint() {
        let problem: String? = NewCourseWizardView.sectionNumbersProblem("1 3 5")
        XCTAssertEqual(problem, "Use commas between section numbers — e.g. 1,3,5.")
    }

    @MainActor
    func testAStrayLetterIsNamed() {
        let problem: String? = NewCourseWizardView.sectionNumbersProblem("1a,3 4")
        XCTAssertNotNil(problem)
        XCTAssertTrue(problem?.contains("“1a”") == true, "The bad piece is quoted so it can be found: \(problem ?? "")")
    }

    @MainActor
    func testTheSilentDropCaseIsCaught() {
        // "1,3 5" used to parse as just [1], quietly losing the rest.
        XCTAssertNotNil(NewCourseWizardView.sectionNumbersProblem("1,3 5"))
    }

    @MainActor
    func testEmptyAndPunctuationShapes() {
        XCTAssertNotNil(NewCourseWizardView.sectionNumbersProblem(""))
        XCTAssertEqual(NewCourseWizardView.sectionNumbersProblem("1,,3"), "There’s an empty spot between commas.")
        XCTAssertEqual(NewCourseWizardView.sectionNumbersProblem("1,"), "There’s an empty spot between commas.")
    }

    @MainActor
    func testZeroAndDuplicates() {
        XCTAssertEqual(NewCourseWizardView.sectionNumbersProblem("0,1"), "“0” isn’t a section number — sections are 1 or higher.")
        XCTAssertEqual(NewCourseWizardView.sectionNumbersProblem("1,3,1"), "Section 1 is listed more than once.")
    }

    @MainActor
    func testATeacherNeedNotTeachSectionOne() {
        // A school may run five sections while this teacher has only three
        // of them — the list does not have to include 1, or be contiguous.
        XCTAssertNil(NewCourseWizardView.sectionNumbersProblem("2,4,5"))
        XCTAssertNil(NewCourseWizardView.sectionNumbersProblem("3"))
        XCTAssertNil(NewCourseWizardView.sectionNumbersProblem("7,2"))
    }

    // MARK: - The code field

    // The course-code cases used to live here, as a copy of the wizard's own
    // rule. They now live in `contracts/course-management.json` under
    // `courseCode`, run by `CourseManagementContractTests`, because RENAMING
    // a course asks the identical question — and a rule written down twice
    // is a rule that will disagree with itself. The wizard consults
    // `CourseCodeRule`; so does the sidebar's rename field.

}
