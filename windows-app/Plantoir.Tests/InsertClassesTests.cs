using Plantoir.Core.Assist;

namespace Plantoir.Tests;

/// <summary>
/// Making room part-way through a unit that is already built out — the change
/// that renames pages a teacher's links point at, and so the one that has to
/// say exactly what it will do before it does it.
/// </summary>
public sealed class InsertClassesTests : IDisposable
{
    private readonly string _folder = Path.Combine(Path.GetTempPath(),
        "plantoir-insert-" + Guid.NewGuid().ToString("N"));
    private readonly FakeLauncher _launcher = new();

    public InsertClassesTests()
    {
        Directory.CreateDirectory(Path.Combine(_folder, "courses", "ICS3U", "section1", "All Classes"));
        File.WriteAllText(Path.Combine(_folder, "preview.ps1"), "# marker");
        File.WriteAllText(Path.Combine(_folder, "deploy.ps1"), "# marker");
        File.WriteAllText(Path.Combine(_folder, "courses", "ICS3U", "course_config.json"),
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

        TimetableMemory.Write(_folder, "ICS3U", 1,
            Enumerable.Range(0, 12).Select(i => new DateOnly(2026, 9, 8).AddDays(i * 2)),
            "block H", new DateOnly(2026, 8, 14));
    }

    public void Dispose()
    {
        try { Directory.Delete(_folder, recursive: true); } catch { }
    }

    private AssistWorkspace Open() => new(_folder, _launcher);

    private string ClassPath(string title) =>
        Path.Combine(_folder, "courses", "ICS3U", "section1", "All Classes", title + ".md");

    /// <summary>Four classes: Unit 1 Days 1-2, Unit 2 Days 1-2, on consecutive meeting days.</summary>
    private void FourClasses()
    {
        var dates = new[] { "2026-09-08", "2026-09-10", "2026-09-12", "2026-09-14" };
        string[] titles = ["Unit 1, Day 1", "Unit 1, Day 2", "Unit 2, Day 1", "Unit 2, Day 2"];
        for (int i = 0; i < titles.Length; i++)
            File.WriteAllText(ClassPath(titles[i]),
                $"---\ntitle: {titles[i]}\npublish: true\ncreated: {dates[i]}T07:00:00.000-0400\n---\nBody.\n");
    }

    // ---- What it plans ----------------------------------------------------

    [Fact]
    public void LaterDaysOfTheSameUnitAreRenamed()
    {
        FourClasses();

        var plan = Open().PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        // Unit 2 renumbers; Unit 1 is untouched.
        Assert.Equal(new[] { ("Unit 2, Day 2", "Unit 2, Day 3"), ("Unit 2, Day 1", "Unit 2, Day 2") },
                     plan.Renames.Select(r => (r.From, r.To)));
    }

    [Fact]
    public void RenamesRunHighestDayFirstSoTheyNeverCollide()
    {
        FourClasses();

        var plan = Open().PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        // Renaming Day 1 -> Day 2 before Day 2 -> Day 3 would overwrite a
        // real lesson. Order is part of the plan, not an implementation detail.
        Assert.Equal("Unit 2, Day 2", plan.Renames[0].From);
    }

    [Fact]
    public void ALaterUnitKeepsItsNameButMovesToALaterDay()
    {
        FourClasses();

        var plan = Open().PlanInsertClasses("ICS3U", 1, unit: 1, atDay: 2, count: 1);

        // Unit 2's classes are still Unit 2's classes; they just happen later.
        Assert.DoesNotContain(plan.Renames, r => r.From.StartsWith("Unit 2"));
        Assert.Contains(plan.Moves, m => m.Title == "Unit 2, Day 1");
    }

    [Fact]
    public void ItCountsTheLinksThatWouldFollowARename()
    {
        FourClasses();
        File.WriteAllText(ClassPath("Unit 1, Day 1"),
            "---\ntitle: Unit 1, Day 1\npublish: true\ncreated: 2026-09-08T07:00:00.000-0400\n---\n" +
            "See [[Unit 2, Day 2]] and again [[Unit 2, Day 2|the task day]].\n");

        var plan = Open().PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        // The number a teacher cannot check without opening every page.
        Assert.Equal(2, plan.LinksToRewrite);
        Assert.Contains("2 links point at those names", plan.Describe());
    }

    [Fact]
    public void RunningOutOfClassDaysChangesNothingAndSaysHowManyAreNeeded()
    {
        FourClasses();
        TimetableMemory.Write(_folder, "ICS3U", 1,
            new[] { new DateOnly(2026, 9, 8), new DateOnly(2026, 9, 10),
                    new DateOnly(2026, 9, 12), new DateOnly(2026, 9, 14) },
            "block H", new DateOnly(2026, 8, 14));

        var plan = Open().PlanInsertClasses("ICS3U", 1, unit: 1, atDay: 1, count: 3);

        Assert.True(plan.ChangesNothing);
        Assert.Contains(plan.Problems, p => p.Contains("Add 3 more class dates"));
    }

    [Fact]
    public void PagesNotNamedUnitAndDayAreLeftAloneAndSaidSo()
    {
        FourClasses();
        File.WriteAllText(ClassPath("Field Trip"),
            "---\ntitle: Field Trip\npublish: true\ncreated: 2026-09-16T07:00:00.000-0400\n---\nOut.\n");

        var plan = Open().PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        Assert.Contains(plan.Problems, p => p.Contains("not named"));
        Assert.DoesNotContain(plan.Renames, r => r.From == "Field Trip");
        Assert.DoesNotContain(plan.Moves, m => m.Title == "Field Trip");
    }

    // ---- What it does -----------------------------------------------------

    [Fact]
    public void ApplyingRenamesTheFilesAndTheirTitles()
    {
        FourClasses();
        var workspace = Open();
        var plan = workspace.PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        workspace.ApplyInsertClasses(plan);

        Assert.True(File.Exists(ClassPath("Unit 2, Day 3")));
        // The title inside must follow the file name, or the site shows one
        // name and the sidebar another.
        Assert.Contains("title: Unit 2, Day 3", File.ReadAllText(ClassPath("Unit 2, Day 3")));
        Assert.Contains("title: Unit 2, Day 2", File.ReadAllText(ClassPath("Unit 2, Day 2")));
    }

    [Fact]
    public void ApplyingFollowsTheLinks()
    {
        FourClasses();
        File.WriteAllText(ClassPath("Unit 1, Day 1"),
            "---\ntitle: Unit 1, Day 1\npublish: true\ncreated: 2026-09-08T07:00:00.000-0400\n---\n" +
            "Next: [[Unit 2, Day 2]] and ![[Unit 2, Day 2]] and [[Unit 2, Day 2|the task day]].\n");

        var workspace = Open();
        var plan = workspace.PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);
        workspace.ApplyInsertClasses(plan);

        string text = File.ReadAllText(ClassPath("Unit 1, Day 1"));
        Assert.Contains("[[Unit 2, Day 3]]", text);
        Assert.Contains("![[Unit 2, Day 3]]", text);
        // The alias is the teacher's own words and stays exactly as written.
        Assert.Contains("[[Unit 2, Day 3|the task day]]", text);
        Assert.DoesNotContain("Unit 2, Day 2]]", text);
    }

    [Fact]
    public void EveryLinkFormObsidianWritesSurvivesTheRename()
    {
        // Obsidian rewrites links itself when IT does the rename — but this
        // rename happens on disk from another process, which Obsidian sees as
        // a delete and a create and leaves links alone, and it may not even be
        // running. So Plantoir has to handle every form Obsidian can write.
        FourClasses();
        File.WriteAllText(ClassPath("Unit 1, Day 1"),
            "---\ntitle: Unit 1, Day 1\npublish: true\ncreated: 2026-09-08T07:00:00.000-0400\n---\n" +
            "Plain [[Unit 2, Day 2]]\n" +
            "Alias [[Unit 2, Day 2|the task day]]\n" +
            "Embed ![[Unit 2, Day 2]]\n" +
            "Heading [[Unit 2, Day 2#Agenda]]\n" +
            "Block [[Unit 2, Day 2#^abc123]]\n" +
            "Heading with alias [[Unit 2, Day 2#Agenda|what we did]]\n");

        var workspace = Open();
        var plan = workspace.PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);
        workspace.ApplyInsertClasses(plan);

        string text = File.ReadAllText(ClassPath("Unit 1, Day 1"));
        Assert.Contains("Plain [[Unit 2, Day 3]]", text);
        Assert.Contains("Alias [[Unit 2, Day 3|the task day]]", text);
        Assert.Contains("Embed ![[Unit 2, Day 3]]", text);
        // The heading and block anchors point INSIDE the page and must survive
        // untouched — only the page name changed.
        Assert.Contains("Heading [[Unit 2, Day 3#Agenda]]", text);
        Assert.Contains("Block [[Unit 2, Day 3#^abc123]]", text);
        Assert.Contains("Heading with alias [[Unit 2, Day 3#Agenda|what we did]]", text);
        // And nothing still points at the old name.
        Assert.DoesNotContain("Unit 2, Day 2", text);
    }

    [Fact]
    public void ApplyingCreatesTheNewClassUnpublished()
    {
        FourClasses();
        var workspace = Open();
        var plan = workspace.PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        workspace.ApplyInsertClasses(plan);

        string created = File.ReadAllText(ClassPath("Unit 2, Day 1"));
        Assert.Contains("publish: false", created);
        Assert.Contains("## Agenda", created);
    }

    [Fact]
    public void ApplyingMovesTheDatesOntoRealClassDays()
    {
        FourClasses();
        var workspace = Open();
        var plan = workspace.PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        workspace.ApplyInsertClasses(plan);

        // The new class takes 12 September; what was there moves to the 14th
        // and the 16th — both real meeting days, not "the next day".
        Assert.Contains("created: 2026-09-12", File.ReadAllText(ClassPath("Unit 2, Day 1")));
        Assert.Contains("created: 2026-09-14", File.ReadAllText(ClassPath("Unit 2, Day 2")));
        Assert.Contains("created: 2026-09-16", File.ReadAllText(ClassPath("Unit 2, Day 3")));
        // And the classes before the insertion point never moved.
        Assert.Contains("created: 2026-09-08", File.ReadAllText(ClassPath("Unit 1, Day 1")));
    }

    [Fact]
    public void ApplyingBacksUpFirst()
    {
        FourClasses();
        var workspace = Open();
        var plan = workspace.PlanInsertClasses("ICS3U", 1, unit: 2, atDay: 1, count: 1);

        var result = workspace.ApplyInsertClasses(plan);

        Assert.True(result.Succeeded);
        Assert.NotNull(result.BackupPath);
        Assert.True(File.Exists(result.BackupPath));
    }

    [Fact]
    public void WithoutATimetableItAsksRatherThanGuessing()
    {
        FourClasses();
        File.Delete(Path.Combine(_folder, "courses", "ICS3U", ".internal", "timetable", "section1.json"));

        var refusal = Assert.Throws<AssistRefusal>(
            () => Open().PlanInsertClasses("ICS3U", 1, 2, 1, 1));

        Assert.Contains("remember_timetable", refusal.Message);
    }
}
