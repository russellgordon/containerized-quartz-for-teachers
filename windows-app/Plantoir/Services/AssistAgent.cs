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

    /// <summary>
    /// The tools the LOCAL model is shown, and only those.
    ///
    /// Measured, not guessed. On five tools the routing was 27/27; on the
    /// shipped surface it fell to 31/45, and the failures were exactly the
    /// phrasings a teacher uses — "put up Unit 3, Day 2", "take Unit 4, Day 5
    /// back down" both fell through to list_pages. There are 26 tools now, so
    /// it would be worse again, and the definitions come to some 6,200 tokens
    /// that must be re-read at 21 tokens a second whenever the cache is cold.
    ///
    /// Both problems have the same cause and the same fix. Fewer tools is
    /// better routing AND a shorter prompt: accuracy and speed are not a
    /// trade-off here, they are the same dial.
    ///
    /// So the local model gets the handful of things teachers actually ask for
    /// day to day. Everything else — rolling a course over, re-dating a term,
    /// making room in a unit, scheduling a deploy, curriculum matching — stays
    /// available to Claude Code, which drives the same server and has no
    /// trouble with 26 tools. Nothing is removed; this narrows one client's
    /// view.
    /// </summary>
    private static readonly HashSet<string> ForTheLocalModel = new(StringComparer.OrdinalIgnoreCase)
    {
        // Finding your way about.
        "list_pages", "read_page", "check_section",
        // Publishing a class, which is the commonest request by a wide margin.
        "plan_publish_class_on", "publish_class_on",
        // Publishing and unpublishing pages by name.
        "plan_publish_pages", "publish_pages",
        "plan_unpublish_pages", "unpublish_pages",
        // Seeing the result, and taking it back.
        "rebuild_preview", "undo_last_change",
        // Putting it in front of students, now or at half six tomorrow.
        //
        // Kept deliberately, against the pressure to trim. Deploying is the
        // act a teacher most wants help with at the moment they want it —
        // "the class starts in ten minutes" — and it was asked for by name.
        // The safety is not in withholding the tool: the approval gate stops
        // every one of these until a button is pressed, and the tool's own
        // description tells the assistant to send the teacher to the preview
        // first.
        "deploy_section", "plan_scheduled_deploy", "schedule_deploy", "cancel_scheduled_deploy",
    };

    /// <summary>
    /// Narrow a tool list to what the local model should see.
    ///
    /// A tool NOT in the set is not hidden from the teacher — they can ask for
    /// it, and the assistant will say it cannot do that here rather than
    /// silently doing something else. That is the better failure: the tools it
    /// does have are the ones it routes to reliably.
    /// </summary>
    public static JsonArray NarrowToLocal(JsonArray tools)
    {
        var kept = new JsonArray();
        foreach (var tool in tools)
        {
            if (tool?["function"]?["name"]?.GetValue<string>() is not { } name) continue;
            if (!ForTheLocalModel.Contains(name)) continue;

            var copy = tool.DeepClone();
            if (copy["function"]?["description"]?.GetValue<string>() is { } description)
                copy["function"]!["description"] = Briefly(description);
            kept.Add(copy);
        }
        return kept;
    }

    /// <summary>
    /// The part of a tool description a ROUTER needs, and no more.
    ///
    /// The descriptions are written for Claude Code, and most of their length
    /// is instruction: plan before you write, tell the teacher what it said,
    /// wait for them to agree, this takes several minutes. None of that is
    /// guidance the local model has to be trusted to follow, because none of
    /// it is enforced by the model — the approval gate in this class holds
    /// every write until the teacher presses a button, whatever the model
    /// believes it is doing.
    ///
    /// What a router does need is WHEN to pick this tool. So: the phrasings
    /// teachers use, and the first sentence saying what it does. Measured, the
    /// full surface was some 9,000 tokens of definitions; this and the tool
    /// list together bring what the local model reads down to a fraction of
    /// that, and the prompt is what makes a cold first answer slow.
    /// </summary>
    private static string Briefly(string description)
    {
        var kept = new List<string>();

        // The trigger phrasings, which are the most useful line for routing
        // and are deliberately written first.
        int endOfPhrasings = description.IndexOf("\". ", StringComparison.Ordinal);
        if (description.StartsWith("TEACHERS SAY:", StringComparison.Ordinal) && endOfPhrasings > 0)
        {
            kept.Add(description[..(endOfPhrasings + 2)]);
            description = description[(endOfPhrasings + 3)..];
        }

        // Then one sentence of what it actually does.
        int firstStop = description.IndexOf(". ", StringComparison.Ordinal);
        kept.Add(firstStop > 0 ? description[..(firstStop + 1)] : description);

        return string.Join(" ", kept).Trim();
    }

    /// <summary>
    /// The one tool that changes something and still needs no permission:
    /// explaining what publishing means. All it writes is Plantoir's own note
    /// that this section has been briefed — nothing of the teacher's — and
    /// asking "may I explain how this works?" before the first sentence of the
    /// first conversation would be absurd.
    ///
    /// A single name, rather than the list of writes this used to keep. That
    /// list had already drifted: it named <c>hide_pages</c> and
    /// <c>republish_section</c>, neither of which exists any more, so both
    /// silently fell OUT of the set — and a renamed write tool that falls out
    /// of the set runs unannounced, which is the one failure this class exists
    /// to prevent. Approval is decided from the server's own
    /// <c>readOnlyHint</c> now (see <see cref="NeedsApproval"/>), so there is
    /// no second list to fall out of.
    /// </summary>
    private const string Briefing = "explain_publishing";

    /// <summary>
    /// Whether this call has to be shown to the teacher before it runs.
    ///
    /// Read-only tools — every list, read, check and plan — run freely. Anything
    /// else waits. Note which way the unknown case falls: a tool this app has
    /// never heard of, or one whose annotations went missing, needs approval.
    /// The cost of being wrong that way is one extra question; the cost of being
    /// wrong the other way is a teacher's course changing without being asked.
    /// </summary>
    private bool NeedsApproval(string name)
    {
        if (string.Equals(name, Briefing, StringComparison.OrdinalIgnoreCase)) return false;

        foreach (var tool in _schemas)
        {
            if (tool?["function"]?["name"]?.GetValue<string>() is not { } listed) continue;
            if (!string.Equals(listed, name, StringComparison.OrdinalIgnoreCase)) continue;
            return tool["annotations"]?["readOnlyHint"]?.GetValue<bool>() is not true;
        }
        return true;
    }

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
                "If no tool fits, say so plainly instead of inventing one.\n" +
                // Two words that sound alike and are not. The teacher gets this
                // explained once per section by explain_publishing; the model
                // needs it every turn, because it is the distinction it is
                // likeliest to collapse.
                "PUBLISHING a page decides whether students can see it in the site. " +
                "DEPLOYING sends the whole site to the web. They are different acts. " +
                "After a change, rebuild the preview so the teacher can look it over. " +
                "Do not offer to deploy unless they ask; when they do ask, say plainly that " +
                "deploying puts the change in front of students immediately and that reviewing " +
                "the preview first is the safer order — then do as they decide.",
        });
    }

    /// <summary>
    /// A throwaway exchange shaped EXACTLY like a real one, for warming the
    /// prompt cache.
    ///
    /// The system message has to be in it. Warming with just the tools and a
    /// stray "Say ready" primes a prefix no real turn ever uses: llama.cpp
    /// renders the tools and the system prompt into the same leading block, so
    /// a conversation that carries a system message diverges from that warm-up
    /// almost at the first token and re-reads everything.
    ///
    /// That is not a small waste. It is the difference between the three
    /// minutes buying every later answer, and buying nothing at all — measured
    /// as a 75-second wait for the word "Hi" AFTER a warm-up had finished.
    ///
    /// Called before any real turn, so this is the system message alone plus
    /// one short user line, which is the shortest thing shaped like the real
    /// prefix.
    /// </summary>
    public JsonArray PrimingMessages()
    {
        var priming = new JsonArray();
        foreach (var message in _messages)
            if (message is not null) priming.Add(message.DeepClone());
        priming.Add(new JsonObject { ["role"] = "user", ["content"] = "Hello." });
        return priming;
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
            if (NeedsApproval(name))
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
