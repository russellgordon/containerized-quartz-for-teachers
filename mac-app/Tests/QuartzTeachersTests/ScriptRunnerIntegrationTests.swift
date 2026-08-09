import XCTest
@testable import QuartzTeachers

/// Runs the REAL preview.sh through the app's script runner and verifies
/// the result is identical to running it at the command line.
///
/// Requires INTEGRATION_WORKSPACE to point at a real working folder (the
/// repository checkout, which has the EXC2O example course and a container
/// already set up). Skipped otherwise, so plain unit runs stay fast.
final class ScriptRunnerIntegrationTests: XCTestCase {

    // MARK: - Functions

    var integrationWorkspacePath: String? {
        let environment: [String: String] = ProcessInfo.processInfo.environment
        return environment["INTEGRATION_WORKSPACE"]
    }

    /// The page contents with one known nondeterminism normalized away:
    /// Quartz's OverflowList emits a random DOM id unless the toolchain's
    /// stable-id patch has been applied by a setup.sh run in the current
    /// container. Both CLI and GUI builds share that behaviour, so it must
    /// not fail an equivalence comparison.
    func normalizedContents(at url: URL) throws -> String {
        var text: String = try String(contentsOf: url, encoding: .utf8)
        text = text.replacingOccurrences(
            of: #"class="explorer-ul overflow" id="[A-Za-z0-9]+""#,
            with: #"class="explorer-ul overflow" id="NORMALIZED""#,
            options: [.regularExpression]
        )
        return text
    }

    @MainActor
    func testPreviewBuildMatchesCommandLineResult() async throws {
        guard let workspacePath = integrationWorkspacePath else {
            throw XCTSkip("Set INTEGRATION_WORKSPACE to run the preview equivalence test.")
        }
        let workspaceURL: URL = URL(fileURLWithPath: workspacePath)
        let indexURL: URL = workspaceURL
            .appendingPathComponent("courses/EXC2O/.merged_output/section1/public/index.html")

        // First, produce the command-line baseline by genuinely running the
        // script the way a teacher would in Terminal. script(1) supplies
        // the pseudo-terminal that `docker exec -it` requires, with no app
        // code involved — a truly independent CLI invocation.
        let cliProcess: Process = Process()
        cliProcess.executableURL = URL(fileURLWithPath: "/usr/bin/script")
        cliProcess.arguments = ["-q", "/dev/null", "./preview.sh", "EXC2O", "1", "--build-only"]
        cliProcess.currentDirectoryURL = workspaceURL
        var cliEnvironment: [String: String] = ProcessInfo.processInfo.environment
        let existingPath: String = cliEnvironment["PATH"] ?? "/usr/bin:/bin"
        cliEnvironment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + existingPath
        cliProcess.environment = cliEnvironment
        cliProcess.standardOutput = FileHandle.nullDevice
        cliProcess.standardError = FileHandle.nullDevice
        try cliProcess.run()
        while cliProcess.isRunning {
            try await Task.sleep(for: .seconds(2))
        }
        XCTAssertEqual(cliProcess.terminationStatus, 0, "The command-line baseline build should succeed")
        let baselineContents: String = try normalizedContents(at: indexURL)

        // Now run the SAME script through the app's runner.
        let runner: ScriptRunner = ScriptRunner()
        runner.run(
            scriptNamed: "preview.sh",
            arguments: ["EXC2O", "1", "--build-only"],
            workingDirectory: workspaceURL
        )
        XCTAssertNil(runner.launchProblem)

        // Wait for completion (up to 5 minutes; the scaffold is cached).
        var waited: Double = 0
        while runner.isRunning && waited < 300 {
            try await Task.sleep(for: .seconds(2))
            waited += 2
        }

        XCTAssertFalse(runner.isRunning, "preview.sh should finish within five minutes")
        XCTAssertEqual(runner.lastExitCode, 0, "preview.sh should succeed; output:\n\(runner.transcript.displayText.suffix(2000))")
        XCTAssertTrue(
            runner.transcript.displayText.contains("Static build complete"),
            "The transcript should show the toolchain's success message"
        )

        // The GUI-driven build must produce the same site as the CLI build.
        let rebuiltContents: String = try normalizedContents(at: indexURL)
        XCTAssertEqual(baselineContents, rebuiltContents, "App-driven build should be byte-identical to the CLI build")
    }

    /// The Preview button's real path: serve mode, wait for the local
    /// server, and confirm the page the embedded web view would load.
    @MainActor
    func testPreviewServeModeServesTheSite() async throws {
        guard let workspacePath = integrationWorkspacePath else {
            throw XCTSkip("Set INTEGRATION_WORKSPACE to run the serve-mode test.")
        }
        let workspaceURL: URL = URL(fileURLWithPath: workspacePath)

        let runner: ScriptRunner = ScriptRunner()
        runner.run(
            scriptNamed: "preview.sh",
            arguments: ["EXC2O", "1"],
            workingDirectory: workspaceURL
        )
        XCTAssertNil(runner.launchProblem)

        // Poll the server the same way SectionDetailView does.
        let serverURL: URL = URL(string: "http://localhost:8081/")!
        var pageText: String = ""
        var waited: Double = 0
        while waited < 240 {
            if !runner.isRunning {
                XCTFail("preview.sh exited early; output:\n\(runner.transcript.displayText.suffix(2000))")
                return
            }
            var request: URLRequest = URLRequest(url: serverURL)
            request.timeoutInterval = 2
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        pageText = String(decoding: data, as: UTF8.self)
                        break
                    }
                }
            } catch {
                // Not up yet.
            }
            try? await Task.sleep(for: .seconds(2))
            waited += 2
        }

        XCTAssertTrue(pageText.contains("EXC2O"), "The served page should be the example course site")

        runner.terminate()
        var stopWaited: Double = 0
        while runner.isRunning && stopWaited < 20 {
            try? await Task.sleep(for: .seconds(1))
            stopWaited += 1
        }
        XCTAssertFalse(runner.isRunning, "Stop should end the preview script")
    }
}
