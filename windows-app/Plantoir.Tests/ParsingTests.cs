using Plantoir.Core.Scripting;
using Xunit;

namespace Plantoir.Tests;

public class OutputParserTests
{
    [Fact]
    public void PreviewAddressComesFromTheAnnouncementLastWins()
    {
        string text = "noise\nPreview will be available at: http://localhost:8081/\n" +
                      "more\nPreview will be available at: http://localhost:8092/\n";
        var url = OutputParsers.PreviewAddress(text)!;
        Assert.Equal("127.0.0.1", url.Host);
        Assert.Equal(8092, url.Port);
    }

    [Fact]
    public void PreviewAddressIgnoresUnrelatedLines() =>
        Assert.Null(OutputParsers.PreviewAddress("Launching Quartz preview on http://localhost:8081\n"));

    [Fact]
    public void PublishedUrlPrefersLabelledLinesAndSkipsAdmin()
    {
        string text = " Netlify site created.\n Live URL: https://ics3u-s1.netlify.app\n Admin: https://app.netlify.com/sites/x\n";
        Assert.Equal("https://ics3u-s1.netlify.app/", OutputParsers.PublishedSiteUrl(text)!.ToString());
    }

    [Fact]
    public void RepeatPublishPlainHttpIsPromoted()
    {
        string text = " Using existing Netlify site for this section.\n Site: http://ics3u-s1.netlify.app\n";
        Assert.Equal("https://ics3u-s1.netlify.app/", OutputParsers.PublishedSiteUrl(text)!.ToString());
    }

    [Fact]
    public void CustomDomainSiteIsRecognizedFromItsLabel()
    {
        string text = " Site URL: https://ics3u.school.ca/welcome\n";
        Assert.Equal("https://ics3u.school.ca/welcome", OutputParsers.PublishedSiteUrl(text)!.ToString());
    }

    [Fact]
    public void DashboardOnlyOutputYieldsNothing() =>
        Assert.Null(OutputParsers.PublishedSiteUrl(" Admin: https://app.netlify.com/sites/x\nsee https://docs.netlify.com/x\n"));

    [Fact]
    public void CustomDomainSwapsHostKeepsPathForcesHttps()
    {
        var swapped = OutputParsers.ApplyingCustomDomain("ics3u.school.ca",
            new Uri("http://ics3u-s1.netlify.app/notes/page"));
        Assert.Equal("https://ics3u.school.ca/notes/page", swapped.ToString());
    }

    [Fact]
    public void UploadCountsAreParsedLastWins()
    {
        Assert.Equal((125, 234), OutputParsers.UploadProgress(" …uploaded 100/234 required files\n …uploaded 125/234 required files\n"));
        Assert.Equal(234, OutputParsers.UploadTotal(" Netlify requires 234 file(s) for this deploy.\n"));
        Assert.Null(OutputParsers.UploadProgress("nothing uploaded here\n"));
    }

    [Fact]
    public void BuildStepsComeFromBuildKitLines()
    {
        Assert.Equal((7, 15), OutputParsers.BuildStepProgress("#12 [ 7/15] RUN apt-get update\n"));
        Assert.Null(OutputParsers.BuildStepProgress("[7/15] not a hash line\n"));
    }

    [Fact]
    public void ExampleCourseCodeIsReadBack()
    {
        Assert.Equal("XXX2O", OutputParsers.ExampleCourseCode("EXAMPLE_COURSE_CODE=EXC2O\nEXAMPLE_COURSE_CODE=XXX2O\n"));
        Assert.Null(OutputParsers.ExampleCourseCode("no code here"));
    }
}

public class QuestionParserTests
{
    [Fact]
    public void BracketedDefaultMovesIntoTheAnswerField()
    {
        var asked = QuestionParser.SeparateDefaultAnswer("Enter Netlify site name [ics3u-s3-2026-gordon]:");
        Assert.Equal("Enter Netlify site name:", asked.Question);
        Assert.Equal("ics3u-s3-2026-gordon", asked.SuggestedAnswer);
    }

    [Fact]
    public void DefaultPrefixIsUnderstood()
    {
        var asked = QuestionParser.SeparateDefaultAnswer("Enter the course code (e.g. ICS3U) [Default: ICS3U]:");
        Assert.Equal("ICS3U", asked.SuggestedAnswer);
    }

    [Fact]
    public void ChoiceListsStayInTheWording()
    {
        var asked = QuestionParser.SeparateDefaultAnswer("Overwrite? [Y/n]:");
        Assert.Equal("", asked.SuggestedAnswer);
        Assert.Contains("[Y/n]", asked.Question);
    }

    [Fact]
    public void CancelKeystrokeAsideIsHiddenButCaptured()
    {
        string prompt = "Choose a different Netlify site name (or 'q' to cancel) [ics3u-s3-2026-gordon-01]:";
        var asked = QuestionParser.SeparateDefaultAnswer(prompt);
        Assert.Equal("Choose a different Netlify site name:", asked.Question);
        Assert.Equal("q", asked.CancelToken);
        Assert.Equal("ics3u-s3-2026-gordon-01", asked.SuggestedAnswer);
    }

    [Fact]
    public void InformativeAsidesAreKept() =>
        Assert.Equal("Install the Example Course now? (y/n)", QuestionParser.Asked("Install the Example Course now? (y/n)"));

    [Fact]
    public void UnclosedBracketIsNotAnAside() =>
        Assert.Equal("weird (unclosed", QuestionParser.Asked("weird (unclosed"));

    [Theory]
    [InlineData("Enter something:", true)]
    [InlineData("What is your last name?", true)]
    [InlineData(">", true)]
    [InlineData("Install? (y/n) proceeding", true)]
    [InlineData("Just some progress line", false)]
    public void PromptShapesAreRecognized(string line, bool expected) =>
        Assert.Equal(expected, QuestionParser.LooksLikeQuestion(line));
}

public class FailureExplainerTests
{
    [Fact]
    public void RateLimitReadsTheResetWindow()
    {
        string output = "Netlify API error 429: rate limited\nWindow resets at: 2026-08-11 01:00:00 EDT (in ~59s).";
        Assert.Equal("Netlify is limiting how often websites can be published right now. Try publishing again in about a minute.",
            FailureExplainer.Explanation(output));
        Assert.Contains("in about 3 minutes", FailureExplainer.WaitDescription("(in ~150s)"));
        Assert.Equal("in a few minutes", FailureExplainer.WaitDescription("no marker"));
    }

    [Fact]
    public void TokenProblemsAreExplained()
    {
        Assert.Contains("isn't connected yet", FailureExplainer.Explanation("❌ Netlify token missing."));
        Assert.Contains("didn't accept your access token", FailureExplainer.Explanation("Netlify API error 401: unauthorized"));
    }

    [Fact]
    public void ConnectionAndMissingBuildAreExplained()
    {
        Assert.Contains("couldn't reach the internet", FailureExplainer.Explanation("curl: Could not resolve host api.netlify.com"));
        Assert.Contains("hasn't been built yet", FailureExplainer.Explanation("Built site not found at: /x"));
    }

    [Fact]
    public void UnrecognizedFailuresStayQuiet() =>
        Assert.Null(FailureExplainer.Explanation("something exploded mysteriously"));
}

public class TranscriptBuilderTests
{
    [Fact]
    public void CrLfIsANormalLineEnding()
    {
        var transcript = new TranscriptBuilder();
        transcript.Append("hello\r\nworld\r\n");
        Assert.Equal(new[] { "hello", "world" }, transcript.Lines);
    }

    [Fact]
    public void LoneCarriageReturnRestartsTheLine()
    {
        var transcript = new TranscriptBuilder();
        transcript.Append("spinner |\rspinner /\rspinner done\r\n");
        Assert.Equal(new[] { "spinner done" }, transcript.Lines);
    }

    [Fact]
    public void PendingCarriageReturnCarriesAcrossChunks()
    {
        var transcript = new TranscriptBuilder();
        transcript.Append("line\r");
        transcript.Append("\nnext");
        Assert.Equal(new[] { "line" }, transcript.Lines);
        Assert.Equal("next", transcript.CurrentLine);
    }

    [Fact]
    public void AnsiSequencesAreStripped()
    {
        var transcript = new TranscriptBuilder();
        transcript.Append("\x1b[32mgreen\x1b[0m and \x1b]0;title\x07plain\r\n");
        Assert.Equal(new[] { "green and plain" }, transcript.Lines);
    }

    [Fact]
    public void RetainedLinesAreCapped()
    {
        var transcript = new TranscriptBuilder();
        for (int i = 0; i < 4200; i++) transcript.Append($"line {i}\r\n");
        Assert.Equal(TranscriptBuilder.MaximumRetainedLines, transcript.Lines.Count);
        Assert.Equal("line 4199", transcript.Lines[^1]);
    }

    [Fact]
    public void RecentTextWalksBackwards()
    {
        var transcript = new TranscriptBuilder();
        transcript.Append("aaaa\r\nbbbb\r\ncccc");
        string recent = transcript.RecentText(10);
        Assert.Contains("cccc", recent);
        Assert.DoesNotContain("aaaa", recent);
    }
}

public class TaskMilestoneTests
{
    [Fact]
    public void EveryLabelEndsWithAnEllipsis()
    {
        foreach (var list in TaskMilestones.AllLists)
            foreach (var milestone in list)
                Assert.EndsWith("…", milestone.Label);
    }

    [Fact]
    public void NoLabelMentionsMachinery()
    {
        foreach (var list in TaskMilestones.AllLists)
            foreach (var milestone in list)
            {
                Assert.DoesNotContain("Docker", milestone.Label);
                Assert.DoesNotContain("WSL", milestone.Label);
                Assert.DoesNotContain("script", milestone.Label, StringComparison.OrdinalIgnoreCase);
            }
    }

    [Fact]
    public void ALaterMarkerImpliesEarlierSteps()
    {
        var runner = new ScriptRunner(uiContext: null) { Milestones = TaskMilestones.Preview };
        runner.ReceiveOutput("Quartz v4 building...\n");
        Assert.Equal(7, runner.MilestonesReached);
        Assert.Equal("Opening the preview…", runner.CurrentMilestoneLabel);
    }

    [Fact]
    public void AMarkerSplitAcrossChunksStillMatches()
    {
        var runner = new ScriptRunner(uiContext: null) { Milestones = TaskMilestones.Preview };
        runner.ReceiveOutput("Copying shared fol");
        runner.ReceiveOutput("ders into place\n");
        Assert.Equal(4, runner.MilestonesReached);
    }

    [Fact]
    public void UploadCountsBecomeStepDetailAndClearOnAdvance()
    {
        var runner = new ScriptRunner(uiContext: null) { Milestones = TaskMilestones.Deploy };
        runner.ReceiveOutput("Delta deploy created\n");
        runner.ReceiveOutput(" …uploaded 125/234 required files\n");
        Assert.Equal("125 of 234", runner.StepDetail);
        runner.ReceiveOutput("Deploy complete\n");
        Assert.Equal("", runner.StepDetail);
    }
}
