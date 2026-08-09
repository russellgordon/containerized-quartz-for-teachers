import XCTest
@testable import QuartzTeachers

/// Round-trip tests for the course configuration: the app must read and
/// write `course_config.json` without losing anything the command-line
/// scripts put there.
final class CourseConfigurationTests: XCTestCase {

    // MARK: - Functions

    /// A fixture matching what the setup wizard writes for a small course.
    @MainActor
    func makeFixtureDictionary() -> [String: Any] {
        return [
            "course_code": "EXC2O",
            "course_name": "Example Course",
            "locale": "en-US",
            "emojis": ["sections": ["section1": "📚", "section2": "📝"]],
            "num_sections": 2,
            "section_numbers": [1, 2],
            "shared_folders": ["Concepts", "Exercises"],
            "shared_files": ["Learning Goals.md"],
            "per_section_folders": ["All Classes"],
            "per_section_files": ["Key Links.md"],
            "hidden": ["Media"],
            "expandable": ["Concepts", "Exercises"],
            "expandOnFolderClick": false,
            "footer_html": "",
            "show_reading_time": false,
            "fonts": [
                "default": ["header": "Montserrat", "body": "Lora", "code": "JetBrains Mono"],
                "sections": [:],
            ],
            "show_section_marker": ["sections": ["section1": true]],
            "color_schemes": ["section1": "quartz-standard"],
            "some_future_key_the_app_does_not_know": ["keep": "me"],
        ]
    }

    @MainActor
    func makeFixtureConfiguration() throws -> (configuration: CourseConfiguration, fileURL: URL) {
        let dictionary: [String: Any] = makeFixtureDictionary()
        let data: Data = try JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys])
        let fileURL: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("course_config_test_\(UUID().uuidString).json")
        try data.write(to: fileURL)
        let configuration: CourseConfiguration = try CourseConfiguration(contentsOf: fileURL)
        return (configuration: configuration, fileURL: fileURL)
    }

    @MainActor
    func testReadingKnownValues() throws {
        let fixture = try makeFixtureConfiguration()
        let configuration: CourseConfiguration = fixture.configuration

        XCTAssertEqual(configuration.courseCode, "EXC2O")
        XCTAssertEqual(configuration.courseName, "Example Course")
        XCTAssertEqual(configuration.sectionNumbers, [1, 2])
        XCTAssertEqual(configuration.emoji(forSection: 2), "📝")
        XCTAssertEqual(configuration.colourSchemeID(forSection: 1), "quartz-standard")
        XCTAssertTrue(configuration.showsSectionMarker(forSection: 1))
        XCTAssertFalse(configuration.showReadingTime)
        XCTAssertFalse(configuration.isClub)
        XCTAssertEqual(configuration.fontChoice(forSection: 1).header, "Montserrat")
    }

    @MainActor
    func testRoundTripPreservesUnknownKeys() throws {
        let fixture = try makeFixtureConfiguration()
        let configuration: CourseConfiguration = fixture.configuration

        // Change one value the way the settings form would.
        configuration.showReadingTime = true

        let outputURL: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("course_config_out_\(UUID().uuidString).json")
        try configuration.write(to: outputURL)

        let writtenData: Data = try Data(contentsOf: outputURL)
        let decoded: Any = try JSONSerialization.jsonObject(with: writtenData)
        guard let writtenDictionary = decoded as? [String: Any] else {
            XCTFail("Written file was not a JSON object")
            return
        }

        // The edited value changed…
        XCTAssertEqual(writtenDictionary["show_reading_time"] as? Bool, true)

        // …and every other key survived, including one the app knows
        // nothing about.
        let unknown: [String: Any]? = writtenDictionary["some_future_key_the_app_does_not_know"] as? [String: Any]
        XCTAssertEqual(unknown?["keep"] as? String, "me")

        var originalDictionary: [String: Any] = makeFixtureDictionary()
        originalDictionary["show_reading_time"] = true
        XCTAssertTrue(
            (writtenDictionary as NSDictionary).isEqual(to: originalDictionary),
            "Round-tripped configuration should be semantically identical apart from the one edit"
        )
    }

    @MainActor
    func testDiscardChangesRestoresSavedValues() throws {
        let fixture = try makeFixtureConfiguration()
        let configuration: CourseConfiguration = fixture.configuration

        configuration.courseName = "Renamed"
        XCTAssertTrue(configuration.hasUnsavedChanges)

        try configuration.discardChanges()
        XCTAssertEqual(configuration.courseName, "Example Course")
        XCTAssertFalse(configuration.hasUnsavedChanges)
    }

    @MainActor
    func testClubDetection() throws {
        var dictionary: [String: Any] = makeFixtureDictionary()
        dictionary["course_code"] = "CODING"
        let configuration: CourseConfiguration = CourseConfiguration(
            values: dictionary,
            lastSavedData: try JSONSerialization.data(withJSONObject: dictionary)
        )
        XCTAssertTrue(configuration.isClub)
    }
}
