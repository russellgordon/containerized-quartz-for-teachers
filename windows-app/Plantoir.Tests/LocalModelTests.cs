using System;
using System.IO;
using Plantoir.Core.Assist;
using Xunit;

namespace Plantoir.Tests;

public class LocalModelTests : IDisposable
{
    private readonly string _tempDir;

    public LocalModelTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), "plantoir-model-tests-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(_tempDir);
        LocalModel.ModelDirectoryOverride = _tempDir;
    }

    public void Dispose()
    {
        LocalModel.ModelDirectoryOverride = null;
        if (Directory.Exists(_tempDir))
        {
            try { Directory.Delete(_tempDir, recursive: true); } catch { }
        }
    }

    [Fact]
    public void ModelConstants_MatchVerifiedSpecifications()
    {
        Assert.Equal("qwen2.5-1.5b-instruct-q4_k_m.gguf", LocalModel.ModelFileName);
        Assert.Equal(1_117_320_736L, LocalModel.ExpectedDownloadBytes);
        Assert.Contains("qwen2.5-1.5b-instruct-q4_k_m.gguf", LocalModel.ModelUrl, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void IsInstalled_ReturnsFalseWhenMissingOrIncomplete()
    {
        var model = new LocalModel();
        Assert.False(model.IsInstalled());

        // Partial or empty file must fail
        string path = Path.Combine(_tempDir, LocalModel.ModelFileName);
        File.WriteAllBytes(path, new byte[100]);
        Assert.False(model.IsInstalled());
    }

    [Fact]
    public void IsInstalled_ReturnsTrueWhenExactFileSizeMatches()
    {
        var model = new LocalModel();
        string path = Path.Combine(_tempDir, LocalModel.ModelFileName);
        using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write))
        {
            fs.SetLength(LocalModel.ExpectedDownloadBytes);
        }

        Assert.True(model.IsInstalled());
        Assert.Equal(path, LocalModel.GetModelPath());
    }

    [Fact]
    public void IsInstalled_AcceptsLegacyCasingIfPresent()
    {
        var model = new LocalModel();
        string legacyPath = Path.Combine(_tempDir, LocalModel.LegacyModelFileName);
        using (var fs = new FileStream(legacyPath, FileMode.Create, FileAccess.Write))
        {
            fs.SetLength(LocalModel.ExpectedDownloadBytes);
        }

        Assert.True(model.IsInstalled());
        Assert.True(File.Exists(LocalModel.GetModelPath()));
    }

    [Fact]
    public void BuildArguments_CarriesLoadBearingFlags()
    {
        var args = LocalModel.BuildArguments("C:\\models\\test.gguf", port: 8099, threads: 4, ctxSize: 8192);

        // Required flags
        Assert.Contains("--model", args);
        Assert.Contains("C:\\models\\test.gguf", args);
        Assert.Contains("--port", args);
        Assert.Contains("8099", args);
        Assert.Contains("--host", args);
        Assert.Contains("127.0.0.1", args);
        Assert.Contains("--ctx-size", args);
        Assert.Contains("8192", args);
        Assert.Contains("--threads", args);
        Assert.Contains("4", args);
        Assert.Contains("--n-gpu-layers", args);
        Assert.Contains("999", args);
        Assert.Contains("--reasoning", args);
        Assert.Contains("off", args);
        Assert.Contains("--reasoning-budget", args);
        Assert.Contains("0", args);
        Assert.Contains("--jinja", args);
        Assert.Contains("--parallel", args);
        Assert.Contains("1", args);
    }

    [Fact]
    public void Fetching_CalculatesPercentageAndClamps()
    {
        var unknown = new LocalModel.Fetching(500 * 1024 * 1024, 0);
        Assert.False(unknown.Known);
        Assert.Equal(0, unknown.Percent);
        Assert.Contains("500 MB so far", unknown.Describe());

        var known = new LocalModel.Fetching(500 * 1024 * 1024, 1000 * 1024 * 1024);
        Assert.True(known.Known);
        Assert.Equal(50.0, known.Percent, precision: 1);
        Assert.Contains("500 MB of 1000 MB (50%)", known.Describe());

        var overflow = new LocalModel.Fetching(1200 * 1024 * 1024, 1000 * 1024 * 1024);
        Assert.Equal(100.0, overflow.Percent);
    }

    [Fact]
    public void FindServer_LocatesBundledOrVendorServer()
    {
        string? server = LocalModel.FindServer();
        // When Vendor/llama is present on dev machine, FindServer must locate it
        if (Directory.Exists(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "Vendor", "llama")))
        {
            Assert.NotNull(server);
            Assert.True(File.Exists(server));
            Assert.EndsWith("llama-server.exe", server, StringComparison.OrdinalIgnoreCase);
        }
    }
}
