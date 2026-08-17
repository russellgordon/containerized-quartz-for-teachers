using System;
using System.IO;
using System.Text.RegularExpressions;

namespace Plantoir.Core.Models;

public static class CurriculumRules
{
    private static readonly Regex ExpectationCodeRegex = new(@"^[A-Za-z]\d+\.\d+$", RegexOptions.Compiled);
    private static readonly Regex BlockAnchorRegex = new(@"\s+\^[A-Za-z0-9_-]+$", RegexOptions.Compiled);

    /// <summary>
    /// Checks whether a page path is inside a curriculum folder.
    /// Matches any folder segment containing "curriculum" (case-insensitive);
    /// the file name itself is ignored.
    /// </summary>
    public static bool IsCurriculumPage(string path)
    {
        if (string.IsNullOrWhiteSpace(path)) return false;

        string normalized = path.Replace('\\', '/');
        var segments = normalized.Split('/');
        for (int i = 0; i < segments.Length - 1; i++)
        {
            if (segments[i].Contains("curriculum", StringComparison.OrdinalIgnoreCase))
                return true;
        }
        return false;
    }

    /// <summary>
    /// Checks whether a string is a leaf curriculum expectation code (e.g., "A1.1", "B2.11").
    /// </summary>
    public static bool IsExpectationCode(string code)
    {
        if (string.IsNullOrWhiteSpace(code)) return false;
        return ExpectationCodeRegex.IsMatch(code.Trim());
    }

    /// <summary>
    /// Returns the expectation wording from a markdown body:
    /// body after frontmatter, minus any trailing block anchor (e.g. ^b21).
    /// </summary>
    public static string ExpectationWording(string body)
    {
        if (string.IsNullOrWhiteSpace(body)) return "";

        string afterFrontmatter = StripFrontmatter(body).Trim();
        return BlockAnchorRegex.Replace(afterFrontmatter, "").Trim();
    }

    private static string StripFrontmatter(string text)
    {
        if (!text.StartsWith("---")) return text;
        int next = text.IndexOf("---", 3, StringComparison.Ordinal);
        if (next < 0) return text;
        return text[(next + 3)..];
    }
}
