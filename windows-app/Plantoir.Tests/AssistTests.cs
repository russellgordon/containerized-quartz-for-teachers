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

    // ---- Pages that are never hidden -------------------------------------

    [Fact]
    public void APageKeyLinksPointsAtIsNeverHiddenByALinkSweep()
    {
        // Key Links is the section's year-round signposts. Hiding one because
        // some class happened to link to it takes away the signpost, not the
        // lesson — a teacher had to protect exactly this set by hand.
        Page("ICS3U", "section1/Key Links.md", draft: false, body: "- [[How Marks Work]]");
        Page("ICS3U", "Setup/How Marks Work.md", draftSection1: false);
        Class("ICS3U", "Unit 1, Day 2", "2026-09-09");
        File.AppendAllText(Path.Combine(_folder, "courses", "ICS3U",
            "section1", "All Classes", "Unit 1, Day 2.md"), "See [[How Marks Work]].\n");

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 1, Day 2" },
            includeLinked: true, draft: true);

        Assert.DoesNotContain(plan.Pages, p => p.Title == "How Marks Work");
        Assert.Contains(plan.Problems, p => p.Contains("left published"));
    }

    [Fact]
    public void NamingAProtectedPageOutrightSaysSoByName()
    {
        // Silently dropping a page somebody explicitly asked for is worse
        // than telling them it will not happen.
        Page("ICS3U", "section1/Key Links.md", draft: false, body: "- [[How Marks Work]]");
        Page("ICS3U", "Setup/How Marks Work.md", draftSection1: false);

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "How Marks Work" },
            includeLinked: false, draft: true);

        Assert.Contains(plan.Problems, p => p.Contains("“How Marks Work” is never hidden"));
        Assert.Empty(plan.Pages);
    }

    [Fact]
    public void AnIndexPageIsNeverHidden()
    {
        // All Classes/index.md is where a student who missed a class is told
        // to start. (Only one index here: two would be an ambiguous title,
        // which is a different refusal and would hide what this is testing.)
        Page("ICS3U", "section1/All Classes/index.md", draft: false);

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "index" }, includeLinked: false, draft: true);

        Assert.Contains(plan.Problems, p => p.Contains("is never hidden"));
        Assert.Empty(plan.Pages);
    }

    [Fact]
    public void ProtectionAppliesToHidingOnlyNotPublishing()
    {
        Page("ICS3U", "section1/Key Links.md", draft: false, body: "- [[How Marks Work]]");
        Page("ICS3U", "Setup/How Marks Work.md", draftSection1: true);

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "How Marks Work" },
            includeLinked: false, draft: false);

        Assert.True(Assert.Single(plan.Named).WillChange);   // publishing it is fine
        Assert.Empty(plan.Problems);
    }

    // ---- What students would actually meet -------------------------------

    [Fact]
    public void ThePlanWarnsWhenAVisiblePageWouldPointAtAHiddenOne()
    {
        // The depth problem: a class links to a Concept, the Concept links to
        // a curriculum expectation. Publishing one hop leaves the second hop
        // hidden, so a published page points at a page that is not there.
        Class("ICS3U", "Unit 1, Day 2", "2026-09-09");
        File.AppendAllText(Path.Combine(_folder, "courses", "ICS3U",
            "section1", "All Classes", "Unit 1, Day 2.md"), "Concept: [[Ohm's Law]]\n");
        Page("ICS3U", "Concepts/Ohm's Law.md", draftSection1: true, body: "See [[E2.6]].");
        Page("ICS3U", "Curriculum/E2.6.md", draftSection1: true);

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 1, Day 2" }, includeLinked: true);

        var dangling = Assert.Single(plan.Dangling);
        Assert.EndsWith("Ohm's Law.md", dangling.From, StringComparison.Ordinal);
        Assert.EndsWith("E2.6.md", dangling.To, StringComparison.Ordinal);
        Assert.Contains("would point at a hidden page", plan.Describe());
    }

    [Fact]
    public void ThePlanWarnsWhenHidingBreaksAPageThatStaysVisible()
    {
        // The same defect from the other end, and the reason hiding must not
        // silently follow links to the end: a page some published class still
        // needs would be swallowed.
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");
        File.AppendAllText(Path.Combine(_folder, "courses", "ICS3U",
            "section1", "All Classes", "Unit 1, Day 1.md"), "Concept: [[Photosynthesis]]\n");
        Page("ICS3U", "Concepts/Photosynthesis.md", draftSection1: false);

        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Photosynthesis" },
            includeLinked: false, draft: true);

        var dangling = Assert.Single(plan.Dangling);
        Assert.EndsWith("Unit 1, Day 1.md", dangling.From, StringComparison.Ordinal);
    }

    [Fact]
    public void AConsistentPlanWarnsAboutNothing()
    {
        Class("ICS3U", "Unit 1, Day 2", "2026-09-09");
        var plan = Open().PlanPublish("ICS3U", 1, new[] { "Unit 1, Day 2" }, includeLinked: true, draft: true);
        Assert.Empty(plan.Dangling);
        Assert.DoesNotContain("point at a hidden page", plan.Describe());
    }

    [Fact]
    public void UnreferencedPagesAreFoundBecauseNoLinkRuleEverWill()
    {
        // Quartz publishes every non-draft page and lists it in the explorer,
        // so a page nothing links to is still visible to students.
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");
        Page("ICS3U", "Concepts/Astronomical Phenomena.md", draftSection1: false);

        var workspace = Open();
        var (graph, _) = workspace.Inspect(workspace.Course("ICS3U"), 1);

        Assert.Contains(graph.Unreferenced(),
            p => p.EndsWith("Astronomical Phenomena.md", StringComparison.Ordinal));
    }

    // ---- Choosing classes by date ----------------------------------------

    [Fact]
    public void ClassesCanBeChosenByDateRatherThanNamed()
    {
        // "Every class from the 15th onwards" is a comparison, and comparisons
        // are what the model must never be doing on a teacher's behalf.
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");
        Class("ICS3U", "Unit 1, Day 2", "2026-09-09");
        Class("ICS3U", "Unit 1, Day 3", "2026-09-15");
        Class("ICS3U", "Unit 1, Day 4", "2026-09-16");

        var plan = Open().PlanPublish("ICS3U", 1, Array.Empty<string>(),
            includeLinked: false, draft: true, onOrAfter: new DateOnly(2026, 9, 15));

        Assert.Equal(new[] { "Unit 1, Day 3", "Unit 1, Day 4" },
            plan.Named.Select(p => p.Title));
    }

    [Fact]
    public void ADateRangeExcludesItsEndDate()
    {
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");
        Class("ICS3U", "Unit 1, Day 2", "2026-09-15");

        var plan = Open().PlanPublish("ICS3U", 1, Array.Empty<string>(),
            includeLinked: false, draft: true, before: new DateOnly(2026, 9, 15));

        Assert.Equal("Unit 1, Day 1", Assert.Single(plan.Named).Title);
    }

    [Fact]
    public void ADateRuleNeverSweepsUpTheSectionsOwnIndexPages()
    {
        // The dangerous case, and the reason "class page" is read from
        // per_section_folders rather than from dates alone: a section's
        // index.md, its folder index and its Key Links page all carry the SAME
        // date as the first class. Hiding them takes down the site's front
        // door for a request that only mentioned classes.
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");
        Dated("ICS3U", "section1/index.md", "2026-09-08");
        Dated("ICS3U", "section1/All Classes/index.md", "2026-09-08");
        Dated("ICS3U", "section1/Key Links.md", "2026-09-08");

        var plan = Open().PlanPublish("ICS3U", 1, Array.Empty<string>(),
            includeLinked: false, draft: true, onOrAfter: new DateOnly(2026, 9, 1));

        Assert.Equal("Unit 1, Day 1", Assert.Single(plan.Named).Title);
        Assert.DoesNotContain(plan.Pages, p => p.RelativePath.EndsWith("index.md", StringComparison.Ordinal));
        Assert.DoesNotContain(plan.Pages, p => p.RelativePath.EndsWith("Key Links.md", StringComparison.Ordinal));
    }

    [Fact]
    public void AnUndatedClassIsNeverSweptUpByADateRule()
    {
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");
        Page("ICS3U", "section1/All Classes/Scratch.md", draft: false);   // no date at all

        var plan = Open().PlanPublish("ICS3U", 1, Array.Empty<string>(),
            includeLinked: false, draft: true, onOrAfter: new DateOnly(2026, 1, 1));

        Assert.Equal("Unit 1, Day 1", Assert.Single(plan.Named).Title);
    }

    [Fact]
    public void ADateRangeMatchingNothingSaysSoRatherThanPlanningAnEmptyChange()
    {
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");

        var plan = Open().PlanPublish("ICS3U", 1, Array.Empty<string>(),
            includeLinked: false, draft: true, onOrAfter: new DateOnly(2027, 1, 1));

        Assert.Contains("No class in ICS3U Section 1 falls in that date range.", plan.Problems);
        // And it says that rather than "hide 0 pages … all 0 are already hidden".
        Assert.StartsWith("No pages were selected in ICS3U Section 1, so there is nothing to do.",
            plan.Describe());
        Assert.True(plan.ChangesNothing);
    }

    [Fact]
    public void AnImpossibleDateRangeIsRefusedRatherThanSilentlyEmpty()
    {
        Class("ICS3U", "Unit 1, Day 1", "2026-09-08");
        var refusal = Assert.Throws<AssistRefusal>(() => Open().PlanPublish("ICS3U", 1,
            Array.Empty<string>(), includeLinked: false, draft: true,
            onOrAfter: new DateOnly(2026, 10, 1), before: new DateOnly(2026, 9, 1)));
        Assert.Equal("No class can be on or after 2026-10-01 and also before 2026-09-01.", refusal.Message);
    }

    [Fact]
    public void NamingNothingAndGivingNoDatesIsRefused()
    {
        var refusal = Assert.Throws<AssistRefusal>(() => Open().PlanPublish("ICS3U", 1,
            Array.Empty<string>(), includeLinked: false));
        Assert.Equal("No page was named, and no dates were given to choose classes by.", refusal.Message);
    }

    [Fact]
    public void ThePlanShowsEachClassesDateSoADateRangeCanBeChecked()
    {
        Class("ICS3U", "Unit 1, Day 2", "2026-09-09");
        var plan = Open().PlanPublish("ICS3U", 1, Array.Empty<string>(),
            includeLinked: false, draft: true, onOrAfter: new DateOnly(2026, 9, 1));
        Assert.Contains("(2026-09-09, draft: false → true)", plan.Describe());
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
              "per_section_folders": ["All Classes"],
              "per_section_files": ["Key Links.md"],
              "section_numbers": [{{string.Join(", ", sections)}}]
            }
            """);
    }

    /// <summary>A class page: inside the per-section folder, with a date.</summary>
    private void Class(string course, string title, string date) =>
        Dated(course, $"section1/All Classes/{title}.md", date);

    private void Dated(string course, string relative, string date)
    {
        string full = Path.Combine(_folder, "courses", course,
            relative.Replace('/', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(Path.GetDirectoryName(full)!);
        File.WriteAllText(full,
            $"---\ndraft: false\ncreated: {date}T07:00:00.000-0400\n---\nBody.\n");
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
