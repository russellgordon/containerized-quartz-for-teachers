using Plantoir.Core.Models;

namespace Plantoir.Core.Assist;

/// <summary>
/// The short explanation of what "publish" means here, given once per section
/// and then remembered.
///
/// Two words do a lot of work in this app and mean different things:
///
/// * **Publish / unpublish** is about a page's <c>draft</c> flag — whether the
///   page is part of the site at all.
/// * **Deploy** is putting the built site where students can reach it, and
///   that is always the teacher's own action, taken in Plantoir.
///
/// A teacher who has not been told that will reasonably hear "I've published
/// tomorrow's class" as "students can see it now" — and act, or fail to act,
/// on that. So the assistant says it plainly the first time it works on a
/// section, and never again for that section: a tool that re-explains itself
/// every conversation is one a teacher learns to skim.
///
/// Kept per SECTION rather than per course or per machine because that is the
/// unit a teacher works in, and because a teacher who takes on a second
/// section months later has usually forgotten.
/// </summary>
public static class Briefing
{
    private static string FileFor(string workspacePath, string courseCode, int sectionNumber) =>
        Path.Combine(Workspace.CoursesDirectory(workspacePath), ".internal", "assist",
            $"{courseCode.ToUpperInvariant()}.section{sectionNumber}.explained");

    public static bool AlreadyExplained(string workspacePath, string courseCode, int sectionNumber)
    {
        try { return File.Exists(FileFor(workspacePath, courseCode, sectionNumber)); }
        catch { return false; }
    }

    public static void MarkExplained(string workspacePath, string courseCode, int sectionNumber)
    {
        try
        {
            string path = FileFor(workspacePath, courseCode, sectionNumber);
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            File.WriteAllText(path, $"{DateTime.UtcNow:O}\n");
        }
        catch { /* failing to remember is not worth failing the conversation over */ }
    }

    /// <summary>
    /// The words themselves, in the app's voice: short, concrete, and about
    /// what the teacher will see rather than about how any of it works.
    /// </summary>
    public static string Words(string courseCode, int sectionNumber, string destination) =>
        $"Before we start on {courseCode} Section {sectionNumber}, two words I’ll use:\n\n" +
        "**Publish** and **unpublish** decide whether a page is part of your site at all. " +
        "Unpublished pages stay in your folder and stay yours to edit — students simply don’t see them.\n\n" +
        "**Deploying** is putting the site where students can actually reach it, and I never do that. " +
        $"When I finish a change I rebuild your preview so you can look it over, and you decide whether " +
        $"to send it to {destination} — that button is yours, in Plantoir.\n\n" +
        "So: I change pages and rebuild the preview. Nothing reaches students until you say so.";
}
