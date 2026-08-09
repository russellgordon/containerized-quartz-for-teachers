import XCTest
@testable import QuartzTeachers

/// Creates a throwaway course through the app's New Course flow — which
/// runs the REAL ./setup.sh — and verifies the wizard scaffolds it exactly
/// as a command-line run would.
///
/// Requires INTEGRATION_WORKSPACE (see ScriptRunnerIntegrationTests).
final class NewCourseCreatorIntegrationTests: XCTestCase {

    // MARK: - Stored properties

    /// A code unlikely to collide with real courses; cleaned up afterwards.
    let throwawayCode: String = "ZZT2O"

    // MARK: - Functions

    var integrationWorkspacePath: String? {
        let environment: [String: String] = ProcessInfo.processInfo.environment
        return environment["INTEGRATION_WORKSPACE"]
    }

    @MainActor
    func testWizardDrivenCourseCreationMatchesCommandLine() async throws {
        guard let workspacePath = integrationWorkspacePath else {
            throw XCTSkip("Set INTEGRATION_WORKSPACE to run the wizard equivalence test.")
        }
        let workspaceURL: URL = URL(fileURLWithPath: workspacePath)
        let courseDirectoryURL: URL = workspaceURL
            .appendingPathComponent("courses")
            .appendingPathComponent(throwawayCode)

        // Clean slate.
        try? FileManager.default.removeItem(at: courseDirectoryURL)

        // The configuration the wizard form would assemble.
        let configuration: [String: Any] = [
            "course_code": throwawayCode,
            "course_name": "Wizard Equivalence Test",
            "custom_short_name": "",
            "locale": "en-US",
            "emojis": ["sections": ["section1": "🧪"]],
            "num_sections": 1,
            "section_numbers": [1],
            "shared_folders": ["Concepts", "Exercises"],
            "shared_files": ["Learning Goals.md"],
            "per_section_folders": ["All Classes"],
            "per_section_files": ["Key Links.md"],
            "hidden": ["Media", "Learning Goals.md", "Key Links.md"],
            "expandable": ["Concepts", "Exercises"],
            "expandOnFolderClick": false,
            "footer_html": "",
            "show_reading_time": false,
            "fonts": [
                "default": ["header": "Helvetica, Arial", "body": "Helvetica, Arial", "code": "IBM Plex Mono"],
                "sections": ["section1": ["header": "Helvetica, Arial", "body": "Helvetica, Arial", "code": "IBM Plex Mono"]],
            ],
            "show_section_marker": ["sections": ["section1": true]],
            "color_schemes": ["section1": "quartz-standard"],
        ]

        let creator: NewCourseCreator = NewCourseCreator()
        creator.createCourse(configuration: configuration, workspaceURL: workspaceURL)
        XCTAssertNil(creator.preparationProblem)

        // The wizard walks many prompts and scaffolds the course;
        // allow up to five minutes.
        var waited: Double = 0
        while creator.isCreating && waited < 300 {
            try await Task.sleep(for: .seconds(2))
            waited += 2
        }
        XCTAssertFalse(creator.isCreating, "setup.sh should finish; output:\n\(creator.runner.transcript.displayText.suffix(3000))")
        XCTAssertEqual(creator.runner.lastExitCode, 0, "setup.sh should succeed; output:\n\(creator.runner.transcript.displayText.suffix(3000))")

        // Now verify the scaffolding the REAL wizard created — the same
        // artifacts a command-line run produces.
        let fileManager: FileManager = FileManager.default
        let expectedPaths: [String] = [
            "course_config.json",
            "Media",
            ".obsidian/app.json",
            "Concepts/index.md",
            "Exercises/index.md",
            "Learning Goals.md",
            "section1/index.md",
            "section1/All Classes/index.md",
            "section1/Key Links.md",
        ]
        for expectedPath in expectedPaths {
            let fullPath: String = courseDirectoryURL.appendingPathComponent(expectedPath).path
            XCTAssertTrue(fileManager.fileExists(atPath: fullPath), "Wizard should have created \(expectedPath)")
        }

        // The wizard re-writes course_config.json itself at the end; it
        // must round-trip our answers (section markers, scheme, fonts…).
        let finalConfigURL: URL = courseDirectoryURL.appendingPathComponent("course_config.json")
        let finalConfiguration: CourseConfiguration = try CourseConfiguration(contentsOf: finalConfigURL)
        XCTAssertEqual(finalConfiguration.courseName, "Wizard Equivalence Test")
        XCTAssertEqual(finalConfiguration.sectionNumbers, [1])
        XCTAssertEqual(finalConfiguration.emoji(forSection: 1), "🧪")
        XCTAssertEqual(finalConfiguration.colourSchemeID(forSection: 1), "quartz-standard")
        XCTAssertEqual(finalConfiguration.sharedFolders, ["Concepts", "Exercises"])

        // A shared index.md must carry the per-section frontmatter keys the
        // multi-section publishing system depends on.
        let conceptsIndexURL: URL = courseDirectoryURL.appendingPathComponent("Concepts/index.md")
        let conceptsIndexText: String = try String(contentsOf: conceptsIndexURL, encoding: .utf8)
        XCTAssertTrue(conceptsIndexText.contains("createdSection1:"), "Shared scaffolding should use createdSection1 keys")
        XCTAssertTrue(conceptsIndexText.contains("draftSection1: false"), "Shared scaffolding should use draftSection1 keys")

        // Clean up the throwaway course (and its automatic backup).
        try? fileManager.removeItem(at: courseDirectoryURL)
        let backupURL: URL = workspaceURL.appendingPathComponent("courses/_backups/\(throwawayCode)")
        try? fileManager.removeItem(at: backupURL)
    }
}
