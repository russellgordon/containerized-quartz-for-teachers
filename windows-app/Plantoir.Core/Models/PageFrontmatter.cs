using System.Text;

namespace Plantoir.Core.Models;

/// <summary>
/// Reading and editing the <c>draft:</c> flag in a page's YAML frontmatter,
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
///   it carries a plain <c>draft:</c>.
/// * A page at course level is copied into EVERY section at build time, so it
///   carries <c>draftSection&lt;N&gt;:</c> — one flag per section, which is
///   what lets "Ohm's Law" be published in section 1 and still drafted in
///   section 2.
///
/// This mirrors <c>process_frontmatter</c> in build_site.py, which copies
/// <c>draftSection&lt;N&gt;</c> over <c>draft</c> for the section being built
/// and then strips every <c>draftSection*</c> key from the built copy. The
/// source files keep both; only the build output is flattened.
/// </summary>
public static class PageFrontmatter
{
    /// <summary>The frontmatter key that governs this page in this section.</summary>
    /// <param name="isSectionLocal">
    /// True when the page lives under <c>section&lt;N&gt;/</c>. Callers get
    /// this from <see cref="PagePaths"/> rather than deciding it themselves.
    /// </param>
    public static string DraftKeyFor(int sectionNumber, bool isSectionLocal) =>
        isSectionLocal ? "draft" : "draftSection" + sectionNumber;

    /// <summary>
    /// Whether this page is a draft in the given section, resolved the way the
    /// build resolves it: the per-section key wins, a plain <c>draft:</c> is
    /// the fallback, and a page with neither is published — matching Quartz's
    /// own default.
    /// </summary>
    public static bool IsDraft(string pageText, int sectionNumber)
    {
        var block = Block.Parse(pageText);
        if (block is null) return false;
        return block.BoolValue("draftSection" + sectionNumber)
            ?? block.BoolValue("draft")
            ?? false;
    }

    /// <summary>
    /// The value literally stored under one key, or null when the key is
    /// absent. The caller needs the difference between "set to false" and
    /// "not set at all" to describe an edit honestly.
    /// </summary>
    public static bool? StoredValue(string pageText, string key) =>
        Block.Parse(pageText)?.BoolValue(key);

    /// <summary>
    /// The page text with <paramref name="key"/> set to
    /// <paramref name="draft"/>, and a note of what that changed.
    ///
    /// An existing key is edited where it sits. A missing key is inserted at
    /// the top of the block, which is where the course installer puts it and
    /// which can never land inside a nested list or block scalar. A page with
    /// no frontmatter at all gets a block.
    /// </summary>
    public static (string Text, DraftEdit Edit) SetDraft(string pageText, string key, bool draft)
    {
        var block = Block.Parse(pageText);
        bool? before = block?.BoolValue(key);
        if (before == draft) return (pageText, new DraftEdit(key, before, draft, Changed: false));

        string newline = DominantNewline(pageText);
        string line = key + ": " + (draft ? "true" : "false");

        if (block is null)
        {
            // No frontmatter. Give the page a block and keep its body intact.
            string text = "---" + newline + line + newline + "---" + newline + pageText;
            return (text, new DraftEdit(key, null, draft, Changed: true));
        }

        var lines = new List<string>(block.Lines);
        if (block.IndexOf(key) is { } at)
            lines[at] = ReplaceValue(lines[at], draft);
        else
            lines.Insert(block.FirstBodyLine, line);

        return (block.Rebuild(lines, newline), new DraftEdit(key, before, draft, Changed: true));
    }

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
