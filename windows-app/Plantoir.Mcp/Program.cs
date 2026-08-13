using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using ModelContextProtocol.Protocol;
using Plantoir.Core.Assist;
using Plantoir.Mcp;

// plantoir-mcp — an MCP server over one Plantoir working folder.
//
//   plantoir-mcp --folder "C:\Users\me\Documents\Teaching"
//
// The folder is fixed at startup and never changes afterwards. A server that
// could be pointed anywhere mid-session would make every path check meaningless.

string? folder = null;
for (int i = 0; i < args.Length; i++)
{
    if ((args[i] == "--folder" || args[i] == "-f") && i + 1 < args.Length) folder = args[++i];
    else if (args[i].StartsWith("--folder=", StringComparison.Ordinal)) folder = args[i]["--folder=".Length..];
}

folder ??= Environment.GetEnvironmentVariable("PLANTOIR_FOLDER");

if (string.IsNullOrWhiteSpace(folder))
{
    // stderr, not stdout: stdout belongs to the protocol.
    await Console.Error.WriteLineAsync(
        "plantoir-mcp needs the working folder to serve.\n\n" +
        "  plantoir-mcp --folder \"<path to your Plantoir working folder>\"\n\n" +
        "That is the folder holding your courses — the one Plantoir opens.");
    return 2;
}

AssistWorkspace workspace;
try
{
    workspace = new AssistWorkspace(folder, new LauncherRunner());
}
catch (Exception error)
{
    await Console.Error.WriteLineAsync(error.Message);
    return 2;
}

var builder = Host.CreateApplicationBuilder();

// Every log line goes to stderr. stdout carries JSON-RPC frames and nothing
// else; one stray line on it corrupts the session for the whole client.
builder.Logging.AddConsole(options => options.LogToStandardErrorThreshold = LogLevel.Trace);

builder.Services.AddSingleton(workspace);
builder.Services.AddMcpServer(options =>
        options.ServerInfo = new Implementation { Name = "plantoir", Version = "0.1.0" })
    .WithStdioServerTransport()
    .WithToolsFromAssembly();

await builder.Build().RunAsync();
return 0;
