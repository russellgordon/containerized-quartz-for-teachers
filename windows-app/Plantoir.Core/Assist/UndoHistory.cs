namespace Plantoir.Core.Assist;

/// <summary>
/// What this session changed, so a teacher who published the wrong class can
/// say "undo that" and get exactly that back.
///
/// A whole-course backup is taken before every write and is the durable safety
/// net, but it is a sledgehammer: restoring it puts the entire course back,
/// losing anything else done since. The common mistake is small and recent —
/// the wrong class, in a rush, thirty seconds ago — and it deserves a small
/// and recent fix.
///
/// Deliberately **in memory and session-scoped**. It lives as long as the
/// server process, which lives as long as the teacher's conversation, and goes
/// when that does. Nothing accumulates on disk, nothing has to be pruned, and
/// there is no second store of course content to fall out of step with the
/// files. For anything older than the conversation, the backups are the
/// answer, and they are what the undo tool points at once its own history runs
/// out.
///
/// Every entry stores what each file held BEFORE and what this session wrote
/// AFTER. The "after" is the important half: on undo, a file whose contents no
/// longer match what we wrote has been changed by someone else — Obsidian, the
/// teacher, another session — and putting our old copy back would destroy
/// their work. Those are reported and skipped rather than overwritten.
/// </summary>
public sealed class UndoHistory
{
    /// <summary>One operation, and the files it touched.</summary>
    public sealed record Entry(string Description, DateTime When, IReadOnlyDictionary<string, FileState> Files);

    /// <summary>What a file held before and after. Null means it did not exist.</summary>
    public readonly record struct FileState(string? Before, string? After);

    private readonly List<Entry> _entries = new();
    private Dictionary<string, FileState>? _open;
    private string _description = "";

    /// <summary>How many operations back a teacher can go before the backups take over.</summary>
    private const int MostRemembered = 20;

    public IReadOnlyList<Entry> Entries => _entries;

    /// <summary>Start recording an operation. Nested calls are ignored — the outermost wins.</summary>
    public void Begin(string description)
    {
        if (_open is not null) return;
        _open = new Dictionary<string, FileState>(StringComparer.OrdinalIgnoreCase);
        _description = description;
    }

    /// <summary>
    /// Note a file about to be written. Called before the write, so the
    /// "before" is genuinely what was there.
    /// </summary>
    public void Touch(string path, string? before)
    {
        if (_open is null) return;
        // Only the FIRST before matters: if one operation writes a file twice,
        // undoing it should reach back past both writes.
        if (!_open.ContainsKey(path)) _open[path] = new FileState(before, null);
    }

    /// <summary>Note what was actually written, so a later change by someone else is detectable.</summary>
    public void Wrote(string path, string? after)
    {
        if (_open is null || !_open.TryGetValue(path, out var state)) return;
        _open[path] = state with { After = after };
    }

    /// <summary>Finish recording. An operation that changed nothing is not remembered.</summary>
    public void End()
    {
        if (_open is null) return;
        var touched = _open.Where(f => f.Value.Before != f.Value.After)
            .ToDictionary(f => f.Key, f => f.Value, StringComparer.OrdinalIgnoreCase);
        if (touched.Count > 0)
        {
            _entries.Add(new Entry(_description, DateTime.Now, touched));
            while (_entries.Count > MostRemembered) _entries.RemoveAt(0);
        }
        _open = null;
    }

    /// <summary>Abandon recording, for an operation that threw partway.</summary>
    public void Abandon() => _open = null;

    /// <summary>
    /// Put the most recent operation back. Files somebody else has changed
    /// since are left alone and named, because our copy of them is stale and
    /// writing it would destroy whatever they did.
    /// </summary>
    public UndoResult Undo()
    {
        if (_entries.Count == 0)
            return new UndoResult(false, "This conversation hasn’t changed anything yet.",
                Array.Empty<string>(), Array.Empty<string>());

        var entry = _entries[^1];
        var restored = new List<string>();
        var skipped = new List<string>();

        foreach (var (path, state) in entry.Files)
        {
            string? current;
            try { current = File.Exists(path) ? File.ReadAllText(path) : null; }
            catch { skipped.Add(path); continue; }

            if (current != state.After) { skipped.Add(path); continue; }

            try
            {
                if (state.Before is null) File.Delete(path);
                else File.WriteAllText(path, state.Before);
                restored.Add(path);
            }
            catch { skipped.Add(path); }
        }

        // Only forget the operation once it has actually been put back. A
        // half-undone change stays on the list so the teacher can try again
        // after sorting out whatever is holding the other files.
        if (skipped.Count == 0) _entries.RemoveAt(_entries.Count - 1);

        return new UndoResult(restored.Count > 0, entry.Description, restored, skipped);
    }
}

/// <summary>How an undo went.</summary>
public sealed record UndoResult(
    bool Succeeded, string Description, IReadOnlyList<string> Restored, IReadOnlyList<string> Skipped);
