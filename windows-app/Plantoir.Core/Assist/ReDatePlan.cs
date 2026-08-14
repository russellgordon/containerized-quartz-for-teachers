namespace Plantoir.Core.Assist;

/// <summary>
/// Moving a section's classes onto a real timetable, worked out before
/// anything is written.
///
/// Example course content ships with invented dates — it has to, since nobody
/// can know when a given teacher's block meets. Rolling it onto a real
/// timetable is therefore the FIRST thing most teachers will want, and it
/// touches every class page at once, which is exactly the kind of change that
/// needs to be readable before it happens.
///
/// The tool does not decide which lesson lands on which day. It supplies the
/// meetings, applies the dates, and reports what looks wrong; the choice of
/// spread is a judgement about content — whether a lesson can be split, what
/// must follow an investigation, which day would be left holding nothing but a
/// warm-up — and the tool can see none of that.
/// </summary>
public sealed class ReDatePlan
{
    public required string CourseCode { get; init; }
    public required int SectionNumber { get; init; }
    public required string Block { get; init; }
    public required IReadOnlyList<PlannedDate> Dates { get; init; }

    /// <summary>
    /// Concepts, exercises and the rest, carried along by the same amount as
    /// the lesson that anchors them.
    ///
    /// Moving classes and leaving their materials behind is not a neutral
    /// choice — it silently breaks the relationship the build depends on, and
    /// makes every material look like an unfinished copy-paste. Measured on
    /// the sample course: re-dating 26 classes without their materials
    /// produced 140 warnings, all of them the re-date's own doing.
    ///
    /// The shift is a DELTA, not an assignment, so a teacher who deliberately
    /// dates a handout a week ahead of the lesson still has it a week ahead
    /// afterwards.
    /// </summary>
    public required IReadOnlyList<PlannedDate> Materials { get; init; }

    /// <summary>
    /// Year-round reference pages moved to the first day of class: everything
    /// Key Links points at, and every curriculum page. They belong to the
    /// start of the year rather than to any one lesson, and a rollover would
    /// otherwise leave them stranded on last year's dates.
    /// </summary>
    public IReadOnlyList<PlannedDate> Reference { get; init; } = Array.Empty<PlannedDate>();

    /// <summary>
    /// How many of the reference pages are curriculum, which the plan has to
    /// mention separately because the SITE will not show the date being set.
    ///
    /// build_site.py gives every curriculum page the section's newest class
    /// date when it builds, and that behaviour stays. The source date is still
    /// worth setting — the build only overwrites a date that is absent or
    /// OLDER than the newest class, so a page left on a later date from a
    /// previous year would otherwise survive and sort above everything — but
    /// saying "these move to the first day" without saying the site shows them
    /// differently would be the plan describing something a teacher cannot
    /// see.
    /// </summary>
    public int CurriculumCount { get; init; }

    /// <summary>Date problems this change would leave behind, in plain words.</summary>
    public required IReadOnlyList<string> Problems { get; init; }

    /// <summary>Days the timetable names that no unit content belongs on.</summary>
    public required IReadOnlyList<NonTeachingDay> NonTeachingDays { get; init; }

    /// <summary>Meetings the spread did not use.</summary>
    public required int UnusedMeetings { get; init; }

    public IEnumerable<PlannedDate> Changing =>
        Dates.Concat(Materials).Concat(Reference).Where(d => d.WillChange);

    public bool ChangesNothing => !Changing.Any();

    /// <summary>Problems and materials are both listed in full only up to this.</summary>
    private const int MostListed = 10;

    public string Describe()
    {
        var lines = new List<string>();
        var changing = Changing.ToList();

        lines.Add($"Re-date {Dates.Count} class{(Dates.Count == 1 ? "" : "es")} in {CourseCode} " +
                  $"Section {SectionNumber} onto block {Block}.");
        int movingClasses = Dates.Count(d => d.WillChange);
        lines.Add(movingClasses == 0
            ? "Every class already carries the date it would be given."
            : $"{movingClasses} of {Dates.Count} would move.");

        if (UnusedMeetings > 0)
            lines.Add($"{UnusedMeetings} of block {Block}’s meetings are left unused.");

        if (NonTeachingDays.Count > 0)
        {
            var labels = NonTeachingDays.GroupBy(d => d.Label)
                .Select(g => $"{g.Count()} {g.Key}").ToList();
            lines.Add($"No content was placed on non-teaching days ({string.Join(", ", labels)}).");
        }

        int movingMaterials = Materials.Count(m => m.WillChange);
        if (movingMaterials > 0)
            lines.Add($"{movingMaterials} concept, exercise and tutorial page{(movingMaterials == 1 ? "" : "s")} " +
                      "move by the same amount, keeping their spacing from the lessons that use them.");

        int movingReference = Reference.Count(r => r.WillChange);
        if (movingReference > 0)
        {
            lines.Add($"{movingReference} year-round page{(movingReference == 1 ? "" : "s")} — " +
                      "the section's front page, what Key Links points at, and the curriculum — " +
                      "move to the first day of class.");
            if (CurriculumCount > 0)
                lines.Add($"  (Of those, {CurriculumCount} are curriculum pages. Their dates change in your " +
                          "files, but the website always shows curriculum alongside the newest class, so you " +
                          "will not see a difference there.)");
        }

        if (changing.Count > 0)
        {
            lines.Add("");
            lines.Add("New class dates:");
            foreach (var date in Dates) lines.Add("  " + date.Describe());
        }

        if (Problems.Count > 0)
        {
            lines.Add("");
            lines.Add($"{Problems.Count} thing{(Problems.Count == 1 ? "" : "s")} worth looking at:");
            foreach (string problem in Problems.Take(MostListed)) lines.Add("  • " + problem);
            if (Problems.Count > MostListed)
                lines.Add($"  …and {Problems.Count - MostListed} more.");
        }
        return string.Join("\n", lines);
    }
}

/// <summary>One class page and the day it would move to.</summary>
public sealed record PlannedDate(
    string Title,
    string RelativePath,
    string FrontmatterKey,
    DateOnly? Current,
    DateOnly New,
    int MeetingNumber)
{
    public bool WillChange => Current != New;

    /// <summary>
    /// The meeting number is only meaningful for a date that came from a
    /// timetable. Pages taking a class's date have no meeting of their own,
    /// and printing "meeting 0" beside them is noise in a line a teacher is
    /// meant to read.
    /// </summary>
    private string Meeting => MeetingNumber > 0 ? $", meeting {MeetingNumber}" : "";

    public string Describe() =>
        WillChange
            ? $"{Title}  {Show(Current)} → {New:yyyy-MM-dd} ({New:ddd}){Meeting}"
            : $"{Title}  {New:yyyy-MM-dd} ({New:ddd}){Meeting} — unchanged";

    private static string Show(DateOnly? value) => value is { } date ? date.ToString("yyyy-MM-dd") : "no date";
}
