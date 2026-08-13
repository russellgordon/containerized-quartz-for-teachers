using System.ComponentModel;
using System.Text;
using ModelContextProtocol;
using ModelContextProtocol.Server;
using Plantoir.Core.Assist;

namespace Plantoir.Mcp;

/// <summary>
/// The tools an assistant may call.
///
/// Three rules shape this surface, each of them measured rather than assumed
/// (AI-ASSIST.md has the numbers):
///
/// 1. **Nothing destructive exists.** There is no delete, no archive, no
///    rename. In testing, the model reliably declined "delete the Unit 1
///    folder" — not because it judged the request unwise, but because it had
///    no tool for it. Absence is the strongest guardrail available, so it is
///    the one relied on.
///
/// 2. **Publishing and hiding are separate tools, not a flag.** The one
///    genuinely dangerous failure observed was polarity inversion: asked to
///    HIDE a page, the model called publish with "include everything it links
///    to" set. A boolean is a coin flip under pressure; a verb in the tool
///    name is not.
///
/// 3. **Every write has a matching plan_ tool that changes nothing.** The
///    assistant is expected to plan, show the teacher, and only then act. The
///    descriptions say so, and the plan output is written to be read aloud.
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
    /// has 190, most of them curriculum expectations nobody is asking about.
    /// Returning all of them buries the answer and, for a small local model,
    /// fills the context before the question is even considered. So the list
    /// is filterable and capped, and says plainly when it has been cut.
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
    [Description("Read one page's Markdown, including its frontmatter. Use this to see what a class page's agenda links to " +
                 "before proposing anything.")]
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

    [McpServerTool(Name = "plan_publish_class", Title = "Plan publishing a class", ReadOnly = true, Destructive = false)]
    [Description("Work out exactly what publishing a class page would do, WITHOUT changing anything. " +
                 "Always call this before publish_class and show the teacher the result. " +
                 "It resolves the class page's links for you, so you never need to work out which pages are linked.")]
    public string PlanPublishClass(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The class page title, for example \"Unit 2, Day 3\".")] string page,
        [Description("True to also publish every page this class page links to.")] bool includeLinked = true)
        => Guarded(() => Render(workspace.PlanPublish(course, section, page, includeLinked, draft: false)));

    [McpServerTool(Name = "plan_hide_class", Title = "Plan hiding a class", ReadOnly = true, Destructive = false)]
    [Description("Work out exactly what hiding a class page from students would do, WITHOUT changing anything. " +
                 "Always call this before hide_class and show the teacher the result.")]
    public string PlanHideClass(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The class page title, for example \"Unit 2, Day 3\".")] string page,
        [Description("True to also hide every page this class page links to.")] bool includeLinked = false)
        => Guarded(() => Render(workspace.PlanPublish(course, section, page, includeLinked, draft: true)));

    // ---- Acting ----------------------------------------------------------

    [McpServerTool(Name = "publish_class", Title = "Publish a class", Destructive = false, Idempotent = true)]
    [Description("Make a class page visible to students, optionally along with every page it links to, then republish the " +
                 "section's website. The course is backed up first, automatically. " +
                 "Only call this after plan_publish_class and after the teacher has agreed to what it said. " +
                 "This takes several minutes.")]
    public Task<string> PublishClass(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The class page title, for example \"Unit 2, Day 3\".")] string page,
        [Description("True to also publish every page this class page links to.")] bool includeLinked,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation,
        [Description("False to change the pages but not republish the website yet.")] bool republish = true)
        => Act(course, section, page, includeLinked, draft: false, republish, progress, cancellation);

    [McpServerTool(Name = "hide_class", Title = "Hide a class", Destructive = false, Idempotent = true)]
    [Description("Hide a class page from students, optionally along with every page it links to, then republish the " +
                 "section's website so it disappears from the live site. The course is backed up first, automatically. " +
                 "Only call this after plan_hide_class and after the teacher has agreed to what it said. " +
                 "This takes several minutes.")]
    public Task<string> HideClass(
        [Description("The course code, for example ICS3U.")] string course,
        [Description("The section number, for example 1.")] int section,
        [Description("The class page title, for example \"Unit 2, Day 3\".")] string page,
        [Description("True to also hide every page this class page links to.")] bool includeLinked,
        IProgress<ProgressNotificationValue> progress,
        CancellationToken cancellation,
        [Description("False to change the pages but not republish the website yet.")] bool republish = true)
        => Act(course, section, page, includeLinked, draft: true, republish, progress, cancellation);

    [McpServerTool(Name = "back_up_course", Title = "Back up a course", Destructive = false, Idempotent = false)]
    [Description("Make a full backup of one course, which the teacher can restore from inside Plantoir. " +
                 "Do this before any bulk editing of a course's files.")]
    public string BackUpCourse(
        [Description("The course code, for example ICS3U.")] string course)
        => Guarded(() => $"Backed up to {workspace.BackUp(course)}");

    // ---- Shared ----------------------------------------------------------

    private async Task<string> Act(string course, int section, string page, bool includeLinked,
                                   bool draft, bool republish,
                                   IProgress<ProgressNotificationValue> progress,
                                   CancellationToken cancellation)
    {
        try
        {
            var plan = workspace.PlanPublish(course, section, page, includeLinked, draft, republish);
            if (plan.ChangesNothing && !republish) return plan.Describe();

            int step = 0;
            var relay = new Progress<string>(message =>
                progress.Report(new ProgressNotificationValue
                {
                    Progress = Math.Min(++step, 99),
                    Total = 100,
                    Message = message,
                }));

            var result = await workspace.Apply(plan, relay, cancellation);
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
    /// A refusal is an answer, not a crash: it comes back as ordinary text so
    /// the assistant reads the reason to the teacher and can correct itself.
    /// Anything unexpected is reported honestly rather than dressed up.
    /// </summary>
    private static string Guarded(Func<string> work)
    {
        try { return work(); }
        catch (AssistRefusal refusal) { return refusal.Message; }
        catch (Plantoir.Core.Models.OutsideWorkspaceException refusal) { return refusal.Message; }
        catch (IOException error) { return $"That couldn’t be read: {error.Message}"; }
        catch (UnauthorizedAccessException) { return "Plantoir doesn’t have permission to read that."; }
    }

    private static string Render(PublishPlan plan)
    {
        var text = new StringBuilder(plan.Describe());
        var changing = plan.Changing.ToList();
        if (changing.Count > 0)
        {
            text.AppendLine().AppendLine().AppendLine("Pages that would change:");
            foreach (var page in changing) text.AppendLine($"  {page.RelativePath}");
        }
        text.AppendLine().Append("Nothing has been changed. Show this to the teacher and ask before going ahead.");
        return text.ToString();
    }
}
