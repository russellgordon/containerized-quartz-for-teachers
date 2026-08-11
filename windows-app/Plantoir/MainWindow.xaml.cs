using System;
using System.IO;
using System.Linq;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Plantoir.Core.Models;
using Plantoir.Services;
using Plantoir.ViewModels;
using Plantoir.Views;
using Windows.Graphics;

namespace Plantoir;

public sealed partial class MainWindow : Window
{
    public WorkspaceViewModel Workspace { get; }

    /// <summary>The sidebar pane, reachable from sibling views.</summary>
    public Views.SidebarPane SidebarPane => Sidebar;

    public MainWindow(string? folderPath, RememberedWindow? frame)
    {
        InitializeComponent();
        Workspace = new WorkspaceViewModel(App.Settings);

        // Min 900×600, ideal 1100×720 — the bounded-ideal lesson from the
        // mac app carries over as a sensible default size.
        AppWindow.Resize(new SizeInt32(
            frame is { Width: > 200 } ? (int)frame.Width : 1100,
            frame is { Height: > 200 } ? (int)frame.Height : 720));
        if (frame is { } f && f.X > -10000 && f.Y > -10000)
            AppWindow.Move(new PointInt32((int)f.X, (int)f.Y));

        Picker.Attach(this);
        Sidebar.Attach(this);

        Activated += (_, args) =>
        {
            if (args.WindowActivationState != WindowActivationState.Deactivated)
                Workspace.NoteBecameKey();
        };
        Closed += (_, _) => Workspace.UnregisterWindow();

        Workspace.PropertyChanged += (_, args) =>
        {
            if (args.PropertyName is nameof(WorkspaceViewModel.State)
                or nameof(WorkspaceViewModel.WorkspacePath)
                or nameof(WorkspaceViewModel.WorkspaceProblem)) ApplyState();
            if (args.PropertyName is nameof(WorkspaceViewModel.Selection)
                or nameof(WorkspaceViewModel.Courses)) ShowDetailForSelection();
        };

        // Decide the folder BEFORE first paint so the picker never flashes.
        if (folderPath is not null && Directory.Exists(folderPath))
            Workspace.AdoptRestoredPath(folderPath);
        ApplyState();
        RunAutomationHooks();
    }

    /// <summary>
    /// Test hooks: "--auto-select CODE N" selects a section on launch;
    /// "--auto-preview" additionally presses Preview — the same code path
    /// as the button, so smoke tests exercise the real flow.
    /// </summary>
    private void RunAutomationHooks()
    {
        string[] args = Environment.GetCommandLineArgs();
        int index = Array.IndexOf(args, "--auto-select");
        if (index < 0) index = Array.IndexOf(args, "--auto-preview");
        if (index < 0 || index + 2 >= args.Length) return;
        string code = args[index + 1];
        if (!int.TryParse(args[index + 2], out int section)) return;
        bool preview = args.Contains("--auto-preview");
        DispatcherQueue.TryEnqueue(async () =>
        {
            await System.Threading.Tasks.Task.Delay(1500);
            Workspace.Selection = new SidebarSelection.SectionItem(code, section);
            if (preview && DetailHost.Content is SectionDetailView detail)
                detail.StartPreviewForAutomation();
        });
    }

    public RememberedWindow? RememberedEntry()
    {
        if (Workspace.WorkspacePath is null) return null;
        var position = AppWindow.Position;
        var size = AppWindow.Size;
        return new RememberedWindow(Workspace.WorkspacePath, position.X, position.Y, size.Width, size.Height);
    }

    // ---- State switching -------------------------------------------------

    public void ApplyState()
    {
        bool ready = Workspace.State == WorkspaceState.Ready && Workspace.WorkspaceProblem is null;
        Picker.Visibility = ready ? Visibility.Collapsed : Visibility.Visible;
        SplitView.Visibility = ready ? Visibility.Visible : Visibility.Collapsed;
        PathBar.Visibility = Workspace.WorkspacePath is null ? Visibility.Collapsed : Visibility.Visible;
        if (!ready) Picker.Refresh();
        else
        {
            Sidebar.Refresh();
            ShowDetailForSelection();
        }
        RefreshPathBar();
        RestoreFromArchiveItem.IsEnabled = Workspace.SelectedArchivedItem is not null;
        App.RememberOpenWindows();
    }

    private void RefreshPathBar()
    {
        if (Workspace.WorkspacePath is null) return;
        var parts = new System.Collections.Generic.List<string>();
        var directory = new DirectoryInfo(Workspace.WorkspacePath);
        for (var current = directory; current is not null; current = current.Parent)
            parts.Insert(0, current.FullName);
        FolderCrumbs.ItemsSource = parts.Select(p => new FolderCrumb(p)).ToList();
    }

    public sealed record FolderCrumb(string Path)
    {
        public override string ToString() =>
            System.IO.Path.GetFileName(Path.TrimEnd('\\')) is { Length: > 0 } name ? name : Path;
    }

    private void FolderCrumbs_ItemClicked(BreadcrumbBar sender, BreadcrumbBarItemClickedEventArgs args)
    {
        if (args.Item is FolderCrumb crumb) FolderActions.ShowInFileExplorer(crumb.Path);
    }

    // ---- Detail routing --------------------------------------------------

    public void ShowDetailForSelection()
    {
        RestoreFromArchiveItem.IsEnabled = Workspace.SelectedArchivedItem is not null;
        switch (Workspace.Selection)
        {
            case SidebarSelection.SectionItem(var code, var number)
                when Workspace.Courses.FirstOrDefault(c => c.Code == code) is { } course:
                // Fresh identity per selection: preview runners and local
                // state must never leak between sections.
                DetailHost.Content = new SectionDetailView(this, course, number);
                break;
            case SidebarSelection.CourseItem(var code)
                when Workspace.Courses.FirstOrDefault(c => c.Code == code) is { } course:
                DetailHost.Content = new CourseSettingsView(this, course);
                break;
            case SidebarSelection.ArchivedEntry(var id)
                when Workspace.ArchivedItems.FirstOrDefault(a => a.Id == id) is { } item:
                DetailHost.Content = EmptyState(item.Title,
                    $"{item.Subtitle}. It is not part of your courses until you restore it.",
                    "Restore…", () => Sidebar.ConfirmRestore(item));
                break;
            case null when Workspace.Courses.Count == 0:
                DetailHost.Content = EmptyState("No Courses Yet",
                    "Add your first course, or start from the example course to see how everything fits together.",
                    "Add a Course…", () => _ = SidebarPane.OpenNewCourseWizard());
                break;
            case null:
                DetailHost.Content = EmptyState("Select a Course or Section",
                    "Choose a course to edit its settings, or a section to preview and publish its website.",
                    null, null);
                break;
            default:
                DetailHost.Content = EmptyState("Course Not Found",
                    "Reload courses from the File menu, or choose a different working folder.", null, null);
                break;
        }
    }

    private static UIElement EmptyState(string title, string description, string? actionLabel, Action? action)
    {
        var panel = new StackPanel
        {
            HorizontalAlignment = HorizontalAlignment.Center,
            VerticalAlignment = VerticalAlignment.Center,
            Spacing = 8,
            MaxWidth = 460,
        };
        panel.Children.Add(new TextBlock
        {
            Text = title,
            FontSize = 22,
            FontWeight = Microsoft.UI.Text.FontWeights.SemiBold,
            HorizontalAlignment = HorizontalAlignment.Center,
        });
        panel.Children.Add(new TextBlock
        {
            Text = description,
            TextWrapping = TextWrapping.Wrap,
            TextAlignment = TextAlignment.Center,
            Opacity = 0.7,
        });
        if (actionLabel is not null && action is not null)
        {
            var button = new Button
            {
                Content = actionLabel,
                HorizontalAlignment = HorizontalAlignment.Center,
                Style = Application.Current.Resources["AccentButtonStyle"] as Style,
                Margin = new Thickness(0, 8, 0, 0),
            };
            button.Click += (_, _) => action();
            panel.Children.Add(button);
        }
        return panel;
    }

    // ---- Menu commands ---------------------------------------------------

    public async void OpenWorkingFolder_Click(object sender, RoutedEventArgs e)
    {
        var picker = new Windows.Storage.Pickers.FolderPicker();
        WinRT.Interop.InitializeWithWindow.Initialize(picker,
            WinRT.Interop.WindowNative.GetWindowHandle(this));
        picker.FileTypeFilter.Add("*");
        var folder = await picker.PickSingleFolderAsync();
        if (folder is not null) Workspace.ChooseWorkspace(folder.Path);
    }

    private void NewWindow_Click(object sender, RoutedEventArgs e) => App.OpenNewWindow();

    private void ReloadCourses_Click(object sender, RoutedEventArgs e)
    {
        Workspace.Reload();
        ApplyState();
    }

    private void RestoreFromArchive_Click(object sender, RoutedEventArgs e)
    {
        if (Workspace.SelectedArchivedItem is { } item) Sidebar.ConfirmRestore(item);
    }

    private async void About_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new AboutDialog { XamlRoot = Content.XamlRoot };
        await dialog.ShowAsync();
    }

    private void OpenWorkingFolderAccelerator(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        OpenWorkingFolder_Click(sender, null!);
        args.Handled = true;
    }

    private void NewWindowAccelerator(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        App.OpenNewWindow();
        args.Handled = true;
    }

    private void ReloadCoursesAccelerator(KeyboardAccelerator sender, KeyboardAcceleratorInvokedEventArgs args)
    {
        Workspace.Reload();
        ApplyState();
        args.Handled = true;
    }
}
