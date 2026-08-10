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
        XCTAssertEqual(NewCourseWizardView.sectionNumbersProblem("0,1"), "Section numbers start at 1.")
        XCTAssertEqual(NewCourseWizardView.sectionNumbersProblem("1,3,1"), "Section 1 is listed more than once.")
    }
}
