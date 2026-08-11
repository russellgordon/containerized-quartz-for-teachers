using Newtonsoft.Json.Linq;
using Plantoir.Core.Models;

namespace Plantoir.Core.Scripting;

/// <summary>
/// "The wizard with every answer pre-filled": the app writes the teacher's
/// choices to course_config.json first, runs the REAL setup launcher, and
/// presses Return at each prompt — the wizard re-reads the file as its
/// saved defaults, so a plain Return accepts every one. The one exception,
/// the course-code prompt, is answered explicitly.
/// </summary>
public sealed class NewCourseCreator
{
    public ScriptRunner Runner { get; }
    public bool IsCreating { get; private set; }
    public string? PreparationProblem { get; private set; }
    public string? InstalledExampleCode { get; private set; }

    private string _courseCode = "";
    private long _respondedVersion = -1;
    private int _responsesSent;

    public NewCourseCreator(ScriptRunner runner) => Runner = runner;

    public async Task CreateCourse(JObject configuration, string workspacePath)
    {
        PreparationProblem = null;
        if (configuration["course_code"]?.ToString() is not { Length: > 0 } storedCode)
        {
            PreparationProblem = "The course needs a code.";
            return;
        }
        _courseCode = storedCode.ToUpperInvariant();

        try
        {
            string courseDir = Path.Combine(Workspace.CoursesDirectory(workspacePath), _courseCode);
            Directory.CreateDirectory(courseDir);
            CourseConfiguration.FromDictionary(configuration)
                .Write(Path.Combine(courseDir, "course_config.json"));
        }
        catch (Exception error)
        {
            PreparationProblem = $"Could not write the course configuration: {error.Message}";
            return;
        }

        _respondedVersion = -1;
        _responsesSent = 0;
        IsCreating = true;
        Runner.Milestones = TaskMilestones.CourseCreation;
        Runner.Run("setup.ps1", Array.Empty<string>(), workspacePath);
        await PumpAnswers();
        IsCreating = false;
    }

    public async Task InstallExampleCourse(string workspacePath)
    {
        PreparationProblem = null;
        IsCreating = true;
        Runner.Milestones = TaskMilestones.ExampleCourse;
        Runner.Run("setup.ps1", new[] { "--install-example" }, workspacePath);
        await Runner.WaitUntilFinished();
        InstalledExampleCode = OutputParsers.ExampleCourseCode(Runner.Transcript.DisplayText);
        IsCreating = false;
    }

    /// <summary>
    /// Every 400 ms: if NEW output has arrived and its last non-empty line is
    /// prompt-shaped, answer — the course code where asked, a bare Return
    /// everywhere else. The new-output guard is the whole anti-double-answer
    /// mechanism; 300 responses is the runaway valve.
    /// </summary>
    private async Task PumpAnswers()
    {
        while (Runner.IsRunning)
        {
            await Task.Delay(400);
            if (_responsesSent > 300) { Runner.Terminate(); break; }
            long version = Runner.Transcript.Version;
            if (version == _respondedVersion) continue;
            string lastLine = CurrentPromptLine();
            if (!LooksLikePrompt(lastLine)) continue;
            _respondedVersion = version;
            _responsesSent++;
            Runner.SendLine(lastLine.Contains("Enter the course code") ? _courseCode : "");
        }
    }

    private string CurrentPromptLine()
    {
        string current = Runner.Transcript.CurrentLine.Trim();
        if (current.Length > 0) return current;
        for (int i = Runner.Transcript.Lines.Count - 1; i >= 0; i--)
        {
            string line = Runner.Transcript.Lines[i].Trim();
            if (line.Length > 0) return line;
        }
        return "";
    }

    /// <summary>
    /// Looser than the question heuristic on purpose — matched to the prompt
    /// shapes setup_course.py really prints, including the arrow-key colour
    /// picker (where Return accepts the saved default).
    /// </summary>
    internal static bool LooksLikePrompt(string line) =>
        line.EndsWith(':') || line.EndsWith(": ", StringComparison.Ordinal)
        || line == ">"
        || line.StartsWith("Use ← / →", StringComparison.Ordinal)
        || line.EndsWith('?');
}
