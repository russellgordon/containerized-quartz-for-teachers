import XCTest
@testable import QuartzTeachers

/// The bundled Ontario course lookup must behave like the wizard's:
/// same file, same names, case-insensitive on the code.
final class CourseNameCatalogTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testCatalogLoadsFromBundle() {
        XCTAssertGreaterThan(CourseNameCatalog.entries.count, 1000, "The Ontario course lookup should be bundled and loaded")
    }

    @MainActor
    func testKnownCodeReturnsBothNames() {
        let names: CourseNames? = CourseNameCatalog.names(forCode: "ICS3U")
        XCTAssertEqual(names?.formal, "Introduction to Computer Science, Grade 11, U")
        XCTAssertEqual(names?.short, "Intro to Comp Sci")
    }

    @MainActor
    func testLookupIsCaseInsensitiveAndTrimsWhitespace() {
        let names: CourseNames? = CourseNameCatalog.names(forCode: "  ics3u ")
        XCTAssertEqual(names?.short, "Intro to Comp Sci")
    }

    @MainActor
    /// The suggestion offered as a course name is the CLEAN name — the
    /// catalog citation's grade-and-pathway suffix belongs to the grade
    /// toggle, not the name.
    func testDisplayNameDropsTheCitationSuffix() {
        XCTAssertEqual(CourseNames(formal: "Computer Science, Grade 12, U", short: "Comp Sci").display,
                       "Computer Science")
        XCTAssertEqual(CourseNames(formal: "Science, Grade 9, Destreamed", short: "Sci").display,
                       "Science")
        XCTAssertEqual(CourseNames(formal: "Coding Club", short: "Coding").display,
                       "Coding Club", "A name without the suffix passes through whole")
    }

    @MainActor
    func testUnknownAndClubCodesReturnNil() {
        XCTAssertNil(CourseNameCatalog.names(forCode: "CODING"))
        XCTAssertNil(CourseNameCatalog.names(forCode: ""))
    }
}
