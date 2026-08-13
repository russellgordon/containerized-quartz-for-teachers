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
    /// The section's CLASS pages — the ones that are days of teaching, in date
    /// order.
    ///
    /// "Class page" is read from the course's own configuration rather than
    /// guessed: it is a page inside one of the course's
    /// <c>per_section_folders</c> (typically "All Classes"), and never an
    /// <c>index.md</c>.
    ///
    /// Both exclusions matter, and the second is the dangerous one. A section's
    /// <c>index.md</c>, its folder indexes and its Key Links page all carry the
    /// SAME date as the first class — so "every class from September 8th"
    /// filtered naively on dates alone would hide the site's own front page.
    /// </summary>
    public List<string> ClassPages(Course course, int sectionNumber)
    {
        var folders = course.Configuration.PerSectionFolders;
        var pages = new List<(DateOnly? Date, string Path)>();

        foreach (string folder in folders)
        {
            string root = Path.Combine(course.SectionDirectory(sectionNumber), folder);
            if (!Directory.Exists(root)) continue;
            foreach (string page in PagePaths.MarkdownPages(root, sectionNumber))
            {
                if (string.Equals(Path.GetFileName(page), "index.md", StringComparison.OrdinalIgnoreCase))
                    continue;
                pages.Add((DateOf(course, sectionNumber, page), page));
            }
        }

        // Dated pages first, in date order; undated ones keep name order after.
        return pages
            .OrderBy(p => p.Date is null)
            .ThenBy(p => p.Date ?? default)
            .ThenBy(p => p.Path, StringComparer.OrdinalIgnoreCase)
            .Select(p => p.Path)
            .ToList();
    }

    /// <summary>
    /// Pages that must never be hidden from students, whatever is asked.
    ///
    /// Two rules, both from the teacher, and both about navigation rather than
    /// content:
    ///
    /// * **Anything Key Links points at.** That page is the section's list of
    ///   things a student needs all year — the curriculum expectations, how
    ///   marks work, where to get help. Hiding one because some class happened
    ///   to link to it takes away the signpost, not the lesson. (In a real
    ///   session a teacher had to protect exactly this set by hand, then
    ///   accept a window where a safety document was hidden, because nothing
    ///   expressed the rule.)
    /// * **Index pages.** <c>All Classes/index.md</c> is where a student who
    ///   missed a class is told to start; a section's own <c>index.md</c> is
    ///   the front door. An index is a way in, not a lesson, and an empty
    ///   folder page is far better than a broken one.
    ///
    /// This constrains the DRAFT FLAG only. Nothing here stops a page's
    /// <c>created</c> date being changed — rolling a course over to a new year
    /// has to be able to move these dates like any others.
    /// </summary>
    public HashSet<string> ProtectedFromHiding(Course course, int sectionNumber)
    {
        var protectedPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (string page in PagePaths.MarkdownPages(course.DirectoryPath, sectionNumber))
        {
            if (string.Equals(Path.GetFileName(page), "index.md", StringComparison.OrdinalIgnoreCase))
                protectedPaths.Add(Path.GetFullPath(page));
        }

        string keyLinks = Path.Combine(course.SectionDirectory(sectionNumber), KeyLinksFileName);
        if (!File.Exists(keyLinks)) return protectedPaths;

        protectedPaths.Add(Path.GetFullPath(keyLinks));
        try
        {
            var resolutions = WikiLinks.Resolve(
                WikiLinks.Parse(File.ReadAllText(keyLinks)), course.DirectoryPath, sectionNumber, keyLinks);
            foreach (var resolution in resolutions)
                if (resolution.Outcome == LinkOutcome.Resolved)
                    protectedPaths.Add(Path.GetFullPath(resolution.Path!));
        }
        catch { /* an unreadable Key Links protects what it already listed */ }

        return protectedPaths;
    }

    /// <summary>The per-section page whose links are the year-round signposts.</summary>
    private const string KeyLinksFileName = "Key Links.md";

    private static DateOnly? DateOf(Course course, int sectionNumber, string pagePath)
    {
        bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, pagePath);
        try { return PageFrontmatter.CreatedOn(File.ReadAllText(pagePath), sectionNumber, sectionLocal); }
        catch { return null; }
    }

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
    /// Work out what publishing (or hiding) these pages would do, without
    /// touching anything. This is what the teacher confirms.
    ///
    /// Takes a LIST, and takes any page — not just a class page. Both of those
    /// came out of a real session that the single-class-page version could not
    /// express:
    ///
    /// * Hiding 25 classes meant 25 calls, each one republishing the site: 26
    ///   deploys for what is logically one change. Batching is not a
    ///   convenience here, it is the difference between usable and not.
    /// * A safety contract linked from BOTH the first class (which must stay
    ///   up) and a later one (which must come down) made the task
    ///   unsatisfiable: <c>includeLinked</c> took it down, and nothing could
    ///   put just that page back. Being able to name any page directly
    ///   dissolves it. That shape — a shared page reachable from several
    ///   classes — is the normal shape of a course, not an edge case.
    /// </summary>
    public PublishPlan PlanPublish(
        string courseCode, int sectionNumber, IReadOnlyList<string> pageTitles,
        bool includeLinked, bool draft = false, bool publishes = true,
        DateOnly? onOrAfter = null, DateOnly? before = null)
    {
        var course = Course(courseCode);
        int section = Section(course, sectionNumber);

        if (pageTitles.Count == 0 && onOrAfter is null && before is null)
            throw new AssistRefusal("No page was named, and no dates were given to choose classes by.");
        if (onOrAfter is { } from && before is { } until && until <= from)
            throw new AssistRefusal(
                $"No class can be on or after {from:yyyy-MM-dd} and also before {until:yyyy-MM-dd}.");

        var problems = new List<string>();
        var pages = new List<PlannedPage>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // Surface it in the PLAN, so the teacher learns the publish can't
        // happen before agreeing to it rather than after.
        if (publishes && PublishProblem(course) is { } blocked) problems.Add(blocked);

        // Hiding, and only hiding, is subject to the never-hide rules.
        var protectedPaths = draft
            ? ProtectedFromHiding(course, section)
            : new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        int protectedLinked = 0;

        var namedPaths = new List<string>();
        foreach (string title in pageTitles)
        {
            string path = Page(course, section, title);
            string full = Path.GetFullPath(path);
            if (!seen.Add(full)) continue;                     // the same page named twice
            if (protectedPaths.Contains(full))
            {
                // Named outright, so say so by name — silently dropping a page
                // somebody explicitly asked for is worse than refusing it.
                problems.Add($"“{Path.GetFileNameWithoutExtension(path)}” is never hidden — " +
                             "it is an index page or something Key Links points at. Left published.");
                continue;
            }
            namedPaths.Add(path);
            pages.Add(Plan(course, section, path, draft, viaLink: false));
        }

        // Dates choose classes IN CODE. A teacher's "every class from the 15th
        // onwards" is a comparison, and comparisons are exactly what a model
        // should never be doing on a teacher's behalf — the whole design moves
        // that work here.
        if (onOrAfter is not null || before is not null)
        {
            var matched = 0;
            foreach (string path in ClassPages(course, section))
            {
                var date = DateOf(course, section, path);
                if (date is null) continue;                     // undated: never swept up by a date rule
                if (onOrAfter is { } start && date < start) continue;
                if (before is { } end && date >= end) continue;
                matched++;
                if (!seen.Add(Path.GetFullPath(path))) continue;
                namedPaths.Add(path);
                pages.Add(Plan(course, section, path, draft, viaLink: false));
            }
            if (matched == 0)
                problems.Add($"No class in {course.Code} Section {section} falls in that date range.");
        }

        if (includeLinked)
        {
            foreach (string path in namedPaths)
            {
                var resolutions = WikiLinks.Resolve(
                    WikiLinks.Parse(File.ReadAllText(path)), course.DirectoryPath, section, path);
                foreach (var resolution in resolutions)
                {
                    if (resolution.Problem is { } problem)
                    {
                        if (!problems.Contains(problem)) problems.Add(problem);
                        continue;
                    }
                    if (resolution.Outcome != LinkOutcome.Resolved) continue;
                    // A page reached from two different classes is one page.
                    string full = Path.GetFullPath(resolution.Path!);
                    if (!seen.Add(full)) continue;
                    // Reached only incidentally, so a count is enough; naming
                    // each one would bury the change the teacher is checking.
                    if (protectedPaths.Contains(full)) { protectedLinked++; continue; }
                    pages.Add(Plan(course, section, resolution.Path!, draft, viaLink: true));
                }
            }
        }

        // Counted while following links above, so it has to be reported after
        // that loop rather than before it.
        if (protectedLinked > 0)
            problems.Add($"{protectedLinked} linked page{(protectedLinked == 1 ? " was" : "s were")} left published: " +
                         "index pages, and the pages Key Links points at, are never hidden.");

        return new PublishPlan
        {
            CourseCode = course.Code,
            SectionNumber = section,
            Pages = pages,
            Problems = problems,
            Publishes = publishes,
            Destination = DestinationOf(course),
            Hiding = draft,
            Dangling = DanglingAfter(course, section, pages),
        };
    }

    /// <summary>
    /// Links a student would meet that lead nowhere, if this plan went ahead.
    ///
    /// Following links one hop is not the same as leaving the site coherent:
    /// publish a class and its concepts, and the curriculum expectations those
    /// concepts point at are still hidden. Rather than expanding the change to
    /// cover them — safe when publishing, dangerous when hiding, since each
    /// extra hop can swallow a page some published class still needs — the
    /// plan reports the consequence and lets the teacher decide.
    /// </summary>
    private List<DanglingLink> DanglingAfter(Course course, int section, IReadOnlyList<PlannedPage> pages)
    {
        LinkGraph graph;
        try { graph = LinkGraph.Build(course.DirectoryPath, section); }
        catch { return new List<DanglingLink>(); }

        var planned = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
        foreach (var page in pages)
        {
            try { planned[PagePaths.ResolveInside(_folder, page.RelativePath)] = page.Draft; }
            catch { }
        }

        return graph.DanglingLinks(path =>
        {
            if (planned.TryGetValue(path, out bool willBeDraft)) return willBeDraft;
            bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, path);
            try
            {
                string key = PageFrontmatter.DraftKeyFor(section, sectionLocal);
                return PageFrontmatter.StoredValue(File.ReadAllText(path), key) ?? false;
            }
            catch { return false; }
        });
    }

    /// <summary>The section's link graph, for the standalone consistency check.</summary>
    public (LinkGraph Graph, Func<string, bool> IsHidden) Inspect(Course course, int section)
    {
        var graph = LinkGraph.Build(course.DirectoryPath, section);
        return (graph, path =>
        {
            bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, path);
            try
            {
                string key = PageFrontmatter.DraftKeyFor(section, sectionLocal);
                return PageFrontmatter.StoredValue(File.ReadAllText(path), key) ?? false;
            }
            catch { return false; }
        }
        );
    }


    private PlannedPage Plan(Course course, int section, string pagePath, bool draft, bool viaLink)
    {
        bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, pagePath);
        string key = PageFrontmatter.DraftKeyFor(section, sectionLocal);
        string text = File.ReadAllText(pagePath);
        return new PlannedPage(
            Title: Path.GetFileNameWithoutExtension(pagePath),
            RelativePath: Relative(pagePath),
            FrontmatterKey: key,
            CurrentValue: PageFrontmatter.StoredValue(text, key),
            Draft: draft,
            ViaLink: viaLink,
            Date: PageFrontmatter.CreatedOn(text, section, sectionLocal));
    }

    /// <summary>
    /// Rebuild and republish a section, changing no content at all.
    ///
    /// Without this there was no way to ask for a deploy on its own, so a real
    /// session ended up calling publish on a page that happened to need no
    /// changes, purely to trigger a rebuild. That only worked by luck.
    /// </summary>
    public async Task<AssistResult> Republish(string courseCode, int sectionNumber,
                                              IProgress<string>? progress = null,
                                              CancellationToken cancellation = default)
    {
        var course = Course(courseCode);
        int section = Section(course, sectionNumber);
        DeployArguments(course, section);   // refuse now if this course can't publish from here

        progress?.Report($"Building Section {section} of {course.Code}…");
        var build = await _launcher.Run("preview", new[] { course.Code, section.ToString(), "--build-only" },
                                        _folder, progress, cancellation);
        if (!build.Succeeded)
            return new AssistResult(false, $"Nothing was changed, and the build failed. {build.Message}", null);

        progress?.Report($"Publishing to {DestinationOf(course)}…");
        var publish = await _launcher.Run("deploy", DeployArguments(course, section), _folder, progress, cancellation);
        return publish.Succeeded
            ? new AssistResult(true, $"Republished {course.Code} Section {section} to {DestinationOf(course)}. No content was changed.", null)
            : new AssistResult(false, $"Nothing was changed, and publishing failed. {publish.Message}", null);
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
                $"{WhatSurvived(changed)}, but the build failed, so nothing was published. {build.Message}",
                backup);

        progress?.Report($"Publishing to {DestinationOf(course)}…");
        var publish = await _launcher.Run("deploy", DeployArguments(course, section), _folder, progress, cancellation);
        if (!publish.Succeeded)
            return new AssistResult(false,
                $"{WhatSurvived(changed)}, but publishing failed. {publish.Message}", backup);

        return new AssistResult(true, Summary(changed, published: true, course.Code, section), backup);
    }

    /// <summary>
    /// What is actually true after a failure, said accurately.
    ///
    /// This used to read "The pages were changed and backed up" whatever
    /// happened — including when the plan had just established that no page
    /// needed changing. A teacher reading that reasonably concludes their
    /// content was modified and goes looking for damage that isn't there.
    /// </summary>
    private static string WhatSurvived(IReadOnlyList<string> changed) =>
        changed.Count == 0
            ? "No page needed changing, and the course was backed up"
            : $"{changed.Count} page{(changed.Count == 1 ? " was" : "s were")} changed and the course was backed up";

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

    // ---- Rolling a course onto a real timetable --------------------------

    /// <summary>
    /// Work out what re-dating this section's classes onto a timetable would
    /// do, without touching anything.
    ///
    /// <paramref name="assignedPages"/> and <paramref name="assignedMeetings"/>
    /// are parallel: the page at each position takes the meeting number at the
    /// same position. Give neither and the classes are spread evenly across
    /// the block — a starting point, not an answer, because which lesson
    /// belongs on which day depends on what is IN the lesson.
    /// </summary>
    public ReDatePlan PlanReDate(
        string courseCode, int sectionNumber, Timetable timetable,
        IReadOnlyList<string> assignedPages, IReadOnlyList<int> assignedMeetings)
    {
        var course = Course(courseCode);
        int section = Section(course, sectionNumber);
        var classPages = ClassPages(course, section);

        if (classPages.Count == 0)
            throw new AssistRefusal($"{course.Code} Section {section} has no class pages to re-date.");
        if (assignedPages.Count != assignedMeetings.Count)
            throw new AssistRefusal(
                $"{assignedPages.Count} pages were given but {assignedMeetings.Count} meeting numbers — " +
                "they have to line up one for one.");

        var chosen = new List<(string Page, Meeting Meeting)>();
        if (assignedPages.Count > 0)
        {
            foreach (var pair in assignedPages.Zip(assignedMeetings))
            {
                string path = Page(course, section, pair.First);
                if (timetable.ByNumber(pair.Second) is not { } meeting)
                    throw new AssistRefusal(
                        $"Block {timetable.Block} has no meeting {pair.Second}. " +
                        $"It runs 1 to {timetable.Meetings.Count}.");
                chosen.Add((path, meeting));
            }
        }
        else
        {
            var spread = timetable.EvenSpread(classPages.Count);
            for (int i = 0; i < classPages.Count && i < spread.Count; i++)
                chosen.Add((classPages[i], spread[i]));
        }

        string tail = SiblingTimeAndOffset(course, section, classPages);
        var dates = new List<PlannedDate>();
        foreach (var (path, meeting) in chosen)
        {
            bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, path);
            dates.Add(new PlannedDate(
                Title: Path.GetFileNameWithoutExtension(path),
                RelativePath: Relative(path),
                FrontmatterKey: PageFrontmatter.CreatedKeyFor(section, sectionLocal),
                Current: DateOf(course, section, path),
                New: meeting.Date,
                MeetingNumber: meeting.Number));
        }

        var materials = ShiftMaterials(course, section, dates);

        return new ReDatePlan
        {
            CourseCode = course.Code,
            SectionNumber = section,
            Block = timetable.Block,
            Dates = dates,
            Materials = materials,
            NonTeachingDays = timetable.NonTeachingDays,
            UnusedMeetings = Math.Max(0, timetable.Meetings.Count - chosen.Count),
            Problems = ProblemsAfter(course, section, dates.Concat(materials).ToList(), tail),
        };
    }

    /// <summary>
    /// Concepts, exercises and tutorials moved by the same number of days as
    /// the lesson that anchors them.
    ///
    /// A material's date was derived from a class in the first place — the
    /// build gives every shared page the date of the first class that links to
    /// it — so moving classes and leaving materials behind breaks a
    /// relationship rather than preserving one. Shifting by a DELTA rather
    /// than assigning the class's date keeps any spacing the teacher set on
    /// purpose.
    ///
    /// The anchor is the linking class whose CURRENT date sits nearest the
    /// material's current date, which is the class the material was dated from
    /// however many terms ago. A page used by several classes therefore
    /// travels with the one that introduced it, not with whichever happens to
    /// come first alphabetically.
    /// </summary>
    private List<PlannedDate> ShiftMaterials(Course course, int section, IReadOnlyList<PlannedDate> classes)
    {
        var shifted = new List<PlannedDate>();
        LinkGraph graph;
        try { graph = LinkGraph.Build(course.DirectoryPath, section); }
        catch { return shifted; }

        var moves = new Dictionary<string, (DateOnly From, DateOnly To)>(StringComparer.OrdinalIgnoreCase);
        foreach (var entry in classes)
        {
            if (entry.Current is not { } from) continue;
            try { moves[PagePaths.ResolveInside(_folder, entry.RelativePath)] = (from, entry.New); }
            catch { }
        }

        var classPaths = new HashSet<string>(
            ClassPages(course, section).Select(Path.GetFullPath), StringComparer.OrdinalIgnoreCase);

        foreach (string page in graph.Pages)
        {
            if (classPaths.Contains(page)) continue;                       // classes are handled above
            if (DateOf(course, section, page) is not { } pageDate) continue;

            (DateOnly From, DateOnly To)? anchor = null;
            int nearest = int.MaxValue;
            foreach (string linker in graph.SourcesOf(page))
            {
                if (!moves.TryGetValue(Path.GetFullPath(linker), out var move)) continue;
                int gap = Math.Abs(move.From.DayNumber - pageDate.DayNumber);
                if (gap < nearest) { nearest = gap; anchor = move; }
            }
            if (anchor is not { } chosen) continue;                        // no class moved that uses this page

            int delta = chosen.To.DayNumber - chosen.From.DayNumber;
            if (delta == 0) continue;

            bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, page);
            shifted.Add(new PlannedDate(
                Title: Path.GetFileNameWithoutExtension(page),
                RelativePath: Relative(page),
                FrontmatterKey: PageFrontmatter.CreatedKeyFor(section, sectionLocal),
                Current: pageDate,
                New: pageDate.AddDays(delta),
                MeetingNumber: 0));
        }
        return shifted;
    }

    /// <summary>
    /// The date problems this re-date would LEAVE — audited against the new
    /// dates, not the current ones, so the teacher sees the world the change
    /// would create rather than the one it replaces.
    /// </summary>
    private List<string> ProblemsAfter(Course course, int section, IReadOnlyList<PlannedDate> dates, string tail)
    {
        var planned = new Dictionary<string, DateOnly>(StringComparer.OrdinalIgnoreCase);
        foreach (var date in dates)
        {
            try { planned[PagePaths.ResolveInside(_folder, date.RelativePath)] = date.New; }
            catch { }
        }

        DateOnly? Resolve(string path) =>
            planned.TryGetValue(Path.GetFullPath(path), out var moved)
                ? moved
                : DateOf(course, section, path);

        LinkGraph graph;
        try { graph = LinkGraph.Build(course.DirectoryPath, section); }
        catch { return new List<string>(); }

        var classPages = ClassPages(course, section);
        var problems = DateAudit.Run(classPages, graph, Resolve, Relative);

        var newDates = dates.Select(d => d.New).ToList();
        if (newDates.Count > 0)
        {
            var others = graph.Pages.Where(p => !classPages.Contains(p)).ToList();
            problems.AddRange(DateAudit.Stragglers(
                others, newDates.Min(), newDates.Max(), Resolve, Relative));
        }
        return problems;
    }

    /// <summary>
    /// The time-of-day and offset a course already uses, so a class that never
    /// had a date joins the convention its siblings follow instead of
    /// inventing one.
    /// </summary>
    private string SiblingTimeAndOffset(Course course, int section, IReadOnlyList<string> classPages)
    {
        foreach (string path in classPages)
        {
            bool sectionLocal = PagePaths.IsSectionLocal(course.DirectoryPath, path);
            string key = PageFrontmatter.CreatedKeyFor(section, sectionLocal);
            try
            {
                string? raw = PageFrontmatter.StoredText(File.ReadAllText(path), key);
                if (raw is { Length: > 10 }) return raw[10..];
            }
            catch { }
        }
        return "T07:00:00.000-0400";
    }

    /// <summary>Carry out a re-date the teacher has agreed to, after backing the course up.</summary>
    public AssistResult ApplyReDate(ReDatePlan plan, IProgress<string>? progress = null)
    {
        var course = Course(plan.CourseCode);
        int section = Section(course, plan.SectionNumber);
        if (plan.ChangesNothing) return new AssistResult(true, "Every class already carries that date.", null);

        string backup;
        progress?.Report($"Backing up {course.Code} first…");
        try { backup = CourseArchiver.BackUpCourse(course, Workspace.CoursesDirectory(_folder)); }
        catch (Exception error)
        {
            throw new AssistRefusal(
                $"{course.Code} couldn’t be backed up, so no dates were changed: {error.Message}");
        }

        string tail = SiblingTimeAndOffset(course, section, ClassPages(course, section));
        int moved = 0;
        foreach (var date in plan.Changing)
        {
            string full = PagePaths.ResolveInside(_folder, date.RelativePath);
            var (updated, changed) = PageFrontmatter.SetCreated(
                File.ReadAllText(full), date.FrontmatterKey, date.New, tail);
            if (!changed) continue;
            File.WriteAllText(full, updated);
            moved++;
        }

        return new AssistResult(true,
            $"Moved {moved} class{(moved == 1 ? "" : "es")} onto block {plan.Block} in " +
            $"{course.Code} Section {section}. Nothing was published — preview or publish the section when ready.",
            backup);
    }

    /// <summary>A whole-course backup, on its own.</summary>
    public string BackUp(string courseCode)
    {
        var course = Course(courseCode);
        return Relative(CourseArchiver.BackUpCourse(course, Workspace.CoursesDirectory(_folder)));
    }

    // ---- Helpers ---------------------------------------------------------

    /// <summary>A path as the teacher sees it: relative to the working folder, forward slashes.</summary>
    public string Relative(string fullPath) =>
        Path.GetRelativePath(_folder, fullPath).Replace('\\', '/');

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
