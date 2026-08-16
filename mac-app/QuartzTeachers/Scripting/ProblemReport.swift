import Foundation

/// What one task did, kept so it can still be read after the window that
/// showed it has gone.
///
/// This is the whole reason the feature exists. A teacher reports a problem
/// AFTER it has happened — the sheet is closed, the app may have been
/// restarted — so anything that asks them to turn something on and do it
/// again is a feature that will not be used. Records are written as tasks
/// finish, whether they succeeded or not, and the oldest are thrown away.
nonisolated struct RunRecord {

    // MARK: - Stored properties

    let startedAt: Date
    let finishedAt: Date

    /// The launcher that ran, and what it was asked to do.
    let scriptName: String
    let arguments: [String]

    /// The folder it ran in — redacted like everything else, so what
    /// survives is the shape of the path rather than who owns it.
    let workingFolderPath: String

    /// The outcome in the words the app itself used.
    let outcome: String

    /// Whether this counts as a failure at all.
    ///
    /// Kept as its own fact rather than read back out of `outcome`, because
    /// a task stopped on purpose also exits non-zero and reading the word
    /// "Failed" out of a sentence is the kind of test that passes until
    /// somebody rewords the sentence.
    let wasFailure: Bool

    /// What `FailureExplainer` made of it, when it recognised anything.
    /// Recorded because its SILENCE is the interesting case: a failure it
    /// could not explain is the one worth a person's attention.
    let explanation: String?

    /// Everything the task printed, already tidied by `TranscriptBuilder`.
    let transcript: String

    /// Which copy of the app wrote this, and which machine it ran on.
    /// Filled from `ProblemReportEnvironment` in the app and passed as
    /// plain text so a test can render a record without a bundle.
    let appDescription: String
    let systemDescription: String

    /// The longest transcript kept in one record. A record is read from the
    /// END — that is where a failure is — so trimming takes from the front.
    static let mostTranscriptCharacters: Int = 250_000

    /// What stands in for the part that was not kept.
    static let trimmedMarker: String = "[earlier output not kept]"

    // MARK: - Computed properties

    /// How long the task took.
    var duration: TimeInterval {
        return finishedAt.timeIntervalSince(startedAt)
    }

    /// The launcher and its arguments as one line.
    var taskDescription: String {
        var parts: [String] = [scriptName]
        for argument in arguments {
            parts.append(argument)
        }
        return parts.joined(separator: " ")
    }

    // MARK: - Functions

    /// The file this record is written to. Named so that sorting the folder
    /// by name is sorting it by time, which is what makes keeping "the
    /// newest twenty" a matter of dropping from one end of a sorted list.
    func fileName(timeZone: TimeZone = TimeZone.current) -> String {
        let stamp: String = RunRecord.stampFormatter(timeZone: timeZone).string(from: startedAt)
        var task: String = scriptName
        if let dot = task.firstIndex(of: ".") {
            task = String(task[task.startIndex..<dot])
        }
        return stamp + "-" + task + ".txt"
    }

    /// The record as it is written — redacted, in full, once.
    ///
    /// Redaction is applied HERE, to the finished text, rather than to each
    /// field on the way in: one call over one string is one place to be
    /// wrong, and a field added later is covered by it without anyone
    /// having to remember.
    func text(timeZone: TimeZone = TimeZone.current) -> String {
        var lines: [String] = []
        lines.append("Plantoir problem report")
        lines.append("=======================")
        lines.append(labelled("When", RunRecord.readableFormatter(timeZone: timeZone).string(from: startedAt)))
        lines.append(labelled("App", appDescription))
        lines.append(labelled("System", systemDescription))
        lines.append(labelled("Task", taskDescription))
        lines.append(labelled("Folder", workingFolderPath))
        lines.append(labelled("Outcome", outcome + " after " + String(format: "%.1f", duration) + "s"))
        // Only a failure gets this line. A task that was stopped on purpose
        // has nothing to explain, and telling somebody that nothing was
        // recognised about it reads as a fault where there was none.
        if wasFailure {
            lines.append(labelled("Explained", explanation ?? "nothing recognised — worth a look"))
        }
        lines.append("")
        lines.append("----- what the task printed -----")
        lines.append(trimmedTranscript)
        return LogRedactor.redacting(lines.joined(separator: "\n"))
    }

    /// The transcript, shortened from the front if it is very long.
    var trimmedTranscript: String {
        if transcript.count <= RunRecord.mostTranscriptCharacters {
            return transcript
        }
        let keptFrom: String.Index = transcript.index(
            transcript.endIndex, offsetBy: -RunRecord.mostTranscriptCharacters
        )
        return RunRecord.trimmedMarker + "\n" + String(transcript[keptFrom..<transcript.endIndex])
    }

    /// One header line, with the labels lined up.
    func labelled(_ label: String, _ value: String) -> String {
        var padded: String = label
        while padded.count < 10 {
            padded += " "
        }
        return padded + value
    }

    /// Sortable and filename-safe: 2026-08-16-143022.
    static func stampFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter
    }

    /// Readable, and carrying the offset — a report sent across a time zone
    /// is otherwise an hour's confusion.
    static func readableFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
        return formatter
    }
}

/// Which copy of the app is running, and on what.
///
/// The bundle path and the process id are here for a reason that is not
/// obvious: two copies of Plantoir can be running at once (Xcode's Run does
/// not stop a copy it did not start), and when they are, they take turns
/// rewriting the same working folder. Two process ids in one folder of
/// records is the fastest way that has ever been available to see it.
nonisolated enum ProblemReportEnvironment {

    // MARK: - Computed properties

    /// "Plantoir 1.0 (12) · pid 4711 · /Applications/Plantoir.app"
    static var appDescription: String {
        let shortVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let buildNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let processIdentifier: Int32 = ProcessInfo.processInfo.processIdentifier
        return "Plantoir \(shortVersion) (\(buildNumber)) · pid \(processIdentifier) · \(Bundle.main.bundlePath)"
    }

    /// "macOS 15.6 · arm64 · 8 cores · 36 GB"
    static var systemDescription: String {
        let information: ProcessInfo = ProcessInfo.processInfo
        let version: OperatingSystemVersion = information.operatingSystemVersion
        let memoryInGigabytes: Int = Int(information.physicalMemory / 1_073_741_824)
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            + " · \(machineArchitecture)"
            + " · \(information.processorCount) cores"
            + " · \(memoryInGigabytes) GB"
    }

    /// arm64 or x86_64 — which matters here, because the assistant runs
    /// natively on one and the whole toolchain emulates on the other.
    static var machineArchitecture: String {
        var information: utsname = utsname()
        if uname(&information) != 0 {
            return "unknown"
        }
        var bytes: [CChar] = []
        withUnsafeBytes(of: &information.machine) { raw in
            for byte in raw {
                bytes.append(CChar(bitPattern: byte))
            }
        }
        return String(cString: bytes)
    }
}

/// Where records are kept, and how many.
///
/// `~/Library/Logs/Plantoir` — the folder macOS keeps application logs in,
/// which means Console.app lists it under Log Reports and a teacher who
/// goes looking finds it where they would expect to. Plain text, never a
/// bundle format: a file a teacher cannot open is a file they cannot decide
/// whether to send.
nonisolated struct ProblemReportStore {

    // MARK: - Stored properties

    /// The folder these records live in.
    let folderURL: URL

    /// Records older than the newest this many are deleted as each new one
    /// is written. Twenty covers a working session with room to spare; a
    /// teacher reporting something from last week is being asked about
    /// something they have since done twenty more tasks after.
    static let mostRetainedRuns: Int = 20

    /// The breadcrumb trail: one line per notable thing the teacher did, in
    /// the order it happened.
    ///
    /// ONE file rather than one per subject, because the question a report is
    /// read to answer is "what was going on when it broke", and that is a
    /// sequence. Two files, each half a story, forces whoever reads them to
    /// interleave by timestamp in their head.
    static let activityFileName: String = "activity.txt"
    static let mostActivityLines: Int = 1200
    static let keptActivityLines: Int = 600

    /// The folder for the running app.
    ///
    /// Under a test run this is a throwaway folder instead. The tests build
    /// real `ScriptRunner`s and real agents, and those write a record when
    /// they finish — which without this lands in the folder a REAL problem
    /// report is later gathered from, so a report would carry a handful of
    /// invented tasks alongside the teacher's own. Tests that care about the
    /// store pass their own folder in; this is only about the ones that do
    /// not know they have one.
    static var standard: ProblemReportStore {
        if ProblemReportStore.isRunningTests {
            return ProblemReportStore(folderURL: ProblemReportStore.throwawayFolderURL)
        }
        return ProblemReportStore(folderURL: ProblemReportStore.defaultFolderURL())
    }

    /// True while XCTest is hosting the app.
    static var isRunningTests: Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// One folder per test RUN rather than per call, so that a test which
    /// writes and then reads back still finds what it wrote.
    static let throwawayFolderURL: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("Plantoir-tests-" + UUID().uuidString, isDirectory: true)

    // MARK: - Computed properties

    /// Where the per-task records sit.
    var runsFolderURL: URL {
        return folderURL.appendingPathComponent("runs", isDirectory: true)
    }

    // MARK: - Functions

    /// `~/Library/Logs/Plantoir`.
    static func defaultFolderURL() -> URL {
        let library: URL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        return library.appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("Plantoir", isDirectory: true)
    }

    /// Writes one record and drops the oldest beyond the limit.
    ///
    /// Never throws to its caller: a task that has just finished must not
    /// be reported as having failed because a log could not be written.
    @discardableResult
    func write(_ record: RunRecord, timeZone: TimeZone = TimeZone.current) -> URL? {
        do {
            try FileManager.default.createDirectory(
                at: runsFolderURL, withIntermediateDirectories: true
            )
            let url: URL = runsFolderURL.appendingPathComponent(record.fileName(timeZone: timeZone))
            try record.text(timeZone: timeZone).write(to: url, atomically: true, encoding: .utf8)
            pruneRuns()
            return url
        } catch {
            return nil
        }
    }

    /// Every kept record, newest first.
    func runFileURLs() -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: runsFolderURL, includingPropertiesForKeys: nil
        ) else {
            return []
        }
        var records: [URL] = []
        for url in contents {
            if url.pathExtension == "txt" {
                records.append(url)
            }
        }
        // The names begin with a sortable timestamp, so sorting by name is
        // sorting by time — no file dates involved, and therefore nothing
        // that a copy or a restore from a backup could disturb.
        records.sort { first, second in
            return first.lastPathComponent > second.lastPathComponent
        }
        return records
    }

    /// Keeps the newest records and deletes the rest.
    func pruneRuns() {
        let records: [URL] = runFileURLs()
        if records.count <= ProblemReportStore.mostRetainedRuns {
            return
        }
        var index: Int = ProblemReportStore.mostRetainedRuns
        while index < records.count {
            try? FileManager.default.removeItem(at: records[index])
            index += 1
        }
    }

    /// Adds one line to the trail.
    ///
    /// Everything notable goes here — folders opened, sections chosen, tasks
    /// started and finished, the assistant answering — because the trail is
    /// what turns a pile of records into an account of what somebody was
    /// doing. The task records hold the DETAIL; this holds the order.
    func appendActivityLine(_ line: String) {
        let safeLine: String = LogRedactor.redacting(line)
        do {
            try FileManager.default.createDirectory(
                at: folderURL, withIntermediateDirectories: true
            )
        } catch {
            return
        }
        let url: URL = folderURL.appendingPathComponent(ProblemReportStore.activityFileName)
        var existing: String = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        existing += safeLine + "\n"
        try? ProblemReportStore.trimmed(existing).write(to: url, atomically: true, encoding: .utf8)
    }

    /// Whether there is anything worth gathering.
    ///
    /// Asked BEFORE the teacher is asked anything, so that somebody who has
    /// just installed the app is told there is nothing to send rather than
    /// being walked through a choice and a save panel first and told
    /// afterwards.
    var hasAnythingToReport: Bool {
        if !runFileURLs().isEmpty {
            return true
        }
        return !activityText(includingPrompts: true).isEmpty
    }

    /// Whether the teacher has actually typed anything to the local AI
    /// assistant.
    ///
    /// The question the CHECKBOX asks is only meaningful if there is
    /// something to answer it about. Opening the assistant and closing it
    /// again leaves turns on the trail but no prompts, so this looks for the
    /// prompt lines themselves rather than for assistant events — the
    /// narrower test, and the one that matches what the box controls.
    var hasAssistantPrompts: Bool {
        for line in activityText(includingPrompts: true).components(separatedBy: "\n") {
            if line.hasPrefix(AssistTurnRecord.promptMarker) {
                return true
            }
        }
        return false
    }

    /// The trail as it should go into a report.
    ///
    /// The teacher's own sentences are the one thing here that is
    /// unmistakably theirs, so they are kept locally and left out unless the
    /// teacher ticks the box. Everything else — which tool was chosen, with
    /// which arguments filled in, how long it took — goes either way, and
    /// that is most of what a routing problem is diagnosed from.
    func activityText(includingPrompts: Bool) -> String {
        let url: URL = folderURL.appendingPathComponent(ProblemReportStore.activityFileName)
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        if includingPrompts {
            return text
        }
        var kept: [String] = []
        var droppedAny: Bool = false
        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix(AssistTurnRecord.promptMarker) {
                droppedAny = true
                continue
            }
            kept.append(line)
        }
        if droppedAny {
            kept.insert("(What the teacher typed was left out of this report.)", at: 0)
        }
        return kept.joined(separator: "\n")
    }

    /// Drops the oldest lines once the file has grown past its limit.
    ///
    /// Trimming to HALF rather than to the limit on purpose: trimming to
    /// the limit would rewrite the whole file on every single line once it
    /// filled up, which for a file this size is work nobody asked for.
    static func trimmed(_ text: String) -> String {
        var lines: [String] = text.components(separatedBy: "\n")
        if lines.count <= mostActivityLines {
            return text
        }
        lines.removeFirst(lines.count - keptActivityLines)
        return lines.joined(separator: "\n")
    }
}
