namespace Plantoir.Core.Assist;

/// <summary>
/// A deploy the teacher wants to happen while they are asleep.
///
/// "Deploy tomorrow's class at 6:30 AM" — so the class is live before the
/// students are, without the teacher being at their desk at half six.
///
/// The honest part of this is what it does NOT promise. It asks Windows to
/// run a task at a time; it cannot make a computer that is switched off run
/// anything, and it deliberately does not set a wake timer. A wake timer
/// depends on the hardware, the power plan, and on the machine being asleep
/// rather than shut down or hibernating, and it fails SILENTLY when any of
/// those is not true — which for a teacher means walking into class to find
/// yesterday's site still up. A plain warning they can act on beats a promise
/// that might not be kept.
/// </summary>
public sealed class ScheduledDeploy
{
    public required string CourseCode { get; init; }
    public required int SectionNumber { get; init; }
    public required DateTime When { get; init; }

    /// <summary>The name the task carries, so it can be found and cancelled.</summary>
    public string TaskName => $"Plantoir deploy {CourseCode} section {SectionNumber}";

    /// <summary>Classes that are not published yet, and so would not reach students.</summary>
    public required IReadOnlyList<string> UnpublishedClasses { get; init; }

    /// <summary>Where the deploy would land.</summary>
    public required string Destination { get; init; }

    /// <summary>
    /// What the teacher is agreeing to — including everything that has to be
    /// true of the computer, said plainly and up front.
    /// </summary>
    public string Describe()
    {
        var lines = new List<string>
        {
            $"Deploy {CourseCode} Section {SectionNumber} to {Destination} at " +
            $"{When:dddd d MMMM, h:mm tt}.",
            "",
            "For this to happen, at that moment this computer must be:",
            "  • switched on, and awake — not asleep, shut down, or hibernating",
            "  • plugged in, if it is a laptop",
            "  • with the lid open, if closing it puts it to sleep",
            "",
            "Plantoir does not wake the computer up. If it is asleep at that time, " +
            "nothing happens and the site stays as it is.",
        };

        if (UnpublishedClasses.Count > 0)
        {
            lines.Add("");
            // The failure this exists to prevent: a deploy that runs perfectly
            // and ships a class students still cannot see.
            lines.Add($"One thing first — {UnpublishedClasses.Count} " +
                      $"class{(UnpublishedClasses.Count == 1 ? " is" : "es are")} not published yet:");
            foreach (string page in UnpublishedClasses.Take(8)) lines.Add($"  {page}");
            if (UnpublishedClasses.Count > 8)
                lines.Add($"  …and {UnpublishedClasses.Count - 8} more.");
            lines.Add("Deploying now would put the site up without " +
                      $"{(UnpublishedClasses.Count == 1 ? "it" : "them")}. " +
                      "Publish first, look the preview over, then schedule this.");
        }

        return string.Join("\n", lines);
    }
}
