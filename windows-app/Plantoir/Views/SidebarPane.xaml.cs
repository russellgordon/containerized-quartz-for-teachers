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
    public bool IsExpanded { get; init; }
    public string AutomationId { get; init; } = "";
    public ObservableCollection<SidebarRow> Children { get; init; } = new();
    public MenuFlyout? Menu { get; set; }
    public SidebarSelection? Selection { get; init; }
    public ArchivedItem? Archived { get; init; }
}

public sealed partial class SidebarPane : UserControl
{
    // Segoe Fluent glyphs, mirroring the mac symbol choices.
    private const string LibraryGlyph = "";        // books.vertical
    private const string DocumentGlyph = "";       // doc.richtext
    private const string ArchiveGlyph = "";        // archivebox
    private const string AddSectionGlyph = "";     // plus
    private const string ObsidianGlyph = "";       // square.and.pencil
    private const string ExplorerGlyph = "";       // finder analogue
    private const string TerminalGlyph = "";       // terminal
    private const string RestoreGlyph = "";        // arrow.uturn.backward

    private MainWindow _window = null!;
    private WorkspaceViewModel Workspace => _window.Workspace;

    public SidebarPane() => InitializeComponent();

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

    public void Refresh()
    {
        var roots = new ObservableCollection<SidebarRow>();

        var coursesGroup = new SidebarRow
        {
            Title = "Courses & Clubs",
            Glyph = "",
            IsExpanded = true,
        };
        foreach (var course in Workspace.FilteredCourses)
        {
            var courseRow = new SidebarRow
            {
                Title = course.Code,
                Glyph = LibraryGlyph,
                IsExpanded = true,
                Selection = new SidebarSelection.CourseItem(course.Code),
                AutomationId = $"sidebar-{course.Code}",
            };
            courseRow.Menu = CourseMenu(course);
            foreach (int number in course.SectionNumbers)
            {
                var sectionRow = new SidebarRow
                {
                    Title = $"Section {number}",
                    Glyph = DocumentGlyph,
                    Selection = new SidebarSelection.SectionItem(course.Code, number),
                    AutomationId = $"sidebar-{course.Code}-section{number}",
                };
                sectionRow.Menu = SectionMenu(course, number);
                courseRow.Children.Add(sectionRow);
            }
            coursesGroup.Children.Add(courseRow);
        }
        roots.Add(coursesGroup);

        if (Workspace.ArchivedItems.Count > 0)
        {
            // A place to go looking, not something to step over — closed by default.
            var archivedGroup = new SidebarRow
            {
                Title = "Archived",
                Glyph = ArchiveGlyph,
                IsExpanded = false,
                AutomationId = "archivedGroup",
            };
            foreach (var item in Workspace.ArchivedItems)
            {
                var row = new SidebarRow
                {
                    Title = item.Title,
                    Glyph = item.IsCourse ? LibraryGlyph : DocumentGlyph,   // same faces as live rows
                    Tooltip = item.Subtitle,
                    Selection = new SidebarSelection.ArchivedEntry(item.Id),
                    Archived = item,
                    AutomationId = $"archived-{item.Title}",
                };
                row.Menu = ArchivedMenu(item);
                archivedGroup.Children.Add(row);
            }
            roots.Add(archivedGroup);
        }

        Tree.ItemsSource = roots;
        RefreshNoMatches();
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
        menu.Items.Add(MenuItem("Add Section…", AddSectionGlyph, () => _ = OpenAddSectionDialog(course)));
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

    public async Task OpenNewCourseWizard()
    {
        var wizard = new NewCourseDialog(_window) { XamlRoot = XamlRoot };
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
