import XCTest
@testable import QuartzTeachers

/// Runs `contracts/app-rules.json` — the rules both apps must agree on that
/// have nothing to do with the assistant.
///
/// Same division as the assistant contract, for the same reason. The cases are
/// data, so the Windows suite runs the identical list; the setup is Swift,
/// because only this side knows what a `CourseConfiguration` is. And the
/// expectations are AUTHORED rather than generated wherever a regression must
/// be catchable: a readout of the code cannot fail when the code changes.
@MainActor
final class AppRulesContractTests: XCTestCase {

    // MARK: - The launcher's arguments

    /// The bug this exists for was silent. The assistant built its own
    /// `deploy.sh` arguments, never passed `--target cloudflare`, and a
    /// Cloudflare course deployed to Netlify: no error, no failure, the site
    /// simply appeared on the wrong host.
    func testDeployArgumentsAreWhatTheContractSays() throws {
        let rules: [String: Any] = try AppRulesContractTests.readRules()
        let section: [String: Any] = try XCTUnwrap(rules["deployArguments"] as? [String: Any])

        for testCase in try XCTUnwrap(section["cases"] as? [[String: Any]]) {
            let name: String = try XCTUnwrap(testCase["name"] as? String)
            let configuration: CourseConfiguration = try roundTripped(
                try XCTUnwrap(testCase["configuration"] as? [String: Any])
            )
            let arguments: [String] = DeployCommand.arguments(
                courseCode: try XCTUnwrap(testCase["course"] as? String),
                sectionNumber: try XCTUnwrap(testCase["section"] as? Int),
                configuration: configuration,
                cloudflareAccountID: testCase["cloudflareAccountID"] as? String ?? ""
            )
            XCTAssertEqual(arguments, try XCTUnwrap(testCase["expectArguments"] as? [String]), name)
        }
    }

    // MARK: - What a teacher is told about what they typed

    func testTheValidationSaysWhatTheContractSays() throws {
        let rules: [String: Any] = try AppRulesContractTests.readRules()
        let section: [String: Any] = try XCTUnwrap(rules["configurationRules"] as? [String: Any])

        for testCase in try XCTUnwrap(section["cloudflareAccountID"] as? [[String: Any]]) {
            let input: String = try XCTUnwrap(testCase["input"] as? String)
            XCTAssertEqual(
                CourseConfiguration.cloudflareAccountProblem(forID: input),
                testCase["expectProblem"] as? String,
                "Cloudflare Account ID \"\(input)\""
            )
        }

        for testCase in try XCTUnwrap(section["customDomain"] as? [[String: Any]]) {
            let input: String = try XCTUnwrap(testCase["input"] as? String)
            XCTAssertEqual(
                CourseConfiguration.normalizedCustomDomain(input),
                try XCTUnwrap(testCase["expectNormalized"] as? String),
                "Custom domain \"\(input)\""
            )
        }

        // The folder cases need a real filesystem, so the contract writes
        // tokens and the runner supplies the paths — which keeps the CASES
        // portable while the setup stays local. A Windows runner substitutes
        // its own paths for the same three tokens.
        let root: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("deploy-folder-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let realFile: URL = root.appendingPathComponent("not-a-folder.txt")
        try "x".write(to: realFile, atomically: true, encoding: .utf8)

        for testCase in try XCTUnwrap(section["deployFolder"] as? [[String: Any]]) {
            let written: String = try XCTUnwrap(testCase["input"] as? String)
            let input: String = written
                .replacingOccurrences(of: "@MISSING@", with: root.appendingPathComponent("nope").path)
                .replacingOccurrences(of: "@FILE@", with: realFile.path)
                .replacingOccurrences(of: "@FOLDER@", with: root.path)
            XCTAssertEqual(
                CourseConfiguration.deployFolderProblem(forPath: input),
                testCase["expectProblem"] as? String,
                "Deploy folder \"\(written)\""
            )
        }
    }

    // MARK: - The milestones, and where their markers come from

    /// The generated readout is still what `TaskMilestones` holds.
    func testTheCommittedMilestonesAreWhatTheAppWatchesFor() throws {
        let committed: [String: Any] = try XCTUnwrap(
            (try AppRulesContractTests.readRules())["milestones"] as? [String: Any]
        )
        let generated: [String: Any] = try XCTUnwrap(
            AppRulesContract.generated()["milestones"] as? [String: Any]
        )
        let left: Data = try AssistContract.encode(["value": generated])
        let right: Data = try AssistContract.encode(["value": committed])
        XCTAssertEqual(
            String(decoding: right, as: UTF8.self), String(decoding: left, as: UTF8.self),
            "contracts/app-rules.json no longer matches TaskMilestones."
            + "\n\nRegenerate it:\n    Plantoir --write-contracts contracts"
        )
    }

    /// **The one worth having.** Every marker is classified by where its text
    /// comes from, and the classification is checked against the actual files
    /// — because it decides whether Windows must match the string exactly.
    ///
    /// A marker printed by `scripts/*.py` is identical on both platforms and
    /// must match to the character. A marker printed by a launcher has a
    /// separately written `.ps1` counterpart and deliberately differs: the
    /// mac's "Setting up this Mac" is Windows' "Setting up this PC". Telling
    /// the two apart by eye is how a progress bar quietly stops moving.
    func testEveryMarkerIsClassifiedAndTheClassificationIsTrue() throws {
        let rules: [String: Any] = try AppRulesContractTests.readRules()
        let milestones: [String: Any] = try XCTUnwrap(rules["milestones"] as? [String: Any])
        let origins: [String: String] = try XCTUnwrap(
            (rules["markerOrigins"] as? [String: Any])?["origins"] as? [String: String]
        )
        let repository: URL = AppRulesContractTests.repositoryRoot()

        var seen: Set<String> = []
        for (key, value) in milestones where key != "note" {
            for step in try XCTUnwrap(value as? [[String: String]]) {
                seen.insert(try XCTUnwrap(step["marker"]))
            }
        }

        for marker in seen.sorted() {
            let origin: String = try XCTUnwrap(
                origins[marker],
                "The marker \"\(marker)\" is not classified in markerOrigins. Windows cannot tell "
                + "whether to match it exactly or write their own — say which."
            )
            switch origin {
            case "shared-python":
                XCTAssertTrue(
                    AppRulesContractTests.text(marker, appearsUnder: repository.appendingPathComponent("scripts")),
                    "\"\(marker)\" is classified as shared Python and is not printed by anything in "
                    + "scripts/ — so Windows would be told to match a string that no longer exists."
                )
            case "launcher":
                var found: Bool = false
                for launcher in ["setup.sh", "preview.sh", "deploy.sh"] {
                    let url: URL = repository.appendingPathComponent(launcher)
                    if let text = try? String(contentsOf: url, encoding: .utf8), text.contains(marker) {
                        found = true
                    }
                }
                XCTAssertTrue(found, "\"\(marker)\" is classified as a launcher marker and no launcher prints it.")
            default:
                // "elsewhere" is an honest answer — the Docker build and the
                // tools print things too — but it means somebody has to look.
                XCTAssertEqual(origin, "elsewhere", "Unknown origin \"\(origin)\" for \"\(marker)\"")
            }
        }
    }

    // MARK: - The preview's ports

    func testThePortsAreWhatTheContractSays() throws {
        let ports: [String: Any] = try XCTUnwrap(
            (try AppRulesContractTests.readRules())["previewPorts"] as? [String: Any]
        )
        XCTAssertEqual(
            PreviewLeases.availablePorts, try XCTUnwrap(ports["containerPorts"] as? [Int]),
            "The container publishes these; both apps map onto them."
        )

        // The host-side block: 8081, 8091, 8101 — one block per working
        // folder, so two folders previewing at once cannot collide.
        let step: Int = try XCTUnwrap(ports["hostBlockStep"] as? Int)
        let blocks: [Int] = try XCTUnwrap(ports["firstHostBlock"] as? [Int])
        for index in 1..<blocks.count {
            XCTAssertEqual(blocks[index] - blocks[index - 1], step, "The blocks step by \(step)")
        }
        XCTAssertEqual(blocks.first, PreviewLeases.availablePorts.first)
    }

    // MARK: - Private

    private func roundTripped(_ values: [String: Any]) throws -> CourseConfiguration {
        let data: Data = try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
        let url: URL = FileManager.default.temporaryDirectory
            .appendingPathComponent("app-rules-config-\(UUID().uuidString).json")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        return try CourseConfiguration(contentsOf: url)
    }

    private static func text(_ needle: String, appearsUnder directory: URL) -> Bool {
        guard let walker = FileManager.default.enumerator(atPath: directory.path) else {
            return false
        }
        for case let relative as String in walker where relative.hasSuffix(".py") {
            let url: URL = directory.appendingPathComponent(relative)
            if let text = try? String(contentsOf: url, encoding: .utf8), text.contains(needle) {
                return true
            }
        }
        return false
    }

    private static func repositoryRoot() -> URL {
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private static func readRules() throws -> [String: Any] {
        let url: URL = repositoryRoot()
            .appendingPathComponent("contracts")
            .appendingPathComponent(AppRulesContract.fileName)
        return try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]
        )
    }
}
