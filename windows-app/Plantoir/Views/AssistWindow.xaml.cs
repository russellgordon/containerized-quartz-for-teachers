using System;
using System.Collections.Generic;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
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
            var progress = new Progress<LocalModel.Fetching>(state =>
            {
                note.Text.Text = state.Describe();
                // An unknown total leaves the bar sweeping rather than sitting
                // at zero, which reads as stuck.
                note.Bar.IsIndeterminate = !state.Known;
                if (state.Known) note.Bar.Value = state.Percent;
            });

            if (!await _model.Install(progress, _closing.Token))
            {
                note.Text.Text = "The download didn’t finish. Check the network and try opening this window again.";
                note.Bar.Visibility = Visibility.Collapsed;
                return;
            }
            note.Text.Text = "The assistant is downloaded.";
            note.Bar.Visibility = Visibility.Collapsed;
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

        Input.IsEnabled = true;
        SendButton.IsEnabled = true;
        Input.Focus(FocusState.Programmatic);

        // The briefing, before anything else — it is what makes "publish" and
        // "deploy" mean the same thing to both parties for the rest of the
        // conversation. The tool itself decides whether it is still needed.
        await Turn(() => _agent.Say(
            "Explain publishing for this section if that has not been done, then wait for me.",
            _closing.Token));
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
        var body = new TextBlock { Text = text, TextWrapping = TextWrapping.Wrap, IsTextSelectionEnabled = true };
        var card = new Border
        {
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(6),
            Background = (Brush)Application.Current.Resources[
                speaker == "You" ? "SystemFillColorAttentionBackgroundBrush" : "CardBackgroundFillColorDefaultBrush"],
            Child = new StackPanel
            {
                Spacing = 4,
                Children =
                {
                    new TextBlock
                    {
                        Text = speaker,
                        Opacity = 0.7,
                        Style = (Style)Application.Current.Resources["CaptionTextBlockStyle"],
                    },
                    body,
                },
            },
        };
        Transcript.Children.Add(card);
        TranscriptScroller.UpdateLayout();
        TranscriptScroller.ChangeView(null, TranscriptScroller.ScrollableHeight, null);
        return body;
    }

    /// <summary>A turn that carries a progress bar as well as words.</summary>
    private sealed record Reporting(TextBlock Text, ProgressBar Bar);

    /// <summary>
    /// Say something that will take a while, with a bar under it.
    ///
    /// The bar starts indeterminate: the total arrives from the server a moment
    /// after the download begins, and a determinate bar pinned at zero in the
    /// meantime is exactly what "frozen" looks like.
    /// </summary>
    private Reporting SayWithBar(string speaker, string text)
    {
        var body = Say(speaker, text);
        var bar = new ProgressBar
        {
            IsIndeterminate = true,
            Minimum = 0,
            Maximum = 100,
            Margin = new Thickness(0, 8, 0, 0),
            HorizontalAlignment = HorizontalAlignment.Stretch,
        };
        if (body.Parent is StackPanel panel) panel.Children.Add(bar);
        return new Reporting(body, bar);
    }

    private void ShowApproval(string question)
    {
        ApprovalText.Text = question;
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
