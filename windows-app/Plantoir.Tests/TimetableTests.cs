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
        // Not "block Z" — the label might be a period, a colour or a room.
        Assert.Equal("That timetable has no “Z”. It has A, B, F.", refusal.Message);
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

    // ---- Other schools, other sheets --------------------------------------

    /// <summary>Every date style, written as the same three days.</summary>
    [Theory]
    [InlineData("Oct-13,Oct-14,Oct-16", "month name and day")]
    [InlineData("13-Oct,14-Oct,16-Oct", "day and month name")]
    [InlineData("October 13,October 14,October 16", "month name and day")]
    [InlineData("2026-10-13,2026-10-14,2026-10-16", "year-month-day")]
    [InlineData("10/13/2026,10/14/2026,10/16/2026", "month/day/year")]
    [InlineData("13/10/2026,14/10/2026,16/10/2026", "day/month/year")]
    [InlineData("Oct 13, 2026|Oct 14, 2026|Oct 16, 2026", "month name, day, year")]
    [InlineData("13 October 2026|14 October 2026|16 October 2026", "day, month name, year")]
    public void AnySensibleDateFormatIsRead(string dates, string expectedStyle)
    {
        var days = dates.Split(dates.Contains('|') ? '|' : ',');
        string sheet = "P,\n" + string.Join("", days.Select((d, i) => $"\"{d}\",{i + 1}\n"));

        var timetable = Timetable.Parse(sheet, "P", 2026);

        Assert.Equal(expectedStyle, timetable.DateFormat);
        Assert.Equal(new DateOnly(2026, 10, 13), timetable.Meetings[0].Date);
        Assert.Equal(new DateOnly(2026, 10, 16), timetable.Meetings[2].Date);
    }

    [Fact]
    public void AnAmbiguousNumericDateIsSettledByTheWholeColumn()
    {
        // "05/06" alone could be either. Read as month/day the column runs
        // May → June → July; read as day/month it would run May → back to
        // February, which needs a year rollover. Fewest rollovers wins.
        var timetable = Timetable.Parse("P,\n05/06,1\n06/10,2\n07/02,3\n", "P", 2026);

        Assert.Equal("month/day", timetable.DateFormat);
        Assert.Equal(new DateOnly(2026, 5, 6), timetable.Meetings[0].Date);
    }

    [Fact]
    public void ADayFirstColumnIsRecognisedFromAValueOverTwelve()
    {
        var timetable = Timetable.Parse("P,\n13/05,1\n20/05,2\n", "P", 2026);
        Assert.Equal("day/month", timetable.DateFormat);
        Assert.Equal(new DateOnly(2026, 5, 13), timetable.Meetings[0].Date);
    }

    [Theory]
    [InlineData("Block F")]
    [InlineData("Period 3")]
    [InlineData("1A")]
    [InlineData("Green")]
    public void LabelsDoNotHaveToBeSingleLetters(string label)
    {
        string sheet = $"\"{label}\",\nOct-13,1\nOct-14,2\n";
        Assert.Equal(2, Timetable.Parse(sheet, label, 2026).Meetings.Count);
    }

    [Fact]
    public void ALabelMatchesWithOrWithoutTheWordBlock()
    {
        // A teacher says "F"; the sheet says "Block F". Same room.
        string sheet = "Block F,\nOct-13,1\nOct-14,2\n";
        Assert.Equal(2, Timetable.Parse(sheet, "F", 2026).Meetings.Count);
        Assert.Equal(2, Timetable.Parse(sheet, "block f", 2026).Meetings.Count);
    }

    [Fact]
    public void ASheetWithNoNumbersColumnStillWorks()
    {
        // Just dates under each label. Every dated row is a meeting, numbered
        // in the order it appears.
        var timetable = Timetable.Parse("A,B\nOct-13,Oct-14\nOct-20,Oct-21\n", "B", 2026);

        Assert.Equal(2, timetable.Meetings.Count);
        Assert.Equal(1, timetable.Meetings[0].Number);
        Assert.Equal(new DateOnly(2026, 10, 14), timetable.Meetings[0].Date);
        Assert.Empty(timetable.NonTeachingDays);
    }

    [Fact]
    public void TheHeaderIsFoundBelowWhateverPreambleTheSheetCarries()
    {
        string sheet =
            ",,\n" +
            "St Somewhere Secondary — 2026/27 timetable,,\n" +
            "\"Notes:\n- copy the column you need\",,\n" +
            ",,\n" +
            "Block A,,Block F\n" +
            "Sep-8,1,Oct-13\n" +
            "Sep-9,2,Oct-14\n";
        var timetable = Timetable.Parse(sheet, "F", 2026);
        Assert.Equal(2, timetable.Meetings.Count);
    }

    [Fact]
    public void AColumnWrittenInsideOutIsRefusedRatherThanHalfRead()
    {
        // Mixed formats cannot be read reliably, and quietly dropping the rows
        // that do not fit would produce a plausible, wrong timetable.
        var refusal = Assert.Throws<AssistRefusal>(
            () => Timetable.Parse("P,\nOct-13,1\n2026-10-14,2\n", "P", 2026));
        Assert.Contains("aren’t all written the same way", refusal.Message);
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
