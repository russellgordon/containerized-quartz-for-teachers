using System.Text;

namespace Plantoir.Core.Scripting;

/// <summary>
/// Turns raw terminal output into clean display lines.
///
/// A pseudo console converts every "\n" the script prints into "\r\n", so
/// CR followed by LF is an ordinary line ending. Only a LONE carriage
/// return is a spinner redrawing its line — it restarts the current line.
/// ANSI escape sequences (colours, cursor movement, OSC titles) are
/// stripped before the line machine runs.
/// </summary>
public sealed class TranscriptBuilder
{
    public const int MaximumRetainedLines = 4000;

    private readonly List<string> _lines = new();
    private readonly StringBuilder _currentLine = new();
    private bool _hasPendingCarriageReturn;
    private string? _cachedDisplayText;
    private long _version;

    /// <summary>Completed lines, oldest first (capped at MaximumRetainedLines).</summary>
    public IReadOnlyList<string> Lines => _lines;

    /// <summary>The unterminated line under construction.</summary>
    public string CurrentLine => _currentLine.ToString();

    /// <summary>Monotonic counter bumped on every append — cheap change detection.</summary>
    public long Version => _version;

    public void Append(string rawText)
    {
        _cachedDisplayText = null;
        _version++;
        string cleaned = StripControlSequences(rawText);
        foreach (char c in cleaned)
        {
            if (_hasPendingCarriageReturn)
            {
                _hasPendingCarriageReturn = false;
                if (c == '\n') { PushLine(); continue; }
                _currentLine.Clear();               // lone CR: spinner redraw
            }
            if (c == '\n') { PushLine(); }
            else if (c == '\r') { _hasPendingCarriageReturn = true; }
            else { _currentLine.Append(c); }
        }
    }

    private void PushLine()
    {
        _lines.Add(_currentLine.ToString());
        _currentLine.Clear();
        if (_lines.Count > MaximumRetainedLines)
            _lines.RemoveRange(0, _lines.Count - MaximumRetainedLines);
    }

    public string DisplayText
    {
        get
        {
            if (_cachedDisplayText is null)
            {
                var all = _currentLine.Length > 0
                    ? _lines.Append(_currentLine.ToString())
                    : _lines;
                _cachedDisplayText = string.Join("\n", all);
            }
            return _cachedDisplayText;
        }
    }

    /// <summary>The tail of the transcript, built without joining everything.</summary>
    public string RecentText(int maximumCharacters)
    {
        var collected = new List<string>();
        int budget = maximumCharacters;
        string current = _currentLine.ToString();
        if (current.Length > 0) { collected.Add(current); budget -= current.Length + 1; }
        for (int i = _lines.Count - 1; i >= 0 && budget > 0; i--)
        {
            collected.Add(_lines[i]);
            budget -= _lines[i].Length + 1;
        }
        collected.Reverse();
        return string.Join("\n", collected);
    }

    /// <summary>
    /// Strips ANSI CSI (ESC [ ... final letter), OSC (ESC ] ... BEL), other
    /// two-byte escapes, and control characters below 0x20 except \n \r \t.
    /// </summary>
    public static string StripControlSequences(string text)
    {
        var result = new StringBuilder(text.Length);
        int i = 0;
        while (i < text.Length)
        {
            char c = text[i];
            if (c == '\x1b')
            {
                if (i + 1 < text.Length && text[i + 1] == '[')
                {
                    int j = i + 2;
                    while (j < text.Length && !char.IsAsciiLetter(text[j])) j++;
                    i = j + 1;
                    continue;
                }
                if (i + 1 < text.Length && text[i + 1] == ']')
                {
                    int j = i + 2;
                    while (j < text.Length && text[j] != '\x07') j++;
                    i = j + 1;
                    continue;
                }
                i += 2;
                continue;
            }
            if (c < ' ' && c != '\n' && c != '\r' && c != '\t') { i++; continue; }
            result.Append(c);
            i++;
        }
        return result.ToString();
    }
}
