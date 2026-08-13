using Plantoir.Core.Assist;
using Xunit;

namespace Plantoir.Tests;

/// <summary>
/// The operations an assistant is allowed to ask for. These are the tests that
/// stand in for the safety argument: a plan that reads honestly, a refusal
/// that never guesses, and a write that cannot happen without a backup.
/// </summary>
public class AssistWorkspaceTests : IDisposable
{
    private readonly string _folder = Directory.CreateTempSubdirectory("plantoir-assist").FullName;
    private readonly FakeLauncher _launcher = new();

    public AssistWorkspaceTests()
    {
        File.WriteAllText(Path.Combine(_folder, "preview.ps1"), "# marker");
        File.WriteAllText(Path.Combine(_folder, "deploy.ps1"), "# marker");
        AddCourse("ICS3U", "Introduction to Computer Science", 1, 2);
    }

    public void Dispose()
    {
        try { Directory.Delete(_folder, recursive: true); } catch { }
        GC.SuppressFinalize(this);
    }

    private AssistWorkspace Open() => new(_folder, _launcher);

    // ---- Refusals name what exists --------------------------------------

    [Fact]
    public void AnUnknownFolderIsRefusedWithTheReasonAndTheFix()
    {
        string empty = Directory.CreateTempSubdirectory("plantoir-empty").FullName;
        var refusal = Assert.Throws<AssistRefusal>(() => new AssistWorkspace(empty, _launcher));
        Assert.Contains("isn’t a Plantoir working folder", refusal.Message);
        Directory.Delete(empty, recursive: true);
    }

    [Fact]
    public void AnInventedCourseCodeIsRefusedAndTheRealOnesAreNamed()
    {
        // The measured failure this defends against: asked to "clean up my
        // course", the small model proposed backing up MCV4U — a code it made
        // up, for a request naming no course at all.
        var refusal = Assert.Throws<AssistRefusal>(() => Open().Course("MCV4U"));
        Assert.Equal("There’s no course called “MCV4U” in this working folder. The courses here are ICS3U.",
            refusal.Message);
    }

    [Fact]
    public void ACourseCodeIsMatchedWhateverTheCasing()
    {
        Assert.Equal("ICS3U", Open().Course("ics3u").Code);
    }

    [Fact]
    public void AnUnknownSectionIsRefusedAndTheRealOnesAreNamed()
    {
        var workspace = Open();
        var refusal = Assert.Throws<AssistRefusal>(() => workspace.Section(workspace.Course("ICS3U"), 9));
        Assert.Equal("There’s no section 9 in ICS3U. ICS3U has sections 1 and 2.", refusal.Message);
    }

    [Fact]
    public void ATitleMatchingTwoPagesIsRefusedRatherThanPicked()
    {
        // Publishing the wrong page is the failure the whole design exists to
        // avoid, so an ambiguous title is never resolved by choosing.
        Page("ICS3U", "Concepts/Review.md", draftSection1: true);
        Page("ICS3U", "Exercises/Review.md", draftSection1: true);

        var workspace = Open();
        var refusal = Assert.Throws<AssistRefusal>(
            () => workspace.Page(workspace.Course("ICS3U"), 1, "Review"));
        Assert.Contains("has 2 pages called “Review”", refusal.Message);
        Assert.Contains("Say which one you mean.", refusal.Message);
    }

    // ---- The plan --------------------------------------------------------

    [Fact]
    public void ThePlanPicksTheRightKeyForSharedAndSectionLocalPages()
    {
        // The single most error-prone thing in the whole feature, and the one
        // no model should ever be asked to decide.
        Page("ICS3U", "Concepts/Ohm's Law.md", draftSection1: true);
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true,
             body: "Concept: [[Ohm's Law]]");

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: true);

        Assert.Equal("draft", Assert.Single(plan.Named).FrontmatterKey);
        Assert.Equal("draftSection1", Assert.Single(plan.Linked).FrontmatterKey);
    }

    [Fact]
    public void ThePlanReadsAsASentenceATeacherCanCheck()
    {
        Page("ICS3U", "Concepts/Ohm's Law.md", draftSection1: true);
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true,
             body: "Concept: [[Ohm's Law]]");

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: true);

        // Every changing page names its key and its transition. A reader who
        // has only seen class pages would otherwise generalise `draft:` to
        // course-level pages and be wrong — which is exactly what happened.
        Assert.Equal(
            "Publish “Unit 2, Day 3” in ICS3U Section 1, and the 1 page they link to.\n" +
            "All 2 pages would change.\n" +
            "\n" +
            "Would change:\n" +
            "  courses/ICS3U/section1/All Classes/Unit 2, Day 3.md  (draft: true → false)\n" +
            "  courses/ICS3U/Concepts/Ohm's Law.md  (draftSection1: true → false)\n" +
            "\n" +
            "Then republish Section 1 to Netlify.",
            plan.Describe());
    }

    [Fact]
    public void APlanThatWouldChangeNothingSaysSoAndCountsTheLinksItFollowed()
    {
        // Without the count, "and so is everything it links to" reads the same
        // whether resolution worked or silently found nothing.
        Page("ICS3U", "Concepts/Ohm's Law.md", draftSection1: false);
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: false,
             body: "Concept: [[Ohm's Law]]");

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: true);

        Assert.True(plan.ChangesNothing);
        Assert.Contains("and the 1 page they link to", plan.Describe());
        Assert.Contains("all 2 pages are already published", plan.Describe());
    }

    [Fact]
    public void TheLinkCountAndTheChangeCountAreNeverTheSamePhrase()
    {
        // A real session ran the same call twice with a file edited between,
        // got "the 2 pages it links to" and then "the 1 page it links to", and
        // concluded the tool was unreliable. Both answers were right; the
        // phrase was doing two jobs. Now the number of links followed and the
        // number of pages changing are separate sentences.
        Page("ICS3U", "Concepts/Ohm's Law.md", draftSection1: true);
        Page("ICS3U", "Exercises/Ohm's Law Practice.md", draftSection1: false);
        Page("ICS3U", "section1/All Classes/Unit 4, Day 5.md", draft: false,
             body: "[[Ohm's Law]] and [[Ohm's Law Practice]]");

        string description = Open()
            .PlanPublish("ICS3U", 1, new[] { "Unit 4, Day 5" }, includeLinked: true).Describe();

        Assert.Contains("and the 2 pages they link to", description);      // links followed
        Assert.Contains("1 of 3 pages would change", description);          // pages changing
        Assert.Contains("(draftSection1: true → false)", description);      // and the state it saw
    }

    [Fact]
    public void AnUnresolvableLinkIsReportedRatherThanDroppedQuietly()
    {
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true,
             body: "Concept: [[A Page That Does Not Exist]]");

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: true);

        Assert.Equal("“A Page That Does Not Exist” doesn’t match any page in this section.",
            Assert.Single(plan.Problems));
        Assert.Contains("• “A Page That Does Not Exist” doesn’t match", plan.Describe());
    }

    [Fact]
    public void HidingIsPlannedWithTheOppositePolarity()
    {
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: false);
        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: false, draft: true);
        Assert.StartsWith("Hide “Unit 2, Day 3” in ICS3U Section 1.", plan.Describe());
        Assert.True(Assert.Single(plan.Named).WillChange);
    }

    // ---- What the single-page surface could not express -------------------

    [Fact]
    public void SeveralPagesArePlannedAsOneChange()
    {
        // 25 classes used to mean 25 calls and 25 deploys.
        for (int day = 2; day <= 5; day++)
            Page("ICS3U", $"section1/All Classes/Unit 1, Day {day}.md", draft: false);

        var plan = Open().PlanPublish("ICS3U", 1,
            new[] { "Unit 1, Day 2", "Unit 1, Day 3", "Unit 1, Day 4", "Unit 1, Day 5" },
            includeLinked: false, draft: true);

        Assert.Equal(4, plan.Named.Count());
        Assert.StartsWith("Hide 4 pages in ICS3U Section 1.", plan.Describe());
    }

    [Fact]
    public void ACourseLevelPageCanBeNamedDirectly()
    {
        // The Safety Contract case: a page linked from a class that must stay
        // up AND one that must come down. Naming it directly is the only way
        // to express "leave this one alone" — with class-page-only tools the
        // constraint was unsatisfiable.
        Page("ICS3U", "Setup/Safety Contract.md", draftSection1: true);

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Safety Contract" }, includeLinked: false);

        var page = Assert.Single(plan.Named);
        Assert.Equal("draftSection1", page.FrontmatterKey);
        Assert.True(page.WillChange);
    }

    [Fact]
    public void APageReachedFromTwoClassesIsCountedOnce()
    {
        Page("ICS3U", "Setup/Safety Contract.md", draftSection1: false);
        Page("ICS3U", "section1/All Classes/Unit 1, Day 2.md", draft: false, body: "[[Safety Contract]]");
        Page("ICS3U", "section1/All Classes/Unit 1, Day 3.md", draft: false, body: "[[Safety Contract]]");

        var plan = Open().PlanPublish("ICS3U", 1,
            new[] { "Unit 1, Day 2", "Unit 1, Day 3" }, includeLinked: true, draft: true);

        Assert.Single(plan.Linked);
        Assert.Equal(3, plan.Pages.Count);
    }

    [Fact]
    public async Task RepublishingRunsTheLaunchersAndChangesNoContent()
    {
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true);
        var workspace = Open();

        var result = await workspace.Republish("ICS3U", 1);

        Assert.True(result.Succeeded);
        Assert.Contains("No content was changed.", result.Message);
        Assert.Equal(new[] { "preview", "deploy" }, _launcher.Runs.Select(r => r.Launcher));
        Assert.Contains("draft: true",
            File.ReadAllText(Path.Combine(_folder, "courses", "ICS3U", "section1", "All Classes", "Unit 2, Day 3.md")));
    }

    // ---- Applying --------------------------------------------------------

    [Fact]
    public async Task ApplyingBacksUpBeforeItChangesAnything()
    {
        // Row 106 built whole-course backups for exactly this scenario, so
        // undo is a real button rather than advice.
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true);
        var workspace = Open();
        var plan = workspace.PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: false, publishes: false);

        var result = await workspace.Apply(plan);

        Assert.True(result.Succeeded);
        Assert.NotNull(result.BackupPath);
        Assert.True(File.Exists(result.BackupPath));
    }

    [Fact]
    public async Task ApplyingOnlyTouchesTheRequestedSectionsFlag()
    {
        Page("ICS3U", "Concepts/Ohm's Law.md", draftSection1: true, draftSection2: true);
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true, body: "Concept: [[Ohm's Law]]");

        var workspace = Open();
        await workspace.Apply(workspace.PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: true, publishes: false));

        string text = File.ReadAllText(Path.Combine(_folder, "courses", "ICS3U", "Concepts", "Ohm's Law.md"));
        Assert.Contains("draftSection1: false", text);
        Assert.Contains("draftSection2: true", text);   // section 2 is none of this operation's business
    }

    [Fact]
    public async Task PublishingRunsTheBuildAndThenTheDeployLauncher()
    {
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true);
        var workspace = Open();

        await workspace.Apply(workspace.PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: false));

        Assert.Equal(2, _launcher.Runs.Count);
        Assert.Equal("preview", _launcher.Runs[0].Launcher);
        Assert.Equal(new[] { "ICS3U", "1", "--build-only" }, _launcher.Runs[0].Arguments);
        Assert.Equal("deploy", _launcher.Runs[1].Launcher);
        Assert.Equal(new[] { "ICS3U", "1" }, _launcher.Runs[1].Arguments);
    }

    [Fact]
    public async Task AFailedBuildStopsBeforePublishingAndSaysWhatSurvived()
    {
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: true);
        _launcher.FailOn = "preview";
        var workspace = Open();

        var result = await workspace.Apply(workspace.PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: false));

        Assert.False(result.Succeeded);
        Assert.Contains("nothing was published", result.Message);
        Assert.Single(_launcher.Runs);                       // deploy never ran
        Assert.NotNull(result.BackupPath);                   // and the backup is still there
    }

    [Fact]
    public async Task AFailureDoesNotClaimPagesChangedWhenNoneDid()
    {
        // This message used to read "The pages were changed and backed up"
        // whatever happened — including when the plan had just established
        // that nothing needed changing. A teacher reading that goes looking
        // for damage that was never done.
        Page("ICS3U", "section1/All Classes/Unit 2, Day 3.md", draft: false);
        _launcher.FailOn = "preview";
        var workspace = Open();

        var result = await workspace.Apply(
            workspace.PlanPublish("ICS3U", 1, new[] { "Unit 2, Day 3" }, includeLinked: false));

        Assert.False(result.Succeeded);
        Assert.StartsWith("No page needed changing, and the course was backed up", result.Message);
        Assert.DoesNotContain("pages were changed", result.Message);
    }

    [Fact]
    public async Task ACloudflareCourseIsRefusedWithTheReasonAndWhereToGo()
    {
        // A Pages-scoped token cannot list its own account, so the account ID
        // lives in Plantoir's settings and only the app can supply it.
        AddCourse("SNC1W", "Science", 1, deployTarget: "cloudflare_pages");
        Page("SNC1W", "section1/All Classes/Unit 1, Day 1.md", draft: true);
        var workspace = Open();
        var plan = workspace.PlanPublish("SNC1W", 1, new[] { "Unit 1, Day 1" }, includeLinked: false);

        var refusal = await Assert.ThrowsAsync<AssistRefusal>(() => workspace.Apply(plan));

        Assert.Contains("publishes to Cloudflare Pages", refusal.Message);
        Assert.Contains("Publish this section from Plantoir instead.", refusal.Message);

        // And it refused BEFORE doing anything. Discovering this at the deploy
        // step would leave the teacher with edited pages, a rebuilt site and a
        // refusal — the worst possible order.
        string page = File.ReadAllText(Path.Combine(
            _folder, "courses", "SNC1W", "section1", "All Classes", "Unit 1, Day 1.md"));
        Assert.Contains("draft: true", page);              // never edited
        Assert.Empty(_launcher.Runs);                      // never built
        Assert.False(Directory.Exists(Path.Combine(_folder, "courses", "_backups")));   // never backed up
    }

    [Fact]
    public void ThePlanSaysUpFrontThatACloudflareCourseCannotBePublishedFromHere()
    {
        AddCourse("SNC1W", "Science", 1, deployTarget: "cloudflare_pages");
        Page("SNC1W", "section1/All Classes/Unit 1, Day 1.md", draft: true);

        var plan = Open().PlanPublish("SNC1W", 1, new[] { "Unit 1, Day 1" }, includeLinked: false);

        Assert.Contains(plan.Problems, p => p.Contains("Cloudflare Pages"));
        Assert.Contains("Publish this section from Plantoir instead.", plan.Describe());
    }

    // ---- Fixtures --------------------------------------------------------

    private void AddCourse(string code, string name, params int[] sections) =>
        AddCourse(code, name, sections.Length == 0 ? new[] { 1 } : sections, "netlify");

    private void AddCourse(string code, string name, int section, string deployTarget) =>
        AddCourse(code, name, new[] { section }, deployTarget);

    private void AddCourse(string code, string name, int[] sections, string deployTarget)
    {
        string directory = Path.Combine(_folder, "courses", code);
        Directory.CreateDirectory(directory);
        File.WriteAllText(Path.Combine(directory, "course_config.json"),
            $$"""
            {
              "course_code": "{{code}}",
              "course_name": "{{name}}",
              "deploy_target": "{{deployTarget}}",
              "num_sections": {{sections.Length}},
              "section_numbers": [{{string.Join(", ", sections)}}]
            }
            """);
    }

    private void Page(string course, string relative, bool? draft = null,
                      bool? draftSection1 = null, bool? draftSection2 = null, string body = "Body.")
    {
        string full = Path.Combine(_folder, "courses", course,
            relative.Replace('/', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(Path.GetDirectoryName(full)!);

        var frontmatter = new List<string>();
        if (draft is { } d) frontmatter.Add($"draft: {(d ? "true" : "false")}");
        if (draftSection1 is { } one) frontmatter.Add($"draftSection1: {(one ? "true" : "false")}");
        if (draftSection2 is { } two) frontmatter.Add($"draftSection2: {(two ? "true" : "false")}");

        File.WriteAllText(full, "---\n" + string.Join("\n", frontmatter) + "\n---\n" + body + "\n");
    }
}

/// <summary>Records launcher runs instead of starting Docker.</summary>
internal sealed class FakeLauncher : ILauncherRunner
{
    public record Run(string Launcher, string[] Arguments);

    public List<Run> Runs { get; } = new();

    /// <summary>Which launcher, if any, should report failure.</summary>
    public string? FailOn { get; set; }

    Task<LaunchOutcome> ILauncherRunner.Run(string launcher, IReadOnlyList<string> arguments,
                                            string workingFolder, IProgress<string>? progress,
                                            CancellationToken cancellation)
    {
        Runs.Add(new Run(launcher, arguments.ToArray()));
        return Task.FromResult(launcher == FailOn
            ? new LaunchOutcome(false, "It went wrong.")
            : new LaunchOutcome(true, "Done."));
    }
}
