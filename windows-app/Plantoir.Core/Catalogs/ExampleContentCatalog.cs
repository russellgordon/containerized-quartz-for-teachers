using Newtonsoft.Json.Linq;

namespace Plantoir.Core.Catalogs;

/// <summary>
/// Answers one question for the new-course wizard: does ready-made example
/// content exist for a course code? The content itself lives in the bundled
/// support/example_content/&lt;CODE&gt;/ folders — one per course code, each
/// with a manifest.json — and is installed by the real setup wizard, not by
/// the app. The app only needs to know whether to offer it. Mirrors the mac
/// app's ExampleContentCatalog; callers pass the bundled example_content
/// directory (the Core layer knows no bundle paths).
/// </summary>
public static class ExampleContentCatalog
{
    /// <summary>
    /// The bundled manifest for a course code, or null when no example
    /// content exists for it. Lookup is case-insensitive, matching how
    /// course codes are normalized everywhere else.
    /// </summary>
    public static string? ManifestPath(string exampleContentRoot, string code)
    {
        string normalized = code.Trim().ToUpperInvariant();
        if (normalized.Length == 0) return null;
        string path = Path.Combine(exampleContentRoot, normalized, "manifest.json");
        return File.Exists(path) ? path : null;
    }

    /// <summary>True when example content is bundled for this course code.</summary>
    public static bool HasContent(string exampleContentRoot, string code) =>
        ManifestPath(exampleContentRoot, code) is not null;

    /// <summary>
    /// True when the example content for this code includes the official
    /// curriculum pages — the wizard only shows the curriculum toggle when
    /// there are curriculum pages to include. Any unreadable manifest simply
    /// answers false, never throws.
    /// </summary>
    public static bool IncludesCurriculum(string exampleContentRoot, string code)
    {
        if (ManifestPath(exampleContentRoot, code) is not { } path) return false;
        try
        {
            var manifest = JObject.Parse(File.ReadAllText(path));
            return manifest["curriculum_folder"]?.Type == JTokenType.String
                && manifest["curriculum_folder"]!.ToString().Length > 0;
        }
        catch
        {
            return false;
        }
    }
}
