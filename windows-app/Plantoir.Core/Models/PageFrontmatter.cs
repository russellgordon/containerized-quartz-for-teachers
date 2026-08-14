using System.Text;

namespace Plantoir.Core.Models;

/// <summary>
/// Reading and editing the <c>publish:</c> flag in a page's YAML frontmatter,
/// without reserializing the YAML.
///
/// The teacher's frontmatter is theirs. Round-tripping it through a YAML
/// library would reorder keys, requote strings, reflow the tag list and strip
/// their comments — a diff full of changes nobody asked for, in files Obsidian
/// has open. So every edit here is a line-level edit: find the line, change
/// the value after the colon, leave every other byte alone.
///
/// The subtle part is WHICH key to write, and that is decided by where the
/// page lives rather than by anything the caller says:
///
/// * A page inside <c>section&lt;N&gt;/</c> belongs to exactly one section, so
///   it carries a plain <c>publish:</c>.
/// * A page at course level is copied into EVERY section at build time, so it
///   carries <c>publishForSection&lt;N&gt;:</c> — one flag per section, which
///   is what lets "Ohm's Law" be published in section 1 and still hidden in
///   section 2.
///
/// This mirrors <c>process_frontmatter</c> in build_site.py, which copies
/// <c>publishForSection&lt;N&gt;</c> over <c>publish</c> for the section being
/// built and then strips every per-section key from the built copy. The source
/// files keep them all; only the build output is flattened.
///
/// Both keys have a legacy spelling — <c>draft:</c> and
/// <c>draftSection&lt;N&gt;:</c> — with the opposite polarity. Those are still
/// READ, so a course nobody has touched behaves exactly as it did, but they
/// are never written: the first edit to a page migrates it.
/// </summary>
public static class PageFrontmatter
{
    /// <summary>
    /// The frontmatter key that decides whether students see this page.
    ///
    /// <c>publish: true</c> means visible; <c>publish: false</c> means not.
    /// A teacher says a page is or is not published — never that it is or is
    /// not a draft, which reads as "unfinished" and is a different thing.
    /// </summary>
    /// <param name="isSectionLocal">
    /// True when the page lives under <c>section&lt;N&gt;/</c>. Callers get
    /// this from <see cref="PagePaths"/> rather than deciding it themselves.
    /// </param>
    public static string PublishKeyFor(int sectionNumber, bool isSectionLocal) =>
        isSectionLocal ? "publish" : "publishForSection" + sectionNumber;

    /// <summary>
    /// What the same page used to use. Courses written before the change still
    /// carry these, and are read — inverted — until something touches the page
    /// and writes the new key.
    /// </summary>
    public static string LegacyDraftKeyFor(int sectionNumber, bool isSectionLocal) =>
        isSectionLocal ? "draft" : "draftSection" + sectionNumber;

    /// <summary>
    /// Whether this page is hidden in the given section, resolved the way the
    /// build resolves it: the per-section key wins, a plain <c>publish:</c> is
    /// the fallback, the legacy draft keys are read after that, and a page with
    /// none of them is published — the kinder default, since a forgotten flag
    /// leaves a page visible rather than silently removing it.
    /// </summary>
    public static bool IsDraft(string pageText, int sectionNumber)
    {
        var block = Block.Parse(pageText);
        if (block is null) return false;

        // The new keys win outright. A page carrying both has already been
        // migrated, and the leftover draft key must not contradict it.
        if (block.BoolValue("publishForSection" + sectionNumber) is { } perSection) return !perSection;
        if (block.BoolValue("publish") is { } plain) return !plain;

        // Not yet migrated: read the old keys, inverted.
        return block.BoolValue("draftSection" + sectionNumber)
            ?? block.BoolValue("draft")
            ?? false;   // no flag at all means visible, then as now
    }

    /// <summary>
    /// The value literally stored under one key, or null when the key is
    /// absent. The caller needs the difference between "set to false" and
    /// "not set at all" to describe an edit honestly.
    /// </summary>
    public static bool? StoredValue(string pageText, string key) =>
        Block.Parse(pageText)?.BoolValue(key);

    /// <summary>One key's value exactly as written, or null when absent.</summary>
    public static string? StoredText(string pageText, string key) =>
        Block.Parse(pageText)?.RawValue(key);

    /// <summary>
    /// Whether this page is currently hidden, in DRAFT terms, or null when it
    /// says nothing either way.
    ///
    /// Callers reason in "is it hidden" because that is the question a plan
    /// answers, while the file now stores the opposite. Reading the raw
    /// <c>publish</c> value into a field that means "draft" inverts every
    /// comparison that depends on it — which is exactly what happened, and
    /// what made a plan think an already-published page still needed
    /// publishing.
    /// </summary>
    public static bool? StoredDraft(string pageText, string publishKey)
    {
        var block = Block.Parse(pageText);
        if (block is null) return null;
        if (block.BoolValue(publishKey) is { } published) return !published;
        if (block.BoolValue(LegacyKeyOf(publishKey)) is { } draft) return draft;
        return null;
    }

    /// <summary>
    /// The key carrying this page's date, following the same rule as the draft
    /// key: one section's page has a plain <c>created:</c>, a page shared
    /// across sections has one <c>createdSection&lt;N&gt;:</c> per section.
    /// </summary>
    public static string CreatedKeyFor(int sectionNumber, bool isSectionLocal) =>
        isSectionLocal ? "created" : "createdSection" + sectionNumber;

    /// <summary>
    /// The calendar date this page is scheduled for in this section, or null
    /// when it has none.
    ///
    /// The stored value carries a time and a UTC offset
    /// (<c>2026-09-08T07:00:00.000-0400</c>), but a teacher asking for
    /// "classes from September 15th" means the calendar date as written, so
    /// the date is taken in the page's OWN offset. Converting to local time
    /// first would move an early-morning class onto the previous day for
    /// anyone east of the school.
    /// </summary>
    public static DateOnly? CreatedOn(string pageText, int sectionNumber, bool isSectionLocal)
    {
        var block = Block.Parse(pageText);
        if (block is null) return null;
        return block.DateValue(CreatedKeyFor(sectionNumber, isSectionLocal))
            ?? block.DateValue("created");   // fall back to a plain date if the page carries one
    }

    /// <summary>
    /// The page text with its date moved to <paramref name="date"/>, keeping
    /// the time of day and UTC offset the page already carried.
    ///
    /// Only the calendar part is rewritten. A course's class times are the
    /// teacher's, and a re-date is about which DAY a lesson falls on — moving
    /// 07:00 to midnight because the code found it easier would change how the
    /// site sorts pages that share a day.
    /// </summary>
    /// <param name="fallbackTail">
    /// The time-and-offset to use when the page has no date yet — taken from a
    /// sibling class page, so a course keeps one convention.
    /// </param>
    public static (string Text, bool Changed) SetCreated(
        string pageText, string key, DateOnly date, string fallbackTail = "T07:00:00.000-0400")
    {
        var block = Block.Parse(pageText);
        string stamp = date.ToString("yyyy-MM-dd");
        string existing = block?.RawValue(key) ?? "";
        string tail = TimeAndOffset(existing) ?? fallbackTail;
        string value = stamp + tail;

        if (string.Equals(existing.Trim(), value, StringComparison.Ordinal)) return (pageText, false);

        string newline = DominantNewline(pageText);
        string line = key + ": " + value;

        if (block is null)
            return ("---" + newline + line + newline + "---" + newline + pageText, true);

        var lines = new List<string>(block.Lines);
        if (block.IndexOf(key) is { } at)
            lines[at] = ReplaceRawValue(lines[at], value);
        else
            lines.Insert(block.FirstBodyLine, line);
        return (block.Rebuild(lines, newline), true);
    }

    /// <summary>Everything after the calendar date in an ISO timestamp, or null.</summary>
    private static string? TimeAndOffset(string raw)
    {
        string value = raw.Trim().Trim('"', '\'');
        if (value.Length < 10) return null;
        for (int i = 0; i < 10; i++)
            if (i is 4 or 7 ? value[i] != '-' : !char.IsDigit(value[i])) return null;
        return value[10..];
    }

    private static string ReplaceRawValue(string line, string value)
    {
        string carriageReturn = line.EndsWith('\r') ? "\r" : "";
        string body = line.TrimEnd('\r');
        int colon = body.IndexOf(':');
        if (colon < 0) return line;
        return body[..(colon + 1)] + " " + value + carriageReturn;
    }

    /// <summary>
    /// The page text with <paramref name="key"/> set to
    /// <paramref name="draft"/>, and a note of what that changed.
    ///
    /// An existing key is edited where it sits. A missing key is inserted at
    /// the top of the block, which is where the course installer puts it and
    /// which can never land inside a nested list or block scalar. A page with
    /// no frontmatter at all gets a block.
    /// </summary>
    /// <summary>
    /// Set a page's visibility, writing the <c>publish</c> key and clearing
    /// any leftover <c>draft</c> one.
    ///
    /// Migration happens here, a page at a time, as things are touched. There
    /// is no sweep and no flag day: build_site.py reads the old keys too, so a
    /// course that nobody has touched still builds exactly as it did, and a
    /// page converts the moment anything changes its visibility.
    /// </summary>
    /// <param name="key">The publish key, from <see cref="PublishKeyFor"/>.</param>
    /// <param name="draft">True to hide the page from students.</param>
    public static (string Text, DraftEdit Edit) SetDraft(string pageText, string key, bool draft)
    {
        bool publish = !draft;
        var block = Block.Parse(pageText);
        // Reads the old key too, so a page that predates the change reports
        // the state it actually has rather than "not set".
        bool? before = StoredDraft(pageText, key);

        string legacy = LegacyKeyOf(key);
        bool hasLegacy = block?.IndexOf(legacy) is not null;

        // Already right AND already migrated: nothing to do.
        if (before == draft && !hasLegacy)
            return (pageText, new DraftEdit(key, before, draft, Changed: false));

        string newline = DominantNewline(pageText);
        string line = key + ": " + (publish ? "true" : "false");

        if (block is null)
        {
            string text = "---" + newline + line + newline + "---" + newline + pageText;
            return (text, new DraftEdit(key, null, draft, Changed: true));
        }

        var lines = new List<string>(block.Lines);
        int? publishAt = block.IndexOf(key);
        int? legacyAt = block.IndexOf(legacy);

        if (publishAt is { } at)
        {
            lines[at] = ReplaceValue(lines[at], publish);
            // Already migrated; the leftover is just noise now.
            if (legacyAt is { } duplicate) lines.RemoveAt(duplicate);
        }
        else if (legacyAt is { } old)
        {
            // Migrating: put the new key exactly where the old one sat, so the
            // teacher's frontmatter keeps its order. Moving it to the top would
            // show up as a reordered diff in a file Obsidian has open.
            string carriageReturn = lines[old].EndsWith('\r') ? "\r" : "";
            lines[old] = line + carriageReturn;
        }
        else
        {
            lines.Insert(block.FirstBodyLine, line);
        }

        return (block.Rebuild(lines, newline), new DraftEdit(key, before, draft, Changed: true));
    }

    /// <summary>The pre-change key that answers the same question as <paramref name="key"/>.</summary>
    private static string LegacyKeyOf(string key) =>
        key.StartsWith("publishForSection", StringComparison.Ordinal)
            ? "draftSection" + key["publishForSection".Length..]
            : "draft";

    /// <summary>
    /// Rewrites the value after the colon while preserving whatever came
    /// before it — indentation, the key's own spelling, and any spacing the
    /// teacher used. An inline <c># comment</c> after the value survives.
    /// </summary>
    private static string ReplaceValue(string line, bool draft)
    {
        // A CRLF file's lines still carry their '\r' here; rebuilding the line
        // without putting it back would quietly convert that one line to LF.
        string carriageReturn = line.EndsWith('\r') ? "\r" : "";
        string body = line.TrimEnd('\r');

        int colon = body.IndexOf(':');
        if (colon < 0) return line;   // not a mapping line; leave it alone
        string head = body[..(colon + 1)];
        string tail = body[(colon + 1)..];

        int hash = tail.IndexOf('#');
        string comment = hash >= 0 ? tail[hash..].TrimEnd() : "";
        string spacing = tail.Length > 0 && tail[0] == ' ' ? " " : "";
        string gap = comment.Length > 0 ? " " : "";

        return head + spacing + (draft ? "true" : "false") + gap + comment + carriageReturn;
    }

    private static string DominantNewline(string text) =>
        text.Contains("\r\n", StringComparison.Ordinal) ? "\r\n" : "\n";

    /// <summary>
    /// The frontmatter block as raw lines, with just enough structure to find
    /// a top-level key. Deliberately not a YAML parser: it understands the
    /// shape of the files this toolchain writes and declines to guess at
    /// anything else.
    /// </summary>
    private sealed class Block
    {
        public required string[] Lines { get; init; }
        public required int Open { get; init; }      // index of the opening ---
        public required int Close { get; init; }     // index of the closing ---
        public required string Original { get; init; }

        /// <summary>Where a newly inserted key goes: straight after the opening fence.</summary>
        public int FirstBodyLine => Open + 1;

        public static Block? Parse(string text)
        {
            string[] lines = text.Split('\n');
            int open = -1;
            for (int i = 0; i < lines.Length; i++)
            {
                string trimmed = Strip(lines[i]);
                if (trimmed.Length == 0) continue;          // leading blank lines are tolerated
                if (trimmed != "---") return null;          // content before a fence: no frontmatter
                open = i;
                break;
            }
            if (open < 0) return null;

            for (int i = open + 1; i < lines.Length; i++)
            {
                string trimmed = Strip(lines[i]);
                if (trimmed == "---" || trimmed == "...")
                    return new Block { Lines = lines, Open = open, Close = i, Original = text };
            }
            return null;   // unterminated block — refuse to edit rather than guess
        }

        /// <summary>
        /// The index of a TOP-LEVEL key's line, or null. Indentation matters:
        /// an indented <c>draft:</c> is a field of some other mapping, not the
        /// page's own flag, and editing it would change something else.
        /// </summary>
        public int? IndexOf(string key)
        {
            for (int i = Open + 1; i < Close; i++)
            {
                string raw = Lines[i].TrimEnd('\r');
                if (raw.Length == 0 || char.IsWhiteSpace(raw[0])) continue;   // blank or nested
                string line = raw.TrimEnd();
                if (line.Length == 0 || line[0] == '#') continue;
                if (line.StartsWith(key, StringComparison.Ordinal) &&
                    line.Length > key.Length && line[key.Length] == ':')
                    return i;
            }
            return null;
        }

        public bool? BoolValue(string key)
        {
            if (IndexOf(key) is not { } at) return null;
            string line = Strip(Lines[at]);
            string value = line[(line.IndexOf(':') + 1)..];
            int hash = value.IndexOf('#');
            if (hash >= 0) value = value[..hash];
            value = value.Trim();
            if (value.Equals("true", StringComparison.OrdinalIgnoreCase)) return true;
            if (value.Equals("false", StringComparison.OrdinalIgnoreCase)) return false;
            return null;   // a non-boolean draft value is not ours to interpret
        }

        /// <summary>The text after the first colon, exactly as written.</summary>
        public string? RawValue(string key)
        {
            if (IndexOf(key) is not { } at) return null;
            string line = Strip(Lines[at]);
            return line[(line.IndexOf(':') + 1)..].Trim();
        }

        /// <summary>
        /// A date value, read in the offset the page itself states. Quoting is
        /// tolerated because YAML writers vary; anything unparseable is null
        /// rather than a guess.
        /// </summary>
        public DateOnly? DateValue(string key)
        {
            if (IndexOf(key) is not { } at) return null;
            string line = Strip(Lines[at]);
            string value = line[(line.IndexOf(':') + 1)..].Trim().Trim('"', '\'');
            if (value.Length == 0) return null;
            if (DateTimeOffset.TryParse(value, System.Globalization.CultureInfo.InvariantCulture,
                    System.Globalization.DateTimeStyles.None, out var stamp))
                return DateOnly.FromDateTime(stamp.Date);
            if (DateOnly.TryParse(value, System.Globalization.CultureInfo.InvariantCulture,
                    System.Globalization.DateTimeStyles.None, out var plain))
                return plain;
            return null;
        }

        public string Rebuild(List<string> lines, string newline)
        {
            // Split/join on '\n' alone would strip the '\r' from CRLF files, so
            // the lines still carry theirs; only an INSERTED line needs one.
            var builder = new StringBuilder();
            for (int i = 0; i < lines.Count; i++)
            {
                builder.Append(lines[i]);
                if (i < lines.Count - 1)
                    builder.Append(lines[i].EndsWith('\r') || newline == "\n" ? "\n" : newline);
            }
            return builder.ToString();
        }

        private static string Strip(string line) => line.TrimEnd('\r').Trim();
    }
}

/// <summary>
/// What one draft edit did, in terms the confirmation panel can put into a
/// sentence: which key, what it was, what it became.
/// </summary>
public readonly record struct DraftEdit(string Key, bool? Before, bool After, bool Changed)
{
    /// <summary>Plain words for a teacher, in the app's voice.</summary>
    public string Describe(string pageTitle) => Changed
        ? After ? $"Hide “{pageTitle}”" : $"Publish “{pageTitle}”"
        : After ? $"“{pageTitle}” is already hidden" : $"“{pageTitle}” is already published";
}
