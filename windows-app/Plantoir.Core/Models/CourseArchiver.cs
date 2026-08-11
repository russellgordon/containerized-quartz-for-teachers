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

    /// <summary>Archive a whole course, then remove its folder.</summary>
    public static string ArchiveAndRemoveCourse(Course course, string coursesDirectory)
    {
        string archivePath = Archive(course.DirectoryPath, course.Code, coursesDirectory, course.Code);
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
        string archivePath = Path.Combine(backupsDir, TimestampedName(prefix, DateTime.Now));
        ZipFolder(folderPath, archivePath);
        return archivePath;
    }

    /// <summary>
    /// Zips a folder with the folder itself as the archive's root entry,
    /// skipping any path that contains an excluded component.
    /// </summary>
    public static void ZipFolder(string folderPath, string archivePath)
    {
        string rootName = Path.GetFileName(folderPath.TrimEnd(Path.DirectorySeparatorChar));
        using var archive = ZipFile.Open(archivePath, ZipArchiveMode.Create);
        foreach (string file in Directory.EnumerateFiles(folderPath, "*", SearchOption.AllDirectories))
        {
            string relative = Path.GetRelativePath(folderPath, file);
            if (relative.Split(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar)
                        .Any(part => ExcludedFromArchives.Contains(part)))
                continue;
            string entryName = rootName + "/" + relative.Replace('\\', '/');
            archive.CreateEntryFromFile(file, entryName, CompressionLevel.Optimal);
        }
    }
}
