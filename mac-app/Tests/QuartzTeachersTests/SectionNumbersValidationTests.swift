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

    @MainActor
    func testTheCodeFieldExplainsItsOwnProblems() {
        let existing: [String] = ["ICS4U", "MPM2D"]

        XCTAssertNil(NewCourseWizardView.courseCodeProblem("", existingCodes: existing),
                     "An empty code is not-ready-yet, not an error worth showing")
        XCTAssertNil(NewCourseWizardView.courseCodeProblem("SNC1W", existingCodes: existing))

        XCTAssertEqual(NewCourseWizardView.courseCodeProblem("ICS 4U", existingCodes: existing),
                       "A course code cannot contain spaces.")
        XCTAssertEqual(NewCourseWizardView.courseCodeProblem("ics4u", existingCodes: existing),
                       "A course named ICS4U already exists — choose a different code.",
                       "The clash is found case-insensitively")
        XCTAssertEqual(NewCourseWizardView.courseCodeProblem("  MPM2D  ", existingCodes: existing),
                       "A course named MPM2D already exists — choose a different code.",
                       "Whitespace never hides a clash")
    }
}
