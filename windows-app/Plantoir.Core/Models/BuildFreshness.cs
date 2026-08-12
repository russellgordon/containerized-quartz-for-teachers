namespace Plantoir.Core.Models;

/// <summary>
/// Decides whether Deploy must rebuild first: publish only what reflects
/// the current content.
/// </summary>
public static class BuildFreshness
{
    public static bool NeedsRebuild(Course course, int sectionNumber)
    {
        string builtIndex = Path.Combine(course.DirectoryPath, ".merged_output",
            "section" + sectionNumber, "public", "index.html");
        DateTime builtDate;
        try { builtDate = File.GetLastWriteTimeUtc(builtIndex); }
        catch { return true; }
        if (!File.Exists(builtIndex)) return true;

        // A preview's build is never deploy-fresh: serve mode bakes a
        // live-reload client pointed at ws://localhost into every page, and
        // publishing that makes browsers ask to "access other apps and
        // services on this device" on the live site.
        if (BuiltForPreview(builtIndex)) return true;

        DateTime? contentDate = NewestContentDate(course.DirectoryPath);
        if (contentDate is null) return false;   // nothing readable: nothing to rebuild for
        return contentDate > builtDate;
    }

    /// <summary>True when the built page carries the preview server's live-reload client.</summary>
    internal static bool BuiltForPreview(string builtIndexPath)
    {
        try { return File.ReadAllText(builtIndexPath).Contains("ws://localhost:", StringComparison.Ordinal); }
        catch { return true; }   // unreadable: rebuild rather than trust it
    }

    /// <summary>
    /// Newest change anywhere in the course, skipping dot-prefixed entries at
    /// every level — which excludes the generated .merged_output, the
    /// .netlify_sites markers, and Obsidian's .obsidian settings. (On Windows
    /// "hidden" means a leading dot, not the file attribute.)
    /// </summary>
    internal static DateTime? NewestContentDate(string root)
    {
        DateTime? newest = null;
        void Visit(string dir)
        {
            IEnumerable<string> entries;
            try { entries = Directory.EnumerateFileSystemEntries(dir); }
            catch { return; }
            foreach (string entry in entries)
            {
                string name = Path.GetFileName(entry);
                if (name.StartsWith('.')) continue;
                DateTime stamp;
                try { stamp = File.GetLastWriteTimeUtc(entry); }
                catch { continue; }
                if (newest is null || stamp > newest) newest = stamp;
                if (Directory.Exists(entry)) Visit(entry);
            }
        }
        Visit(root);
        return newest;
    }
}
