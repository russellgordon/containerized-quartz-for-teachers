import Foundation
import Observation

/// Runs one of the toolchain's shell scripts and streams its output.
///
/// The app never re-implements toolchain behaviour: everything happens by
/// running the same `setup.sh` / `preview.sh` / `deploy.sh` a teacher would
/// run in Terminal, attached to a pseudo-terminal so interactive steps
/// (like `docker exec -it`) behave exactly as they do on the command line.
@Observable
class ScriptRunner {

    // MARK: - Stored properties

    /// Clean, display-ready output of the running (or finished) script.
    var transcript: TranscriptBuilder = TranscriptBuilder()

    /// True from launch until the script exits.
    var isRunning: Bool = false

    /// The exit code of the most recent run, once it has finished.
    var lastExitCode: Int32?

    /// A launch failure message, if the script could not start at all.
    var launchProblem: String?

    /// When output last arrived — used to sense a stalled prompt.
    var lastOutputAt: Date = Date()

    private var process: Process?
    private var terminal: PseudoTerminal?

    // MARK: - Computed properties

    /// True when the last run finished with exit code 0.
    var lastRunSucceeded: Bool {
        if let lastExitCode {
            return lastExitCode == 0
        }
        return false
    }

    // MARK: - Functions

    /// Starts a script (e.g. "preview.sh") from the working folder.
    func run(scriptNamed scriptName: String, arguments: [String], workingDirectory: URL) {
        if isRunning {
            return
        }

        transcript = TranscriptBuilder()
        lastExitCode = nil
        launchProblem = nil

        let scriptURL: URL = workingDirectory.appendingPathComponent(scriptName)
        if !FileManager.default.fileExists(atPath: scriptURL.path) {
            launchProblem = "This working folder is missing a piece it needs (\(scriptName)). Try choosing your working folder again from the File menu."
            return
        }

        var newTerminal: PseudoTerminal
        do {
            newTerminal = try PseudoTerminal()
        } catch {
            launchProblem = "Could not get started: \(error.localizedDescription)"
            return
        }

        let newProcess: Process = Process()
        newProcess.executableURL = URL(fileURLWithPath: "/bin/bash")
        var fullArguments: [String] = [scriptURL.path]
        for argument in arguments {
            fullArguments.append(argument)
        }
        newProcess.arguments = fullArguments
        newProcess.currentDirectoryURL = workingDirectory

        // GUI apps inherit a minimal PATH; the scripts need Homebrew's
        // programs (docker, colima) the same way a Terminal session has them.
        var environment: [String: String] = ProcessInfo.processInfo.environment
        let existingPath: String = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + existingPath
        environment["TERM"] = "xterm-256color"
        newProcess.environment = environment

        newProcess.standardInput = newTerminal.slaveHandle
        newProcess.standardOutput = newTerminal.slaveHandle
        newProcess.standardError = newTerminal.slaveHandle

        newTerminal.masterHandle.readabilityHandler = { handle in
            let data: Data = handle.availableData
            if data.isEmpty {
                return
            }
            let text: String = String(decoding: data, as: UTF8.self)
            Task { @MainActor in
                self.transcript.append(rawText: text)
                self.lastOutputAt = Date()
            }
        }

        newProcess.terminationHandler = { finishedProcess in
            let exitCode: Int32 = finishedProcess.terminationStatus
            Task { @MainActor in
                self.finishRun(exitCode: exitCode)
            }
        }

        do {
            try newProcess.run()
        } catch {
            launchProblem = "Could not get started: \(error.localizedDescription)"
            return
        }

        process = newProcess
        terminal = newTerminal
        isRunning = true
    }

    /// Sends one line of input to the script, as if typed in Terminal.
    func send(line: String) {
        guard let terminal else {
            return
        }
        let data: Data = Data((line + "\n").utf8)
        try? terminal.masterHandle.write(contentsOf: data)
    }

    /// Sends raw text (no newline added) to the script.
    func send(rawText: String) {
        guard let terminal else {
            return
        }
        let data: Data = Data(rawText.utf8)
        try? terminal.masterHandle.write(contentsOf: data)
    }

    /// Stops the running script.
    ///
    /// Note: this terminates the script process itself. A Quartz preview
    /// server left behind inside the container is cleaned up by the
    /// toolchain on the next preview run (it frees port 8081 first).
    func terminate() {
        guard let process else {
            return
        }
        if process.isRunning {
            process.terminate()
        }
    }

    /// A friendly description of what is happening right now, derived
    /// from markers in the output — shown instead of the raw text.
    var friendlyPhase: String {
        let recentText: String = String(transcript.displayText.suffix(4000))
        let phases: [(marker: String, label: String)] = [
            ("Launching Quartz preview", "Starting the preview…"),
            ("Building static site", "Building your site…"),
            ("Emitting files", "Building your site…"),
            ("Parsing input files", "Building your site…"),
            ("Installing dependencies", "Preparing your site (first time can take a few minutes)…"),
            ("Pulling", "Downloading components (first time can take a few minutes)…"),
            ("Starting Colima", "Starting up (first time can take a few minutes)…"),
            ("Waiting for the container runtime", "Starting up…"),
            ("delta deploy", "Publishing your site…"),
            ("Uploaded", "Publishing your site…"),
            ("Deploying", "Publishing your site…"),
        ]
        // The LAST marker to appear in the output is the current phase.
        var bestLabel: String = "Working…"
        var bestPosition: String.Index? = nil
        for phase in phases {
            var searchRange: Range<String.Index>? = nil
            // Find the last occurrence of this marker.
            var lastFound: Range<String.Index>? = nil
            while let found = recentText.range(of: phase.marker, options: [], range: searchRange) {
                lastFound = found
                searchRange = found.upperBound..<recentText.endIndex
            }
            if let lastFound {
                if bestPosition == nil || lastFound.lowerBound > bestPosition! {
                    bestPosition = lastFound.lowerBound
                    bestLabel = phase.label
                }
            }
        }
        return bestLabel
    }

    /// True when the task appears stuck at a question: the current line
    /// is prompt-shaped and no output has arrived for a few seconds.
    /// (Normally the app answers questions itself; this is the safety
    /// net that tells the teacher to look at the details.)
    func mayBeWaitingForInput(asOf now: Date) -> Bool {
        if !isRunning {
            return false
        }
        if now.timeIntervalSince(lastOutputAt) < 4 {
            return false
        }
        let line: String = transcript.currentLine.trimmingCharacters(in: .whitespaces)
        if line.isEmpty {
            return false
        }
        if line.hasSuffix(":") || line.hasSuffix("?") || line.hasSuffix(">") {
            return true
        }
        if line.contains("(y/n)") || line.contains("[Y/n]") || line.contains("[Default:") {
            return true
        }
        return false
    }

    private func finishRun(exitCode: Int32) {
        lastExitCode = exitCode
        isRunning = false
        terminal?.masterHandle.readabilityHandler = nil
        process = nil
        terminal = nil
    }
}
