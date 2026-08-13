namespace Plantoir.Core.Assist;

/// <summary>
/// What a publish would do, worked out before anything is written.
///
/// This type is the whole safety argument of AI Assist in one object. The
/// investigation on the <c>ai-assist</c> branch found that a small model
/// inverts polarity often enough to matter — asked to HIDE tomorrow's class it
/// proposed publishing it, and the pages it links to, on some runs but not
/// others. Nothing testable defends against that. A teacher reading one
/// sentence does.
///
/// So no assistant, local or remote, is ever allowed to write directly. It
/// builds one of these, Plantoir renders it in plain words, and the teacher
/// says yes. Every field here exists to make that sentence honest —
/// including <see cref="Problems"/>, which names the links that could not be
/// resolved rather than quietly leaving them out.
/// </summary>
public sealed class PublishPlan
{
    public required string CourseCode { get; init; }
    public required int SectionNumber { get; init; }

    /// <summary>The class page this is all about.</summary>
    public required PlannedPage Page { get; init; }

    /// <summary>Pages reached from the class page's wikilinks, in page order.</summary>
    public required IReadOnlyList<PlannedPage> Linked { get; init; }

    /// <summary>Links that named nothing, or named too many things.</summary>
    public required IReadOnlyList<string> Problems { get; init; }

    /// <summary>Whether the site is republished after the flags change.</summary>
    public required bool Publishes { get; init; }

    /// <summary>Where a publish would land — "Netlify", "Cloudflare Pages", or a folder.</summary>
    public required string Destination { get; init; }

    /// <summary>Pages whose flag actually changes; the rest are already in the wanted state.</summary>
    public IEnumerable<PlannedPage> Changing =>
        Linked.Prepend(Page).Where(p => p.WillChange);

    public bool ChangesNothing => !Changing.Any();

    /// <summary>
    /// The proposal as a teacher would read it. Deliberately one short
    /// paragraph: a wall of paths is not something anyone checks carefully,
    /// and this sentence is the last line of defence before a write.
    /// </summary>
    public string Describe()
    {
        string verb = Page.Draft ? "Hide" : "Publish";
        var lines = new List<string>();

        int changingLinked = Linked.Count(p => p.WillChange);
        string headline = $"{verb} “{Page.Title}” in {CourseCode} Section {SectionNumber}";
        if (changingLinked > 0)
            headline += $", and {(Page.Draft ? "hide" : "publish")} the "
                      + $"{changingLinked} page{(changingLinked == 1 ? "" : "s")} it links to";
        lines.Add(headline + ".");

        if (!Page.WillChange && changingLinked == 0)
        {
            // Say how many links were actually followed. "Everything it links
            // to" with no number reads the same whether resolution worked or
            // silently found nothing, and those are very different answers.
            string state = Page.Draft ? "hidden" : "published";
            string linked = Linked.Count switch
            {
                0 => "",
                1 => ", and so is the 1 page it links to",
                _ => $", and so are the {Linked.Count} pages it links to",
            };
            lines.Add($"Nothing would change — “{Page.Title}” is already {state}{linked}.");
        }

        foreach (string problem in Problems) lines.Add("• " + problem);

        if (Publishes) lines.Add($"Then republish Section {SectionNumber} to {Destination}.");
        return string.Join("\n", lines);
    }
}

/// <summary>One page a plan would touch, and what would happen to it.</summary>
public sealed record PlannedPage(
    string Title,
    string RelativePath,
    string FrontmatterKey,
    bool? CurrentValue,
    bool Draft)
{
    /// <summary>False when the page already carries the wanted value.</summary>
    public bool WillChange => CurrentValue != Draft;
}
