using System.Text.RegularExpressions;

namespace Plantoir.Core.Models;

/// <summary>
/// A unit and day number for a class page, e.g. Unit 3, Day 2.
/// </summary>
public readonly record struct UnitDay(int Unit, int Day)
{
    private static readonly Regex UnitDayRegex = new(@"^Unit\s+(\d+),\s*Day\s+(\d+)$", RegexOptions.Compiled);

    public string Title => $"Unit {Unit}, Day {Day}";

    public static UnitDay? Parse(string title)
    {
        if (string.IsNullOrWhiteSpace(title)) return null;
        var match = UnitDayRegex.Match(title.Trim());
        if (!match.Success) return null;
        return new UnitDay(int.Parse(match.Groups[1].Value), int.Parse(match.Groups[2].Value));
    }
}
