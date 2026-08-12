import XCTest
@testable import QuartzTeachers

/// The cross-window record of which courses are previewing or publishing,
/// used to decline actions (like Add Section…) that would rewrite a
/// course's files mid-task.
final class CourseActivityTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testAnIdleCourseIsNotBusy() {
        CourseActivity.reset()
        PreviewLeases.reset()
        XCTAssertFalse(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"))
    }

    @MainActor
    func testAPreviewMakesItsCourseBusyUntilTheLeaseIsReleased() throws {
        CourseActivity.reset()
        PreviewLeases.reset()
        let lease: PreviewLeases.Lease = try PreviewLeases.lease(
            folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 1
        )
        XCTAssertTrue(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"))
        XCTAssertEqual(CourseActivity.busyDescription(folderPath: "/folder", courseCode: "ICS3U"),
                       "Available once preview completed")
        XCTAssertFalse(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "MPM2D"),
                       "Only the previewing course is busy, not its neighbours")
        XCTAssertFalse(CourseActivity.courseIsBusy(folderPath: "/other-folder", courseCode: "ICS3U"),
                       "The same code in a different working folder is a different course")

        PreviewLeases.release(lease)
        XCTAssertFalse(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"))
    }

    @MainActor
    func testAPublishMakesItsCourseBusyUntilItEnds() {
        CourseActivity.reset()
        PreviewLeases.reset()
        CourseActivity.beginPublish(folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 2)
        XCTAssertTrue(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"))
        XCTAssertEqual(CourseActivity.busyDescription(folderPath: "/folder", courseCode: "ICS3U"),
                       "Available once publish completed")

        CourseActivity.endPublish(folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 2)
        XCTAssertFalse(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"))
    }

    @MainActor
    func testTwoPublishesOfOneCourseEndIndependently() {
        CourseActivity.reset()
        PreviewLeases.reset()
        // Two windows publishing two sections of the same course: the
        // course stays busy until BOTH finish.
        CourseActivity.beginPublish(folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 1)
        CourseActivity.beginPublish(folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 3)

        CourseActivity.endPublish(folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 1)
        XCTAssertTrue(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"),
                      "The other section is still publishing")

        CourseActivity.endPublish(folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 3)
        XCTAssertFalse(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"))
    }

    @MainActor
    func testEndingAPublishThatNeverBeganChangesNothing() {
        CourseActivity.reset()
        PreviewLeases.reset()
        CourseActivity.beginPublish(folderPath: "/folder", courseCode: "ICS3U", sectionNumber: 1)
        CourseActivity.endPublish(folderPath: "/folder", courseCode: "MPM2D", sectionNumber: 1)
        XCTAssertTrue(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "ICS3U"))
        XCTAssertFalse(CourseActivity.courseIsBusy(folderPath: "/folder", courseCode: "MPM2D"))
    }
}
