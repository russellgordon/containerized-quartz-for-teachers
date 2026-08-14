using Plantoir.Core.Assist;

namespace Plantoir.Tests;

/// <summary>
/// "Deploy tomorrow's class at 6:30 AM" — and the warnings that go with it.
/// </summary>
public sealed class ScheduledDeployTests : IDisposable
{
    private readonly string _folder = Path.Combine(Path.GetTempPath(),
        "plantoir-schedule-" + Guid.NewGuid().ToString("N"));
    private readonly FakeLauncher _launcher = new();

    public ScheduledDeployTests()
    {
        string course = Path.Combine(_folder, "courses", "ICS3U");
        Directory.CreateDirectory(Path.Combine(course, "section1", "All Classes"));
        Directory.CreateDirectory(Path.Combine(course, ".netlify_sites"));
        File.WriteAllText(Path.Combine(_folder, "preview.ps1"), "# marker");
        File.WriteAllText(Path.Combine(_folder, "deploy.ps1"), "# marker");
        File.WriteAllText(Path.Combine(course, ".netlify_sites", "section1.json"), "{}");
        File.WriteAllText(Path.Combine(course, "course_config.json"),
            """
            {
              "course_code": "ICS3U",
              "course_name": "Computer Science",
              "deploy_target": "netlify",
              "num_sections": 1,
              "per_section_folders": ["All Classes"],
              "per_section_files": [],
              "section_numbers": [1]
            }
            """);
    }

    private void ClassPage(string title, bool published) =>
        File.WriteAllText(
            Path.Combine(_folder, "courses", "ICS3U", "section1", "All Classes", title + ".md"),
            $"---\ntitle: {title}\npublish: {(published ? "true" : "false")}\n---\nBody.\n");

    public void Dispose()
    {
        try { Directory.Delete(_folder, recursive: true); } catch { }
    }

    private AssistWorkspace Open() => new(_folder, _launcher);
    private static DateTime Tomorrow => DateTime.Now.AddDays(1).Date.AddHours(6).AddMinutes(30);

    [Fact]
    public void ATimeThatHasPassedIsRefused()
    {
        var refusal = Assert.Throws<AssistRefusal>(
            () => Open().PlanScheduledDeploy("ICS3U", 1, DateTime.Now.AddHours(-1)));

        Assert.Contains("has already passed", refusal.Message);
    }

    [Fact]
    public void ItSaysWhatMustBeTrueOfTheComputer()
    {
        string described = Open().PlanScheduledDeploy("ICS3U", 1, Tomorrow).Describe();

        // Said up front, because the alternative is a teacher walking into
        // class to find yesterday's site still up.
        Assert.Contains("switched on, and awake", described);
        Assert.Contains("plugged in, if it is a laptop", described);
        Assert.Contains("lid open", described);
        Assert.Contains("Plantoir does not wake the computer up", described);
    }

    [Fact]
    public void AnUnpublishedClassIsCaughtBeforeTheDeployIsScheduled()
    {
        ClassPage("Unit 2, Day 3", published: false);

        var plan = Open().PlanScheduledDeploy("ICS3U", 1, Tomorrow, new[] { "Unit 2, Day 3" });

        // The failure this exists to prevent: a deploy that runs perfectly at
        // half six and ships a site without tomorrow's class.
        Assert.Equal("Unit 2, Day 3", Assert.Single(plan.UnpublishedClasses));
        Assert.Contains("not published yet", plan.Describe());
        Assert.Contains("Publish first", plan.Describe());
    }

    [Fact]
    public void APublishedClassRaisesNothing()
    {
        ClassPage("Unit 2, Day 3", published: true);

        var plan = Open().PlanScheduledDeploy("ICS3U", 1, Tomorrow, new[] { "Unit 2, Day 3" });

        Assert.Empty(plan.UnpublishedClasses);
        Assert.DoesNotContain("not published yet", plan.Describe());
    }

    [Fact]
    public void ThePlanNamesTheDestinationAndTheTime()
    {
        string described = Open().PlanScheduledDeploy("ICS3U", 1, Tomorrow).Describe();

        Assert.Contains("ICS3U Section 1", described);
        Assert.Contains("Netlify", described);
        Assert.Contains("6:30", described);
    }

    [Fact]
    public void TheTaskNameIsPerSectionSoTwoSectionsDoNotCollide()
    {
        var one = Open().PlanScheduledDeploy("ICS3U", 1, Tomorrow);
        Assert.Equal("Plantoir deploy ICS3U section 1", one.TaskName);
    }
}
