using System;
using System.Diagnostics;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Plantoir.Core.Assist;
using Plantoir.Core.Models;
using Plantoir.Core.Scripting;
using Plantoir.Services;

namespace Plantoir.Views;

/// <summary>
/// One section: preview it in an embedded browser, publish it, watch either
/// as a layered progress task. Created fresh per selection so runners and
/// leases never leak between sections.
/// </summary>
public sealed partial class SectionDetailView : UserControl
{
    private readonly MainWindow _window;
    private readonly Course _course;
    private readonly int _sectionNumber;
    private readonly ScriptRunner _previewRunner = new(SynchronizationContext.Current);
    private readonly ScriptRunner _deployRunner = new(SynchronizationContext.Current);
    private PreviewLeases.Lease? _lease;

    // The on-disk half of the same claims. In-memory leases are invisible to
    // the MCP server, which is a different process entirely.
    private IDisposable? _previewWork;
    private IDisposable? _publishWork;
    private IDisposable? _publishActivity;
    private Uri? _previewUrl;
    private Uri? _lastLoadedUrl;
    private bool _isWaitingForServer;
    private CancellationTokenSource? _serverWait;

    private bool IsBusy => _previewRunner.IsRunning || _deployRunner.IsRunning;
    private string TitleText => $"{_course.Code}-S{_sectionNumber}";

    public SectionDetailView(MainWindow window, Course course, int sectionNumber)
    {
        InitializeComponent();
        _window = window;
        _course = course;
        _sectionNumber = sectionNumber;
        SectionTitle.Text = TitleText;
        ObsidianButton.IsEnabled = FolderActions.ObsidianIsInstalled;

        // The empty-state invitation follows the course's publishing choice —
        // "to Netlify" would be wrong twice over for a folder-publishing course.
        NoPreviewDetail.Text = course.Configuration.DeploysToLocalFolder
            ? "Click Preview to build this section's website and see it here, or Publish to copy it to your publishing folder."
            : "Click Preview to build this section's website and see it here, or Publish to put it online.";

        // Each runner is bound to the progress view exactly once — its
        // question dialog and outcome states follow whichever runner the
        // view is currently showing, chosen in RefreshChrome via Show().
        Progress.Register(_previewRunner);
        Progress.Register(_deployRunner);
        _previewRunner.PropertyChanged += (_, _) => RefreshChrome();
        _deployRunner.PropertyChanged += (_, _) => RefreshChrome();
        Preview.NavigationCompleted += (_, _) => RefreshChrome();
        Unloaded += (_, _) => StopPreview();
        RefreshChrome();
    }

    // ---- Chrome state ----------------------------------------------------

    private void RefreshChrome()
    {
        bool previewShown = _previewUrl is not null;
        BackButton.IsEnabled = previewShown && Preview.CanGoBack;
        ForwardButton.IsEnabled = previewShown && Preview.CanGoForward;
        ReloadButton.IsEnabled = previewShown;
        BrowserButton.IsEnabled = previewShown;

        // An assistant working on this course holds the build output, so
        // neither building nor publishing can go ahead. This is the courtesy
        // half — the click itself is checked too, because a session can start
        // while these buttons are already on screen.
        bool assisted = _window.Workspace.WorkspacePath is { } folder &&
                        CourseActivity.IsAssisting(folder, _course.Code);
        DeployButton.IsEnabled = !IsBusy && !assisted;
        if (assisted)
            ToolTipService.SetToolTip(DeployButton, $"Available once you finish revising {_course.Code} with Claude");

        bool running = _previewRunner.IsRunning;
        PreviewLabel.Text = running ? "Stop Preview" : "Preview";
        PreviewIcon.Glyph = running ? Glyphs.Stop : Glyphs.Play;
        ToolTipService.SetToolTip(PreviewButton,
            running ? "Stop previewing this section"
            : assisted ? $"Available once you finish revising {_course.Code} with Claude"
            : "Preview this section's website");
        // Stopping a preview already under way is always allowed.
        PreviewButton.IsEnabled = running || (!IsBusy && !assisted);

        // Which task owns the console: the running one, else the most recent.
        // Bind ONCE per runner (in the constructor) and only swap which is
        // shown here — re-subscribing on every event could swallow the
        // IsAwaitingInput transition that raises the question dialog.
        bool showDeploy = !_previewRunner.IsRunning &&
            (_deployRunner.IsRunning ||
             (_deployRunner.StartedAt ?? DateTime.MinValue) > (_previewRunner.StartedAt ?? DateTime.MinValue));
        if (showDeploy)
            Progress.Show(_deployRunner, $"Publishing {TitleText}");
        else
            Progress.Show(_previewRunner,
                _previewRunner.IsRunning || _isWaitingForServer
                    ? $"Preparing the preview of {TitleText}"
                    : $"Preview of {TitleText}");

        bool anyOutput = _previewRunner.Transcript.Lines.Count > 0 || _deployRunner.Transcript.Lines.Count > 0
                         || _previewRunner.Transcript.CurrentLine.Length > 0;
        bool showConsole = _isWaitingForServer || IsBusy || anyOutput;
        Progress.Visibility = showConsole ? Visibility.Visible : Visibility.Collapsed;
        NoPreviewState.Visibility = showConsole ? Visibility.Collapsed : Visibility.Visible;
        Preview.Visibility = previewShown ? Visibility.Visible : Visibility.Collapsed;
    }

    // ---- Preview ---------------------------------------------------------

    /// <summary>Smoke-test entry: the same path the Preview button takes.</summary>
    public void StartPreviewForAutomation() => PreviewOrStop_Click(this, new RoutedEventArgs());

    /// <summary>Smoke-test entry: open the console details pane.</summary>
    public void ShowDetailsForAutomation() => Progress.ExpandDetailsForAutomation();

    /// <summary>Smoke-test entry: the same path the Deploy button takes.</summary>
    public void StartDeployForAutomation() => Deploy_Click(this, new RoutedEventArgs());

    /// <summary>
    /// Refuse to start a build while an assistant is working on this course.
    ///
    /// Checked at the CLICK, not just when the buttons were last drawn: a
    /// session can start at any moment from the sidebar, and the chrome only
    /// redraws when a runner or the browser says something. The disabled
    /// button is the courtesy; this is the guarantee.
    ///
    /// Both would otherwise build into
    /// <c>.merged_output/section&lt;N&gt;/</c>, which the build clears before
    /// writing — so the loser serves a half-written site, or publishes files
    /// the other just deleted.
    /// </summary>
    private async Task<bool> AnAssistantHasThisCourse()
    {
        if (_window.Workspace.WorkspacePath is not { } folder) return false;
        if (!CourseActivity.IsAssisting(folder, _course.Code)) return false;

        var dialog = new ContentDialog
        {
            Title = $"{_course.Code} is being revised with Claude",
            Content = "Building this section now would clash with what Claude is doing — " +
                      "both write to the same place. Finish in the Claude window, close it, " +
                      "then try again.",
            CloseButtonText = "OK",
            XamlRoot = XamlRoot,
        };
        await dialog.ShowAsync();
        RefreshChrome();
        return true;
    }

    private async void PreviewOrStop_Click(object sender, RoutedEventArgs e)
    {
        if (_previewRunner.IsRunning) { StopPreview(); return; }
        if (await AnAssistantHasThisCourse()) return;
        if (_window.Workspace.WorkspacePath is not { } workspacePath) return;

        try
        {
            _lease = PreviewLeases.Take(workspacePath, _course.Code, _sectionNumber);
            // Say so on disk as well as in memory: an assistant is a separate
            // process and cannot see the in-memory lease.
            _previewWork = WorkLease.Take(workspacePath, _course.Code, WorkLease.Previewing);
        }
        catch (PreviewLeases.LeaseRefusedException refusal)
        {
            var dialog = new ContentDialog
            {
                Title = "Cannot Preview Yet",
                Content = refusal.Message,
                CloseButtonText = "OK",
                XamlRoot = XamlRoot,
            };
            await dialog.ShowAsync();
            return;
        }

        _previewUrl = null;
        _lastLoadedUrl = null;
        _isWaitingForServer = true;
        _previewRunner.Milestones = TaskMilestones.Preview;
        _previewRunner.Run("preview.ps1",
            new[] { _course.Code, _sectionNumber.ToString(), "--port", _lease.Port.ToString() },
            workspacePath);
        RefreshChrome();
        await WaitForPreviewServer(_lease.Port);
    }

    /// <summary>
    /// Phase 1: never trust the port until THIS run announces its launch —
    /// a stale server from a previous preview answers first. Phase 2: poll
    /// until HTTP 200. Ten minutes total, because a first-ever build pulls
    /// the image and installs dependencies.
    /// </summary>
    private async Task WaitForPreviewServer(int containerPort)
    {
        _serverWait?.Cancel();
        var cancel = new CancellationTokenSource();
        _serverWait = cancel;
        Uri serverUrl = new($"http://127.0.0.1:{containerPort}/");
        const int budgetSeconds = 600;
        int elapsed = 0;

        try
        {
            while (elapsed < budgetSeconds)
            {
                if (cancel.IsCancellationRequested) return;
                if (!_previewRunner.IsRunning && _previewRunner.LastExitCode is not null)
                {
                    AbandonWait();
                    return;
                }
                if (_previewRunner.PreviewAddress is { } announced) serverUrl = announced;
                if (_previewRunner.Transcript.DisplayText.Contains("Launching Quartz preview")) break;
                await Task.Delay(1000);
                elapsed++;
            }

            using var client = new HttpClient { Timeout = TimeSpan.FromSeconds(2) };
            while (elapsed < budgetSeconds)
            {
                if (cancel.IsCancellationRequested) return;
                if (!_previewRunner.IsRunning && _previewRunner.LastExitCode is not null)
                {
                    AbandonWait();
                    return;
                }
                try
                {
                    var response = await client.GetAsync(serverUrl);
                    if (response.IsSuccessStatusCode)
                    {
                        _isWaitingForServer = false;
                        _previewUrl = serverUrl;
                        LoadIfNeeded(serverUrl);
                        RefreshChrome();
                        return;
                    }
                }
                catch { }
                await Task.Delay(1000);
                elapsed++;
            }
            _isWaitingForServer = false;
            RefreshChrome();
        }
        finally
        {
            if (_serverWait == cancel) _serverWait = null;
        }
    }

    private void AbandonWait()
    {
        _isWaitingForServer = false;
        ReleaseLease();
        RefreshChrome();
    }

    /// <summary>Interface updates must never yank the teacher back from a page they navigated to.</summary>
    private void LoadIfNeeded(Uri url)
    {
        if (_lastLoadedUrl == url) return;
        _lastLoadedUrl = url;
        Preview.Source = url;
    }

    private void StopPreview()
    {
        // Whenever a preview was actually running (or still building),
        // reclaim its container-side processes too — ending the host
        // launcher alone leaves the serve chain alive inside the container.
        bool hadPreview = _previewRunner.IsRunning || _isWaitingForServer || _previewUrl is not null;
        _serverWait?.Cancel();
        if (_previewRunner.IsRunning) _previewRunner.StopByUser();
        if (hadPreview && _window.Workspace.WorkspacePath is { } workspacePath)
            PreviewStopper.StopSectionProcesses(workspacePath, _course.Code, _sectionNumber);
        _previewUrl = null;
        _lastLoadedUrl = null;
        _isWaitingForServer = false;
        ReleaseLease();
        RefreshChrome();
    }

    private void ReleaseLease()
    {
        _previewWork?.Dispose();
        _previewWork = null;
        if (_lease is { } lease) PreviewLeases.Release(lease);
        _lease = null;
    }

    // ---- Deploy ----------------------------------------------------------

    private async void Deploy_Click(object sender, RoutedEventArgs e)
    {
        if (IsBusy) return;
        if (await AnAssistantHasThisCourse()) return;
        if (_window.Workspace.WorkspacePath is not { } workspacePath) return;

        // Folder publishing (rows 101–102): the save gate keeps the folder
        // valid, but a hand-edited config could still slip a bad one in —
        // decline plainly rather than let the launcher discover it.
        bool toFolder = _course.Configuration.DeploysToLocalFolder;
        string deployFolder = _course.Configuration.DeployFolderPath.Trim();
        if (toFolder && CourseConfiguration.DeployFolderProblem(deployFolder) is { } folderProblem)
        {
            var problemDialog = new ContentDialog
            {
                Title = "The publishing folder needs attention",
                Content = folderProblem + " Fix it in this course's settings, then publish again.",
                CloseButtonText = "OK",
                XamlRoot = XamlRoot,
            };
            await problemDialog.ShowAsync();
            return;
        }

        // Cloudflare needs the teacher's account, and the launcher's console
        // prompt for it can never be answered from here — so decline plainly
        // and point at the setting that fixes it.
        bool toCloudflare = _course.Configuration.DeploysToCloudflare;
        string cloudflareAccount = _window.Workspace.Settings.CloudflareAccountId.Trim();
        if (toCloudflare && CourseConfiguration.CloudflareAccountProblem(cloudflareAccount) is { } accountProblem)
        {
            var accountDialog = new ContentDialog
            {
                Title = "Cloudflare needs your Account ID",
                Content = accountProblem + " Add it in this course's settings, under Publishing, then publish again.",
                CloseButtonText = "OK",
                XamlRoot = XamlRoot,
            };
            await accountDialog.ShowAsync();
            return;
        }

        bool needsBuild = BuildFreshness.NeedsRebuild(_course, _sectionNumber);
        _deployRunner.Milestones = toFolder
            ? (needsBuild ? TaskMilestones.BuildAndDeployToFolder : TaskMilestones.DeployToFolder)
            : toCloudflare
                ? (needsBuild ? TaskMilestones.BuildAndDeployToCloudflare : TaskMilestones.DeployToCloudflare)
                : (needsBuild ? TaskMilestones.BuildAndDeploy : TaskMilestones.Deploy);
        string customDomain = CourseConfiguration.NormalizedCustomDomain(
            _course.Configuration.CustomDomain(_sectionNumber));
        _deployRunner.CustomDomainForLinks = customDomain.Length == 0 ? null : customDomain;

        // The publish is on the books for its WHOLE life — the quiet build
        // included — and comes off them on every exit path (EndPublish runs
        // from the runner-stopped transition in RefreshChrome).
        _publishActivity?.Dispose();
        _publishActivity = CourseActivity.BeginPublish(workspacePath, _course.Code, _sectionNumber);
        _publishWork = WorkLease.Take(workspacePath, _course.Code, WorkLease.Publishing);

        if (needsBuild)
        {
            // Build quietly first; a failed build stops before publishing —
            // the failure and its output are already on screen.
            _deployRunner.Run("preview.ps1",
                new[] { _course.Code, _sectionNumber.ToString(), "--build-only" }, workspacePath);
            RefreshChrome();
            if (!await _deployRunner.WaitUntilFinished()) { EndPublishActivity(); return; }
        }
        var deployArguments = toFolder
            ? new[] { _course.Code, _sectionNumber.ToString(), "--to-folder", deployFolder }
            : toCloudflare
                ? new[] { _course.Code, _sectionNumber.ToString(), "--target", "cloudflare", "--account", cloudflareAccount }
                : new[] { _course.Code, _sectionNumber.ToString() };
        _deployRunner.Run("deploy.ps1", deployArguments, workspacePath,
            keepTranscript: needsBuild);
        RefreshChrome();
        await _deployRunner.WaitUntilFinished();   // outcome already on screen
        EndPublishActivity();
    }

    private void EndPublishActivity()
    {
        _publishActivity?.Dispose();
        _publishActivity = null;
        _publishWork?.Dispose();
        _publishWork = null;
    }

    // ---- Browser chrome --------------------------------------------------

    private void Back_Click(object sender, RoutedEventArgs e) { if (Preview.CanGoBack) Preview.GoBack(); }
    private void Forward_Click(object sender, RoutedEventArgs e) { if (Preview.CanGoForward) Preview.GoForward(); }
    private void Reload_Click(object sender, RoutedEventArgs e) => Preview.Reload();

    private void ReloadAccelerator(Microsoft.UI.Xaml.Input.KeyboardAccelerator sender,
        Microsoft.UI.Xaml.Input.KeyboardAcceleratorInvokedEventArgs args)
    { if (_previewUrl is not null) { Preview.Reload(); args.Handled = true; } }

    private void BackAccelerator(Microsoft.UI.Xaml.Input.KeyboardAccelerator sender,
        Microsoft.UI.Xaml.Input.KeyboardAcceleratorInvokedEventArgs args)
    { if (Preview.CanGoBack) { Preview.GoBack(); args.Handled = true; } }

    private void ForwardAccelerator(Microsoft.UI.Xaml.Input.KeyboardAccelerator sender,
        Microsoft.UI.Xaml.Input.KeyboardAcceleratorInvokedEventArgs args)
    { if (Preview.CanGoForward) { Preview.GoForward(); args.Handled = true; } }

    private void OpenInBrowser_Click(object sender, RoutedEventArgs e)
    {
        // The page currently shown, not the site root; localhost is rewritten
        // to 127.0.0.1 (browsers try IPv6 first; the container is IPv4 only).
        Uri? current = Preview.Source ?? _previewUrl;
        if (current is null) return;
        var builder = new UriBuilder(current);
        if (builder.Host == "localhost") builder.Host = "127.0.0.1";
        try
        {
            Process.Start(new ProcessStartInfo(builder.Uri.AbsoluteUri) { UseShellExecute = true });
        }
        catch { }
    }

    private void Obsidian_Click(object sender, RoutedEventArgs e) =>
        _ = FolderActions.OpenInObsidian(_course.SectionDirectory(_sectionNumber), _course.DirectoryPath,
            BundledToolchain.SupportPath("obsidian_defaults/.obsidian"));
}
