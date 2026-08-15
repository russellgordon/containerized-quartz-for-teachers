import Foundation

/// The fifteen tools, exactly as the local model sees them.
///
/// The descriptions are the Windows server's own, put through the same
/// shortening rule the narrowed surface uses there: keep the `TEACHERS SAY:`
/// clause whole, then the first sentence of the rest, and nothing else.
///
/// The `TEACHERS SAY` phrasings are load-bearing rather than decorative — they
/// are what took routing from 69% to 91% — so they are COPIED, not improved.
/// The temptation to reword one is the temptation to spend a measurement
/// somebody else already paid for.
///
/// Two deliberate departures from the Windows schema, both forced by the shape
/// of the tool surface here:
///
/// * Lists of page names are semicolon-separated strings. The schema this
///   client speaks has strings, integers and booleans and no arrays — and a
///   COMMA-separated list would cut "Unit 2, Day 3" in half, which is the name
///   nearly every class page in these courses has.
/// * There is no `preview` flag. On Windows a batch of edits can be made with
///   the preview suppressed and rebuilt once at the end; here every change
///   rebuilds, which is what the assistant's own system prompt promises a
///   teacher, and it is one fewer boolean on a surface where booleans are the
///   thing that goes wrong.
extension AssistToolRunner {

    // MARK: - The surface

    static let tools: [AssistToolDefinition] = [
        listPagesTool,
        readPageTool,
        checkSectionTool,
        planPublishClassOnTool,
        publishClassOnTool,
        planPublishPagesTool,
        publishPagesTool,
        planUnpublishPagesTool,
        unpublishPagesTool,
        rebuildPreviewTool,
        undoLastChangeTool,
        deploySectionTool,
        planScheduledDeployTool,
        scheduleDeployTool,
        cancelScheduledDeployTool,
    ]

    // MARK: - Shared argument wording

    private static let courseHelp: AssistSchemaProperty = AssistSchemaProperty(
        kind: .string, description: "The course code, for example ICS3U."
    )

    private static let sectionHelp: AssistSchemaProperty = AssistSchemaProperty(
        kind: .integer, description: "The section number, for example 1."
    )

    private static let dateHelp: String =
        "A date as YYYY-MM-DD, for example 2026-09-15. Leave empty for no limit."

    private static let classDateHelp: AssistSchemaProperty = AssistSchemaProperty(
        kind: .string,
        description: "The day the class is taught, as YYYY-MM-DD. For \"tomorrow\" or \"today\", work out "
                   + "the date first — the tool matches it exactly against each class's own date."
    )

    private static let whenHelp: AssistSchemaProperty = AssistSchemaProperty(
        kind: .string,
        description: "When to deploy, as YYYY-MM-DD HH:MM in 24-hour time — for example "
                   + "\"2026-09-09 06:30\"."
    )

    /// Semicolons, because "Unit 2, Day 3" is a page name and a comma-separated
    /// list of those names is a list of nonsense.
    private static func pagesHelp(_ verb: String) -> AssistSchemaProperty {
        return AssistSchemaProperty(
            kind: .string,
            description: "The page titles to \(verb), separated by semicolons — for example "
                       + "\"Unit 2, Day 3; Unit 2, Day 4\". May be empty if you give dates instead."
        )
    }

    private static func includeLinkedHelp(_ verb: String) -> AssistSchemaProperty {
        return AssistSchemaProperty(
            kind: .boolean,
            description: "True to also \(verb) every page these pages link to. Choose deliberately; "
                       + "there is no default."
        )
    }

    private static let onOrAfterHelp: AssistSchemaProperty = AssistSchemaProperty(
        kind: .string, description: "Only classes on or after this date. " + dateHelp
    )

    private static let beforeHelp: AssistSchemaProperty = AssistSchemaProperty(
        kind: .string, description: "Only classes strictly before this date. " + dateHelp
    )

    // MARK: - Looking around

    private static let listPagesTool: AssistToolDefinition = AssistToolDefinition(
        name: "list_pages",
        description: "List the pages in one section of a course, as paths relative to the working folder.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "matching": AssistSchemaProperty(
                kind: .string,
                description: "Only list pages whose path contains this text. Leave empty to list everything."
            ),
        ],
        required: ["course", "section"],
        readOnly: true,
        needsApproval: false
    )

    private static let readPageTool: AssistToolDefinition = AssistToolDefinition(
        name: "read_page",
        description: "Read one page's Markdown, including its frontmatter.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "page": AssistSchemaProperty(
                kind: .string,
                description: "The page title as it appears in the sidebar, for example \"Unit 2, Day 3\"."
            ),
        ],
        required: ["course", "section", "page"],
        readOnly: true,
        needsApproval: false
    )

    private static let checkSectionTool: AssistToolDefinition = AssistToolDefinition(
        name: "check_section",
        description: "TEACHERS SAY: \"what do students see right now?\", \"is anything broken?\", "
                   + "\"what's live?\". Check a section's website as students would meet it, "
                   + "changing nothing.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
        ],
        required: ["course", "section"],
        readOnly: true,
        needsApproval: false
    )

    // MARK: - The commonest request of all

    private static let planPublishClassOnTool: AssistToolDefinition = AssistToolDefinition(
        name: "plan_publish_class_on",
        description: "TEACHERS SAY: \"what would publishing tomorrow's class do?\", \"show me before you "
                   + "put Monday up\". Work out what publishing the class taught on a given day would do, "
                   + "WITHOUT changing anything.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "date": classDateHelp,
        ],
        required: ["course", "section", "date"],
        readOnly: true,
        needsApproval: false
    )

    private static let publishClassOnTool: AssistToolDefinition = AssistToolDefinition(
        name: "publish_class_on",
        description: "TEACHERS SAY: \"publish tomorrow's class\", \"put up Monday's lesson\", \"put Unit 2, "
                   + "Day 3 up\", \"make Friday's class visible\", \"post next class\", \"put the class live "
                   + "for students\". Publish the class taught on a given day, along with the pages it links "
                   + "to, then rebuild the section's preview.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "date": classDateHelp,
        ],
        required: ["course", "section", "date"],
        readOnly: false,
        needsApproval: false
    )

    // MARK: - Publishing, and its own separate opposite

    private static let planPublishPagesTool: AssistToolDefinition = AssistToolDefinition(
        name: "plan_publish_pages",
        description: "Work out exactly what publishing pages would do, WITHOUT changing anything.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "includeLinked": includeLinkedHelp("publish"),
            "pages": pagesHelp("publish"),
            "onOrAfter": onOrAfterHelp,
            "before": beforeHelp,
        ],
        required: ["course", "section", "includeLinked"],
        readOnly: true,
        needsApproval: false
    )

    private static let publishPagesTool: AssistToolDefinition = AssistToolDefinition(
        name: "publish_pages",
        description: "Make pages visible to students, optionally along with every page they link to, then "
                   + "rebuild the section preview.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "includeLinked": includeLinkedHelp("publish"),
            "pages": pagesHelp("publish"),
            "onOrAfter": onOrAfterHelp,
            "before": beforeHelp,
        ],
        required: ["course", "section", "includeLinked"],
        readOnly: false,
        needsApproval: false
    )

    private static let planUnpublishPagesTool: AssistToolDefinition = AssistToolDefinition(
        name: "plan_unpublish_pages",
        description: "TEACHERS SAY: \"what happens if I take that down?\", \"check before you hide Unit 3, "
                   + "Day 2\". Work out exactly what unpublishing pages from students would do, WITHOUT "
                   + "changing anything.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "includeLinked": includeLinkedHelp("unpublish"),
            "pages": pagesHelp("unpublish"),
            "onOrAfter": onOrAfterHelp,
            "before": beforeHelp,
        ],
        required: ["course", "section", "includeLinked"],
        readOnly: true,
        needsApproval: false
    )

    private static let unpublishPagesTool: AssistToolDefinition = AssistToolDefinition(
        name: "unpublish_pages",
        description: "TEACHERS SAY: \"take Unit 4, Day 5 back down\", \"students shouldn't see it yet\", "
                   + "\"hide that page\", \"I posted it by mistake\", \"make it a draft again\", \"pull that "
                   + "lesson\", \"un-publish it\". Unpublish pages, so students no longer see them, "
                   + "optionally along with every page they link to, then rebuild the section preview.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "includeLinked": includeLinkedHelp("unpublish"),
            "pages": pagesHelp("unpublish"),
            "onOrAfter": onOrAfterHelp,
            "before": beforeHelp,
        ],
        required: ["course", "section", "includeLinked"],
        readOnly: false,
        needsApproval: false
    )

    // MARK: - Preview and undo

    private static let rebuildPreviewTool: AssistToolDefinition = AssistToolDefinition(
        name: "rebuild_preview",
        description: "TEACHERS SAY: \"preview the site\", \"show me the preview\", \"start the preview\", "
                   + "\"open the preview\", \"rebuild the preview\", \"refresh what I'm looking at\", "
                   + "\"update the preview\", \"build it again\". Build a section's preview and put it on "
                   + "screen, without changing any page.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
        ],
        required: ["course", "section"],
        readOnly: false,
        needsApproval: false
    )

    private static let undoLastChangeTool: AssistToolDefinition = AssistToolDefinition(
        name: "undo_last_change",
        description: "TEACHERS SAY: \"undo that\", \"put it back\", \"that was wrong, revert it\", \"never "
                   + "mind, undo\". Take back the most recent change this conversation made — the fix for "
                   + "publishing the wrong class in a hurry.",
        parameters: [:],
        required: [],
        readOnly: false,
        needsApproval: false
    )

    // MARK: - The one act that asks for a button

    private static let deploySectionTool: AssistToolDefinition = AssistToolDefinition(
        name: "deploy_section",
        description: "TEACHERS SAY: \"deploy the site\", \"put it online\", \"push it live\", \"send it to "
                   + "the website\", \"make it live for students\", \"upload the site\". Put a section's "
                   + "website where students can actually reach it.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
        ],
        required: ["course", "section"],
        readOnly: false,
        // Deploying is the one act that puts something in front of students
        // immediately and that Plantoir cannot undo for them.
        needsApproval: true
    )

    // MARK: - Deploying later

    private static let planScheduledDeployTool: AssistToolDefinition = AssistToolDefinition(
        name: "plan_scheduled_deploy",
        description: "TEACHERS SAY: \"what happens if I schedule it for 6:30?\", \"check before you set "
                   + "that up\". Work out what scheduling a deploy would mean, scheduling nothing.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "when": whenHelp,
            "classes": AssistSchemaProperty(
                kind: .string,
                description: "The class pages this deploy is meant to publish, separated by semicolons. "
                           + "Checked for whether they are published yet."
            ),
        ],
        required: ["course", "section", "when"],
        readOnly: true,
        needsApproval: false
    )

    private static let scheduleDeployTool: AssistToolDefinition = AssistToolDefinition(
        name: "schedule_deploy",
        description: "TEACHERS SAY: \"deploy tomorrow's class at 6:30 AM\", \"put it live before school\", "
                   + "\"send it out at 7am\", \"schedule the deploy for Monday morning\". Ask this computer "
                   + "to deploy a section at a set time.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
            "when": whenHelp,
        ],
        required: ["course", "section", "when"],
        readOnly: false,
        // A deploy that runs while nobody is watching is still a deploy.
        needsApproval: true
    )

    private static let cancelScheduledDeployTool: AssistToolDefinition = AssistToolDefinition(
        name: "cancel_scheduled_deploy",
        description: "TEACHERS SAY: \"cancel that scheduled deploy\", \"don't send it in the morning after "
                   + "all\", \"call it off\". Call off a deploy that was scheduled for a section.",
        parameters: [
            "course": courseHelp,
            "section": sectionHelp,
        ],
        required: ["course", "section"],
        readOnly: false,
        needsApproval: false
    )
}
