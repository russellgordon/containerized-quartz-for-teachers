import XCTest
@testable import QuartzTeachers

/// Several previews at once, each on its own port.
final class PreviewLeaseTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testEachPreviewGetsItsOwnPort() throws {
        PreviewLeases.reset()
        let first = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 1)
        let second = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 2)
        XCTAssertNotEqual(first.port, second.port, "Two previews on one port would take each other down")
    }

    @MainActor
    func testTheSameSectionCannotBePreviewedTwice() throws {
        PreviewLeases.reset()
        _ = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 1)
        XCTAssertThrowsError(try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 1)) { error in
            let message: String = (error as? LocalizedError)?.errorDescription ?? ""
            XCTAssertTrue(message.contains("already being previewed"), "Got: \(message)")
        }
    }

    @MainActor
    func testTheSameSectionInAnotherFolderIsFine() throws {
        // Comparing this year's course against last year's: same code and
        // section, different working folders.
        PreviewLeases.reset()
        _ = try PreviewLeases.lease(folderPath: "/this-year", courseCode: "SNC1W", sectionNumber: 1)
        XCTAssertNoThrow(try PreviewLeases.lease(folderPath: "/last-year", courseCode: "SNC1W", sectionNumber: 1))
    }

    @MainActor
    func testTheFifthPreviewIsRefusedPolitely() throws {
        PreviewLeases.reset()
        for section in 1...4 {
            _ = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: section)
        }
        XCTAssertThrowsError(try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 5)) { error in
            let message: String = (error as? LocalizedError)?.errorDescription ?? ""
            XCTAssertTrue(message.contains("Stop one"), "Got: \(message)")
        }
    }

    @MainActor
    func testAReleasedPortIsLeasedAgain() throws {
        PreviewLeases.reset()
        let first = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 1)
        PreviewLeases.release(first)
        let again = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 1)
        XCTAssertEqual(again.port, first.port, "A stopped preview's port goes back into the pool")
    }

    @MainActor
    func testReleasingIsExactAboutWhichLease() throws {
        PreviewLeases.reset()
        let first = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 1)
        let second = try PreviewLeases.lease(folderPath: "/w", courseCode: "SNC1W", sectionNumber: 2)
        PreviewLeases.release(first)
        XCTAssertEqual(PreviewLeases.active, [second], "Only the stopped preview's lease is returned")
    }
}
