using System;
using System.Diagnostics;
using System.Net.Http;
using System.Text;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;

namespace Plantoir.Services;

/// <summary>
/// The assistant that runs on the teacher's own computer.
///
/// Everything here follows from what was measured on the `ai-assist` branch
/// (AI-ASSIST.md), and the numbers are unusually specific because the budget
/// is unusually tight:
///
/// * **Qwen2.5-1.5B-Instruct, Q4_K_M.** 1.08 GB resident, 100% routing across
///   27 trials, no malformed calls, no wrong argument types. A 3B model
///   matched it on accuracy while using more than twice the memory and getting
///   every JSON type wrong; a 1B got 78% and invented a course code.
/// * **`--no-mmap` is not optional.** llama.cpp memory-maps the model by
///   default, and in a memory-capped container the page cache for that file
///   counts against the cgroup. Without it a 3B appeared to need 4 GB and died
///   at 3 with `ExitCode=255`, `OOMKilled=false` — no OOM message, nothing in
///   the log, just gone.
/// * **4 GB and 2 CPUs** is the budget on both platforms: macOS pins Colima at
///   `--memory 4` in every launcher, whatever the Mac has, and WSL2 takes
///   about half of an 8 GB machine.
///
/// Nothing ships with the app. The model is fetched once, on a teacher's
/// explicit yes, and the container only runs while a conversation is open —
/// a site build and an assistant never need the memory at the same time.
/// </summary>
public sealed class LocalModel
{
    /// <summary>The measured winner. 1,117,320,736 bytes — about 1.1 GB.</summary>
    private const string ModelFile = "Qwen2.5-1.5B-Instruct-Q4_K_M.gguf";

    private const string ModelUrl =
        "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/" +
        "qwen2.5-1.5b-instruct-q4_k_m.gguf?download=true";

    private const string Image = "ghcr.io/ggml-org/llama.cpp:server";
    private const string ContainerName = "plantoir-assistant";
    private const int Port = 8099;

    // Fifteen minutes, not five. A cold prompt cache means ~6,200 tokens of
    // tool definitions evaluated at some 21 tokens/second, which is five
    // minutes on its own — a timeout set to the same figure would fail exactly
    // when the machine is slowest, and report it as a network error.
    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromMinutes(15) };

    /// <summary>Where the model lives inside WSL, beside the toolchain's own data.</summary>
    private const string ModelDirectoryInWsl = "/var/lib/plantoir/models";

    /// <summary>
    /// Where the prompt cache is kept between sessions.
    ///
    /// Reading the tool definitions takes about three minutes on two CPU
    /// cores — measured, not estimated: 97% at 2m 48s. Paying that once is
    /// defensible; paying it every time a teacher opens the window is not.
    /// llama.cpp can save a slot's KV cache to disk and restore it, so the
    /// three minutes happens once and every session after starts warm.
    /// </summary>
    private const string CacheDirectoryInWsl = "/var/lib/plantoir/cache";

    /// <summary>
    /// Which conversation's prefix the cache holds, set by the window before
    /// the first save or restore — "exc2o-s1", say.
    ///
    /// Per course and section, not one file, because the prefix itself is:
    /// the system prompt names the course and the section in its first
    /// sentence, so a cache saved for section 2 matches a section 1
    /// conversation for about fifteen tokens and the model re-reads the
    /// whole surface — behind a message promising it is picking up where it
    /// left off. Each file is about 98 MB; a teacher with several sections
    /// keeps several.
    /// </summary>
    public string CacheIdentity { get; set; } = "";

    /// <summary>
    /// Fingerprint the cache with the exact prefix it was read from — the
    /// tool schemas AND the system prompt, because llama.cpp renders both
    /// into the same leading block and either can change with the app.
    ///
    /// An update that rewords one description or one system-prompt sentence
    /// makes every saved cache stale in a way a restore cannot see — the
    /// tokens load, n_restored looks healthy, and then the conversation's
    /// own prefix matches none of them and the model re-reads the surface
    /// behind a message promising it won't. Naming the file for the hash
    /// turns that silent three minutes into an honest one: after an update
    /// the old file simply isn't found, the session announces a cold read,
    /// and the save that follows replaces it.
    /// </summary>
    public void StampCacheWith(JsonArray tools, string systemPrompt)
    {
        byte[] digest = System.Security.Cryptography.SHA256.HashData(
            Encoding.UTF8.GetBytes(systemPrompt + "\n" + tools.ToJsonString()));
        _cacheStamp = Convert.ToHexString(digest)[..8].ToLowerInvariant();
    }

    private string _cacheStamp = "";

    /// <summary>The saved prefix, named for the model so a model change cannot restore the wrong one.</summary>
    private string CacheFile =>
        "prefix-qwen2.5-1.5b" +
        (CacheIdentity.Length > 0 ? $"-{CacheIdentity}" : "") +
        (_cacheStamp.Length > 0 ? $"-{_cacheStamp}" : "") +
        ".bin";

    public string Endpoint => $"http://127.0.0.1:{Port}/v1/chat/completions";

    /// <summary>True when the model file has already been fetched.</summary>
    public bool IsInstalled() =>
        Wsl($"test -f {ModelDirectoryInWsl}/{ModelFile} && echo yes").Trim() == "yes";

    public bool IsRunning() =>
        Wsl($"docker ps --filter name={ContainerName} --format '{{{{.Names}}}}'").Trim() == ContainerName;

    /// <summary>
    /// How far the one-time download has got. <see cref="Total"/> is 0 when the
    /// server would not say how big the file is, which turns the bar
    /// indeterminate rather than inventing a denominator.
    /// </summary>
    public readonly record struct Fetching(long Bytes, long Total)
    {
        public bool Known => Total > 0;

        /// <summary>Clamped, because a resumed or over-long response must not read as 103%.</summary>
        public double Percent => Known ? Math.Min(100, 100.0 * Bytes / Total) : 0;

        public string Describe() => Known
            ? $"Downloading the assistant — {Mb(Bytes)} of {Mb(Total)} ({Percent:0}%)."
            : $"Downloading the assistant — {Mb(Bytes)} so far.";

        private static string Mb(long bytes) => $"{bytes / 1024.0 / 1024.0:0} MB";
    }

    /// <summary>
    /// Fetch the model. About 1.1 GB, once, and only after the teacher has
    /// said yes — this is the whole reason the feature is opt-in.
    ///
    /// Progress is measured by watching the part-file grow rather than by
    /// parsing curl's own meter: curl draws that with carriage returns on
    /// stderr, which arrives as one unreadable line through two layers of
    /// process redirection. Asking the file how big it is costs one cheap call
    /// every two seconds and cannot be broken by curl changing its output.
    /// </summary>
    public async Task<bool> Install(IProgress<Fetching>? progress, CancellationToken cancellation)
    {
        string part = $"{ModelDirectoryInWsl}/{ModelFile}.part";
        long total = await Task.Run(SizeOnServer, cancellation);
        progress?.Report(new Fetching(0, total));

        var download = Task.Run(() => Wsl(
            $"mkdir -p {ModelDirectoryInWsl} && " +
            $"curl -fL --retry 3 -o {part} '{ModelUrl}' && " +
            // Renamed only on success, so an interrupted download is never
            // mistaken for an installed model.
            $"mv {part} {ModelDirectoryInWsl}/{ModelFile} && echo done",
            minutes: 30), cancellation);

        while (!download.IsCompleted)
        {
            // Delay first: at nought seconds there is nothing to report but the
            // zero already sent, and the wait is what keeps this to one process
            // every two seconds rather than one per frame.
            //
            // ConfigureAwait(false) matters more than it looks. Without it this
            // loop resumes on the UI thread and then calls BytesSoFar, which
            // starts wsl.exe and waits for it — freezing the window for a few
            // hundred milliseconds out of every two seconds, while it is
            // supposed to be demonstrating that the app is still alive.
            try { await Task.Delay(2000, cancellation).ConfigureAwait(false); }
            catch (OperationCanceledException) { break; }
            long got = await Task.Run(() => BytesSoFar(part)).ConfigureAwait(false);
            progress?.Report(new Fetching(got, total));
        }

        string result = await download.ConfigureAwait(false);
        return result.Contains("done", StringComparison.Ordinal) && IsInstalled();
    }

    /// <summary>How big the finished file will be, or 0 if the server won't say.</summary>
    private static long SizeOnServer()
    {
        // -L because the real file sits behind a redirect to a CDN, and it is
        // the LAST content-length that describes it.
        string headers = Wsl($"curl -sIL '{ModelUrl}' | tr -d '\\r' | grep -i '^content-length:' | tail -1");
        string[] parts = headers.Split(':', 2);
        return parts.Length == 2 && long.TryParse(parts[1].Trim(), out long size) ? size : 0;
    }

    private static long BytesSoFar(string path) =>
        long.TryParse(Wsl($"stat -c %s {path} 2>/dev/null").Trim(), out long size) ? size : 0;

    /// <summary>
    /// A WSL process that does nothing but exist, for as long as the assistant
    /// does.
    ///
    /// WSL2 shuts the distro down once no session is holding it open, and that
    /// takes the Docker daemon and every container with it. A detached
    /// `docker run -d` holds nothing, so the assistant loaded its model,
    /// answered a health check, reported itself Ready — and was killed about
    /// twenty-five seconds later, mid-way through its first answer. The symptom
    /// was an HTTP error from the app, which points at the network and is
    /// nothing to do with it: measured directly, Windows reaches the container
    /// on 127.0.0.1 perfectly well while it is alive.
    ///
    /// Every other part of the toolchain is accidentally immune, because the
    /// preview and deploy launchers stay attached to their container for the
    /// whole run. This one has to hold the door open deliberately.
    ///
    /// The sleep is bounded so that a Plantoir that dies without calling
    /// <see cref="Stop"/> cannot pin WSL — and the container's memory — for the
    /// rest of the day.
    /// </summary>
    private Process? _keepWslAwake;

    /// <summary>Start the model and wait for it to answer. Idempotent.</summary>
    public async Task<bool> Start(IProgress<string>? progress, CancellationToken cancellation)
    {
        progress?.Report("Starting the assistant…");

        // Before the container, not after: between `docker run` returning and
        // the first health check there is already a window in which WSL could
        // decide nobody wants it.
        HoldWslOpen();

        if (!await Task.Run(IsRunning, cancellation))
        {
            await Task.Run(() => Wsl(
                $"docker rm -f {ContainerName} >/dev/null 2>&1; " +
                $"docker run -d --name {ContainerName} --memory 4g --cpus=2 " +
                $"-p {Port}:8080 -v {ModelDirectoryInWsl}:/models:ro " +
                // A WRITABLE mount for the prompt cache, beside the read-only
                // model. Without somewhere to put it, the three minutes spent
                // reading the tool definitions is paid again every session.
                $"-v {CacheDirectoryInWsl}:/cache {Image} " +
                "--slot-save-path /cache " +
                // One slot, not the four this image now defaults to: one window
                // is one conversation, and four slots multiply the KV cache by
                // four for no benefit here. That saving is what pays for the
                // context below.
                //
                // 16384, not 8192, because the tool definitions alone measured
                // ~6,200 tokens — three quarters of an 8k context before the
                // teacher has said anything, leaving a conversation that would
                // run out of room within a few turns.
                $"-m /models/{ModelFile} --no-mmap --parallel 1 -c 16384 " +
                "--jinja --host 0.0.0.0 --port 8080"), cancellation);
        }

        // The first load reads a gigabyte off disk; later starts are quicker.
        for (int i = 0; i < 120 && !cancellation.IsCancellationRequested; i++)
        {
            bool up = await Task.Run(
                () => Wsl($"curl -s http://127.0.0.1:{Port}/health").Contains("ok", StringComparison.Ordinal),
                cancellation);
            if (up) return true;
            await Task.Delay(1000, cancellation);
        }
        return false;
    }

    private void HoldWslOpen()
    {
        if (_keepWslAwake is { HasExited: false }) return;

        var info = new ProcessStartInfo
        {
            FileName = "wsl.exe",
            CreateNoWindow = true,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        info.ArgumentList.Add("-e");
        info.ArgumentList.Add("sh");
        info.ArgumentList.Add("-c");
        // It watches the container and lets go within five seconds of it
        // disappearing, rather than sleeping blindly for six hours.
        //
        // A plain sleep leaked: two conversations left four of these behind,
        // still pinning WSL long after their windows had closed. Stop() kills
        // them, but Stop() runs on the way out and does not always finish —
        // and anything that only cleans up when asked nicely will eventually
        // meet a process that was not asked. This one ends on its own.
        // It must not give up before the container it is waiting for EXISTS.
        //
        // The first version checked immediately and exited when it saw
        // nothing — and it is started BEFORE `docker run`, deliberately, so
        // that WSL cannot idle out in the gap. So it killed itself on its
        // first tick, every time, and the container died with WSL a minute
        // later: "the target machine actively refused it". The leak fix
        // reintroduced the very bug it was written after.
        //
        // So: sleep first, and only leave once the container has been SEEN and
        // then gone. If it never appears at all — a start that failed — give up
        // after five minutes rather than holding WSL open for the full run.
        info.ArgumentList.Add(
            "seen=0; missing=0; " +
            "for i in $(seq 1 4320); do sleep 5; " +
            $"if docker ps --filter name={ContainerName} --format '{{{{.Names}}}}' | grep -q {ContainerName}; " +
            "then seen=1; missing=0; " +
            "else if [ \"$seen\" = 1 ]; then exit 0; fi; " +
            "missing=$((missing+1)); if [ \"$missing\" -gt 60 ]; then exit 0; fi; fi; done");
        try { _keepWslAwake = Process.Start(info); } catch { _keepWslAwake = null; }
    }

    /// <summary>
    /// Whether a prompt cache from an earlier session is waiting on disk.
    ///
    /// Used to decide what to tell the teacher before the wait starts: three
    /// minutes announced is tolerable, three minutes unexplained is not.
    /// </summary>
    public bool HasSavedPrefix() =>
        Wsl($"test -f {CacheDirectoryInWsl}/{CacheFile} && echo yes").Trim() == "yes";

    /// <summary>
    /// Load the prompt cache saved by an earlier session, if there is one.
    ///
    /// Returns whether anything was actually restored, because the window's
    /// wording depends on it: "picking up where I left off" over a restore
    /// that quietly failed announces a ten-second wait and delivers a
    /// three-minute one. Measured working: 3,428 tokens back in about 30 ms,
    /// and the next turn evaluated only the sentence the teacher typed.
    /// </summary>
    public bool RestorePrefix()
    {
        if (!HasSavedPrefix()) return false;
        string reply = Wsl($"curl -s -m 120 -X POST 'http://127.0.0.1:{Port}/slots/0?action=restore' " +
                           $"-H 'Content-Type: application/json' -d '{{\"filename\":\"{CacheFile}\"}}'");
        return TokensIn(reply, "n_restored") > 0;
    }

    /// <summary>
    /// Keep the prompt cache for next time.
    ///
    /// The one failure worth guarding against is the quiet one. Saving an
    /// EMPTY slot succeeds — HTTP 200, n_saved = 0, a valid 36-byte file —
    /// and that file makes the next session claim it is picking up where it
    /// left off, restore nothing, and pay the three minutes anyway, now
    /// unannounced. So the save is checked, and a save that kept no tokens
    /// is deleted rather than left to mislead.
    /// </summary>
    public bool SavePrefix()
    {
        string reply = Wsl($"mkdir -p {CacheDirectoryInWsl}; " +
                           $"curl -s -m 120 -X POST 'http://127.0.0.1:{Port}/slots/0?action=save' " +
                           $"-H 'Content-Type: application/json' -d '{{\"filename\":\"{CacheFile}\"}}'");
        if (TokensIn(reply, "n_saved") > 0)
        {
            // Superseded saves for the same section — older schema stamps —
            // are 98 MB each and can never be restored again. One live file
            // per section.
            if (CacheIdentity.Length > 0 && _cacheStamp.Length > 0)
                Wsl($"for f in {CacheDirectoryInWsl}/prefix-qwen2.5-1.5b-{CacheIdentity}-*.bin; do " +
                    $"[ \"$f\" = \"{CacheDirectoryInWsl}/{CacheFile}\" ] || rm -f \"$f\"; done");
            return true;
        }
        Wsl($"rm -f {CacheDirectoryInWsl}/{CacheFile}");
        return false;
    }

    /// <summary>A count out of the slot endpoint's JSON, or 0 when the call failed.</summary>
    private static long TokensIn(string reply, string field)
    {
        var match = System.Text.RegularExpressions.Regex.Match(reply, $"\"{field}\"\\s*:\\s*(\\d+)");
        return match.Success && long.TryParse(match.Groups[1].Value, out long count) ? count : 0;
    }

    /// <summary>
    /// How far through reading the prompt the model is, from 0 to 1, or null
    /// when it is not reading one.
    ///
    /// llama.cpp says this itself, once per batch, on its own log:
    ///
    ///   prompt processing, n_tokens = 2048, progress = 0.33, t = 97.32 s
    ///
    /// which is the only honest source for it — the HTTP request is a single
    /// POST that returns when the whole thing is done, so from the app's side
    /// there is nothing to watch. Reading the container's log is not elegant,
    /// and it is the difference between a bar that moves and a spinner that
    /// lies.
    ///
    /// Only the LAST line matters: earlier ones belong to batches already
    /// finished, or to a previous request.
    /// </summary>
    public double? PromptProgress()
    {
        // A short tail: enough to catch the current batch, small enough that
        // this stays cheap at one call every second or two.
        string log = Wsl($"docker logs --tail 12 {ContainerName} 2>&1 | grep -o 'progress = [0-9.]*' | tail -1");
        var match = System.Text.RegularExpressions.Regex.Match(log, @"progress = ([0-9.]+)");
        if (!match.Success) return null;
        return double.TryParse(match.Groups[1].Value,
                               System.Globalization.NumberStyles.Float,
                               System.Globalization.CultureInfo.InvariantCulture,
                               out double fraction)
            ? Math.Clamp(fraction, 0, 1)
            : null;
    }

    /// <summary>Stop it, so the memory goes back to the machine when the conversation ends.</summary>
    public void Stop()
    {
        Wsl($"docker rm -f {ContainerName} >/dev/null 2>&1 || true");

        // After the container, so WSL is still up to receive that command.
        try { _keepWslAwake?.Kill(entireProcessTree: true); } catch { }
        try { _keepWslAwake?.Dispose(); } catch { }
        _keepWslAwake = null;
    }

    /// <summary>
    /// One turn of the conversation. Returns the raw assistant message, which
    /// carries either content, tool calls, or both.
    /// </summary>
    public async Task<JsonObject?> Ask(JsonArray messages, JsonArray tools, CancellationToken cancellation)
    {
        var request = new JsonObject
        {
            ["model"] = "local",
            ["temperature"] = 0.1,      // the routing measurements were taken here
            ["max_tokens"] = 512,
            ["messages"] = messages.DeepClone(),
            ["tools"] = tools.DeepClone(),
        };

        using var content = new StringContent(request.ToJsonString(), Encoding.UTF8, "application/json");
        using var response = await Http.PostAsync(Endpoint, content, cancellation);
        if (!response.IsSuccessStatusCode) return null;

        string body = await response.Content.ReadAsStringAsync(cancellation);
        return JsonNode.Parse(body)?["choices"]?[0]?["message"] as JsonObject;
    }

    /// <summary>
    /// Runs a command inside WSL, where this machine's Docker lives.
    ///
    /// Wrapped in <c>sh -c</c> deliberately: Git Bash rewrites anything that
    /// looks like a Unix path on the way past, so <c>-v /models:ro</c> arrives
    /// as <c>\Program Files\Git\models;ro</c> and the mount silently fails.
    /// </summary>
    private static string Wsl(string command, int minutes = 2)
    {
        var info = new ProcessStartInfo
        {
            FileName = "wsl.exe",
            CreateNoWindow = true,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
        };
        info.ArgumentList.Add("-e");
        info.ArgumentList.Add("sh");
        info.ArgumentList.Add("-c");
        info.ArgumentList.Add(command);

        try
        {
            using var process = Process.Start(info);
            if (process is null) return "";
            string output = process.StandardOutput.ReadToEnd();
            if (!process.WaitForExit(minutes * 60_000)) { try { process.Kill(true); } catch { } }
            return output;
        }
        catch { return ""; }
    }
}
