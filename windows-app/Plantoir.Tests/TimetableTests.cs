using Plantoir.Core.Assist;
using Plantoir.Core.Models;
using Xunit;

namespace Plantoir.Tests;

/// <summary>
/// Reading a school timetable, and rolling a course onto it. Shaped from a
/// real sheet: paired date/marker columns per block, dates with no year, and
/// rows that are days the school knows about but nobody teaches on.
/// </summary>
public class TimetableTests
{
    private const string Sheet =
        ",,,,,,\n" +
        "Instructions,,,,,,\n" +
        "\"- Each course location is a letter.\n- Copy the columns you need.\",,,,,,\n" +
        ",,,,,,\n" +
        "A,,B,,F,,\n" +
        "Sep-21,1,Sep-21,1,Oct-13,1,\n" +
        "Sep-22,2,Sep-22,2,Oct-14,2,\n" +
        "Oct-9,MB,Oct-9,MB,Oct-16,3,\n" +
        "Nov-6,INT,Nov-6,INT,Dec-1,4,\n" +
        "Jun-20,Exam,Jun-20,Exam,Feb-8,5,\n" +
        ",,,,Jun-11,6,\n" +
        ",,,,Jun-20,Exam,\n" +
        ",,,,Jun-24,Closing,\n";

    private static Timetable Parse(string block = "F", int year = 2026) =>
        Timetable.Parse(Sheet, block, year);

    [Fact]
    public void ABlocksPairedColumnsAreRead()
    {
        var timetable = Parse();
        Assert.Equal("F", timetable.Block);
        Assert.Equal(6, timetable.Meetings.Count);
        Assert.Equal(1, timetable.Meetings[0].Number);
        Assert.Equal(new DateOnly(2026, 10, 13), timetable.Meetings[0].Date);
    }

    [Fact]
    public void TheYearRollsForwardWhenTheMonthGoesBackwards()
    {
        // The sheet carries "Oct-13" and "Feb-8" with no year at all, and the
        // second one belongs to the following calendar year.
        var timetable = Parse();
        Assert.Equal(new DateOnly(2026, 12, 1), timetable.Meetings[3].Date);
        Assert.Equal(new DateOnly(2027, 2, 8), timetable.Meetings[4].Date);
        Assert.Equal(new DateOnly(2027, 6, 11), timetable.Meetings[5].Date);
    }

    [Fact]
    public void DaysNobodyTeachesOnAreKeptButNotCountedAsClasses()
    {
        // Kept rather than dropped: a teacher planning a year wants to see
        // where the exam sits, even though no unit content goes on it.
        var timetable = Parse();
        Assert.DoesNotContain(timetable.Meetings, m => m.Date == new DateOnly(2027, 6, 20));
        Assert.Contains(timetable.NonTeachingDays, d => d.Label == "Exam");
        Assert.Contains(timetable.NonTeachingDays, d => d.Label == "Closing");
    }

    [Fact]
    public void ModBreaksAndIntersessionsAreNotClasses()
    {
        var timetable = Parse("A");
        Assert.Equal(2, timetable.Meetings.Count);
        Assert.Equal(new[] { "MB", "INT", "Exam" },
            timetable.NonTeachingDays.Select(d => d.Label));
    }

    [Fact]
    public void AnUnknownBlockIsRefusedAndTheRealOnesAreNamed()
    {
        var refusal = Assert.Throws<AssistRefusal>(() => Parse("Z"));
        Assert.Equal("That timetable has no block “Z”. It has A, B, F.", refusal.Message);
    }

    [Fact]
    public void SomethingThatIsNotATimetableIsRefusedPlainly()
    {
        var refusal = Assert.Throws<AssistRefusal>(() => Timetable.Parse("name,email\nRuss,r@x.ca\n", "F", 2026));
        Assert.Contains("doesn’t look like a timetable", refusal.Message);
    }

    [Fact]
    public void QuotedCellsWithCommasAndNewlinesDoNotShiftTheColumns()
    {
        // Row 3 of the real sheet is a multi-line quoted instruction block.
        Assert.Equal(6, Parse().Meetings.Count);
    }

    // ---- The academic year -----------------------------------------------

    [Theory]
    [InlineData(2026, 8, 13, 2026)]   // August: the new year has begun
    [InlineData(2026, 10, 1, 2026)]
    [InlineData(2027, 3, 15, 2026)]   // March: still the year that started in 2026
    [InlineData(2027, 7, 31, 2026)]
    [InlineData(2027, 8, 1, 2027)]
    public void TheAcademicYearIsNamedForTheCalendarYearItStartsIn(int y, int m, int d, int expected) =>
        Assert.Equal(expected, Timetable.AcademicYearStarting(new DateOnly(y, m, d)));

    // ---- Spreading -------------------------------------------------------

    [Fact]
    public void AnEvenSpreadAnchorsTheFirstAndLastClassToTheYear()
    {
        var spread = Parse().EvenSpread(3);
        Assert.Equal(1, spread[0].Number);
        Assert.Equal(6, spread[^1].Number);
    }

    [Fact]
    public void AskingForMoreClassesThanMeetingsGivesEveryMeetingOnce()
    {
        var spread = Parse().EvenSpread(99);
        Assert.Equal(6, spread.Count);
    }
}

/// <summary>Rolling a course's classes onto a timetable.</summary>
public class ReDateTests : IDisposable
{
    private readonly string _folder = Directory.CreateTempSubdirectory("plantoir-redate").FullName;

    private const string Sheet =
        "A,,F,,\n" +
        "Sep-8,1,Oct-13,1,\n" +
        "Sep-9,2,Oct-20,2,\n" +
        "Sep-10,3,Oct-27,3,\n" +
        "Sep-11,4,Nov-3,4,\n";

    public ReDateTests()
    {
        File.WriteAllText(Path.Combine(_folder, "preview.ps1"), "# marker");
        string directory = Path.Combine(_folder, "courses", "ICS3U");
        Directory.CreateDirectory(directory);
        File.WriteAllText(Path.Combine(directory, "course_config.json"),
            """
            {
              "course_code": "ICS3U",
              "course_name": "Computer Science",
              "num_sections": 1,
              "per_section_folders": ["All Classes"],
              "section_numbers": [1]
            }
            """);
    }

    public void Dispose()
    {
        try { Directory.Delete(_folder, recursive: true); } catch { }
        GC.SuppressFinalize(this);
    }

    private AssistWorkspace Open() => new(_folder, new FakeLauncher());
    private static Timetable Block() => Timetable.Parse(Sheet, "F", 2026);

    private void Class(string title, string date, string body = "Body.") =>
        Write($"section1/All Classes/{title}.md", $"draft: false\ncreated: {date}T07:00:00.000-0400", body);

    private void Material(string path, string date, string body = "Body.") =>
        Write(path, $"draftSection1: false\ncreatedSection1: {date}T08:00:00.000-0500", body);

    private void Write(string relative, string frontmatter, string body)
    {
        string full = Path.Combine(_folder, "courses", "ICS3U",
            relative.Replace('/', Path.DirectorySeparatorChar));
        Directory.CreateDirectory(Path.GetDirectoryName(full)!);
        File.WriteAllText(full, $"---\n{frontmatter}\n---\n{body}\n");
    }

    private string Read(string relative) =>
        File.ReadAllText(Path.Combine(_folder, "courses", "ICS3U",
            relative.Replace('/', Path.DirectorySeparatorChar)));

    [Fact]
    public void AnEvenSpreadGivesEveryClassAMeeting()
    {
        Class("Unit 1, Day 1", "2026-09-08");
        Class("Unit 1, Day 2", "2026-09-09");

        var plan = Open().PlanReDate("ICS3U", 1, Block(), Array.Empty<string>(), Array.Empty<int>());

        Assert.Equal(new DateOnly(2026, 10, 13), plan.Dates[0].New);
        Assert.Equal(new DateOnly(2026, 11, 3), plan.Dates[1].New);   // anchored to the last meeting
    }

    [Fact]
    public void AnExplicitAssignmentBeatsTheSpread()
    {
        // Which lesson lands on which day is a judgement about content, so the
        // caller has to be able to overrule the arithmetic.
        Class("Unit 1, Day 1", "2026-09-08");
        Class("Unit 1, Day 2", "2026-09-09");

        var plan = Open().PlanReDate("ICS3U", 1, Block(),
            new[] { "Unit 1, Day 1", "Unit 1, Day 2" }, new[] { 1, 2 });

        Assert.Equal(new DateOnly(2026, 10, 13), plan.Dates[0].New);
        Assert.Equal(new DateOnly(2026, 10, 20), plan.Dates[1].New);
    }

    [Fact]
    public void MismatchedAssignmentListsAreRefused()
    {
        Class("Unit 1, Day 1", "2026-09-08");
        var refusal = Assert.Throws<AssistRefusal>(() => Open().PlanReDate("ICS3U", 1, Block(),
            new[] { "Unit 1, Day 1" }, new[] { 1, 2 }));
        Assert.Contains("they have to line up one for one", refusal.Message);
    }

    [Fact]
    public void AMeetingNumberThatDoesNotExistIsRefused()
    {
        Class("Unit 1, Day 1", "2026-09-08");
        var refusal = Assert.Throws<AssistRefusal>(() => Open().PlanReDate("ICS3U", 1, Block(),
            new[] { "Unit 1, Day 1" }, new[] { 99 }));
        Assert.Equal("Block F has no meeting 99. It runs 1 to 4.", refusal.Message);
    }

    [Fact]
    public void MaterialsMoveByTheSameAmountAndKeepTheirSpacing()
    {
        // Moving classes and leaving materials behind breaks the relationship
        // the build depends on. A delta preserves a gap the teacher set on
        // purpose; assigning the class's date would flatten it.
        Class("Unit 1, Day 1", "2026-09-08", "Concept: [[Variables]]");
        Material("Concepts/Variables.md", "2026-09-05");          // three days ahead of the lesson

        var plan = Open().PlanReDate("ICS3U", 1, Block(), new[] { "Unit 1, Day 1" }, new[] { 1 });

        var moved = Assert.Single(plan.Materials);
        Assert.Equal("Variables", moved.Title);
        Assert.Equal(new DateOnly(2026, 10, 10), moved.New);       // still three days ahead
        Assert.Equal("createdSection1", moved.FrontmatterKey);
    }

    [Fact]
    public void AMaterialNoClassLinksToIsLeftAloneAndReported()
    {
        Class("Unit 1, Day 1", "2026-09-08");
        Material("Concepts/Astronomy.md", "2026-09-05");

        var plan = Open().PlanReDate("ICS3U", 1, Block(), new[] { "Unit 1, Day 1" }, new[] { 1 });

        Assert.Empty(plan.Materials);
        Assert.Contains(plan.Problems, p => p.Contains("No class links to") && p.Contains("Astronomy"));
    }

    [Fact]
    public void ApplyingKeepsTheTimeOfDayAndOffsetThePageAlreadyHad()
    {
        // A re-date is about which DAY a lesson falls on. Rewriting 07:00 to
        // midnight would change how same-day pages sort.
        Class("Unit 1, Day 1", "2026-09-08", "Concept: [[Variables]]");
        Material("Concepts/Variables.md", "2026-09-08");
        var workspace = Open();

        var result = workspace.ApplyReDate(
            workspace.PlanReDate("ICS3U", 1, Block(), new[] { "Unit 1, Day 1" }, new[] { 1 }));

        Assert.True(result.Succeeded);
        Assert.NotNull(result.BackupPath);
        Assert.Contains("created: 2026-10-13T07:00:00.000-0400", Read("section1/All Classes/Unit 1, Day 1.md"));
        Assert.Contains("createdSection1: 2026-10-13T08:00:00.000-0500", Read("Concepts/Variables.md"));
    }

    [Fact]
    public void TheResultCountsClassesAndTheirMaterialsSeparately()
    {
        // "Moved 91 classes" when 26 classes and 65 materials moved is a
        // sentence a teacher would rightly query.
        Class("Unit 1, Day 1", "2026-09-08", "Concept: [[Variables]]");
        Material("Concepts/Variables.md", "2026-09-08");
        var workspace = Open();

        var result = workspace.ApplyReDate(
            workspace.PlanReDate("ICS3U", 1, Block(), new[] { "Unit 1, Day 1" }, new[] { 1 }));

        Assert.StartsWith("Moved 1 class and 1 linked page onto block F", result.Message);
    }

    [Fact]
    public void ApplyingLeavesEveryOtherFrontmatterLineAlone()
    {
        Class("Unit 1, Day 1", "2026-09-08");
        var workspace = Open();
        workspace.ApplyReDate(workspace.PlanReDate("ICS3U", 1, Block(), new[] { "Unit 1, Day 1" }, new[] { 1 }));
        Assert.Contains("draft: false", Read("section1/All Classes/Unit 1, Day 1.md"));
    }

    [Fact]
    public void ClassesFiledOutOfOrderAreReported()
    {
        Class("Unit 1, Day 1", "2026-09-08");
        Class("Unit 1, Day 2", "2026-09-09");

        // Deliberately backwards: Day 2 onto the earlier meeting.
        var plan = Open().PlanReDate("ICS3U", 1, Block(),
            new[] { "Unit 1, Day 1", "Unit 1, Day 2" }, new[] { 2, 1 });

        Assert.Contains(plan.Problems, p => p.Contains("dated BEFORE") && p.Contains("out of order"));
    }

    [Fact]
    public void TwoClassesOnOneDayAreReported()
    {
        Class("Unit 1, Day 1", "2026-09-08");
        Class("Unit 1, Day 2", "2026-09-09");

        var plan = Open().PlanReDate("ICS3U", 1, Block(),
            new[] { "Unit 1, Day 1", "Unit 1, Day 2" }, new[] { 1, 1 });

        Assert.Contains(plan.Problems, p => p.Contains("classes share 2026-10-13"));
    }

    [Fact]
    public void AMaterialStrandedFarFromEveryClassUsingItIsReported()
    {
        // The copy-paste case the teacher described: a page duplicated for a
        // new lesson whose date was never changed.
        Class("Unit 1, Day 1", "2026-09-08", "Concept: [[Variables]]");
        Material("Concepts/Variables.md", "2026-02-01");

        var plan = Open().PlanReDate("ICS3U", 1, Block(), new[] { "Unit 1, Day 1" }, new[] { 1 });

        Assert.Contains(plan.Problems, p =>
            p.Contains("Variables") && p.Contains("no class that links to it falls near that date"));
    }

    // ---- Bringing materials into date ------------------------------------

    [Fact]
    public void SyncingBringsALessonsMaterialsToItsOwnDate()
    {
        // The fix that belongs next to the audit: told "Unit 1, Day 1 is dated
        // October but links to a page dated February", the teacher can say
        // "yes, fix that" without opening the files.
        Class("Unit 1, Day 1", "2026-10-13", "Concept: [[Variables]]");
        Material("Concepts/Variables.md", "2026-02-01");

        var plan = Open().PlanSyncDates("ICS3U", 1, new[] { "Unit 1, Day 1" });

        var moved = Assert.Single(plan.Changing);
        Assert.Equal("Variables", moved.Title);
        Assert.Equal(new DateOnly(2026, 10, 13), moved.New);
    }

    [Fact]
    public void SyncingUsesTheEarliestClassThatLinksToAPage()
    {
        // The build's own rule: a shared page belongs to the lesson that
        // introduced it, not the one that revisited it.
        Class("Unit 1, Day 1", "2026-10-13", "Concept: [[Variables]]");
        Class("Unit 1, Day 4", "2026-11-03", "Revisit: [[Variables]]");
        Material("Concepts/Variables.md", "2026-02-01");

        var plan = Open().PlanSyncDates("ICS3U", 1, Array.Empty<string>());

        Assert.Equal(new DateOnly(2026, 10, 13), Assert.Single(plan.Changing).New);
    }

    [Fact]
    public void SyncingScopedToOneClassUsesThatClassEvenIfAnEarlierOneLinksToo()
    {
        Class("Unit 1, Day 1", "2026-10-13", "Concept: [[Variables]]");
        Class("Unit 1, Day 4", "2026-11-03", "Revisit: [[Variables]]");
        Material("Concepts/Variables.md", "2026-02-01");

        var plan = Open().PlanSyncDates("ICS3U", 1, new[] { "Unit 1, Day 4" });

        Assert.Equal(new DateOnly(2026, 11, 3), Assert.Single(plan.Changing).New);
    }

    [Fact]
    public void SyncingWritesTheDateAndLeavesTheRestOfTheFileAlone()
    {
        Class("Unit 1, Day 1", "2026-10-13", "Concept: [[Variables]]");
        Material("Concepts/Variables.md", "2026-02-01");
        var workspace = Open();

        var result = workspace.ApplySyncDates(workspace.PlanSyncDates("ICS3U", 1, new[] { "Unit 1, Day 1" }));

        Assert.True(result.Succeeded);
        Assert.NotNull(result.BackupPath);
        string text = Read("Concepts/Variables.md");
        Assert.Contains("createdSection1: 2026-10-13T08:00:00.000-0500", text);
        Assert.Contains("draftSection1: false", text);
    }

    [Fact]
    public void AClassCannotBeAnchoredToAnotherPage()
    {
        Class("Unit 1, Day 1", "2026-10-13");
        Material("Concepts/Variables.md", "2026-02-01");
        var refusal = Assert.Throws<AssistRefusal>(
            () => Open().PlanSyncDates("ICS3U", 1, new[] { "Variables" }));
        Assert.Contains("isn’t a class page", refusal.Message);
    }

    [Fact]
    public void AConceptRevisitedLaterIsNotMistakenForAMistake()
    {
        // A page introduced in October and used again in November is dated for
        // the lesson that introduced it. That is correct, not a copy-paste.
        Class("Unit 1, Day 1", "2026-09-08", "Concept: [[Variables]]");
        Class("Unit 1, Day 4", "2026-09-11", "Revisit: [[Variables]]");
        Material("Concepts/Variables.md", "2026-09-08");

        var plan = Open().PlanReDate("ICS3U", 1, Block(),
            new[] { "Unit 1, Day 1", "Unit 1, Day 4" }, new[] { 1, 4 });

        Assert.DoesNotContain(plan.Problems, p => p.Contains("no class that links to it falls near"));
    }
}
