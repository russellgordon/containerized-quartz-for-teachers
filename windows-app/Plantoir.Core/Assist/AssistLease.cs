using System.Diagnostics;
using Plantoir.Core.Models;

namespace Plantoir.Core.Assist;

/// <summary>
/// A file saying "an assistant is working on this course right now", written
/// by the MCP server and read by the app.
///
/// This exists because the two are separate processes and neither can see the
/// other's memory. The app's busy-tracking — preview leases, publish records —
/// is in-process, so without something on disk a teacher could ask an
/// assistant to publish a section and then hit Preview on the same section,
/// and both would build into <c>.merged_output/section&lt;N&gt;/</c> at once.
/// The build clears that folder before writing it, so the loser serves a
/// half-written site or publishes files the other just deleted.
///
/// Deliberately the simplest thing that survives a crash: a file per course,
/// carrying the process id that owns it. A reader treats a lease whose process
/// is gone as gone too, so a killed session cannot leave a course locked
/// forever — no cleanup pass, no timeout to tune.
///
/// **This is the shape proposed for the shared registry both apps would
/// adopt** (MCP-PROPOSAL.md, phase 2). Written here first because launching an
/// assistant from the GUI makes the overlap ordinary rather than theoretical.
/// </summary>
public static class AssistLease
{
    /// <summary>Beside the profile the toolchain already keeps there.</summary>
    private static string Directory(string workspacePath) =>
        Path.Combine(Workspace.CoursesDirectory(workspacePath), ".internal", "assist");

    private static string FileFor(string workspacePath, string courseCode) =>
        Path.Combine(Directory(workspacePath), courseCode.ToUpperInvariant() + ".lease");

    /// <summary>
    /// Claim a course for this process. Disposing releases it; so does the
    /// process ending, since a lease whose owner is gone is ignored.
    /// </summary>
    public static IDisposable Take(string workspacePath, string courseCode)
    {
        string path = FileFor(workspacePath, courseCode);
        try
        {
            System.IO.Directory.CreateDirectory(Directory(workspacePath));
            File.WriteAllText(path,
                $"{Environment.ProcessId}\n{Process.GetCurrentProcess().ProcessName}\n{DateTime.UtcNow:O}\n");
        }
        catch { /* an unwritable folder must not stop the assistant working */ }
        return new Release(path);
    }

    private sealed class Release(string path) : IDisposable
    {
        private bool _done;
        public void Dispose()
        {
            if (_done) return;
            _done = true;
            try { File.Delete(path); } catch { }
        }
    }

    /// <summary>
    /// True when some other process is assisting on this course. A lease owned
    /// by a process that no longer exists is not a lease.
    /// </summary>
    public static bool IsAssisting(string workspacePath, string courseCode)
    {
        string path = FileFor(workspacePath, courseCode);
        string[] lines;
        try
        {
            if (!File.Exists(path)) return false;
            lines = File.ReadAllLines(path);
        }
        catch { return false; }

        if (lines.Length < 2 || !int.TryParse(lines[0].Trim(), out int pid)) return false;
        if (pid == Environment.ProcessId) return false;   // our own lease is not a conflict

        try
        {
            var owner = Process.GetProcessById(pid);
            // A recycled process id is a different program: compare the name
            // too, so a dead session cannot be impersonated by whatever the
            // operating system handed the number to next.
            return !owner.HasExited &&
                   string.Equals(owner.ProcessName, lines[1].Trim(), StringComparison.OrdinalIgnoreCase);
        }
        catch (ArgumentException) { return false; }        // no such process: stale
        catch (InvalidOperationException) { return false; } // exited while we looked: stale
        catch { return true; }                             // can't tell: assume busy
    }
}
