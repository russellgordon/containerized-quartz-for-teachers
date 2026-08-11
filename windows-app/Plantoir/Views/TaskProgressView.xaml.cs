using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Plantoir.Core.Scripting;
using Windows.System;
using Windows.UI;

namespace Plantoir.Views;

/// <summary>
/// Layered progress: a determinate bar with milestone labels by default, the
/// raw output one click away behind "Show details", questions asked in a
/// native dialog, and outcomes that distinguish Done / Stopped / Cancelled /
/// failed-with-explanation.
/// </summary>
public sealed partial class TaskProgressView : UserControl
{
    private readonly System.Collections.Generic.List<ScriptRunner> _registered = new();
    private ScriptRunner? _runner;
    private string _title = "";
    private bool _detailsOpen;
    private bool _questionDialogShowing;
    private long _renderedTranscriptVersion = -1;

    public TaskProgressView() => InitializeComponent();

    /// <summary>
    /// Subscribe to a runner ONCE. Its question dialog fires whenever this
    /// runner awaits input — even when it is not the runner currently shown,
    /// so a background deploy's prompt is never missed.
    /// </summary>
    public void Register(ScriptRunner runner)
    {
        if (_registered.Contains(runner)) return;
        _registered.Add(runner);
        runner.PropertyChanged += (sender, e) => RunnerChanged((ScriptRunner)sender!, e);
    }

    /// <summary>Choose which registered runner the panel displays.</summary>
    public void Show(ScriptRunner runner, string title)
    {
        Register(runner);
        if (!ReferenceEquals(_runner, runner)) _renderedTranscriptVersion = -1;
        _runner = runner;
        _title = title;
        Render();
    }

    /// <summary>Single-runner callers (the wizard) register-and-show in one call.</summary>
    public void Bind(ScriptRunner runner, string title) => Show(runner, title);

    private void RunnerChanged(ScriptRunner runner, System.ComponentModel.PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(ScriptRunner.IsAwaitingInput) && runner.IsAwaitingInput)
            _ = AskQuestion(runner);
        if (e.PropertyName == nameof(ScriptRunner.LastExitCode) && !runner.IsRunning
            && ReferenceEquals(runner, _runner))
            AutoExpandOnUnexplainedFailure();
        if (ReferenceEquals(runner, _runner)) Render();
    }

    private void Render()
    {
        if (_runner is null) return;
        TitleText.Text = _title;

        bool hasMilestones = _runner.Milestones.Count > 0;
        if (_runner.IsRunning)
        {
            OutcomeIcon.Visibility = Visibility.Collapsed;
            PhaseText.Text = hasMilestones ? _runner.StepDescription : "Working…";
            Bar.IsIndeterminate = !hasMilestones;
            if (hasMilestones) Bar.Value = _runner.ProgressFraction * 100;
            Bar.Visibility = Visibility.Visible;
            string detail = _runner.StepDetail;
            MilestoneText.Text = detail.Length > 0
                ? $"{_runner.CurrentMilestoneLabel} {detail}"
                : _runner.CurrentMilestoneLabel;
            MilestoneText.Visibility = hasMilestones ? Visibility.Visible : Visibility.Collapsed;
            OutcomeDetail.Visibility = Visibility.Collapsed;
            LiveLink.Visibility = Visibility.Collapsed;
        }
        else if (_runner.LastExitCode is { } exitCode)
        {
            Bar.IsIndeterminate = false;
            Bar.Value = _runner.WasCancelled || _runner.WasStoppedByUser ? Bar.Value : 100;
            MilestoneText.Visibility = Visibility.Collapsed;
            // An ending the teacher asked for is not a fault.
            if (_runner.WasCancelled) Outcome("Cancelled", "", Caution(), $"{_title} was cancelled.");
            else if (_runner.WasStoppedByUser) Outcome("Stopped", "", Secondary(), null);
            else if (exitCode == 0) Outcome("Done", "", Success(), null);
            else Outcome("Something went wrong", "", Critical(), _runner.FailureExplanation);

            if (exitCode == 0 && !_runner.WasCancelled && _runner.PublishedSiteUrl is { } url)
            {
                LiveLink.Visibility = Visibility.Visible;
                LiveLinkButton.Content = url.AbsoluteUri;
                LiveLinkButton.NavigateUri = url;
            }
        }

        AwaitingNotice.Visibility = _runner.IsAwaitingInput ? Visibility.Visible : Visibility.Collapsed;
        LaunchProblemText.Text = _runner.LaunchProblem ?? "";
        LaunchProblemText.Visibility = _runner.LaunchProblem is null ? Visibility.Collapsed : Visibility.Visible;
        ConsoleInputRow.Visibility = _runner.IsRunning ? Visibility.Visible : Visibility.Collapsed;

        if (_detailsOpen && _runner.Transcript.Version != _renderedTranscriptVersion)
        {
            _renderedTranscriptVersion = _runner.Transcript.Version;
            string text = _runner.Transcript.DisplayText;
            ConsoleText.Text = text.Length == 0 ? "Starting…" : text;
            ConsoleScroll.UpdateLayout();
            ConsoleScroll.ChangeView(null, ConsoleScroll.ScrollableHeight, null, disableAnimation: true);
        }
    }

    private void Outcome(string label, string glyph, Brush brush, string? detail)
    {
        OutcomeIcon.Glyph = glyph;
        OutcomeIcon.Foreground = brush;
        OutcomeIcon.Visibility = Visibility.Visible;
        PhaseText.Text = label;
        PhaseText.Foreground = brush;
        OutcomeDetail.Text = detail ?? "";
        OutcomeDetail.Visibility = detail is null ? Visibility.Collapsed : Visibility.Visible;
    }

    private Brush Caution() => (Brush)Application.Current.Resources["SystemFillColorCautionBrush"];
    private Brush Critical() => (Brush)Application.Current.Resources["SystemFillColorCriticalBrush"];
    private Brush Success() => (Brush)Application.Current.Resources["SystemFillColorSuccessBrush"];
    private Brush Secondary() => (Brush)Application.Current.Resources["TextFillColorSecondaryBrush"];

    /// <summary>Only fall back to the raw output when the app has nothing better to say.</summary>
    private void AutoExpandOnUnexplainedFailure()
    {
        if (_runner is null || _runner.LastExitCode is not { } exitCode) return;
        if (exitCode != 0 && !_runner.WasCancelled && !_runner.WasStoppedByUser
            && _runner.FailureExplanation is null && !_detailsOpen)
            ToggleDetails(open: true);
    }

    // ---- Question dialog -------------------------------------------------

    private async System.Threading.Tasks.Task AskQuestion(ScriptRunner runner)
    {
        if (_questionDialogShowing || XamlRoot is null) return;
        _questionDialogShowing = true;
        try
        {
            var answerBox = new TextBox
            {
                Text = runner.SuggestedAnswer,   // agreeing is one keystroke
                PlaceholderText = "Your answer",
            };
            var panel = new StackPanel { Spacing = 12 };
            panel.Children.Add(new TextBlock { Text = runner.PendingQuestion, TextWrapping = TextWrapping.Wrap });
            panel.Children.Add(answerBox);
            var dialog = new ContentDialog
            {
                // Neutral title: a task may ask several questions in a row.
                Title = "Input required",
                Content = panel,
                PrimaryButtonText = "Send",
                CloseButtonText = "Cancel",
                DefaultButton = ContentDialogButton.Primary,
                XamlRoot = XamlRoot,
            };
            answerBox.Loaded += (_, _) => { answerBox.Focus(FocusState.Programmatic); answerBox.SelectAll(); };
            var result = await dialog.ShowAsync();
            if (result == ContentDialogResult.Primary) runner.SendLine(answerBox.Text);
            else runner.CancelPendingQuestion();   // the script's own clean-up runs
        }
        finally { _questionDialogShowing = false; }
    }

    // ---- Details disclosure ----------------------------------------------

    private void Disclosure_Click(object sender, RoutedEventArgs e) => ToggleDetails(!_detailsOpen);

    private void ToggleDetails(bool open)
    {
        _detailsOpen = open;
        ConsolePane.Visibility = open ? Visibility.Visible : Visibility.Collapsed;
        DisclosureChevron.Glyph = open ? "" : "";
        DisclosureLabel.Text = open ? "Hide details" : "Show details";
        _renderedTranscriptVersion = -1;
        Render();
    }

    private void ConsoleSend_Click(object sender, RoutedEventArgs e) => SendConsoleInput();

    private void ConsoleInput_KeyDown(object sender, Microsoft.UI.Xaml.Input.KeyRoutedEventArgs e)
    {
        if (e.Key == VirtualKey.Enter) { SendConsoleInput(); e.Handled = true; }
    }

    private void SendConsoleInput()
    {
        _runner?.SendLine(ConsoleInput.Text);
        ConsoleInput.Text = "";
    }

    private void ConsoleStop_Click(object sender, RoutedEventArgs e) => _runner?.Terminate();
}
