using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace Plantoir.Core.Scripting;

public class ProblemReportStore
{
    public string LogsDirectory { get; }
    public const int MostRetainedRuns = 20;
    public const string ActivityFileName = "activity.txt";

    public ProblemReportStore(string? logsDirectory = null)
    {
        LogsDirectory = logsDirectory ?? ActivityTrail.DefaultLogDirectory;
    }

    public static ProblemReportStore Standard
    {
        get
        {
            string currentPath = ActivityTrail.CurrentLogPath;
            string dir = Path.GetDirectoryName(currentPath) ?? ActivityTrail.DefaultLogDirectory;
            return new ProblemReportStore(dir);
        }
    }

    public string RunsFolder => Path.Combine(LogsDirectory, "runs");
    public string ActivityFile => Path.Combine(LogsDirectory, ActivityFileName);

    public IReadOnlyList<string> RunFilePaths()
    {
        if (!Directory.Exists(RunsFolder)) return Array.Empty<string>();
        return Directory.GetFiles(RunsFolder, "*.txt")
            .OrderByDescending(Path.GetFileName, StringComparer.Ordinal)
            .Take(MostRetainedRuns)
            .ToList();
    }

    public string ActivityText(bool includingPrompts)
    {
        string path = ActivityFile;
        if (!File.Exists(path)) return "";
        string content = File.ReadAllText(path);
        if (includingPrompts) return content;

        var keptLines = content.Split('\n')
            .Where(line => !line.StartsWith(ActivityTrail.PromptPrefix, StringComparison.Ordinal));
        return string.Join("\n", keptLines);
    }

    public bool HasAnythingToReport
    {
        get
        {
            if (RunFilePaths().Count > 0) return true;
            return !string.IsNullOrWhiteSpace(ActivityText(includingPrompts: true));
        }
    }

    public bool HasAssistantPrompts
    {
        get
        {
            string text = ActivityText(includingPrompts: true);
            foreach (var line in text.Split('\n'))
            {
                if (line.StartsWith(ActivityTrail.PromptPrefix, StringComparison.Ordinal))
                    return true;
            }
            return false;
        }
    }
}
