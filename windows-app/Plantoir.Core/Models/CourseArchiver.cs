using System.Globalization;
using System.IO.Compression;

namespace Plantoir.Core.Models;

/// <summary>
/// Removes a course or section without destroying content: zip first into
/// courses/_backups/&lt;CODE&gt;/, then delete. The archive root contains the
/// folder itself (section3/…, ICS3U/…) — the restorer depends on that.
/// </summary>
public static class CourseArchiver
{
    /// <summary>The same exclusion list the setup wizard uses for its own backups.</summary>
    public static readonly IReadOnlyList<string> ExcludedFromArchives = new[]
    {
        ".merged_output", "node_modules", ".git", ".quartz-cache", ".cache",
        "dist", "build", "out", "__pycache__", ".DS_Store",
    };

    public static string TimestampedName(string prefix, DateTime stamp) =>
        prefix + "_" + stamp.ToString(ArchivedItem.StampFormat, CultureInfo.InvariantCulture) + ".zip";

    public static string BackupsDirectory(string coursesDirectory, string courseCode) =>
        Path.Combine(coursesDirectory, "_backups", courseCode);

    /// <summary>
    /// Saves a copy of an entire course — and touches nothing: the course
    /// stays exactly where it is. Made on purpose before risky editing so
    /// there is always a way back (row 106). The name
    /// (&lt;CODE&gt;_backup_&lt;timestamp&gt;.zip) is what separates a backup from an
    /// archive in the shared _backups folder.
    /// </summary>
    public static string BackUpCourse(Course course, string coursesDirectory) =>
        Archive(course.DirectoryPath, course.Code + "_backup", coursesDirectory, course.Code);

    /// <summary>
    /// Writes an archive of an entire course folder WITHOUT removing it —
    /// for restores, which replace the course's contents in place so
    /// Obsidian's file watcher (anchored to the folder) keeps up.
    /// </summary>
    public static string ArchiveCourseWithoutRemoving(Course course, string coursesDirectory) =>
        Archive(course.DirectoryPath, course.Code, coursesDirectory, course.Code);

    /// <summary>Archive a whole course, then remove its folder.</summary>
    public static string ArchiveAndRemoveCourse(Course course, string coursesDirectory)
    {
        string archivePath = ArchiveCourseWithoutRemoving(course, coursesDirectory);
        Directory.Delete(course.DirectoryPath, recursive: true);
        return archivePath;
    }

    /// <summary>
    /// Archive one section, remove it, and take its number out of the
    /// course's settings (num_sections follows along).
    /// </summary>
    public static string ArchiveAndRemoveSection(Course course, int sectionNumber, string coursesDirectory)
    {
        string sectionDir = course.SectionDirectory(sectionNumber);
        string archivePath = Archive(sectionDir, $"{course.Code}-section{sectionNumber}",
                                     coursesDirectory, course.Code);
        if (Directory.Exists(sectionDir)) Directory.Delete(sectionDir, recursive: true);
        var remaining = course.Configuration.SectionNumbers.Where(n => n != sectionNumber).ToList();
        course.Configuration.SetSectionNumbers(remaining);
        course.Configuration.Write(course.ConfigFilePath);
        return archivePath;
    }

    private static string Archive(string folderPath, string prefix, string coursesDirectory, string courseCode)
    {
        string backupsDir = BackupsDirectory(coursesDirectory, courseCode);
        Directory.CreateDirectory(backupsDir);

        // Names are stamped to the second, and two operations can easily land
        // in the same one — an assistant publishing two classes in a row does
        // it every time. Without this the second backup throws, which (because
        // no backup means no edits) turns a routine sequence into a refusal.
        string archivePath = Path.Combine(backupsDir, TimestampedName(prefix, DateTime.Now));
        for (int attempt = 2; File.Exists(archivePath) && attempt < 100; attempt++)
            archivePath = Path.Combine(backupsDir,
                TimestampedName(prefix, DateTime.Now).Replace(".zip", $"-{attempt}.zip"));

        ZipFolder(folderPath, archivePath);
        return archivePath;
    }

    /// <summary>
    /// Zips a folder with the folder itself as the archive's root entry.
    /// The walk NEVER DESCENDS into an excluded folder — filtering paths
    /// after a full enumeration walked straight into .merged_output, where
    /// container-made links (content\Media) cannot be traversed by Windows
    /// and sank the whole backup. Reparse points are skipped for the same
    /// reason. A failure never leaves a partial zip behind.
    /// </summary>
    public static void ZipFolder(string folderPath, string archivePath)
    {
        string rootName = Path.GetFileName(folderPath.TrimEnd(Path.DirectorySeparatorChar));
        try
        {
            using var archive = ZipFile.Open(archivePath, ZipArchiveMode.Create);
            AddFolder(archive, folderPath, rootName);
        }
        catch
        {
            try { File.Delete(archivePath); } catch { }
            throw;
        }
    }

    private static void AddFolder(ZipArchive archive, string folderPath, string entryPrefix)
    {
        foreach (string file in Directory.EnumerateFiles(folderPath))
        {
            if (ExcludedFromArchives.Contains(Path.GetFileName(file))) continue;   // .DS_Store
            archive.CreateEntryFromFile(file, entryPrefix + "/" + Path.GetFileName(file),
                                        CompressionLevel.Optimal);
        }
        foreach (string sub in Directory.EnumerateDirectories(folderPath))
        {
            string name = Path.GetFileName(sub);
            if (ExcludedFromArchives.Contains(name)) continue;
            if ((new DirectoryInfo(sub).Attributes & FileAttributes.ReparsePoint) != 0) continue;
            AddFolder(archive, sub, entryPrefix + "/" + name);
        }
    }
}
