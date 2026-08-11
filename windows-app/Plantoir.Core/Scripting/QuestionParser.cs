using System.Text;

namespace Plantoir.Core.Scripting;

/// <summary>What a waiting script asked, ready for a native dialog.</summary>
public sealed record AskedQuestion(string Question, string SuggestedAnswer, string CancelToken);

/// <summary>
/// Turns a raw prompt line into dialog-ready pieces: the wording (keystroke
/// asides removed), the bracketed default lifted into the answer field, and
/// the script's own cancel key captured so Cancel runs the script's clean-up.
/// </summary>
public static class QuestionParser
{
    /// <summary>Prompt shapes the toolchain's scripts actually use.</summary>
    public static bool LooksLikeQuestion(string line) =>
        line.EndsWith(':') || line.EndsWith('?') || line.EndsWith('>')
        || line.Contains("(y/n)") || line.Contains("[Y/n]") || line.Contains("[Default:");

    /// <summary>
    /// Lifts a bracketed default out of the wording and into the field, so
    /// agreeing is one keystroke and changing it is still easy. A bracket
    /// containing "/" names choices ([Y/n]) rather than a value — it stays
    /// in the wording with nothing pre-filled.
    /// </summary>
    public static AskedQuestion SeparateDefaultAnswer(string question)
    {
        int open = question.LastIndexOf('[');
        int close = question.LastIndexOf(']');
        if (open < 0 || close < 0 || open >= close)
            return new AskedQuestion(Asked(question), "", CancelToken(question));

        string offered = question[(open + 1)..close].Trim();
        if (offered.StartsWith("Default:", StringComparison.Ordinal))
            offered = offered["Default:".Length..].Trim();
        if (offered.Length == 0 || offered.Contains('/'))
            return new AskedQuestion(Asked(question), "", CancelToken(question));

        string wording = question[..open].Trim() + question[(close + 1)..].Trim();
        return new AskedQuestion(Asked(wording), offered, CancelToken(question));
    }

    /// <summary>
    /// The key the script accepts as "cancel" at this question — captured
    /// from a parenthetical like "(or 'q' to cancel)" before the aside is
    /// hidden from the dialog. Empty when the script offers no way out.
    /// </summary>
    public static string CancelToken(string question)
    {
        string token = "";
        int depth = 0;
        var aside = new StringBuilder();
        foreach (char c in question)
        {
            if (c == '(')
            {
                depth++;
                if (depth == 1) { aside.Clear(); continue; }
            }
            else if (c == ')')
            {
                depth--;
                if (depth == 0)
                {
                    string text = aside.ToString();
                    if (OffersAWayOut(text))
                    {
                        string quoted = QuotedText(text);
                        if (quoted.Length > 0) token = quoted;   // later asides win
                    }
                    continue;
                }
            }
            if (depth > 0) aside.Append(c);
        }
        return token;
    }

    private static bool OffersAWayOut(string aside)
    {
        string lower = aside.ToLowerInvariant();
        return lower.Contains("cancel") || lower.Contains("quit");
    }

    /// <summary>Text between the first pair of quotes (' or ", either kind).</summary>
    internal static string QuotedText(string text)
    {
        var collected = new StringBuilder();
        bool inQuote = false;
        foreach (char c in text)
        {
            if (c == '\'' || c == '"')
            {
                if (inQuote) return collected.ToString();
                inQuote = true;
                continue;
            }
            if (inQuote) collected.Append(c);
        }
        return "";
    }

    /// <summary>Dialog wording: keystroke asides removed, spacing tidied.</summary>
    public static string Asked(string question) => TidyingSpacing(RemovingKeystrokeAside(question));

    /// <summary>
    /// Drops a top-level parenthetical that names a key to type — the dialog
    /// has its own Cancel button. Informative asides like (y/n) are kept;
    /// an unclosed bracket is not an aside and is kept verbatim.
    /// </summary>
    internal static string RemovingKeystrokeAside(string question)
    {
        var result = new StringBuilder();
        var aside = new StringBuilder();
        int depth = 0;
        foreach (char c in question)
        {
            if (c == '(')
            {
                depth++;
                if (depth == 1) { aside.Clear(); continue; }
            }
            else if (c == ')')
            {
                depth--;
                if (depth == 0)
                {
                    string text = aside.ToString();
                    if (!NamesAKeyToType(text)) result.Append('(').Append(text).Append(')');
                    continue;
                }
            }
            if (depth > 0) aside.Append(c);
            else result.Append(c);
        }
        if (depth > 0) result.Append('(').Append(aside);
        return result.ToString();
    }

    private static bool NamesAKeyToType(string aside)
    {
        string lower = aside.ToLowerInvariant();
        return lower.Contains("cancel") || lower.Contains("quit") || lower.Contains("skip");
    }

    /// <summary>Collapses space runs and closes the gap a removed aside leaves before ":" or "?".</summary>
    internal static string TidyingSpacing(string text)
    {
        var result = new StringBuilder(text.Length);
        foreach (char c in text)
        {
            if (c == ' ' && result.Length > 0 && result[^1] == ' ') continue;
            if ((c == ':' || c == '?') && result.Length > 0 && result[^1] == ' ')
                result.Length--;
            result.Append(c);
        }
        return result.ToString().Trim();
    }
}
