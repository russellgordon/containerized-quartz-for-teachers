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
/// 2. **Publishing and hiding are separate tools, not a flag.** The one
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
///    linked from both a protected class and a hidden one is the normal shape
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
                 "and to see which draft key governs the page: a page under section1/ carries `draft:`, while a course-level " +
                 "page such as a Concept carries `draftSection1:` and `draftSection2:` — one flag per section.")]
    public string ReadPage(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The page title as it appears in the sidebar, for example \"Unit 2, Day 3\".")] string page)
        => Guarded(() =>
        {
            var found = workspace.Course(course);
            return workspace.ReadPage(found, workspace.Section(found, section), page);
        });

    // ---- Planning (changes nothing) --------------------------------------

    [McpServerTool(Name = "plan_publish_pages", Title = "Plan publishing pages", ReadOnly = true, Destructive = false)]
    [Description("Work out exactly what publishing these pages would do, WITHOUT changing anything. " +
                 "Always call this before publish_pages and show the teacher the result. " +
                 "Accepts any pages — class pages, concepts, exercises, anything — and can follow their links for you, " +
                 "so you never need to work out which pages are linked.")]
    public string PlanPublishPages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The page titles, for example [\"Unit 2, Day 3\"]. Pass several to plan them as one change.")]
        string[] pages,
        [Description("True to also publish every page these pages link to. Choose deliberately; there is no default.")]
        bool includeLinked)
        => Guarded(() => Render(workspace.PlanPublish(course, section, pages, includeLinked, draft: false)));

    [McpServerTool(Name = "plan_hide_pages", Title = "Plan hiding pages", ReadOnly = true, Destructive = false)]
    [Description("Work out exactly what hiding these pages from students would do, WITHOUT changing anything. " +
                 "Always call this before hide_pages and show the teacher the result. " +
                 "Note that a page linked from a class you are hiding may also be linked from one that must stay up — " +
                 "check the list before agreeing to it.")]
    public string PlanHidePages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The page titles, for example [\"Unit 2, Day 3\"]. Pass several to plan them as one change.")]
        string[] pages,
        [Description("True to also hide every page these pages link to. Choose deliberately; there is no default.")]
        bool includeLinked)
        => Guarded(() => Render(workspace.PlanPublish(course, section, pages, includeLinked, draft: true)));

    // ---- Acting ----------------------------------------------------------

    [McpServerTool(Name = "publish_pages", Title = "Publish pages", Destructive = false, Idempotent = true)]
    [Description("Make pages visible to students, optionally along with every page they link to, then republish the " +
                 "section's website. The course is backed up first, automatically. " +
                 "Only call this after plan_publish_pages and after the teacher has agreed to what it said. " +
                 "Pass every page you intend to change in ONE call: each call with republish=true is a separate deploy. " +
                 "This takes several minutes.")]
    public Task<string> PublishPages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The page titles to publish.")] string[] pages,
        [Description("True to also publish every page these pages link to.")] bool includeLinked,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation,
        [Description("False to change the pages but not republish the website yet.")] bool republish = true)
        => Act(course, section, pages, includeLinked, draft: false, republish, progress, cancellation);

    [McpServerTool(Name = "hide_pages", Title = "Hide pages", Destructive = false, Idempotent = true)]
    [Description("Hide pages from students, optionally along with every page they link to, then republish the " +
                 "section's website so they disappear from the live site. The course is backed up first, automatically. " +
                 "Only call this after plan_hide_pages and after the teacher has agreed to what it said. " +
                 "Pass every page you intend to change in ONE call: each call with republish=true is a separate deploy. " +
                 "This takes several minutes.")]
    public Task<string> HidePages(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The page titles to hide.")] string[] pages,
        [Description("True to also hide every page these pages link to.")] bool includeLinked,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation,
        [Description("False to change the pages but not republish the website yet.")] bool republish = true)
        => Act(course, section, pages, includeLinked, draft: true, republish, progress, cancellation);

    [McpServerTool(Name = "republish_section", Title = "Republish a section", Destructive = false, Idempotent = true)]
    [Description("Rebuild and republish a section's website without changing any page. " +
                 "Use this after a batch of publish_pages or hide_pages calls made with republish=false. " +
                 "This takes several minutes.")]
    public async Task<string> RepublishSection(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation)
    {
        try
        {
            var result = await workspace.Republish(course, section, Relay(progress), cancellation);
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

    private async Task<string> Act(string course, int section, string[] pages, bool includeLinked,
                                   bool draft, bool republish,
                                   IProgress<ProgressNotificationValue> progress,
                                   CancellationToken cancellation)
    {
        try
        {
            var plan = workspace.PlanPublish(course, section, pages, includeLinked, draft, republish);
            if (plan.ChangesNothing && !republish) return plan.Describe();

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
