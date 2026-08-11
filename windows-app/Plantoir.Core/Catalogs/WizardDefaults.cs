namespace Plantoir.Core.Catalogs;

/// <summary>
/// Defaults for a brand-new course — mirrors the DEFAULT_* / LCS_* constants
/// at the top of scripts/setup_course.py (and the mac app's WizardDefaults).
///
/// The factory defaults are deliberately school-neutral; the "Use
/// LCS-specific terminology" switch brings back LCS's own set-up — its terms
/// (Grove Time, SIC) and the College Board folder its AP courses use. The
/// paired lists are the whole difference. "Media" is absent from the app-side
/// folder lists on purpose: the toolchain manages it itself.
/// </summary>
public static class WizardDefaults
{
    public static readonly IReadOnlyList<string> SharedFolders = new[]
    {
        "Concepts", "Discussions", "Examples", "Exercises",
        "Ontario Curriculum", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    };

    public static readonly IReadOnlyList<string> LcsSharedFolders = new[]
    {
        "Concepts", "Discussions", "Examples", "Exercises",
        "Ontario Curriculum", "College Board Curriculum", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials",
    };

    public static readonly IReadOnlyList<string> SharedFiles = new[]
    {
        "Extra Help.md", "Learning Goals.md",
    };

    public static readonly IReadOnlyList<string> LcsSharedFiles = new[]
    {
        "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md",
    };

    public static readonly IReadOnlyList<string> PerSectionFolders = new[] { "All Classes" };

    public static readonly IReadOnlyList<string> PerSectionFiles = new[]
    {
        "Private Notes.md", "Scratch Page.md", "Key Links.md",
    };

    /// <summary>
    /// Both terminologies appear here, so whichever names a course ends up
    /// with are hidden by default.
    /// </summary>
    public static readonly IReadOnlyList<string> HiddenItems = new[]
    {
        "Media", "Ontario Curriculum", "College Board Curriculum",
        "Extra Help.md", "SIC Drop-In Sessions.md", "Grove Time.md",
        "Learning Goals.md",
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

    /// <summary>
    /// The current list, moved to the other terminology's factory set:
    /// factory items are replaced wholesale, while names the teacher added
    /// themselves survive at the end of the list. A factory item the teacher
    /// deleted stays deleted only if they also deleted its counterpart's
    /// spot — the switch is a reset of the factory portion, which keeps its
    /// behaviour predictable.
    /// </summary>
    public static List<string> SwitchingFactoryItems(
        IReadOnlyList<string> currentNames,
        IReadOnlyList<string> toFactory,
        IReadOnlyList<string> fromFactory)
    {
        var result = new List<string>(toFactory);
        foreach (string name in currentNames)
        {
            bool belongsToAFactorySet = toFactory.Contains(name) || fromFactory.Contains(name);
            if (!belongsToAFactorySet && !result.Contains(name))
                result.Add(name);
        }
        return result;
    }
}
