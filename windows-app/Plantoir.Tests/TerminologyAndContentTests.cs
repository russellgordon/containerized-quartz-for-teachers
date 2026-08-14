using Plantoir.Core.Catalogs;
using Xunit;

namespace Plantoir.Tests;

/// <summary>
/// The LCS-terminology switch: school-neutral factory defaults, with one
/// toggle bringing back LCS's own words and folders. Mirrors the mac app's
/// TerminologyTests so the two wizards can never drift apart.
/// </summary>
public class TerminologyTests
{
    [Fact]
    public void TheNeutralDefaultsCarryNoLcsTerms()
    {
        Assert.DoesNotContain("College Board Curriculum", WizardDefaults.SharedFolders);
        Assert.DoesNotContain("SIC Drop-In Sessions.md", WizardDefaults.SharedFiles);
        Assert.DoesNotContain("Grove Time.md", WizardDefaults.SharedFiles);
        Assert.Contains("Extra Help.md", WizardDefaults.SharedFiles);
        Assert.Contains("Learning Goals.md", WizardDefaults.SharedFiles);
    }

    [Fact]
    public void TheLcsSetRestoresTheSchoolsOwnSetUp()
    {
        Assert.Contains("College Board Curriculum", WizardDefaults.LcsSharedFolders);
        Assert.Contains("SIC Drop-In Sessions.md", WizardDefaults.LcsSharedFiles);
        Assert.Contains("Grove Time.md", WizardDefaults.LcsSharedFiles);
        Assert.DoesNotContain("Extra Help.md", WizardDefaults.LcsSharedFiles);
    }

    [Fact]
    public void SwitchingReplacesFactoryItemsAndKeepsCustomOnes()
    {
        var current = new List<string> { "Extra Help.md", "Learning Goals.md", "My Own Page.md" };

        var switched = WizardDefaults.SwitchingFactoryItems(
            current, WizardDefaults.LcsSharedFiles, WizardDefaults.SharedFiles);
        Assert.Contains("Grove Time.md", switched);
        Assert.Contains("SIC Drop-In Sessions.md", switched);
        Assert.DoesNotContain("Extra Help.md", switched);
        Assert.Contains("My Own Page.md", switched);

        var switchedBack = WizardDefaults.SwitchingFactoryItems(
            switched, WizardDefaults.SharedFiles, WizardDefaults.LcsSharedFiles);
        Assert.Equal(new[] { "Extra Help.md", "Learning Goals.md", "My Own Page.md" }, switchedBack);
    }

    [Fact]
    public void HiddenListCoversBothTerminologies()
    {
        foreach (string name in new[]
                 { "Extra Help.md", "Grove Time.md", "SIC Drop-In Sessions.md", "College Board Curriculum" })
            Assert.Contains(name, WizardDefaults.HiddenItems);
    }
}

/// <summary>
/// The bundled example-content lookup that decides whether the wizard offers
/// its Starting Content toggles. Mirrors the mac app's ExampleContentCatalog.
/// </summary>
public class ExampleContentCatalogTests
{
    private static string Temp()
    {
        string root = Path.Combine(Path.GetTempPath(), "plantoir-content-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        return root;
    }

    private static void WriteManifest(string root, string code, string json)
    {
        string dir = Path.Combine(root, code);
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, "manifest.json"), json);
    }

    [Fact]
    public void NoPayloadMeansNoContent()
    {
        string root = Temp();
        try
        {
            Assert.False(ExampleContentCatalog.HasContent(root, "ICS3U"));
            Assert.False(ExampleContentCatalog.IncludesCurriculum(root, "ICS3U"));
        }
        finally { try { Directory.Delete(root, true); } catch { } }
    }

    [Fact]
    public void LookupIsCaseInsensitiveAndTrimmed()
    {
        string root = Temp();
        try
        {
            WriteManifest(root, "ADA1O", """{"curriculum_folder": "Curriculum"}""");
            Assert.True(ExampleContentCatalog.HasContent(root, "  ada1o "));
            Assert.True(ExampleContentCatalog.IncludesCurriculum(root, "ada1o"));
        }
        finally { try { Directory.Delete(root, true); } catch { } }
    }

    [Fact]
    public void EmptyOrBlankCodeAnswersNothing()
    {
        string root = Temp();
        try
        {
            Assert.Null(ExampleContentCatalog.ManifestPath(root, ""));
            Assert.Null(ExampleContentCatalog.ManifestPath(root, "   "));
        }
        finally { try { Directory.Delete(root, true); } catch { } }
    }

    [Fact]
    public void CurriculumRequiresANonEmptyFolderKey()
    {
        string root = Temp();
        try
        {
            WriteManifest(root, "AAA1O", """{"curriculum_folder": ""}""");
            WriteManifest(root, "BBB1O", """{"shared_folders": []}""");
            WriteManifest(root, "CCC1O", "not json at all");
            Assert.True(ExampleContentCatalog.HasContent(root, "AAA1O"));
            Assert.False(ExampleContentCatalog.IncludesCurriculum(root, "AAA1O"));
            Assert.False(ExampleContentCatalog.IncludesCurriculum(root, "BBB1O"));
            Assert.False(ExampleContentCatalog.IncludesCurriculum(root, "CCC1O"));
        }
        finally { try { Directory.Delete(root, true); } catch { } }
    }

    [Fact]
    public void TheSixShippedPayloadsAreFoundInTheRepoSupportFolder()
    {
        // Walk up from the test bin to the repo's support/example_content.
        string? dir = AppContext.BaseDirectory;
        while (dir is not null && !Directory.Exists(Path.Combine(dir, "support", "example_content")))
            dir = Path.GetDirectoryName(dir);
        Assert.NotNull(dir);
        string root = Path.Combine(dir!, "support", "example_content");
        foreach (string code in new[] { "ADA1O", "ICD2O", "MPM2D", "MTH1W", "TEJ2O", "TGJ2O" })
        {
            Assert.True(ExampleContentCatalog.HasContent(root, code), $"{code} payload missing");
            Assert.True(ExampleContentCatalog.IncludesCurriculum(root, code), $"{code} curriculum missing");
        }
    }
}
