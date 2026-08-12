using System.Text;
using Plantoir.Core.Models;
using Xunit;

namespace Plantoir.Tests;

public class PreviewLeaseTests : IDisposable
{
    public PreviewLeaseTests() => PreviewLeases.Reset();
    public void Dispose() => PreviewLeases.Reset();

    [Fact]
    public void SameSectionSameFolderIsRefused()
    {
        PreviewLeases.Take(@"C:\folder", "ICS3U", 1);
        var refusal = Assert.Throws<PreviewLeases.LeaseRefusedException>(
            () => PreviewLeases.Take(@"C:\folder", "ICS3U", 1));
        Assert.Equal("Section 1 of ICS3U is already being previewed in another window. Stop that preview first, or work with it there.",
            refusal.Message);
    }

    [Fact]
    public void SameSectionDifferentFolderIsAllowed()
    {
        PreviewLeases.Take(@"C:\folderA", "ICS3U", 1);
        var lease = PreviewLeases.Take(@"C:\folderB", "ICS3U", 1);
        Assert.Equal(8081, lease.Port);   // ports contend per folder only
    }

    [Fact]
    public void FifthPreviewOfAFolderIsRefusedPolitely()
    {
        for (int i = 1; i <= 4; i++) PreviewLeases.Take(@"C:\folder", "ICS3U", i);
        var refusal = Assert.Throws<PreviewLeases.LeaseRefusedException>(
            () => PreviewLeases.Take(@"C:\folder", "ICS3U", 5));
        Assert.Equal("Four previews of this folder are already running, which is the most that can run at once. Stop one, then try again.",
            refusal.Message);
    }

    [Fact]
    public void ReleaseFreesThePort()
    {
        var lease = PreviewLeases.Take(@"C:\folder", "ICS3U", 1);
        PreviewLeases.Release(lease);
        var again = PreviewLeases.Take(@"C:\folder", "ICS3U", 1);
        Assert.Equal(8081, again.Port);
    }
}

public class ArchivedItemTests
{
    [Fact]
    public void CourseArchiveParses()
    {
        var item = ArchivedItem.From(@"C:\b\ICS3U_2026-08-09_141530.zip", "ICS3U")!;
        Assert.Null(item.SectionNumber);
        Assert.Equal("ICS3U", item.Title);
        Assert.Equal(new DateTime(2026, 8, 9, 14, 15, 30), item.ArchivedAt);
    }

    [Fact]
    public void SectionArchiveParses()
    {
        var item = ArchivedItem.From(@"C:\b\ICS3U-section3_2026-08-09_141530.zip", "ICS3U")!;
        Assert.Equal(3, item.SectionNumber);
        Assert.Equal("ICS3U — Section 3", item.Title);
    }

    [Fact]
    public void WizardTimestampBackupsAreNotArchives() =>
        Assert.Null(ArchivedItem.From(@"C:\b\2026-08-09_141530.zip", "ICS3U"));

    [Fact]
    public void ForeignAndMalformedNamesAreIgnored()
    {
        Assert.Null(ArchivedItem.From(@"C:\b\OTHER_2026-08-09_141530.zip", "ICS3U"));
        Assert.Null(ArchivedItem.From(@"C:\b\ICS3U_notadate.zip", "ICS3U"));
        Assert.Null(ArchivedItem.From(@"C:\b\ICS3U-section3_2026-08-09_141530.txt", "ICS3U"));
        Assert.Null(ArchivedItem.From(@"C:\b\noseparator.zip", "ICS3U"));
    }
}

public class SectionAdderTests
{
    [Theory]
    [InlineData("ICS3U", "Grade 11")]
    [InlineData("SNC1W", "Grade 9")]
    [InlineData("MHF4U", "Grade 12")]
    [InlineData("ABC5X", "Grade ?")]
    [InlineData("CODING", "")]
    [InlineData("ART", "")]
    public void GradeLabelsComeFromTheFourthCharacter(string code, string label) =>
        Assert.Equal(label, SectionAdder.GradeLabel(code));

    [Fact]
    public void SuggestedNumberIsTheSmallestGap()
    {
        Assert.Equal(2, SectionAdder.SuggestedNumber(new[] { 1, 3 }));
        Assert.Equal(1, SectionAdder.SuggestedNumber(Array.Empty<int>()));
        Assert.Equal(4, SectionAdder.SuggestedNumber(new[] { 1, 2, 3 }));
    }

    [Fact]
    public void EntryProblemsMatchTheHouseWording()
    {
        Assert.Null(SectionAdder.EntryProblem("", new[] { 1 }, "ICS3U"));
        Assert.Equal("“2a” isn’t a section number — sections are 1 or higher.",
            SectionAdder.EntryProblem("2a", new[] { 1 }, "ICS3U"));
        Assert.Equal("“0” isn’t a section number — sections are 1 or higher.",
            SectionAdder.EntryProblem("0", new[] { 1 }, "ICS3U"));
        Assert.Equal("Section 1 of ICS3U already exists.",
            SectionAdder.EntryProblem("1", new[] { 1 }, "ICS3U"));
        Assert.Null(SectionAdder.EntryProblem("2", new[] { 1 }, "ICS3U"));
    }

    [Fact]
    public void TimestampUsesColonFreeOffset()
    {
        string stamp = SectionAdder.Timestamp(new DateTimeOffset(2026, 8, 10, 14, 30, 0, TimeSpan.FromHours(-4)));
        Assert.Equal("2026-08-10T14:30:00.000-0400", stamp);
    }

    [Fact]
    public void ScaffoldingMirrorsTheLowestSibling()
    {
        string root = Path.Combine(Path.GetTempPath(), "adder-" + Guid.NewGuid());
        try
        {
            var course = MakeCourse(root, "ICS3U", """
                {"course_code":"ICS3U","course_name":"Computer Science","section_numbers":[2],
                 "per_section_folders":["All Classes"],"per_section_files":["Private Notes.md","Key Links.md"]}
                """);
            string section2 = Path.Combine(course.DirectoryPath, "section2");
            Directory.CreateDirectory(Path.Combine(section2, "All Classes"));
            File.WriteAllText(Path.Combine(section2, "index.md"),
                "---\ntitle: My Special Wording, Section 2\ncreated: 2025-01-01T00:00:00.000-0500\nenableToc: false\n---");
            File.WriteAllText(Path.Combine(section2, "Private Notes.md"),
                "---\ntitle: Private Notes\ncreated: 2025-01-01T00:00:00.000-0500\ndraft: true\n---\nbody");
            File.WriteAllText(Path.Combine(section2, "All Classes", "index.md"),
                "---\ntitle: All Classes\ncreated: 2025-01-01T00:00:00.000-0500\n---\nbody");

            SectionAdder.AddSection(1, course);

            string index = File.ReadAllText(Path.Combine(course.DirectoryPath, "section1", "index.md"));
            Assert.Contains("title: My Special Wording, Section 1", index);   // teacher's wording kept, renumbered
            Assert.Contains("enableToc: false", index);                        // flags carried over
            Assert.DoesNotContain("2025-01-01", index);                        // created freshened

            string notes = File.ReadAllText(Path.Combine(course.DirectoryPath, "section1", "Private Notes.md"));
            Assert.Contains("draft: true", notes);                             // sibling's draft flag carried

            Assert.Equal(new[] { 1, 2 }, CourseConfiguration.Load(course.ConfigFilePath).SectionNumbers);
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    [Fact]
    public void FallbackTemplateMakesTeacherPagesDrafts()
    {
        string root = Path.Combine(Path.GetTempPath(), "adder-" + Guid.NewGuid());
        try
        {
            var course = MakeCourse(root, "SNC1W", """
                {"course_code":"SNC1W","course_name":"Science","section_numbers":[],
                 "per_section_files":["Private Notes.md","Key Links.md"]}
                """);
            SectionAdder.AddSection(1, course);
            Assert.Contains("draft: true", File.ReadAllText(Path.Combine(course.DirectoryPath, "section1", "Private Notes.md")));
            Assert.Contains("draft: false", File.ReadAllText(Path.Combine(course.DirectoryPath, "section1", "Key Links.md")));
            Assert.Contains("title: Grade 9 Science, Section 1",
                File.ReadAllText(Path.Combine(course.DirectoryPath, "section1", "index.md")));
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    [Fact]
    public void RefusalsProtectExistingWork()
    {
        string root = Path.Combine(Path.GetTempPath(), "adder-" + Guid.NewGuid());
        try
        {
            var course = MakeCourse(root, "ICS3U", """{"course_code":"ICS3U","section_numbers":[1]}""");
            var listed = Assert.Throws<SectionAdder.SectionAddException>(() => SectionAdder.AddSection(1, course));
            Assert.Equal("Section 1 of ICS3U already exists.", listed.Message);

            Directory.CreateDirectory(Path.Combine(course.DirectoryPath, "section3"));
            var inTheWay = Assert.Throws<SectionAdder.SectionAddException>(() => SectionAdder.AddSection(3, course));
            Assert.Contains("Move it aside first — it may hold work you want to keep.", inTheWay.Message);
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    internal static Course MakeCourse(string root, string code, string configJson)
    {
        string courseDir = Path.Combine(root, "courses", code);
        Directory.CreateDirectory(courseDir);
        File.WriteAllText(Path.Combine(courseDir, "course_config.json"), configJson);
        var config = CourseConfiguration.FromBytes(Encoding.UTF8.GetBytes(configJson));
        return new Course(code, courseDir, config);
    }
}

public class ArchiveRoundTripTests
{
    [Fact]
    public void SectionArchiveRoundTripsAndKeepsBookkeeping()
    {
        string root = Path.Combine(Path.GetTempPath(), "arch-" + Guid.NewGuid());
        try
        {
            string coursesDir = Path.Combine(root, "courses");
            var course = SectionAdderTests.MakeCourse(root, "ICS3U",
                """{"course_code":"ICS3U","course_name":"CS","section_numbers":[1,2]}""");
            string section2 = Path.Combine(course.DirectoryPath, "section2");
            Directory.CreateDirectory(Path.Combine(section2, ".merged_output", "junk"));
            File.WriteAllText(Path.Combine(section2, ".merged_output", "junk", "big.html"), "generated");
            File.WriteAllText(Path.Combine(section2, "index.md"), "---\ntitle: T\n---");

            string archivePath = CourseArchiver.ArchiveAndRemoveSection(course, 2, coursesDir);

            Assert.False(Directory.Exists(section2));
            Assert.Equal(new[] { 1 }, CourseConfiguration.Load(course.ConfigFilePath).SectionNumbers);
            var item = ArchivedItem.From(archivePath, "ICS3U")!;
            Assert.Equal(2, item.SectionNumber);

            // Restore refuses while the course is missing from the list, then succeeds.
            var missing = Assert.Throws<CourseRestorer.RestoreException>(
                () => CourseRestorer.Restore(item, coursesDir, Array.Empty<Course>()));
            Assert.Contains("Restore the course first", missing.Message);

            CourseRestorer.Restore(item, coursesDir, new[] { course });
            Assert.True(File.Exists(Path.Combine(section2, "index.md")));
            Assert.False(Directory.Exists(Path.Combine(section2, ".merged_output")));   // excluded from the zip
            Assert.Equal(new[] { 1, 2 }, CourseConfiguration.Load(course.ConfigFilePath).SectionNumbers);
            Assert.False(File.Exists(archivePath));   // restored = no longer archived
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    [Fact]
    public void RestoreNeverOverwrites()
    {
        string root = Path.Combine(Path.GetTempPath(), "arch-" + Guid.NewGuid());
        try
        {
            string coursesDir = Path.Combine(root, "courses");
            var course = SectionAdderTests.MakeCourse(root, "ICS3U",
                """{"course_code":"ICS3U","section_numbers":[1]}""");
            string section1 = Path.Combine(course.DirectoryPath, "section1");
            Directory.CreateDirectory(section1);
            File.WriteAllText(Path.Combine(section1, "index.md"), "---\ntitle: T\n---");

            string zipPath = Path.Combine(CourseArchiver.BackupsDirectory(coursesDir, "ICS3U"),
                CourseArchiver.TimestampedName("ICS3U-section1", DateTime.Now));
            Directory.CreateDirectory(Path.GetDirectoryName(zipPath)!);
            CourseArchiver.ZipFolder(section1, zipPath);
            var item = ArchivedItem.From(zipPath, "ICS3U")!;

            var refusal = Assert.Throws<CourseRestorer.RestoreException>(
                () => CourseRestorer.Restore(item, coursesDir, new[] { course }));
            Assert.Equal("Section 1 of ICS3U already exists. Remove it first if you want the archived copy back.", refusal.Message);
            Assert.True(File.Exists(zipPath));   // refusal leaves the archive alone
        }
        finally { Directory.Delete(root, recursive: true); }
    }
}

/// <summary>
/// The cross-window busy registry gating Add Section (row 104). Folder paths
/// are unique per test so the static registry never crosses wires with the
/// lease tests.
/// </summary>
public class CourseActivityTests
{
    private static string Folder() => @"C:\activity-" + Guid.NewGuid().ToString("N");

    [Fact]
    public void PublishesAreScopedToTheirCourseAndFolder()
    {
        string folder = Folder(), other = Folder();
        using var publish = CourseActivity.BeginPublish(folder, "ICS3U", 1);
        Assert.True(CourseActivity.IsPublishing(folder, "ICS3U"));
        Assert.False(CourseActivity.IsPublishing(folder, "ICS4U"));
        Assert.False(CourseActivity.IsPublishing(other, "ICS3U"));   // same code, other folder = other course
    }

    [Fact]
    public void TwoPublishesOfOneCourseEndIndependently()
    {
        string folder = Folder();
        var first = CourseActivity.BeginPublish(folder, "ICS3U", 1);
        var second = CourseActivity.BeginPublish(folder, "ICS3U", 3);
        first.Dispose();
        Assert.True(CourseActivity.IsPublishing(folder, "ICS3U"));   // section 3 still going
        second.Dispose();
        Assert.False(CourseActivity.IsPublishing(folder, "ICS3U"));
        second.Dispose();   // double-dispose is harmless
        Assert.False(CourseActivity.IsPublishing(folder, "ICS3U"));
    }

    [Fact]
    public void BusyReasonNamesWhatStandsInTheWay()
    {
        string folder = Folder();
        Assert.Null(CourseActivity.BusyReason(folder, "ICS3U"));

        var publish = CourseActivity.BeginPublish(folder, "ICS3U", 1);
        Assert.Equal("Available once publish completed", CourseActivity.BusyReason(folder, "ICS3U"));

        var lease = PreviewLeases.Take(folder, "ICS3U", 2);
        Assert.Equal("Available once preview and publish complete", CourseActivity.BusyReason(folder, "ICS3U"));

        publish.Dispose();
        Assert.Equal("Available once preview completed", CourseActivity.BusyReason(folder, "ICS3U"));

        PreviewLeases.Release(lease);
        Assert.Null(CourseActivity.BusyReason(folder, "ICS3U"));
    }

    [Fact]
    public void PreviewsCountThroughTheirLeases()
    {
        string folder = Folder();
        var lease = PreviewLeases.Take(folder, "MCV4U", 1);
        Assert.True(CourseActivity.IsPreviewing(folder, "MCV4U"));
        Assert.False(CourseActivity.IsPreviewing(folder, "ICS3U"));
        PreviewLeases.Release(lease);
        Assert.False(CourseActivity.IsPreviewing(folder, "MCV4U"));
    }
}

public class BuildFreshnessTests
{
    [Fact]
    public void NeverBuiltNeedsRebuild()
    {
        string root = Path.Combine(Path.GetTempPath(), "fresh-" + Guid.NewGuid());
        try
        {
            var course = SectionAdderTests.MakeCourse(root, "ICS3U", """{"course_code":"ICS3U"}""");
            Assert.True(BuildFreshness.NeedsRebuild(course, 1));
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    [Fact]
    public void FreshBuildDoesNotRebuildUntilContentChanges()
    {
        string root = Path.Combine(Path.GetTempPath(), "fresh-" + Guid.NewGuid());
        try
        {
            var course = SectionAdderTests.MakeCourse(root, "ICS3U", """{"course_code":"ICS3U"}""");
            string publicDir = Path.Combine(course.DirectoryPath, ".merged_output", "section1", "public");
            Directory.CreateDirectory(publicDir);
            string content = Path.Combine(course.DirectoryPath, "section1");
            Directory.CreateDirectory(content);
            File.WriteAllText(Path.Combine(content, "index.md"), "x");
            File.WriteAllText(Path.Combine(publicDir, "index.html"), "built");
            File.SetLastWriteTimeUtc(Path.Combine(publicDir, "index.html"), DateTime.UtcNow.AddMinutes(5));
            Assert.False(BuildFreshness.NeedsRebuild(course, 1));

            File.SetLastWriteTimeUtc(Path.Combine(content, "index.md"), DateTime.UtcNow.AddMinutes(10));
            Assert.True(BuildFreshness.NeedsRebuild(course, 1));
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    [Fact]
    public void HiddenEntriesNeverTriggerRebuilds()
    {
        string root = Path.Combine(Path.GetTempPath(), "fresh-" + Guid.NewGuid());
        try
        {
            var course = SectionAdderTests.MakeCourse(root, "ICS3U", """{"course_code":"ICS3U"}""");
            string publicDir = Path.Combine(course.DirectoryPath, ".merged_output", "section1", "public");
            Directory.CreateDirectory(publicDir);
            File.WriteAllText(Path.Combine(publicDir, "index.html"), "built");
            File.SetLastWriteTimeUtc(Path.Combine(publicDir, "index.html"), DateTime.UtcNow.AddMinutes(5));

            string obsidian = Path.Combine(course.DirectoryPath, ".obsidian");
            Directory.CreateDirectory(obsidian);
            File.WriteAllText(Path.Combine(obsidian, "workspace.json"), "{}");
            File.SetLastWriteTimeUtc(Path.Combine(obsidian, "workspace.json"), DateTime.UtcNow.AddMinutes(30));

            Assert.False(BuildFreshness.NeedsRebuild(course, 1));
        }
        finally { Directory.Delete(root, recursive: true); }
    }

    [Fact]
    public void APreviewBuildIsNeverDeployFresh()
    {
        // Serve mode bakes a live-reload client into every page; deploying it
        // makes the public site knock on ws://localhost and browsers prompt.
        string root = Path.Combine(Path.GetTempPath(), "fresh-" + Guid.NewGuid());
        try
        {
            var course = SectionAdderTests.MakeCourse(root, "ICS3U", """{"course_code":"ICS3U"}""");
            string publicDir = Path.Combine(course.DirectoryPath, ".merged_output", "section1", "public");
            Directory.CreateDirectory(publicDir);
            string index = Path.Combine(publicDir, "index.html");
            File.WriteAllText(index,
                "<script>const socket = new WebSocket('ws://localhost:9081')</script>");
            File.SetLastWriteTimeUtc(index, DateTime.UtcNow.AddMinutes(5));

            Assert.True(BuildFreshness.BuiltForPreview(index));
            Assert.True(BuildFreshness.NeedsRebuild(course, 1));

            File.WriteAllText(index, "a clean production page");
            File.SetLastWriteTimeUtc(index, DateTime.UtcNow.AddMinutes(5));
            Assert.False(BuildFreshness.BuiltForPreview(index));
            Assert.False(BuildFreshness.NeedsRebuild(course, 1));
        }
        finally { Directory.Delete(root, recursive: true); }
    }
}

public class FolderContainerTests
{
    [Fact]
    public void ContainerNameMatchesTheLauncherDerivation()
    {
        // The launcher hashes the physical path (true casing) + "\n"; the app
        // must agree even when handed a differently-cased path.
        string dir = Path.Combine(Path.GetTempPath(), "MixedCase-" + Guid.NewGuid());
        Directory.CreateDirectory(dir);
        try
        {
            string physical = FolderContainers.PhysicalPath(dir.ToLowerInvariant());
            byte[] hash = System.Security.Cryptography.SHA256.HashData(Encoding.UTF8.GetBytes(physical + "\n"));
            string expected = "teaching-quartz-" + Convert.ToHexString(hash).ToLowerInvariant()[..8];

            Assert.Equal(expected, FolderContainers.ContainerName(dir.ToLowerInvariant()));
            Assert.Equal(expected, FolderContainers.ContainerName(dir.ToUpperInvariant()));
            Assert.Equal(expected, FolderContainers.ContainerName(dir));
            Assert.StartsWith("teaching-quartz-", expected);
            Assert.Equal("teaching-quartz-".Length + 8, expected.Length);
        }
        finally { Directory.Delete(dir); }
    }

    [Fact]
    public void QuitReleaseStopsContainersThenChecksForIdle()
    {
        var recorded = new List<string[]>();
        FolderContainers.CommandRunnerOverride = recorded.Add;
        try
        {
            FolderContainers.ReleaseEverythingAtQuit(new[] { @"C:\Windows", @"C:\Windows" });
            var command = Assert.Single(recorded);
            string joined = string.Join(" ", command);
            Assert.Contains("docker stop -t 2 teaching-quartz-", joined);
            Assert.Contains("docker ps -q", joined);          // the emptiness check
            Assert.Contains("wsl --terminate", joined);       // only fires when idle
            // De-duplicated: one container name, mentioned once.
            int count = joined.Split("teaching-quartz-").Length - 1;
            Assert.Equal(1, count);
        }
        finally { FolderContainers.CommandRunnerOverride = null; }
    }
}
