using System.Globalization;

namespace Plantoir.Core.Models;

/// <summary>
/// A saved copy of a whole course, made on purpose before risky editing —
/// handing a pile of pages to an LLM, say — so there is always a way back.
///
/// Backups live beside the archives in courses/_backups/&lt;CODE&gt;/, told
/// apart by name: a backup is &lt;CODE&gt;_backup_&lt;timestamp&gt;.zip, an archive is
/// &lt;CODE&gt;_&lt;timestamp&gt;.zip, and the setup wizard's automatic zips are
/// &lt;timestamp&gt;.zip alone. Each parser accepts only its own form, so the
/// three kinds can never appear in each other's lists.
/// </summary>
public sealed record BackupItem(string CourseCode, DateTime BackedUpAt, string FilePath)
{
    public string Id => FilePath;

    public string Title => CourseCode;

    /// <summary>
    /// "11 August 2026 at 10:15 PM" — the moment alone, with the time,
    /// because a careful teacher may make several backups in one evening.
    /// </summary>
    public string WhenDescription =>
        BackedUpAt.ToString("d MMMM yyyy 'at' h:mm tt", CultureInfo.CurrentCulture);

    public string Subtitle => "Backed up " + WhenDescription;

    /// <summary>
    /// Reads a backup's name, which is &lt;CODE&gt;_backup_&lt;timestamp&gt;.zip.
    /// Returns null for anything else — archives and the wizard's automatic
    /// zips included.
    /// </summary>
    public static BackupItem? From(string filePath, string courseCode)
    {
        if (!filePath.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)) return null;
        string name = Path.GetFileNameWithoutExtension(filePath);
        string expectedPrefix = courseCode + "_backup_";
        if (!name.StartsWith(expectedPrefix, StringComparison.Ordinal)) return null;
        string stamp = name[expectedPrefix.Length..];
        if (!DateTime.TryParseExact(stamp, ArchivedItem.StampFormat, CultureInfo.InvariantCulture,
                                    DateTimeStyles.None, out DateTime backedUpAt))
            return null;
        return new BackupItem(courseCode, backedUpAt, filePath);
    }
}
