using System.Text.RegularExpressions;
using Plantoir.Core.Assist;

namespace Plantoir.Mcp;

/// <summary>
/// Getting a timetable's CSV, from a file on this computer or from a shared
/// spreadsheet the teacher names.
///
/// **This is the only place the server reaches the network**, and it does so
/// only when a teacher pastes a link. Everything else about AI Assist works
/// offline by design, because course material can name students. A timetable
/// is the exception worth making: it is a school-wide document with no student
/// data in it, and asking a teacher to export a CSV by hand every time the
/// schedule shifts is the kind of friction that means the feature goes unused.
/// </summary>
public static class TimetableSource
{
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(30) };

    /// <summary>A Google Sheets link in any of its usual forms.</summary>
    private static readonly Regex GoogleSheet = new(
        @"docs\.google\.com/spreadsheets/d/(?<id>[A-Za-z0-9_-]+)", RegexOptions.IgnoreCase);

    public static async Task<string> Read(string source, CancellationToken cancellation)
    {
        string value = source.Trim();
        if (value.Length == 0) throw new AssistRefusal("No timetable was given.");

        if (!value.StartsWith("http://", StringComparison.OrdinalIgnoreCase) &&
            !value.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            if (!File.Exists(value))
                throw new AssistRefusal($"There’s no file at “{value}”, and it isn’t a web address either.");
            return await File.ReadAllTextAsync(value, cancellation);
        }

        // A Sheets "edit" link is a web page, not data. Its own CSV export is.
        var match = GoogleSheet.Match(value);
        string url = match.Success
            ? $"https://docs.google.com/spreadsheets/d/{match.Groups["id"].Value}/export?format=csv"
            : value;

        try
        {
            using var response = await Http.GetAsync(url, cancellation);
            if (!response.IsSuccessStatusCode)
                throw new AssistRefusal(Explain(response.StatusCode, match.Success));
            string body = await response.Content.ReadAsStringAsync(cancellation);
            if (body.TrimStart().StartsWith("<", StringComparison.Ordinal))
                throw new AssistRefusal(
                    "That link returned a web page rather than a spreadsheet. If it is a Google Sheet, " +
                    "share it so that anyone with the link can view it.");
            return body;
        }
        catch (AssistRefusal) { throw; }
        catch (TaskCanceledException) { throw new AssistRefusal("That timetable took too long to fetch."); }
        catch (HttpRequestException error)
        {
            throw new AssistRefusal($"That timetable couldn’t be fetched: {error.Message}");
        }
    }

    private static string Explain(System.Net.HttpStatusCode status, bool isGoogleSheet) =>
        status is System.Net.HttpStatusCode.Forbidden or System.Net.HttpStatusCode.Unauthorized
            ? isGoogleSheet
                ? "That Google Sheet isn’t readable without signing in. Share it so anyone with the link can " +
                  "view it, or download it as a CSV and give the file path instead."
                : "That address refused the request. If it needs a sign-in, download the CSV and give its path."
            : $"That address returned {(int)status}.";
}
