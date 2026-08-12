namespace Plantoir.Core.Models;

/// <summary>
/// The string forms a remembered window stores for its sidebar state
/// (row 99): the selection as "course|CODE", "section|CODE|N", or
/// "archived|ID", and the open course codes comma-joined (codes never
/// contain commas). Unrecognized or empty stored forms decode to nothing.
///
/// One deliberate divergence from the mac: an entry WITHOUT expansion
/// state (a legacy entry, or a brand-new window) restores all-EXPANDED on
/// Windows — encoded as null — where the mac restores all-collapsed. An
/// explicit empty string means "the teacher collapsed everything".
/// </summary>
public static class WindowMemoryCodec
{
    public sealed record DecodedSelection(string Kind, string Code, int Section, string Id);

    public static string EncodeCourse(string code) => $"course|{code}";
    public static string EncodeSection(string code, int section) => $"section|{code}|{section}";
    public static string EncodeArchived(string id) => $"archived|{id}";

    public static DecodedSelection? ParseSelection(string? stored)
    {
        if (string.IsNullOrWhiteSpace(stored)) return null;
        var parts = stored.Split('|');
        return parts switch
        {
            ["course", var code] when code.Length > 0 =>
                new DecodedSelection("course", code, 0, ""),
            ["section", var code, var number] when code.Length > 0 && int.TryParse(number, out int n) && n > 0 =>
                new DecodedSelection("section", code, int.Parse(number), ""),
            ["archived", var id] when id.Length > 0 =>
                new DecodedSelection("archived", "", 0, id),
            _ => null,
        };
    }

    /// <summary>null means "everything open" (the Windows fallback).</summary>
    public static string? EncodeExpandedCourses(IReadOnlyCollection<string>? openCodes) =>
        openCodes is null ? null : string.Join(",", openCodes.OrderBy(c => c, StringComparer.Ordinal));

    /// <summary>null in, null out: no stored state keeps the all-open fallback.</summary>
    public static HashSet<string>? ParseExpandedCourses(string? stored) =>
        stored is null
            ? null
            : stored.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .ToHashSet(StringComparer.Ordinal);
}
