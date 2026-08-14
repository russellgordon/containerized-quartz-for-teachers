using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;

namespace Plantoir.Services;

/// <summary>
/// The conversation loop: what the teacher said, what the model decided, what
/// the tools did, and back again.
///
/// The shape is dictated by one measured finding — **the model is a router,
/// not a planner**. Given fine-grained tools and asked to publish a class "and
/// everything it links to", it chose the publish tool and skipped the link
/// resolution eight times out of eight. Given one coarse tool that resolves
/// links itself, it was right eight times out of eight. So this loop is
/// deliberately thin: it does not decompose the request, does not plan, and
/// does not retry cleverly. It carries messages between a teacher and a set of
/// tools that already know how to do the work.
///
/// The safety rules are not enforced here either — they are enforced by the
/// tools, and by there being no destructive tool to reach for. What this loop
/// adds is the one thing tools cannot: **it never runs a write tool without
/// showing the teacher the plan first and being told to go ahead.**
/// </summary>
public sealed class AssistAgent
{
    private readonly LocalModel _model;
    private readonly McpClient _tools;
    private readonly JsonArray _schemas;
    private readonly JsonArray _messages = new();

    /// <summary>Tools that change files. Everything else runs without asking.</summary>
    private static readonly HashSet<string> Writes = new(StringComparer.OrdinalIgnoreCase)
    {
        "publish_pages", "hide_pages", "publish_class_on", "republish_section",
        "re_date_classes", "roll_over_section", "sync_page_dates", "back_up_course",
        "undo_last_change",
    };

    /// <summary>
    /// How many tool calls one turn may make before the loop stops.
    ///
    /// A small model that has lost the thread repeats itself rather than
    /// stopping, and a runaway loop against a teacher's course is the failure
    /// nobody would forgive. Reading, planning and then acting is three.
    /// </summary>
    private const int MostStepsPerTurn = 6;

    public AssistAgent(LocalModel model, McpClient tools, JsonArray schemas, string courseCode, int section)
    {
        _model = model;
        _tools = tools;
        _schemas = schemas;
        _messages.Add(new JsonObject
        {
            ["role"] = "system",
            ["content"] =
                $"You are Plantoir's assistant, helping a teacher with {courseCode} section {section}. " +
                "Choose exactly one tool at a time and fill in its arguments from what the teacher said. " +
                "Before anything that changes files, call the matching plan tool first and show the teacher " +
                "exactly what it said, word for word, then wait. Never guess a course, a section, a page title " +
                "or a date — if you are not certain, look it up or ask. " +
                "If no tool fits, say so plainly instead of inventing one.",
        });
    }

    /// <summary>A line for the transcript.</summary>
    public sealed record Line(string Speaker, string Text, bool NeedsApproval = false, string? Pending = null);

    private JsonObject? _awaiting;      // a write the teacher has not agreed to yet

    public bool IsAwaitingApproval => _awaiting is not null;

    /// <summary>
    /// Say something to the assistant and get back everything that happened.
    /// </summary>
    public async Task<List<Line>> Say(string text, CancellationToken cancellation)
    {
        _messages.Add(new JsonObject { ["role"] = "user", ["content"] = text });
        return await Run(cancellation);
    }

    /// <summary>
    /// The teacher agreed to the write that was waiting. Run it, then carry on.
    /// </summary>
    public async Task<List<Line>> Approve(CancellationToken cancellation)
    {
        if (_awaiting is not { } call) return new List<Line>();
        _awaiting = null;

        var lines = new List<Line>();
        string result = await RunTool(call, lines, cancellation);
        lines.Add(new Line("tools", result));
        return lines.Concat(await Run(cancellation)).ToList();
    }

    /// <summary>The teacher said no. Tell the model, so it does not simply try again.</summary>
    public async Task<List<Line>> Decline(CancellationToken cancellation)
    {
        if (_awaiting is not { } call) return new List<Line>();
        _awaiting = null;
        _messages.Add(new JsonObject
        {
            ["role"] = "tool",
            ["tool_call_id"] = call["id"]?.DeepClone(),
            ["content"] = "The teacher said no. Do not run this. Ask what they would like instead.",
        });
        return await Run(cancellation);
    }

    private async Task<List<Line>> Run(CancellationToken cancellation)
    {
        var lines = new List<Line>();

        for (int step = 0; step < MostStepsPerTurn; step++)
        {
            var reply = await _model.Ask(_messages, _schemas, cancellation);
            if (reply is null)
            {
                lines.Add(new Line("assistant", "The assistant didn’t answer. Try again in a moment."));
                return lines;
            }
            _messages.Add(reply.DeepClone()!);

            string said = reply["content"]?.GetValue<string>() ?? "";
            if (said.Trim().Length > 0) lines.Add(new Line("assistant", said.Trim()));

            if (reply["tool_calls"] is not JsonArray calls || calls.Count == 0) return lines;

            // One at a time, so a teacher reading the transcript can follow it.
            var call = calls[0] as JsonObject;
            if (call is null) return lines;

            string name = call["function"]?["name"]?.GetValue<string>() ?? "";
            if (Writes.Contains(name))
            {
                // The one rule this loop owns. A plan the teacher has not read
                // is not a confirmation, and the measurements say the model
                // will occasionally reach for the opposite of what was asked.
                _awaiting = call;
                lines.Add(new Line("assistant",
                    $"I’d like to run **{name.Replace('_', ' ')}**. Shall I go ahead?",
                    NeedsApproval: true, Pending: name));
                return lines;
            }

            string result = await RunTool(call, lines, cancellation);
            lines.Add(new Line("tools", result));
        }

        lines.Add(new Line("assistant",
            "I’ve gone round several times without finishing. Tell me what you’d like me to do next."));
        return lines;
    }

    private async Task<string> RunTool(JsonObject call, List<Line> lines, CancellationToken cancellation)
    {
        string name = call["function"]?["name"]?.GetValue<string>() ?? "";
        var arguments = new JsonObject();
        if (call["function"]?["arguments"]?.GetValue<string>() is { } raw)
        {
            try { arguments = JsonNode.Parse(raw) as JsonObject ?? new JsonObject(); }
            catch { /* a malformed call is answered, not crashed on */ }
        }

        string result = await _tools.CallTool(name, arguments, cancellation);
        _messages.Add(new JsonObject
        {
            ["role"] = "tool",
            ["tool_call_id"] = call["id"]?.DeepClone(),
            ["content"] = result,
        });
        return result;
    }
}
