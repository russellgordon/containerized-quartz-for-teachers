import XCTest
@testable import QuartzTeachers

/// Runs `contracts/shared-rules.json` — four rule sets that both apps need and
/// neither platform owns.
///
/// Two of them sit on top of machinery that could not be less alike: launchd
/// against Task Scheduler, AppKit against WinUI. That is the argument for
/// writing the RULES down rather than the implementation — what must be
/// refused, matched or stripped does not change with the machinery that does
/// it, and a Windows session reading "we refuse a section that has never been
/// deployed" does not need to know what a plist is.
@MainActor
final class SharedRulesContractTests: XCTestCase {

    // MARK: - What a scheduled deploy refuses, and in what order

    /// Everything a deploy running at 06:30 would ASK is asked now, while
    /// somebody is awake. The ORDER matters as much as the list: the first
    /// match is what the teacher is told.
    func testScheduledDeploysRefuseWhatTheContractSays() throws {
        let section: [String: Any] = try SharedRulesContractTests.section("scheduledDeployRefusals")
        let now: Date = Date(timeIntervalSince1970: 1_786_000_000)

        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let name: String = try XCTUnwrap(testCase["name"] as? String)
            let given: [String: Any] = testCase["given"] as? [String: Any] ?? [:]

            let root: URL = FileManager.default.temporaryDirectory
                .appendingPathComponent("scheduled-\(UUID().uuidString)")
            defer { try? FileManager.default.removeItem(at: root) }
            let course: Course = try makeCourse(
                in: root,
                target: given["target"] as? String,
                folderPath: (given["folderProblem"] as? Bool == true)
                    ? root.appendingPathComponent("no-such-folder").path
                    : root.path,
                hasDeployedBefore: given["hasDeployedBefore"] as? Bool ?? true
            )

            let when: Date = (given["whenIsInThePast"] as? Bool == true)
                ? now.addingTimeInterval(-3600)
                : now.addingTimeInterval(3600)

            let problem: String? = ScheduledDeploy.problem(
                course: course,
                sectionNumber: 1,
                when: when,
                now: now,
                cloudflareAccountID: given["cloudflareAccountID"] as? String ?? "",
                locale: Locale(identifier: "en_CA")
            )

            guard let expected = testCase["expectRefusal"] as? String else {
                XCTAssertNil(problem, "\(name): nothing should be wrong — it said \"\(problem ?? "")\"")
                continue
            }
            let said: String = try XCTUnwrap(problem, "\(name): should have been refused as \(expected)")
            XCTAssertEqual(
                SharedRulesContractTests.name(ofRefusal: said), expected,
                "\(name): refused, but not for the reason the contract names — it said \"\(said)\""
            )
        }
    }

    // MARK: - What the sidebar's filter shows

    func testTheSidebarFilterMatchesAsTheContractSays() throws {
        let section: [String: Any] = try SharedRulesContractTests.section("sidebarFilter")
        let root: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("filter-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }

        let workspace: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        // A working folder is recognised by its launchers; stubs are enough,
        // and nothing here ever runs one.
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        for launcher in ["preview.sh", "deploy.sh", "setup.sh"] {
            try "#!/bin/bash\n".write(
                to: root.appendingPathComponent(launcher), atomically: true, encoding: .utf8
            )
        }
        for entry in try XCTUnwrap(section["courses"] as? [[String: String]]) {
            try makeCourseFolder(
                code: try XCTUnwrap(entry["code"]), name: try XCTUnwrap(entry["name"]), in: root
            )
        }
        workspace.chooseWorkspace(at: root)

        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            workspace.filterText = try XCTUnwrap(testCase["filter"] as? String)
            var shown: [String] = []
            for course in workspace.filteredCourses {
                shown.append(course.code)
            }
            XCTAssertEqual(
                shown.sorted(), (try XCTUnwrap(testCase["expect"] as? [String])).sorted(),
                "filter “\(workspace.filterText)”"
            )
        }
    }

    // MARK: - What is stripped from the launchers' output

    func testTheTranscriptStripsWhatTheContractSays() throws {
        let section: [String: Any] = try SharedRulesContractTests.section("transcriptStripping")
        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let input: String = try XCTUnwrap(testCase["input"] as? String)
            XCTAssertEqual(
                TranscriptBuilder.strippingControlSequences(from: input),
                try XCTUnwrap(testCase["expect"] as? String),
                "input \(input.debugDescription)"
            )
        }
    }

    // MARK: - What counts as a curriculum expectation

    func testCurriculumPagesAreRecognisedAsTheContractSays() throws {
        let rules: [String: Any] = try SharedRulesContractTests.section("curriculumRules")
        let root: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("curriculum-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let course: Course = try makeCourse(in: root, target: nil, folderPath: root.path,
                                            hasDeployedBefore: true)

        let pages: [String: Any] = try XCTUnwrap(rules["isCurriculumPage"] as? [String: Any])
        for testCase in try XCTUnwrap(pages["cases"] as? [[String: Any]]) {
            let path: String = try XCTUnwrap(testCase["path"] as? String)
            let url: URL = course.directoryURL.appendingPathComponent("section1").appendingPathComponent(path)
            XCTAssertEqual(
                AssistCurriculumMentions.isCurriculum(pageAt: url, in: course),
                testCase["expect"] as? Bool, path
            )
        }

        let codes: [String: Any] = try XCTUnwrap(rules["isExpectationCode"] as? [String: Any])
        for testCase in try XCTUnwrap(codes["cases"] as? [[String: Any]]) {
            let code: String = try XCTUnwrap(testCase["code"] as? String)
            XCTAssertEqual(
                AssistCurriculumMentions.isExpectationCode(code), testCase["expect"] as? Bool, code
            )
        }

        let wording: [String: Any] = try XCTUnwrap(rules["expectationWording"] as? [String: Any])
        for testCase in try XCTUnwrap(wording["cases"] as? [[String: Any]]) {
            let body: String = try XCTUnwrap(testCase["body"] as? String)
            let page: String = """
            ---
            title: B2.1
            ---

            \(body)
            """
            XCTAssertEqual(
                AssistCurriculumMentions.wording(in: page),
                try XCTUnwrap(testCase["expect"] as? String), body
            )
        }
    }

    // MARK: - Private

    /// The contract names refusals by CASE. The sentences are the product's
    /// wording and belong to the wording contract; WHICH refusal fired has to
    /// match on both platforms.
    private static func name(ofRefusal said: String) -> String {
        if said.contains("has already passed") {
            return "hasAlreadyPassed"
        }
        if said.contains("deploys to a folder") {
            return "deployFolderNeedsAttention"
        }
        if said.contains("Account ID") {
            return "cloudflareAccountMissing"
        }
        if said.contains("never been deployed") {
            return "neverDeployed"
        }
        return "other"
    }

    private func makeCourse(in root: URL, target: String?, folderPath: String,
                            hasDeployedBefore: Bool) throws -> Course {
        let courseURL: URL = root.appendingPathComponent("courses").appendingPathComponent("ICS3U")
        try FileManager.default.createDirectory(
            at: courseURL.appendingPathComponent("section1/All Classes"), withIntermediateDirectories: true
        )
        var configuration: [String: Any] = [
            "course_code": "ICS3U",
            "course_name": "Introduction to Computer Science",
            "section_numbers": [1],
            "num_sections": 1,
        ]
        if let target {
            configuration["deploy_target"] = target
            configuration["deploy_folder_path"] = folderPath
        }
        try JSONSerialization.data(withJSONObject: configuration, options: [.prettyPrinted])
            .write(to: courseURL.appendingPathComponent("course_config.json"))
        let loaded: CourseConfiguration = try CourseConfiguration(
            contentsOf: courseURL.appendingPathComponent("course_config.json")
        )
        if hasDeployedBefore {
            let marker: URL = courseURL.appendingPathComponent(".netlify_sites")
            try FileManager.default.createDirectory(at: marker, withIntermediateDirectories: true)
            try "{}".write(to: marker.appendingPathComponent("section1.json"),
                           atomically: true, encoding: .utf8)
        }
        return Course(code: "ICS3U", directoryURL: courseURL, configuration: loaded)
    }

    private func makeCourseFolder(code: String, name: String, in root: URL) throws {
        let courseURL: URL = root.appendingPathComponent("courses").appendingPathComponent(code)
        try FileManager.default.createDirectory(
            at: courseURL.appendingPathComponent("section1"), withIntermediateDirectories: true
        )
        let configuration: [String: Any] = [
            "course_code": code,
            "course_name": name,
            "section_numbers": [1],
            "num_sections": 1,
        ]
        try JSONSerialization.data(withJSONObject: configuration, options: [.prettyPrinted])
            .write(to: courseURL.appendingPathComponent("course_config.json"))
    }

    private static func section(_ name: String) throws -> [String: Any] {
        let url: URL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("contracts/shared-rules.json")
        let all: [String: Any] = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]
        )
        return try XCTUnwrap(all[name] as? [String: Any], "No \(name) in shared-rules.json")
    }
}
