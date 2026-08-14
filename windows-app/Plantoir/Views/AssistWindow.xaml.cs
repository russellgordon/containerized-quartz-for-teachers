using System;
using System.Collections.Generic;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Plantoir.Core.Models;
using Plantoir.Services;
using Windows.System;

namespace Plantoir.Views;

/// <summary>
/// A conversation about one section, in a window of its own.
///
/// Its own window rather than a pane, because of what the teacher needs to be
/// doing while it runs: looking at the preview of the very section being
/// changed. A pane inside the main window would put the conversation and the
/// thing it is about in competition for the same screen.
///
/// The safety story is not implemented here — it is inherited. The window
/// drives <see cref="AssistAgent"/>, which drives the same
/// <c>plantoir-mcp</c> that Claude Code drives, so the plan-before-write rule,
/// the backups, the refusals and the course lock are the tools' behaviour and
/// not a second copy of it. What this window owns is the last step: showing
/// the teacher what is about to happen and waiting to be told yes.
/// </summary>
public sealed partial class AssistWindow : Window
{
    private readonly string _folder;
    private readonly Course _course;
    private readonly int _section;

    private readonly LocalModel _model = new();
    private McpClient? _tools;
    private AssistAgent? _agent;
    private readonly CancellationTokenSource _closing = new();

    public AssistWindow(string workspacePath, Course course, int section)
    {
        InitializeComponent();
        _folder = workspacePath;
        _course = course;
        _section = section;

        Title = $"Revise {course.Code} Section {section}";
        Heading.Text = $"Revising {course.Code} Section {section}";
        Subheading.Text = "Ask for a change in plain words. Nothing is written until you say so, " +
                          "and nothing reaches students until you deploy the section yourself.";

        Closed += (_, _) => Shutdown();

        // Started on Loaded, not here: the download offer is a ContentDialog,
        // and a dialog needs a XamlRoot, which does not exist until the
        // window's content has actually been loaded. Raised once.
        Root.Loaded += OnceLoaded;
    }

    private void OnceLoaded(object sender, RoutedEventArgs e)
    {
        Root.Loaded -= OnceLoaded;
        _ = Begin();
    }

    // ---- Starting up -----------------------------------------------------

    /// <summary>
    /// Get the assistant to the point where it can answer: the model running,
    /// the tools connected, and the teacher told what those two words mean.
    ///
    /// Each step reports failure in the teacher's terms and stops. A half
    /// started session that accepts typing and cannot act on it would be worse
    /// than one that plainly says it is not available.
    /// </summary>
    private async Task Begin()
    {
        if (ClaudeCodeLauncher.FindServer() is not { } server)
        {
            Say("Plantoir", "The Plantoir tools couldn’t be found, so there is nothing for the " +
                            "assistant to work with. Reinstalling Plantoir should put them back.");
            return;
        }

        if (!_model.IsInstalled())
        {
            // The one download, and the one place a teacher gets to refuse it.
            var offer = new ContentDialog
            {
                Title = "Download the assistant?",
                Content = "The assistant runs on this computer — nothing you write is sent anywhere. " +
                          "It needs a one-time download of about 1.1 GB, and then it works offline.",
                PrimaryButtonText = "Download",
                CloseButtonText = "Not now",
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = Root.XamlRoot,
            };
            if (await offer.ShowAsync() != ContentDialogResult.Primary)
            {
                Say("Plantoir", "No assistant, then — close this window whenever you like.");
                return;
            }

            var note = SayWithBar("Plantoir", "Downloading the assistant…");

            // Reports are POSTED to this thread, so one can still be in the
            // queue when the download finishes — and it would land after the
            // closing message and overwrite it with a stale byte count. The
            // flag makes anything arriving after the end a no-op.
            bool finished = false;
            var progress = new Progress<LocalModel.Fetching>(state =>
            {
                if (finished) return;
                note.Text.Text = state.Describe();
                // An unknown total leaves the bar sweeping rather than sitting
                // at zero, which reads as stuck.
                note.Bar.IsIndeterminate = !state.Known;
                if (state.Known) note.Bar.Value = state.Percent;
            });

            bool installed = await _model.Install(progress, _closing.Token);
            finished = true;
            note.Bar.Visibility = Visibility.Collapsed;
            if (!installed)
            {
                note.Text.Text = "The download didn’t finish. Check the network and try opening this window again.";
                return;
            }
            note.Text.Text = "The assistant is downloaded.";
        }

        var starting = Say("Plantoir", "Starting the assistant…");
        if (!await _model.Start(new Progress<string>(line => starting.Text = line), _closing.Token))
        {
            starting.Text = "The assistant wouldn’t start. If Docker or WSL was just installed or updated, " +
                            "restarting this computer usually settles it.";
            return;
        }

        _tools = await McpClient.Start(server, _folder, _course.Code, _closing.Token);
        if (_tools is null)
        {
            starting.Text = "The assistant started, but Plantoir’s tools didn’t answer. Try opening this window again.";
            return;
        }

        var schemas = await _tools.Tools(_closing.Token);
        _agent = new AssistAgent(_model, _tools, schemas, _course.Code, _section);
        starting.Text = "Ready.";

        // The briefing is fetched from the tool DIRECTLY, with no model in the
        // loop. It used to be a conversational turn, and that turn was the
        // slowest thing in the session: the 22 tool definitions come to some
        // 6,200 tokens, and at the 21 tokens/second this hardware manages that
        // is five minutes of prompt evaluation before the teacher sees a word.
        // Nothing about it needed a model — the text is fixed, and the tool
        // already decides whether this section has heard it.
        string briefing = await _tools.CallTool("explain_publishing", new JsonObject
        {
            ["course"] = _course.Code,
            ["section"] = _section,
        }, _closing.Token);
        if (briefing.Trim().Length > 0) Say("Plantoir", briefing.Trim());

        // Typing is available from here. The teacher reads the briefing while
        // the model quietly evaluates that same 6,200-token prefix in the
        // background; llama.cpp caches it, so their first real question pays
        // only for the sentence they typed. Waiting once per session was
        // always the plan — this puts the wait somewhere it costs nothing.
        Input.IsEnabled = true;
        SendButton.IsEnabled = true;
        Input.Focus(FocusState.Programmatic);
        _ = WarmUp(schemas);
    }

    /// <summary>
    /// Make the model read the tool definitions once, in its own time.
    ///
    /// llama.cpp caches the prompt prefix, and every turn in this window shares
    /// the same one: the system prompt and the 22 tool schemas. Paying for it
    /// here, while the teacher is reading the briefing, is the difference
    /// between a five-minute wait on their first question and a few seconds.
    ///
    /// Failure is ignored on purpose. Nothing depends on this — if it does not
    /// finish, or the model is not ready, the teacher's own request simply pays
    /// the cost it would have paid anyway.
    /// </summary>
    private async Task WarmUp(JsonArray schemas)
    {
        try
        {
            var priming = new JsonArray
            {
                new JsonObject { ["role"] = "user", ["content"] = "Say ready." },
            };
            await _model.Ask(priming, schemas, _closing.Token);
        }
        catch { /* a cold cache is slow, not broken */ }
    }

    // ---- One turn --------------------------------------------------------

    private async void Send_Click(object sender, RoutedEventArgs e) => await SendWhatIsTyped();

    private async void Input_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key != VirtualKey.Enter) return;
        e.Handled = true;
        await SendWhatIsTyped();
    }

    private async Task SendWhatIsTyped()
    {
        if (_agent is null) return;
        string said = Input.Text.Trim();
        if (said.Length == 0) return;

        Input.Text = "";
        Say("You", said);
        await Turn(() => _agent.Say(said, _closing.Token));
    }

    private async void Approve_Click(object sender, RoutedEventArgs e)
    {
        if (_agent is null) return;
        HideApproval();
        Say("You", "Go ahead.");
        await Turn(() => _agent.Approve(_closing.Token));
    }

    private async void Decline_Click(object sender, RoutedEventArgs e)
    {
        if (_agent is null) return;
        HideApproval();
        Say("You", "No.");
        await Turn(() => _agent.Decline(_closing.Token));
    }

    /// <summary>
    /// Run one exchange and put it on screen.
    ///
    /// The input is disabled throughout — not for tidiness, but because a
    /// second request arriving mid-turn would interleave two conversations
    /// through one set of tools against one course.
    /// </summary>
    private async Task Turn(Func<Task<List<AssistAgent.Line>>> exchange)
    {
        Input.IsEnabled = false;
        SendButton.IsEnabled = false;
        try
        {
            foreach (var line in await exchange())
            {
                Say(Speaker(line.Speaker), line.Text);
                if (line.NeedsApproval) ShowApproval(line.Text);
            }
        }
        catch (OperationCanceledException) { /* the window is closing */ }
        catch (Exception error)
        {
            Say("Plantoir", $"Something went wrong there: {error.Message}");
        }
        finally
        {
            // Never re-enable typing under a question that is still waiting —
            // the answer to "shall I go ahead?" is a button, not a sentence.
            bool waiting = _agent?.IsAwaitingApproval == true;
            Input.IsEnabled = _agent is not null && !waiting;
            SendButton.IsEnabled = Input.IsEnabled;
            if (Input.IsEnabled) Input.Focus(FocusState.Programmatic);
        }
    }

    private static string Speaker(string raw) => raw switch
    {
        "assistant" => "Assistant",
        "tools" => "Plantoir",
        _ => raw,
    };

    // ---- The transcript --------------------------------------------------

    /// <summary>Add a turn and scroll to it. Returns its text block so slow work can update in place.</summary>
    private TextBlock Say(string speaker, string text)
    {
        var body = new TextBlock { TextWrapping = TextWrapping.Wrap, IsTextSelectionEnabled = true };
        Write(body, text);
        AddCard(speaker, body);
        return body;
    }

    /// <summary>
    /// Put text on a TextBlock with <c>**bold**</c> actually bold.
    ///
    /// The tools write for a Markdown reader — the briefing emphasises the two
    /// words it exists to distinguish, and the approval line emphasises the
    /// tool about to run. Setting <c>.Text</c> renders the asterisks literally,
    /// so the one visual cue in the most important sentence in the window was
    /// showing up as punctuation.
    ///
    /// This is not a Markdown parser and should not become one. It handles the
    /// one construct the tools actually emit; anything else is left exactly as
    /// written, which for a teacher's own page titles is the safer failure.
    /// </summary>
    private static void Write(TextBlock block, string text)
    {
        block.Inlines.Clear();

        string[] lines = text.Replace("\r\n", "\n").Split('\n');
        for (int line = 0; line < lines.Length; line++)
        {
            if (line > 0) block.Inlines.Add(new LineBreak());

            // Odd-numbered pieces sit between a pair of markers, so they are
            // the emphasised ones. An unpaired marker leaves a final piece with
            // an even index, and it stays plain — text, not an error.
            string[] pieces = lines[line].Split("**");
            for (int piece = 0; piece < pieces.Length; piece++)
            {
                if (pieces[piece].Length == 0) continue;
                bool emphasised = piece % 2 == 1 && piece < pieces.Length - 1;
                block.Inlines.Add(new Run
                {
                    Text = pieces[piece],
                    FontWeight = emphasised ? FontWeights.SemiBold : FontWeights.Normal,
                });
            }
        }
    }

    /// <summary>The one place a turn is built, so every card is the same card.</summary>
    private void AddCard(string speaker, params UIElement[] contents)
    {
        var panel = new StackPanel { Spacing = 4 };
        panel.Children.Add(new TextBlock
        {
            Text = speaker,
            Opacity = 0.7,
            Style = (Style)Application.Current.Resources["CaptionTextBlockStyle"],
        });
        foreach (var element in contents) panel.Children.Add(element);

        Transcript.Children.Add(new Border
        {
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(6),
            Background = (Brush)Application.Current.Resources[
                speaker == "You" ? "SystemFillColorAttentionBackgroundBrush" : "CardBackgroundFillColorDefaultBrush"],
            Child = panel,
        });
        TranscriptScroller.UpdateLayout();
        TranscriptScroller.ChangeView(null, TranscriptScroller.ScrollableHeight, null);
    }

    /// <summary>A turn that carries a progress bar as well as words.</summary>
    private sealed record Reporting(TextBlock Text, ProgressBar Bar);

    /// <summary>
    /// Say something that will take a while, with a bar under it.
    ///
    /// The bar is added to a panel this method built and still holds, rather
    /// than to whatever <c>body.Parent</c> reports. Parent is a visual-tree
    /// property and is not reliably set the instant an element is put in a
    /// Children collection, so the first attempt silently added the bar to
    /// nothing at all: the download ran with no bar on screen, which is the
    /// very thing it was there to show.
    ///
    /// It starts indeterminate. The total arrives from the server a moment
    /// after the download begins, and a determinate bar pinned at zero in the
    /// meantime is exactly what "frozen" looks like.
    /// </summary>
    private Reporting SayWithBar(string speaker, string text)
    {
        var body = new TextBlock { Text = text, TextWrapping = TextWrapping.Wrap, IsTextSelectionEnabled = true };
        var bar = new ProgressBar
        {
            IsIndeterminate = true,
            Minimum = 0,
            Maximum = 100,
            Margin = new Thickness(0, 8, 0, 0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        AddCard(speaker, body, bar);
        return new Reporting(body, bar);
    }

    private void ShowApproval(string question)
    {
        // The tool's name is emphasised in this sentence, and this is the
        // sentence the teacher is answering yes or no to.
        Write(ApprovalText, question);
        ApprovalBar.Visibility = Visibility.Visible;
    }

    private void HideApproval() => ApprovalBar.Visibility = Visibility.Collapsed;

    // ---- Ending ----------------------------------------------------------

    /// <summary>
    /// Closing the window ends the session, and ending the session must give
    /// the machine its memory back and the course its freedom back: the model
    /// container stops, and the server exits, which drops the assist lease
    /// that has been holding Preview and Deploy off this course.
    /// </summary>
    private void Shutdown()
    {
        try { _closing.Cancel(); } catch { }
        _ = Task.Run(async () =>
        {
            if (_tools is not null) await _tools.DisposeAsync();
            _model.Stop();
        });
    }
}
