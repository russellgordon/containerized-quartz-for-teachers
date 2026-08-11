using System.Globalization;

namespace Plantoir.Core.Models;

/// <summary>
/// One thing the teacher removed, recoverable from a zip under
/// courses/_backups/&lt;CODE&gt;/. Only archives NAMED after what was removed
/// count — the setup wizard's automatic backups are named by timestamp
/// alone and must never appear as archived courses.
/// </summary>
public sealed record ArchivedItem(string CourseCode, int? SectionNumber, DateTime ArchivedAt, string FilePath)
{
    public string Id => FilePath;

    public string Title => SectionNumber is int n ? $"{CourseCode} — Section {n}" : CourseCode;

    /// <summary>Segoe Fluent glyph name analogues of the mac symbols.</summary>
    public bool IsCourse => SectionNumber is null;

    public string Subtitle => "Archived " + ArchivedAt.ToString("d MMMM yyyy", CultureInfo.CurrentCulture);

    public const string StampFormat = "yyyy-MM-dd_HHmmss";

    public static ArchivedItem? From(string filePath, string courseCode)
    {
        if (!filePath.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)) return null;
        string name = Path.GetFileNameWithoutExtension(filePath);
        int underscore = name.IndexOf('_');
        if (underscore < 0) return null;
        string subject = name[..underscore];
        string stamp = name[(underscore + 1)..];
        if (!DateTime.TryParseExact(stamp, StampFormat, CultureInfo.InvariantCulture,
                                    DateTimeStyles.None, out DateTime archivedAt))
            return null;
        if (subject == courseCode)
            return new ArchivedItem(courseCode, null, archivedAt, filePath);
        string sectionPrefix = courseCode + "-section";
        if (subject.StartsWith(sectionPrefix, StringComparison.Ordinal) &&
            int.TryParse(subject[sectionPrefix.Length..], out int section))
            return new ArchivedItem(courseCode, section, archivedAt, filePath);
        return null;
    }
}
