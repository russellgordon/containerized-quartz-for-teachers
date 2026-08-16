import Foundation
import Observation

/// The twenty tools that exist — thirteen of them shown to the local model —
/// and what running one does.
///
/// Four rules shape this surface. They are inherited from the Windows work
/// rather than rediscovered, and every one of them is measured:
///
/// 1. **Nothing destructive exists.** No delete, no rename, no archive. In
///    testing the model reliably declined "delete the Unit 1 folder" — not from
///    judgement, but because it had no tool for it. Absence is the strongest
///    guardrail available, so it is the one relied on.
///
/// 2. **Publishing and unpublishing are separate tools, not a flag.** The one
///    genuinely dangerous failure ever observed was polarity inversion: asked
///    to HIDE a page, the model called publish with "include everything it
///    links to" set. A boolean is a coin flip under pressure; a verb is not. So
///    the verb is in the tool NAME, it is fixed at the point the tool is
///    routed, and it is carried by the plan all the way to the write — there is
///    no argument anywhere on this surface that could invert it. That boolean
///    is gone entirely now: how far each verb reaches is `AssistPublishPlanner`'s
///    rule, and no tool anywhere takes a boolean.
///
/// 3. **Every write that changes a page has a matching `plan_` tool that
///    changes nothing**, and the plan is written to be read aloud.
///
/// 4. **The coarse tools resolve their own links.** Given `resolve_links`,
///    `set_publish` and `publish_section` separately and asked to publish
///    tomorrow's class and everything it links to, the model chose
///    `publish_section` 8 times out of 8 — consistent, and wrong. Given one
///    `publish_class_on` that follows the links itself, it was right 8 out of
///    8.
///
/// Approval is declared by the tool, not kept in a list here. Only deploying
/// asks for a button: publishing is backed up and `undo_last_change` takes it
/// back, and a gate in front of every write teaches a teacher to click through
/// gates, which is worse than having no gate at all.
///
/// Observable for one property's sake: `conversationBackupURL` appears part way
/// through a conversation, the moment the first write saves a copy, and the
/// window's Restore banner has to appear with it rather than at whatever redraw
/// happens along next.
@Observable
@MainActor
final class AssistToolRunner {

    // MARK: - Stored properties

    /// Where the courses are.
    private let workspace: WorkspaceModel

    /// Building a preview and putting a site on the web.
    private let siteWork: AssistSiteWork

    /// What this conversation has changed, so `undo_last_change` can take it
    /// back.
    private let history: AssistChangeHistory = AssistChangeHistory()

    /// The day "tomorrow" is counted from. Injectable so a test is not a
    /// different test depending on when it runs.
    private let today: CalendarDay

    /// How a scheduled deploy reaches launchd. Injectable for the same reason
    /// the app's own schedule sheet injects it: a test that really bootstrapped
    /// an agent would leave one on the machine running the suite.
    private let launchControl: LaunchControlRunning

    /// The backup this conversation has already made of each course it has
    /// changed, by course code.
    ///
    /// One runner is built per assistant window, so this is per-conversation
    /// state — and that is the whole point: a course full of images makes a
    /// slow, fat zip, and a chat with six commands in it used to make six
    /// near-identical ones. The first write of a conversation saves a copy;
    /// every later write in the same conversation is covered by that copy and
    /// the undo history, so it makes none. A conversation that only reads
    /// makes none at all.
    private var conversationBackups: [String: URL] = [:]

    /// The most recent backup this conversation made, for a window that wants
    /// to offer the teacher a way back to where the chat started. Nil until
    /// the conversation changes something.
    private(set) var conversationBackupURL: URL?

    // MARK: - Computed properties

    /// Whether this conversation has saved a copy to go back to yet.
    var hasConversationBackup: Bool {
        return conversationBackupURL != nil
    }

    /// The tools, as the LOCAL model sees them.
    ///
    /// Thirteen of the twenty that exist. A small local model routes worse the
    /// more it is shown, so anything it never has to NAME is kept off the list:
    /// the six `plan_` twins, which plan mode calls in code, and
    /// `remember_timetable`, whose dates must come from a teacher rather than
    /// from a model. All of them still run when they are called.
    var definitions: [AssistToolDefinition] {
        return AssistToolRunner.localTools
    }

    /// The tools the MCP client sees: everything that exists, plus the ones
    /// that ask for judgement a small local model has no business making.
    var mcpDefinitions: [AssistToolDefinition] {
        return AssistToolRunner.mcpTools
    }

    // MARK: - Initializer

    init(workspace: WorkspaceModel,
         siteWork: AssistSiteWork? = nil,
         today: CalendarDay = CalendarDay.today(),
         launchControl: LaunchControlRunning = LaunchControl()) {
        self.workspace = workspace
        self.siteWork = siteWork ?? AssistToolchainWork(workspace: workspace)
        self.today = today
        self.launchControl = launchControl
    }

    // MARK: - Functions

    /// The tool by that name, or nil when there is none.
    ///
    /// Looks through everything either client may call, because `run(call:)`
    /// runs everything either client may call — and the approval gate reads
    /// `needsApproval` off whatever this hands back. A name that does not look
    /// up is a write that never meets its gate.
    func definition(named name: String) -> AssistToolDefinition? {
        for tool in AssistToolRunner.mcpTools where tool.name == name {
            return tool
        }
        return nil
    }

    /// What pressing the button would do, for the two acts that ask for one.
    ///
    /// Said in the teacher's terms and naming the real destination: "publishes
    /// to the folder you chose" tells a teacher with two courses nothing at
    /// all.
    func explain(call: AssistToolCall) -> String {
        let arguments: [String: Any] = call.argumentValues
        let code: String = text("course", in: arguments)
        let number: Int = number("section", in: arguments) ?? 0

        var destination: String = "the web"
        for course in workspace.courses where course.code.lowercased() == code.lowercased() {
            destination = AssistToolRunner.destination(of: course)
        }

        switch call.function.name {
        case "deploy_section":
            return "Deploy \(code) Section \(number) to \(destination). This is the one thing that changes "
                 + "what students see, and Plantoir cannot take it back for you. Looking the preview over "
                 + "first is the safer order."
        case "schedule_deploy":
            let raw: String = text("when", in: arguments)
            let when: String = AssistToolRunner.moment(named: raw)
                .map { moment in ScheduledDeploy.dayAndTimeText(moment) } ?? raw
            return "Set this Mac to deploy \(code) Section \(number) to \(destination) at \(when). "
                 + "It has to be on and awake then — plugged in if it is a laptop, lid open. "
                 + "Plantoir cannot wake it up."
        default:
            return "Run \(call.function.name)."
        }
    }

    /// Run one tool.
    func run(call: AssistToolCall) async -> AssistToolOutcome {
        let arguments: [String: Any] = call.argumentValues
        switch call.function.name {
        case "list_pages":
            return listPages(arguments)
        case "read_page":
            return readPage(arguments)
        case "check_section":
            return checkSection(arguments)
        case "plan_publish_class_on":
            return planPublishClassOn(arguments)
        case "publish_class_on":
            return await publishClassOn(arguments)
        case "plan_publish_pages":
            return planPublishPages(arguments)
        case "publish_pages":
            return await publishPages(arguments)
        case "plan_unpublish_pages":
            return planUnpublishPages(arguments)
        case "unpublish_pages":
            return await unpublishPages(arguments)
        case "rebuild_preview":
            return await rebuildPreview(arguments)
        case "undo_last_change":
            return undoLastChange()
        case "deploy_section":
            return await deploySection(arguments)
        case "plan_scheduled_deploy":
            return planScheduledDeploy(arguments)
        case "schedule_deploy":
            return scheduleDeploy(arguments)
        case "cancel_scheduled_deploy":
            return cancelScheduledDeploy(arguments)
        case "read_remembered_timetable":
            return readRememberedTimetable(arguments)
        case "plan_remember_timetable":
            return planRememberTimetable(arguments)
        case "remember_timetable":
            return rememberTimetable(arguments)
        case "plan_add_next_class":
            return planAddNextClass(arguments)
        case "add_next_class":
            return addNextClass(arguments)
        case "list_curriculum_expectations":
            return listCurriculumExpectations(arguments)
        case "plan_curriculum_mentions":
            return planCurriculumMentions(arguments)
        case "add_curriculum_mentions":
            return addCurriculumMentions(arguments)
        default:
            return AssistToolOutcome.couldNotRead(
                "There is no tool called “\(call.function.name)”."
            )
        }
    }

    // MARK: - Looking around

    private func listPages(_ arguments: [String: Any]) -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.couldNotRead(refusal(from: found).message)
        }

        let filter: String = text("matching", in: arguments).trimmingCharacters(in: .whitespaces)
        var paths: [String] = []
        for pageURL in ClassPages.pagesOfSection(located.sectionNumber, in: located.course) {
            let path: String = AssistSectionGraph.relativePath(
                of: pageURL, workspaceURL: workspace.workspaceURL
            )
            if filter.isEmpty || path.localizedCaseInsensitiveContains(filter) {
                paths.append(path)
            }
        }

        let where_: String = "\(located.course.code) Section \(located.sectionNumber)"
        if paths.isEmpty {
            let reason: String = filter.isEmpty
                ? "\(where_) has no pages."
                : "No page in \(where_) matches “\(filter)”."
            return AssistToolOutcome.read("Nothing matched in \(where_).", detail: reason)
        }

        var listed: [String] = []
        for path in paths {
            if listed.count == AssistToolRunner.mostPagesListed {
                break
            }
            listed.append(path)
        }
        var detail: String = listed.joined(separator: "\n")
        if paths.count > listed.count {
            detail += "\n\n…and \(paths.count - listed.count) more of \(paths.count). "
                    + "Pass `matching` to narrow this down."
        }

        let word: String = paths.count == 1 ? "page" : "pages"
        return AssistToolOutcome.read("Found \(paths.count) \(word) in \(where_).", detail: detail)
    }

    private func readPage(_ arguments: [String: Any]) -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.couldNotRead(refusal(from: found).message)
        }

        let title: String = text("page", in: arguments)
        let graph: AssistSectionGraph = AssistSectionGraph.read(
            forSection: located.sectionNumber, in: located.course,
            workspaceURL: workspace.workspaceURL
        )
        guard let page = graph.page(titled: title) else {
            return AssistToolOutcome.couldNotRead(AssistToolRefusal.noSuchPage(
                title, located.course.code, located.sectionNumber
            ).message)
        }
        guard var body = try? String(contentsOf: page.fileURL, encoding: .utf8) else {
            return AssistToolOutcome.couldNotRead("“\(page.title)” could not be read.")
        }

        // A whole course does not fit in a small model's context, and a page
        // truncated with a note is far better than a question answered from
        // the half of the page that happened to fit.
        if body.count > AssistToolRunner.mostCharactersRead {
            body = String(body.prefix(AssistToolRunner.mostCharactersRead))
                 + "\n\n…the rest of this page was left out; it is longer than the assistant can read at once."
        }

        return AssistToolOutcome.read(
            "Read “\(page.title)”.",
            detail: "\(page.relativePath)\n\n\(body)"
        )
    }

    private func checkSection(_ arguments: [String: Any]) -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.couldNotRead(refusal(from: found).message)
        }

        let graph: AssistSectionGraph = AssistSectionGraph.read(
            forSection: located.sectionNumber, in: located.course,
            workspaceURL: workspace.workspaceURL
        )
        let dangling: [AssistSectionLink] = graph.linksIntoHiddenPages()
        let orphans: [AssistSectionPage] = graph.visiblePagesNothingLinksTo()

        let visible: Int = graph.visiblePageCount
        let pageWord: String = visible == 1 ? "page" : "pages"
        var paragraphs: [String] = []
        paragraphs.append("Students would see \(visible) \(pageWord) in "
                          + "\(located.course.code) Section \(located.sectionNumber).")

        if dangling.isEmpty {
            paragraphs.append("None of the visible pages link to unpublished pages, ensuring "
                              + "that all links are functional and point to published content.")
        } else {
            var lines: [String] = []
            let word: String = dangling.count == 1 ? "link" : "links"
            lines.append("\(dangling.count) \(word) would take a student to a page that isn't there:")
            var listed: Int = 0
            for link in dangling {
                if listed == AssistToolRunner.mostListed {
                    lines.append("…and \(dangling.count - listed) more.")
                    break
                }
                lines.append("• \(link.fromRelativePath)  →  \(link.toTitle)  (hidden)")
                listed += 1
            }
            lines.append("Either publish the page each one points at, or take the link off "
                         + "the page that points at it.")
            paragraphs.append(lines.joined(separator: "\n"))
        }

        // Silence when nothing is stranded: the teacher asked what students
        // would see, and "every page is linked from somewhere" is only an
        // answer when it is bad news.
        if !orphans.isEmpty {
            var lines: [String] = []
            let word: String = orphans.count == 1 ? "page is" : "pages are"
            lines.append("\(orphans.count) visible \(word) linked from nowhere. Students can still "
                         + "reach these through the site's explorer, and no publish or hide rule "
                         + "that follows links will ever touch them:")
            var listed: Int = 0
            for page in orphans {
                if listed == AssistToolRunner.mostListed {
                    lines.append("…and \(orphans.count - listed) more.")
                    break
                }
                lines.append("• " + page.relativePath)
                listed += 1
            }
            paragraphs.append(lines.joined(separator: "\n"))
        }

        if sectionWindow(for: located.course, sectionNumber: located.sectionNumber)?.isPreviewRunning() == true {
            let these: String = visible == 1 ? "this page" : "these \(visible) pages"
            paragraphs.append("The section's preview will show \(these) once any rebuild "
                              + "in progress finishes.")
        }

        let answer: String = paragraphs.joined(separator: "\n\n")

        // The whole answer, once, and the turn is over. This used to be a
        // read — a terse count for the transcript, a "Show me" disclosure
        // with the specifics, and then the model's own paraphrase of the same
        // facts as a second bubble. Three renderings of one answer, and the
        // only one a teacher actually read was the model's — which, being a
        // paraphrase, was also the only one that could get the facts wrong.
        // The answer is deterministic, so it is composed here and shown
        // as-is; a model lap after it could only restate it.
        return AssistToolOutcome(summary: answer, detail: answer, shouldContinue: false)
    }

    // MARK: - The commonest request of all

    private func planPublishClassOn(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch classPlan(arguments) {
        case .failure(let refusal):
            return AssistToolOutcome.couldNotRead(refusal.message)
        case .success(let planned):
            return AssistToolOutcome.planned(
                "Worked out what publishing the class on \(planned.day.text) would do.",
                plan: planned.plan.describe()
            )
        }
    }

    private func publishClassOn(_ arguments: [String: Any]) async -> AssistToolOutcome {
        switch classPlan(arguments) {
        case .failure(let refusal):
            return AssistToolOutcome.refused(refusal.message)
        case .success(let planned):
            return await carryOut(
                planned.plan,
                forSection: planned.located.sectionNumber,
                in: planned.located.course,
                summary: "Published the class on \(planned.day.text)."
            )
        }
    }

    /// A located class plan: everything the two halves of "publish tomorrow's
    /// class" both need.
    private struct PlannedClass {
        let located: Located
        let day: CalendarDay
        let plan: AssistPublishPlan
    }

    private func classPlan(_ arguments: [String: Any]) -> Result<PlannedClass, AssistToolRefusal> {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return .failure(refusal(from: found))
        }

        // `date` is what the schema asks for. `when` is what the assistant
        // window's fixed phrasings send — "publish tomorrow's class" never
        // reaches the model at all, so the word "tomorrow" arrives here
        // literally and has to be understood here.
        var raw: String = text("date", in: arguments)
        if raw.isEmpty {
            raw = text("when", in: arguments)
        }
        guard let day = AssistToolRunner.day(named: raw, today: today) else {
            return .failure(.unreadableDate(raw, "date"))
        }

        let graph: AssistSectionGraph = AssistSectionGraph.read(
            forSection: located.sectionNumber, in: located.course,
            workspaceURL: workspace.workspaceURL
        )
        let classPages: [ClassPageSummary] = ClassPages.list(
            forSection: located.sectionNumber, in: located.course
        )
        let planned = AssistPublishPlanner.planPublishingClass(
            on: day, graph: graph, classPages: classPages,
            forSection: located.sectionNumber, in: located.course
        )
        switch planned {
        case .failure(let refusal):
            return .failure(refusal)
        case .success(let plan):
            return .success(PlannedClass(located: located, day: day, plan: plan))
        }
    }

    // MARK: - Publishing and unpublishing, which are two different verbs

    private func planPublishPages(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch pagePlan(arguments, publishing: true) {
        case .failure(let refusal):
            return AssistToolOutcome.couldNotRead(refusal.message)
        case .success(let planned):
            return AssistToolOutcome.planned(
                "Worked out what publishing those pages would do.",
                plan: planned.plan.describe()
            )
        }
    }

    private func publishPages(_ arguments: [String: Any]) async -> AssistToolOutcome {
        switch pagePlan(arguments, publishing: true) {
        case .failure(let refusal):
            return AssistToolOutcome.refused(refusal.message)
        case .success(let planned):
            return await carryOut(
                planned.plan,
                forSection: planned.located.sectionNumber,
                in: planned.located.course,
                summary: "Published \(planned.plan.changes.count) "
                       + "\(planned.plan.changes.count == 1 ? "page" : "pages")."
            )
        }
    }

    private func planUnpublishPages(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch pagePlan(arguments, publishing: false) {
        case .failure(let refusal):
            return AssistToolOutcome.couldNotRead(refusal.message)
        case .success(let planned):
            return AssistToolOutcome.planned(
                "Worked out what unpublishing those pages would do.",
                plan: planned.plan.describe()
            )
        }
    }

    private func unpublishPages(_ arguments: [String: Any]) async -> AssistToolOutcome {
        switch pagePlan(arguments, publishing: false) {
        case .failure(let refusal):
            return AssistToolOutcome.refused(refusal.message)
        case .success(let planned):
            return await carryOut(
                planned.plan,
                forSection: planned.located.sectionNumber,
                in: planned.located.course,
                summary: "Unpublished \(planned.plan.changes.count) "
                       + "\(planned.plan.changes.count == 1 ? "page" : "pages")."
            )
        }
    }

    private struct PlannedPages {
        let located: Located
        let plan: AssistPublishPlan
    }

    /// The shared reading of the arguments.
    ///
    /// `publishing` arrives from the CALLER — one of exactly four private
    /// functions above, each of which writes it down literally. It is never
    /// read out of the model's arguments, because that is the one place the
    /// polarity could be inverted.
    private func pagePlan(
        _ arguments: [String: Any],
        publishing: Bool
    ) -> Result<PlannedPages, AssistToolRefusal> {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return .failure(refusal(from: found))
        }

        let titles: [String] = names("pages", in: arguments)
        let onOrAfterText: String = text("onOrAfter", in: arguments)
        let beforeText: String = text("before", in: arguments)

        var onOrAfter: CalendarDay? = nil
        if !onOrAfterText.isEmpty {
            guard let day = CalendarDay(text: onOrAfterText) else {
                return .failure(.unreadableDate(onOrAfterText, "onOrAfter"))
            }
            onOrAfter = day
        }
        var before: CalendarDay? = nil
        if !beforeText.isEmpty {
            guard let day = CalendarDay(text: beforeText) else {
                return .failure(.unreadableDate(beforeText, "before"))
            }
            before = day
        }

        if titles.isEmpty && onOrAfter == nil && before == nil {
            return .failure(.nothingNamed)
        }

        // An open-ended PUBLISH — no pages named, a start date and no end —
        // means "everything from this day to the end of the course", which is
        // not a thing a teacher asks for. It is, however, what a mistyped
        // request for a single lesson turns into: "publsh tomorows class …
        // and the stuff it links to" routed here 10 times out of 10 and filled
        // in `onOrAfter` alone, quietly offering to publish the rest of the
        // term.
        //
        // The rule lives HERE rather than in the tool's description because
        // the description was tried first and measured worse: naming
        // publish_class_on in the text fixed that probe and broke three
        // others, since a small model reads a sentence naming another tool as
        // a recommendation rather than a boundary. A refusal changes nothing
        // the model reads, so it cannot cost accuracy — and it comes back as
        // ordinary text the assistant reads out, so the model gets to correct
        // itself on the next turn.
        //
        // Publishing only. An open-ended UNPUBLISH hides work rather than
        // exposing it, is undone by the same backup, and a teacher clearing a
        // section down to a date is a real thing to want.
        if publishing && titles.isEmpty && before == nil, let from = onOrAfter {
            return .failure(.openEndedPublish(from))
        }

        let graph: AssistSectionGraph = AssistSectionGraph.read(
            forSection: located.sectionNumber, in: located.course,
            workspaceURL: workspace.workspaceURL
        )
        let classPages: [ClassPageSummary] = ClassPages.list(
            forSection: located.sectionNumber, in: located.course
        )

        // How far each verb reaches is the planner's rule, not an argument.
        // Publishing always takes the pages it links to; unpublishing takes
        // only the pages nothing else needs.
        let plan: AssistPublishPlan
        if publishing {
            plan = AssistPublishPlanner.planPublishing(
                titles: titles,
                onOrAfter: onOrAfter, before: before,
                graph: graph, classPages: classPages,
                forSection: located.sectionNumber, in: located.course
            )
        } else {
            plan = AssistPublishPlanner.planUnpublishing(
                titles: titles,
                onOrAfter: onOrAfter, before: before,
                graph: graph, classPages: classPages,
                forSection: located.sectionNumber, in: located.course
            )
        }
        return .success(PlannedPages(located: located, plan: plan))
    }

    // MARK: - Backing up, once per conversation

    /// Makes sure a copy of the course exists from before this conversation
    /// touched it, and says whether one does.
    ///
    /// Lazy and once: the first write saves the copy, and every later write in
    /// the same conversation reuses it rather than saving a near-identical one.
    /// The copy is named for the assistant and the section it was made for, so
    /// a teacher reading the Backups list knows what it was for.
    private func backUpOnceForThisConversation(
        _ course: Course,
        forSection sectionNumber: Int
    ) -> Bool {
        if conversationBackups[course.code] != nil {
            return true
        }
        guard let coursesDirectoryURL = workspace.coursesDirectoryURL else {
            return false
        }
        guard let backupURL = try? CourseArchiver.backUpCourse(
            course,
            coursesDirectoryURL: coursesDirectoryURL,
            madeBy: .assistant(sectionNumber: sectionNumber)
        ) else {
            return false
        }
        conversationBackups[course.code] = backupURL
        conversationBackupURL = backupURL
        return true
    }

    /// What the teacher is told about that copy. The same sentence whether the
    /// backup was made by this command or by an earlier one in the same chat,
    /// because what matters to them is only that there is a way back.
    private static let backedUpNote: String =
        "The course was backed up before this conversation changed anything, so this can also be "
      + "undone from Plantoir's Backups list."

    // MARK: - Writing pages

    /// Back the course up, write the change, remember it, rebuild the preview.
    private func carryOut(
        _ plan: AssistPublishPlan,
        forSection sectionNumber: Int,
        in course: Course,
        summary: String
    ) async -> AssistToolOutcome {
        if plan.changesNothing {
            return AssistToolOutcome.wrote(
                "Nothing needed changing.",
                detail: plan.describe() + "\n\nNothing was changed, because nothing needed to be."
            )
        }

        // Before anything is touched — but only the first time in a
        // conversation. The undo history covers the rest of it; the backup
        // outlives the conversation.
        let backedUp: Bool = backUpOnceForThisConversation(course, forSection: sectionNumber)

        // Stop → write → start, and the stop is HERE rather than beside the
        // start for a reason. A preview left serving while the pages beneath
        // it are rewritten serves a half-changed site, and the teacher's next
        // refresh is a race they cannot see they are in.
        _ = await stopThePreviewBeforeWriting(for: course, sectionNumber: sectionNumber)

        let change: AssistChange
        do {
            change = try AssistPublishPlanner.apply(plan, forSection: sectionNumber, in: course)
        } catch {
            return AssistToolOutcome.refused(
                "Nothing was changed: \(error.localizedDescription)"
            )
        }
        history.record(change)

        var detail: String = plan.describe() + "\n\nDone: \(change.description)."
        if backedUp {
            detail += "\n\n" + AssistToolRunner.backedUpNote
        }

        let previewNote: String = await bringThePreviewUpToDate(
            for: course, sectionNumber: sectionNumber
        )
        detail += "\n\n" + previewNote
        detail += "\n\nThis changed the teacher's files and their PREVIEW. It did not put anything in front "
                + "of students — deploying does that, and only when they ask."

        return AssistToolOutcome.wrote(summary, detail: detail)
    }

    // MARK: - Preview, undo, deploy

    private func rebuildPreview(_ arguments: [String: Any]) async -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.refused(refusal(from: found).message)
        }
        let message: String = await bringThePreviewUpToDate(
            for: located.course, sectionNumber: located.sectionNumber
        )
        return AssistToolOutcome.wrote(message, detail: message)
    }

    /// The window this section is open in, if one is on screen.
    private func sectionWindow(
        for course: Course, sectionNumber: Int
    ) -> SectionWindowControllers.Controller? {
        guard let folder = workspace.workspaceURL else {
            return nil
        }
        return SectionWindowControllers.shared.controller(
            folderPath: folder.path, courseCode: course.code, sectionNumber: sectionNumber
        )
    }

    /// Stop the preview before changing files. Returns whether one was up.
    ///
    /// Called BEFORE the writes, which is the whole point of it being a
    /// separate step. A preview left serving while the pages underneath it are
    /// rewritten is serving a half-changed site, and the teacher's next
    /// refresh is a race they cannot see they are in.
    private func stopThePreviewBeforeWriting(
        for course: Course, sectionNumber: Int
    ) async -> Bool {
        guard let window = sectionWindow(for: course, sectionNumber: sectionNumber) else {
            return false
        }
        if !window.isPreviewRunning() {
            return false
        }
        // Awaited. A stop that is still finishing when the rebuild starts
        // kills the rebuild, and the teacher is left with no preview and a
        // site on disk from before their change.
        await window.stopPreview()
        return true
    }

    /// Put the section's preview back up, built from what is now on disk.
    ///
    /// Always a full stop and restart when one is running, never a quiet
    /// rebuild underneath it: "Preview" asks to be shown the section as it is
    /// NOW, and the running preview is precisely the stale thing being
    /// complained about.
    ///
    /// Two paths, and which one runs depends on whether a section window is
    /// open — not on a flag anyone passes:
    ///
    /// * **A window is open.** Its own Preview is started, which builds AND
    ///   serves. Nothing else builds, because starting it builds: doing a
    ///   `--build-only` pass first would build the same site twice and make a
    ///   teacher wait through both.
    /// * **No window is open.** Nobody can be shown anything, so the site is
    ///   brought up to date on disk and the answer says so plainly rather than
    ///   claiming a preview that does not exist.
    private func bringThePreviewUpToDate(
        for course: Course, sectionNumber: Int
    ) async -> String {
        let where_: String = "\(course.code) Section \(sectionNumber)"

        if let window = sectionWindow(for: course, sectionNumber: sectionNumber) {
            // Stop whatever is running first, and WAIT for it. "Preview" means
            // show me this section as it is now, so a preview already up is
            // the thing most in need of replacing — leaving it alone would
            // answer the request with the very page it was asked to refresh.
            //
            // The wait is not politeness. Stopping reaches into the container
            // and kills that section's processes, so a stop still finishing
            // when the rebuild starts kills the rebuild, and what gets served
            // is the last build allowed to complete — the site as it was
            // before.
            if window.isPreviewRunning() {
                await window.stopPreview()
            }
            window.startPreview()
            return "The preview for \(where_) is rebuilding now, and will appear in that "
                 + "section's window when it is ready."
        }

        let rebuild: AssistSiteWorkResult = await siteWork.rebuildPreview(
            course: course, sectionNumber: sectionNumber
        )
        if !rebuild.succeeded {
            return rebuild.message
        }
        return "Rebuilt the site for \(where_). Open that section in Plantoir and press Preview "
             + "to look it over — no window is showing it at the moment."
    }

    private func undoLastChange() -> AssistToolOutcome {
        if history.isEmpty {
            let reason: String = "This conversation hasn't changed anything yet, so there is nothing to "
                               + "undo. Anything older is in Plantoir's Backups list."
            return AssistToolOutcome.refused(reason)
        }

        let result: AssistUndoResult = history.undo()
        if !result.succeeded && result.restored.isEmpty && result.skipped.isEmpty {
            return AssistToolOutcome.refused(result.description)
        }

        let word: String = result.restored.count == 1 ? "file" : "files"
        var detail: String = "Undid \(result.description) — put \(result.restored.count) \(word) back."
        if !result.skipped.isEmpty {
            let skippedWord: String = result.skipped.count == 1 ? "file was" : "files were"
            detail += "\n\n\(result.skipped.count) \(skippedWord) left alone, because they have changed "
                    + "since — putting the old copy back would throw away that newer work:"
            var listed: Int = 0
            for url in result.skipped {
                if listed == AssistToolRunner.mostListed {
                    detail += "\n  …and \(result.skipped.count - listed) more."
                    break
                }
                detail += "\n  " + AssistSectionGraph.relativePath(
                    of: url, workspaceURL: workspace.workspaceURL
                )
                listed += 1
            }
            detail += "\n\nThis change is still on the list, so it can be tried again."
        }
        detail += "\n\nIf the section had already been deployed, undoing the pages does not take the live "
                + "site back — it has to be deployed again to bring it in step."

        return AssistToolOutcome.wrote("Undid \(result.description).", detail: detail)
    }

    /// Deploy the section — by doing exactly what the teacher would do with
    /// the two buttons in the section's window: Stop Preview, then Deploy.
    ///
    /// **Why the buttons rather than the toolchain directly.** The old version
    /// ran `deploy.sh` in a `ScriptRunner` the assistant made for itself, which
    /// nothing on screen was watching. Two things went wrong with that, and
    /// they compounded into "I pressed Deploy and nothing happened":
    ///
    /// * **Nothing showed.** No console, no progress header, no live-site link
    ///   at the end — a deploy is minutes long, and every visible sign of it
    ///   belongs to the section window. The teacher had a spinner in the chat
    ///   and a section window sitting there saying "No Preview Running".
    /// * **The preview blocked it.** A running preview is exactly when a
    ///   teacher asks for this, and it made the deploy REFUSE — with
    ///   `busyDescription`'s menu fragment, "Available once preview completed",
    ///   which reads like nothing at all. The window's own Deploy button is
    ///   greyed out then, so what a teacher does is press Stop Preview first.
    ///   The assistant now does the same thing, in the same order.
    ///
    /// Stopping is AWAITED before the deploy starts, for the reason it is
    /// awaited before a write: stop mode finds a section's processes by
    /// working directory, so a stop still finishing when the build begins
    /// kills the build.
    ///
    /// With no window open there is nothing to press, and `siteWork` runs the
    /// launcher itself — the path Claude Code and a 6:30 a.m. alarm take.
    private func deploySection(_ arguments: [String: Any]) async -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.refused(refusal(from: found).message)
        }

        _ = await stopThePreviewBeforeWriting(
            for: located.course, sectionNumber: located.sectionNumber
        )

        let result: AssistSiteWorkResult
        if let window = sectionWindow(for: located.course, sectionNumber: located.sectionNumber) {
            result = await window.deploy()
        } else {
            result = await siteWork.deploy(
                course: located.course, sectionNumber: located.sectionNumber
            )
        }

        if !result.succeeded {
            return AssistToolOutcome.refused(result.message)
        }
        // The stopped preview is NOT mentioned, and that was a decision.
        //
        // A sentence explaining it was written first, on the theory that a
        // preview window going blank unasked is its own small alarm. Read in
        // place it was three lines of machinery after the one line that
        // mattered — "CIA4U Section 1 is deployed. Students can reach it now."
        // is the whole answer to what was asked, and the teacher can see the
        // window it happened in. Anything that explains what the assistant had
        // to do to obey is talking about itself.
        return AssistToolOutcome.wrote(result.message, detail: result.message)
    }

    // MARK: - Deploying later

    /// A moment and a section, both read.
    private struct ScheduleRequest {
        let located: Located
        let when: Date
        let plan: ScheduledDeployPlan
    }

    private func scheduleRequest(_ arguments: [String: Any]) -> Result<ScheduleRequest, AssistToolRefusal> {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return .failure(refusal(from: found))
        }
        let raw: String = text("when", in: arguments)
        guard let when = AssistToolRunner.moment(named: raw) else {
            return .failure(.unreadableTime(raw))
        }
        let plan: ScheduledDeployPlan = ScheduledDeploy.plan(
            course: located.course,
            sectionNumber: located.sectionNumber,
            when: when,
            now: Date(),
            cloudflareAccountID: AppSettings.shared.cloudflareAccountID
        )
        return .success(ScheduleRequest(located: located, when: when, plan: plan))
    }

    private func planScheduledDeploy(_ arguments: [String: Any]) -> AssistToolOutcome {
        let request: Result<ScheduleRequest, AssistToolRefusal> = scheduleRequest(arguments)
        guard case .success(let asked) = request else {
            if case .failure(let refusal) = request {
                return AssistToolOutcome.couldNotRead(refusal.message)
            }
            return AssistToolOutcome.couldNotRead(AssistToolRefusal.noWorkingFolder.message)
        }

        // `ScheduledDeployPlan` already says what has to be true of the Mac,
        // and which of the section's classes are still held back. The classes
        // the TEACHER had in mind are checked here on top of that: a deploy
        // that runs perfectly and ships a site without tomorrow's class is the
        // failure worth catching while somebody is awake.
        var lines: [String] = [asked.plan.description]
        let classes: [String] = names("classes", in: arguments)
        if !classes.isEmpty {
            let graph: AssistSectionGraph = AssistSectionGraph.read(
                forSection: asked.located.sectionNumber, in: asked.located.course,
                workspaceURL: workspace.workspaceURL
            )
            lines.append("")
            lines.append("The classes this deploy is meant to carry:")
            for title in classes {
                guard let page = graph.page(titled: title) else {
                    lines.append("  \(title) — no page in this section is called that.")
                    continue
                }
                lines.append("  \(page.title) — "
                             + (page.isVisibleToStudents
                                ? "published, so the deploy would carry it."
                                : "NOT published, so the deploy would ship without it."))
            }
        }
        return AssistToolOutcome.planned(
            asked.plan.isSchedulable
                ? "Worked out what scheduling that deploy would mean."
                : "That deploy cannot be scheduled.",
            plan: lines.joined(separator: "\n")
        )
    }

    private func scheduleDeploy(_ arguments: [String: Any]) -> AssistToolOutcome {
        let request: Result<ScheduleRequest, AssistToolRefusal> = scheduleRequest(arguments)
        guard case .success(let asked) = request else {
            if case .failure(let refusal) = request {
                return AssistToolOutcome.refused(refusal.message)
            }
            return AssistToolOutcome.refused(AssistToolRefusal.noWorkingFolder.message)
        }
        guard let workspaceURL = workspace.workspaceURL else {
            return AssistToolOutcome.refused(AssistToolRefusal.noWorkingFolder.message)
        }

        // Everything the plan refuses is something that would ASK A QUESTION
        // at the scheduled moment, with nobody there to answer it.
        if let problem = asked.plan.problem {
            return AssistToolOutcome.refused("Nothing was scheduled. \(problem)")
        }

        if let problem = ScheduledDeploy.scheduleDeploy(
            course: asked.located.course,
            sectionNumber: asked.located.sectionNumber,
            when: asked.when,
            workspaceURL: workspaceURL,
            cloudflareAccountID: AppSettings.shared.cloudflareAccountID,
            runner: launchControl
        ) {
            return AssistToolOutcome.refused("Nothing was scheduled. \(problem)")
        }

        let moment: String = ScheduledDeploy.dayAndTimeText(asked.when)
        let summary: String = "Scheduled: \(asked.located.course.code) Section "
            + "\(asked.located.sectionNumber) deploys to \(asked.plan.destination) at \(moment)."
        return AssistToolOutcome.wrote(
            summary,
            detail: summary + "\n\nThis Mac has to be on and awake then — plugged in if it is a laptop, "
                  + "lid open. Plantoir cannot wake it up. Say the word and I'll cancel it."
        )
    }

    private func cancelScheduledDeploy(_ arguments: [String: Any]) -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.refused(refusal(from: found).message)
        }

        let pending: Date? = ScheduledDeploy.nextRun(
            courseCode: located.course.code, sectionNumber: located.sectionNumber
        )
        if pending == nil {
            // Safe to call when nothing is scheduled — and it still tidies
            // away an agent left behind by a Mac that was off, which is why
            // this goes ahead rather than returning here.
            ScheduledDeploy.cancelScheduledDeploy(
                courseCode: located.course.code,
                sectionNumber: located.sectionNumber,
                runner: launchControl
            )
            return AssistToolOutcome.wrote(
                "There is no deploy scheduled for \(located.course.code) Section "
                + "\(located.sectionNumber).",
                detail: "There is no deploy scheduled for \(located.course.code) Section "
                      + "\(located.sectionNumber), so there was nothing to call off."
            )
        }

        if let problem = ScheduledDeploy.cancelScheduledDeploy(
            courseCode: located.course.code,
            sectionNumber: located.sectionNumber,
            runner: launchControl
        ) {
            return AssistToolOutcome.refused("That could not be cancelled: \(problem)")
        }
        let message: String = "Cancelled the scheduled deploy for \(located.course.code) Section "
            + "\(located.sectionNumber)."
        return AssistToolOutcome.wrote(message, detail: message)
    }

    // MARK: - When this class meets

    /// What is remembered about when a section meets, read back with WHERE IT
    /// CAME FROM — so a teacher can recognise a stale answer and say so.
    private func readRememberedTimetable(_ arguments: [String: Any]) -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.couldNotRead(refusal(from: found).message)
        }
        let where_: String = "\(located.course.code) Section \(located.sectionNumber)"

        let remembered: SectionTimetable?
        do {
            remembered = try SectionTimetableStore.read(
                forSection: located.sectionNumber, in: located.course
            )
        } catch {
            // A file that IS there and cannot be read whole. Said out loud
            // rather than reported as "no timetable": the two ask different
            // things of the teacher.
            return AssistToolOutcome.couldNotRead(error.localizedDescription)
        }

        guard let remembered else {
            // Asks, rather than telling the model to record them. The tool
            // that writes a timetable is off the local surface, so naming it
            // here would send the model somewhere it cannot go — and the one
            // thing worse than a refusal is a refusal whose remedy does not
            // exist, because the next move is to invent the dates.
            SectionSchedulePrompt.shared.ask(
                courseCode: located.course.code,
                sectionNumber: located.sectionNumber,
                workingFolder: workspace.workspaceURL ?? located.course.directoryURL,
                because: "Nothing on file says when \(where_) meets."
            )
            return AssistToolOutcome.read(
                "No class dates are recorded for \(where_) yet.",
                detail: "No class dates are recorded for \(where_) yet, so nothing knows when it meets — "
                      + "and until they are, a new class page cannot be dated. Plantoir is asking the "
                      + "teacher for this section's class dates now; say so, and that they can be typed "
                      + "in, chosen from a file, or read from a shared sheet."
            )
        }

        var lines: [String] = []
        lines.append("\(where_) meets on \(remembered.dates.count) "
                     + "\(remembered.dates.count == 1 ? "day" : "days"), from "
                     + "\(remembered.firstDate.text) (\(remembered.firstDate.weekdayName)) to "
                     + "\(remembered.lastDate.text) (\(remembered.lastDate.weekdayName)).")
        lines.append("")
        var origin: String = "Where they came from: \(remembered.source)."
        if let when = remembered.recorded {
            origin += " Recorded \(when.text)."
        }
        lines.append(origin)

        // What the dates are actually FOR: the next class takes the next one
        // along, counted by how many class pages the section already has.
        let existing: [ClassPageSummary] = ClassPages.list(
            forSection: located.sectionNumber, in: located.course
        )
        let spare: Int = remembered.spareDates(after: existing.count)
        lines.append("")
        lines.append("\(where_) has \(existing.count) class "
                     + "\(existing.count == 1 ? "page" : "pages").")
        if spare == 0 {
            lines.append("Every recorded date is spoken for, so another class cannot be dated until more "
                         + "dates are recorded.")
        } else {
            let next: CalendarDay = remembered.dates[existing.count]
            lines.append("\(spare) recorded \(spare == 1 ? "date is" : "dates are") still spare; the next "
                         + "class would fall on \(next.text) (\(next.weekdayName)).")
        }

        return AssistToolOutcome.read(
            "\(where_) meets on \(remembered.dates.count) recorded "
            + "\(remembered.dates.count == 1 ? "day" : "days"), from \(remembered.source).",
            detail: lines.joined(separator: "\n")
        )
    }

    private struct PlannedTimetable {
        let located: Located
        let plan: RememberTimetablePlan
    }

    /// The shared reading of the arguments for both halves of remembering a
    /// timetable.
    ///
    /// The dates arrive ALREADY WORKED OUT, as `YYYY-MM-DD`. Nothing here reads
    /// a spreadsheet, a `.csv`, an `.ics` or a teacher's pasted paragraph, and
    /// the model is not asked to do it either — a date read loosely is a class
    /// scheduled on the wrong day.
    ///
    /// - Note: turning a Google Sheet link, a `.csv`, an `.ics` or pasted text
    ///   into `[CalendarDay]` belongs to `SectionScheduleSource`, and it plugs
    ///   in one step upstream of here rather than inside this tool: whatever
    ///   read the dates hands `SectionScheduleSource.Reading.datesText` on to
    ///   `planRememberTimetable`, exactly as this does. Reading a source can
    ///   need a question answered — "is 08/09/2026 the 8th of September or the
    ///   9th of August?" — and that is a question for the teacher, not
    ///   something to settle inside a tool call.
    private func timetablePlan(_ arguments: [String: Any]) -> Result<PlannedTimetable, Error> {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return .failure(refusal(from: found))
        }
        do {
            let plan: RememberTimetablePlan = try SectionTimetableStore.planRememberTimetable(
                dates: days("dates", in: arguments),
                source: text("source", in: arguments),
                forSection: located.sectionNumber,
                in: located.course,
                today: today
            )
            return .success(PlannedTimetable(located: located, plan: plan))
        } catch {
            return .failure(error)
        }
    }

    private func planRememberTimetable(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch timetablePlan(arguments) {
        case .failure(let problem):
            return AssistToolOutcome.couldNotRead(problem.localizedDescription)
        case .success(let asked):
            return AssistToolOutcome.planned(
                asked.plan.changesNothing
                    ? "Those dates are already remembered."
                    : "Worked out what recording those class dates would do.",
                plan: asked.plan.description
            )
        }
    }

    private func rememberTimetable(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch timetablePlan(arguments) {
        case .failure(let problem):
            return AssistToolOutcome.refused(problem.localizedDescription)
        case .success(let asked):
            if asked.plan.changesNothing {
                return AssistToolOutcome.wrote(
                    "Those dates were already remembered.",
                    detail: asked.plan.description
                          + "\n\nNothing was changed, because nothing needed to be."
                )
            }

            // Replacing a year's dates is worth having a way back from, and
            // the copy is made once per conversation however many writes
            // follow it.
            let backedUp: Bool = backUpOnceForThisConversation(
                asked.located.course, forSection: asked.located.sectionNumber
            )
            do {
                try SectionTimetableStore.applyRememberTimetable(asked.plan)
            } catch {
                return AssistToolOutcome.refused(
                    "Nothing was remembered: \(error.localizedDescription)"
                )
            }

            let summary: String = "Remembered \(asked.plan.dates.count) class "
                + "\(asked.plan.dates.count == 1 ? "date" : "dates") for "
                + "\(asked.plan.courseCode) Section \(asked.plan.sectionNumber)."
            var detail: String = asked.plan.description + "\n\nDone: \(summary)"
            detail += "\n\nNo page was touched and no student saw anything. New class pages take their "
                    + "dates from these, so this is worth reading back if a date ever looks wrong."
            if backedUp {
                detail += "\n\n" + AssistToolRunner.backedUpNote
            }
            return AssistToolOutcome.wrote(summary, detail: detail)
        }
    }

    // MARK: - The page for the next class

    private struct PlannedNextClass {
        let located: Located
        let plan: PlaceholderClassPlan
    }

    /// The shared reading of the arguments: which section, and what the next
    /// class page in it would be.
    ///
    /// The failure is carried as the error itself rather than as an
    /// `AssistToolRefusal`, because the two that matter here — no timetable at
    /// all, and a timetable that has run out — belong to `NextClassPlanner`,
    /// and each already says in its own words what to do about it.
    private func nextClassPlan(_ arguments: [String: Any]) -> Result<PlannedNextClass, Error> {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return .failure(refusal(from: found))
        }
        do {
            let plan: PlaceholderClassPlan = try NextClassPlanner.plan(
                forSection: located.sectionNumber, in: located.course
            )
            return .success(PlannedNextClass(located: located, plan: plan))
        } catch {
            return .failure(error)
        }
    }

    /// When the only thing missing is the section's class dates, ASK for them.
    ///
    /// `remember_timetable` is no longer on the local surface — dates the
    /// model supplies are dates it may have invented, and a wrong one silently
    /// puts a class on the wrong day — so a refusal that says "record them
    /// first" is a dead end for the local model: it cannot see the tool it is
    /// being sent to. The sheet is the way a teacher gives dates, and this is
    /// the call that opens it. `SectionSchedulePrompt` exists precisely for
    /// this: the runner knows nothing about windows, so it leaves a request
    /// and whichever assistant window is showing that section presents it.
    ///
    /// Fire and forget on purpose. The tool still refuses THIS turn — the
    /// dates are not there yet — and the teacher answers the sheet and asks
    /// again. Waiting inside the tool would hold the conversation open across
    /// a file picker and a Google Sheets fetch.
    private func askForTheTimetableIfThatIsWhatIsMissing(_ problem: Error) {
        guard case NextClassPlanner.Problem.noTimetable(let code, let number) = problem else {
            return
        }
        guard let folder = workspace.workspaceURL else {
            return
        }
        SectionSchedulePrompt.shared.ask(
            courseCode: code,
            sectionNumber: number,
            workingFolder: folder,
            because: "Adding the next class page needs to know which days this section meets."
        )
    }

    private func planAddNextClass(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch nextClassPlan(arguments) {
        case .failure(let problem):
            askForTheTimetableIfThatIsWhatIsMissing(problem)
            return AssistToolOutcome.couldNotRead(problem.localizedDescription)
        case .success(let asked):
            return AssistToolOutcome.planned(
                asked.plan.changesNothing
                    ? "The next class page already exists."
                    : "Worked out what the next class page would be.",
                plan: asked.plan.description
            )
        }
    }

    private func addNextClass(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch nextClassPlan(arguments) {
        case .failure(let problem):
            askForTheTimetableIfThatIsWhatIsMissing(problem)
            return AssistToolOutcome.refused(problem.localizedDescription)
        case .success(let asked):
            if asked.plan.changesNothing {
                return AssistToolOutcome.wrote(
                    "Nothing needed adding — that page already exists.",
                    detail: asked.plan.description
                          + "\n\nNothing was created, because the page is already there. A page with that "
                          + "name is never written over: it may be a lesson written months ago."
                )
            }

            let backedUp: Bool = backUpOnceForThisConversation(
                asked.located.course, forSection: asked.located.sectionNumber
            )

            let outcome: ClassChangeOutcome
            do {
                // Checked a second time inside `apply`, immediately before the
                // file is written: Obsidian is open in the other window, and a
                // page can appear while the teacher is deciding.
                outcome = try PlaceholderClassPlanner.apply(asked.plan, in: asked.located.course)
            } catch {
                return AssistToolOutcome.refused(
                    "Nothing was created: \(error.localizedDescription)"
                )
            }

            var detail: String = asked.plan.description + "\n\nDone: \(outcome.message)"
            // No preview rebuild: the page starts unpublished, so rebuilding
            // would take minutes to show exactly what is on screen already.
            detail += "\n\nThe preview was not rebuilt, because an unpublished page does not appear on the "
                    + "site. Publishing it when it is written rebuilds by itself."
            // Said plainly rather than left to be discovered: an undo puts
            // files BACK as they were, and a page that did not exist has
            // nothing to be put back to.
            detail += "\n\n“Undo that” does not take away a page it created — delete it in Obsidian if it "
                    + "isn't wanted."
            if backedUp {
                detail += "\n\n" + AssistToolRunner.backedUpNote
            }

            var summary: String = "Added the next class page."
            if let created = asked.plan.classes.first {
                summary = "Added \(created.title), dated \(created.date.text)."
            }
            return AssistToolOutcome.wrote(summary, detail: detail)
        }
    }

    // MARK: - Pointing a page at the curriculum

    /// Read out every expectation, wording and all, and decide nothing.
    ///
    /// Which expectations fit a lesson is a judgement about MEANING. Handing
    /// back the full wording is what makes that judgement possible for whoever
    /// is driving; making it here would put a teacher's name to a claim they
    /// never agreed to.
    private func listCurriculumExpectations(_ arguments: [String: Any]) -> AssistToolOutcome {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return AssistToolOutcome.couldNotRead(refusal(from: found).message)
        }

        let all: [AssistCurriculumExpectation] = AssistCurriculumMentions.expectations(
            forSection: located.sectionNumber, in: located.course,
            workspaceURL: workspace.workspaceURL
        )
        let filter: String = text("matching", in: arguments).trimmingCharacters(in: .whitespaces)

        var matching: [AssistCurriculumExpectation] = []
        for expectation in all {
            if filter.isEmpty
                || expectation.code.localizedCaseInsensitiveContains(filter)
                || expectation.text.localizedCaseInsensitiveContains(filter) {
                matching.append(expectation)
            }
        }

        if matching.isEmpty {
            var reason: String = "No curriculum expectation in \(located.course.code) "
                               + "matches “\(filter)”."
            if filter.isEmpty {
                reason = "\(located.course.code) has no curriculum expectations — this course was "
                       + "installed without them."
            }
            return AssistToolOutcome.read("Nothing matched in \(located.course.code).", detail: reason)
        }

        var lines: [String] = []
        for expectation in matching {
            lines.append("\(expectation.code)  \(expectation.text)")
        }
        let word: String = matching.count == 1 ? "expectation" : "expectations"
        return AssistToolOutcome.read(
            "Found \(matching.count) curriculum \(word) in \(located.course.code).",
            detail: lines.joined(separator: "\n")
        )
    }

    private struct PlannedMentions {
        let located: Located
        let plan: AssistCurriculumMentionsPlan
    }

    private func mentionsPlan(
        _ arguments: [String: Any]
    ) -> Result<PlannedMentions, AssistToolRefusal> {
        let found: Result<Located, AssistToolRefusal> = locate(arguments)
        guard case .success(let located) = found else {
            return .failure(refusal(from: found))
        }

        let title: String = text("page", in: arguments)
        let graph: AssistSectionGraph = AssistSectionGraph.read(
            forSection: located.sectionNumber, in: located.course,
            workspaceURL: workspace.workspaceURL
        )
        guard let page = graph.page(titled: title) else {
            return .failure(.noSuchPage(title, located.course.code, located.sectionNumber))
        }
        guard let pageText = try? String(contentsOf: page.fileURL, encoding: .utf8) else {
            return .failure(.unreadablePage(page.title))
        }

        let plan: AssistCurriculumMentionsPlan = AssistCurriculumMentions.plan(
            codes: codes("codes", in: arguments),
            page: page,
            pageText: pageText,
            expectations: AssistCurriculumMentions.expectations(
                forSection: located.sectionNumber, in: located.course,
                workspaceURL: workspace.workspaceURL
            ),
            courseCode: located.course.code,
            sectionNumber: located.sectionNumber
        )
        return .success(PlannedMentions(located: located, plan: plan))
    }

    private func planCurriculumMentions(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch mentionsPlan(arguments) {
        case .failure(let refusal):
            return AssistToolOutcome.couldNotRead(refusal.message)
        case .success(let asked):
            return AssistToolOutcome.planned(
                asked.plan.changesNothing
                    ? "Nothing needs adding to “\(asked.plan.pageTitle)”."
                    : "Worked out what pointing “\(asked.plan.pageTitle)” at those expectations would do.",
                plan: asked.plan.describe()
            )
        }
    }

    private func addCurriculumMentions(_ arguments: [String: Any]) -> AssistToolOutcome {
        switch mentionsPlan(arguments) {
        case .failure(let refusal):
            return AssistToolOutcome.refused(refusal.message)
        case .success(let asked):
            if asked.plan.changesNothing {
                return AssistToolOutcome.wrote(
                    "Nothing needed adding.",
                    detail: asked.plan.describe()
                          + "\n\nNothing was changed, because nothing needed to be."
                )
            }

            // Before anything is touched — but only the first time in a
            // conversation. The undo history covers the rest of it; the
            // backup outlives the conversation.
            let backedUp: Bool = backUpOnceForThisConversation(
                asked.located.course, forSection: asked.located.sectionNumber
            )

            let change: AssistChange
            do {
                change = try AssistCurriculumMentions.apply(asked.plan)
            } catch {
                return AssistToolOutcome.refused(
                    "Nothing was changed: \(error.localizedDescription)"
                )
            }
            history.record(change)

            let word: String = asked.plan.adding.count == 1 ? "expectation" : "expectations"
            let summary: String = "Added \(asked.plan.adding.count) curriculum \(word) to "
                + "“\(asked.plan.pageTitle)”."
            var detail: String = asked.plan.describe() + "\n\nDone: \(summary.dropLast()) — "
                + AssistCurriculumMentions.codeList(of: asked.plan.adding) + "."
            detail += "\n\nThey are wrapped in the curriculum markers, so a course installed without "
                    + "curriculum still builds. Look the page over in Plantoir."
            if backedUp {
                detail += "\n\n" + AssistToolRunner.backedUpNote
            }
            detail += "\n\nThis changed the teacher's files. It did not put anything in front of students — "
                    + "deploying does that, and only when they ask."

            return AssistToolOutcome.wrote(summary, detail: detail)
        }
    }

    // MARK: - Finding the course and section

    /// A course and section the model named, both found.
    private struct Located {
        let course: Course
        let sectionNumber: Int
    }

    private func locate(_ arguments: [String: Any]) -> Result<Located, AssistToolRefusal> {
        if workspace.workspaceURL == nil {
            return .failure(.noWorkingFolder)
        }

        let code: String = text("course", in: arguments).trimmingCharacters(in: .whitespaces)
        var course: Course? = nil
        for candidate in workspace.courses where candidate.code.lowercased() == code.lowercased() {
            course = candidate
        }
        guard let course else {
            return .failure(.noSuchCourse(code))
        }

        var numbers: [Int] = course.sectionNumbers
        numbers.sort()
        if let asked = number("section", in: arguments) {
            for candidate in numbers where candidate == asked {
                return .success(Located(course: course, sectionNumber: candidate))
            }
            return .failure(.noSuchSection(course.code, asked))
        }
        // No section given. A course with exactly one section has only one
        // answer, so that is not a guess; anything else is, and is refused.
        if numbers.count == 1, let only = numbers.first {
            return .success(Located(course: course, sectionNumber: only))
        }
        return .failure(.noSuchSection(course.code, 0))
    }

    private func refusal(from result: Result<Located, AssistToolRefusal>) -> AssistToolRefusal {
        switch result {
        case .failure(let refusal):
            return refusal
        case .success:
            return .noWorkingFolder
        }
    }

    /// Where a course's site goes, named rather than described.
    static func destination(of course: Course) -> String {
        if course.configuration.deploysToLocalFolder {
            return "a folder on this computer"
        }
        if course.configuration.deploysToCloudflare {
            return "Cloudflare Pages"
        }
        return "Netlify"
    }

    // MARK: - Reading the model's arguments

    /// The model sends numbers as numbers on a good day and as strings on
    /// another; both are read, because a dropped argument reads to a teacher as
    /// the assistant ignoring them.
    private func text(_ key: String, in arguments: [String: Any]) -> String {
        guard let value = arguments[key] else {
            return ""
        }
        if let string = value as? String {
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return ""
    }

    private func number(_ key: String, in arguments: [String: Any]) -> Int? {
        guard let value = arguments[key] else {
            return nil
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let string = value as? String {
            return Int(string.trimmingCharacters(in: .whitespaces))
        }
        return nil
    }

    // No `flag` reader lives here any more, and none should come back. The
    // last boolean on the surface was `includeLinked`, and reading a boolean
    // out of the model's arguments is how a verb gets inverted under pressure.

    /// A list of page names, however the model chose to send it.
    ///
    /// Semicolons, not commas: the class pages in these courses are called
    /// "Unit 2, Day 3", so a comma-separated list of them cuts every name in
    /// half. A JSON array is accepted too, because some builds send one whatever
    /// the schema says.
    private func names(_ key: String, in arguments: [String: Any]) -> [String] {
        var raw: [String] = []
        if let list = arguments[key] as? [Any] {
            for entry in list {
                if let string = entry as? String {
                    raw.append(string)
                }
            }
        } else if let string = arguments[key] as? String {
            for piece in string.components(separatedBy: CharacterSet(charactersIn: ";\n")) {
                raw.append(piece)
            }
        }

        var names: [String] = []
        for entry in raw {
            let tidied: String = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tidied.isEmpty {
                names.append(tidied)
            }
        }
        return names
    }

    /// A list of curriculum expectation codes, however the model chose to send
    /// it.
    ///
    /// Commas here, unlike the page lists, because `A1.1` has no comma in it
    /// and commas are what the Windows server's schema asks for. Semicolons and
    /// newlines are read too — a model that separated them another way still
    /// said exactly which expectations it meant.
    private func codes(_ key: String, in arguments: [String: Any]) -> [String] {
        var raw: [String] = []
        if let list = arguments[key] as? [Any] {
            for entry in list {
                if let string = entry as? String {
                    raw.append(string)
                }
            }
        } else if let string = arguments[key] as? String {
            for piece in string.components(separatedBy: CharacterSet(charactersIn: ",;\n")) {
                raw.append(piece)
            }
        }

        var found: [String] = []
        for entry in raw {
            let tidied: String = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tidied.isEmpty {
                found.append(tidied)
            }
        }
        return found
    }

    /// A list of dates, however the model chose to separate them.
    ///
    /// Deliberately forgiving about the SEPARATOR and not at all forgiving
    /// about the dates themselves. `2026-09-08` has no comma and no semicolon
    /// in it, so either can be read as a separator without risking a date being
    /// cut in half — and a whole year's timetable refused over a punctuation
    /// mark would cost a teacher the five minutes this is meant to save. What
    /// each piece MEANS is still read strictly, one form only, by
    /// `SectionTimetableStore`, which refuses a partial list whole.
    ///
    /// A space is NOT a separator, though a list of dates could be split on one
    /// safely enough. It is left out for the sake of the refusal: "next
    /// Tuesday" quoted back whole is something a teacher can correct, where
    /// "“next” and “Tuesday” aren't dates" reads like the tool misunderstanding
    /// them twice.
    private func days(_ key: String, in arguments: [String: Any]) -> [String] {
        var raw: [String] = []
        if let list = arguments[key] as? [Any] {
            for entry in list {
                if let string = entry as? String {
                    raw.append(string)
                }
            }
        } else if let string = arguments[key] as? String {
            let separators: CharacterSet = CharacterSet(charactersIn: ",;\n\t")
            for piece in string.components(separatedBy: separators) {
                raw.append(piece)
            }
        }

        var found: [String] = []
        for entry in raw {
            let tidied: String = entry.trimmingCharacters(in: .whitespacesAndNewlines)
            if !tidied.isEmpty {
                found.append(tidied)
            }
        }
        return found
    }

    /// A day the teacher named: `2026-09-15`, or the handful of words the
    /// assistant window's fixed phrasings send straight through.
    static func day(named raw: String, today: CalendarDay) -> CalendarDay? {
        let tidied: String = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch tidied {
        case "today":
            return today
        case "tomorrow":
            return shifting(today, byDays: 1)
        case "yesterday":
            return shifting(today, byDays: -1)
        default:
            return CalendarDay(text: raw)
        }
    }

    /// A moment the teacher named: `2026-09-09 06:30`, in 24-hour time and in
    /// this Mac's own time zone.
    ///
    /// Deliberately strict about the FORM, and deliberately forgiving about the
    /// separator — a model that writes `T` between the date and the time has
    /// still said exactly which minute it meant, and refusing that would cost a
    /// teacher a scheduled deploy over a character.
    static func moment(named raw: String) -> Date? {
        let tidied: String = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if tidied.isEmpty {
            return nil
        }
        let patterns: [String] = ["yyyy-MM-dd HH:mm", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd HH:mm:ss"]
        for pattern in patterns {
            let formatter: DateFormatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = pattern
            if let moment = formatter.date(from: tidied) {
                return moment
            }
        }
        return nil
    }

    /// A day this many days along from another.
    static func shifting(_ day: CalendarDay, byDays offset: Int) -> CalendarDay? {
        var components: DateComponents = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        guard let moment = CalendarDay.calendar.date(from: components),
              let moved = CalendarDay.calendar.date(byAdding: .day, value: offset, to: moment) else {
            return nil
        }
        let parts: DateComponents = CalendarDay.calendar.dateComponents(
            [.year, .month, .day], from: moved
        )
        guard let year = parts.year, let month = parts.month, let dayNumber = parts.day else {
            return nil
        }
        return CalendarDay(year: year, month: month, day: dayNumber)
    }

    // MARK: - How much to say

    /// A course runs to a couple of hundred pages — the sample course alone has
    /// 198, most of them curriculum expectations nobody is asking about.
    /// Returning all of them buries the answer and, for a small local model,
    /// fills the context before the question is even considered.
    static let mostPagesListed: Int = 60

    /// How many of each kind to name before summarising.
    static let mostListed: Int = 15

    /// How much of one page to hand back.
    static let mostCharactersRead: Int = 8000
}
