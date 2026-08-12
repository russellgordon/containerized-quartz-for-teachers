using System;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Automation;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Plantoir.Core.Models;

namespace Plantoir.Views;

/// <summary>
/// The publishing choice — Netlify, or a folder on this PC — used by BOTH
/// Course Settings and the new-course wizard, so the two offer exactly the
/// same behaviour and wording (rows 101–102; mirrors the mac's
/// PublishingChoiceView). Validation is live: the problem line follows every
/// keystroke and every choice, and callers gate Save/Create on
/// <see cref="Problem"/> so a publish can never discover a bad folder after
/// the fact.
/// </summary>
public sealed class PublishingChoiceView
{
    public StackPanel Root { get; }

    /// <summary>Raised after every change the teacher makes here.</summary>
    public event Action? Changed;

    private readonly Func<string> _getTarget;
    private readonly Action<string> _setTarget;
    private readonly Func<string> _getPath;
    private readonly Action<string> _setPath;
    private readonly StackPanel _folderArea;
    private readonly TextBox _pathBox;
    private readonly TextBlock _problemText;
    private readonly TextBlock _caption;
    private readonly Window _pickerOwner;
    private bool _updatingFromModel;

    /// <summary>
    /// What is wrong with the chosen folder, or null when nothing is —
    /// always null in Netlify mode.
    /// </summary>
    public string? Problem =>
        _getTarget() == "local_folder" ? CourseConfiguration.DeployFolderProblem(_getPath()) : null;

    public PublishingChoiceView(Window pickerOwner,
                                Func<string> getTarget, Action<string> setTarget,
                                Func<string> getPath, Action<string> setPath)
    {
        _pickerOwner = pickerOwner;
        _getTarget = getTarget;
        _setTarget = setTarget;
        _getPath = getPath;
        _setPath = setPath;

        Root = new StackPanel { Spacing = 6 };

        var targetBox = new ComboBox { MinWidth = 300 };
        targetBox.Items.Add("Netlify");
        targetBox.Items.Add("A folder on this PC");
        targetBox.SelectedIndex = getTarget() == "local_folder" ? 1 : 0;
        AutomationProperties.SetAutomationId(targetBox, "deployTargetPicker");
        Root.Children.Add(FormBuilders.LabeledRow("Publish to", targetBox));

        _folderArea = new StackPanel { Spacing = 4 };
        var pathRow = new Grid { ColumnSpacing = 8 };
        pathRow.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        pathRow.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        _pathBox = new TextBox { Text = getPath(), PlaceholderText = "Folder" };
        AutomationProperties.SetAutomationId(_pathBox, "deployFolderField");
        pathRow.Children.Add(_pathBox);
        var chooseButton = new Button { Content = "Choose…" };
        AutomationProperties.SetAutomationId(chooseButton, "deployFolderChooseButton");
        Grid.SetColumn(chooseButton, 1);
        pathRow.Children.Add(chooseButton);
        _folderArea.Children.Add(pathRow);

        _problemText = new TextBlock
        {
            FontSize = 12,
            TextWrapping = TextWrapping.Wrap,
            Foreground = (Brush)Application.Current.Resources["SystemFillColorCautionBrush"],
            Visibility = Visibility.Collapsed,
        };
        AutomationProperties.SetAutomationId(_problemText, "deployFolderProblem");
        _folderArea.Children.Add(_problemText);
        _caption = FormBuilders.ExampleCaption(
            "Each section publishes into its own subfolder here — section1, section2 — and only changed files are copied. Upload the folder to your web host however you prefer (e.g. over SFTP). Netlify isn’t involved.");
        _folderArea.Children.Add(_caption);
        Root.Children.Add(_folderArea);

        targetBox.SelectionChanged += (_, _) =>
        {
            if (_updatingFromModel) return;
            setTarget(targetBox.SelectedIndex == 1 ? "local_folder" : "netlify");
            RefreshFolderArea();
            Changed?.Invoke();
        };
        _pathBox.TextChanged += (_, _) =>
        {
            if (_updatingFromModel) return;
            setPath(_pathBox.Text);
            RefreshFolderArea();
            Changed?.Invoke();
        };
        chooseButton.Click += async (_, _) =>
        {
            var picker = new Windows.Storage.Pickers.FolderPicker();
            WinRT.Interop.InitializeWithWindow.Initialize(picker,
                WinRT.Interop.WindowNative.GetWindowHandle(_pickerOwner));
            picker.FileTypeFilter.Add("*");
            var folder = await picker.PickSingleFolderAsync();
            if (folder is null) return;
            _updatingFromModel = true;
            _pathBox.Text = folder.Path;
            _updatingFromModel = false;
            setPath(folder.Path);
            RefreshFolderArea();   // validation runs on the choice instantly
            Changed?.Invoke();
        };

        RefreshFolderArea();
    }

    private void RefreshFolderArea()
    {
        bool folderMode = _getTarget() == "local_folder";
        _folderArea.Visibility = folderMode ? Visibility.Visible : Visibility.Collapsed;
        string? problem = Problem;
        _problemText.Text = problem ?? "";
        _problemText.Visibility = problem is null ? Visibility.Collapsed : Visibility.Visible;
        _caption.Visibility = problem is null ? Visibility.Visible : Visibility.Collapsed;
    }
}
