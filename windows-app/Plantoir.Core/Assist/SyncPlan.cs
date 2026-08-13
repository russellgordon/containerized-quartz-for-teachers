namespace Plantoir.Core.Assist;

/// <summary>
/// Bringing a lesson's materials into date with the lesson itself.
///
/// The remedy that belongs next to the date audit. Finding out that "Unit 4,
/// Day 5 is dated June 11th but links to Ohm's Law, dated November 20th" is
/// only half an answer; the other half is being able to say "yes, fix that"
/// without opening twelve files.
///
/// This is deliberately a SEPARATE operation from re-dating a course, and not
/// something the re-date does on its own. A re-date shifts materials by a
/// delta, which preserves any spacing the teacher meant. This flattens that
/// spacing on purpose, so it only ever runs when someone asks for it.
/// </summary>
public sealed class SyncPlan
{
    public required string CourseCode { get; init; }
    public required int SectionNumber { get; init; }

    /// <summary>The classes whose materials are being brought into line.</summary>
    public required IReadOnlyList<string> Anchors { get; init; }

    public required IReadOnlyList<PlannedDate> Dates { get; init; }

    /// <summary>Materials that could not be dated, and why.</summary>
    public required IReadOnlyList<string> Problems { get; init; }

    public IEnumerable<PlannedDate> Changing => Dates.Where(d => d.WillChange);

    public bool ChangesNothing => !Changing.Any();

    private const int MostListed = 25;

    public string Describe()
    {
        var lines = new List<string>();
        var changing = Changing.ToList();

        string subject = Anchors.Count == 1
            ? $"the pages “{Anchors[0]}” links to"
            : $"the pages {Anchors.Count} classes link to";
        lines.Add($"Bring {subject} into date with the class that uses them, " +
                  $"in {CourseCode} Section {SectionNumber}.");

        lines.Add(changing.Count == 0
            ? $"Nothing would change — all {Dates.Count} already match."
            : $"{changing.Count} of {Dates.Count} would move.");

        if (changing.Count > 0)
        {
            lines.Add("");
            lines.Add("Would change:");
            foreach (var date in changing.Take(MostListed)) lines.Add("  " + date.Describe());
            if (changing.Count > MostListed)
                lines.Add($"  …and {changing.Count - MostListed} more.");
        }

        foreach (string problem in Problems) lines.Add("• " + problem);

        lines.Add("");
        lines.Add("This changes dates only. Nothing is published, and no page's visibility changes.");
        return string.Join("\n", lines);
    }
}
