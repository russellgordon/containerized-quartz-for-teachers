import Foundation

/// "Deploy tomorrow's class at 6:30 AM."
///
/// A launchd user agent runs `deploy.sh <CODE> <N>` at a set time with
/// nothing of ours running — that is the whole point, so the plist must be
/// self-sufficient: the working folder, the arguments, and the PATH the
/// launcher needs are all written into it. Plantoir can be closed, and
/// usually is at half six in the morning.
///
/// The decision of WHETHER to schedule, and every word the teacher reads,
/// lives here in the app. The launchd layer below only runs the thing.
///
/// **No wake timer, deliberately.** `pmset schedule` needs administrator
/// rights and depends on the hardware and the power settings, and when it
/// fails it fails SILENTLY. Rather than promise a wake-up that may not
/// happen, the plan states the conditions and says what launchd really
/// does with a job whose time passed while the Mac was asleep: it runs it
/// at the next wake, which could be well after the class it was for.
enum ScheduledDeploy {

    // MARK: - Stored properties

    /// The prefix every one of our agents' labels carries, so an agent of
    /// ours is never mistaken for anything else in the teacher's
    /// `LaunchAgents` folder.
    static let labelPrefix: String = "ca.russellgordon.Plantoir.deploy"

    /// The environment key carrying the moment the agent was set for.
    ///
    /// `StartCalendarInterval` has no year — it repeats annually — so the
    /// plist alone cannot say which day it meant. launchd passes
    /// `EnvironmentVariables` through untouched, so the full moment rides
    /// there: it is what the sidebar reads back, and it also lands in the
    /// agent's own log.
    static let scheduledForKey: String = "PLANTOIR_SCHEDULED_FOR"

    // MARK: - Functions

    /// This section's agent label — the course code AND the section number,
    /// so two sections of one course can never collide, nor two courses.
    static func agentLabel(courseCode: String, sectionNumber: Int) -> String {
        let code: String = sanitizedCode(courseCode)
        return "\(labelPrefix).\(code).section\(sectionNumber)"
    }

    /// A course code reduced to what a launchd label may carry. Codes are
    /// already letters and digits, so in practice this changes nothing —
    /// it is here so that a club named with a space cannot produce a label
    /// launchd refuses.
    static func sanitizedCode(_ courseCode: String) -> String {
        var result: String = ""
        for character in courseCode.uppercased() {
            if character.isLetter || character.isNumber {
                result.append(character)
            } else {
                result.append("-")
            }
        }
        return result.isEmpty ? "COURSE" : result
    }

    /// Where this section's agent is written. `~/Library/LaunchAgents` is
    /// the teacher's own folder — no administrator rights, and nothing of
    /// ours outside it.
    static func plistURL(courseCode: String, sectionNumber: Int) -> URL {
        let label: String = agentLabel(courseCode: courseCode, sectionNumber: sectionNumber)
        return launchAgentsDirectoryURL().appendingPathComponent("\(label).plist")
    }

    /// A folder to write agents into instead of the teacher's own.
    ///
    /// Set only by tests. A test that wrote into the real `LaunchAgents`
    /// folder would leave a deploy scheduled on the machine running the
    /// suite — which is exactly the kind of surprise this feature exists
    /// to make deliberate.
    static var launchAgentsDirectoryOverride: URL?

    static func launchAgentsDirectoryURL() -> URL {
        if let launchAgentsDirectoryOverride {
            return launchAgentsDirectoryOverride
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("LaunchAgents")
    }

    /// Where the agent's own output goes. A deploy that ran at half six
    /// with nobody watching has to have left something behind, or a
    /// failure is invisible until a student says the site is stale.
    static func logURL(courseCode: String, sectionNumber: Int) -> URL {
        let label: String = agentLabel(courseCode: courseCode, sectionNumber: sectionNumber)
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("Plantoir")
            .appendingPathComponent("\(label).log")
    }

    // MARK: - Planning

    /// Why this deploy cannot be scheduled, or nil when it can be.
    ///
    /// Everything refused here is something that would ASK A QUESTION at
    /// the scheduled moment. Attended, those questions get answered;
    /// scheduled, they wait at half six with nobody there, and the class
    /// site is not updated. So the questions are put now instead.
    static func problem(
        course: Course,
        sectionNumber: Int,
        when: Date,
        now: Date,
        cloudflareAccountID: String,
        locale: Locale = Locale.current
    ) -> String? {
        if when <= now {
            return "\(dayAndTimeText(when, locale: locale)) has already passed. Pick a time still to come."
        }

        let configuration: CourseConfiguration = course.configuration

        if configuration.deployTarget == "local_folder" {
            if let folderProblem = CourseConfiguration.deployFolderProblem(forPath: configuration.deployFolderPath) {
                return "\(course.code) deploys to a folder, and that folder needs attention first: \(folderProblem)"
            }
        }

        // Cloudflare needs an Account ID that only the app has. Unlike the
        // Windows app — where the scheduled task cannot be handed one —
        // the plist carries `--account`, so the question is asked HERE and
        // answered once rather than making Cloudflare unschedulable.
        if configuration.deploysToCloudflare {
            if let accountProblem = CourseConfiguration.cloudflareAccountProblem(forID: cloudflareAccountID) {
                return "\(course.code) deploys to Cloudflare Pages, which needs your Account ID. \(accountProblem) Add it in this course’s settings, under Deploying, then schedule this again."
            }
        }

        if !DeployCommand.hasDeployedBefore(section: sectionNumber, in: course) {
            return "\(course.code) Section \(sectionNumber) has never been deployed, so deploying it asks what to call the website. Nobody would be there to answer that at the scheduled time, and it would wait. Deploy it once from Plantoir, and after that it can be scheduled."
        }

        return nil
    }

    /// Describes what scheduling would do, changing nothing.
    ///
    /// The words are meant to be read aloud, so they say what has to be
    /// true of the Mac and what happens when it isn't.
    static func plan(
        course: Course,
        sectionNumber: Int,
        when: Date,
        now: Date,
        cloudflareAccountID: String,
        locale: Locale = Locale.current
    ) -> ScheduledDeployPlan {
        return ScheduledDeployPlan(
            courseCode: course.code,
            sectionNumber: sectionNumber,
            when: when,
            destination: DeployCommand.destinationDescription(for: course.configuration),
            unpublishedClasses: unpublishedClasses(course: course, sectionNumber: sectionNumber),
            problem: problem(
                course: course,
                sectionNumber: sectionNumber,
                when: when,
                now: now,
                cloudflareAccountID: cloudflareAccountID,
                locale: locale
            ),
            locale: locale
        )
    }

    /// The section's class pages students cannot see yet, by name.
    ///
    /// Not a refusal — a teacher may well be deploying deliberately
    /// without them — but worth saying before a site goes out on its own.
    static func unpublishedClasses(course: Course, sectionNumber: Int) -> [String] {
        var held: [String] = []
        for page in ClassPages.list(forSection: sectionNumber, in: course) {
            guard let text = try? String(contentsOf: page.fileURL, encoding: .utf8) else {
                continue
            }
            let isVisible: Bool = AssistPageVisibility.publishes(
                in: text,
                forSection: sectionNumber,
                isSectionLocal: true
            )
            if !isVisible {
                held.append(page.title)
            }
        }
        return held
    }

    // MARK: - The launchd agent

    /// The agent, as a property list.
    ///
    /// Built separately from anything that writes or loads it, so the
    /// exact plist a teacher would get can be inspected in a test without
    /// touching the real launchd.
    static func propertyList(
        courseCode: String,
        sectionNumber: Int,
        when: Date,
        workspaceURL: URL,
        deployArguments: [String],
        calendar: Calendar = Calendar.current
    ) -> [String: Any] {
        let label: String = agentLabel(courseCode: courseCode, sectionNumber: sectionNumber)
        let components: DateComponents = calendar.dateComponents([.month, .day, .hour, .minute], from: when)

        var schedule: [String: Any] = [:]
        schedule["Month"] = components.month ?? 1
        schedule["Day"] = components.day ?? 1
        schedule["Hour"] = components.hour ?? 0
        schedule["Minute"] = components.minute ?? 0

        var environment: [String: String] = [:]
        // A launchd agent starts with a bare PATH; the launcher needs to
        // find docker and colima the way a Terminal session does. Same
        // list ScriptRunner prepends when the app runs a script itself.
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        environment[scheduledForKey] = ISO8601DateFormatter().string(from: when)

        var plist: [String: Any] = [:]
        plist["Label"] = label
        plist["ProgramArguments"] = [
            "/bin/bash",
            "-c",
            oneShotCommand(
                courseCode: courseCode,
                sectionNumber: sectionNumber,
                workspaceURL: workspaceURL,
                deployArguments: deployArguments
            ),
        ]
        plist["StartCalendarInterval"] = schedule
        plist["WorkingDirectory"] = workspaceURL.path
        plist["EnvironmentVariables"] = environment
        plist["StandardOutPath"] = logURL(courseCode: courseCode, sectionNumber: sectionNumber).path
        plist["StandardErrorPath"] = logURL(courseCode: courseCode, sectionNumber: sectionNumber).path
        // Loading the agent must not deploy on the spot: the teacher's
        // "Go ahead" set an alarm, it did not consent to a deploy now.
        plist["RunAtLoad"] = false
        return plist
    }

    /// What the agent actually runs: the deploy, once, and then itself out
    /// of existence.
    ///
    /// `StartCalendarInterval` has no "just this once" — a month and day
    /// come round again every year — so a fired agent that did not clear
    /// itself away would sit in launchd for twelve months and then deploy
    /// a course that may not exist any more. The plist is removed FIRST,
    /// so even a Mac that restarts mid-deploy comes back with nothing
    /// pending, and the job boots itself out LAST, once the deploy is done.
    static func oneShotCommand(
        courseCode: String,
        sectionNumber: Int,
        workspaceURL: URL,
        deployArguments: [String]
    ) -> String {
        let label: String = agentLabel(courseCode: courseCode, sectionNumber: sectionNumber)
        let plistPath: String = plistURL(courseCode: courseCode, sectionNumber: sectionNumber).path
        let scriptPath: String = workspaceURL.appendingPathComponent(DeployCommand.scriptName).path
        let logDirectory: String = logURL(courseCode: courseCode, sectionNumber: sectionNumber)
            .deletingLastPathComponent().path

        var deployLine: String = "/bin/bash \(shellQuoted(scriptPath))"
        for argument in deployArguments {
            deployLine += " \(shellQuoted(argument))"
        }

        var lines: [String] = []
        lines.append("/bin/mkdir -p \(shellQuoted(logDirectory))")
        lines.append("/bin/rm -f \(shellQuoted(plistPath))")
        lines.append(deployLine)
        lines.append("/bin/launchctl bootout gui/$(/usr/bin/id -u)/\(shellQuoted(label))")
        return lines.joined(separator: "\n")
    }

    /// One argument, safe to paste into a shell command.
    static func shellQuoted(_ value: String) -> String {
        let escaped: String = value.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    // MARK: - Applying

    /// Sets the alarm. Returns nil on success, or what went wrong in words
    /// the teacher can act on.
    ///
    /// Scheduling the same section twice replaces rather than stacks: the
    /// label is fixed per section, and the previous agent is booted out
    /// before the new one is written.
    @discardableResult
    static func scheduleDeploy(
        course: Course,
        sectionNumber: Int,
        when: Date,
        workspaceURL: URL,
        cloudflareAccountID: String,
        runner: LaunchControlRunning = LaunchControl()
    ) -> String? {
        let scriptURL: URL = workspaceURL.appendingPathComponent(DeployCommand.scriptName)
        if !FileManager.default.fileExists(atPath: scriptURL.path) {
            return "This working folder is missing a piece it needs (\(DeployCommand.scriptName)), so there is nothing to schedule."
        }

        let deployArguments: [String] = DeployCommand.arguments(
            courseCode: course.code,
            sectionNumber: sectionNumber,
            configuration: course.configuration,
            cloudflareAccountID: cloudflareAccountID
        )
        let plist: [String: Any] = propertyList(
            courseCode: course.code,
            sectionNumber: sectionNumber,
            when: when,
            workspaceURL: workspaceURL,
            deployArguments: deployArguments
        )
        let destinationURL: URL = plistURL(courseCode: course.code, sectionNumber: sectionNumber)

        // Anything already scheduled for this section goes first, so the
        // replacement is never briefly a second agent.
        runner.bootOut(label: agentLabel(courseCode: course.code, sectionNumber: sectionNumber))

        do {
            try FileManager.default.createDirectory(
                at: launchAgentsDirectoryURL(),
                withIntermediateDirectories: true
            )
            let data: Data = try PropertyListSerialization.data(
                fromPropertyList: plist,
                format: .xml,
                options: 0
            )
            try data.write(to: destinationURL, options: [.atomic])
        } catch {
            return "The scheduled deploy could not be written: \(error.localizedDescription)"
        }

        if let failure = runner.bootstrap(plistURL: destinationURL) {
            try? FileManager.default.removeItem(at: destinationURL)
            return "macOS would not accept the scheduled deploy: \(failure)"
        }
        return nil
    }

    /// Takes the alarm off. Returns nil on success.
    @discardableResult
    static func cancelScheduledDeploy(
        courseCode: String,
        sectionNumber: Int,
        runner: LaunchControlRunning = LaunchControl()
    ) -> String? {
        let destinationURL: URL = plistURL(courseCode: courseCode, sectionNumber: sectionNumber)
        runner.bootOut(label: agentLabel(courseCode: courseCode, sectionNumber: sectionNumber))
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try FileManager.default.removeItem(at: destinationURL)
            } catch {
                return "The scheduled deploy could not be removed: \(error.localizedDescription)"
            }
        }
        return nil
    }

    /// When this section is next set to deploy on its own, or nil when
    /// nothing is scheduled.
    ///
    /// Read back from the agent itself rather than from a note of our own.
    /// The teacher can delete the agent from `~/Library/LaunchAgents`
    /// without telling us, and a badge promising a deploy that will never
    /// happen is worse than no badge at all.
    static func nextRun(courseCode: String, sectionNumber: Int, now: Date = Date()) -> Date? {
        let destinationURL: URL = plistURL(courseCode: courseCode, sectionNumber: sectionNumber)
        guard let data = try? Data(contentsOf: destinationURL) else {
            return nil
        }
        guard let decoded = try? PropertyListSerialization.propertyList(from: data, format: nil) else {
            return nil
        }
        guard let plist = decoded as? [String: Any] else {
            return nil
        }
        guard let environment = plist["EnvironmentVariables"] as? [String: String] else {
            return nil
        }
        guard let stamp = environment[scheduledForKey] else {
            return nil
        }
        guard let moment = ISO8601DateFormatter().date(from: stamp) else {
            return nil
        }
        // An agent whose moment has passed has either just fired and is
        // clearing itself away, or was left behind by a Mac that was off.
        // Either way it is not a promise worth showing.
        if moment <= now {
            return nil
        }
        return moment
    }

    // MARK: - Wording

    /// "Tuesday 12 August, 6:30 AM" — the whole moment.
    static func dayAndTimeText(_ date: Date, locale: Locale = Locale.current) -> String {
        return "\(dayText(date, locale: locale)), \(timeText(date, locale: locale))"
    }

    /// "Tuesday 12 August".
    static func dayText(_ date: Date, locale: Locale = Locale.current) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: date)
    }

    /// "6:30 AM", in whatever way this Mac writes times.
    static func timeText(_ date: Date, locale: Locale = Locale.current) -> String {
        let formatter: DateFormatter = DateFormatter()
        formatter.locale = locale
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

/// A deploy that has not been scheduled yet, described in full.
///
/// The plan half of the plan/apply pair: making one changes nothing at all,
/// which is what lets the app — or the assistant — read it out and wait for
/// a yes before anything is set.
struct ScheduledDeployPlan {

    // MARK: - Stored properties

    let courseCode: String
    let sectionNumber: Int
    let when: Date

    /// Where the site would go: "Netlify", "Cloudflare Pages", or a folder.
    let destination: String

    /// Class pages students cannot see yet, by name.
    let unpublishedClasses: [String]

    /// Why this cannot be scheduled, or nil when it can be.
    let problem: String?

    let locale: Locale

    // MARK: - Computed properties

    /// True when scheduling this would work.
    var isSchedulable: Bool {
        return problem == nil
    }

    /// The whole plan, in words meant to be read aloud.
    var description: String {
        if let problem {
            return problem
        }

        var lines: [String] = []
        lines.append("Deploy \(courseCode) Section \(sectionNumber) to \(destination) at \(ScheduledDeploy.dayAndTimeText(when, locale: locale)).")
        lines.append("")
        lines.append("For this to happen, at that moment this Mac must be:")
        lines.append("  • switched on, and awake — not asleep or shut down")
        lines.append("  • plugged in, if it is a laptop")
        lines.append("  • with the lid open, if closing it puts it to sleep")
        lines.append("")
        lines.append("Plantoir does not wake this Mac up. If it is asleep or switched off at that time, macOS runs the deploy at the next wake instead — which could be well after the class it was meant for.")

        if !unpublishedClasses.isEmpty {
            lines.append("")
            let count: Int = unpublishedClasses.count
            let isSingle: Bool = count == 1
            lines.append("One thing first — \(count) class\(isSingle ? " is" : "es are") not published yet:")
            var shown: Int = 0
            for title in unpublishedClasses {
                if shown >= 8 {
                    break
                }
                lines.append("  \(title)")
                shown += 1
            }
            if count > 8 {
                lines.append("  …and \(count - 8) more.")
            }
            lines.append("Deploying now would put the site up without \(isSingle ? "it" : "them"). Publish first, look the preview over, then schedule this.")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Initializer

    init(
        courseCode: String,
        sectionNumber: Int,
        when: Date,
        destination: String,
        unpublishedClasses: [String],
        problem: String?,
        locale: Locale = Locale.current
    ) {
        self.courseCode = courseCode
        self.sectionNumber = sectionNumber
        self.when = when
        self.destination = destination
        self.unpublishedClasses = unpublishedClasses
        self.problem = problem
        self.locale = locale
    }
}

/// The two `launchctl` calls a scheduled deploy needs.
///
/// Behind a protocol so a test can watch what would be asked of launchd
/// without asking it — a test that really bootstrapped an agent would leave
/// one in the person running the suite.
protocol LaunchControlRunning {

    // MARK: - Functions

    /// Loads an agent into the logged-in user's own launchd domain.
    /// Returns nil on success, or what launchctl said.
    func bootstrap(plistURL: URL) -> String?

    /// Removes an agent from that domain. Silent about an agent that was
    /// not there — cancelling something already gone is not a failure.
    func bootOut(label: String)
}

/// The real `launchctl`.
///
/// `bootstrap` and `bootout` rather than the deprecated `load`/`unload`:
/// the modern pair names the domain explicitly (`gui/<uid>`, the logged-in
/// user's session), reports real errors, and is what launchd's own
/// documentation has told people to use for years.
struct LaunchControl: LaunchControlRunning {

    // MARK: - Computed properties

    /// The logged-in user's GUI domain, e.g. "gui/501".
    var domainTarget: String {
        return "gui/\(getuid())"
    }

    // MARK: - Functions

    func bootstrap(plistURL: URL) -> String? {
        let result = LaunchControl.run(arguments: ["bootstrap", domainTarget, plistURL.path])
        if result.exitCode == 0 {
            return nil
        }
        let message: String = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        return message.isEmpty ? "launchctl exited with code \(result.exitCode)." : message
    }

    func bootOut(label: String) {
        _ = LaunchControl.run(arguments: ["bootout", "\(domainTarget)/\(label)"])
    }

    /// Runs launchctl and collects what it said.
    static func run(arguments: [String]) -> (exitCode: Int32, output: String) {
        let process: Process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        let pipe: Pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            return (exitCode: -1, output: error.localizedDescription)
        }
        let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (exitCode: process.terminationStatus, output: String(decoding: data, as: UTF8.self))
    }
}
