using System;
using System.Linq;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Plantoir.Core.Models;

namespace Plantoir.Views;

/// <summary>
/// "Add a Section to CODE": a digits-only number field with a stepper,
/// live orange validation in a reserved slot (the sheet never jumps), and
/// an Add button enabled only when the entry names an addable section.
/// A failed add keeps the dialog open — the whole point is a chance to
/// correct and try again.
/// </summary>
public sealed class AddSectionDialog : ContentDialog
{
    public int? AddedNumber { get; private set; }

    private readonly Course _course;
    private readonly TextBox _numberBox = new() { Width = 64, TextAlignment = TextAlignment.Right };
    private readonly TextBlock _warningSlot = new()
    {
        FontSize = 12,
        TextWrapping = TextWrapping.Wrap,
        MinHeight = 26,
    };

    public AddSectionDialog(Course course)
    {
        _course = course;
        Title = $"Add a Section to {course.Code}";
        PrimaryButtonText = "Add Section";
        CloseButtonText = "Cancel";
        DefaultButton = ContentDialogButton.Primary;
        PrimaryButtonClick += OnAdd;

        var existing = course.SectionNumbers;
        string existingSentence = existing.Count switch
        {
            0 => $"{course.Code} has no sections yet.",
            1 => $"{course.Code} already has section {existing[0]}.",
            _ => $"{course.Code} already has sections {JoinWithAnd(existing)}.",
        };

        _numberBox.Text = SectionAdder.SuggestedNumber(existing).ToString();
        _numberBox.TextChanged += (_, _) =>
        {
            // Digits only — non-digits never land in the field.
            string digits = new(_numberBox.Text.Where(char.IsAsciiDigit).ToArray());
            if (digits != _numberBox.Text)
            {
                int caret = _numberBox.SelectionStart;
                _numberBox.Text = digits;
                _numberBox.SelectionStart = Math.Min(caret, digits.Length);
            }
            RefreshValidation();
        };

        var stepper = new StackPanel { Orientation = Orientation.Vertical, Spacing = 0 };
        var up = StepButton("", +1);
        var down = StepButton("", -1);
        stepper.Children.Add(up);
        stepper.Children.Add(down);

        var numberRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 4 };
        numberRow.Children.Add(new TextBlock { Text = "Section number:", VerticalAlignment = VerticalAlignment.Center });
        numberRow.Children.Add(_numberBox);
        numberRow.Children.Add(stepper);

        var panel = new StackPanel { Spacing = 12, MinWidth = 300 };
        panel.Children.Add(new TextBlock { Text = existingSentence, FontSize = 12, Opacity = 0.7, TextWrapping = TextWrapping.Wrap });
        panel.Children.Add(numberRow);
        panel.Children.Add(_warningSlot);
        Content = panel;
        RefreshValidation();
    }

    private Button StepButton(string glyph, int delta)
    {
        var button = new Button
        {
            Content = new FontIcon { Glyph = glyph, FontSize = 8 },
            Padding = new Thickness(4, 0, 4, 0),
            MinWidth = 24,
            MinHeight = 15,
        };
        button.Click += (_, _) =>
        {
            var existing = _course.SectionNumbers;
            // An empty field steps to the suggestion rather than from nowhere.
            int current = int.TryParse(_numberBox.Text, out int n) ? n : SectionAdder.SuggestedNumber(existing) - delta;
            _numberBox.Text = Math.Max(1, current + delta).ToString();
            RefreshValidation();
        };
        return button;
    }

    private void RefreshValidation()
    {
        var existing = _course.SectionNumbers;
        string? problem = SectionAdder.EntryProblem(_numberBox.Text, existing, _course.Code);
        _warningSlot.Text = problem ?? " ";
        _warningSlot.Foreground = (Brush)Application.Current.Resources["SystemFillColorCautionBrush"];
        IsPrimaryButtonEnabled = SectionAdder.EntryIsAddable(_numberBox.Text, existing);
    }

    private void OnAdd(ContentDialog sender, ContentDialogButtonClickEventArgs args)
    {
        if (!int.TryParse(_numberBox.Text, out int number)) { args.Cancel = true; return; }
        try
        {
            SectionAdder.AddSection(number, _course);
            AddedNumber = number;
        }
        catch (SectionAdder.SectionAddException error)
        {
            _warningSlot.Text = error.Message;
            args.Cancel = true;   // stay open: a chance to correct
        }
    }

    private static string JoinWithAnd(System.Collections.Generic.IReadOnlyList<int> numbers)
    {
        if (numbers.Count == 1) return numbers[0].ToString();
        return string.Join(", ", numbers.Take(numbers.Count - 1)) + " and " + numbers[^1];
    }
}
