using System.IO.Compression;

namespace Plantoir.Core.Models;

/// <summary>
/// Brings an archived course or section back. Nothing is ever written over —
/// what is in the way may be newer work, so the restore refuses and explains.
/// </summary>
public static class CourseRestorer
{
    public sealed class RestoreException(string message) : Exception(message);

    public static void Restore(ArchivedItem item, string coursesDirectory, IReadOnlyList<Course> courses)
    {
        if (item.SectionNumber is int section)
        {
            Course? course = courses.FirstOrDefault(c => c.Code == item.CourseCode);
            if (course is null)
                throw new RestoreException(
                    $"{item.CourseCode} is not in Courses & Clubs. Restore the course first, then restore this section into it.");
            string sectionDir = course.SectionDirectory(section);
            if (Directory.Exists(sectionDir))
                throw new RestoreException(
                    $"Section {section} of {item.CourseCode} already exists. Remove it first if you want the archived copy back.");
            Extract(item.FilePath, "section" + section, course.DirectoryPath);
            PutSectionBack(course, section);
        }
        else
        {
            string courseDir = Path.Combine(coursesDirectory, item.CourseCode);
            if (Directory.Exists(courseDir))
                throw new RestoreException(
                    $"{item.CourseCode} is already in Courses & Clubs. Remove it first if you want the archived copy back.");
            Extract(item.FilePath, item.CourseCode, coursesDirectory);
        }
        // A restored thing is no longer archived (failure to delete is not fatal).
        try { File.Delete(item.FilePath); } catch { }
    }

    /// <summary>Archiving took the number out; restoring must put it back.</summary>
    private static void PutSectionBack(Course course, int section)
    {
        var numbers = course.Configuration.SectionNumbers;
        if (!numbers.Contains(section)) numbers.Add(section);
        numbers.Sort();
        course.Configuration.SetSectionNumbers(numbers);
        course.Configuration.Write(course.ConfigFilePath);
    }

    /// <summary>
    /// Extract expecting the named folder at the archive root; when it is
    /// absent but the archive holds exactly one folder, use that one (so
    /// archives made by another version still restore).
    /// </summary>
    private static void Extract(string archivePath, string expectedName, string destinationParent)
    {
        string staging = Path.Combine(Path.GetTempPath(), "restore-" + Guid.NewGuid());
        Directory.CreateDirectory(staging);
        try
        {
            try { ZipFile.ExtractToDirectory(archivePath, staging); }
            catch (Exception error)
            {
                throw new RestoreException($"The archive could not be opened: {error.Message}");
            }

            string payload = Path.Combine(staging, expectedName);
            if (!Directory.Exists(payload))
            {
                var entries = Directory.EnumerateFileSystemEntries(staging)
                    .Where(e => !Path.GetFileName(e).StartsWith('.'))
                    .ToList();
                if (entries.Count == 1) payload = entries[0];
                else throw new RestoreException($"The archive could not be opened: it does not contain {expectedName}");
            }

            Directory.CreateDirectory(destinationParent);
            Directory.Move(payload, Path.Combine(destinationParent, expectedName));
        }
        finally
        {
            try { Directory.Delete(staging, recursive: true); } catch { }
        }
    }
}
