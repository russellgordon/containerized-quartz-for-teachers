using Plantoir.Core.Models;

namespace Plantoir.Core.Assist;

/// <summary>
/// Every Plantoir operation an assistant is allowed to ask for, locked to one
/// working folder.
///
/// Two rules run through all of it, both earned from the measurements in
/// AI-ASSIST.md:
///
/// **Nothing named is taken on trust.** A course code, a section number and a
/// page title are all validated against what is actually on disk before
/// anything happens. Asked to "clean up my course" — a request naming no
/// course at all — the small model proposed backing up "MCV4U", a code it
/// invented. So a name that does not resolve is a refusal that says what does
/// exist, never a best guess.
///
/// **The tools do the work; the assistant only picks one.** Given fine-grained
/// tools and asked to publish a class "and everything it links to", the model
/// chose the publish tool and silently skipped the link resolution, eight
/// times out of eight. Given one coarse tool that resolves links itself, it
/// got it right eight times out of eight. So link resolution, the choice
/// between <c>draft:</c> and <c>draftSection&lt;N&gt;:</c>, the backup, the
/// rebuild and the publish are one operation here — not steps somebody else
/// sequences.
///
/// There is deliberately no delete, no archive and no overwrite. The model
/// declines what it has no tool for, which is why "delete the Unit 1 folder"
/// was harmless in testing; that property is worth keeping by construction.
/// </summary>
public sealed class AssistWorkspace
{
    private readonly string _folder;
    private readonly ILauncherRunner _launcher;

    public AssistWorkspace(string workspacePath, ILauncherRunner launcher)
    {
        _folder = Path.GetFullPath(workspacePath);
        _launcher = launcher;
        if (Workspace.Classify(_folder) != WorkspaceState.Ready)
            throw new AssistRefusal(
                $"“{_folder}” isn’t a Plantoir working folder — it has no {Workspace.MarkerLauncher}. " +
                "Open the folder in Plantoir once to set it up.");
    }

    public string FolderPath => _folder;

    // ---- Looking things up ----------------------------------------------

    public List<Course> Courses() => Workspace.DiscoverCourses(_folder);

    /// <summary>
    /// The course with this code, or a refusal naming the codes that do exist.
    /// Matching is case-insensitive because teachers type "mcv4u".
    /// </summary>
    public Course Course(string code)
    {
        string wanted = code.Trim();
        var courses = Courses();
        var found = courses.FirstOrDefault(c => string.Equals(c.Code, wanted, StringComparison.OrdinalIgnoreCase));
        if (found is not null) return found;

        string known = courses.Count == 0
            ? "This working folder has no courses yet."
            : "The courses here are " + Humanize(courses.Select(c => c.Code)) + ".";
        throw new AssistRefusal($"There’s no course called “{wanted}” in this working folder. {known}");
    }

    /// <summary>The section, or a refusal naming the sections that do exist.</summary>
    public int Section(Course course, int sectionNumber)
    {
        var numbers = course.SectionNumbers;
        if (numbers.Contains(sectionNumber)) return sectionNumber;
        string known = numbers.Count == 0
            ? $"{course.Code} has no sections."
            : $"{course.Code} has section{(numbers.Count == 1 ? "" : "s")} " +
              Humanize(numbers.Select(n => n.ToString())) + ".";
        throw new AssistRefusal($"There’s no section {sectionNumber} in {course.Code}. {known}");
    }

    /// <summary>Every page of a section, as paths relative to the working folder.</summary>
    public List<string> Pages(Course course, int sectionNumber) =>
        PagePaths.MarkdownPages(course.DirectoryPath, sectionNumber)
            .Select(Relative).ToList();

    /// <summary>
    /// The single page with this title, or a refusal. A title matching several
    /// files is never resolved by picking one — publishing the wrong page is
    /// exactly the failure this whole design is built to avoid.
    /// </summary>
    public string Page(Course course, int sectionNumber, string title)
    {
        string wanted = title.Trim();
        if (wanted.Length == 0) throw new AssistRefusal("No page was named.");

        // A path was given rather than a title: honour it, but only inside.
        if (wanted.Contains('/') || wanted.Contains('\\'))
        {
            string direct = PagePaths.ResolveInside(_folder, wanted);
            if (File.Exists(direct)) return direct;
        }

        string bare = wanted.EndsWith(".md", StringComparison.OrdinalIgnoreCase) ? wanted[..^3] : wanted;
        var matches = PagePaths.MarkdownPages(course.DirectoryPath, sectionNumber)
            .Where(p => string.Equals(System.IO.Path.GetFileNameWithoutExtension(p), bare,
                                      StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (matches.Count == 1) return matches[0];
        if (matches.Count == 0)
            throw new AssistRefusal(
                $"There’s no page called “{wanted}” in {course.Code} Section {sectionNumber}.");
        throw new AssistRefusal(
            $"{course.Code} Section {sectionNumber} has {matches.Count} pages called “{wanted}” — " +
            Humanize(matches.Select(Relative)) + ". Say which one you mean.");
    }

    public string ReadPage(Course course, int sectionNumber, string title) =>
        File.ReadAllText(Page(course, sectionNumber, title));

    // ---- Planning --------------------------------------------------------

    /// <summary>
    /// Work out what publishing (or hiding) this class page would do, without
    /// touching anything. This is what the teacher confirms.
    /// </summary>
    public PublishPlan PlanPublish(
        string courseCode, int sectionNumber, string pageTitle,
        bool includeLinked, bool draft = false, bool publishes = true)
    {
        var course = Course(courseCode);
        int section = Section(course, sectionNumber);
        string pagePath = Page(course, section, pageTitle);

        var problems = new List<string>();
        var linked = new List<PlannedPage>();

        // Surface it in the PLAN, so the teacher learns the publish can't
        // happen before agreeing to it rather than after.
        if (publishes && PublishProblem(course) is { } blocked) problems.Add(blocked);

        if (includeLinked)
        {
            var resolutions = WikiLinks.Resolve(
                WikiLinks.Parse(File.ReadAllText(pagePath)), course.DirectoryPath, section, pagePath);
            foreach (var resolution in resolutions)
            {
                if (resolution.Problem is { } problem) { problems.Add(problem); continue; }
                if (resolution.Outcome != LinkOutcome.Resolved) continue;
                linked.Add(Plan(course, section, resolution.Path!, draft));
            }
        }

        return new PublishPlan
        {
            CourseCode = course.Code,
            SectionNumber = section,
            Page = Plan(course, section, pagePath, draft),
            Linked = linked,
            Problems = problems,
            Publishes = publishes,
            Destination = DestinationOf(course),
        };
    }

    private PlannedPage Plan(Course course, int section, string pagePath, bool draft)
    {
        bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, pagePath);
        string key = PageFrontmatter.DraftKeyFor(section, sectionLocal);
        string text = File.ReadAllText(pagePath);
        return new PlannedPage(
            Title: System.IO.Path.GetFileNameWithoutExtension(pagePath),
            RelativePath: Relative(pagePath),
            FrontmatterKey: key,
            CurrentValue: PageFrontmatter.StoredValue(text, key),
            Draft: draft);
    }

    private static string DestinationOf(Course course) =>
        course.Configuration.DeploysToLocalFolder ? course.Configuration.DeployFolderPath
        : course.Configuration.DeploysToCloudflare ? "Cloudflare Pages"
        : "Netlify";

    // ---- Doing it --------------------------------------------------------

    /// <summary>
    /// Carry out a plan the teacher has agreed to: back up, change the flags,
    /// rebuild, publish.
    ///
    /// The backup is not optional and is not a separate tool call. Row 106
    /// built whole-course backups for precisely this scenario — "teachers will
    /// be encouraged to use an LLM for bulk edits, and an LLM can make a mess
    /// that is hard to undo" — so undo is a real button here, not advice.
    /// </summary>
    public async Task<AssistResult> Apply(PublishPlan plan, IProgress<string>? progress = null,
                                          CancellationToken cancellation = default)
    {
        var course = Course(plan.CourseCode);
        int section = Section(course, plan.SectionNumber);

        if (plan.ChangesNothing && !plan.Publishes)
            return new AssistResult(true, "Nothing needed changing.", null);

        // Anything that would make the publish impossible has to be found NOW,
        // before the backup, the edits and a build that takes minutes. Failing
        // at the last step would leave the teacher with changed files, a
        // rebuilt site and a refusal — the worst of all the orders.
        if (plan.Publishes) DeployArguments(course, section);

        string backup;
        progress?.Report($"Backing up {course.Code} first…");
        try { backup = CourseArchiver.BackUpCourse(course, Workspace.CoursesDirectory(_folder)); }
        catch (Exception error)
        {
            // No backup, no edits. This is the one step that has no fallback.
            throw new AssistRefusal(
                $"{course.Code} couldn’t be backed up, so nothing was changed: {error.Message}");
        }

        var changed = new List<string>();
        foreach (var page in plan.Changing)
        {
            string full = PagePaths.ResolveInside(_folder, page.RelativePath);
            string text = File.ReadAllText(full);
            var (updated, edit) = PageFrontmatter.SetDraft(text, page.FrontmatterKey, page.Draft);
            if (!edit.Changed) continue;
            File.WriteAllText(full, updated);
            changed.Add(page.Title);
        }
        if (changed.Count > 0)
            progress?.Report($"Changed {changed.Count} page{(changed.Count == 1 ? "" : "s")}.");

        if (!plan.Publishes)
            return new AssistResult(true, Summary(changed, published: false, course.Code, section), backup);

        progress?.Report($"Building Section {section} of {course.Code}…");
        var build = await _launcher.Run("preview", new[] { course.Code, section.ToString(), "--build-only" },
                                        _folder, progress, cancellation);
        if (!build.Succeeded)
            return new AssistResult(false,
                $"The pages were changed and backed up, but the build failed, so nothing was published. {build.Message}",
                backup);

        progress?.Report($"Publishing to {DestinationOf(course)}…");
        var publish = await _launcher.Run("deploy", DeployArguments(course, section), _folder, progress, cancellation);
        if (!publish.Succeeded)
            return new AssistResult(false,
                $"The pages were changed and backed up, but publishing failed. {publish.Message}", backup);

        return new AssistResult(true, Summary(changed, published: true, course.Code, section), backup);
    }

    private static string Summary(IReadOnlyList<string> changed, bool published, string code, int section)
    {
        string what = changed.Count == 0
            ? "No page needed changing"
            : $"Changed {changed.Count} page{(changed.Count == 1 ? "" : "s")} ({string.Join(", ", changed)})";
        return published ? $"{what}, and republished {code} Section {section}." : what + ".";
    }

    /// <summary>
    /// Why this course cannot be published from here, or null when it can.
    /// A Pages-scoped Cloudflare token cannot list its own account — verified
    /// against a real token — so the account ID lives in Plantoir's settings
    /// and only the app can supply it.
    /// </summary>
    private static string? PublishProblem(Course course) =>
        course.Configuration.DeploysToCloudflare
            ? $"{course.Code} publishes to Cloudflare Pages, which needs the account ID Plantoir stores. " +
              "Publish this section from Plantoir instead."
            : null;

    private string[] DeployArguments(Course course, int section)
    {
        if (PublishProblem(course) is { } problem) throw new AssistRefusal(problem);
        var configuration = course.Configuration;
        if (configuration.DeploysToLocalFolder)
            return new[] { course.Code, section.ToString(), "--to-folder", configuration.DeployFolderPath };
        return new[] { course.Code, section.ToString() };
    }

    /// <summary>A whole-course backup, on its own.</summary>
    public string BackUp(string courseCode)
    {
        var course = Course(courseCode);
        return Relative(CourseArchiver.BackUpCourse(course, Workspace.CoursesDirectory(_folder)));
    }

    // ---- Helpers ---------------------------------------------------------

    private string Relative(string fullPath) =>
        System.IO.Path.GetRelativePath(_folder, fullPath).Replace('\\', '/');

    private static string Humanize(IEnumerable<string> items)
    {
        var list = items.ToList();
        if (list.Count == 0) return "none";
        if (list.Count == 1) return list[0];
        return string.Join(", ", list.Take(list.Count - 1)) + " and " + list[^1];
    }
}

/// <summary>
/// A request that will not be carried out, with a reason a teacher can act on.
/// Never a stack trace, never a code — the assistant reads this back aloud.
/// </summary>
public sealed class AssistRefusal(string message) : Exception(message);

/// <summary>How an operation ended, and where the backup went.</summary>
public sealed record AssistResult(bool Succeeded, string Message, string? BackupPath);

/// <summary>
/// Runs one of the working folder's launchers. Abstracted so the plan logic can
/// be tested without Docker, and so the same operations work on macOS, where
/// the launchers are <c>preview.sh</c> and <c>deploy.sh</c>.
/// </summary>
public interface ILauncherRunner
{
    /// <param name="launcher">"preview" or "deploy" — the implementation adds the extension.</param>
    Task<LaunchOutcome> Run(string launcher, IReadOnlyList<string> arguments, string workingFolder,
                            IProgress<string>? progress, CancellationToken cancellation);
}

/// <summary>The result of one launcher run.</summary>
public readonly record struct LaunchOutcome(bool Succeeded, string Message);
