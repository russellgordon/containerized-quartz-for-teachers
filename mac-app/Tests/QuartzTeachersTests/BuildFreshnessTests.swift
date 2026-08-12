import XCTest
@testable import QuartzTeachers

/// Publishing must never send a stale site: the freshness check decides
/// whether a build has to run first.
final class BuildFreshnessTests: XCTestCase {

    // MARK: - Functions

    /// A course folder with one section and an optional built site.
    @MainActor
    func makeCourse(withBuiltSite hasBuiltSite: Bool) throws -> Course {
        let courseURL: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cq4t-fresh-\(UUID().uuidString)")
            .appendingPathComponent("ICS3U")
        let sectionURL: URL = courseURL.appendingPathComponent("section1")
        try FileManager.default.createDirectory(at: sectionURL, withIntermediateDirectories: true)
        try Data("# lesson\n".utf8).write(to: sectionURL.appendingPathComponent("index.md"))

        let values: [String: Any] = ["course_code": "ICS3U", "section_numbers": [1]]
        let data: Data = try JSONSerialization.data(withJSONObject: values)
        try data.write(to: courseURL.appendingPathComponent("course_config.json"))

        if hasBuiltSite {
            let publicURL: URL = courseURL
                .appendingPathComponent(".merged_output")
                .appendingPathComponent("section1")
                .appendingPathComponent("public")
            try FileManager.default.createDirectory(at: publicURL, withIntermediateDirectories: true)
            try Data("<html></html>".utf8).write(to: publicURL.appendingPathComponent("index.html"))
        }

        let configuration: CourseConfiguration = CourseConfiguration(values: values, lastSavedData: data)
        return Course(code: "ICS3U", directoryURL: courseURL, configuration: configuration)
    }

    /// Stamps a file's modification date, for ordering tests.
    func setModificationDate(_ date: Date, of url: URL) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }

    /// Back-dates EVERY entry in the course (files and the folders that
    /// hold them — creating a file bumps its parent's date too), so a
    /// test can then make exactly one thing newer.
    func backdateEverything(in courseURL: URL, to date: Date) throws {
        var urls: [URL] = [courseURL]
        if let enumerator = FileManager.default.enumerator(at: courseURL, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator {
                urls.append(url)
            }
        }
        // Deepest first, so stamping a child cannot re-dirty its parent.
        urls.sort { first, second in
            return first.pathComponents.count > second.pathComponents.count
        }
        for url in urls {
            try setModificationDate(date, of: url)
        }
    }

    @MainActor
    func testNeverBuiltMeansRebuild() throws {
        let course: Course = try makeCourse(withBuiltSite: false)
        XCTAssertTrue(BuildFreshness.needsRebuild(course: course, sectionNumber: 1))
        XCTAssertNil(BuildFreshness.builtSiteDate(course: course, sectionNumber: 1))
    }

    @MainActor
    func testAPreviewBuildIsNeverDeployFresh() throws {
        // Serve mode bakes a live-reload client into every page;
        // deploying it makes the public site knock on ws://localhost
        // and browsers prompt every visitor. Newer-than-content is not
        // enough — a preview's build always rebuilds before publishing.
        let course: Course = try makeCourse(withBuiltSite: true)
        let builtIndexURL: URL = course.directoryURL
            .appendingPathComponent(".merged_output/section1/public/index.html")

        try backdateEverything(in: course.directoryURL, to: Date(timeIntervalSinceNow: -600))
        try Data("<script>const socket = new WebSocket('ws://localhost:9081')</script>".utf8)
            .write(to: builtIndexURL)
        try setModificationDate(Date(timeIntervalSinceNow: 300), of: builtIndexURL)

        XCTAssertTrue(BuildFreshness.builtForPreview(builtIndexURL))
        XCTAssertTrue(BuildFreshness.needsRebuild(course: course, sectionNumber: 1),
                      "A preview's build is never deploy-fresh, however new it is")

        try Data("a clean production page".utf8).write(to: builtIndexURL)
        try setModificationDate(Date(timeIntervalSinceNow: 300), of: builtIndexURL)
        XCTAssertFalse(BuildFreshness.builtForPreview(builtIndexURL))
        XCTAssertFalse(BuildFreshness.needsRebuild(course: course, sectionNumber: 1),
                       "A clean production build newer than the content is current")
    }

    @MainActor
    func testBuiltAfterContentIsUpToDate() throws {
        let course: Course = try makeCourse(withBuiltSite: true)
        let lessonURL: URL = course.directoryURL.appendingPathComponent("section1/index.md")
        let builtIndexURL: URL = course.directoryURL
            .appendingPathComponent(".merged_output/section1/public/index.html")

        try backdateEverything(in: course.directoryURL, to: Date(timeIntervalSinceNow: -600))
        try setModificationDate(Date(timeIntervalSinceNow: -60), of: builtIndexURL)
        XCTAssertNotNil(lessonURL)

        XCTAssertFalse(BuildFreshness.needsRebuild(course: course, sectionNumber: 1), "A site built after the last edit is current")
    }

    @MainActor
    func testEditingContentAfterBuildingMeansRebuild() throws {
        let course: Course = try makeCourse(withBuiltSite: true)
        let lessonURL: URL = course.directoryURL.appendingPathComponent("section1/index.md")
        let builtIndexURL: URL = course.directoryURL
            .appendingPathComponent(".merged_output/section1/public/index.html")

        try backdateEverything(in: course.directoryURL, to: Date(timeIntervalSinceNow: -600))
        try setModificationDate(Date(timeIntervalSinceNow: -300), of: builtIndexURL)
        try setModificationDate(Date(timeIntervalSinceNow: -10), of: lessonURL)

        XCTAssertTrue(BuildFreshness.needsRebuild(course: course, sectionNumber: 1), "An edit after the build must trigger a rebuild")
    }

    @MainActor
    func testChangingSettingsMeansRebuild() throws {
        let course: Course = try makeCourse(withBuiltSite: true)
        let configURL: URL = course.configFileURL
        let builtIndexURL: URL = course.directoryURL
            .appendingPathComponent(".merged_output/section1/public/index.html")

        try backdateEverything(in: course.directoryURL, to: Date(timeIntervalSinceNow: -600))
        try setModificationDate(Date(timeIntervalSinceNow: -300), of: builtIndexURL)
        try setModificationDate(Date(timeIntervalSinceNow: -10), of: configURL)

        XCTAssertTrue(BuildFreshness.needsRebuild(course: course, sectionNumber: 1), "Saved settings must trigger a rebuild")
    }

    @MainActor
    func testGeneratedAndHiddenFilesDoNotTriggerRebuilds() throws {
        let course: Course = try makeCourse(withBuiltSite: true)
        let builtIndexURL: URL = course.directoryURL
            .appendingPathComponent(".merged_output/section1/public/index.html")
        // Deploy markers and Obsidian settings churn constantly; they are
        // not content and must not force a rebuild. Create them BEFORE
        // back-dating so only their own (hidden) entries are recent.
        let markerURL: URL = course.directoryURL.appendingPathComponent(".netlify_sites")
        try FileManager.default.createDirectory(at: markerURL, withIntermediateDirectories: true)
        try backdateEverything(in: course.directoryURL, to: Date(timeIntervalSinceNow: -600))
        try setModificationDate(Date(timeIntervalSinceNow: -300), of: builtIndexURL)
        try Data("{}".utf8).write(to: markerURL.appendingPathComponent("section1.json"))

        XCTAssertFalse(BuildFreshness.needsRebuild(course: course, sectionNumber: 1), "Hidden, generated files should be ignored")
    }
}
