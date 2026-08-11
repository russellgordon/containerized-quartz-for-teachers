namespace Plantoir.Core.Catalogs;

/// <summary>Defaults for a brand-new course — mirrors scripts/setup_course.py.</summary>
public static class WizardDefaults
{
    public static readonly IReadOnlyList<string> SharedFolders = new[]
    {
        "Concepts", "Discussions", "Examples", "Exercises", "Ontario Curriculum",
        "College Board Curriculum", "Portfolios", "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    };

    public static readonly IReadOnlyList<string> SharedFiles = new[]
    {
        "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md",
    };

    public static readonly IReadOnlyList<string> PerSectionFolders = new[] { "All Classes" };

    public static readonly IReadOnlyList<string> PerSectionFiles = new[]
    {
        "Private Notes.md", "Scratch Page.md", "Key Links.md",
    };

    public static readonly IReadOnlyList<string> HiddenItems = new[]
    {
        "Media", "Ontario Curriculum", "College Board Curriculum",
        "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md",
        "Private Notes.md", "Scratch Page.md", "Key Links.md",
    };

    public static readonly IReadOnlyList<string> ExpandableItems = new[]
    {
        "Concepts", "Discussions", "Examples", "Exercises", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    };

    public const string DefaultLocale = "en-US";
    public const string DefaultEmoji = "📚";
    public const string DefaultColourSchemeId = "quartz-standard";
    public const string FallbackCourseName = "Course Website";
}
