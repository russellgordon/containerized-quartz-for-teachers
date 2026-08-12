using System;
using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;

namespace Plantoir.Services;

/// <summary>
/// One remembered window: its folder, frame, and sidebar state (row 99).
/// The three sidebar fields are optional so entries written before they
/// existed still load: a null ExpandedCourses restores all-expanded (the
/// Windows fallback), null Selection restores none.
/// </summary>
public sealed record RememberedWindow(string Path, double X, double Y, double Width, double Height,
                                      string? ExpandedCourses = null, bool ShowsArchived = false,
                                      string? Selection = null, bool ShowsBackups = false);

/// <summary>
/// The app's own settings store (%LOCALAPPDATA%\Plantoir\settings.json).
/// Windows has no system window restoration, so the remembered-windows
/// list IS the restoration mechanism — recorded at quit while the windows
/// still exist, replayed at launch when the preference asks for it.
/// </summary>
public sealed class AppSettings
{
    public string? WorkspacePath { get; set; }
    public List<RememberedWindow> RememberedWindows { get; set; } = new();
    /// <summary>No OS-level setting exists here, so it is an app preference — default restore.</summary>
    public bool RestoreWindowsOnLaunch { get; set; } = true;

    public static string DefaultPath =>
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                     "Plantoir", "settings.json");

    public static AppSettings Load(string? path = null)
    {
        try
        {
            string file = path ?? DefaultPath;
            if (File.Exists(file) &&
                JsonConvert.DeserializeObject<AppSettings>(File.ReadAllText(file)) is { } settings)
            {
                // A stored folder that no longer exists must not be presented
                // as the working folder.
                if (settings.WorkspacePath is not null && !Directory.Exists(settings.WorkspacePath))
                    settings.WorkspacePath = null;
                settings.RememberedWindows.RemoveAll(w => !Directory.Exists(w.Path));
                return settings;
            }
        }
        catch { }
        return new AppSettings();
    }

    public void Save(string? path = null)
    {
        try
        {
            string file = path ?? DefaultPath;
            Directory.CreateDirectory(Path.GetDirectoryName(file)!);
            File.WriteAllText(file, JsonConvert.SerializeObject(this, Formatting.Indented));
        }
        catch { }
    }
}
