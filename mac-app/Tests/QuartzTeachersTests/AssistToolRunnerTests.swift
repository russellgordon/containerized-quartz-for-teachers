import XCTest
@testable import QuartzTeachers

/// The tool surface the local model calls, and what running one does.
///
/// Most of what is pinned here is SHAPE rather than behaviour, and that is the
/// point. The safety of this feature is almost entirely a property of which
/// tools exist and what they are called: no destructive tool anywhere, publish
/// and unpublish as two separate verbs rather than one flag, a plan in front of
/// every write that changes a page, and a button in front of the one act that
/// reaches students. Those are the things a well-meaning refactor would quietly
/// undo, so those are the things with tests around them.
final class AssistToolRunnerTests: XCTestCase {

    // MARK: - The surface

    /// The exact twenty. Narrowed from the Windows server's full surface, which
    /// is far larger: a small local model routes worse the more it is shown,
    /// and these are the ones a teacher actually asks for.
    ///
    /// **The count is a measurement, and it has moved.** Routing accuracy was
    /// counted against FIFTEEN tools. Five have been added since — reading and
    /// recording a section's timetable, and the page for the next class — and
    /// each was a deliberate decision to spend some of that number. Anyone
    /// changing this figure again should say so out loud, and the accuracy is
    /// worth re-measuring rather than assumed to have survived.
    @MainActor
    func testTheSurfaceIsExactlyTheTwentyNarrowedTools() {
        let expected: Set<String> = [
            "list_pages", "read_page", "check_section",
            "plan_publish_class_on", "publish_class_on",
            "plan_publish_pages", "publish_pages",
            "plan_unpublish_pages", "unpublish_pages",
            "rebuild_preview", "undo_last_change",
            "deploy_section", "plan_scheduled_deploy", "schedule_deploy", "cancel_scheduled_deploy",
            "read_remembered_timetable", "plan_remember_timetable", "remember_timetable",
            "plan_add_next_class", "add_next_class",
        ]

        var names: Set<String> = []
        for tool in AssistToolRunner.tools {
            names.insert(tool.name)
        }
        XCTAssertEqual(names, expected)
        XCTAssertEqual(AssistToolRunner.tools.count, 20, "A tool is defined twice.")
    }

    /// What the LOCAL model is shown: thirteen of the twenty.
    ///
    /// Seven are left off because the model never has to NAME them, and every
    /// schema in the prompt costs a small router accuracy. The six `plan_`
    /// twins are called IN CODE by plan mode, which builds the call from the
    /// write the model already chose; `remember_timetable` is off because dates
    /// the model supplies are dates it may have invented, and a wrong one
    /// silently puts a class on the wrong day. All seven still RUN — they are
    /// hidden from the list, not removed from the surface.
    @MainActor
    func testTheLocalModelIsShownExactlyThirteenToolsAndNoPlans() throws {
        let expected: Set<String> = [
            "list_pages", "read_page", "check_section",
            "publish_class_on", "publish_pages", "unpublish_pages",
            "rebuild_preview", "undo_last_change",
            "deploy_section", "schedule_deploy", "cancel_scheduled_deploy",
            "read_remembered_timetable", "add_next_class",
        ]

        var shown: Set<String> = []
        for tool in AssistToolRunner.localTools {
            shown.insert(tool.name)
        }
        XCTAssertEqual(shown, expected)
        XCTAssertEqual(AssistToolRunner.localTools.count, 13, "A tool is shown twice.")

        for tool in AssistToolRunner.localTools {
            XCTAssertFalse(
                tool.name.hasPrefix("plan_"),
                "\(tool.name) is a plan; plan mode calls those in code, so the model never names one."
            )
        }

        // And the runner really hands that list to the model.
        let runner: AssistToolRunner = try makeRunner().runner
        var handedOver: Set<String> = []
        for definition in runner.definitions {
            handedOver.insert(definition.name)
        }
        XCTAssertEqual(handedOver, expected)
    }

    /// Claude Code, on the other end of the MCP server, has no plan mode: it
    /// needs the twins by name to show a teacher what a write would do. So the
    /// seven hidden from the local list are still served there.
    @MainActor
    func testTheHiddenToolsAreStillServedToClaudeCode() throws {
        let runner: AssistToolRunner = try makeRunner().runner
        var overMCP: Set<String> = []
        for definition in runner.mcpDefinitions {
            overMCP.insert(definition.name)
        }

        let hidden: [String] = [
            "plan_publish_class_on", "plan_publish_pages", "plan_unpublish_pages",
            "plan_scheduled_deploy", "plan_remember_timetable", "plan_add_next_class",
            "remember_timetable",
        ]
        for name in hidden {
            XCTAssertTrue(overMCP.contains(name), "\(name) is missing from the MCP surface.")
            XCTAssertNotNil(runner.definition(named: name), "\(name) must still be runnable.")
        }

        // Reading the dates back is not the same act as writing them, and it
        // invents nothing, so it stays on both surfaces.
        var localNames: Set<String> = []
        for tool in AssistToolRunner.localTools {
            localNames.insert(tool.name)
        }
        XCTAssertTrue(localNames.contains("read_remembered_timetable"))
        XCTAssertTrue(overMCP.contains("read_remembered_timetable"))
    }

    /// Every tool the model may name can be found again by name — the gate
    /// reads `needsApproval` off the definition it looks up, so a name that
    /// does not look up is a write that never meets its gate.
    @MainActor
    func testEveryToolCanBeFoundByName() throws {
        let runner: AssistToolRunner = try makeRunner().runner
        for tool in AssistToolRunner.tools {
            XCTAssertEqual(runner.definition(named: tool.name)?.name, tool.name)
        }
        XCTAssertNil(runner.definition(named: "delete_everything"))
    }

    /// Only deploying asks for a button. Publishing is backed up and
    /// `undo_last_change` takes it back, and a gate in front of every write
    /// teaches a teacher to click through gates — which is worse than having no
    /// gate at all.
    @MainActor
    func testOnlyDeployingAndSchedulingADeployAskForApproval() {
        var needingApproval: Set<String> = []
        for tool in AssistToolRunner.tools where tool.needsApproval {
            needingApproval.insert(tool.name)
        }
        XCTAssertEqual(needingApproval, ["deploy_section", "schedule_deploy"])
    }

    /// Approval survives the rewrite that names the real course. The gate reads
    /// the runner's own definition, but nothing should depend on that: a tool
    /// that loses its gate on the way to the model is a bug waiting for a
    /// second caller.
    @MainActor
    func testNamingTheRealCourseKeepsTheApprovalGate() {
        for tool in AssistToolRunner.tools {
            let renamed: AssistToolDefinition = tool.namingTheRealCourse("EXC2O")
            XCTAssertEqual(renamed.needsApproval, tool.needsApproval, tool.name)
            XCTAssertEqual(renamed.readOnly, tool.readOnly, tool.name)
        }
    }

    /// Nothing destructive exists. In testing the model reliably declined
    /// "delete the Unit 1 folder" — not from judgement, but because it had no
    /// tool for it. Absence is the strongest guardrail available.
    @MainActor
    func testNoToolCanDestroyAnything() {
        let forbidden: [String] = ["delete", "remove", "rename", "archive", "erase", "destroy", "move"]
        for tool in AssistToolRunner.tools {
            for word in forbidden {
                XCTAssertFalse(
                    tool.name.contains(word),
                    "\(tool.name) contains “\(word)”, and nothing on this surface may destroy anything."
                )
            }
        }
    }

    /// Every write that changes what is IN a teacher's pages has a `plan_` twin
    /// that changes nothing.
    ///
    /// The three writes without one are each their own reversal: rebuilding a
    /// preview changes no page, undoing IS the undo, and cancelling a schedule
    /// only takes one away. Deploying has no plan because it has the one thing
    /// a plan is a substitute for — a button the teacher has to press.
    @MainActor
    func testEveryWriteThatChangesPagesHasAPlanTwin() {
        let ownReversal: Set<String> = [
            "rebuild_preview", "undo_last_change", "deploy_section", "cancel_scheduled_deploy",
        ]

        var names: Set<String> = []
        for tool in AssistToolRunner.tools {
            names.insert(tool.name)
        }

        for definition in AssistToolRunner.tools {
            if definition.readOnly || ownReversal.contains(definition.name) {
                continue
            }
            let twin: String = planName(for: definition.name)
            XCTAssertTrue(
                names.contains(twin),
                "\(definition.name) changes pages but has no \(twin) to show the teacher first."
            )
            XCTAssertEqual(
                tool(named: twin)?.readOnly, true, "\(twin) must change nothing."
            )
        }

        // And the plans really are plans.
        for tool in AssistToolRunner.tools where tool.name.hasPrefix("plan_") {
            XCTAssertTrue(tool.readOnly, "\(tool.name) is named a plan but is not read-only.")
            XCTAssertFalse(tool.needsApproval, "A plan changes nothing, so it never needs a button.")
        }
    }

    /// `schedule_deploy`'s twin is spelled differently from the rest, so the
    /// mapping is written down rather than assumed.
    private func planName(for toolName: String) -> String {
        if toolName == "schedule_deploy" {
            return "plan_scheduled_deploy"
        }
        return "plan_" + toolName
    }

    @MainActor
    private func tool(named name: String) -> AssistToolDefinition? {
        for definition in AssistToolRunner.tools where definition.name == name {
            return definition
        }
        return nil
    }

    // MARK: - The polarity rule

    /// Publishing and unpublishing are separate tools, and NOTHING on the
    /// surface can turn one into the other.
    ///
    /// This is the rule the whole design turns on. The single genuinely
    /// dangerous failure ever observed was polarity inversion: asked to HIDE a
    /// page, the model called publish with "include everything it links to"
    /// set. A boolean is a coin flip under pressure; a verb is not — so the
    /// verb lives in the tool's NAME, and there is now no boolean anywhere on
    /// the surface at all. `includeLinked` was the last one, and how far each
    /// verb reaches is `AssistPublishPlanner`'s rule instead.
    @MainActor
    func testPublishingAndUnpublishingAreSeparateVerbsWithNoFlagBetweenThem() {
        let pairs: [(String, String)] = [
            ("publish_pages", "unpublish_pages"),
            ("plan_publish_pages", "plan_unpublish_pages"),
        ]
        var names: Set<String> = []
        for tool in AssistToolRunner.tools {
            names.insert(tool.name)
        }
        for (publishing, unpublishing) in pairs {
            XCTAssertTrue(names.contains(publishing))
            XCTAssertTrue(names.contains(unpublishing))
        }

        // No boolean, anywhere — on either surface. Every one of them is an
        // argument the model has to decide, and deciding is the thing this
        // design keeps away from it.
        for tool in AssistToolRunner.mcpTools {
            for (name, property) in tool.parameters {
                XCTAssertNotEqual(
                    property.kind, .boolean,
                    "\(tool.name) takes a boolean called \(name); no tool on this surface takes one, "
                    + "because a boolean is what the model gets wrong under pressure."
                )
            }
            XCTAssertNil(tool.parameters["includeLinked"],
                         "\(tool.name) still asks the model how far to reach.")
        }
    }

    /// Publishing takes the pages it links to WITHOUT being asked. There is no
    /// argument for it any more: a published page whose links lead to pages
    /// students cannot see is the failure the rule exists to prevent.
    @MainActor
    func testPublishingTakesTheLinkedPagesWithNoArgument() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "false", body: "See [[Loops]].", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "false",
                  body: "See [[Snippets]].", in: made.course)
        try write(courseLevelPage: "Snippets", publishForSection1: "false",
                  body: "Some code.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "publish_pages", arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))
        XCTAssertFalse(outcome.shouldContinue)
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: true"))
        // Followed all the way along, as publishing a class already was.
        XCTAssertTrue(text(ofCourseLevelPage: "Loops", in: made.course).contains("publishForSection1: true"))
        XCTAssertTrue(text(ofCourseLevelPage: "Snippets", in: made.course).contains("publishForSection1: true"))
    }

    /// A class page is a ROOT, not an orphan.
    ///
    /// The rule the courses are built to is that every page must be reachable
    /// FROM a class page; the class page itself is reached through the site's
    /// own navigation, and normally nothing wikilinks to it. Counting them
    /// made a perfectly healthy 86-period course report 84 pages "linked from
    /// nowhere" — every one of them a lesson — which teaches a teacher to
    /// ignore the whole check.
    @MainActor
    func testClassPagesAreNotCountedAsLinkedFromNowhere() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        // Two lessons nothing links to, and one concept page that IS linked.
        try write(page: "Unit 1, Day 1", publish: "true", body: "See [[Loops]].", in: made.course)
        try write(page: "Unit 1, Day 2", publish: "true", body: "More practice.", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "true",
                  body: "About loops.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "check_section", arguments: ["course": "ICS3U", "section": 1]
        ))

        XCTAssertTrue(outcome.summary.contains("0 linked from nowhere"), outcome.summary)
        XCTAssertTrue(outcome.detail.contains("Every visible page is linked from somewhere."),
                      outcome.detail)
    }

    /// A page that is genuinely stranded is still reported — the fix above
    /// must not turn the check off.
    @MainActor
    func testAStrandedPageIsStillReported() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true", body: "A lesson.", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "true",
                  body: "Nothing points at this.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "check_section", arguments: ["course": "ICS3U", "section": 1]
        ))

        XCTAssertTrue(outcome.summary.contains("1 linked from nowhere"), outcome.summary)
        XCTAssertTrue(outcome.detail.contains("Loops"), outcome.detail)
    }

    /// The plan card shows the teacher `forTheCard`, not `detail`.
    ///
    /// `detail` ends with a sentence addressed to whatever is reading a plan
    /// on a surface with no Go and Cancel of its own — Claude Code over MCP.
    /// It appeared on the card for a while, directly above the very buttons
    /// it was describing, telling a teacher to "show this to the teacher".
    @MainActor
    func testAPlanCardDoesNotShowTheSentenceWrittenForTheModel() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true", body: "A lesson.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "plan_unpublish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))

        XCTAssertTrue(outcome.detail.contains("ask before going ahead"),
                      "Claude Code has no plan mode, so it still has to be told to ask")
        XCTAssertFalse(outcome.forTheCard.contains("ask before going ahead"),
                       "The card has Go and Cancel underneath it; saying it as well is noise")
        XCTAssertFalse(outcome.forTheCard.contains("Show this to the teacher"),
                       "…and it addresses the teacher as though they were the model")
        XCTAssertTrue(outcome.forTheCard.contains("Unit 1, Day 1"),
                      "The plan itself is still all there")
    }

    /// A start date with no end date and no pages named means "everything
    /// from here to the end of the course", which is what a mistyped request
    /// for ONE lesson turns into — measured at 10 trials out of 10 on
    /// "publsh tomorows class … and the stuff it links to". It is refused
    /// rather than planned, and the refusal says what to do instead.
    @MainActor
    func testAnOpenEndedPublishIsRefusedRatherThanPlanned() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "false", body: "A lesson.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "publish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "", "onOrAfter": "2026-09-08"]
        ))

        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"),
                      "Nothing may be published by an open-ended range")
        XCTAssertTrue(outcome.detail.contains("publish_class_on"),
                      "The refusal has to name what to do for one day, or the model cannot correct itself")
        XCTAssertTrue(outcome.detail.contains("before"),
                      "…and how to ask for a stretch of classes")
    }

    /// The same shape is allowed for UNPUBLISHING: hiding work back to a date
    /// is a real thing to want, it exposes nothing, and the same backup undoes
    /// it. The asymmetry is deliberate.
    @MainActor
    func testAnOpenEndedUnpublishIsStillAllowed() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true", body: "A lesson.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "unpublish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "", "onOrAfter": "2020-01-01"]
        ))

        XCTAssertFalse(outcome.detail.contains("almost certainly not what was meant"),
                       "Unpublishing must not inherit publishing's refusal")
    }

    /// Unpublishing is NOT the mirror image. A page the named ones are the only
    /// link to comes down with them — and so does what only THAT page linked
    /// to, which is why the rule is worked out to a fixed point.
    @MainActor
    func testUnpublishingTakesAPageLinkedOnlyByTheOneComingDown() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true", body: "See [[Loops]].", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "true",
                  body: "See [[Snippets]].", in: made.course)
        try write(courseLevelPage: "Snippets", publishForSection1: "true",
                  body: "Some code.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "unpublish_pages", arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))
        XCTAssertFalse(outcome.shouldContinue)
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"))
        XCTAssertTrue(text(ofCourseLevelPage: "Loops", in: made.course).contains("publishForSection1: false"))
        XCTAssertTrue(
            text(ofCourseLevelPage: "Snippets", in: made.course).contains("publishForSection1: false"),
            "A page only the page only THAT page linked to still comes down."
        )
    }

    /// The rule that keeps this from breaking another class: a page something
    /// else still links to stays published — and the plan SAYS so, naming what
    /// still links to it.
    @MainActor
    func testUnpublishingKeepsAPageAnotherPageStillLinksToAndSaysWhy() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 3, Day 1", publish: "true", body: "See [[Ohm's Law]].", in: made.course)
        try write(page: "Unit 3, Day 2", publish: "true", body: "See [[Ohm's Law]].", in: made.course)
        try write(courseLevelPage: "Ohm's Law", publishForSection1: "true",
                  body: "Voltage over current.", in: made.course)

        let planned: AssistToolOutcome = await made.runner.run(call: call(
            "plan_unpublish_pages", arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 3, Day 1"]
        ))
        XCTAssertTrue(planned.detail.contains("Ohm's Law"))
        XCTAssertTrue(
            planned.detail.contains("“Unit 3, Day 2” still links to it."),
            "A teacher has to see that the tool thought about it: \(planned.detail)"
        )

        let done: AssistToolOutcome = await made.runner.run(call: call(
            "unpublish_pages", arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 3, Day 1"]
        ))
        XCTAssertFalse(done.shouldContinue)
        XCTAssertTrue(text(ofPage: "Unit 3, Day 1", in: made.course).contains("publish: false"))
        XCTAssertTrue(text(ofPage: "Unit 3, Day 2", in: made.course).contains("publish: true"))
        XCTAssertTrue(
            text(ofCourseLevelPage: "Ohm's Law", in: made.course).contains("publishForSection1: true"),
            "Hiding this week's lesson must not leave last week's pointing at nothing."
        )
    }

    /// Three kinds of page never come down by following a link, whatever the
    /// link count: a folder's landing page, anything the section's Key Links
    /// offers, and any curriculum page.
    ///
    /// Each is reached from somewhere other than a lesson, so counting links
    /// says nothing useful about whether it is still wanted. Both pages that
    /// link to Key Links' entry are taken down here, so the reference rule
    /// alone would have swept it — the exclusion is what saves it.
    @MainActor
    func testAFolderIndexKeyLinksAndCurriculumAreNeverUnpublishedByFollowingLinks() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true",
                  body: "See [[Concepts/index]], [[Course Outline]], [[A1.1]] and [[Loops]].",
                  in: made.course)
        try write(sectionPage: "Key Links", publish: "true",
                  body: "See [[Course Outline]].", in: made.course)
        try write(courseLevelPage: "index", inFolder: "Concepts",
                  publishForSection1: "true", body: "The concepts.", in: made.course)
        try write(courseLevelPage: "Course Outline", inFolder: "Concepts",
                  publishForSection1: "true", body: "How the class runs.", in: made.course)
        try write(courseLevelPage: "A1.1", inFolder: "Curriculum",
                  publishForSection1: "true", body: "Describe an algorithm. ^text", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "true",
                  body: "About loops.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "unpublish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1; Key Links"]
        ))
        XCTAssertFalse(outcome.shouldContinue)

        // The pages the teacher named came down, because they asked.
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"))
        // And the page nothing else needs came down with them.
        XCTAssertTrue(text(ofCourseLevelPage: "Loops", in: made.course).contains("publishForSection1: false"))

        // The three that never do.
        XCTAssertTrue(
            text(ofCourseLevelPage: "index", inFolder: "Concepts", in: made.course)
                .contains("publishForSection1: true"),
            "A folder's landing page is the way IN to a folder, never an orphan."
        )
        XCTAssertTrue(
            text(ofCourseLevelPage: "Course Outline", inFolder: "Concepts", in: made.course)
                .contains("publishForSection1: true"),
            "A page this section's Key Links offers stays."
        )
        XCTAssertTrue(
            text(ofCourseLevelPage: "A1.1", inFolder: "Curriculum", in: made.course)
                .contains("publishForSection1: true"),
            "A curriculum page stays — build_site.py's own rule, any folder named for curriculum."
        )

        XCTAssertTrue(outcome.detail.contains("folder's landing page"), outcome.detail)
        XCTAssertTrue(outcome.detail.contains("Key Links"), outcome.detail)
        XCTAssertTrue(outcome.detail.contains("curriculum page"), outcome.detail)
    }

    /// The verb reaches the FILE without passing through anything that could
    /// flip it: hiding a page with "include everything it links to" set hides
    /// the linked pages too, and publishes nothing.
    @MainActor
    func testHidingWithLinkedPagesNeverPublishesAnything() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true", body: "See [[Loops]].", in: made.course)
        try write(page: "Unit 1, Day 2", publish: "false", body: "Nothing yet.", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "true", body: "About loops.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "unpublish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))

        XCTAssertFalse(outcome.shouldContinue, "A write ends the turn.")
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"))
        XCTAssertTrue(text(ofCourseLevelPage: "Loops", in: made.course).contains("publishForSection1: false"))
        // The page that was already hidden is untouched, not toggled.
        XCTAssertTrue(text(ofPage: "Unit 1, Day 2", in: made.course).contains("publish: false"))
    }

    // MARK: - Naming the real course

    /// With `for example ICS3U` left in the schema, a request that named no
    /// course copied ICS3U out of the examples nine times out of nine. So every
    /// mention of the placeholder is replaced before the model ever sees it —
    /// in the parameter descriptions, which is where the examples live.
    @MainActor
    func testNamingTheRealCourseRewritesEveryParameterDescription() {
        var placeholdersFound: Int = 0
        for tool in AssistToolRunner.tools {
            for (_, property) in tool.parameters where property.description.contains("ICS3U") {
                placeholdersFound += 1
            }
        }
        XCTAssertGreaterThan(placeholdersFound, 0, "The placeholder has to be there to be worth replacing.")

        for tool in AssistToolRunner.tools {
            let renamed: AssistToolDefinition = tool.namingTheRealCourse("EXC2O")
            XCTAssertFalse(renamed.description.contains("ICS3U"), tool.name)
            for (name, property) in renamed.parameters {
                XCTAssertFalse(
                    property.description.contains("ICS3U"),
                    "\(tool.name).\(name) still names the placeholder course."
                )
            }
            if let course = renamed.parameters["course"] {
                XCTAssertTrue(course.description.contains("EXC2O"))
            }
        }
    }

    /// The description is rewritten too. None of the fifteen happens to name
    /// the placeholder in its own description — the shortening rule cuts the
    /// sentences that did — so the rewrite is proved on a definition built for
    /// the purpose rather than left untested.
    @MainActor
    func testNamingTheRealCourseRewritesTheDescriptionAsWell() {
        let invented: AssistToolDefinition = AssistToolDefinition(
            name: "list_pages",
            description: "List the pages in ICS3U.",
            parameters: ["course": AssistSchemaProperty(kind: .string, description: "For example ICS3U.")],
            required: ["course"],
            readOnly: true,
            needsApproval: false
        )
        let renamed: AssistToolDefinition = invented.namingTheRealCourse("EXC2O")
        XCTAssertEqual(renamed.description, "List the pages in EXC2O.")
        XCTAssertEqual(renamed.parameters["course"]?.description, "For example EXC2O.")
    }

    // MARK: - The phrasings that were measured

    /// The `TEACHERS SAY` clauses are what took routing from 69% to 91%. They
    /// are copied from the Windows server rather than reworded, so this pins
    /// the ones that must survive a tidy-up.
    @MainActor
    func testTheMeasuredPhrasingsAreStillThere() throws {
        let mustSay: [String: String] = [
            "publish_class_on": "TEACHERS SAY: \"publish tomorrow's class\"",
            "unpublish_pages": "\"take Unit 4, Day 5 back down\"",
            "rebuild_preview": "TEACHERS SAY: \"preview the site\"",
            "undo_last_change": "TEACHERS SAY: \"undo that\"",
            "deploy_section": "TEACHERS SAY: \"deploy the site\"",
            "check_section": "TEACHERS SAY: \"what do students see right now?\"",
            "add_next_class": "TEACHERS SAY: \"add an entry for the next class\"",
            "read_remembered_timetable": "TEACHERS SAY: \"when does this class meet?\"",
        ]
        for (name, phrasing) in mustSay {
            let definition: AssistToolDefinition = try XCTUnwrap(tool(named: name))
            XCTAssertTrue(definition.description.contains(phrasing), "\(name) lost a measured phrasing.")
        }
    }

    /// Every phrasing the assistant window offers as a card routes to a tool
    /// that exists. The cards never reach the model, so a name that does not
    /// match is a button that does nothing at all.
    @MainActor
    func testEveryCardPhrasingNamesARealTool() throws {
        let phrasings: [String] = [
            "what would students see in this section right now?",
            "what do students see right now?",
            "rebuild the preview",
            "undo that",
            "deploy now",
            "deploy this section now",
            "publish tomorrow's class",
        ]
        // Checked against what the LOCAL model is shown, because a card is a
        // shortcut past the model to a tool the window promises.
        var names: Set<String> = []
        for tool in AssistToolRunner.localTools {
            names.insert(tool.name)
        }
        for phrasing in phrasings {
            let command: AssistCardCommand = try XCTUnwrap(AssistCardCommand.matching(phrasing))
            XCTAssertTrue(names.contains(command.toolName), phrasing)
        }
    }

    /// "Publish tomorrow's class" is matched in code and never reaches the
    /// model, so the word "tomorrow" arrives at the runner literally. It has to
    /// be understood there or the card publishes nothing.
    @MainActor
    func testTheCardsWordForTomorrowIsUnderstood() {
        let today: CalendarDay = CalendarDay(year: 2026, month: 9, day: 8)!
        XCTAssertEqual(AssistToolRunner.day(named: "tomorrow", today: today)?.text, "2026-09-09")
        XCTAssertEqual(AssistToolRunner.day(named: "today", today: today)?.text, "2026-09-08")
        XCTAssertEqual(AssistToolRunner.day(named: "2026-10-01", today: today)?.text, "2026-10-01")
        XCTAssertNil(AssistToolRunner.day(named: "next Tuesday", today: today))
    }

    // MARK: - Running the tools

    @MainActor
    func testListingAndReadingPages() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true", body: "See [[Loops]].", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "true", body: "About loops.", in: made.course)

        let listed: AssistToolOutcome = await made.runner.run(call: call(
            "list_pages", arguments: ["course": "ICS3U", "section": 1]
        ))
        XCTAssertTrue(listed.shouldContinue, "A read hands back so the model can answer.")
        XCTAssertTrue(listed.detail.contains("Unit 1, Day 1.md"))
        XCTAssertTrue(listed.detail.contains("Loops.md"))

        let filtered: AssistToolOutcome = await made.runner.run(call: call(
            "list_pages", arguments: ["course": "ICS3U", "section": 1, "matching": "Loops"]
        ))
        XCTAssertFalse(filtered.detail.contains("Unit 1, Day 1.md"))

        let read: AssistToolOutcome = await made.runner.run(call: call(
            "read_page", arguments: ["course": "ICS3U", "section": 1, "page": "unit 1, day 1"]
        ))
        XCTAssertTrue(read.detail.contains("See [[Loops]]."), "Titles match without regard to case.")

        let missing: AssistToolOutcome = await made.runner.run(call: call(
            "read_page", arguments: ["course": "ICS3U", "section": 1, "page": "Unit 9, Day 9"]
        ))
        XCTAssertTrue(missing.detail.contains("No page in ICS3U Section 1 is called"))
    }

    /// What `check_section` is for: the two things the publishing tools cannot
    /// see for themselves.
    @MainActor
    func testCheckSectionReportsBrokenLinksAndPagesNothingLinksTo() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        // A visible class pointing at a hidden page: a student clicks and finds
        // nothing.
        try write(page: "Unit 1, Day 1", publish: "true", body: "See [[Loops]].", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "false", body: "About loops.", in: made.course)
        // A visible page nothing links to: still in the site's explorer, and no
        // link-following rule will ever reach it.
        //
        // A COURSE-LEVEL page deliberately. Written as a class page it would
        // not count, and rightly: class pages are the roots a section is
        // navigated from, so nothing linking to one is its ordinary state.
        try write(courseLevelPage: "Field Trip", publishForSection1: "true",
                  body: "The museum.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "check_section", arguments: ["course": "ICS3U", "section": 1]
        ))
        XCTAssertTrue(outcome.shouldContinue)
        XCTAssertTrue(outcome.detail.contains("3 pages, 2 visible to students"))
        XCTAssertTrue(outcome.detail.contains("Loops"))
        XCTAssertTrue(outcome.detail.contains("(hidden)"))
        XCTAssertTrue(outcome.detail.contains("linked from nowhere"))
        XCTAssertTrue(outcome.detail.contains("Field Trip"))
    }

    /// The coarse tool. "Publish tomorrow's class" resolves the linked pages
    /// ITSELF rather than leaving the model to chain calls — the decision that
    /// took an 8-of-8 failure to 8-of-8 correct.
    @MainActor
    func testPublishingAClassByDatePublishesWhatItLinksTo() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "false", date: "2026-09-08",
                  body: "See [[Loops]].", in: made.course)
        try write(courseLevelPage: "Loops", publishForSection1: "false",
                  body: "See [[Snippets]].", in: made.course)
        try write(courseLevelPage: "Snippets", publishForSection1: "false",
                  body: "Some code.", in: made.course)
        try write(page: "Unit 1, Day 2", publish: "false", date: "2026-09-10",
                  body: "Nothing here.", in: made.course)

        let planned: AssistToolOutcome = await made.runner.run(call: call(
            "plan_publish_class_on", arguments: ["course": "ICS3U", "section": 1, "date": "2026-09-08"]
        ))
        XCTAssertTrue(planned.shouldContinue)
        XCTAssertTrue(planned.detail.contains("Nothing has been changed."))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"),
                      "A plan changes nothing.")

        let done: AssistToolOutcome = await made.runner.run(call: call(
            "publish_class_on", arguments: ["course": "ICS3U", "section": 1, "date": "2026-09-08"]
        ))
        XCTAssertFalse(done.shouldContinue)
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: true"))
        // Followed transitively: the class links to Loops, and Loops links to
        // Snippets. Stopping at one hop leaves a student one click from
        // nothing.
        XCTAssertTrue(text(ofCourseLevelPage: "Loops", in: made.course).contains("publishForSection1: true"))
        XCTAssertTrue(text(ofCourseLevelPage: "Snippets", in: made.course).contains("publishForSection1: true"))
        // The class nobody asked about is left exactly as it was.
        XCTAssertTrue(text(ofPage: "Unit 1, Day 2", in: made.course).contains("publish: false"))
        XCTAssertEqual(made.siteWork.previewRebuilds, 1, "A change rebuilds the preview by itself.")
    }

    /// No class on that day is a sentence, not a crash — and nothing is
    /// written.
    @MainActor
    func testPublishingAClassOnADayWithNoClassChangesNothing() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "false", date: "2026-09-08", body: "Loops.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "publish_class_on", arguments: ["course": "ICS3U", "section": 1, "date": "2026-12-25"]
        ))
        XCTAssertFalse(outcome.shouldContinue, "A refused write is still the end of the turn.")
        XCTAssertTrue(outcome.summary.contains("No class"))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"))
    }

    /// The older spelling means the OPPOSITE, is read correctly, and is written
    /// back in the spelling the teacher used.
    @MainActor
    func testTheOlderDraftSpellingIsReadAndKept() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        let page: String = """
        ---
        title: Unit 1, Day 1
        draft: true
        created: 2026-09-08T07:00:00.000-0400
        ---

        Loops.
        """
        let url: URL = ClassPages.folderURL(forSection: 1, in: made.course)
            .appendingPathComponent("Unit 1, Day 1.md")
        try page.write(to: url, atomically: true, encoding: .utf8)

        // `draft: true` is a page students cannot see, so the check must count
        // it as hidden rather than as published.
        let checked: AssistToolOutcome = await made.runner.run(call: call(
            "check_section", arguments: ["course": "ICS3U", "section": 1]
        ))
        XCTAssertTrue(checked.detail.contains("1 page, 0 visible to students"))

        let published: AssistToolOutcome = await made.runner.run(call: call(
            "publish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))
        XCTAssertFalse(published.shouldContinue)
        let after: String = text(ofPage: "Unit 1, Day 1", in: made.course)
        XCTAssertTrue(after.contains("draft: false"), "The teacher's own spelling is kept, inverted.")
        XCTAssertFalse(after.contains("publish:"), "No second key is invented behind their back.")
    }

    /// Choosing classes by date, so "hide everything from next Monday on" is
    /// one call and the comparison is never something the model does.
    @MainActor
    func testPagesCanBeChosenByDateRatherThanByName() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "true", date: "2026-09-08", body: "One.", in: made.course)
        try write(page: "Unit 1, Day 2", publish: "true", date: "2026-09-10", body: "Two.", in: made.course)
        try write(page: "Unit 1, Day 3", publish: "true", date: "2026-09-14", body: "Three.", in: made.course)

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "unpublish_pages",
            arguments: ["course": "ICS3U", "section": 1, "onOrAfter": "2026-09-10"]
        ))
        XCTAssertFalse(outcome.shouldContinue)
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: true"))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 2", in: made.course).contains("publish: false"))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 3", in: made.course).contains("publish: false"))
    }

    /// Undo puts exactly those pages back — and leaves alone anything the
    /// teacher has edited since, because losing ten minutes of their writing to
    /// "undo that" would be far worse than not undoing at all.
    @MainActor
    func testUndoPutsPagesBackAndLeavesNewerWorkAlone() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        try write(page: "Unit 1, Day 1", publish: "false", body: "One.", in: made.course)
        try write(page: "Unit 1, Day 2", publish: "false", body: "Two.", in: made.course)

        let nothingYet: AssistToolOutcome = await made.runner.run(call: call("undo_last_change"))
        XCTAssertTrue(nothingYet.summary.contains("nothing to undo"))

        _ = await made.runner.run(call: call(
            "publish_pages",
            arguments: ["course": "ICS3U", "section": 1,
                        "pages": "Unit 1, Day 1; Unit 1, Day 2"]
        ))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: true"))

        let undone: AssistToolOutcome = await made.runner.run(call: call("undo_last_change"))
        XCTAssertFalse(undone.shouldContinue)
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 2", in: made.course).contains("publish: false"))

        // Now publish again, edit one of them the way a teacher would, and undo.
        _ = await made.runner.run(call: call(
            "publish_pages",
            arguments: ["course": "ICS3U", "section": 1,
                        "pages": "Unit 1, Day 1; Unit 1, Day 2"]
        ))
        let edited: String = text(ofPage: "Unit 1, Day 2", in: made.course) + "\n\nWritten since.\n"
        try edited.write(
            to: ClassPages.folderURL(forSection: 1, in: made.course)
                .appendingPathComponent("Unit 1, Day 2.md"),
            atomically: true, encoding: .utf8
        )

        let partly: AssistToolOutcome = await made.runner.run(call: call("undo_last_change"))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 2", in: made.course).contains("Written since."),
                      "Newer work is never thrown away by an undo.")
        XCTAssertTrue(partly.detail.contains("left alone"))
    }

    // MARK: - Backing up, once per conversation

    /// One conversation, one backup — however many commands it runs.
    ///
    /// A vault full of images makes a slow, fat zip, and a chat with six
    /// commands in it used to make six near-identical ones. The first write
    /// saves the copy; the undo history covers everything after it.
    @MainActor
    func testAConversationWithThreeWritesBacksUpExactlyOnce() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }
        let coursesDirectoryURL: URL = made.root.appendingPathComponent("courses")

        try write(page: "Unit 1, Day 1", publish: "false", body: "One.", in: made.course)
        try write(page: "Unit 1, Day 2", publish: "false", body: "Two.", in: made.course)

        _ = await made.runner.run(call: call(
            "publish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))
        _ = await made.runner.run(call: call(
            "publish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 2"]
        ))
        let third: AssistToolOutcome = await made.runner.run(call: call(
            "unpublish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))

        // All three really wrote.
        XCTAssertTrue(text(ofPage: "Unit 1, Day 1", in: made.course).contains("publish: false"))
        XCTAssertTrue(text(ofPage: "Unit 1, Day 2", in: made.course).contains("publish: true"))
        XCTAssertTrue(third.detail.contains("backed up"),
                      "Every write still tells the teacher there is a way back")

        let backups: [BackupItem] = WorkspaceModel.findBackupItems(in: coursesDirectoryURL)
        XCTAssertEqual(backups.count, 1, "Three writes in one chat make ONE backup")
        XCTAssertEqual(backups[0].maker, .assistant(sectionNumber: 1),
                       "And it says who made it, and what it was for")

        // What the assistant's window reads to offer a way back to where the
        // conversation started.
        XCTAssertTrue(made.runner.hasConversationBackup)
        // Compared by name: the temporary folder is reached through a symlink,
        // so the two URLs spell the same file differently.
        XCTAssertEqual(made.runner.conversationBackupURL?.lastPathComponent,
                       backups[0].fileURL.lastPathComponent)
    }

    /// A conversation that only reads makes no backup at all — there is
    /// nothing to go back from.
    @MainActor
    func testAReadOnlyConversationMakesNoBackup() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }
        let coursesDirectoryURL: URL = made.root.appendingPathComponent("courses")

        try write(page: "Unit 1, Day 1", publish: "false", body: "One.", in: made.course)

        _ = await made.runner.run(call: call(
            "list_pages", arguments: ["course": "ICS3U", "section": 1]
        ))
        _ = await made.runner.run(call: call(
            "read_page", arguments: ["course": "ICS3U", "section": 1, "page": "Unit 1, Day 1"]
        ))
        _ = await made.runner.run(call: call(
            "check_section", arguments: ["course": "ICS3U", "section": 1]
        ))
        _ = await made.runner.run(call: call(
            "plan_publish_pages",
            arguments: ["course": "ICS3U", "section": 1, "pages": "Unit 1, Day 1"]
        ))

        XCTAssertEqual(
            WorkspaceModel.findBackupItems(in: coursesDirectoryURL).count, 0,
            "Reading — and planning, which changes nothing — copies nothing"
        )
        XCTAssertFalse(made.runner.hasConversationBackup)
        XCTAssertNil(made.runner.conversationBackupURL)
    }

    /// The gate is the tool's own answer, not a list kept beside it, and the
    /// explanation is the sentence the teacher reads before pressing anything.
    @MainActor
    func testDeployingAsksForAButtonAndSaysWhyInPlainWords() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        let definition: AssistToolDefinition = try XCTUnwrap(made.runner.definition(named: "deploy_section"))
        XCTAssertTrue(definition.needsApproval)

        let explanation: String = made.runner.explain(call: call(
            "deploy_section", arguments: ["course": "ICS3U", "section": 1]
        ))
        XCTAssertTrue(explanation.contains("ICS3U Section 1"))
        XCTAssertTrue(explanation.contains("students"))

        // Approved, it runs — through the app's own script runner, stubbed here
        // so a unit test never starts Docker.
        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "deploy_section", arguments: ["course": "ICS3U", "section": 1]
        ))
        XCTAssertFalse(outcome.shouldContinue)
        XCTAssertEqual(made.siteWork.deploys, 1)
    }

    /// A deploy set for later goes through the app's own launchd machinery, and
    /// the plan names the classes it would ship WITHOUT — which is the whole
    /// value of planning it: a deploy that runs perfectly at half six and puts
    /// up a site missing tomorrow's class is the failure worth catching while
    /// somebody is awake.
    @MainActor
    func testPlanningAndSettingADeployForLater() async throws {
        let made = try makeRunner(hasDeployedBefore: true)
        defer {
            try? FileManager.default.removeItem(at: made.root)
            ScheduledDeploy.launchAgentsDirectoryOverride = nil
        }
        ScheduledDeploy.launchAgentsDirectoryOverride = made.root.appendingPathComponent("LaunchAgents")

        try write(page: "Unit 1, Day 1", publish: "false", body: "One.", in: made.course)

        let planned: AssistToolOutcome = await made.runner.run(call: call(
            "plan_scheduled_deploy",
            arguments: ["course": "ICS3U", "section": 1,
                        "when": "2030-09-09 06:30", "classes": "Unit 1, Day 1"]
        ))
        XCTAssertTrue(planned.shouldContinue, "A plan is a read.")
        XCTAssertTrue(planned.detail.contains("NOT published, so the deploy would ship without it."))
        XCTAssertTrue(planned.detail.contains("awake"))
        XCTAssertTrue(planned.detail.contains("Nothing has been changed."))

        // Nothing is set by planning it.
        XCTAssertNil(ScheduledDeploy.nextRun(courseCode: "ICS3U", sectionNumber: 1))

        let set: AssistToolOutcome = await made.runner.run(call: call(
            "schedule_deploy",
            arguments: ["course": "ICS3U", "section": 1, "when": "2030-09-09 06:30"]
        ))
        XCTAssertFalse(set.shouldContinue)
        XCTAssertTrue(set.summary.contains("Scheduled:"))
        XCTAssertNotNil(ScheduledDeploy.nextRun(courseCode: "ICS3U", sectionNumber: 1))

        let cancelled: AssistToolOutcome = await made.runner.run(call: call(
            "cancel_scheduled_deploy", arguments: ["course": "ICS3U", "section": 1]
        ))
        XCTAssertTrue(cancelled.summary.contains("Cancelled"))
        XCTAssertNil(ScheduledDeploy.nextRun(courseCode: "ICS3U", sectionNumber: 1))
    }

    /// Everything a scheduled deploy would ASK at half six is asked now
    /// instead. A section nobody has deployed yet would sit at a prompt with
    /// nobody there, so it is refused before anything is written.
    @MainActor
    func testADeployThatWouldAskAQuestionAtNightIsRefusedNow() async throws {
        let made = try makeRunner()
        defer {
            try? FileManager.default.removeItem(at: made.root)
            ScheduledDeploy.launchAgentsDirectoryOverride = nil
        }
        ScheduledDeploy.launchAgentsDirectoryOverride = made.root.appendingPathComponent("LaunchAgents")

        let refused: AssistToolOutcome = await made.runner.run(call: call(
            "schedule_deploy",
            arguments: ["course": "ICS3U", "section": 1, "when": "2030-09-09 06:30"]
        ))
        XCTAssertTrue(refused.summary.contains("Nothing was scheduled."))
        XCTAssertTrue(refused.summary.contains("never been deployed"))
        XCTAssertNil(ScheduledDeploy.nextRun(courseCode: "ICS3U", sectionNumber: 1))

        // Cancelling when nothing is set is safe, and says so.
        let cancelled: AssistToolOutcome = await made.runner.run(call: call(
            "cancel_scheduled_deploy", arguments: ["course": "ICS3U", "section": 1]
        ))
        XCTAssertTrue(cancelled.summary.contains("no deploy scheduled"))

        // A time nobody could read is a sentence, not a schema error.
        let unreadable: AssistToolOutcome = await made.runner.run(call: call(
            "schedule_deploy",
            arguments: ["course": "ICS3U", "section": 1, "when": "half six tomorrow"]
        ))
        XCTAssertTrue(unreadable.summary.contains("isn't a time I can read"))
    }

    /// A course the teacher does not have is a sentence, not a stack trace.
    @MainActor
    func testAnUnknownCourseIsRefusedInWords() async throws {
        let made = try makeRunner()
        defer { try? FileManager.default.removeItem(at: made.root) }

        let outcome: AssistToolOutcome = await made.runner.run(call: call(
            "check_section", arguments: ["course": "MPM2D", "section": 1]
        ))
        XCTAssertTrue(outcome.detail.contains("no course called “MPM2D”"))

        let unknownTool: AssistToolOutcome = await made.runner.run(call: call("set_publish"))
        XCTAssertTrue(unknownTool.detail.contains("no tool called"))
    }

    // MARK: - Fixtures

    /// Records what it was asked to do instead of starting Docker.
    @MainActor
    final class StubSiteWork: AssistSiteWork {

        // MARK: - Stored properties

        private(set) var previewRebuilds: Int = 0
        private(set) var deploys: Int = 0

        // MARK: - Functions

        func rebuildPreview(course: Course, sectionNumber: Int) async -> AssistSiteWorkResult {
            previewRebuilds += 1
            return AssistSiteWorkResult(succeeded: true, message: "Rebuilt the preview.")
        }

        func deploy(course: Course, sectionNumber: Int) async -> AssistSiteWorkResult {
            deploys += 1
            return AssistSiteWorkResult(succeeded: true, message: "Deployed.")
        }
    }

    /// Watches what would be asked of launchd without asking it.
    struct SilentLaunchControl: LaunchControlRunning {
        func bootstrap(plistURL: URL) -> String? {
            return nil
        }

        func bootOut(label: String) {
        }
    }

    @MainActor
    private func makeRunner(hasDeployedBefore: Bool = false) throws
        -> (root: URL, course: Course, runner: AssistToolRunner, siteWork: StubSiteWork) {
        let fileManager: FileManager = FileManager.default
        let root: URL = fileManager.temporaryDirectory
            .appendingPathComponent("assist-tools-\(UUID().uuidString)")
        let courseURL: URL = root.appendingPathComponent("courses").appendingPathComponent("ICS3U")
        try fileManager.createDirectory(
            at: courseURL.appendingPathComponent("section1/All Classes"), withIntermediateDirectories: true
        )
        try fileManager.createDirectory(
            at: courseURL.appendingPathComponent("Concepts"), withIntermediateDirectories: true
        )
        // A working folder is recognised by its launchers; a stub is enough,
        // and nothing in these tests ever runs one.
        try "#!/bin/bash\n".write(
            to: root.appendingPathComponent("preview.sh"), atomically: true, encoding: .utf8
        )
        try "#!/bin/bash\n".write(
            to: root.appendingPathComponent("deploy.sh"), atomically: true, encoding: .utf8
        )
        if hasDeployedBefore {
            // The marker `deploy.py` leaves the first time a section goes out.
            // Without it, scheduling is refused — deploying a section for the
            // first time asks what to call the website.
            try fileManager.createDirectory(
                at: courseURL.appendingPathComponent(".netlify_sites"), withIntermediateDirectories: true
            )
            try "{}".write(
                to: courseURL.appendingPathComponent(".netlify_sites/section1.json"),
                atomically: true, encoding: .utf8
            )
        }

        let configuration: [String: Any] = [
            "course_code": "ICS3U",
            "course_name": "Introduction to Computer Science",
            "section_numbers": [1],
            "num_sections": 1,
            "per_section_folders": ["All Classes"],
            "per_section_files": [],
        ]
        try JSONSerialization.data(withJSONObject: configuration, options: [.prettyPrinted])
            .write(to: courseURL.appendingPathComponent("course_config.json"))

        let workspace: WorkspaceModel = WorkspaceModel(defaults: TestDefaults.make())
        workspace.chooseWorkspace(at: root)
        let course: Course = try XCTUnwrap(workspace.courses.first)

        let siteWork: StubSiteWork = StubSiteWork()
        let runner: AssistToolRunner = AssistToolRunner(
            workspace: workspace,
            siteWork: siteWork,
            today: CalendarDay(year: 2026, month: 9, day: 8)!,
            launchControl: SilentLaunchControl()
        )
        return (root, course, runner, siteWork)
    }

    private func call(_ name: String, arguments: [String: Any] = [:]) -> AssistToolCall {
        let encoded: Data = (try? JSONSerialization.data(withJSONObject: arguments)) ?? Data("{}".utf8)
        return AssistToolCall(
            id: UUID().uuidString,
            type: "function",
            function: AssistToolCall.Function(
                name: name, arguments: String(decoding: encoded, as: UTF8.self)
            )
        )
    }

    @MainActor
    private func write(page title: String,
                       publish: String,
                       date: String = "2026-09-08",
                       body: String,
                       in course: Course) throws {
        let text: String = """
        ---
        title: \(title)
        publish: \(publish)
        created: \(date)T07:00:00.000-0400
        ---

        \(body)
        """
        try text.write(
            to: ClassPages.folderURL(forSection: 1, in: course).appendingPathComponent(title + ".md"),
            atomically: true, encoding: .utf8
        )
    }

    /// A page in the section's own folder rather than in its classes folder —
    /// which is where a real course keeps `Key Links.md`. Section-local, so it
    /// carries the plain `publish:` key.
    @MainActor
    private func write(sectionPage title: String,
                       publish: String,
                       body: String,
                       in course: Course) throws {
        let text: String = """
        ---
        title: \(title)
        publish: \(publish)
        ---

        \(body)
        """
        try text.write(
            to: course.sectionDirectoryURL(forSection: 1).appendingPathComponent(title + ".md"),
            atomically: true, encoding: .utf8
        )
    }

    @MainActor
    private func write(courseLevelPage title: String,
                       inFolder folder: String = "Concepts",
                       publishForSection1: String,
                       body: String,
                       in course: Course) throws {
        let text: String = """
        ---
        title: \(title)
        publishForSection1: \(publishForSection1)
        createdSection1: 2026-09-08T07:00:00.000-0400
        ---

        \(body)
        """
        let folderURL: URL = course.directoryURL.appendingPathComponent(folder)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        try text.write(
            to: folderURL.appendingPathComponent(title + ".md"),
            atomically: true, encoding: .utf8
        )
    }

    @MainActor
    private func text(ofPage title: String, in course: Course) -> String {
        let url: URL = ClassPages.folderURL(forSection: 1, in: course)
            .appendingPathComponent(title + ".md")
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    @MainActor
    private func text(ofCourseLevelPage title: String,
                      inFolder folder: String = "Concepts",
                      in course: Course) -> String {
        let url: URL = course.directoryURL.appendingPathComponent(folder)
            .appendingPathComponent(title + ".md")
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
}
