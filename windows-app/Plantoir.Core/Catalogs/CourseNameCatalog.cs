using System.Text.Json.Nodes;

namespace Plantoir.Core.Catalogs;

public sealed record CourseNames(string Formal, string Short);

/// <summary>
/// Ontario course-name lookup from support/ontario_secondary_courses.json —
/// the same file the CLI wizard consults. Codes are trimmed and uppercased
/// before lookup; unknown and club codes return null.
/// </summary>
public sealed class CourseNameCatalog
{
    private readonly Dictionary<string, CourseNames> _entries = new();

    public static CourseNameCatalog Load(string jsonPath)
    {
        var catalog = new CourseNameCatalog();
        try
        {
            if (JsonNode.Parse(File.ReadAllBytes(jsonPath)) is JsonObject root)
                foreach (var (code, value) in root)
                {
                    if (value is not JsonObject entry) continue;
                    if (entry["formal_name"] is not JsonValue f || !f.TryGetValue<string>(out string? formal)) continue;
                    if (entry["short_name"] is not JsonValue s || !s.TryGetValue<string>(out string? shortName)) continue;
                    catalog._entries[code] = new CourseNames(formal, shortName);
                }
        }
        catch { }
        return catalog;
    }

    public CourseNames? Names(string code)
    {
        string key = code.Trim().ToUpperInvariant();
        return _entries.TryGetValue(key, out CourseNames? names) ? names : null;
    }

    public int Count => _entries.Count;
}
