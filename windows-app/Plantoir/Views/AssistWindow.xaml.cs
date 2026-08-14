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
using Plantoir.Core.Assist;
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
    private readonly MainWindow? _main;

    private readonly LocalModel _model = new();
    private McpClient? _tools;
    private AssistAgent? _agent;
    private readonly CancellationTokenSource _closing = new();

    public AssistWindow(string workspacePath, Course course, int section, MainWindow? main = null)
    {
        InitializeComponent();
        _folder = workspacePath;
        _course = course;
        _section = section;
        _main = main;

        // The prompt cache is per course and section, because the prefix it
        // holds is — see LocalModel.CacheIdentity.
        _model.CacheIdentity = $"{course.Code.ToLowerInvariant()}-s{section}";

        Title = $"Revise {course.Code} Section {section}";
        Heading.Text = $"Revising {course.Code} Section {section}";
        Subheading.Text = "Ask for a change in plain words. Every change is backed up and can be undone, " +
                          "and nothing reaches students until the section deploys — which always waits for your OK.";

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

        // Narrowed before the model ever sees them — see AssistAgent for the
        // measurements. Fewer tools is both better routing and a shorter
        // prompt, and the prompt is what makes the first answer slow.
        var schemas = AssistAgent.NarrowToLocal(await _tools.Tools(_closing.Token), _course.Code);

        // The cache file is named for the exact prefix — schemas and system
        // prompt — so an app update that changes either retires the old cache
        // instead of restoring a prefix no conversation will match.
        _model.StampCacheWith(schemas, AssistAgent.SystemPrompt(_course.Code, _section));

        _agent = new AssistAgent(_model, _tools, schemas, _course.Code, _section)
        {
            // A tool that narrates gets its words on the thinking indicator,
            // where "Thinking" alone would be a lie minutes long.
            OnToolProgress = NoteToolProgress,
            // Building and deploying automate the main window's own flows —
            // once, on screen — rather than running again behind the chat.
            ShowPreviewInApp = () => _main?.ShowPreviewFor(_course.Code, _section),
            StartDeployInApp = () => _main?.DeployFor(_course.Code, _section),
        };

        // NOT "Ready." — it is not. Reading the instructions takes minutes on
        // a cold cache, and a teacher told "Ready" who then waits three of them
        // has been misled by the one line that was supposed to orient them.
        // The warm-up card below says Ready, when it is.
        starting.Text = "Started.";

        // The briefing, EVERY time this window opens, and taken straight from
        // the words rather than through the tool.
        //
        // Two reasons. The tool answers a returning section with "this has
        // been explained already — don't repeat it, carry on with what the
        // teacher asked", which is an instruction addressed to a MODEL; a
        // teacher was being shown it, and it reads as the assistant talking
        // about them rather than to them.
        //
        // And once per section turned out to be too rare. These two words
        // decide whether "published" means students can see it, and a teacher
        // opening this window a month later has every reason to want the
        // reminder. It is four sentences at the top of a window they chose to
        // open, not an interruption. The once-per-section machinery stays for
        // Claude Code, where an assistant re-explaining itself mid-conversation
        // genuinely is one.
        Say("Plantoir", Briefing.Words(_course.Code, _section, AssistWorkspace.DestinationOf(_course)));

        // What to say, in the words that work.
        //
        // A small model matches text; it does not infer intent. So rather than
        // leaving a teacher to discover which phrasings land — and the first
        // real use of this window opened with "Hello, what is your name?",
        // which is the one question it can only answer slowly and unhelpfully
        // — the examples are put in front of them before they type. These are
        // the shapes the routing was measured on.
        Say("Plantoir", ExampleRequests);

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
        // A cache from a previous session, if there is one — this is what turns
        // three minutes per session into three minutes once. Believed only when
        // the restore says it restored something: the wording below promises a
        // short wait, and a failed restore behind "picking up where I left off"
        // would deliver the three minutes unannounced.
        bool warmAlready = await Task.Run(() => _model.RestorePrefix(), _closing.Token);

        var note = SayWithBar("Plantoir",
            warmAlready
                ? "Picking up where I left off…"
                : "Reading my instructions — this happens once, and takes a few minutes…");
        var started = DateTime.Now;

        // How long this should take, from the size of what it has to read.
        //
        // PROJECTED from elapsed time rather than read from the model, because
        // the model barely reports it: llama.cpp logs progress once per
        // completed batch, and measured against a prompt this size that meant
        // nothing at all for 81 seconds, a single reading of 32%, then silence
        // until the answer arrived. A bar driven by that would sit at zero,
        // jump a third of the way, and freeze — which is worse than no bar,
        // because it looks like something broke.
        //
        // So the estimate is arithmetic on two measured numbers: roughly 3.6
        // characters per token, and roughly 21 tokens a second on two CPU
        // cores. When a real reading DOES turn up it wins, so the bar is
        // corrected by the truth whenever the truth is available.
        double tokens = schemas.ToJsonString().Length / 3.6;
        // After a restore the model reads a sentence, not the surface: measured
        // at about twelve seconds against 175 for the same turn cold.
        double expected = warmAlready ? 15 : Math.Max(20, tokens / 21.0);

        // The agent's OWN opening messages, so the prefix warmed here is the
        // prefix every later turn actually starts with. Priming a different
        // shape warms nothing.
        var warming = _model.Ask(_agent!.PrimingMessages(), schemas, _closing.Token);
        bool warmed = false;

        try
        {
            while (!warming.IsCompleted)
            {
                try { await Task.Delay(1000, _closing.Token).ConfigureAwait(true); }
                catch (OperationCanceledException) { break; }

                int elapsed = (int)(DateTime.Now - started).TotalSeconds;
                var reported = await Task.Run(() => _model.PromptProgress(), _closing.Token);

                // Never quite reaches the end on the estimate alone: finishing
                // is what the disappearing bar says, not 100% sitting there.
                double fraction = Math.Min(0.97, elapsed / expected);
                if (reported is { } real && real > fraction) fraction = Math.Min(0.99, real);

                note.Bar.IsIndeterminate = false;
                note.Bar.Value = fraction * 100;

                int left = Math.Max(0, (int)expected - elapsed);
                note.Text.Text = left > 0
                    ? $"Reading my instructions — {fraction * 100:0}%. " +
                      $"{Spent(elapsed)} so far, about {Spent(left)} to go. " +
                      "This happens once; after it, answers are quick."
                    : $"Reading my instructions — nearly there. {Spent(elapsed)} so far.";
            }

            warmed = await warming is not null;
        }
        catch { /* a cold cache is slow, not broken */ }
        finally
        {
            note.Bar.Visibility = Visibility.Collapsed;

            if (warmed)
            {
                note.Text.Text = "Ready — ask me for a change whenever you like.";

                // Keep the cache, so the next session starts warm rather than
                // spending another three minutes on the same instructions.
                // Only after a warm-up that finished: saving a slot that never
                // read the prefix writes an empty file that the next session
                // would mistake for a warm start.
                if (!_closing.IsCancellationRequested)
                    _ = Task.Run(() => _model.SavePrefix());
            }
            else if (!_closing.IsCancellationRequested)
            {
                // Saying "Ready" here misled a teacher once already: the model
                // had died mid-warm-up, and Ready was followed by silence.
                note.Text.Text = "The warm-up didn’t finish. You can still ask — the first " +
                                 "answer may take a few minutes while I read my instructions.";
            }
        }
    }

    /// <summary>A duration a person would say out loud.</summary>
    private static string Spent(int seconds)
    {
        if (seconds < 0) seconds = 0;
        if (seconds < 60) return $"{seconds}s";
        int minutes = seconds / 60;
        int rest = seconds % 60;
        return rest == 0 ? $"{minutes}m" : $"{minutes}m {rest}s";
    }

    /// <summary>
    /// The opening menu, in the teacher's own words.
    ///
    /// Deliberately phrased as things to SAY rather than features to have.
    /// Each line is a shape the local model routes reliably, and naming the
    /// page ("Unit 2, Day 3") is what keeps it from having to guess — so the
    /// examples all show it.
    /// </summary>
    private const string ExampleRequests =
        "Here's what I'm good at. These wordings work well — copy one and change the details:\n\n" +
        "**Publishing a class**\n" +
        "  • Publish Unit 2, Day 3, and everything it links to\n" +
        "  • Publish tomorrow's class\n\n" +
        "**Taking something back down**\n" +
        "  • Unpublish Unit 2, Day 3\n" +
        "  • I published Unit 4, Day 1 by mistake — unpublish it\n\n" +
        "**Looking before you leap**\n" +
        "  • What would publishing Unit 3, Day 1 change?\n" +
        "  • What would students see in this section right now?\n\n" +
        "**Afterwards**\n" +
        "  • Rebuild the preview\n" +
        "  • Undo that\n\n" +
        "**Putting it in front of students**\n" +
        "  • Deploy this section now\n" +
        "  • Deploy tomorrow's class at 6:30 AM\n" +
        "  • Cancel that scheduled deploy\n\n" +
        "Deploying is the one that students actually notice, so I'll always ask you to look at the " +
        "preview first — and you press the button, not me.\n\n" +
        "Name the page if you can — “Unit 2, Day 3” rather than “tomorrow's one” — and I'll be quicker " +
        "and more certain. Bigger jobs — re-dating a term, rolling a course over, adding a unit's worth " +
        "of pages — are beyond me, and want one of the more capable assistants in the same right-click " +
        "menu.";

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
        ShowThinking();
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
            HideThinking();
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

    /// <summary>
    /// The one place a turn is built, so every bubble is the same bubble.
    ///
    /// Laid out the way every messaging app a teacher already uses lays it
    /// out: what they said on the right, what the assistant said on the left.
    /// Nobody has to learn that, and at a glance down the transcript the two
    /// voices separate without reading a word of it.
    ///
    /// Bubbles stop well short of the full width. A line of text running the
    /// whole way across a maximised window is hard to read and, worse here,
    /// makes the two sides indistinguishable — which is the one thing this
    /// layout exists to prevent.
    /// </summary>
    private void AddCard(string speaker, params UIElement[] contents)
    {
        bool fromTeacher = speaker == "You";

        var panel = new StackPanel { Spacing = 4 };
        panel.Children.Add(new TextBlock
        {
            Text = speaker,
            Opacity = 0.7,
            Style = (Style)Application.Current.Resources["CaptionTextBlockStyle"],
        });
        foreach (var element in contents) panel.Children.Add(element);

        // The teacher's bubble is filled with the accent colour, so its text
        // has to be the ON-accent one. Left as the default it is dark ink on a
        // dark blue ground in the light theme — unreadable, and only in the
        // half of the conversation they wrote themselves.
        if (fromTeacher)
        {
            var onAccent = (Brush)Application.Current.Resources["TextOnAccentFillColorPrimaryBrush"];
            foreach (var child in panel.Children)
                if (child is TextBlock block) block.Foreground = onAccent;
        }

        Transcript.Children.Add(new Border
        {
            Padding = new Thickness(12),
            // The tail corner is squared off on the side the bubble comes
            // from, which is what gives a chat its direction.
            CornerRadius = fromTeacher
                ? new CornerRadius(12, 12, 4, 12)
                : new CornerRadius(12, 12, 12, 4),
            HorizontalAlignment = fromTeacher ? HorizontalAlignment.Right : HorizontalAlignment.Left,
            MaxWidth = 620,
            Background = (Brush)Application.Current.Resources[
                fromTeacher ? "AccentFillColorDefaultBrush" : "CardBackgroundFillColorDefaultBrush"],
            Child = panel,
        });
        TranscriptScroller.UpdateLayout();
        TranscriptScroller.ChangeView(null, TranscriptScroller.ScrollableHeight, null);
    }

    // ---- "It is still thinking" -------------------------------------------

    private Border? _thinking;
    private TextBlock? _thinkingLabel;
    private DispatcherTimer? _tick;
    private DateTime _thinkingSince;

    /// <summary>
    /// Put a running tool's own words on the thinking indicator.
    ///
    /// "Thinking" is the right label while the model is choosing; it is the
    /// wrong one for the minutes a rebuild can spend recreating its container
    /// and reinstalling the toolchain. The toolchain narrates those minutes
    /// in plain words, the server relays them, and this shows them — so the
    /// teacher reads "Building the section…" with a climbing count instead of
    /// deciding the window is stuck. Called from whatever thread the tool's
    /// reply arrives on, hence the dispatch.
    /// </summary>
    private void NoteToolProgress(string message)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            if (_thinkingLabel is not null) _thinkingLabel.Text = message;
        });
    }

    /// <summary>
    /// Show that the assistant is working, and for how long.
    ///
    /// Without this the window sits perfectly still while the model chews
    /// through a six-thousand-token prompt at twenty-one tokens a second,
    /// which on the first question of a session is minutes. Silence and a
    /// crash look identical, and a teacher who cannot tell them apart will
    /// reasonably close the window.
    ///
    /// The elapsed count is deliberate rather than decorative. Animated dots
    /// alone say "something is happening"; a number climbing past thirty
    /// seconds also says "this one is slow, and it is not stuck", which is the
    /// honest description of a first answer on two CPU cores.
    /// </summary>
    private void ShowThinking()
    {
        HideThinking();
        _thinkingSince = DateTime.Now;

        var label = new TextBlock { Text = "Thinking", Opacity = 0.8, TextWrapping = TextWrapping.Wrap };
        _thinkingLabel = label;
        var dots = new TextBlock { Text = "", Opacity = 0.8, MinWidth = 24 };
        var elapsed = new TextBlock { Text = "", Opacity = 0.55 };

        var row = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 2 };
        row.Children.Add(label);
        row.Children.Add(dots);
        row.Children.Add(elapsed);

        // Left, like everything else the assistant says — it IS the assistant
        // speaking, and a centred or full-width indicator would break the line
        // the eye follows down the conversation.
        _thinking = new Border
        {
            Padding = new Thickness(12),
            CornerRadius = new CornerRadius(12, 12, 12, 4),
            HorizontalAlignment = HorizontalAlignment.Left,
            Background = (Brush)Application.Current.Resources["CardBackgroundFillColorDefaultBrush"],
            Child = row,
        };
        Transcript.Children.Add(_thinking);
        TranscriptScroller.UpdateLayout();
        TranscriptScroller.ChangeView(null, TranscriptScroller.ScrollableHeight, null);

        int step = 0;
        _tick = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(400) };
        _tick.Tick += (_, _) =>
        {
            step++;
            dots.Text = new string('.', step % 4);
            int seconds = (int)(DateTime.Now - _thinkingSince).TotalSeconds;
            // Quiet for the first few seconds; a stopwatch on every quick
            // answer would make the app feel slower than it is.
            elapsed.Text = seconds >= 5 ? $"  {seconds}s" : "";
        };
        _tick.Start();
    }

    private void HideThinking()
    {
        _tick?.Stop();
        _tick = null;
        if (_thinking is not null) Transcript.Children.Remove(_thinking);
        _thinking = null;
        _thinkingLabel = null;
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

        // WAITED ON, not fired and forgotten. The old version started this on
        // a background task and returned, so closing the window — or closing
        // Plantoir straight after — could end the process before the container
        // was removed and the WSL keepalive released. Two conversations left
        // four keepalives behind that way.
        //
        // Bounded, because a shutdown that hangs is worse than one that leaks:
        // if Docker is wedged, the keepalive now ends by itself anyway.
        var cleanup = Task.Run(async () =>
        {
            if (_tools is not null) await _tools.DisposeAsync();
            _model.Stop();
        });
        try { cleanup.Wait(TimeSpan.FromSeconds(8)); } catch { }
    }
}
