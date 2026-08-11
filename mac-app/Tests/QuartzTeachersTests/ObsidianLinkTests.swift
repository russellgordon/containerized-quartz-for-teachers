import XCTest
@testable import QuartzTeachers

/// The obsidian:// link that opens a course or section folder as a vault.
final class ObsidianLinkTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testTheLinkCarriesTheFullPathEncoded() throws {
        let folder: URL = URL(fileURLWithPath: "/Users/teacher/Desktop/Class Websites/courses/ICS3U/section2")
        let link: URL = try XCTUnwrap(FolderActions.obsidianURL(forFolder: folder))

        XCTAssertEqual(link.scheme, "obsidian")
        XCTAssertEqual(link.host, "open")
        XCTAssertEqual(link.absoluteString,
                       "obsidian://open?path=/Users/teacher/Desktop/Class%20Websites/courses/ICS3U/section2",
                       "Spaces in the path must be percent-encoded or Obsidian gets a broken path")

        // And the path survives the round trip exactly.
        let components: URLComponents = try XCTUnwrap(URLComponents(url: link, resolvingAgainstBaseURL: false))
        var pathValue: String?
        for item in components.queryItems ?? [] {
            if item.name == "path" {
                pathValue = item.value
            }
        }
        XCTAssertEqual(pathValue, folder.path)
    }
}
