using System.Globalization;

namespace Plantoir.Core.Models;

/// <summary>
/// Scaffolds a brand-new section for an existing course, imitating a sibling
/// section where one exists so a page the siblings keep unpublished starts
/// unpublished here too.
/// </summary>
public static class SectionAdder
{
    /// <summary>Teacher-eyes-only pages: created unpublished, never in the site.</summary>
    public static readonly IReadOnlySet<string> UnpublishedFileNames =
        new HashSet<string> { "Private Notes.md", "Scratch Page.md" };

    public sealed class SectionAddException(string message) : Exception(message);

    public static void AddSection(int number, Course course)
    {
        var config = course.Configuration;
        if (config.SectionNumbers.Contains(number))
            throw new SectionAddException($"Section {number} of {course.Code} already exists.");
        string sectionDir = course.SectionDirectory(number);
        if (Directory.Exists(sectionDir))
            throw new SectionAddException(
                $"A folder for section {number} of {course.Code} is already on disk. Move it aside first — it may hold work you want to keep.");

        string created = Timestamp(DateTimeOffset.Now);
        Directory.CreateDirectory(sectionDir);

        // index.md — frontmatter only, title recomputed for this section.
        string indexFrontmatter = ScaffoldFrontmatter(
            SiblingFile("index.md", course),
            newTitle: SectionTitle(course, number),
            fallbackTitle: null, fallbackIsDraft: false, created: created);
        File.WriteAllText(Path.Combine(sectionDir, "index.md"), $"---\n{indexFrontmatter}\n---");

        foreach (string folder in config.PerSectionFolders)
        {
            string folderPath = Path.Combine(sectionDir, folder);
            Directory.CreateDirectory(folderPath);
            string fm = ScaffoldFrontmatter(
                SiblingFile(folder + "/index.md", course),
                newTitle: null, fallbackTitle: folder, fallbackIsDraft: false, created: created);
            File.WriteAllText(Path.Combine(folderPath, "index.md"),
                $"---\n{fm}\n---\nThis is the **{folder}** folder. Add Markdown files to this folder to build out your site.");
        }

        foreach (string fileName in config.PerSectionFiles)
        {
            string fm = ScaffoldFrontmatter(
                SiblingFile(fileName, course),
                newTitle: null,
                fallbackTitle: fileName.Replace(".md", ""),
                fallbackIsDraft: UnpublishedFileNames.Contains(fileName),
                created: created);
            File.WriteAllText(Path.Combine(sectionDir, fileName),
                $"---\n{fm}\n---\nThis is the per-section file **{fileName}**.");
        }

        // Only after the folder is safely written does the config learn about
        // it — a mid-way failure never leaves settings pointing at nothing.
        var numbers = config.SectionNumbers;
        numbers.Add(number);
        numbers.Sort();
        config.SetSectionNumbers(numbers);
        config.Write(course.ConfigFilePath);
    }

    /// <summary>The first existing copy among ascending section numbers — deterministic.</summary>
    internal static string? SiblingFile(string relativePath, Course course)
    {
        foreach (int n in course.Configuration.SectionNumbers.OrderBy(n => n))
        {
            string candidate = Path.Combine(course.SectionDirectory(n),
                relativePath.Replace('/', Path.DirectorySeparatorChar));
            if (File.Exists(candidate)) return candidate;
        }
        return null;
    }

    /// <summary>
    /// Lines between an opening "---" (which must be line 1, exactly) and the
    /// closing "---". No closing marker → null.
    /// </summary>
    internal static List<string>? FrontmatterLines(string path)
    {
        string text;
        try { text = File.ReadAllText(path); } catch { return null; }
        var lines = text.Split('\n');
        if (lines.Length == 0 || lines[0].TrimEnd('\r') != "---") return null;
        var collected = new List<string>();
        for (int i = 1; i < lines.Length; i++)
        {
            if (lines[i].TrimEnd('\r') == "---") return collected;
            collected.Add(lines[i].TrimEnd('\r'));
        }
        return null;
    }

    /// <summary>
    /// A sibling's frontmatter carried over whole, with only the created date
    /// freshened and (for index.md) the title replaced.
    /// </summary>
    internal static string ScaffoldFrontmatter(string? siblingPath, string? newTitle,
                                               string? fallbackTitle, bool fallbackIsDraft, string created)
    {
        var siblingLines = siblingPath is null ? null : FrontmatterLines(siblingPath);
        if (siblingLines is not null)
        {
            var rewritten = siblingLines.Select(line =>
            {
                if (line.StartsWith("created:", StringComparison.Ordinal)) return "created: " + created;
                if (line.StartsWith("title:", StringComparison.Ordinal) && newTitle is not null) return "title: " + newTitle;
                return line;
            });
            return string.Join("\n", rewritten);
        }
        // The publish key, not the legacy draft one, and note the polarity is
        // INVERTED: a teacher-eyes-only page is `publish: false`. Missing this
        // would have quietly born every new section in the old schema — the
        // same gap that setup_course.py had, in the other creation path.
        //
        // Only the fallback writes this. When there is a sibling section its
        // frontmatter is copied verbatim, which is what a course still using
        // `draft:` wants: the new section matches its siblings rather than
        // becoming the one page in the course with a different vocabulary.
        string title = newTitle ?? fallbackTitle ?? "";
        return $"title: {title}\ncreated: {created}\npublish: {(fallbackIsDraft ? "false" : "true")}";
    }

    /// <summary>
    /// Prefer the sibling's own title with its trailing "Section N" renumbered
    /// (preserving the teacher's wording); otherwise the wizard's form. The
    /// grade prefix is LITERAL — the switch alone decides.
    /// </summary>
    public static string SectionTitle(Course course, int sectionNumber)
    {
        string? sibling = SiblingFile("index.md", course);
        if (sibling is not null && FrontmatterLines(sibling) is { } lines)
        {
            foreach (string line in lines)
            {
                if (!line.StartsWith("title:", StringComparison.Ordinal)) continue;
                string value = line["title:".Length..].Trim();
                var match = System.Text.RegularExpressions.Regex.Match(value, @"Section \d+$");
                if (match.Success)
                    return value[..match.Index] + "Section " + sectionNumber;
                break;
            }
        }
        string gradeLabel = GradeLabel(course.Code);
        bool showsGrade = course.Configuration.ShowsGradeInTitle(sectionNumber);
        string prefix = showsGrade && gradeLabel.Length > 0 ? gradeLabel + " " : "";
        return $"{prefix}{course.Configuration.CourseName}, Section {sectionNumber}";
    }

    /// <summary>The 4th character of an Ontario course code carries its grade.</summary>
    public static string GradeLabel(string courseCode)
    {
        if (courseCode.Length < 4) return "";
        char c = courseCode[3];
        if (!char.IsDigit(c)) return "";
        return c switch
        {
            '1' => "Grade 9",
            '2' => "Grade 10",
            '3' => "Grade 11",
            '4' => "Grade 12",
            _ => "Grade ?",
        };
    }

    /// <summary>Wizard-style created stamp: 2026-08-10T14:30:00.000-0400 (offset without colon).</summary>
    public static string Timestamp(DateTimeOffset date)
    {
        string body = date.ToString("yyyy-MM-dd'T'HH:mm:ss.'000'", CultureInfo.InvariantCulture);
        string offset = date.ToString("zzz", CultureInfo.InvariantCulture).Replace(":", "");
        return body + offset;
    }

    /// <summary>The smallest positive number not already in use.</summary>
    public static int SuggestedNumber(IReadOnlyCollection<int> existing)
    {
        int candidate = 1;
        while (existing.Contains(candidate)) candidate++;
        return candidate;
    }

    /// <summary>Live validation for the Add Section sheet. Empty entry → no warning yet.</summary>
    public static string? EntryProblem(string entry, IReadOnlyCollection<int> existing, string courseCode)
    {
        string trimmed = entry.Trim();
        if (trimmed.Length == 0) return null;
        if (!int.TryParse(trimmed, out int number) || number < 1)
            return $"“{trimmed}” isn’t a section number — sections are 1 or higher.";
        if (existing.Contains(number))
            return $"Section {number} of {courseCode} already exists.";
        return null;
    }

    public static bool EntryIsAddable(string entry, IReadOnlyCollection<int> existing) =>
        int.TryParse(entry.Trim(), out int number) && number >= 1 && !existing.Contains(number);
}
