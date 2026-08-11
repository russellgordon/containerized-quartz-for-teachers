using System.Text;
using System.Text.RegularExpressions;
using Plantoir.Core.Scripting;

// PtyDriver — runs a command under a ConPTY, logs cleaned output, and
// auto-answers prompts from scripted rules. A test harness for the
// launchers, exercising the same ConPtyProcess the app uses.
//
// Usage:
//   PtyDriver --cwd DIR --log FILE [--rule "regex=>reply"]... [--timeout SEC]
//             [--settle MS] -- COMMAND LINE...
//
// A rule fires when the transcript's last non-empty line matches the regex,
// output has been silent for the settle window, and NEW output has arrived
// since the last reply (the mac app's respondedLength guard). Replies:
// text (sent + Enter), {ENTER}, {RIGHT} (ESC[C), {Q}. Safety valve: 300 replies.

var rules = new List<(Regex Pattern, string Reply)>();
string? cwd = null, logPath = null;
int timeoutSeconds = 3600, settleMs = 1200;
var command = new List<string>();
for (int i = 0; i < args.Length; i++)
{
    switch (args[i])
    {
        case "--raw": break;   // legacy no-op: raw is the only mode
        case "--cwd": cwd = args[++i]; break;
        case "--log": logPath = args[++i]; break;
        case "--timeout": timeoutSeconds = int.Parse(args[++i]); break;
        case "--settle": settleMs = int.Parse(args[++i]); break;
        case "--rule":
            var parts = args[++i].Split("=>", 2);
            rules.Add((new Regex(parts[0], RegexOptions.IgnoreCase), parts.Length > 1 ? parts[1] : ""));
            break;
        case "--":
            for (int j = i + 1; j < args.Length; j++) command.Add(args[j]);
            i = args.Length;
            break;
    }
}
if (cwd is null || command.Count == 0)
{
    Console.Error.WriteLine("PtyDriver --cwd DIR [--log FILE] [--rule re=>reply]... -- command...");
    return 2;
}

string commandLine = string.Join(" ", command.Select(c => c.Contains(' ') ? $"\"{c}\"" : c));
using var log = logPath is null ? null : new StreamWriter(logPath, append: false, Encoding.UTF8) { AutoFlush = true };
void Note(string s) { Console.WriteLine(s); log?.WriteLine(s); }

Note($"# PtyDriver: {commandLine}");
Note($"# cwd: {cwd}");

using var pty = ConPtyProcess.Start(commandLine, cwd);
var transcript = new TranscriptBuilder();
var decoder = Encoding.UTF8.GetDecoder();
var outputLock = new object();
DateTime lastOutputAt = DateTime.UtcNow;
long lastLoggedLineCount = 0;

var reader = new Thread(() =>
{
    var buffer = new byte[8192];
    var chars = new char[8192];
    while (true)
    {
        int n = pty.ReadOutput(buffer);
        if (n <= 0) break;
        int charCount = decoder.GetChars(buffer, 0, n, chars, 0);
        var text = new string(chars, 0, charCount);
        lock (outputLock)
        {
            transcript.Append(text);
            lastOutputAt = DateTime.UtcNow;
            while (lastLoggedLineCount < transcript.Lines.Count)
                log?.WriteLine(transcript.Lines[(int)lastLoggedLineCount++]);
        }
    }
}) { IsBackground = true };
reader.Start();

long respondedVersion = -1;
int responsesSent = 0;
var deadline = DateTime.UtcNow.AddSeconds(timeoutSeconds);
while (!pty.HasExited)
{
    Thread.Sleep(200);
    if (DateTime.UtcNow > deadline) { Note("# TIMEOUT — killing"); pty.Kill(); break; }
    string lastLine; long version; DateTime silentSince;
    lock (outputLock)
    {
        version = transcript.Version;
        silentSince = lastOutputAt;
        lastLine = transcript.CurrentLine.Trim();
        if (lastLine.Length == 0)
            for (int i = transcript.Lines.Count - 1; i >= 0; i--)
                if (transcript.Lines[i].Trim().Length > 0) { lastLine = transcript.Lines[i].Trim(); break; }
    }
    if (version == respondedVersion) continue;                       // nothing new since last reply
    if ((DateTime.UtcNow - silentSince).TotalMilliseconds < settleMs) continue;
    foreach (var (pattern, reply) in rules)
    {
        if (!pattern.IsMatch(lastLine)) continue;
        respondedVersion = version;
        if (++responsesSent > 300) { Note("# SAFETY VALVE — killing"); pty.Kill(); break; }
        Note($"# prompt: {lastLine}");
        Note($"# reply : {reply}");
        byte[] bytes = reply switch
        {
            "{ENTER}" => "\r"u8.ToArray(),
            "{RIGHT}" => "\x1b[C"u8.ToArray(),
            "{Q}" => "q"u8.ToArray(),
            _ => Encoding.UTF8.GetBytes(reply + "\r"),
        };
        pty.WriteInput(bytes);
        break;
    }
}

pty.WaitForExit(15000);
pty.ClosePty();
reader.Join(5000);
lock (outputLock)
{
    while (lastLoggedLineCount < transcript.Lines.Count)
        log?.WriteLine(transcript.Lines[(int)lastLoggedLineCount++]);
    if (transcript.CurrentLine.Length > 0) log?.WriteLine(transcript.CurrentLine);
}
int exit = pty.ExitCode ?? -1;
Note($"# exit: {exit}");
return exit;
