import Foundation

/// Gathers the kept records into one file a teacher can look at and send.
///
/// A folder of plain text, zipped. Not an archive format of our own and not
/// a binary blob: a teacher who cannot open the thing cannot decide whether
/// to send it, and "trust me, there is nothing private in here" is a promise
/// where a readable file is a fact.
nonisolated struct ProblemReportBuilder {

    // MARK: - Types

    /// What the report has to say about the teacher's own sentences.
    ///
    /// Three states rather than a flag, because "left out" and "there were
    /// none" are different things to be told. A teacher who has never opened
    /// the assistant should not read a line promising that what they typed to
    /// it was excluded — it invites them to wonder what else the app thinks
    /// they did.
    enum AssistantPrompts {
        case none
        case excluded
        case included
    }

    // MARK: - Stored properties

    let store: ProblemReportStore

    /// The folder name inside the zip, and the first thing a teacher sees
    /// when they open it.
    static let folderName: String = "Plantoir problem report"

    /// What the report says about itself.
    static let aboutFileName: String = "what is in this report.txt"

    /// The breadcrumb trail — the file to read first.
    static let trailFileName: String = "what you were doing.txt"

    /// Where a teacher sends the report.
    ///
    /// One place, so the dialog and the note inside the report cannot come to
    /// disagree — and so the Windows app can take the address from here
    /// rather than from a screenshot of this dialog.
    static let supportEmail: String = "support@plantoir.app"

    /// What the teacher's mail app opens with. The subject is filled in
    /// because a report titled "Help" is a report that has to be asked about
    /// before it can be read.
    static var supportMailURL: URL? {
        return URL(string: "mailto:" + supportEmail + "?subject=Plantoir%20problem%20report")
    }

    // MARK: - Functions

    /// Builds the report folder in a working place and returns it.
    ///
    /// Returns nil when there is nothing to report yet — which is a real
    /// answer, not a failure: a teacher who has done nothing has nothing to
    /// send, and telling them so beats handing them an empty file.
    func assembleFolder(
        includingAssistantPrompts: Bool,
        in parentURL: URL,
        now: Date = Date(),
        timeZone: TimeZone = TimeZone.current
    ) -> URL? {
        let records: [URL] = store.runFileURLs()
        let trail: String = store.activityText(includingPrompts: includingAssistantPrompts)
        if records.isEmpty && trail.isEmpty {
            return nil
        }

        let folderURL: URL = parentURL.appendingPathComponent(
            ProblemReportBuilder.stampedFolderName(at: now, timeZone: timeZone), isDirectory: true
        )
        try? FileManager.default.removeItem(at: folderURL)
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            try about(
                recordCount: records.count,
                assistantPrompts: ProblemReportBuilder.promptState(
                    hasAny: store.hasAssistantPrompts, including: includingAssistantPrompts
                ),
                now: now,
                timeZone: timeZone
            ).write(
                to: folderURL.appendingPathComponent(ProblemReportBuilder.aboutFileName),
                atomically: true,
                encoding: .utf8
            )
            if !trail.isEmpty {
                // Named first among the files on purpose: it is the one to
                // read first, and the task records are the detail behind it.
                try trail.write(
                    to: folderURL.appendingPathComponent(ProblemReportBuilder.trailFileName),
                    atomically: true,
                    encoding: .utf8
                )
            }
            let tasksURL: URL = folderURL.appendingPathComponent("tasks", isDirectory: true)
            try FileManager.default.createDirectory(at: tasksURL, withIntermediateDirectories: true)
            for record in records {
                try FileManager.default.copyItem(
                    at: record, to: tasksURL.appendingPathComponent(record.lastPathComponent)
                )
            }
        } catch {
            return nil
        }
        return folderURL
    }

    /// The note that opens the report, written to be read by the teacher who
    /// is about to send it rather than by whoever receives it.
    /// Which of the three things the note has to say.
    static func promptState(hasAny: Bool, including: Bool) -> AssistantPrompts {
        if !hasAny {
            return .none
        }
        return including ? .included : .excluded
    }

    func about(
        recordCount: Int,
        assistantPrompts: AssistantPrompts,
        now: Date,
        timeZone: TimeZone
    ) -> String {
        var lines: [String] = []
        lines.append("What is in this report")
        lines.append("======================")
        lines.append("")
        lines.append("Made on " + RunRecord.readableFormatter(timeZone: timeZone).string(from: now) + ".")
        lines.append("")
        lines.append("Everything here is plain text. Open any of it and read it before you")
        lines.append("send it — that is what it is for.")
        lines.append("")
        lines.append("When you are ready, email this file to " + ProblemReportBuilder.supportEmail + ".")
        lines.append("")
        lines.append("IN THIS REPORT")
        lines.append("  · a list of what you did in Plantoir, in order, with the time of each")
        lines.append("  · " + ProblemReportBuilder.taskCountPhrase(recordCount) + ", and everything")
        lines.append("    each one showed on screen while it worked")
        lines.append("  · your course codes, section numbers and where your course folders sit")
        lines.append("  · the NAMES of your pages — your website builder lists each one as it")
        lines.append("    works, so they appear in what it printed")
        lines.append("  · which version of Plantoir you are using, and what kind of Mac this is")
        if assistantPrompts == .included {
            lines.append("  · what you typed to the local AI assistant, because you asked for it")
            lines.append("    to be included")
        }
        lines.append("")
        lines.append("NOT IN THIS REPORT")
        lines.append("  · what you have WRITTEN on your pages — only their names appear")
        lines.append("  · your sign-in details for Netlify or Cloudflare")
        lines.append("  · your name, your email address, or your account name on this Mac")
        if assistantPrompts == .excluded {
            lines.append("  · what you typed to the local AI assistant")
        }
        lines.append("")
        lines.append("Where something was taken out, it says so in square brackets, like this:")
        lines.append("  " + LogRedactor.removedToken)
        return lines.joined(separator: "\n") + "\n"
    }

    /// "the last task Plantoir ran for you" — or "the last 6 tasks".
    ///
    /// Worth the four lines: "the last 1 task(s)" is the kind of sentence
    /// that tells a teacher this was written for somebody else.
    static func taskCountPhrase(_ count: Int) -> String {
        if count == 1 {
            return "the last task Plantoir ran for you"
        }
        return "the last \(count) tasks Plantoir ran for you"
    }

    /// When the report was made, for its name.
    ///
    /// To the SECOND, not the day: somebody chasing a problem sends two or
    /// three reports in an afternoon — before a change and after it — and a
    /// date alone makes them a pile of files that have to be opened to be
    /// told apart, or worse, silently overwrite each other.
    ///
    /// Dots rather than colons in the time, because a colon is not legal in a
    /// file name and the Finder shows it as a slash. This is the shape macOS
    /// gives its own screenshots, so it is already familiar to read.
    static func stamp(_ now: Date, timeZone: TimeZone = TimeZone.current) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return formatter.string(from: now)
    }

    /// The folder INSIDE the zip carries the same stamp as the zip.
    ///
    /// Otherwise two reports unzipped side by side both land in a folder
    /// called "Plantoir problem report", and the second either overwrites the
    /// first or gets a "2" bolted on by the Finder — which is exactly the
    /// muddle the stamp exists to prevent, one layer down and at the worst
    /// possible moment, on the machine of whoever is trying to help.
    static func stampedFolderName(at now: Date, timeZone: TimeZone = TimeZone.current) -> String {
        return ProblemReportBuilder.folderName + " " + ProblemReportBuilder.stamp(now, timeZone: timeZone)
    }

    /// The name to offer when saving.
    static func suggestedFileName(now: Date, timeZone: TimeZone = TimeZone.current) -> String {
        return ProblemReportBuilder.stampedFolderName(at: now, timeZone: timeZone) + ".zip"
    }
}
