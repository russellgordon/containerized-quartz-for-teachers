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
    /// <summary>The measured winner. Roughly 940 MB on disk.</summary>
    private const string ModelFile = "Qwen2.5-1.5B-Instruct-Q4_K_M.gguf";

    private const string ModelUrl =
        "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/" +
        "qwen2.5-1.5b-instruct-q4_k_m.gguf?download=true";

    private const string Image = "ghcr.io/ggml-org/llama.cpp:server";
    private const string ContainerName = "plantoir-assistant";
    private const int Port = 8099;

    private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromMinutes(5) };

    /// <summary>Where the model lives inside WSL, beside the toolchain's own data.</summary>
    private const string ModelDirectoryInWsl = "/var/lib/plantoir/models";

    public string Endpoint => $"http://127.0.0.1:{Port}/v1/chat/completions";

    /// <summary>True when the model file has already been fetched.</summary>
    public bool IsInstalled() =>
        Wsl($"test -f {ModelDirectoryInWsl}/{ModelFile} && echo yes").Trim() == "yes";

    public bool IsRunning() =>
        Wsl($"docker ps --filter name={ContainerName} --format '{{{{.Names}}}}'").Trim() == ContainerName;

    /// <summary>
    /// Fetch the model. Roughly 940 MB, once, and only after the teacher has
    /// said yes — this is the whole reason the feature is opt-in.
    /// </summary>
    public Task<bool> Install(IProgress<string>? progress, CancellationToken cancellation) =>
        Task.Run(() =>
        {
            progress?.Report("Fetching the assistant — this is about 940 MB, and happens once.");
            string result = Wsl(
                $"mkdir -p {ModelDirectoryInWsl} && " +
                $"curl -fL --retry 3 -o {ModelDirectoryInWsl}/{ModelFile}.part '{ModelUrl}' && " +
                // Renamed only on success, so an interrupted download is never
                // mistaken for an installed model.
                $"mv {ModelDirectoryInWsl}/{ModelFile}.part {ModelDirectoryInWsl}/{ModelFile} && echo done",
                minutes: 30);
            return result.Contains("done", StringComparison.Ordinal) && IsInstalled();
        }, cancellation);

    /// <summary>Start the model and wait for it to answer. Idempotent.</summary>
    public async Task<bool> Start(IProgress<string>? progress, CancellationToken cancellation)
    {
        if (!IsRunning())
        {
            progress?.Report("Starting the assistant…");
            Wsl($"docker rm -f {ContainerName} >/dev/null 2>&1; " +
                $"docker run -d --name {ContainerName} --memory 4g --cpus=2 " +
                $"-p {Port}:8080 -v {ModelDirectoryInWsl}:/models:ro {Image} " +
                $"-m /models/{ModelFile} --no-mmap -c 8192 --jinja --host 0.0.0.0 --port 8080");
        }

        // The first load reads a gigabyte off disk; later starts are quicker.
        for (int i = 0; i < 120 && !cancellation.IsCancellationRequested; i++)
        {
            if (Wsl($"curl -s http://127.0.0.1:{Port}/health").Contains("ok", StringComparison.Ordinal))
                return true;
            await Task.Delay(1000, cancellation);
        }
        return false;
    }

    /// <summary>Stop it, so the memory goes back to the machine when the conversation ends.</summary>
    public void Stop() => Wsl($"docker rm -f {ContainerName} >/dev/null 2>&1 || true");

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
