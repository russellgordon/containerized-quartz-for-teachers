using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Plantoir.Tests;

public static class ContractLoader
{
    public static string GetContractPath(string fileName)
    {
        string local = Path.Combine(AppContext.BaseDirectory, "contracts", fileName);
        if (File.Exists(local)) return local;

        string parentLocal = Path.Combine(AppContext.BaseDirectory, fileName);
        if (File.Exists(parentLocal)) return parentLocal;

        // Fallback relative to repository root if running in different test runners
        string repoPath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "contracts", fileName));
        if (File.Exists(repoPath)) return repoPath;

        throw new FileNotFoundException($"Could not find contract file: {fileName}");
    }

    public static string GetSupportPath(string fileName)
    {
        string local = Path.Combine(AppContext.BaseDirectory, "support", fileName);
        if (File.Exists(local)) return local;

        string parentLocal = Path.Combine(AppContext.BaseDirectory, fileName);
        if (File.Exists(parentLocal)) return parentLocal;

        string repoPath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", "support", fileName));
        if (File.Exists(repoPath)) return repoPath;

        throw new FileNotFoundException($"Could not find support file: {fileName}");
    }

    public static JsonNode LoadJson(string fileName)
    {
        string path = GetContractPath(fileName);
        string content = File.ReadAllText(path);
        return JsonNode.Parse(content) ?? throw new InvalidOperationException($"Failed to parse {fileName}");
    }

    public static JsonDocument LoadDocument(string fileName)
    {
        string path = GetContractPath(fileName);
        string content = File.ReadAllText(path);
        return JsonDocument.Parse(content);
    }
}
