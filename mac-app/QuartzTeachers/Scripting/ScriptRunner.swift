import Foundation
import Observation
import OSLog

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

    /// True when the script appears to be waiting for an answer, with the
    /// question it is waiting on. Maintained HERE rather than in a view,
    /// so nothing decides it while a view body is being evaluated.
    var isAwaitingInput: Bool = false
    var pendingQuestion: String = ""

    /// The answer the script would use if the teacher simply agreed —
    /// what it showed in square brackets. Offered in the answer field
    /// rather than left in the wording of the question.
    var suggestedAnswer: String = ""

    private var promptCheck: DispatchWorkItem?

    private var process: Process?
    private var terminal: PseudoTerminal?

    /// Output that has arrived but not yet been shown. Chunks land on a
    /// background queue and reach the interface at a fixed, modest rate.
    nonisolated private let outputBuffer: OutputBuffer = OutputBuffer()

    /// How often buffered output reaches the interface.
    nonisolated private static let flushInterval: TimeInterval = 0.15

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
    ///
    /// `keepingTranscript` continues an earlier run's output, so a task
    /// made of two scripts (build, then publish) reads as one job.
    func run(
        scriptNamed scriptName: String,
        arguments: [String],
        workingDirectory: URL,
        keepingTranscript: Bool = false
    ) {
        if isRunning {
            return
        }

        if !keepingTranscript {
            transcript = TranscriptBuilder()
        }
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
            self.bufferOutput(text)
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
        AppLog.output.info("Started \(scriptName, privacy: .public) \(arguments, privacy: .public)")
    }

    /// Waits for the current run to finish; true when it succeeded.
    func waitUntilFinished() async -> Bool {
        while isRunning {
            try? await Task.sleep(for: .milliseconds(300))
        }
        return lastExitCode == 0
    }

    /// Sends one line of input to the script, as if typed in Terminal.
    func send(line: String) {
        isAwaitingInput = false
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

    /// The milestones for whatever this runner was started to do, set by
    /// the view that launches it. Drives the deterministic progress bar.
    var milestones: [TaskMilestone] = [] {
        didSet {
            reachedMilestoneCount = 0
            unscannedOutput = ""
        }
    }

    /// Milestones detected so far. Tracked as output ARRIVES rather than
    /// by re-reading the whole transcript on every refresh, which stalls
    /// the main thread once a long publish fills it.
    private var reachedMilestoneCount: Int = 0

    /// Output not yet scanned for markers (kept small).
    private var unscannedOutput: String = ""

    /// How many milestones have been reached (0…milestones.count).
    var milestonesReached: Int {
        if milestones.isEmpty {
            return 0
        }
        // A finished, successful task has completed everything.
        if !isRunning && lastExitCode == 0 {
            return milestones.count
        }
        return reachedMilestoneCount
    }

    /// Takes a chunk from the reading queue and schedules a flush.
    /// Runs OFF the main actor, so it must not touch observed state.
    nonisolated private func bufferOutput(_ text: String) {
        let needsScheduling: Bool = outputBuffer.add(text)
        if !needsScheduling {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ScriptRunner.flushInterval) {
            MainActor.assumeIsolated {
                self.flushBufferedOutput()
            }
        }
    }

    /// Hands everything buffered to the interface in one update.
    private func flushBufferedOutput() {
        let buffered: (text: String, chunkCount: Int) = outputBuffer.take()
        let text: String = buffered.text
        let chunkCount: Int = buffered.chunkCount

        if text.isEmpty {
            return
        }
        let started: Date = Date()
        receiveOutput(text)
        let elapsed: TimeInterval = Date().timeIntervalSince(started)
        if elapsed > 0.05 || chunkCount > 200 {
            AppLog.output.warning("""
                Slow flush: \(chunkCount) chunks, \(text.count) characters, \
                \(elapsed, format: .fixed(precision: 3))s, transcript now \
                \(self.transcript.lines.count) lines
                """)
        }
    }

    /// The single entry point for output arriving from a running script:
    /// records it and folds it into the milestone count. (Tests feed
    /// simulated output through here too, so both paths behave alike.)
    func receiveOutput(_ text: String) {
        transcript.append(rawText: text)
        advanceMilestones(with: text)
        lastOutputAt = Date()

        // Fresh output means the script is working, not waiting.
        isAwaitingInput = false
        schedulePromptCheck()
    }

    /// After a quiet spell, decide whether the script is sitting at a
    /// question and, if so, publish it for the interface to ask.
    private func schedulePromptCheck() {
        promptCheck?.cancel()
        let check: DispatchWorkItem = DispatchWorkItem {
            MainActor.assumeIsolated {
                if !self.isRunning {
                    return
                }
                let line: String = self.transcript.currentLine.trimmingCharacters(in: .whitespaces)
                if line.isEmpty {
                    return
                }
                if ScriptRunner.looksLikeQuestion(line) {
                    let asked = ScriptRunner.separateDefaultAnswer(from: line)
                    self.pendingQuestion = asked.question
                    self.suggestedAnswer = asked.suggestedAnswer
                    self.isAwaitingInput = true
                }
            }
        }
        promptCheck = check
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: check)
    }

    /// The published site's address, if the output announced one.
    /// Netlify's deployer prints "Live URL:" when it creates a site and
    /// "Site URL:" on every deploy after that.
    var publishedSiteURL: URL? {
        let text: String = transcript.recentText(maximumCharacters: 8000)
        var bestCandidate: String?
        for rawToken in text.split(whereSeparator: { character in character.isWhitespace }) {
            var token: String = String(rawToken)
            while let last = token.last, last == "." || last == "," || last == ")" {
                token.removeLast()
            }
            if !token.hasPrefix("https://") {
                continue
            }
            // The teacher's site, not Netlify's own pages.
            if token.contains("app.netlify.com") || token.contains("docs.netlify.com") {
                continue
            }
            if token.contains(".netlify.app") {
                bestCandidate = token
            }
        }
        guard let bestCandidate else {
            return nil
        }
        return URL(string: bestCandidate)
    }

    /// Prompt shapes the toolchain's scripts actually use.
    static func looksLikeQuestion(_ line: String) -> Bool {
        if line.hasSuffix(":") || line.hasSuffix("?") || line.hasSuffix(">") {
            return true
        }
        if line.contains("(y/n)") || line.contains("[Y/n]") || line.contains("[Default:") {
            return true
        }
        return false
    }

    /// Splits a question into the wording to show and the default answer
    /// to offer, when the script named one in square brackets.
    ///
    /// "Enter Netlify site name [ics3u-s3-2026-gordon]:" becomes
    /// "Enter Netlify site name:" with "ics3u-s3-2026-gordon" waiting in
    /// the answer field, ready to accept or type over. That reads as a
    /// filled-in form rather than as instructions to follow.
    static func separateDefaultAnswer(from question: String) -> (question: String, suggestedAnswer: String) {
        guard let openIndex = question.lastIndex(of: "["), let closeIndex = question.lastIndex(of: "]") else {
            return (question, "")
        }
        if openIndex >= closeIndex {
            return (question, "")
        }
        var offered: String = String(question[question.index(after: openIndex)..<closeIndex]).trimmingCharacters(in: .whitespaces)

        // Some prompts name what they are offering: "[Default: foo]".
        let defaultLabel: String = "Default:"
        if offered.hasPrefix(defaultLabel) {
            offered = String(offered.dropFirst(defaultLabel.count)).trimmingCharacters(in: .whitespaces)
        }
        if offered.isEmpty {
            return (question, "")
        }
        // "[Y/n]" lists choices rather than naming a value, so the
        // wording keeps it and nothing is filled in.
        if offered.contains("/") {
            return (question, "")
        }

        var wording: String = String(question[question.startIndex..<openIndex]).trimmingCharacters(in: .whitespaces)
        let afterBracket: String = String(question[question.index(after: closeIndex)...]).trimmingCharacters(in: .whitespaces)
        wording += afterBracket
        return (wording, offered)
    }

    /// Folds newly arrived output into the milestone count.
    private func advanceMilestones(with newText: String) {
        if milestones.isEmpty {
            return
        }
        unscannedOutput += newText

        // Take the HIGHEST milestone the new output reveals: a later
        // marker implies the earlier steps, so varying output never
        // stalls or reverses the bar.
        while reachedMilestoneCount < milestones.count {
            var matchedIndex: Int?
            var matchedEnd: String.Index?
            for index in reachedMilestoneCount..<milestones.count {
                if let range = unscannedOutput.range(of: milestones[index].marker) {
                    matchedIndex = index
                    matchedEnd = range.upperBound
                }
            }
            guard let matchedIndex, let matchedEnd else {
                break
            }
            reachedMilestoneCount = matchedIndex + 1
            unscannedOutput = String(unscannedOutput[matchedEnd...])
        }

        // Keep only enough tail for a marker split across two chunks.
        if unscannedOutput.count > 8000 {
            unscannedOutput = String(unscannedOutput.suffix(4000))
        }
    }

    /// Progress from 0 to 1 for the bar.
    var progressFraction: Double {
        if milestones.isEmpty {
            return 0
        }
        return Double(milestonesReached) / Double(milestones.count)
    }

    /// The step currently under way, e.g. "Building your site" — the
    /// milestone AFTER the last one reached, or the final one when done.
    var currentMilestoneLabel: String {
        if milestones.isEmpty {
            return friendlyPhase
        }
        let reached: Int = milestonesReached
        if reached >= milestones.count {
            return milestones[milestones.count - 1].label
        }
        return milestones[reached].label
    }

    /// "Step 2 of 6" for the label beside the bar.
    var stepDescription: String {
        if milestones.isEmpty {
            return ""
        }
        let currentStep: Int = min(milestonesReached + 1, milestones.count)
        return "Step \(currentStep) of \(milestones.count)"
    }

    /// A friendly description of what is happening right now, derived
    /// from markers in the output — used when no milestones are set.
    var friendlyPhase: String {
        let recentText: String = String(transcript.recentText(maximumCharacters: 4000))
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
        promptCheck?.cancel()
        isAwaitingInput = false
        // Show anything still buffered when the script ended.
        flushBufferedOutput()
        AppLog.output.info("Finished with exit code \(exitCode), transcript \(self.transcript.lines.count) lines")
        lastExitCode = exitCode
        isRunning = false
        terminal?.masterHandle.readabilityHandler = nil
        process = nil
        terminal = nil
    }
}
