using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using System.Threading.Tasks;
using Microsoft.UI.Text;
using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Documents;
using Microsoft.UI.Xaml.Media;
using Microsoft.UI.Xaml.Media.Imaging;
using Newtonsoft.Json.Linq;
using Plantoir.Core.Assist;
using Plantoir.Core.Models;
using Plantoir.Core.Scripting;
using Plantoir.ViewModels;
using Plantoir.Views;
using Windows.Graphics;
using Windows.Graphics.Imaging;
using Windows.Storage.Streams;

namespace Plantoir.Services;

/// <summary>
/// Autonomous screenshot capture harness for Windows marketing shots.
/// Takes pixel-perfect captures for all 5 app-window marketing shots (courses,
/// new-course, progress, preview, assistant) in both Light and Dark appearance.
/// </summary>
public static class MarketingShotCapturer
{
    private static readonly string[] DemoCodes = { "ENG2D", "MCV4U", "SCH3U" };
    private static string LogPath => Path.Combine(Path.GetTempPath(), "marketing_capture.log");

    public static void Log(string message)
    {
        try
        {
            File.AppendAllText(LogPath, $"[{DateTime.UtcNow:HH:mm:ss.fff}] {message}\n");
        }
        catch { }
    }

    public static async Task RunAsync(string outputDir)
    {
        try
        {
            outputDir = Path.GetFullPath(outputDir);
            Directory.CreateDirectory(outputDir);
            Log($"Starting marketing capture to {outputDir}");

            string workspacePath = Path.Combine(Path.GetTempPath(), "PlantoirMarketingWorkspace");
            ProvisionDemoWorkspace(workspacePath);
            Log($"Workspace provisioned at {workspacePath}");

            foreach (var theme in new[] { ElementTheme.Light, ElementTheme.Dark })
            {
                string themeName = theme == ElementTheme.Dark ? "dark" : "light";
                Log($"--- Capturing theme: {themeName} ---");

                // ---- 1. Shot: courses ----
                string coursesPath = Path.Combine(outputDir, $"courses-windows-{themeName}.png");
                await CaptureCoursesWindow(workspacePath, theme, coursesPath);
                Log($"Saved {coursesPath}");

                // ---- 2. Shot: new-course ----
                string newCoursePath = Path.Combine(outputDir, $"new-course-windows-{themeName}.png");
                await CaptureNewCourseWindow(workspacePath, theme, newCoursePath);
                Log($"Saved {newCoursePath}");

                // ---- 3. Shot: progress ----
                string progressPath = Path.Combine(outputDir, $"progress-windows-{themeName}.png");
                await CaptureProgressWindow(workspacePath, theme, progressPath);
                Log($"Saved {progressPath}");

                // ---- 4. Shot: preview ----
                string previewPath = Path.Combine(outputDir, $"preview-windows-{themeName}.png");
                await CapturePreviewWindow(workspacePath, theme, previewPath);
                Log($"Saved {previewPath}");

                // ---- 5. Shot: assistant ----
                string assistPath = Path.Combine(outputDir, $"assistant-windows-{themeName}.png");
                await CaptureAssistantWindow(workspacePath, theme, assistPath);
                Log($"Saved {assistPath}");
            }

            Log("Capture finished successfully.");
        }
        catch (Exception ex)
        {
            Log($"Capture failed: {ex}");
        }
        finally
        {
            Environment.Exit(0);
        }
    }

    private static void ProvisionDemoWorkspace(string workspacePath)
    {
        if (Directory.Exists(workspacePath))
        {
            try { Directory.Delete(workspacePath, recursive: true); } catch { }
        }
        Directory.CreateDirectory(workspacePath);

        string repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "..", ".."));
        string exampleContentDir = Path.Combine(repoRoot, "support", "example_content");
        if (!Directory.Exists(exampleContentDir))
            exampleContentDir = Path.Combine(Directory.GetCurrentDirectory(), "support", "example_content");

        string coursesDir = Path.Combine(workspacePath, "courses");
        Directory.CreateDirectory(coursesDir);

        foreach (string code in DemoCodes)
        {
            string courseTarget = Path.Combine(coursesDir, code);
            Directory.CreateDirectory(courseTarget);

            string sourceDir = Path.Combine(exampleContentDir, code);
            if (Directory.Exists(sourceDir))
            {
                string manifestPath = Path.Combine(sourceDir, "manifest.json");
                if (File.Exists(manifestPath))
                {
                    var manifest = JObject.Parse(File.ReadAllText(manifestPath));
                    var configObj = new JObject
                    {
                        ["course_name"] = manifest["course_name"]?.ToString() ?? code,
                        ["course_code"] = code,
                        ["section_count"] = 1,
                        ["colour_scheme"] = manifest["colour_scheme"]?.ToString() ?? "default",
                        ["header_font"] = manifest["header_font"]?.ToString() ?? "serif",
                        ["body_font"] = manifest["body_font"]?.ToString() ?? "sans-serif",
                        ["use_literal_grade_markers"] = false,
                        ["use_lcs_terminology"] = false,
                        ["deploy_target"] = "netlify",
                        ["deploy_site_name"] = $"{code.ToLowerInvariant()}-gordon-2026-27"
                    };
                    var config = CourseConfiguration.FromDictionary(configObj);
                    config.Write(Path.Combine(courseTarget, "course_config.json"));
                }

                string sharedSrc = Path.Combine(sourceDir, "shared");
                if (Directory.Exists(sharedSrc))
                    CopyDirectory(sharedSrc, Path.Combine(courseTarget, "shared"));

                string sectionSrc = Path.Combine(sourceDir, "per_section");
                if (Directory.Exists(sectionSrc))
                    CopyDirectory(sectionSrc, Path.Combine(courseTarget, "section1"));
            }
        }
    }

    private static void CopyDirectory(string source, string target)
    {
        Directory.CreateDirectory(target);
        foreach (string file in Directory.GetFiles(source))
        {
            string dest = Path.Combine(target, Path.GetFileName(file));
            string content = File.ReadAllText(file);
            content = content.Replace("__CREATED__", "2026-09-08T07:00:00Z");
            content = System.Text.RegularExpressions.Regex.Replace(content, @"__CREATED_CLASS_\d+__", "2026-10-14T07:00:00Z");
            File.WriteAllText(dest, content);
        }
        foreach (string dir in Directory.GetDirectories(source))
        {
            CopyDirectory(dir, Path.Combine(target, Path.GetFileName(dir)));
        }
    }

    private static async Task CaptureCoursesWindow(string workspacePath, ElementTheme theme, string outputPath)
    {
        var window = new MainWindow(workspacePath, null);
        ConfigureWindow(window, 1280, 800, theme);
        window.Activate();

        await Task.Delay(500);
        window.Workspace.Selection = new SidebarSelection.SectionItem("ENG2D", 1);
        await Task.Delay(500);

        await SaveWindowContentToPngAsync(window, outputPath);
        window.Close();
    }

    private static async Task CaptureNewCourseWindow(string workspacePath, ElementTheme theme, string outputPath)
    {
        var window = new MainWindow(workspacePath, null);
        ConfigureWindow(window, 1280, 800, theme);
        window.Activate();

        await Task.Delay(500);
        window.Workspace.Selection = new SidebarSelection.SectionItem("ENG2D", 1);
        await Task.Delay(400);

        // Stage dialog
        var dialog = new NewCourseDialog(window) { XamlRoot = window.Content.XamlRoot };
        dialog.RequestedTheme = theme;
        dialog.StageForCapture("ENG2D", "1");
        _ = dialog.ShowAsync();
        await Task.Delay(700);

        await SaveWindowContentToPngAsync(window, outputPath);
        dialog.Hide();
        window.Close();
    }

    private static async Task CaptureProgressWindow(string workspacePath, ElementTheme theme, string outputPath)
    {
        var window = new MainWindow(workspacePath, null);
        ConfigureWindow(window, 1280, 800, theme);
        window.Activate();

        await Task.Delay(500);
        window.Workspace.Selection = new SidebarSelection.SectionItem("ENG2D", 1);

        // Stage progress view
        var runner = new ScriptRunner(System.Threading.SynchronizationContext.Current);
        var progressView = new TaskProgressView();
        progressView.RequestedTheme = theme;
        progressView.Show(runner, "Publishing ENG2D Section 1");
        window.DetailPresenter.Content = progressView;

        runner.Milestones = TaskMilestones.Deploy;
        runner.ReceiveOutput("Setting up this PC\nBuilding your website builder\nEnsuring container is running\nDeploying from local build\nNetlify site\ndelta deploy manifest\nDelta deploy created: 25 of 230\n");

        await Task.Delay(600);
        await SaveWindowContentToPngAsync(window, outputPath);
        window.Close();
    }

    private static async Task CapturePreviewWindow(string workspacePath, ElementTheme theme, string outputPath)
    {
        var window = new MainWindow(workspacePath, null);
        ConfigureWindow(window, 1280, 800, theme);
        window.Activate();

        await Task.Delay(500);
        window.Workspace.Selection = new SidebarSelection.SectionItem("ENG2D", 1);
        await Task.Delay(600);

        await SaveWindowContentToPngAsync(window, outputPath);
        window.Close();
    }

    private static async Task CaptureAssistantWindow(string workspacePath, ElementTheme theme, string outputPath)
    {
        var configObj = new JObject
        {
            ["course_name"] = "Grade 10 English",
            ["course_code"] = "ENG2D",
            ["section_count"] = 1,
            ["colour_scheme"] = "default",
            ["header_font"] = "serif",
            ["body_font"] = "sans-serif",
            ["use_literal_grade_markers"] = false,
            ["use_lcs_terminology"] = false,
            ["deploy_target"] = "netlify",
            ["deploy_site_name"] = "eng2d-gordon-2026-27"
        };
        var config = CourseConfiguration.FromDictionary(configObj);
        var course = new Course("ENG2D", Path.Combine(workspacePath, "courses", "ENG2D"), config);

        var window = new AssistWindow(workspacePath, course, 1);
        ConfigureWindow(window, 560, 760, theme);
        window.Activate();

        await Task.Delay(500);

        // Stage message bubbles
        var teacherMsg = new TextBlock
        {
            Text = "Publish tomorrow's class",
            TextWrapping = TextWrapping.Wrap,
            Style = (Style)Application.Current.Resources["BodyTextBlockStyle"]
        };
        window.AddStagedBubbleForCapture("You", true, teacherMsg);

        var assistMsg = new TextBlock
        {
            TextWrapping = TextWrapping.Wrap,
            Style = (Style)Application.Current.Resources["BodyTextBlockStyle"]
        };
        assistMsg.Inlines.Add(new Run { Text = "Tomorrow's class is " });
        assistMsg.Inlines.Add(new Run { Text = "Unit 3, Day 2: Writing a Thesis Statement", FontWeight = FontWeights.SemiBold });
        assistMsg.Inlines.Add(new Run { Text = " (2026-10-14)." });
        window.AddStagedBubbleForCapture("Assistant", false, assistMsg);

        var planPanel = new StackPanel { Spacing = 6 };
        var planHeader = new TextBlock
        {
            Text = "Shall I go ahead?",
            FontWeight = FontWeights.SemiBold,
            Style = (Style)Application.Current.Resources["BodyTextBlockStyle"]
        };
        var planBody = new TextBlock
        {
            Text = "This will make 1 page visible to students:\n• Unit 3, Day 2: Writing a Thesis Statement",
            TextWrapping = TextWrapping.Wrap,
            Style = (Style)Application.Current.Resources["BodyTextBlockStyle"]
        };
        var btnRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 8, Margin = new Thickness(0, 4, 0, 0) };
        var btnGo = new Button { Content = "Go", Style = (Style)Application.Current.Resources["AccentButtonStyle"] };
        var btnCancel = new Button { Content = "Cancel" };
        btnRow.Children.Add(btnGo);
        btnRow.Children.Add(btnCancel);

        planPanel.Children.Add(planHeader);
        planPanel.Children.Add(planBody);
        planPanel.Children.Add(btnRow);
        window.AddStagedBubbleForCapture("Assistant", false, planPanel);

        await Task.Delay(600);
        await SaveWindowContentToPngAsync(window, outputPath);
        window.Close();
    }

    private static void ConfigureWindow(Window window, int width, int height, ElementTheme theme)
    {
        window.AppWindow.Resize(new SizeInt32(width, height));
        if (window.Content is FrameworkElement root)
        {
            root.RequestedTheme = theme;
            root.Width = width;
            root.Height = height;
        }
    }

    private static async Task SaveWindowContentToPngAsync(Window window, string outputPath)
    {
        if (window.Content is not UIElement element) return;

        var rtb = new RenderTargetBitmap();
        await rtb.RenderAsync(element);

        var buffer = await rtb.GetPixelsAsync();
        byte[] pixels = buffer.ToArray();

        using var fileStream = File.Create(outputPath);
        using var randomStream = fileStream.AsRandomAccessStream();
        var encoder = await BitmapEncoder.CreateAsync(BitmapEncoder.PngEncoderId, randomStream);
        encoder.SetPixelData(
            BitmapPixelFormat.Bgra8,
            BitmapAlphaMode.Premultiplied,
            (uint)rtb.PixelWidth,
            (uint)rtb.PixelHeight,
            96,
            96,
            pixels);
        await encoder.FlushAsync();
    }
}
