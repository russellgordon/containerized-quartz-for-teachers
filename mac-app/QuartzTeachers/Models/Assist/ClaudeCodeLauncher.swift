import AppKit
import Foundation

/// Starting a Claude Code session already connected to this working folder's
/// Plantoir tools, locked to one course.
///
/// The teacher never types a command. Everything the connection needs is
/// written for them and thrown away with the session:
///
/// * **No global configuration is touched.** The connection is passed with
///   `--mcp-config`, and `--strict-mcp-config` means only that server is
///   loaded — so a teacher's own MCP servers are neither used nor disturbed,
///   and nothing is left behind when the session ends.
/// * **Nothing lands in the teacher's folder.** The config sits in the app's
///   own data directory, not in the vault Obsidian is watching.
/// * **The session is locked to the course it was started from.** Passed to
///   the server rather than asked for in a prompt, so it holds however the
///   conversation wanders.
///
/// The menu item only appears when this returns true from
/// `isAvailable` — a teacher without Claude Code should not be offered a
/// door that opens onto an error.
nonisolated enum ClaudeCodeLauncher {

    // MARK: - Computed properties

    /// Both halves have to be present: the assistant, and the tools for it to use.
    static var isAvailable: Bool {
        return findClaude() != nil && findServer() != nil
    }

    // MARK: - Functions

    /// Where Claude Code is, or nil. Checked on PATH first, then the places
    /// its own installers put it.
    static func findClaude() -> String? {
        if let onPath = onPath("claude") {
            return onPath
        }

        let homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
        var candidates: [String] = [
            homeDirectory.appendingPathComponent(".local/bin/claude").path,
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            homeDirectory.appendingPathComponent(".npm-global/bin/claude").path,
            homeDirectory.appendingPathComponent(".bun/bin/claude").path,
        ]

        let nvmNodeDirectory: URL = homeDirectory.appendingPathComponent(".nvm/versions/node")
        if let nodeVersions = try? FileManager.default.contentsOfDirectory(atPath: nvmNodeDirectory.path) {
            for version in nodeVersions {
                let nvmClaudePath: String = nvmNodeDirectory.appendingPathComponent("\(version)/bin/claude").path
                candidates.append(nvmClaudePath)
            }
        }

        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    /// The MCP server, which is the Plantoir binary itself answering `--mcp-stdio`.
    static func findServer() -> String? {
        if let executablePath = Bundle.main.executablePath,
           FileManager.default.isExecutableFile(atPath: executablePath) {
            return executablePath
        }
        if let firstArgument = ProcessInfo.processInfo.arguments.first,
           FileManager.default.isExecutableFile(atPath: firstArgument) {
            return firstArgument
        }
        return nil
    }

    /// Check if a binary exists and is executable in any folder listed in PATH.
    static func onPath(_ name: String) -> String? {
        guard let pathVariable = ProcessInfo.processInfo.environment["PATH"] else {
            return nil
        }
        let directories: [String] = pathVariable.components(separatedBy: ":")
        for directory in directories {
            let candidate: String = (directory.trimmingCharacters(in: .whitespacesAndNewlines) as NSString)
                .appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return nil
    }

    /// Open a session for one course. Returns false when it could not be
    /// started, so the caller can say so rather than leaving a teacher looking
    /// at nothing.
    @discardableResult
    static func open(workspacePath: String, courseCode: String, courseName: String) -> Bool {
        guard let claude: String = findClaude(),
              let server: String = findServer() else {
            return false
        }

        let configPath: String
        do {
            configPath = try writeConfig(workspacePath: workspacePath, courseCode: courseCode, serverPath: server)
        } catch {
            return false
        }

        let prompt: String = greeting(courseCode: courseCode, courseName: courseName)

        let scriptPath: String
        do {
            scriptPath = try writeLauncherScript(
                workspacePath: workspacePath,
                courseCode: courseCode,
                claudePath: claude,
                configPath: configPath,
                prompt: prompt
            )
        } catch {
            return false
        }

        ActivityTrail.note(.assistantOpened, "started Claude Code for \(courseCode)")

        return launchTerminal(scriptPath: scriptPath)
    }

    /// The opening message. It names the course and points at the plan tools,
    /// because the safety of every write here depends on a plan being shown to
    /// the teacher first — and an assistant that starts by reading is far more
    /// useful than one that starts by asking what to do.
    static func greeting(courseCode: String, courseName: String) -> String {
        var text: String = "I'm a teacher working on \(courseCode)"
        let trimmedName: String = courseName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && trimmedName != courseCode {
            text.append(" (\(trimmedName))")
        }
        text.append(" in Plantoir. Use the plantoir tools for anything to do with this course. ")
        text.append("Start by listing its sections so we both know what's there. ")
        text.append("Before changing anything, use the matching plan tool first and show me what it says, ")
        text.append("in plain words, and wait for me to agree.")
        return text.replacingOccurrences(of: "\"", with: "'")
    }

    /// The connection, written per course into the app's own data directory.
    /// One file per course so two sessions on different courses do not
    /// overwrite each other's configuration mid-launch.
    static func writeConfig(workspacePath: String, courseCode: String, serverPath: String) throws -> String {
        let appSupportDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Plantoir/assist")
        try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)

        let configuration: [String: Any] = [
            "mcpServers": [
                "plantoir": [
                    "command": serverPath,
                    "args": [
                        "--mcp-stdio",
                        workspacePath
                    ]
                ]
            ]
        ]

        let data: Data = try JSONSerialization.data(
            withJSONObject: configuration,
            options: [.prettyPrinted, .sortedKeys]
        )
        let targetFile: URL = appSupportDirectory.appendingPathComponent("mcp-\(courseCode).json")
        try data.write(to: targetFile)
        return targetFile.path
    }

    /// Writes an executable `.command` launcher script in the app's data directory.
    static func writeLauncherScript(
        workspacePath: String,
        courseCode: String,
        claudePath: String,
        configPath: String,
        prompt: String
    ) throws -> String {
        let appSupportDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Plantoir/assist")
        try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)

        let scriptContent: String = """
        #!/bin/bash
        cd \(escapeForShell(workspacePath)) || exit 1
        \(escapeForShell(claudePath)) --mcp-config \(escapeForShell(configPath)) --strict-mcp-config \(escapeForShell(prompt))
        """

        let scriptFile: URL = appSupportDirectory.appendingPathComponent("launch-\(courseCode).command")
        try scriptContent.write(to: scriptFile, atomically: true, encoding: .utf8)

        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptFile.path)
        return scriptFile.path
    }

    /// Single-quote a string safely for POSIX shell execution.
    static func escapeForShell(_ text: String) -> String {
        return "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Launches a terminal emulator running the generated .command script.
    ///
    /// Uses LaunchServices via `NSWorkspace` instead of AppleScript/AppleEvents
    /// so macOS does not require Automation / AppleEvents permissions.
    private static func launchTerminal(scriptPath: String) -> Bool {
        let itermBundleID: String = "com.googlecode.iterm2"
        let isITermRunning: Bool = !NSRunningApplication.runningApplications(
            withBundleIdentifier: itermBundleID
        ).isEmpty

        if isITermRunning {
            if NSWorkspace.shared.openFile(scriptPath, withApplication: "iTerm") {
                return true
            }
        }

        if NSWorkspace.shared.openFile(scriptPath, withApplication: "Terminal") {
            return true
        }

        let scriptURL: URL = URL(fileURLWithPath: scriptPath)
        return NSWorkspace.shared.open(scriptURL)
    }
}
