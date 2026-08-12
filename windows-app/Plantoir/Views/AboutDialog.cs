using System;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;

namespace Plantoir.Views;

/// <summary>The About panel: icon, name, version, tagline, the namesake story, support links, credits.</summary>
public sealed class AboutDialog : ContentDialog
{
    public AboutDialog()
    {
        Title = "About Plantoir";
        CloseButtonText = "Close";

        var panel = new StackPanel { Spacing = 0, MaxWidth = 460 };

        // The app icon beside the text column, as the mac About arranges it.
        var layout = new Grid { ColumnSpacing = 20 };
        layout.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
        layout.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
        var icon = new Image
        {
            Width = 96,
            Height = 96,
            VerticalAlignment = VerticalAlignment.Top,
            Margin = new Thickness(0, 6, 0, 0),
            Source = new Microsoft.UI.Xaml.Media.Imaging.BitmapImage(
                new Uri("ms-appx:///Assets/PlantoirIcon.png")),
        };
        layout.Children.Add(icon);
        Grid.SetColumn(panel, 1);
        layout.Children.Add(panel);

        panel.Children.Add(new TextBlock { Text = "Plantoir", FontSize = 26, FontWeight = FontWeights.Bold });
        string version = typeof(AboutDialog).Assembly.GetName().Version?.ToString(3) ?? "1.0.0";
        panel.Children.Add(new TextBlock
        {
            Text = $"Version {version}",
            FontSize = 12,
            Opacity = 0.7,
            Margin = new Thickness(0, 2, 0, 0),
        });
        panel.Children.Add(new TextBlock
        {
            Text = "Turns a folder of Markdown notes into a fast, searchable class website you own.",
            TextWrapping = TextWrapping.Wrap,
            FontSize = 12,
            Margin = new Thickness(0, 14, 0, 0),
        });
        panel.Children.Add(new TextBlock
        {
            Text = "A plantoir is a dibber — the simple hand tool that opens a hole at the right depth so a seedling can be set in and take root. This app does the same for teaching materials. Write in Obsidian, preview locally, publish when you're ready.",
            TextWrapping = TextWrapping.Wrap,
            FontSize = 12,
            Opacity = 0.7,
            Margin = new Thickness(0, 8, 0, 0),
        });

        var support = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 16, Margin = new Thickness(0, 18, 0, 0) };
        support.Children.Add(new TextBlock { Text = "Support", FontSize = 12, Opacity = 0.7 });
        support.Children.Add(Link("https://plantoir.app/support", "plantoir.app/support"));
        panel.Children.Add(support);

        var credits = new StackPanel { Spacing = 3, Margin = new Thickness(0, 18, 0, 0) };
        credits.Children.Add(CreditLine("Built on ", "Quartz", "https://quartz.jzhao.xyz", " by Jacky Zhao."));
        credits.Children.Add(new TextBlock { Text = "Designed by Russell Gordon.", FontSize = 11, Opacity = 0.7 });
        credits.Children.Add(new TextBlock { Text = "Made with Claude.", FontSize = 11, Opacity = 0.7 });
        credits.Children.Add(CreditLine("Please ", "sponsor Jacky", "https://github.com/sponsors/jackyzha0",
            " — his work makes this app possible."));
        panel.Children.Add(credits);

        panel.Children.Add(new TextBlock
        {
            Text = "Copyright 2026 Russell Gordon",
            FontSize = 11,
            Opacity = 0.7,
            Margin = new Thickness(0, 14, 0, 0),
        });

        Content = layout;
    }

    private static HyperlinkButton Link(string uri, string label) => new()
    {
        Content = label,
        NavigateUri = new Uri(uri),
        Padding = new Thickness(0),
        FontSize = 12,
    };

    private static TextBlock CreditLine(string before, string linkText, string uri, string after)
    {
        var block = new TextBlock { FontSize = 11, Opacity = 0.7, TextWrapping = TextWrapping.Wrap };
        block.Inlines.Add(new Run { Text = before });
        var link = new Hyperlink { NavigateUri = new Uri(uri) };
        link.Inlines.Add(new Run { Text = linkText });
        block.Inlines.Add(link);
        block.Inlines.Add(new Run { Text = after });
        return block;
    }
}
