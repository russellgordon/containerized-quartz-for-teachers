using System.Text.RegularExpressions;

namespace Plantoir.Core.Models;

/// <summary>
/// Finding the <c>[[wikilinks]]</c> on a page and working out which files they
/// point at.
///
/// This exists because of what a class page IS in this toolchain: the agenda
/// lists the concepts, discussions and setup pages for that day, and those
/// links are the only thing that ties them together. "Publish tomorrow's class
/// and everything it links to" is therefore a link-resolution problem, and the
/// resolution has to be done in code — an assistant asked to work out which
/// files a page links to will happily invent one.
///
/// Ambiguity is reported, never resolved by picking. Two pages with the same
/// name in different folders is a situation only the teacher can settle, and
/// guessing would publish the wrong one.
/// </summary>
public static class WikiLinks
{
    /// <summary>
    /// <c>[[target]]</c>, <c>[[target|alias]]</c>, <c>[[target#heading]]</c>
    /// and the <c>![[embed]]</c> form. The target stops at the first
    /// <c>#</c> or <c>|</c>; anything else up to <c>]]</c> is the target.
    /// </summary>
    private static readonly Regex LinkPattern = new(
        @"(?<embed>!)?\[\[(?<target>[^\]\|#]+)(?:#(?<heading>[^\]\|]*))?(?:\|(?<alias>[^\]]*))?\]\]",
        RegexOptions.Compiled);

    /// <summary>
    /// Every wikilink on the page, in document order, with duplicates kept —
    /// the caller decides whether repetition matters.
    ///
    /// Fenced code blocks and inline code spans are skipped: a page that
    /// documents the link syntax should not cause the pages it mentions to be
    /// published.
    /// </summary>
    public static List<WikiLink> Parse(string markdown)
    {
        var links = new List<WikiLink>();
        foreach (string line in WithoutCode(markdown))
            foreach (Match match in LinkPattern.Matches(line))
            {
                string target = match.Groups["target"].Value.Trim();
                if (target.Length == 0) continue;
                links.Add(new WikiLink(
                    Target: target,
                    Heading: match.Groups["heading"].Success ? match.Groups["heading"].Value.Trim() : null,
                    Alias: match.Groups["alias"].Success ? match.Groups["alias"].Value.Trim() : null,
                    IsEmbed: match.Groups["embed"].Success));
            }
        return links;
    }

    /// <summary>
    /// The page's lines with fenced blocks dropped and inline code blanked.
    /// Blanking rather than removing keeps it simple: we only care about what
    /// links survive, not about the text.
    /// </summary>
    private static IEnumerable<string> WithoutCode(string markdown)
    {
        bool inFence = false;
        string fenceMarker = "";
        foreach (string raw in markdown.Split('\n'))
        {
            string line = raw.TrimEnd('\r');
            string trimmed = line.TrimStart();

            if (trimmed.StartsWith("```", StringComparison.Ordinal) ||
                trimmed.StartsWith("~~~", StringComparison.Ordinal))
            {
                string marker = trimmed[..3];
                if (!inFence) { inFence = true; fenceMarker = marker; }
                else if (marker == fenceMarker) { inFence = false; fenceMarker = ""; }
                continue;
            }
            if (inFence) continue;
            yield return StripInlineCode(line);
        }
    }

    private static string StripInlineCode(string line)
    {
        if (!line.Contains('`')) return line;
        var builder = new System.Text.StringBuilder(line.Length);
        bool inCode = false;
        foreach (char character in line)
        {
            if (character == '`') { inCode = !inCode; builder.Append(' '); continue; }
            builder.Append(inCode ? ' ' : character);
        }
        return builder.ToString();
    }

    /// <summary>
    /// Extensions that mean "this link points at an attachment, not a page".
    ///
    /// Matched against a fixed list rather than by taking whatever follows the
    /// last dot, because curriculum expectation pages are genuinely called
    /// things like <c>A1.1</c> and <c>E2.6</c> — asking for the "extension" of
    /// <c>[[E2.6]]</c> gives <c>.6</c>, and treating that as an attachment
    /// would silently drop a real page from every plan.
    /// </summary>
    private static readonly HashSet<string> AssetExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp", ".avif", ".bmp", ".ico",
        ".pdf", ".mp4", ".mov", ".webm", ".mp3", ".m4a", ".wav", ".ogg",
        ".zip", ".docx", ".pptx", ".xlsx", ".csv",
    };

    private static bool IsAsset(string target)
    {
        int dot = target.LastIndexOf('.');
        return dot >= 0 && AssetExtensions.Contains(target[dot..]);
    }

    /// <summary>
    /// Resolve a page's links against the files of one course section.
    ///
    /// A target containing a slash is tried as a path relative to the course
    /// folder first, which is the form build_site.py rewrites away
    /// (<c>[[section2/All Classes/Thread 2, Day 8|…]]</c>). Everything else is
    /// matched on file name, the way Obsidian and Quartz match it, and
    /// case-insensitively because that is how both behave on the platforms
    /// teachers use.
    /// </summary>
    /// <param name="pagePath">The page whose links these are; excluded from its own results.</param>
    public static List<LinkResolution> Resolve(
        IEnumerable<WikiLink> links, string courseDirectory, int sectionNumber, string? pagePath = null)
    {
        List<string> candidates = PagePaths.MarkdownPages(courseDirectory, sectionNumber);
        var byName = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        foreach (string candidate in candidates)
        {
            string name = Path.GetFileNameWithoutExtension(candidate);
            if (!byName.TryGetValue(name, out var list)) byName[name] = list = new List<string>();
            list.Add(candidate);
        }

        string? self = pagePath is null ? null : Path.GetFullPath(pagePath);
        var results = new List<LinkResolution>();
        var alreadySeen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (WikiLink link in links)
        {
            if (!alreadySeen.Add(link.Target)) continue;   // one resolution per distinct target

            // An embedded diagram is not a missing page. Reporting it as a
            // problem would put "“diagram.png” doesn't match any page" in
            // front of a teacher who did nothing wrong.
            if (IsAsset(link.Target))
            {
                results.Add(new LinkResolution(link, null, LinkOutcome.Attachment, Array.Empty<string>()));
                continue;
            }

            if (link.Target.Contains('/') || link.Target.Contains('\\'))
            {
                string? viaPath = ResolveAsPath(courseDirectory, link.Target);
                if (viaPath is not null)
                {
                    results.Add(Resolution(link, viaPath, self));
                    continue;
                }
            }

            // Take the last path component and strip a trailing ".md" — and
            // NOTHING else. GetFileNameWithoutExtension("E2.6") is "E2", which
            // would make every curriculum-expectation link resolve to nothing.
            string name = link.Target.Replace('\\', '/').Split('/')[^1];
            if (name.EndsWith(".md", StringComparison.OrdinalIgnoreCase)) name = name[..^3];
            if (!byName.TryGetValue(name, out var matches) || matches.Count == 0)
            {
                results.Add(new LinkResolution(link, null, LinkOutcome.NotFound, Array.Empty<string>()));
                continue;
            }
            if (matches.Count > 1)
            {
                results.Add(new LinkResolution(link, null, LinkOutcome.Ambiguous, matches.ToArray()));
                continue;
            }
            results.Add(Resolution(link, matches[0], self));
        }
        return results;
    }

    private static LinkResolution Resolution(WikiLink link, string path, string? self) =>
        self is not null && string.Equals(Path.GetFullPath(path), self, StringComparison.OrdinalIgnoreCase)
            ? new LinkResolution(link, path, LinkOutcome.SelfReference, Array.Empty<string>())
            : new LinkResolution(link, path, LinkOutcome.Resolved, Array.Empty<string>());

    private static string? ResolveAsPath(string courseDirectory, string target)
    {
        string relative = target.Replace('/', Path.DirectorySeparatorChar)
                                .Replace('\\', Path.DirectorySeparatorChar);
        if (!relative.EndsWith(".md", StringComparison.OrdinalIgnoreCase)) relative += ".md";
        string full;
        try { full = PagePaths.ResolveInside(courseDirectory, relative); }
        catch (OutsideWorkspaceException) { return null; }
        return File.Exists(full) ? full : null;
    }
}

/// <summary>One <c>[[wikilink]]</c> as written on the page.</summary>
public readonly record struct WikiLink(string Target, string? Heading, string? Alias, bool IsEmbed)
{
    /// <summary>What the reader sees — the alias when there is one.</summary>
    public string DisplayText => string.IsNullOrEmpty(Alias) ? Target : Alias!;
}

/// <summary>How a link resolution turned out.</summary>
public enum LinkOutcome
{
    /// <summary>Exactly one file matched.</summary>
    Resolved,
    /// <summary>No file of that name is in this section.</summary>
    NotFound,
    /// <summary>Several files share the name; only the teacher can say which.</summary>
    Ambiguous,
    /// <summary>The page links to itself; nothing to do.</summary>
    SelfReference,

    /// <summary>
    /// An image, PDF or other attachment rather than a page. It rides along
    /// with the page that embeds it and has no draft flag of its own.
    /// </summary>
    Attachment,
}

/// <summary>A link and the file it points at, or why it does not point anywhere.</summary>
public readonly record struct LinkResolution(
    WikiLink Link, string? Path, LinkOutcome Outcome, IReadOnlyList<string> Candidates)
{
    /// <summary>Plain words for a teacher, naming the problem rather than a code.</summary>
    public string? Problem => Outcome switch
    {
        LinkOutcome.NotFound => $"“{Link.Target}” doesn’t match any page in this section.",
        LinkOutcome.Ambiguous => $"“{Link.Target}” matches {Candidates.Count} pages, so it’s unclear which one is meant.",
        _ => null,
    };
}
