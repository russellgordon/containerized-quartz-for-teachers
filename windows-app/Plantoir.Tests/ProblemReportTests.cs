using System;
using System.IO;
using System.IO.Compression;
using System.Linq;
using Plantoir.Core.Scripting;
using Xunit;

namespace Plantoir.Tests;

public class ProblemReportTests
{
    [Fact]
    public void Constants_MatchContract()
    {
        var doc = ContractLoader.LoadJson("shared-rules.json");
        var dialog = doc["problemReportDialog"]!.AsObject();

        Assert.Equal(dialog["supportEmail"]!.ToString(), ProblemReportBuilder.SupportEmail);
        Assert.Equal(dialog["includePromptsLabel"]!.ToString(), ProblemReportBuilder.IncludePromptsLabel);
    }

    [Fact]
    public void StampAndFileNames_FollowFormat()
    {
        var date = new DateTime(2026, 8, 16, 15, 50, 22);
        Assert.Equal("2026-08-16 at 15.50.22", ProblemReportBuilder.Stamp(date));
        Assert.Equal("Plantoir problem report 2026-08-16 at 15.50.22", ProblemReportBuilder.StampedFolderName(date));
        Assert.Equal("Plantoir problem report 2026-08-16 at 15.50.22.zip", ProblemReportBuilder.SuggestedFileName(date));
    }

    [Fact]
    public void TaskCountPhrase_FormatsCorrectly()
    {
        Assert.Equal("the last task Plantoir ran for you", ProblemReportBuilder.TaskCountPhrase(1));
        Assert.Equal("the last 5 tasks Plantoir ran for you", ProblemReportBuilder.TaskCountPhrase(5));
    }

    [Fact]
    public void PromptState_MatchesLogic()
    {
        Assert.Equal(ProblemReportBuilder.AssistantPrompts.None, ProblemReportBuilder.PromptState(hasAny: false, including: false));
        Assert.Equal(ProblemReportBuilder.AssistantPrompts.None, ProblemReportBuilder.PromptState(hasAny: false, including: true));
        Assert.Equal(ProblemReportBuilder.AssistantPrompts.Excluded, ProblemReportBuilder.PromptState(hasAny: true, including: false));
        Assert.Equal(ProblemReportBuilder.AssistantPrompts.Included, ProblemReportBuilder.PromptState(hasAny: true, including: true));
    }

    [Fact]
    public void AboutText_RespectsPromptStates()
    {
        var now = new DateTime(2026, 8, 16, 15, 50, 22);

        string none = ProblemReportBuilder.About(3, ProblemReportBuilder.AssistantPrompts.None, now);
        Assert.DoesNotContain("what you typed to the local AI assistant", none);

        string excluded = ProblemReportBuilder.About(3, ProblemReportBuilder.AssistantPrompts.Excluded, now);
        Assert.Contains("NOT IN THIS REPORT", excluded);
        Assert.Contains("  · what you typed to the local AI assistant", excluded);

        string included = ProblemReportBuilder.About(3, ProblemReportBuilder.AssistantPrompts.Included, now);
        Assert.Contains("IN THIS REPORT", included);
        Assert.Contains("  · what you typed to the local AI assistant, because you asked for it", included);
    }

    [Fact]
    public void Store_FiltersPromptsAndDetectsContent()
    {
        string tempDir = Path.Combine(Path.GetTempPath(), "PlantoirProblemStoreTest-" + Guid.NewGuid());
        Directory.CreateDirectory(tempDir);
        try
        {
            var store = new ProblemReportStore(tempDir);
            Assert.False(store.HasAnythingToReport);
            Assert.False(store.HasAssistantPrompts);

            string activityFile = Path.Combine(tempDir, "activity.txt");
            File.WriteAllText(activityFile, "2026-08-16 15:00:00 · opened\n  asked: publish ICS3U\n2026-08-16 15:00:05 · done\n");

            Assert.True(store.HasAnythingToReport);
            Assert.True(store.HasAssistantPrompts);

            string withPrompts = store.ActivityText(includingPrompts: true);
            Assert.Contains("  asked: publish ICS3U", withPrompts);

            string withoutPrompts = store.ActivityText(includingPrompts: false);
            Assert.DoesNotContain("  asked: publish ICS3U", withoutPrompts);
            Assert.Contains("2026-08-16 15:00:00 · opened", withoutPrompts);
            Assert.Contains("2026-08-16 15:00:05 · done", withoutPrompts);
        }
        finally
        {
            try { Directory.Delete(tempDir, recursive: true); } catch { }
        }
    }

    [Fact]
    public void Builder_BuildsZipWithTasksAndActivity()
    {
        string tempDir = Path.Combine(Path.GetTempPath(), "PlantoirProblemBuildTest-" + Guid.NewGuid());
        Directory.CreateDirectory(tempDir);
        try
        {
            string runsDir = Path.Combine(tempDir, "runs");
            Directory.CreateDirectory(runsDir);
            File.WriteAllText(Path.Combine(runsDir, "2026-08-16-15-00-00-deploy.txt"), "deploy output");
            File.WriteAllText(Path.Combine(tempDir, "activity.txt"), "2026-08-16 15:00:00 · task started\n");

            var store = new ProblemReportStore(tempDir);
            var builder = new ProblemReportBuilder(store);

            string zipPath = Path.Combine(tempDir, "report.zip");
            var date = new DateTime(2026, 8, 16, 15, 50, 22);
            bool success = builder.BuildZip(zipPath, includingAssistantPrompts: false, moment: date);

            Assert.True(success);
            Assert.True(File.Exists(zipPath));

            using var zip = ZipFile.OpenRead(zipPath);
            string root = "Plantoir problem report 2026-08-16 at 15.50.22";
            Assert.NotNull(zip.GetEntry($"{root}/what is in this report.txt"));
            Assert.NotNull(zip.GetEntry($"{root}/what you were doing.txt"));
            Assert.NotNull(zip.GetEntry($"{root}/tasks/2026-08-16-15-00-00-deploy.txt"));
        }
        finally
        {
            try { Directory.Delete(tempDir, recursive: true); } catch { }
        }
    }
}
