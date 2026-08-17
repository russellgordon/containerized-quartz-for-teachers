using System.Text.Json.Nodes;
using Plantoir.Core;
using Plantoir.Core.Assist;
using Plantoir.Core.Catalogs;
using Plantoir.Core.Models;
using Plantoir.Core.Scripting;

namespace Plantoir.Tests;

public class ContractTests
{
    [Fact]
    public void AssistWording_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("assist-wording.json");
        var wording = doc["wording"]!.AsObject();

        Assert.Equal(wording["deployApproval"]!.ToString(), AssistWording.DeployApproval);
        Assert.Equal(wording["deployQuestion"]!.ToString(), AssistWording.DeployQuestion);
        Assert.Equal(wording["planQuestion"]!.ToString(), AssistWording.PlanQuestion);
        Assert.Equal(wording["deployAccepted"]!.ToString(), AssistWording.DeployAccepted);
        Assert.Equal(wording["planAccepted"]!.ToString(), AssistWording.PlanAccepted);
        Assert.Equal(wording["cancelled"]!.ToString(), AssistWording.Cancelled);
        Assert.Equal(wording["deployWasCancelled"]!.ToString(), AssistWording.DeployWasCancelled);
        Assert.Equal(wording["planWasCancelled"]!.ToString(), AssistWording.PlanWasCancelled);

        Assert.Equal(wording["deployed"]!.ToString(), AssistWording.Deployed("{course}", "{section}"));
        Assert.Equal(wording["couldNotBuildBeforeDeploying"]!.ToString(), AssistWording.CouldNotBuildBeforeDeploying("{course}", "{section}"));
        Assert.Equal(wording["deployDidNotFinish"]!.ToString(), AssistWording.DeployDidNotFinish("{course}", "{section}"));
        Assert.Equal(wording["sectionIsBusy"]!.ToString(), AssistWording.SectionIsBusy("{course}", "{section}"));
        Assert.Equal(wording["courseIsBusy"]!.ToString(), AssistWording.CourseIsBusy("{course}"));

        Assert.Equal(wording["previewIsRebuilding"]!.ToString(), AssistWording.PreviewIsRebuilding("{course}", "{section}"));
        Assert.Equal(wording["builtWithNoWindowOpen"]!.ToString(), AssistWording.BuiltWithNoWindowOpen("{course}", "{section}"));
        Assert.Equal(wording["rebuiltForACallerWithNoWindow"]!.ToString(), AssistWording.RebuiltForACallerWithNoWindow("{course}", "{section}"));
        Assert.Equal(wording["previewDidNotBuild"]!.ToString(), AssistWording.PreviewDidNotBuild("{course}", "{section}"));

        Assert.Equal(wording["undid"]!.ToString(), AssistWording.Undid("{change}"));
        Assert.Equal(wording["undidPartly"]!.ToString(), AssistWording.UndidPartly("{change}", 2));
        Assert.Equal(wording["couldNotUndo"]!.ToString(), AssistWording.CouldNotUndo("{change}", 2));

        Assert.Equal(wording["undoIsStillAvailable"]!.ToString(), AssistWording.UndoIsStillAvailable);
        Assert.Equal(wording["nothingToUndo"]!.ToString(), AssistWording.NothingToUndo);
        Assert.Equal(wording["aCreatedPageCanBeTakenBack"]!.ToString(), AssistWording.ACreatedPageCanBeTakenBack);
        Assert.Equal(wording["undoDoesNotReachTheLiveSite"]!.ToString(), AssistWording.UndoDoesNotReachTheLiveSite);
        Assert.Equal(wording["whereTheOutputIs"]!.ToString(), AssistWording.WhereTheOutputIs);
        Assert.Equal(wording["nothingToDo"]!.ToString(), AssistWording.NothingToDo);
    }

    [Fact]
    public void FileFormats_PageVisibilityReadingCases()
    {
        var doc = ContractLoader.LoadJson("file-formats.json");
        var cases = doc["pageVisibility"]!["readingCases"]!.AsArray();

        foreach (var c in cases)
        {
            string pageText = c!["page"]!.ToString();
            bool expectedVisible = c["expectVisible"]!.GetValue<bool>();
            int section = c["section"]?.GetValue<int>() ?? 1;

            string fullFrontmatter = $"---\n{pageText}\n---\n# Content";

            bool actualVisible = !PageFrontmatter.IsDraft(fullFrontmatter, section);

            Assert.True(actualVisible == expectedVisible,
                $"Case '{pageText}' (section {section}) expected visible={expectedVisible} but got {actualVisible}");
        }
    }

    [Fact]
    public void CourseManagement_GradeLabels_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("course-management.json");
        var cases = doc["gradeLabels"]!["cases"]!.AsArray();

        foreach (var c in cases)
        {
            if (c is null) continue;
            string code = c["code"]!.ToString();
            string expectedLabel = c["expect"]!.ToString();
            string actual = SectionAdder.GradeLabel(code);
            Assert.Equal(expectedLabel, actual);
        }
    }

    [Fact]
    public void CourseManagement_CourseCode_Normalized_And_Problems_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("course-management.json");
        var normalizedCases = doc["courseCode"]!["normalized"]!.AsArray();

        foreach (var c in normalizedCases)
        {
            string typed = c!["typed"]!.ToString();
            string expected = c["expect"]!.ToString();
            Assert.Equal(expected, CourseCodeValidator.Normalize(typed));
        }

        var problemCases = doc["courseCode"]!["problems"]!.AsArray();
        foreach (var c in problemCases)
        {
            string typed = c!["typed"]!.ToString();
            var existing = c["existing"]!.AsArray().Select(e => e!.ToString()).ToList();
            string? currentCode = c["currentCode"]?.ToString();
            string? expectProblem = c["expectProblem"]?.ToString();
            string? expectShort = c["expectShort"]?.ToString();

            var (problem, shortProblem) = CourseCodeValidator.Validate(typed, existing, currentCode);
            Assert.Equal(expectProblem, problem);
            Assert.Equal(expectShort, shortProblem);
        }
    }

    [Fact]
    public void CourseManagement_DefaultCourseName_MatchesContract()
    {
        string supportFile = ContractLoader.GetSupportPath("ontario_secondary_courses.json");
        var catalog = CourseNameCatalog.Load(supportFile);

        var doc = ContractLoader.LoadJson("course-management.json");
        var cases = doc["defaultCourseName"]!["cases"]!.AsArray();

        foreach (var c in cases)
        {
            string code = c!["code"]!.ToString();
            string? expect = c["expect"]?.ToString();
            string? actual = catalog.DefaultName(code);
            Assert.Equal(expect, actual);
        }
    }

    [Fact]
    public void SharedRules_ActivityTrailEvents_Exist()
    {
        var doc = ContractLoader.LoadJson("shared-rules.json");
        var events = doc["activityTrail"]!["mustRecord"]!.AsArray();

        var contractKeys = events.Select(e => e!["event"]!.ToString()).ToHashSet();

        var codeKeys = Enum.GetValues<ActivityTrail.Event>()
            .Select(ActivityTrail.KeyFor)
            .ToHashSet();

        Assert.Equal(contractKeys, codeKeys);
    }

    [Fact]
    public void AppRules_PreviewPorts_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("app-rules.json");
        var previewPorts = doc["previewPorts"]!;
        int wsOffset = previewPorts["websocketOffset"]!.GetValue<int>();
        Assert.Equal(1000, wsOffset);
    }

    [Fact]
    public void SharedRules_WorkingFolderPathBar_MatchesContract()
    {
        var doc = ContractLoader.LoadJson("shared-rules.json");
        var bar = doc["workingFolderPathBar"]!;
        var actions = bar["actions"]!.AsArray();

        var revealAction = actions.FirstOrDefault(a => a?["action"]?.ToString() == "reveal");
        Assert.NotNull(revealAction);
        Assert.Equal("Show in File Explorer", revealAction["windowsLabel"]?.ToString());

        var openAction = actions.FirstOrDefault(a => a?["action"]?.ToString() == "open");
        Assert.NotNull(openAction);
        Assert.Equal("Open Folder", openAction["windowsLabel"]?.ToString());

        // Ancestor paths on Windows
        string path = @"C:\Users\teacher\Desktop\Courses";
        var crumbs = FolderCrumb.AncestorPaths(path);
        var expected = new[]
        {
            @"C:\",
            @"C:\Users",
            @"C:\Users\teacher",
            @"C:\Users\teacher\Desktop",
            @"C:\Users\teacher\Desktop\Courses",
        };
        Assert.Equal(expected, crumbs);
    }
}

