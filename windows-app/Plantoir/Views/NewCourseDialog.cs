using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Newtonsoft.Json.Linq;
using Plantoir.Core.Catalogs;
using Plantoir.Core.Models;
using Plantoir.Core.Scripting;
using Plantoir.Services;

namespace Plantoir.Views;

/// <summary>
/// The New Course or Club wizard. The form collects the teacher's choices;
/// Create writes them as course_config.json and runs the REAL setup
/// launcher, whose prompts are answered with their now-correct defaults.
/// A "New to this?" panel installs the complete example course instead.
/// </summary>
public sealed class NewCourseDialog : ContentDialog
{
    public string? CreatedCourseCode { get; private set; }
    public bool CreatedIsExample { get; private set; }

    private readonly MainWindow _window;
    private readonly NewCourseCreator _creator;
    private readonly TaskProgressView _progress = new();

    private readonly TextBox _codeBox = new();
    private readonly TextBox _nameBox = new();
    private readonly TextBox _shortBox = new() { MaxLength = 12 };
    private readonly StackPanel _shortRow;
    private readonly TextBox _sectionsBox = new() { Text = "1" };
    private readonly TextBlock _sectionsCaption;
    private readonly ComboBox _localeBox = new() { MinWidth = 300 };
    private readonly StackPanel _suggestionsRow = new() { Spacing = 4, Visibility = Visibility.Collapsed };
    private readonly TextBlock _validationText;
    private readonly ScrollViewer _formScroll;
    private readonly StackPanel _root;

    private string _emoji = WizardDefaults.DefaultEmoji;
    private string _schemeId = WizardDefaults.DefaultColourSchemeId;
    private bool _showsMarker = true;
    private bool _showsGrade = true;
    private bool _expandOnFolderClick;
    private bool _showReadingTime;
    private string _footerHtml = "";
    private FontChoice _fontChoice = FontChoice.SystemDefault;
    private List<string> _sharedFolders = WizardDefaults.SharedFolders.ToList();
    private List<string> _sharedFiles = WizardDefaults.SharedFiles.ToList();
    private List<string> _perSectionFolders = WizardDefaults.PerSectionFolders.ToList();
    private List<string> _perSectionFiles = WizardDefaults.PerSectionFiles.ToList();
    private string _lastAutoFilledName = "";
    private readonly CourseNameCatalog _nameCatalog;
    private readonly TextBlock _gradeWarningSlot;
    private bool _started;

    public NewCourseDialog(MainWindow window)
    {
        _window = window;
        _creator = new NewCourseCreator(new ScriptRunner(System.Threading.SynchronizationContext.Current));
        _nameCatalog = CourseNameCatalog.Load(BundledToolchain.SupportPath("ontario_secondary_courses.json"));

        Title = "New Course or Club";
        PrimaryButtonText = "Create Course";
        CloseButtonText = "Cancel";
        DefaultButton = ContentDialogButton.Primary;
        PrimaryButtonClick += OnPrimaryButton;
        CloseButtonClick += OnCloseButton;

        _validationText = new TextBlock
        {
            TextWrapping = TextWrapping.Wrap,
            Foreground = (Brush)Application.Current.Resources["SystemFillColorCriticalBrush"],
            Visibility = Visibility.Collapsed,
        };
        _sectionsCaption = FormBuilders.ExampleCaption("e.g. 1,3 — comma-separated");
        _gradeWarningSlot = new TextBlock { FontSize = 12, TextWrapping = TextWrapping.Wrap, Visibility = Visibility.Collapsed };
        _shortRow = FormBuilders.LabeledRow("Short label beside emoji (≤ 12 characters)", _shortBox);
        _shortRow.Visibility = Visibility.Collapsed;

        // Pin the whole dialog to a fixed width so the form and the progress
        // view share the same size and the "Step x of y" label can't be
        // clipped off the right edge (issue 3). ContentDialog width is driven
        // by these theme resources, not by the content's own Width.
        Resources["ContentDialogMinWidth"] = 600.0;
        Resources["ContentDialogMaxWidth"] = 600.0;
        _root = new StackPanel { Spacing = 8 };
        _formScroll = new ScrollViewer
        {
            Content = BuildForm(),
            MaxHeight = 520,
            VerticalScrollBarVisibility = ScrollBarVisibility.Auto,
            HorizontalScrollMode = ScrollMode.Disabled,
            HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled,
        };
        _progress.HorizontalAlignment = HorizontalAlignment.Stretch;
        _root.Children.Add(_formScroll);
        _root.Children.Add(_validationText);
        Content = _root;
        RefreshCreateEnabled();
    }

    /// <summary>Smoke-test entry: fill the code (and optional sections) and press Create.</summary>
    public void AutoCreate(string code, string? sections = null)
    {
        _codeBox.Text = code;
        if (sections is not null) _sectionsBox.Text = sections;
        Opened += (_, _) => _ = StartCreation();
    }

    /// <summary>
    /// The Create button stays disabled until there is enough to make a course:
    /// a spaceless, non-duplicate code and a valid section-numbers list (issue 2).
    /// </summary>
    private void RefreshCreateEnabled()
    {
        if (_started) return;   // once running, the affirmative button becomes "Close"
        string code = _codeBox.Text.Trim().ToUpperInvariant();
        bool codeOk = code.Length > 0 && !code.Contains(' ')
                      && !_window.Workspace.Courses.Any(c => c.Code == code);
        bool sectionsOk = SectionNumbersProblem(_sectionsBox.Text) is null;
        IsPrimaryButtonEnabled = codeOk && sectionsOk;
    }

    // ---- Form ------------------------------------------------------------

    private StackPanel BuildForm()
    {
        var form = new StackPanel { Spacing = 6 };

        // "New to this?" — a finished course teaches more than an empty form.
        // Stacked vertically so the button never clips at any dialog width.
        var invitation = new StackPanel { Spacing = 8, Padding = new Thickness(12) };
        invitation.Children.Add(new TextBlock { Text = "New to this?", FontWeight = FontWeights.SemiBold });
        invitation.Children.Add(new TextBlock
        {
            Text = "Add a complete example course — a real Grade 9 science course you can explore, change, and remove whenever you like.",
            TextWrapping = TextWrapping.Wrap,
            FontSize = 12,
            Opacity = 0.7,
        });
        var exampleButton = new Button { Content = "Add Example Course", HorizontalAlignment = HorizontalAlignment.Left };
        exampleButton.Click += (_, _) => _ = StartExampleInstall();
        invitation.Children.Add(exampleButton);
        form.Children.Add(new Border
        {
            Child = invitation,
            Background = (Brush)Application.Current.Resources["CardBackgroundFillColorDefaultBrush"],
            CornerRadius = new CornerRadius(8),
        });

        // -------- Basics --------
        form.Children.Add(FormBuilders.SectionHeaderWithCaption("Basics", null));
        var codeRow = FormBuilders.LabeledRow("Course code", _codeBox);
        codeRow.Children.Add(FormBuilders.ExampleCaption("e.g. ICS3U — or a club name like CODING"));
        form.Children.Add(codeRow);
        _codeBox.TextChanged += (_, _) => { AutoFillCourseName(); RefreshClubRow(); RefreshGradeWarning(); RefreshCreateEnabled(); };

        var nameRow = FormBuilders.LabeledRow("Course name", _nameBox);
        nameRow.Children.Add(FormBuilders.ExampleCaption("e.g. Introduction to Computer Science"));
        nameRow.Children.Add(_suggestionsRow);
        form.Children.Add(nameRow);
        _nameBox.TextChanged += (_, _) => RefreshGradeWarning();

        form.Children.Add(_shortRow);

        var sectionsRow = FormBuilders.LabeledRow("Timetable section numbers", _sectionsBox);
        sectionsRow.Children.Add(_sectionsCaption);
        form.Children.Add(sectionsRow);
        _sectionsBox.TextChanged += (_, _) => { RefreshSectionsValidation(); RefreshCreateEnabled(); };

        foreach (string code in LocaleCatalog.Codes) _localeBox.Items.Add(LocaleCatalog.DisplayName(code));
        _localeBox.SelectedIndex = LocaleCatalog.Codes.ToList().IndexOf(WizardDefaults.DefaultLocale);
        form.Children.Add(FormBuilders.LabeledRow("Language / region", _localeBox));

        // -------- Appearance --------
        form.Children.Add(FormBuilders.SectionHeaderWithCaption("Appearance",
            "Applied to every section — fine-tune later in Settings"));
        form.Children.Add(FormBuilders.EmojiChoiceField("Header emoji",
            () => _emoji, v => _emoji = v, () => { }));

        var schemes = ColourSchemeCatalog.Load(BundledToolchain.SupportPath("colour_schemes.json"));
        var schemeBox = new ComboBox { MinWidth = 300 };
        int schemeIndex = 0;
        for (int i = 0; i < schemes.Count; i++)
        {
            schemeBox.Items.Add(schemes[i].Name);
            if (schemes[i].Id == _schemeId) schemeIndex = i;
        }
        schemeBox.SelectedIndex = schemes.Count > 0 ? schemeIndex : -1;
        schemeBox.SelectionChanged += (_, _) =>
        {
            if (schemeBox.SelectedIndex >= 0) _schemeId = schemes[schemeBox.SelectedIndex].Id;
        };
        form.Children.Add(FormBuilders.LabeledRow("Colour scheme", schemeBox));

        var pairingBox = new ComboBox { MinWidth = 300 };
        foreach (var pairing in FontCatalog.Pairings)
            pairingBox.Items.Add(FontCatalog.PairingLabel(pairing.Header, pairing.Body));
        pairingBox.SelectedIndex = FontCatalog.Pairings.Count - 1;   // system default
        pairingBox.SelectionChanged += (_, _) =>
        {
            if (pairingBox.SelectedIndex >= 0)
            {
                var pairing = FontCatalog.Pairings[pairingBox.SelectedIndex];
                _fontChoice = _fontChoice with { Header = pairing.Header, Body = pairing.Body };
            }
        };
        form.Children.Add(FormBuilders.LabeledRow("Header & body fonts", pairingBox));

        var codeFontBox = new ComboBox { MinWidth = 300 };
        foreach (string font in FontCatalog.CodeFonts) codeFontBox.Items.Add(font);
        codeFontBox.SelectedIndex = FontCatalog.CodeFonts.ToList().IndexOf(_fontChoice.Code);
        codeFontBox.SelectionChanged += (_, _) =>
        {
            if (codeFontBox.SelectedIndex >= 0)
                _fontChoice = _fontChoice with { Code = FontCatalog.CodeFonts[codeFontBox.SelectedIndex] };
        };
        form.Children.Add(FormBuilders.LabeledRow("Code font", codeFontBox));

        var markerToggle = new ToggleSwitch { IsOn = _showsMarker, OnContent = "", OffContent = "" };
        markerToggle.Toggled += (_, _) => _showsMarker = markerToggle.IsOn;
        var markerRow = FormBuilders.LabeledRow("Show section marker in the site title", markerToggle);
        markerRow.Children.Add(FormBuilders.ExampleCaption("e.g. \"S1\" appears beside the course code"));
        form.Children.Add(markerRow);

        var gradeToggle = new ToggleSwitch { IsOn = _showsGrade, OnContent = "", OffContent = "" };
        gradeToggle.Toggled += (_, _) => { _showsGrade = gradeToggle.IsOn; RefreshGradeWarning(); };
        var gradeRow = FormBuilders.LabeledRow("Show the grade in the site title", gradeToggle);
        gradeRow.Children.Add(_gradeWarningSlot);
        gradeRow.Children.Add(FormBuilders.ExampleCaption("e.g. \"Grade 12\" before the course name"));
        form.Children.Add(gradeRow);

        // -------- Behaviour --------
        form.Children.Add(FormBuilders.SectionHeaderWithCaption("Behaviour", null));
        var expandBox = new ComboBox { MinWidth = 300 };
        expandBox.Items.Add("Chevron or folder name");
        expandBox.Items.Add("Chevron only (name opens the folder)");
        expandBox.SelectedIndex = _expandOnFolderClick ? 0 : 1;
        expandBox.SelectionChanged += (_, _) => _expandOnFolderClick = expandBox.SelectedIndex == 0;
        form.Children.Add(FormBuilders.LabeledRow("Sidebar folders expand when clicking", expandBox));

        var readTimeToggle = new ToggleSwitch { IsOn = _showReadingTime, OnContent = "", OffContent = "" };
        readTimeToggle.Toggled += (_, _) => _showReadingTime = readTimeToggle.IsOn;
        form.Children.Add(FormBuilders.LabeledRow("Show page read-time estimates to students", readTimeToggle));

        // -------- Structure (long lists stay collapsed) --------
        form.Children.Add(FormBuilders.SectionHeaderWithCaption("Structure", "Defaults are fine for most courses"));
        var structure = new Expander
        {
            Header = "Folders and files",
            HorizontalAlignment = HorizontalAlignment.Stretch,
            HorizontalContentAlignment = HorizontalAlignment.Stretch,
        };
        var lists = new StackPanel { Spacing = 4 };
        lists.Children.Add(FormBuilders.StringListEditor("Shared folders", false,
            () => _sharedFolders, v => _sharedFolders = v, () => { }));
        lists.Children.Add(FormBuilders.StringListEditor("Shared files", true,
            () => _sharedFiles, v => _sharedFiles = v, () => { }));
        lists.Children.Add(FormBuilders.StringListEditor("Per-section folders", false,
            () => _perSectionFolders, v => _perSectionFolders = v, () => { }));
        lists.Children.Add(FormBuilders.StringListEditor("Per-section files", true,
            () => _perSectionFiles, v => _perSectionFiles = v, () => { }));
        structure.Content = lists;
        form.Children.Add(structure);

        // -------- Footer --------
        form.Children.Add(FormBuilders.SectionHeaderWithCaption("Footer", null));
        form.Children.Add(FormBuilders.ExampleCaption(
            "Optional: type or paste HTML below to appear at the bottom of every page on your site — many teachers use a Creative Commons licence notice. Leave the box empty for no footer."));
        var footerBox = new TextBox
        {
            AcceptsReturn = true,
            MinHeight = 60,
            FontFamily = new FontFamily("Consolas"),
            PlaceholderText = "For example: This site is licensed under <a href=\"…\">CC BY 4.0</a>.",
        };
        footerBox.TextChanged += (_, _) => _footerHtml = footerBox.Text;
        form.Children.Add(footerBox);

        return form;
    }

    // ---- Validation and auto-fill ---------------------------------------

    private bool IsClubCode(string code) => code.Length >= 4 && !char.IsDigit(code[3]);

    private void RefreshClubRow() =>
        _shortRow.Visibility = IsClubCode(_codeBox.Text.Trim().ToUpperInvariant())
            ? Visibility.Visible : Visibility.Collapsed;

    /// <summary>A teacher's own typing is never replaced — auto-fill only over emptiness or a previous auto-fill.</summary>
    private void AutoFillCourseName()
    {
        var names = _nameCatalog.Names(_codeBox.Text);
        _suggestionsRow.Children.Clear();
        if (names is null) { _suggestionsRow.Visibility = Visibility.Collapsed; return; }

        if (_nameBox.Text.Length == 0 || _nameBox.Text == _lastAutoFilledName)
        {
            _nameBox.Text = names.Formal;
            _lastAutoFilledName = names.Formal;
        }
        _suggestionsRow.Visibility = Visibility.Visible;
        _suggestionsRow.Children.Add(FormBuilders.ExampleCaption(
            $"Suggested names for {_codeBox.Text.Trim().ToUpperInvariant()}:"));
        var buttons = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8 };
        foreach (string suggestion in new[] { names.Formal, names.Short }.Distinct())
        {
            var button = new Button { Content = suggestion, FontSize = 12, Padding = new Thickness(8, 2, 8, 2) };
            button.Click += (_, _) => { _nameBox.Text = suggestion; _lastAutoFilledName = suggestion; };
            buttons.Children.Add(button);
        }
        _suggestionsRow.Children.Add(buttons);
    }

    private void RefreshSectionsValidation()
    {
        string? problem = SectionNumbersProblem(_sectionsBox.Text);
        if (problem is null)
        {
            _sectionsCaption.Text = "e.g. 1,3 — comma-separated";
            _sectionsCaption.Foreground = (Brush)Application.Current.Resources["TextFillColorSecondaryBrush"];
        }
        else
        {
            _sectionsCaption.Text = problem;
            _sectionsCaption.Foreground = (Brush)Application.Current.Resources["SystemFillColorCautionBrush"];
        }
    }

    private void RefreshGradeWarning()
    {
        string? warning = CourseConfiguration.GradeInTitleWarning(
            _nameBox.Text, _codeBox.Text.Trim().ToUpperInvariant(), _showsGrade);
        _gradeWarningSlot.Text = warning ?? "";
        _gradeWarningSlot.Foreground = (Brush)Application.Current.Resources["SystemFillColorCautionBrush"];
        _gradeWarningSlot.Visibility = warning is null ? Visibility.Collapsed : Visibility.Visible;
    }

    /// <summary>
    /// Written for the mistakes people actually make — load-bearing because
    /// the parser silently drops pieces it cannot read ("1,3 5" would
    /// quietly become just section 1).
    /// </summary>
    public static string? SectionNumbersProblem(string text)
    {
        string trimmed = text.Trim();
        if (trimmed.Length == 0) return "Enter at least one section number — e.g. 1, or 1,3.";
        var seen = new HashSet<int>();
        foreach (string rawPiece in trimmed.Split(','))
        {
            string piece = rawPiece.Trim();
            if (piece.Length == 0) return "There’s an empty spot between commas.";
            if (int.TryParse(piece, out int number))
            {
                if (number < 1) return $"“{piece}” isn’t a section number — sections are 1 or higher.";
                if (!seen.Add(number)) return $"Section {number} is listed more than once.";
                continue;
            }
            var subPieces = piece.Split(' ', StringSplitOptions.RemoveEmptyEntries);
            if (subPieces.Length > 1 && subPieces.All(p => int.TryParse(p, out _)))
                return $"Use commas between section numbers — e.g. {string.Join(",", subPieces)}.";
            return $"“{piece}” isn’t a section number — sections are whole numbers, like 1 or 3.";
        }
        return null;
    }

    public static List<int> ParsedSectionNumbers(string text) =>
        text.Split(',').Select(p => p.Trim())
            .Select(p => int.TryParse(p, out int n) ? n : 0)
            .Where(n => n > 0)
            .Distinct()
            .ToList();

    // ---- Creation --------------------------------------------------------

    private void OnPrimaryButton(ContentDialog sender, ContentDialogButtonClickEventArgs args)
    {
        if (_started) return;   // "Close" after completion
        args.Cancel = true;
        _ = StartCreation();
    }

    private void OnCloseButton(ContentDialog sender, ContentDialogButtonClickEventArgs args)
    {
        if (_creator.IsCreating) _creator.Runner.Terminate();
    }

    private async System.Threading.Tasks.Task StartCreation()
    {
        string code = _codeBox.Text.Trim().ToUpperInvariant();
        if (code.Length == 0 || code.Contains(' ')) { ShowValidation("Enter a course code without spaces."); return; }
        if (SectionNumbersProblem(_sectionsBox.Text) is { } problem) { ShowValidation(problem); return; }
        if (_window.Workspace.Courses.Any(c => c.Code == code))
        { ShowValidation($"A course named {code} already exists."); return; }
        if (_window.Workspace.WorkspacePath is not { } workspacePath)
        { ShowValidation("No working folder is selected."); return; }

        string name = _nameBox.Text.Trim();
        if (name.Length == 0) name = WizardDefaults.FallbackCourseName;

        BeginProgress("Creating your course");
        await _creator.CreateCourse(BuildConfiguration(code, name), workspacePath);
        if (_creator.PreparationProblem is { } preparationProblem)
        {
            ShowValidation(preparationProblem);
            return;
        }
        CreatedCourseCode = code;
        FinishProgress();
    }

    private async System.Threading.Tasks.Task StartExampleInstall()
    {
        if (_window.Workspace.WorkspacePath is not { } workspacePath)
        { ShowValidation("Choose a working folder first."); return; }
        BeginProgress("Adding the example course");
        await _creator.InstallExampleCourse(workspacePath);
        CreatedCourseCode = _creator.InstalledExampleCode;
        CreatedIsExample = CreatedCourseCode is not null;
        FinishProgress();
    }

    private void BeginProgress(string title)
    {
        _started = true;
        _validationText.Visibility = Visibility.Collapsed;
        _progress.Bind(_creator.Runner, title);
        // Drop the form's ScrollViewer entirely and stand the progress view in
        // its place with a bounded MaxHeight. Nesting the terminal inside a
        // ScrollViewer would measure its console with infinite height, so the
        // console could never clip, show a scrollbar, or follow its newest
        // line. Free-standing with a MaxHeight, the console pane is itself the
        // bounded, tail-following scroll region.
        _progress.MaxHeight = 520;
        _progress.VerticalAlignment = VerticalAlignment.Stretch;
        int slot = _root.Children.IndexOf(_formScroll);
        if (slot >= 0) _root.Children[slot] = _progress;
        else if (!_root.Children.Contains(_progress)) _root.Children.Insert(0, _progress);
        // The closing button is present throughout so the footer never
        // reflows; it becomes usable once the work ends.
        PrimaryButtonText = "Close";
        IsPrimaryButtonEnabled = false;
        CloseButtonText = "Cancel";
    }

    private void FinishProgress()
    {
        IsPrimaryButtonEnabled = true;
        CloseButtonText = "";
    }

    private void ShowValidation(string message)
    {
        _validationText.Text = message;
        _validationText.Visibility = Visibility.Visible;
    }

    private JObject BuildConfiguration(string code, string name)
    {
        var sections = ParsedSectionNumbers(_sectionsBox.Text);
        JObject PerSection(Func<int, JToken> value)
        {
            var map = new JObject();
            foreach (int n in sections) map["section" + n] = value(n);
            return new JObject { ["sections"] = map };
        }
        var flatSchemes = new JObject();
        foreach (int n in sections) flatSchemes["section" + n] = _schemeId;

        string locale = _localeBox.SelectedIndex >= 0
            ? LocaleCatalog.Codes[_localeBox.SelectedIndex]
            : WizardDefaults.DefaultLocale;

        var allItems = _sharedFolders.Concat(_sharedFiles).Concat(_perSectionFolders).Concat(_perSectionFiles).ToHashSet();
        var hidden = WizardDefaults.HiddenItems.Where(i => allItems.Contains(i) || i == "Media").ToList();
        var expandableSource = _sharedFolders.Concat(_perSectionFolders).ToHashSet();
        var expandable = WizardDefaults.ExpandableItems.Where(expandableSource.Contains).ToList();

        return new JObject
        {
            ["course_code"] = code,
            ["course_name"] = name,
            ["custom_short_name"] = IsClubCode(code) ? _shortBox.Text.Trim() : "",
            ["locale"] = locale,
            ["emojis"] = PerSection(_ => _emoji),
            ["num_sections"] = sections.Count,
            ["section_numbers"] = new JArray(sections),
            ["shared_folders"] = new JArray(_sharedFolders),
            ["shared_files"] = new JArray(_sharedFiles),
            ["per_section_folders"] = new JArray(_perSectionFolders),
            ["per_section_files"] = new JArray(_perSectionFiles),
            ["hidden"] = new JArray(hidden),
            ["expandable"] = new JArray(expandable),
            ["expandOnFolderClick"] = _expandOnFolderClick,
            ["footer_html"] = _footerHtml,
            ["show_reading_time"] = _showReadingTime,
            ["show_grade_in_title"] = PerSection(_ => _showsGrade),
            ["fonts"] = new JObject
            {
                ["default"] = _fontChoice.ToJson(),
                ["sections"] = PerSection(_ => _fontChoice.ToJson())["sections"],
            },
            ["show_section_marker"] = PerSection(_ => _showsMarker),
            ["color_schemes"] = flatSchemes,
        };
    }
}
