using System.Collections.Generic;
using System.Text.Json;

namespace Plantoir.Core.Assist;

/// <summary>
/// What the teacher has asked for before, and where they are in it while the
/// arrow keys walk back through it. Modelled on terminal prompt history.
/// </summary>
public sealed class AssistPromptHistory
{
    private readonly List<string> _entries = new();
    private int? _position;
    private string _draft = "";

    public const int MostRemembered = 50;

    public IReadOnlyList<string> Entries => _entries;
    public bool IsBrowsing => _position.HasValue;

    public AssistPromptHistory(IEnumerable<string>? initial = null)
    {
        if (initial != null)
        {
            foreach (var item in initial)
            {
                Remember(item);
            }
        }
    }

    public string Stored
    {
        get
        {
            try
            {
                return JsonSerializer.Serialize(_entries);
            }
            catch
            {
                return "[]";
            }
        }
    }

    public static AssistPromptHistory Read(string? stored)
    {
        if (string.IsNullOrWhiteSpace(stored)) return new AssistPromptHistory();
        try
        {
            var list = JsonSerializer.Deserialize<List<string>>(stored);
            return new AssistPromptHistory(list);
        }
        catch
        {
            return new AssistPromptHistory();
        }
    }

    public void Remember(string prompt)
    {
        string trimmed = prompt.Trim();
        StopBrowsing();
        if (string.IsNullOrEmpty(trimmed)) return;
        if (_entries.Count > 0 && _entries[^1] == trimmed) return;

        _entries.Add(trimmed);
        while (_entries.Count > MostRemembered)
        {
            _entries.RemoveAt(0);
        }
    }

    public string? Earlier(string typed)
    {
        if (_entries.Count == 0) return null;
        if (!_position.HasValue)
        {
            _draft = typed;
            _position = _entries.Count - 1;
            return _entries[^1];
        }

        if (_position.Value == 0) return null;
        _position = _position.Value - 1;
        return _entries[_position.Value];
    }

    public string? Later()
    {
        if (!_position.HasValue) return null;

        if (_position.Value + 1 < _entries.Count)
        {
            _position = _position.Value + 1;
            return _entries[_position.Value];
        }

        string waiting = _draft;
        StopBrowsing();
        return waiting;
    }

    public void StopBrowsing()
    {
        _position = null;
        _draft = "";
    }
}
