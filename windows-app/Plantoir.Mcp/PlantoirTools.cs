using System.ComponentModel;
using System.Text;
using ModelContextProtocol;
using ModelContextProtocol.Server;
using Plantoir.Core.Assist;

namespace Plantoir.Mcp;

/// <summary>
/// The tools an assistant may call.
///
/// Four rules shape this surface. The first three are measured (AI-ASSIST.md
/// has the numbers); the fourth came from watching a real teacher use it.
///
/// 1. **Nothing destructive exists.** No delete, no archive, no rename. In
///    testing the model reliably declined "delete the Unit 1 folder" — not
///    from judgement, but because it had no tool for it. Absence is the
///    strongest guardrail available, so it is the one relied on.
///
/// 2. **Publishing and unpublishing are separate tools, not a flag.** The one
///    genuinely dangerous failure observed was polarity inversion: asked to
///    HIDE a page, the model called publish with "include everything it links
///    to" set. A boolean is a coin flip under pressure; a verb is not.
///
/// 3. **Every write has a matching plan_ tool that changes nothing**, and the
///    plan is written to be read aloud to the teacher.
///
/// 4. **The write tools take a LIST, and take any page.** Single-page tools
///    turned one logical change into 26 deploys, and could not express "hide
///    these classes but leave the safety contract up" at all — a shared page
///    linked from both a protected class and a unpublished one is the normal shape
///    of a course.
///
/// Instance methods get a fresh instance per call, so the workspace comes from
/// the injected singleton rather than any state kept here.
/// </summary>
[McpServerToolType]
public sealed class PlantoirTools(AssistWorkspace workspace)
{
    // ---- Looking around --------------------------------------------------

    [McpServerTool(Name = "list_courses", Title = "List courses", ReadOnly = true, Destructive = false)]
    [Description("List the teacher's courses in this working folder: code, name, sections, and where each one publishes to. " +
                 "Call this first when the teacher mentions a course but you are not certain of its exact code.")]
    public string ListCourses()
    {
        var courses = workspace.Courses();
        if (courses.Count == 0) return "This working folder has no courses yet.";

        var text = new StringBuilder();
        foreach (var course in courses)
        {
            var configuration = course.Configuration;
            string destination = configuration.DeploysToLocalFolder ? "a folder on this computer"
                : configuration.DeploysToCloudflare ? "Cloudflare Pages" : "Netlify";
            text.AppendLine($"{course.Code} — {configuration.CourseName}");
            text.AppendLine($"  sections: {string.Join(", ", course.SectionNumbers)}");
            text.AppendLine($"  publishes to: {destination}");
        }
        return text.ToString().TrimEnd();
    }

    /// <summary>
    /// A course runs to a couple of hundred pages — the sample course alone
    /// has 198, most of them curriculum expectations nobody is asking about.
    /// Returning all of them buries the answer and, for a small local model,
    /// fills the context before the question is even considered.
    /// </summary>
    private const int MostPagesListed = 60;

    [McpServerTool(Name = "list_pages", Title = "List pages in a section", ReadOnly = true, Destructive = false)]
    [Description("List the pages in one section of a course, as paths relative to the working folder. " +
                 "Use this to find the exact title of a page before acting on it. " +
                 "Courses hold hundreds of pages, so pass `matching` to narrow the list — for example \"Unit 2\" " +
                 "for that unit's classes.")]
    public string ListPages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("Only list pages whose path contains this text. Leave empty to list everything.")]
        string matching = "")
        => Guarded(() =>
        {
            var found = workspace.Course(course);
            int number = workspace.Section(found, section);
            var pages = workspace.Pages(found, number);

            string filter = matching.Trim();
            if (filter.Length > 0)
                pages = pages.Where(p => p.Contains(filter, StringComparison.OrdinalIgnoreCase)).ToList();

            if (pages.Count == 0)
                return filter.Length > 0
                    ? $"No page in {found.Code} Section {number} matches “{filter}”."
                    : $"{found.Code} Section {number} has no pages.";

            var shown = pages.Take(MostPagesListed).ToList();
            var text = new StringBuilder(string.Join("\n", shown));
            if (pages.Count > shown.Count)
                text.Append($"\n\n…and {pages.Count - shown.Count} more of {pages.Count}. " +
                            "Pass `matching` to narrow this down.");
            return text.ToString();
        });

    [McpServerTool(Name = "read_page", Title = "Read a page", ReadOnly = true, Destructive = false)]
    [Description("Read one page's Markdown, including its frontmatter. Use this to see what a class page's agenda links to, " +
                 "and to see which key governs the page: a page under section1/ carries `publish:`, while a course-level " +
                 "page such as a Concept carries `publishForSection1:` and `publishForSection2:` — one flag per section. " +
                 "Older courses carry `draft:` and `draftSection1:` instead, which mean the OPPOSITE — `draft: true` is a " +
                 "page students cannot see. Both are understood; report what you find without rewriting it yourself.")]
    public string ReadPage(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The page title as it appears in the sidebar, for example \"Unit 2, Day 3\".")] string page)
        => Guarded(() =>
        {
            var found = workspace.Course(course);
            return workspace.ReadPage(found, workspace.Section(found, section), page);
        });

    [McpServerTool(Name = "deploy_section", Title = "Deploy a section's website",
                   Destructive = false, Idempotent = true)]
    [Description("Put a section's website where students can actually reach it. This is the one thing that changes " +
                 "what students see, so treat it as a big step. " +
                 "\n\nBEFORE calling this, tell the teacher plainly to look over the preview in Plantoir first, and " +
                 "wait for them to say they have. Publishing a page only rebuilds their preview; this is what makes " +
                 "it real. If they have not looked, say so and offer to wait rather than going ahead. " +
                 "\n\nThis takes several minutes.")]
    public async Task<string> DeploySection(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation)
    {
        try
        {
            var result = await workspace.Deploy(course, section, Relay(progress), cancellation);
            progress.Report(new ProgressNotificationValue { Progress = 100, Total = 100, Message = "Finished" });
            return result.Message;
        }
        catch (AssistRefusal refusal) { return refusal.Message; }
        catch (OperationCanceledException) { return "The deploy was stopped before it finished."; }
    }

    [McpServerTool(Name = "explain_publishing", Title = "Explain what publishing means here",
                   Destructive = false, Idempotent = true)]
    [Description("Call this FIRST, before doing anything else with a section. It returns a short explanation of " +
                 "what publishing and deploying mean in Plantoir — say it to the teacher word for word. " +
                 "It only returns the explanation the first time for a given section; after that it says so and " +
                 "you should get straight on with what they asked. Never re-explain a section you have been told " +
                 "is already covered.")]
    public string ExplainPublishing(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section)
        => Guarded(() =>
        {
            var found = workspace.Course(course);
            int number = workspace.Section(found, section);
            if (Briefing.AlreadyExplained(workspace.FolderPath, found.Code, number))
                return $"{found.Code} Section {number} has had this explained already. " +
                       "Don’t repeat it — carry on with what the teacher asked.";

            var configuration = found.Configuration;
            string destination = configuration.DeploysToLocalFolder ? "the folder you publish into"
                : configuration.DeploysToCloudflare ? "Cloudflare Pages" : "Netlify";
            Briefing.MarkExplained(workspace.FolderPath, found.Code, number);
            return Briefing.Words(found.Code, number, destination);
        });

    /// <summary>How many of each kind to name before summarising.</summary>
    private const int MostListed = 15;

    [McpServerTool(Name = "check_section", Title = "Check what students would see",
                   ReadOnly = true, Destructive = false)]
    [Description("Check a section's website as students would meet it, changing nothing. Reports two things that " +
                 "publishing and unpublishing tools cannot see for themselves: links on visible pages that lead to a hidden " +
                 "page (students click and find nothing), and pages nothing links to — which are still published and " +
                 "still listed in the site's explorer, so students can see them even though no class points there. " +
                 "Use this before a term starts, and after any bulk change.")]
    public string CheckSection(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section)
        => Guarded(() =>
        {
            var found = workspace.Course(course);
            int number = workspace.Section(found, section);
            var (graph, isHidden) = workspace.Inspect(found, number);

            var dangling = graph.DanglingLinks(isHidden);
            var orphans = graph.Unreferenced().Where(p => !isHidden(p)).ToList();

            var text = new StringBuilder();
            text.AppendLine($"{found.Code} Section {number}: {graph.Pages.Count} pages, " +
                            $"{graph.Pages.Count(p => !isHidden(p))} visible to students.");
            text.AppendLine();

            if (dangling.Count == 0)
                text.AppendLine("No visible page links to a unpublished one.");
            else
            {
                text.AppendLine($"{dangling.Count} link{(dangling.Count == 1 ? "" : "s")} " +
                                "would take a student to a page that isn’t there:");
                foreach (var link in dangling.Take(MostListed))
                    text.AppendLine($"  {workspace.Relative(link.From)}  →  " +
                                    $"{Path.GetFileNameWithoutExtension(link.To)}  (hidden)");
                if (dangling.Count > MostListed)
                    text.AppendLine($"  …and {dangling.Count - MostListed} more.");
            }
            text.AppendLine();

            if (orphans.Count == 0)
                text.AppendLine("Every visible page is linked from somewhere.");
            else
            {
                text.AppendLine($"{orphans.Count} visible page{(orphans.Count == 1 ? " is" : "s are")} " +
                                "linked from nowhere. Students can still reach these through the site’s " +
                                "explorer, and no publish or hide rule that follows links will ever touch them:");
                foreach (string page in orphans.Take(MostListed))
                    text.AppendLine("  " + workspace.Relative(page));
                if (orphans.Count > MostListed)
                    text.AppendLine($"  …and {orphans.Count - MostListed} more.");
            }
            return text.ToString().TrimEnd();
        });

    // ---- Rolling a course onto a real timetable --------------------------

    private const string TimetableHelp =
        "A link to the timetable spreadsheet, or the path to a CSV of it on this computer. " +
        "A Google Sheets link works if the sheet is shared so anyone with the link can view it.";

    private const string BlockHelp =
        "The block or section letter the teacher is timetabled in, for example F.";

    private const string UnitHelp = "The unit number these classes belong to, for example 2.";

    [McpServerTool(Name = "plan_make_room_for_classes", Title = "Plan making room for classes",
                   ReadOnly = true, Destructive = false)]
    [Description("Work out what would happen if a class were inserted part-way through a unit, changing nothing. " +
                 "Use this for \"duplicate Unit 2, Day 2 and make it the third class, pushing everything back\", " +
                 "or \"give this unit another day\". Later days of the SAME unit are renamed; every class after " +
                 "the insertion point, later units included, moves onto a later day the class actually meets. " +
                 "\n\nThis is the most far-reaching change there is — it renames pages other pages link to — so " +
                 "read the whole plan to the teacher, word for word, and wait. The link count especially: they " +
                 "cannot check that themselves without opening every page in the course.")]
    public string PlanMakeRoomForClasses(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(UnitHelp)] int unit,
        [Description("The day number the new class takes. Existing days from here on are renumbered.")] int atDay,
        [Description("How many classes to make room for. 1 unless the teacher asked for more.")] int howMany = 1)
        => Guarded(() => workspace.PlanInsertClasses(course, section, unit, atDay, howMany).Describe());

    [McpServerTool(Name = "make_room_for_classes", Title = "Make room for classes",
                   Destructive = false, Idempotent = false)]
    [Description("Insert one or more classes part-way through a unit: rename the later days of that unit, " +
                 "update every link that pointed at them, move the classes that follow onto later class days, " +
                 "and create the new pages unpublished. " +
                 "\n\nCall plan_make_room_for_classes FIRST and show the teacher what it said. The course is " +
                 "backed up first and undo_last_change reverses the whole thing. Afterwards, tell them to look " +
                 "the section over in Plantoir before deploying — many pages moved at once.")]
    public string MakeRoomForClasses(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(UnitHelp)] int unit,
        [Description("The day number the new class takes. Existing days from here on are renumbered.")] int atDay,
        [Description("How many classes to make room for. 1 unless the teacher asked for more.")] int howMany = 1)
        => Guarded(() =>
        {
            var plan = workspace.PlanInsertClasses(course, section, unit, atDay, howMany);
            return workspace.ApplyInsertClasses(plan).Message;
        });

    [McpServerTool(Name = "plan_add_classes", Title = "Plan adding class pages",
                   ReadOnly = true, Destructive = false)]
    [Description("Work out which class pages would be created for a unit and what dates they would fall on, " +
                 "changing nothing. Use this for \"add placeholder pages for the next unit, seven days\" or " +
                 "\"add Unit 2 Days 1 through 10\". Dates come from the section's remembered timetable, skipping " +
                 "days already taken by an existing class, so the new unit follows on from the work already there. " +
                 "Show the teacher what it says, word for word, then wait.")]
    public string PlanAddClasses(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(UnitHelp)] int unit,
        [Description("How many class pages to add.")] int howMany,
        [Description("The day number to start at within the unit. 1 unless the earlier days already exist.")]
        int firstDay = 1)
        => Guarded(() => workspace.PlanAddClasses(course, section, unit, firstDay, howMany).Describe());

    [McpServerTool(Name = "add_classes", Title = "Add class pages", Destructive = false, Idempotent = false)]
    [Description("Create the class pages for a unit, dated to the days the section actually meets. " +
                 "Call plan_add_classes FIRST and show the teacher what it said. " +
                 "\n\nThe pages are created UNPUBLISHED — empty skeletons for the teacher to write, which stay out " +
                 "of the site until they publish them. An existing page is never written over. The course is " +
                 "backed up first, and undo_last_change removes what this created.")]
    public string AddClasses(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(UnitHelp)] int unit,
        [Description("How many class pages to add.")] int howMany,
        [Description("The day number to start at within the unit. 1 unless the earlier days already exist.")]
        int firstDay = 1)
        => Guarded(() =>
        {
            var plan = workspace.PlanAddClasses(course, section, unit, firstDay, howMany);
            return workspace.ApplyAddClasses(plan).Message;
        });

    [McpServerTool(Name = "read_remembered_timetable", Title = "What dates this section meets",
                   ReadOnly = true, Destructive = false)]
    [Description("Read the class meeting dates Plantoir already knows for a section, changing nothing. " +
                 "CALL THIS FIRST whenever you need to know when a section's classes fall — before asking the " +
                 "teacher for a timetable, and before any tool that needs dates. It is remembered from the last " +
                 "time they gave one. If it returns nothing, then ask; once they answer, record it with " +
                 "remember_timetable so nobody has to ask a third time.")]
    public string ReadRememberedTimetable(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section)
        => Guarded(() =>
        {
            var found = workspace.Course(course);
            int number = workspace.Section(found, section);
            var remembered = TimetableMemory.Read(workspace.FolderPath, found.Code, number);
            if (remembered is null)
                return $"No class dates are recorded for {found.Code} Section {number}. Ask the teacher when " +
                       "this class meets — a timetable file, or the dates themselves — then call " +
                       "remember_timetable so this only has to be asked once.";

            var text = new StringBuilder();
            text.AppendLine($"{found.Code} Section {number} meets on {remembered.Dates.Count} dates " +
                            $"({remembered.Dates[0]:yyyy-MM-dd} to {remembered.Dates[^1]:yyyy-MM-dd}), " +
                            $"from {remembered.Source}, recorded {remembered.Recorded:yyyy-MM-dd}.");
            var upcoming = remembered.From(DateOnly.FromDateTime(DateTime.Now));
            text.AppendLine($"{upcoming.Count} of those are still to come.");
            text.AppendLine();
            foreach (var date in remembered.Dates) text.AppendLine($"  {date:yyyy-MM-dd} {date.DayOfWeek}");
            return text.ToString().TrimEnd();
        });

    [McpServerTool(Name = "remember_timetable", Title = "Remember when a section meets",
                   Destructive = false, Idempotent = true)]
    [Description("Write down the dates a section's classes fall on, so nobody has to ask again. Call this as soon " +
                 "as a teacher tells you when their class meets, however they say it. Replaces anything recorded " +
                 "before, so send the WHOLE list every time, not just new dates. Dates are YYYY-MM-DD, separated " +
                 "by commas or spaces.")]
    public string RememberTimetable(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("Every date this section meets, as YYYY-MM-DD, separated by commas.")] string dates,
        [Description("Where these came from, in the teacher's words — \"timetable.xlsx, block H\", \"typed in by hand\".")]
        string source = "the teacher")
        => Guarded(() =>
        {
            var found = workspace.Course(course);
            int number = workspace.Section(found, section);

            var parsed = new List<DateOnly>();
            var unreadable = new List<string>();
            foreach (string piece in dates.Split([',', ';', ' ', '\t', '\n', '\r'],
                                                 StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                if (DateOnly.TryParse(piece, out var date)) parsed.Add(date);
                else unreadable.Add(piece);
            }

            // Half a timetable is worse than none: it would be remembered, and
            // then quietly used to date the wrong classes.
            if (unreadable.Count > 0)
                throw new AssistRefusal(
                    $"Nothing was recorded — {unreadable.Count} of those aren't dates I can read " +
                    $"({string.Join(", ", unreadable.Take(5))}). Give them as YYYY-MM-DD and I'll keep the lot.");
            if (parsed.Count == 0)
                throw new AssistRefusal("Nothing was recorded — no dates were given.");

            if (!TimetableMemory.Write(workspace.FolderPath, found.Code, number, parsed, source,
                                       DateOnly.FromDateTime(DateTime.Now)))
                throw new AssistRefusal(
                    "Those dates couldn't be saved, so they aren't remembered. Tell the teacher they may be " +
                    "asked again — don't claim otherwise.");

            var stored = TimetableMemory.Read(workspace.FolderPath, found.Code, number)!;
            return $"Recorded {stored.Dates.Count} class dates for {found.Code} Section {number}, " +
                   $"{stored.Dates[0]:yyyy-MM-dd} to {stored.Dates[^1]:yyyy-MM-dd}. " +
                   "I won't need to ask for this again.";
        });

    [McpServerTool(Name = "read_timetable", Title = "Read a timetable", ReadOnly = true, Destructive = false)]
    [Description("Read one block's class meetings out of a school timetable, changing nothing. Returns each meeting's " +
                 "number and date, plus the days that are NOT teaching days (mod breaks, intersessions, exams, " +
                 "closing). Call this before planning a re-date so you can see the shape of the year and decide " +
                 "which lesson belongs on which day — that choice depends on what is in each lesson, and the tools " +
                 "cannot see that.")]
    public async Task<string> ReadTimetable(
        [Description(TimetableHelp)] string timetable,
        [Description(BlockHelp)] string block,
        CancellationToken cancellation,
        [Description("The first day of class, as YYYY-MM-DD. Meetings before it are ignored — a block runs all year, a section does not. Leave empty to use the whole block.")]
        string firstDay = "",
        [Description("The calendar year the school year starts in. Leave empty to work it out from today's date.")]
        int startYear = 0)
    {
        try
        {
            var parsed = await Load(timetable, block, startYear, cancellation, firstDay);
            var text = new StringBuilder();
            text.AppendLine($"Block {parsed.Block}: {parsed.Meetings.Count} class meetings, " +
                            $"{parsed.Meetings[0].Date:yyyy-MM-dd} to {parsed.Meetings[^1].Date:yyyy-MM-dd}.");
            text.AppendLine();
            foreach (var meeting in parsed.Meetings)
                text.AppendLine($"  {meeting.Number,3}  {meeting.Date:yyyy-MM-dd}  {meeting.Date:ddd}");

            if (parsed.NonTeachingDays.Count > 0)
            {
                text.AppendLine();
                text.AppendLine("Not teaching days — no unit content belongs on these:");
                foreach (var day in parsed.NonTeachingDays)
                    text.AppendLine($"       {day.Date:yyyy-MM-dd}  {day.Label}");
            }
            return text.ToString().TrimEnd();
        }
        catch (AssistRefusal refusal) { return refusal.Message; }
    }

    [McpServerTool(Name = "plan_re_date_classes", Title = "Plan re-dating classes",
                   ReadOnly = true, Destructive = false)]
    [Description("Work out what moving a section's classes onto a timetable would do, WITHOUT changing anything. " +
                 "Always call this first and show the teacher the result. " +
                 "Give `pages` and `meetings` as matching lists to say which lesson lands on which meeting — that " +
                 "choice is yours to make from the lesson content, because a naive spread can leave a class holding " +
                 "nothing but a warm-up, or split a lesson that has to stay whole. Leave both empty for an even " +
                 "spread across the block, which is a starting point rather than an answer. " +
                 "The plan also reports date problems the change would leave behind.")]
    public Task<string> PlanReDateClasses(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(TimetableHelp)] string timetable,
        [Description(BlockHelp)] string block,
        CancellationToken cancellation,
        [Description("Class page titles, in the order they are taught. Leave empty for an even spread.")]
        string[]? pages = null,
        [Description("Meeting numbers, one for each entry in `pages`, in the same order.")]
        int[]? meetings = null,
        [Description("The first day of class, as YYYY-MM-DD. Meetings before it are ignored — a block runs all year, a section does not. Leave empty to use the whole block.")]
        string firstDay = "",
        [Description("The calendar year the school year starts in. Leave empty to work it out from today's date.")]
        int startYear = 0)
        => ReDate(course, section, timetable, block, pages, meetings, startYear, apply: false, firstDay, cancellation);

    [McpServerTool(Name = "roll_over_section", Title = "Roll a section over to a new year",
                   Destructive = false, Idempotent = false)]
    [Description("Start a section again for a new year, after the teacher has copied the course from a prior one. " +
                 "Re-dates every class onto the new timetable, moves each lesson's materials with it, and moves the " +
                 "year-round pages — what Key Links points at, and the curriculum — to the first day of class. " +
                 "Also cuts the section loose from last year's website so the next publish makes a new one rather " +
                 "than overwriting it. The course is backed up first, automatically. " +
                 "\n\nAsk the teacher two things before calling this: what the first day of class is, and where their " +
                 "timetable spreadsheet is. Call plan_re_date_classes first and show them the dates. " +
                 "\n\nThis deliberately does NOT hide anything: the teacher should preview the site and check the " +
                 "dates and structure before deciding what students see. Afterwards the section has to be published " +
                 "once from Plantoir, where the teacher chooses what the new site is called.")]
    public async Task<string> RollOverSection(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(TimetableHelp)] string timetable,
        [Description(BlockHelp)] string block,
        CancellationToken cancellation,
        [Description("Class page titles, in the order they are taught. Leave empty for an even spread.")]
        string[]? pages = null,
        [Description("Meeting numbers, one for each entry in `pages`, in the same order.")]
        int[]? meetings = null,
        [Description("The first day of class, as YYYY-MM-DD. Meetings before it are ignored — a block runs all year, a section does not. Leave empty to use the whole block.")]
        string firstDay = "",
        [Description("The calendar year the school year starts in. Leave empty to work it out from today's date.")]
        int startYear = 0)
    {
        try
        {
            var parsed = await Load(timetable, block, startYear, cancellation, firstDay);
            var plan = workspace.PlanReDate(course, section, parsed,
                pages ?? Array.Empty<string>(), meetings ?? Array.Empty<int>());
            var result = workspace.ApplyReDate(plan);

            var found = workspace.Course(course);
            string? released = workspace.ReleaseSite(found, section);

            var text = new StringBuilder(result.Message);
            text.Append(released is null
                ? "\nThis section had no website yet, so there was nothing to cut it loose from."
                : $"\nCut loose from last year's website — the old details are kept at {released}. " +
                  "Publishing this section from Plantoir will ask what to call the new site.");
            text.Append("\n\nNothing was hidden. Preview the section and check the dates and structure look right, " +
                        "then decide what students should see.");
            if (plan.Problems.Count > 0)
            {
                text.AppendLine().AppendLine();
                text.AppendLine("Worth looking at:");
                foreach (string problem in plan.Problems) text.AppendLine("  • " + problem);
            }
            if (result.BackupPath is not null)
                text.Append("\nA backup was made first, so this can be undone from Plantoir’s Backups list.");
            return text.ToString();
        }
        catch (AssistRefusal refusal) { return refusal.Message; }
    }

    [McpServerTool(Name = "re_date_classes", Title = "Re-date classes", Destructive = false, Idempotent = true)]
    [Description("Move a section's classes onto a timetable's dates. The course is backed up first, automatically. " +
                 "Only call this after plan_re_date_classes and after the teacher has agreed to what it said. " +
                 "This changes dates only — nothing is published, and no page's visibility changes.")]
    public Task<string> ReDateClasses(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(TimetableHelp)] string timetable,
        [Description(BlockHelp)] string block,
        CancellationToken cancellation,
        [Description("Class page titles, in the order they are taught. Leave empty for an even spread.")]
        string[]? pages = null,
        [Description("Meeting numbers, one for each entry in `pages`, in the same order.")]
        int[]? meetings = null,
        [Description("The first day of class, as YYYY-MM-DD. Meetings before it are ignored — a block runs all year, a section does not. Leave empty to use the whole block.")]
        string firstDay = "",
        [Description("The calendar year the school year starts in. Leave empty to work it out from today's date.")]
        int startYear = 0)
        => ReDate(course, section, timetable, block, pages, meetings, startYear, apply: true, firstDay, cancellation);

    private async Task<string> ReDate(string course, int section, string timetable, string block,
                                      string[]? pages, int[]? meetings, int startYear, bool apply,
                                      string firstDay, CancellationToken cancellation)
    {
        try
        {
            var parsed = await Load(timetable, block, startYear, cancellation, firstDay);
            var plan = workspace.PlanReDate(course, section, parsed,
                pages ?? Array.Empty<string>(), meetings ?? Array.Empty<int>());

            if (!apply)
                return plan.Describe() +
                       "\n\nNothing has been changed. Show this to the teacher and ask before going ahead.";

            var result = workspace.ApplyReDate(plan);
            var text = new StringBuilder(result.Message);
            if (plan.Problems.Count > 0)
            {
                text.AppendLine().AppendLine();
                text.AppendLine($"{plan.Problems.Count} thing{(plan.Problems.Count == 1 ? "" : "s")} worth looking at:");
                foreach (string problem in plan.Problems) text.AppendLine("  • " + problem);
            }
            if (result.BackupPath is not null)
                text.Append("\nA backup was made first, so this can be undone from Plantoir’s Backups list.");
            return text.ToString();
        }
        catch (AssistRefusal refusal) { return refusal.Message; }
        catch (Plantoir.Core.Models.OutsideWorkspaceException refusal) { return refusal.Message; }
    }

    private static async Task<Timetable> Load(string timetable, string block, int startYear,
                                              CancellationToken cancellation, string firstDay = "")
    {
        string csv = await TimetableSource.Read(timetable, cancellation);
        int year = startYear > 0
            ? startYear
            : Timetable.AcademicYearStarting(DateOnly.FromDateTime(DateTime.Now));
        var parsed = Timetable.Parse(csv, block, year);
        // The teacher's first day of class, when they gave one: a block runs
        // all year but a section does not span semesters.
        return ParseDate(firstDay, "firstDay") is { } from ? parsed.From(from) : parsed;
    }

    [McpServerTool(Name = "plan_sync_page_dates", Title = "Plan bringing materials into date",
                   ReadOnly = true, Destructive = false)]
    [Description("Work out what bringing a lesson's materials into date with the lesson would do, WITHOUT changing " +
                 "anything. This is the fix for the date problems the other tools report — when a class is dated in " +
                 "June but the concept page it links to is dated in November, this brings the concept to the class. " +
                 "Name classes to fix just those; name none to bring every page into line with the earliest class " +
                 "that links to it. Always show the teacher the result before using sync_page_dates.")]
    public string PlanSyncPageDates(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("Class page titles whose linked pages should be brought into date. Leave empty for all.")]
        string[]? classes = null)
        => Guarded(() => workspace.PlanSyncDates(course, section, classes ?? Array.Empty<string>()).Describe() +
                         "\n\nNothing has been changed. Show this to the teacher and ask before going ahead.");

    [McpServerTool(Name = "sync_page_dates", Title = "Bring materials into date",
                   Destructive = false, Idempotent = true)]
    [Description("Set the date of the pages a class links to, to match that class. The course is backed up first, " +
                 "automatically. Only call this after plan_sync_page_dates and after the teacher has agreed. " +
                 "This changes dates only — nothing is published, and no page's visibility changes.")]
    public string SyncPageDates(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("Class page titles whose linked pages should be brought into date. Leave empty for all.")]
        string[]? classes = null)
        => Guarded(() =>
        {
            var plan = workspace.PlanSyncDates(course, section, classes ?? Array.Empty<string>());
            var result = workspace.ApplySyncDates(plan);
            return result.BackupPath is null
                ? result.Message
                : result.Message + "\n\nA backup was made first, so this can be undone from Plantoir’s Backups list.";
        });

    // ---- Planning (changes nothing) --------------------------------------

    /// <summary>
    /// Dates arrive as plain strings and are parsed here, once, so a bad date
    /// is a sentence rather than a schema error — and so the comparison itself
    /// is never something the assistant does.
    /// </summary>
    private const string DateHelp =
        "A date as YYYY-MM-DD, for example 2026-09-15. Leave empty for no limit.";

    [McpServerTool(Name = "plan_publish_pages", Title = "Plan publishing pages", ReadOnly = true, Destructive = false)]
    [Description("Work out exactly what publishing pages would do, WITHOUT changing anything. " +
                 "Always call this before publish_pages and show the teacher the result. " +
                 "Choose pages by name, or by date with onOrAfter/before — \"every class from September 15th\" is one " +
                 "call, and the dates are compared for you. Accepts any page, not just class pages, and can follow " +
                 "their links, so you never need to work out which pages are linked.")]
    public string PlanPublishPages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("True to also publish every page these pages link to. Choose deliberately; there is no default.")]
        bool includeLinked,
        [Description("The page titles, for example [\"Unit 2, Day 3\"]. May be empty if you give dates instead.")]
        string[]? pages = null,
        [Description("Only classes on or after this date. " + DateHelp)] string onOrAfter = "",
        [Description("Only classes strictly before this date. " + DateHelp)] string before = "")
        => Plan(course, section, pages, includeLinked, draft: false, onOrAfter, before);

    [McpServerTool(Name = "plan_unpublish_pages", Title = "Plan unpublishing pages", ReadOnly = true, Destructive = false)]
    [Description("Work out exactly what unpublishing pages from students would do, WITHOUT changing anything. " +
                 "Always call this before unpublish_pages and show the teacher the result. " +
                 "Choose pages by name, or by date with onOrAfter/before — \"hide everything from next Monday on\" is " +
                 "one call. Note that a page linked from a class you are unpublishing may also be linked from one that must " +
                 "stay up; the plan lists every page, so check it before agreeing.")]
    public string PlanUnpublishPages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("True to also unpublish every page these pages link to. Choose deliberately; there is no default.")]
        bool includeLinked,
        [Description("The page titles, for example [\"Unit 2, Day 3\"]. May be empty if you give dates instead.")]
        string[]? pages = null,
        [Description("Only classes on or after this date. " + DateHelp)] string onOrAfter = "",
        [Description("Only classes strictly before this date. " + DateHelp)] string before = "")
        => Plan(course, section, pages, includeLinked, draft: true, onOrAfter, before);

    private string Plan(string course, int section, string[]? pages, bool includeLinked,
                        bool draft, string onOrAfter, string before)
        => Guarded(() => Render(workspace.PlanPublish(
            course, section, pages ?? Array.Empty<string>(), includeLinked, draft,
            publishes: true, onOrAfter: ParseDate(onOrAfter, "onOrAfter"), before: ParseDate(before, "before"))));

    private static DateOnly? ParseDate(string raw, string which)
    {
        string value = raw.Trim();
        if (value.Length == 0) return null;
        if (DateOnly.TryParse(value, System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.None, out var date))
            return date;
        throw new AssistRefusal($"“{raw}” isn’t a date {which} can use. Give it as YYYY-MM-DD, for example 2026-09-15.");
    }

    // ---- Taking it back --------------------------------------------------

    [McpServerTool(Name = "list_recent_changes", Title = "What this conversation changed",
                   ReadOnly = true, Destructive = false)]
    [Description("List what this conversation has changed, newest first, so the teacher can see what could be " +
                 "taken back. This history is only kept while this conversation is open. Anything older lives in " +
                 "Plantoir's Backups list, which is made before every change.")]
    public string ListRecentChanges()
    {
        var entries = workspace.History?.Entries;
        if (entries is null || entries.Count == 0)
            return "This conversation hasn’t changed anything yet.";

        var text = new StringBuilder();
        for (int i = entries.Count - 1; i >= 0; i--)
        {
            var entry = entries[i];
            text.AppendLine($"{(i == entries.Count - 1 ? "most recent: " : "             ")}" +
                            $"{entry.When:HH:mm} — {entry.Description} " +
                            $"({entry.Files.Count} file{(entry.Files.Count == 1 ? "" : "s")})");
        }
        text.Append("\nundo_last_change takes the most recent one back.");
        return text.ToString();
    }

    [McpServerTool(Name = "undo_last_change", Title = "Undo the last change",
                   Destructive = false, Idempotent = false)]
    [Description("Take back the most recent change this conversation made — the fix for publishing the wrong " +
                 "class in a hurry. Puts exactly those pages back the way they were, without disturbing anything " +
                 "else. Can be called more than once to step further back. " +
                 "\n\nOnly changes made in THIS conversation can be undone this way; the history is not kept " +
                 "afterwards. For anything older, Plantoir's Backups list has a full copy of the course taken " +
                 "before each change. " +
                 "\n\nIf the teacher had already published the section themselves, undoing the pages does not " +
                 "un-publish the live site — they need to publish again in Plantoir to bring it back in step.")]
    public string UndoLastChange()
    {
        if (workspace.History is not { } history)
            return "This session isn’t keeping an undo history.";

        var result = history.Undo();
        if (!result.Succeeded && result.Restored.Count == 0 && result.Skipped.Count == 0)
            return result.Description;   // nothing to undo: the message says so

        var text = new StringBuilder();
        text.Append($"Undid {result.Description} — put {result.Restored.Count} " +
                    $"file{(result.Restored.Count == 1 ? "" : "s")} back.");

        if (result.Skipped.Count > 0)
        {
            text.AppendLine().AppendLine();
            text.AppendLine($"{result.Skipped.Count} file{(result.Skipped.Count == 1 ? " was" : "s were")} " +
                            "left alone, because they have changed since — putting the old copy back would " +
                            "throw away that newer work:");
            foreach (string path in result.Skipped.Take(MostListed))
                text.AppendLine("  " + workspace.Relative(path));
            text.Append("\nThis change is still on the list, so it can be tried again.");
        }
        return text.ToString();
    }

    // ---- The commonest request of all ------------------------------------

    private const string ClassDateHelp =
        "The day the class is taught, as YYYY-MM-DD. For \"tomorrow\" or \"today\", work out the date first — " +
        "the tool matches it exactly against each class's own date.";

    [McpServerTool(Name = "plan_publish_class_on", Title = "Plan publishing a day's class",
                   ReadOnly = true, Destructive = false)]
    [Description("Work out what publishing the class taught on a given day would do, WITHOUT changing anything. " +
                 "This is the tool for \"publish tomorrow's class\" or \"publish today's class\": it finds the class " +
                 "by date, follows its links, gives pages no other class uses that class's date, and points the " +
                 "section's front page at it. Always show the teacher the result before using publish_class_on.")]
    public string PlanPublishClassOn(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(ClassDateHelp)] string date)
        => Guarded(() => Render(PlanForDay(course, section, date, publishes: true)));

    [McpServerTool(Name = "publish_class_on", Title = "Publish a day's class",
                   Destructive = false, Idempotent = true)]
    [Description("Publish the class taught on a given day, along with the pages it links to, then rebuild the " +
                 "section's preview. Pages that no other class links to take the class's date, and the section's " +
                 "front page is pointed at the most recent published class. The course is backed up first, " +
                 "automatically. Only call this after plan_publish_class_on and after the teacher has agreed. " +
                 "\n\nThis changes the teacher's files and rebuilds their PREVIEW. It does not put anything in " +
                 "front of students: only the teacher can do that, from Plantoir. Tell them to look the preview " +
                 "over and publish it there when they are happy. " +
                 "This takes a few minutes.")]
    public async Task<string> PublishClassOn(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description(ClassDateHelp)] string date,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation,
        [Description("False to change the pages without rebuilding the preview.")] bool preview = true)
    {
        try
        {
            var plan = PlanForDay(course, section, date, preview);
            var result = await workspace.Apply(plan, Relay(progress), cancellation);
            progress.Report(new ProgressNotificationValue { Progress = 100, Total = 100, Message = "Finished" });

            var text = new StringBuilder(result.Message);
            if (plan.Index is { WillChange: true } index)
                text.Append($"\nThe section's front page now shows “{index.ToClass}”.");
            if (result.BackupPath is not null)
                text.Append("\n\nA backup was made first, so this can be undone from Plantoir’s Backups list.");
            return text.ToString();
        }
        catch (AssistRefusal refusal) { return refusal.Message; }
        catch (OperationCanceledException) { return "The publish was stopped before it finished."; }
    }

    private PublishPlan PlanForDay(string course, int section, string date, bool publishes)
    {
        var found = workspace.Course(course);
        int number = workspace.Section(found, section);
        var when = ParseDate(date, "date")
            ?? throw new AssistRefusal("No date was given for the class to publish.");
        string page = workspace.ClassOn(found, number, when);

        return workspace.PlanPublish(course, number,
            new[] { Path.GetFileNameWithoutExtension(page) },
            includeLinked: true, draft: false, publishes: publishes);
    }

    // ---- Acting ----------------------------------------------------------

    [McpServerTool(Name = "publish_pages", Title = "Publish pages", Destructive = false, Idempotent = true)]
    [Description("Make pages visible to students, optionally along with every page they link to, then rebuild the section preview. " +
                 "section's website. The course is backed up first, automatically. " +
                 "Only call this after plan_publish_pages and after the teacher has agreed to what it said. " +
                 "Pass every page you intend to change in ONE call: each call with preview=true rebuilds the preview again. " +
                 "This takes several minutes.")]
    public Task<string> PublishPages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("True to also publish every page these pages link to.")] bool includeLinked,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation,
        [Description("The page titles to publish. May be empty if you give dates instead.")]
        string[]? pages = null,
        [Description("Only classes on or after this date. " + DateHelp)] string onOrAfter = "",
        [Description("Only classes strictly before this date. " + DateHelp)] string before = "",
        [Description("False to change the pages without rebuilding the preview.")] bool preview = true)
        => Act(course, section, pages, includeLinked, draft: false, preview, onOrAfter, before,
               progress, cancellation);

    [McpServerTool(Name = "unpublish_pages", Title = "Unpublish pages", Destructive = false, Idempotent = true)]
    [Description("Unpublish pages, so students no longer see them, optionally along with every page they link to, then rebuild the section preview. " +
                 "section's website so they disappear from the live site. The course is backed up first, automatically. " +
                 "Only call this after plan_unpublish_pages and after the teacher has agreed to what it said. " +
                 "Pass every page you intend to change in ONE call: each call with preview=true rebuilds the preview again. " +
                 "This takes several minutes.")]
    public Task<string> UnpublishPages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("True to also unpublish every page these pages link to.")] bool includeLinked,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation,
        [Description("The page titles to unpublish. May be empty if you give dates instead.")]
        string[]? pages = null,
        [Description("Only classes on or after this date. " + DateHelp)] string onOrAfter = "",
        [Description("Only classes strictly before this date. " + DateHelp)] string before = "",
        [Description("False to change the pages without rebuilding the preview.")] bool preview = true)
        => Act(course, section, pages, includeLinked, draft: true, preview, onOrAfter, before,
               progress, cancellation);

    [McpServerTool(Name = "rebuild_preview", Title = "Rebuild the preview", Destructive = false, Idempotent = true)]
    [Description("Rebuild a section preview without changing any page. " +
                 "Use this after a batch of publish_pages or unpublish_pages calls made with preview=false. " +
                 "This takes several minutes.")]
    public async Task<string> RebuildPreview(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation)
    {
        try
        {
            var result = await workspace.RebuildPreview(course, section, Relay(progress), cancellation);
            progress.Report(new ProgressNotificationValue { Progress = 100, Total = 100, Message = "Finished" });
            return result.Message;
        }
        catch (AssistRefusal refusal) { return refusal.Message; }
        catch (OperationCanceledException) { return "The publish was stopped before it finished."; }
    }

    [McpServerTool(Name = "back_up_course", Title = "Back up a course", Destructive = false, Idempotent = false)]
    [Description("Make a full backup of one course, which the teacher can restore from inside Plantoir. " +
                 "Do this before any bulk editing of a course's files — including edits you make directly rather than " +
                 "through these tools. Course folders are not in version control, so a backup is the only undo.")]
    public string BackUpCourse(
        [Description("The course code, for example ICS3U.")] string course)
        => Guarded(() => $"Backed up to {workspace.BackUp(course)}");

    // ---- Shared ----------------------------------------------------------

    private async Task<string> Act(string course, int section, string[]? pages, bool includeLinked,
                                   bool draft, bool preview, string onOrAfter, string before,
                                   IProgress<ProgressNotificationValue> progress,
                                   CancellationToken cancellation)
    {
        try
        {
            var plan = workspace.PlanPublish(
                course, section, pages ?? Array.Empty<string>(), includeLinked, draft, preview,
                ParseDate(onOrAfter, "onOrAfter"), ParseDate(before, "before"));
            if (plan.ChangesNothing && !preview) return plan.Describe();

            var result = await workspace.Apply(plan, Relay(progress), cancellation);
            progress.Report(new ProgressNotificationValue { Progress = 100, Total = 100, Message = "Finished" });

            var text = new StringBuilder(result.Message);
            if (result.BackupPath is not null)
                text.Append("\n\nA backup was made first, so this can be undone from Plantoir’s " +
                            "Backups list if it is not what you wanted.");
            return text.ToString();
        }
        catch (AssistRefusal refusal) { return refusal.Message; }
        catch (OperationCanceledException) { return "The publish was stopped before it finished."; }
    }

    /// <summary>
    /// Forwards the launchers' own milestone lines as MCP progress. The
    /// toolchain already narrates in plain words, so the assistant reports the
    /// toolchain's wording rather than a paraphrase of it.
    /// </summary>
    private static IProgress<string> Relay(IProgress<ProgressNotificationValue> progress)
    {
        int step = 0;
        return new Progress<string>(message =>
            progress.Report(new ProgressNotificationValue
            {
                Progress = Math.Min(++step, 99),
                Total = 100,
                Message = message,
            }));
    }

    /// <summary>
    /// A refusal is an answer, not a crash: it comes back as ordinary text so
    /// the assistant reads the reason to the teacher and can correct itself.
    /// </summary>
    private static string Guarded(Func<string> work)
    {
        try { return work(); }
        catch (AssistRefusal refusal) { return refusal.Message; }
        catch (Plantoir.Core.Models.OutsideWorkspaceException refusal) { return refusal.Message; }
        catch (IOException error) { return $"That couldn’t be read: {error.Message}"; }
        catch (UnauthorizedAccessException) { return "Plantoir doesn’t have permission to read that."; }
    }

    /// <summary>
    /// The plan itself lists every page it would touch, with the key and the
    /// transition; this only adds the standing instruction. Rendering the list
    /// here as well is how two counts drifted apart in the first place — one
    /// description of the plan, in one place.
    /// </summary>
    private static string Render(PublishPlan plan) =>
        plan.Describe() +
        "\n\nNothing has been changed. Show this to the teacher and ask before going ahead.";
}
