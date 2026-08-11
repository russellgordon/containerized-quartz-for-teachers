using System.Text.Json.Nodes;

namespace Plantoir.Core.Catalogs;

/// <summary>One colour scheme from support/colour_schemes.json.</summary>
public sealed record ColourScheme(string Id, string Name,
    IReadOnlyDictionary<string, string> LightModeColors,
    IReadOnlyDictionary<string, string> DarkModeColors)
{
    /// <summary>Light-mode swatches in fixed order, skipping absent keys.</summary>
    public IReadOnlyList<string> SwatchValues =>
        new[] { "secondary", "tertiary", "dark", "light" }
            .Where(LightModeColors.ContainsKey)
            .Select(k => LightModeColors[k])
            .ToList();
}

/// <summary>
/// Loads support/colour_schemes.json — the same file the CLI picker reads.
/// Tolerates either a bare array or {"schemes": [...]}; all failures
/// degrade to an empty catalog, never a crash.
/// </summary>
public static class ColourSchemeCatalog
{
    public static IReadOnlyList<ColourScheme> Load(string jsonPath)
    {
        try { return Parse(File.ReadAllBytes(jsonPath)); }
        catch { return Array.Empty<ColourScheme>(); }
    }

    public static IReadOnlyList<ColourScheme> Parse(byte[] json)
    {
        try
        {
            JsonNode? root = JsonNode.Parse(json);
            JsonArray? array = root as JsonArray ?? (root as JsonObject)?["schemes"] as JsonArray;
            if (array is null) return Array.Empty<ColourScheme>();
            var schemes = new List<ColourScheme>();
            foreach (JsonNode? element in array)
            {
                if (element is not JsonObject obj) continue;
                if (obj["id"] is not JsonValue idValue || !idValue.TryGetValue<string>(out string? id)) continue;
                string name = obj["name"] is JsonValue nameValue && nameValue.TryGetValue<string>(out string? n) ? n : id;
                schemes.Add(new ColourScheme(id, name,
                    ColorMap(obj, "lightMode"), ColorMap(obj, "darkMode")));
            }
            return schemes;
        }
        catch { return Array.Empty<ColourScheme>(); }
    }

    private static IReadOnlyDictionary<string, string> ColorMap(JsonObject scheme, string mode)
    {
        var map = new Dictionary<string, string>();
        if (scheme["colors"] is JsonObject colors && colors[mode] is JsonObject modeMap)
            foreach (var (key, value) in modeMap)
                if (value is JsonValue v && v.TryGetValue<string>(out string? s)) map[key] = s;
        return map;
    }
}
