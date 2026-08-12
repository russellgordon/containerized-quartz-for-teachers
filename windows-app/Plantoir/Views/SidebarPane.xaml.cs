using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Plantoir.Core.Models;
using Plantoir.Services;
using Plantoir.ViewModels;

namespace Plantoir.Views;

/// <summary>One row of the sidebar tree: a course, a section, the Archived group, or an archive.</summary>
public sealed class SidebarRow
{
    public required string Title { get; init; }
    public required string Glyph { get; init; }
    public string? Tooltip { get; init; }
    public bool IsExpanded { get; set; }   // mutable: user toggles are recorded (row 99)
    public string AutomationId { get; init; } = "";
    public ObservableCollection<SidebarRow> Children { get; init; } = new();
    public MenuFlyout? Menu { get; set; }
    public SidebarSelection? Selection { get; init; }
    public ArchivedItem? Archived { get; init; }
}

public sealed partial class SidebarPane : UserControl
{
    // Segoe Fluent glyphs, mirroring the mac symbol choices.
    private const string LibraryGlyph = Glyphs.Library;
    private const string DocumentGlyph = Glyphs.Document;
    private const string ArchiveGlyph = Glyphs.Archive;
    private const string AddSectionGlyph = Glyphs.Add;
    private const string ObsidianGlyph = Glyphs.Edit;
    private const string ExplorerGlyph = Glyphs.Explorer;
    private const string TerminalGlyph = Glyphs.Terminal;
    private const string RestoreGlyph = Glyphs.Restore;

    private MainWindow _window = null!;
    private WorkspaceViewModel Workspace => _window.Workspace;
    private DateTime _lastTreeInteraction = DateTime.MinValue;

    public SidebarPane()
    {
        InitializeComponent();
        // Note the moments the teacher actually touches the tree (chevron
        // clicks arrive with the event already handled, so listen to handled
        // events too). Collapsed uses this to tell a real fold from a glitch.
        Tree.AddHandler(PointerPressedEvent,
            new Microsoft.UI.Xaml.Input.PointerEventHandler((_, _) => _lastTreeInteraction = DateTime.UtcNow), true);
        Tree.AddHandler(KeyDownEvent,
            new Microsoft.UI.Xaml.Input.KeyEventHandler((_, _) => _lastTreeInteraction = DateTime.UtcNow), true);
        Tree.Collapsed += Tree_Collapsed;
        Tree.Expanding += Tree_Expanding;
    }

    /// <summary>
    /// An expand is always worth recording — a deliberate one changes the
    /// per-window memory (row 99), and a programmatic re-assert writes back
    /// the value the model already holds.
    /// </summary>
    private void Tree_Expanding(TreeView sender, TreeViewExpandingEventArgs args)
    {
        if (args.Item is not SidebarRow row) return;
        row.IsExpanded = true;
        RecordExpansion(row, expanded: true);
    }

    /// <summary>Write a group/course toggle into the window's memory.</summary>
    private void RecordExpansion(SidebarRow row, bool expanded)
    {
        if (row.Selection is SidebarSelection.CourseItem(var code))
        {
            if (Workspace.IsCourseExpanded(code) == expanded) return;
            Workspace.SetCourseExpanded(code, expanded);
            App.RememberOpenWindows();
        }
        else if (ReferenceEquals(row, _archivedGroup))
        {
            if (Workspace.IsShowingArchived == expanded) return;
            Workspace.IsShowingArchived = expanded;
            App.RememberOpenWindows();
        }
    }

    /// <summary>
    /// Undo a collapse the teacher didn't ask for. WinUI's TreeView spuriously
    /// folds rows when the tree is rebuilt around a closing dialog — creating a
    /// course folded "Courses & Clubs" the moment the wizard closed, and the
    /// collapse can land many frames after the rebuild, so no fixed-length
    /// re-assert after Refresh is reliable. Catching the collapse itself is:
    /// if a row that asks to be open folds with no recent pointer or key input
    /// on the tree, it was the glitch — reopen it.
    /// </summary>
    private void Tree_Collapsed(TreeView sender, TreeViewCollapsedEventArgs args)
    {
        if (args.Item is not SidebarRow row) return;
        // The chevron raises Collapsed BEFORE its own pointer event bubbles
        // up to the tree (measured live: collapse, then the pointer 6 ms
        // later) — so deciding user-vs-glitch NOW would call every real
        // fold a glitch and reopen it. Defer one dispatcher pass; by then a
        // real click's pointer has been seen, while the rebuild glitch
        // (whose trigger is a dialog click that never routes through the
        // tree) still shows no input.
        DispatcherQueue.TryEnqueue(Microsoft.UI.Dispatching.DispatcherQueuePriority.Low, () =>
        {
            if ((DateTime.UtcNow - _lastTreeInteraction).TotalMilliseconds < 1000)
            {
                // The teacher folded this on purpose: remember it (row 99).
                row.IsExpanded = false;
                RecordExpansion(row, expanded: false);
                return;
            }
            if (!row.IsExpanded) return;
            if (Tree.ContainerFromItem(row) is TreeViewItem container && !container.IsExpanded)
                container.IsExpanded = true;
        });
    }

    public void Attach(MainWindow window)
    {
        _window = window;
        window.Workspace.PropertyChanged += (_, args) =>
        {
            if (args.PropertyName is nameof(WorkspaceViewModel.Selection))
                RemoveButton.IsEnabled = Workspace.SelectedCourse is not null;
        };
    }

    // ---- Building the tree ----------------------------------------------

    // The tree is UPDATED IN PLACE, never rebuilt. Replacing ItemsSource
    // wholesale forces the TreeView to destroy and recreate every container,
    // and WinUI drops expansion state somewhere in that churn — "Courses &
    // Clubs" kept folding up after the create-course dialog closed, on no
    // schedule any timed re-assert could reliably beat. With persistent row
    // objects reconciled against the workspace, the group containers are
    // never re-created, so there is no state to lose.
    private readonly ObservableCollection<SidebarRow> _roots = new();
    private SidebarRow? _coursesGroup;
    private SidebarRow? _archivedGroup;

    public void Refresh()
    {
        if (_coursesGroup is null)
        {
            _coursesGroup = new SidebarRow { Title = "Courses & Clubs", Glyph = "", IsExpanded = true };
            _roots.Add(_coursesGroup);
            Tree.ItemsSource = _roots;
        }
        ReconcileCourses();
        ReconcileArchived();
        RefreshNoMatches();
        ReassertExpansion();
    }

    private void ReconcileCourses()
    {
        var byCode = new Dictionary<string, SidebarRow>();
        foreach (var row in _coursesGroup!.Children) byCode[row.Title] = row;

        var desired = new List<SidebarRow>();
        foreach (var course in Workspace.FilteredCourses)
        {
            if (!byCode.TryGetValue(course.Code, out var row))
                row = new SidebarRow
                {
                    Title = course.Code,
                    Glyph = LibraryGlyph,
                    // The window's own memory decides (row 99); a window
                    // without stored state opens everything.
                    IsExpanded = Workspace.IsCourseExpanded(course.Code),
                    Selection = new SidebarSelection.CourseItem(course.Code),
                    AutomationId = $"sidebar-{course.Code}",
                };
            // Menus are remade every pass so their closures always hold the
            // freshly loaded Course, never a stale pre-reload instance.
            row.Menu = CourseMenu(course);
            ReconcileSections(row, course);
            desired.Add(row);
        }
        ApplyDesiredOrder(_coursesGroup.Children, desired);
    }

    private void ReconcileSections(SidebarRow courseRow, Course course)
    {
        var byTitle = new Dictionary<string, SidebarRow>();
        foreach (var row in courseRow.Children) byTitle[row.Title] = row;

        var desired = new List<SidebarRow>();
        foreach (int number in course.SectionNumbers)
        {
            if (!byTitle.TryGetValue($"Section {number}", out var row))
                row = new SidebarRow
                {
                    Title = $"Section {number}",
                    Glyph = DocumentGlyph,
                    Selection = new SidebarSelection.SectionItem(course.Code, number),
                    AutomationId = $"sidebar-{course.Code}-section{number}",
                };
            row.Menu = SectionMenu(course, number);
            desired.Add(row);
        }
        ApplyDesiredOrder(courseRow.Children, desired);
    }

    private void ReconcileArchived()
    {
        if (Workspace.ArchivedItems.Count == 0)
        {
            if (_archivedGroup is not null) { _roots.Remove(_archivedGroup); _archivedGroup = null; }
            return;
        }
        if (_archivedGroup is null)
        {
            // A place to go looking, not something to step over — closed by
            // default, but a window that had it open gets it back (row 99).
            _archivedGroup = new SidebarRow
            {
                Title = "Archived",
                Glyph = ArchiveGlyph,
                IsExpanded = Workspace.IsShowingArchived,
                AutomationId = "archivedGroup",
            };
            _roots.Add(_archivedGroup);
        }

        var byId = new Dictionary<string, SidebarRow>();
        foreach (var row in _archivedGroup.Children)
            if (row.Archived is { } archived) byId[archived.Id] = row;

        var desired = new List<SidebarRow>();
        foreach (var item in Workspace.ArchivedItems)
        {
            if (!byId.TryGetValue(item.Id, out var row) || row.Title != item.Title || row.Tooltip != item.Subtitle)
                row = new SidebarRow
                {
                    Title = item.Title,
                    Glyph = item.IsCourse ? LibraryGlyph : DocumentGlyph,   // same faces as live rows
                    Tooltip = item.Subtitle,
                    Selection = new SidebarSelection.ArchivedEntry(item.Id),
                    Archived = item,
                    AutomationId = $"archived-{item.Title}",
                };
            row.Menu = ArchivedMenu(item);
            desired.Add(row);
        }
        ApplyDesiredOrder(_archivedGroup.Children, desired);
    }

    /// <summary>
    /// Morph <paramref name="current"/> into <paramref name="desired"/> with
    /// the smallest moves — surviving rows are never removed and re-added, so
    /// their containers (and expansion state) ride through untouched.
    /// </summary>
    private static void ApplyDesiredOrder(ObservableCollection<SidebarRow> current, List<SidebarRow> desired)
    {
        for (int i = current.Count - 1; i >= 0; i--)
            if (!desired.Contains(current[i])) current.RemoveAt(i);
        for (int i = 0; i < desired.Count; i++)
        {
            int at = current.IndexOf(desired[i]);
            if (at == i) continue;
            if (at >= 0) current.Move(at, i);
            else current.Insert(i, desired[i]);
        }
    }

    /// <summary>
    /// Open any container that was REALIZED already folded — a brand-new row's
    /// container can surface collapsed without ever raising Collapsed, so the
    /// glitch guard above cannot see it. Retries briefly, stopping the moment
    /// every row that wants to be open has an open container. Section leaves
    /// and the Archived group ask to stay closed and are never touched.
    /// </summary>
    private void ReassertExpansion()
    {
        var wantOpen = new List<SidebarRow>();
        void Collect(IEnumerable<SidebarRow> rows)
        {
            foreach (var row in rows)
            {
                if (row.IsExpanded) wantOpen.Add(row);
                Collect(row.Children);
            }
        }
        Collect(_roots);

        var timer = DispatcherQueue.CreateTimer();
        int ticks = 0;
        timer.Interval = TimeSpan.FromMilliseconds(100);
        timer.Tick += (t, _) =>
        {
            bool allSettled = true;
            foreach (var row in wantOpen)
            {
                if (Tree.ContainerFromItem(row) is not TreeViewItem container) { allSettled = false; continue; }
                if (!container.IsExpanded) container.IsExpanded = true;
            }
            if (allSettled || ++ticks >= 20) t.Stop();   // settled, or ~2 s
        };
        timer.Start();
    }

    private void RefreshNoMatches()
    {
        bool show = Workspace.ShowsNoFilterMatches;
        NoMatches.Visibility = show ? Visibility.Visible : Visibility.Collapsed;
        Tree.Visibility = show ? Visibility.Collapsed : Visibility.Visible;
        if (show) NoMatchesDetail.Text = $"No course or club matches “{Workspace.FilterText.Trim()}”.";
    }

    private void Tree_ItemInvoked(TreeView sender, TreeViewItemInvokedEventArgs args)
    {
        if (args.InvokedItem is SidebarRow { Selection: { } selection })
            Workspace.Selection = selection;
    }

    // ---- Context menus ---------------------------------------------------

    private MenuFlyout CourseMenu(Course course)
    {
        var menu = new MenuFlyout();
        var addItem = MenuItem("Add Section…", AddSectionGlyph, () => _ = OpenAddSectionDialog(course));
        var busyNote = new MenuFlyoutItem { IsEnabled = false, Visibility = Visibility.Collapsed };
        menu.Items.Add(addItem);
        menu.Items.Add(busyNote);
        // The staleness lesson from the mac (row 104): menu content is built
        // when the ROW renders, not when the teacher opens it — so the busy
        // state is read the moment the menu opens, never captured earlier.
        menu.Opening += (_, _) =>
        {
            string? reason = Workspace.WorkspacePath is { } folder
                ? CourseActivity.BusyReason(folder, course.Code) : null;
            addItem.IsEnabled = reason is null;
            busyNote.Text = reason ?? "";
            busyNote.Visibility = reason is null ? Visibility.Collapsed : Visibility.Visible;
        };
        menu.Items.Add(new MenuFlyoutSeparator());
        menu.Items.Add(ObsidianItem(course.DirectoryPath, course.DirectoryPath));
        menu.Items.Add(new MenuFlyoutSeparator());
        menu.Items.Add(MenuItem("Show in File Explorer", ExplorerGlyph, () => FolderActions.ShowInFileExplorer(course.DirectoryPath)));
        menu.Items.Add(MenuItem("Open in Terminal", TerminalGlyph, () => FolderActions.OpenTerminal(course.DirectoryPath)));
        return menu;
    }

    private MenuFlyout SectionMenu(Course course, int number)
    {
        string sectionDir = course.SectionDirectory(number);
        var menu = new MenuFlyout();
        // The vault is the COURSE folder even for a section — the section is
        // a subfolder within it, and Obsidian lands at its landing page.
        menu.Items.Add(ObsidianItem(sectionDir, course.DirectoryPath));
        menu.Items.Add(new MenuFlyoutSeparator());
        menu.Items.Add(MenuItem("Show in File Explorer", ExplorerGlyph, () => FolderActions.ShowInFileExplorer(sectionDir)));
        menu.Items.Add(MenuItem("Open in Terminal", TerminalGlyph, () => FolderActions.OpenTerminal(sectionDir)));
        return menu;
    }

    private MenuFlyout ArchivedMenu(ArchivedItem item)
    {
        var menu = new MenuFlyout();
        menu.Items.Add(MenuItem("Restore…", RestoreGlyph, () => ConfirmRestore(item)));
        menu.Items.Add(MenuItem("Show in File Explorer", ExplorerGlyph, () => FolderActions.ShowInFileExplorer(item.FilePath)));
        return menu;
    }

    private MenuFlyoutItem ObsidianItem(string revealFolder, string vaultPath)
    {
        var item = MenuItem("Open in Obsidian", ObsidianGlyph,
            () => _ = FolderActions.OpenInObsidian(revealFolder, vaultPath,
                BundledToolchain.SupportPath("obsidian_defaults/.obsidian")));
        item.IsEnabled = FolderActions.ObsidianIsInstalled;
        return item;
    }

    private static MenuFlyoutItem MenuItem(string text, string glyph, Action action)
    {
        var item = new MenuFlyoutItem { Text = text };
        if (glyph.Length > 0) item.Icon = new FontIcon { Glyph = glyph };
        item.Click += (_, _) => action();
        return item;
    }

    // ---- Footer actions --------------------------------------------------

    private void Add_Click(object sender, RoutedEventArgs e) => _ = OpenNewCourseWizard();

    private async void Remove_Click(object sender, RoutedEventArgs e)
    {
        // An archived item is already put away — nothing for this button to do.
        var course = Workspace.SelectedCourse;
        if (course is null || Workspace.WorkspacePath is null) return;

        string title;
        string message;
        int? sectionNumber = (Workspace.Selection as SidebarSelection.SectionItem)?.Number;
        if (sectionNumber is int n && course.SectionNumbers.Count > 1)
        {
            title = $"Remove Section {n} of {course.Code}?";
            message = "Nothing is deleted. This section moves to Archived, at the bottom of the sidebar, where you can get it back.";
        }
        else if (sectionNumber is int only && course.SectionNumbers.Count == 1)
        {
            title = $"Remove {course.Code}?";
            message = $"Section {only} is the only section of {course.Code}, so the whole course moves to Archived. Nothing is deleted — you can get it back from the bottom of the sidebar.";
            sectionNumber = null;   // removing the only section removes the course
        }
        else
        {
            title = $"Remove {course.Code}?";
            message = $"Nothing is deleted. {course.Code} and all of its sections move to Archived, at the bottom of the sidebar, where you can get them back.";
        }

        var dialog = new ContentDialog
        {
            Title = title,
            Content = message,
            PrimaryButtonText = "Remove",
            CloseButtonText = "Cancel",
            DefaultButton = ContentDialogButton.Close,
            XamlRoot = XamlRoot,
        };
        if (await dialog.ShowAsync() != ContentDialogResult.Primary) return;

        try
        {
            string coursesDir = Workspace.CoursesDirectory();
            if (sectionNumber is int number) CourseArchiver.ArchiveAndRemoveSection(course, number, coursesDir);
            else CourseArchiver.ArchiveAndRemoveCourse(course, coursesDir);
            Workspace.Selection = null;
            Workspace.Reload();
            _window.ApplyState();
        }
        catch (Exception error)
        {
            await ShowError("Could not remove", error.Message);
        }
    }

    public async void ConfirmRestore(ArchivedItem item)
    {
        string message = item.SectionNumber is int n
            ? $"Section {n} will be put back into {item.CourseCode}, and will no longer be listed as archived."
            : $"{item.CourseCode} will be put back into Courses & Clubs, and will no longer be listed as archived.";
        var dialog = new ContentDialog
        {
            Title = $"Restore {item.Title}?",
            Content = message,
            PrimaryButtonText = "Restore",
            CloseButtonText = "Cancel",
            DefaultButton = ContentDialogButton.Primary,
            XamlRoot = XamlRoot,
        };
        if (await dialog.ShowAsync() != ContentDialogResult.Primary) return;

        try
        {
            CourseRestorer.Restore(item, Workspace.CoursesDirectory(), Workspace.Courses);
            Workspace.Selection = null;
            Workspace.Reload();
            Workspace.Selection = item.SectionNumber is int number
                ? new SidebarSelection.SectionItem(item.CourseCode, number)
                : new SidebarSelection.CourseItem(item.CourseCode);
            _window.ApplyState();
        }
        catch (Exception error)
        {
            await ShowError("Could not restore", error.Message);
        }
    }

    private async Task ShowError(string title, string message)
    {
        var dialog = new ContentDialog
        {
            Title = title,
            Content = message,
            CloseButtonText = "OK",
            XamlRoot = XamlRoot,
        };
        await dialog.ShowAsync();
    }

    private void Filter_TextChanged(object sender, TextChangedEventArgs e)
    {
        Workspace.FilterText = FilterBox.Text;
        Refresh();
    }

    // ---- Dialog launchers ------------------------------------------------

    public async Task OpenNewCourseWizard(string? autoCreateCode = null, string? autoSections = null)
    {
        var wizard = new NewCourseDialog(_window) { XamlRoot = XamlRoot };
        if (autoCreateCode is not null) wizard.AutoCreate(autoCreateCode, autoSections);
        await wizard.ShowAsync();
        Workspace.Reload();
        _window.ApplyState();
        if (wizard.CreatedCourseCode is { } code)
        {
            Workspace.Selection = wizard.CreatedIsExample
                ? new SidebarSelection.SectionItem(code, 1)
                : new SidebarSelection.CourseItem(code);
        }
    }

    public async Task OpenAddSectionDialog(Course course)
    {
        // Belt to the menu's braces: adding a section re-runs the course
        // setup, which rewrites folders a live preview or publish may be
        // mid-copy of. Decline while the course is busy anywhere.
        if (Workspace.WorkspacePath is { } folder
            && CourseActivity.BusyReason(folder, course.Code) is not null)
        {
            await ShowError($"{course.Code} is busy right now",
                "Adding a section rewrites the course's folders and files, and a " +
                "preview or publish of this course is still using them. Try again when it finishes.");
            return;
        }
        var dialog = new AddSectionDialog(course) { XamlRoot = XamlRoot };
        await dialog.ShowAsync();
        if (dialog.AddedNumber is { } number)
        {
            Workspace.Reload();
            _window.ApplyState();
            Workspace.Selection = new SidebarSelection.SectionItem(course.Code, number);
        }
    }
}
