import XCTest
@testable import QuartzTeachers

/// A section's custom domain: stored per section, cleaned on entry, and
/// worn by the live-site link in place of the Netlify address.
final class CustomDomainTests: XCTestCase {

    // MARK: - Functions

    @MainActor
    func testTheDomainIsStoredPerSectionAndSurvivesARoundTrip() throws {
        let folderURL: URL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("domain-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folderURL) }

        let configJSON: [String: Any] = ["course_code": "ICS3U", "section_numbers": [1, 2]]
        let configURL: URL = folderURL.appendingPathComponent("course_config.json")
        try JSONSerialization.data(withJSONObject: configJSON).write(to: configURL)

        let configuration: CourseConfiguration = try CourseConfiguration(contentsOf: configURL)
        XCTAssertEqual(configuration.customDomain(forSection: 1), "", "No domain until one is set")

        configuration.setCustomDomain("ics3u.school.ca", forSection: 1)
        try configuration.write(to: configURL)

        let reloaded: CourseConfiguration = try CourseConfiguration(contentsOf: configURL)
        XCTAssertEqual(reloaded.customDomain(forSection: 1), "ics3u.school.ca")
        XCTAssertEqual(reloaded.customDomain(forSection: 2), "", "Each section has its own domain")
    }

    @MainActor
    func testAPastedAddressIsReducedToJustTheDomain() {
        XCTAssertEqual(CourseConfiguration.normalizedCustomDomain("https://ics3u.school.ca/"), "ics3u.school.ca")
        XCTAssertEqual(CourseConfiguration.normalizedCustomDomain("http://ics3u.school.ca/some/page"), "ics3u.school.ca")
        XCTAssertEqual(CourseConfiguration.normalizedCustomDomain("  ics3u.school.ca  "), "ics3u.school.ca")
        XCTAssertEqual(CourseConfiguration.normalizedCustomDomain("ics3u.school.ca"), "ics3u.school.ca")
        XCTAssertEqual(CourseConfiguration.normalizedCustomDomain(""), "")
    }

    @MainActor
    func testTheLiveSiteLinkWearsTheCustomDomain() throws {
        let netlifyURL: URL = try XCTUnwrap(URL(string: "https://seedbed-example-course.netlify.app"))

        let dressed: URL = ScriptRunner.applyingCustomDomain("ics3u.school.ca", to: netlifyURL)
        XCTAssertEqual(dressed.absoluteString, "https://ics3u.school.ca")

        // A path on the site survives the swap.
        let deepURL: URL = try XCTUnwrap(URL(string: "https://seedbed-example-course.netlify.app/Curriculum"))
        XCTAssertEqual(ScriptRunner.applyingCustomDomain("ics3u.school.ca", to: deepURL).absoluteString,
                       "https://ics3u.school.ca/Curriculum")

        // No domain set: the address passes through untouched.
        XCTAssertEqual(ScriptRunner.applyingCustomDomain(nil, to: netlifyURL), netlifyURL)
        XCTAssertEqual(ScriptRunner.applyingCustomDomain("", to: netlifyURL), netlifyURL)

        // A plain-http address is promoted to https on the teacher's domain.
        let httpURL: URL = try XCTUnwrap(URL(string: "http://seedbed-example-course.netlify.app"))
        XCTAssertEqual(ScriptRunner.applyingCustomDomain("ics3u.school.ca", to: httpURL).absoluteString,
                       "https://ics3u.school.ca")
    }

    /// The runner end to end: a deploy transcript announcing a Netlify
    /// address shows the teacher's domain when one is set.
    @MainActor
    func testARunnersPublishedLinkUsesTheDomain() {
        let runner: ScriptRunner = ScriptRunner()
        runner.transcript.append(rawText: "Site URL: https://seedbed-example-course.netlify.app\r\n")

        XCTAssertEqual(runner.publishedSiteURL?.absoluteString, "https://seedbed-example-course.netlify.app",
                       "Without a custom domain the Netlify address shows")

        runner.customDomainForLinks = "ics3u.school.ca"
        XCTAssertEqual(runner.publishedSiteURL?.absoluteString, "https://ics3u.school.ca")
    }
}
