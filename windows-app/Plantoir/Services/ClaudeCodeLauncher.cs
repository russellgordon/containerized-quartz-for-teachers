using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Text.Json;

namespace Plantoir.Services;

/// <summary>
/// Starting a Claude Code session already connected to this working folder's
/// Plantoir tools, locked to one course.
///
/// The teacher never types a command. Everything the connection needs is
/// written for them and thrown away with the session:
///
/// * **No global configuration is touched.** The connection is passed with
///   `--mcp-config`, and `--strict-mcp-config` means only that server is
///   loaded — so a teacher's own MCP servers are neither used nor disturbed,
///   and nothing is left behind when the session ends.
/// * **Nothing lands in the teacher's folder.** The config sits in the app's
///   own data directory, not in the vault Obsidian is watching.
/// * **The session is locked to the course it was started from.** Passed to
///   the server rather than asked for in a prompt, so it holds however the
///   conversation wanders.
///
/// The menu item only appears when this returns true from
/// <see cref="IsAvailable"/> — a teacher without Claude Code should not be
/// offered a door that opens onto an error.
/// </summary>
public static class ClaudeCodeLauncher
{
    /// <summary>Both halves have to be present: the assistant, and the tools for it to use.</summary>
    public static bool IsAvailable => FindClaude() is not null && FindServer() is not null;

    /// <summary>
    /// Where Claude Code is, or null. Checked on PATH first, then the places
    /// its own installers put it.
    /// </summary>
    public static string? FindClaude()
    {
        string? onPath = OnPath("claude.exe") ?? OnPath("claude.cmd") ?? OnPath("claude.bat");
        if (onPath is not null) return onPath;

        string home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        foreach (string candidate in new[]
                 {
                     Path.Combine(home, ".local", "bin", "claude.exe"),
                     Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                         "Programs", "claude", "claude.exe"),
                     Path.Combine(home, "AppData", "Roaming", "npm", "claude.cmd"),
                 })
            if (File.Exists(candidate)) return candidate;
        return null;
    }

    /// <summary>The MCP server, which ships beside the app.</summary>
    public static string? FindServer()
    {
        string? beside = Path.GetDirectoryName(Environment.ProcessPath);
        if (beside is null) return null;
        foreach (string candidate in new[]
                 {
                     Path.Combine(beside, "plantoir-mcp.exe"),
                     // Running from a dev build, where each project has its own output.
                     Path.GetFullPath(Path.Combine(beside, "..", "..", "..", "..",
                         "Plantoir.Mcp", "bin", "Debug", "net9.0", "win-x64", "plantoir-mcp.exe")),
                 })
            if (File.Exists(candidate)) return candidate;
        return null;
    }

    private static string? OnPath(string name)
    {
        string paths = Environment.GetEnvironmentVariable("PATH") ?? "";
        foreach (string directory in paths.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
        {
            try
            {
                string candidate = Path.Combine(directory.Trim(), name);
                if (File.Exists(candidate)) return candidate;
            }
            catch { }
        }
        return null;
    }

    /// <summary>
    /// Open a session for one course. Returns false when it could not be
    /// started, so the caller can say so rather than leaving a teacher looking
    /// at nothing.
    /// </summary>
    public static bool Open(string workspacePath, string courseCode, string courseName)
    {
        string? claude = FindClaude();
        string? server = FindServer();
        if (claude is null || server is null) return false;

        string configPath;
        try { configPath = WriteConfig(workspacePath, courseCode, server); }
        catch { return false; }

        string prompt = Greeting(courseCode, courseName);
        string command =
            $"\"{claude}\" --mcp-config \"{configPath}\" --strict-mcp-config \"{prompt}\"";

        // Windows Terminal when it is there, because a teacher will be reading
        // this for a while; the classic console otherwise.
        var info = new ProcessStartInfo { UseShellExecute = true, WorkingDirectory = workspacePath };
        if (OnPath("wt.exe") is not null)
        {
            info.FileName = "wt.exe";
            info.Arguments = $"-d \"{workspacePath}\" cmd /k {command}";
        }
        else
        {
            info.FileName = "cmd.exe";
            info.Arguments = $"/k {command}";
        }

        try { return Process.Start(info) is not null; }
        catch { return false; }
    }

    /// <summary>
    /// The opening message. It names the course and points at the plan tools,
    /// because the safety of every write here depends on a plan being shown to
    /// the teacher first — and an assistant that starts by reading is far more
    /// useful than one that starts by asking what to do.
    /// </summary>
    private static string Greeting(string courseCode, string courseName)
    {
        var text = new StringBuilder();
        text.Append($"I'm a teacher working on {courseCode}");
        if (!string.IsNullOrWhiteSpace(courseName) && courseName != courseCode)
            text.Append($" ({courseName})");
        text.Append(" in Plantoir. Use the plantoir tools for anything to do with this course. ");
        text.Append("Start by listing its sections so we both know what's there. ");
        text.Append("Before changing anything, use the matching plan tool first and show me what it says, ");
        text.Append("in plain words, and wait for me to agree.");
        return text.ToString().Replace("\"", "'");
    }

    /// <summary>
    /// The connection, written per course into the app's own data directory.
    /// One file per course so two sessions on different courses do not
    /// overwrite each other's configuration mid-launch.
    /// </summary>
    private static string WriteConfig(string workspacePath, string courseCode, string server)
    {
        string directory = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Plantoir", "assist");
        Directory.CreateDirectory(directory);

        var config = new
        {
            mcpServers = new Dictionary<string, object>
            {
                ["plantoir"] = new
                {
                    command = server,
                    args = new[] { "--folder", workspacePath, "--course", courseCode },
                },
            },
        };

        string path = Path.Combine(directory, $"mcp-{courseCode}.json");
        File.WriteAllText(path, JsonSerializer.Serialize(config,
            new JsonSerializerOptions { WriteIndented = true }));
        return path;
    }
}
