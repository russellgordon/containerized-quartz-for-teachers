using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;

namespace Plantoir.Core.Assist;

/// <summary>
/// The model half of a conversation: given the messages so far and the tool
/// schemas, one reply. LocalModel implements it over llama.cpp; the tests
/// implement it with a script, which is what lets every promised task be
/// exercised in milliseconds instead of a teacher's afternoon.
/// </summary>
public interface IChatModel
{
    Task<JsonObject?> Ask(JsonArray messages, JsonArray tools, CancellationToken cancellation);
}

/// <summary>
/// The tool half: run one tool, return what it said as text, narrate through
/// <paramref name="progress"/> along the way. McpClient implements it over
/// stdio to plantoir-mcp.
/// </summary>
public interface IToolServer
{
    Task<string> CallTool(string name, JsonObject arguments,
                          Action<string>? progress = null,
                          CancellationToken cancellation = default);
}

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
/// adds is the one thing tools cannot: **nothing deploys to students without
/// the teacher pressing a button.** Everything short of a deploy runs
/// freely, because the tools make it reversible — backed up, undoable, and
/// invisible to students until that button.
/// </summary>
public sealed class AssistAgent
{
    private readonly IChatModel _model;
    private readonly IToolServer _tools;
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
    ///
    /// The schemas' example course becomes THIS window's course, because the
    /// model copies examples: asked to publish with no course named, it wrote
    /// the schema's "for example ICS3U" nine trials out of nine, ignoring the
    /// system prompt's answer — and once even blended the two into ICS2O.
    /// A router matches text; the only example it cannot get wrong is the
    /// right answer. Measured after the change: fifty-four trials, not one
    /// wrong course.
    /// </summary>
    public static JsonArray NarrowToLocal(JsonArray tools, string courseCode)
    {
        var kept = new JsonArray();
        foreach (var tool in tools)
        {
            if (tool?["function"]?["name"]?.GetValue<string>() is not { } name) continue;
            if (!ForTheLocalModel.Contains(name)) continue;

            var copy = tool.DeepClone();
            if (copy["function"]?["description"]?.GetValue<string>() is { } description)
                copy["function"]!["description"] = Briefly(description).Replace(ExampleCourse, courseCode);
            MakeExamplesReal(copy["function"]?["parameters"], courseCode);
            kept.Add(copy);
        }
        return kept;
    }

    /// <summary>The course code the server's schemas use in their examples.</summary>
    private const string ExampleCourse = "ICS3U";

    private static void MakeExamplesReal(JsonNode? node, string courseCode)
    {
        switch (node)
        {
            case JsonObject fields:
                if (fields["description"]?.GetValue<string>() is { } text &&
                    text.Contains(ExampleCourse, StringComparison.Ordinal))
                    fields["description"] = text.Replace(ExampleCourse, courseCode);
                // Snapshotted, because replacing a description mid-walk would
                // otherwise be mutation during enumeration.
                foreach (var field in fields.ToList()) MakeExamplesReal(field.Value, courseCode);
                break;
            case JsonArray items:
                foreach (var item in items) MakeExamplesReal(item, courseCode);
                break;
        }
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
    /// Whether this call has to be shown to the teacher before it runs.
    ///
    /// Only deploying waits for a button, because deploying is the only act
    /// students ever notice. Everything else the assistant can reach is
    /// reversible by construction — validated against the working folder,
    /// backed up before it writes, behind undo_last_change — and a publish
    /// flag changes nothing a student can see until a deploy. Gating every
    /// one of those turned a conversation into a row of button presses, and
    /// the teacher asked for it to stop.
    ///
    /// A SCHEDULED deploy is approved when it is scheduled — that yes is what
    /// the button collects. The firing itself asks nobody, which is the whole
    /// point of scheduling it.
    /// </summary>
    private static readonly HashSet<string> DeploysToStudents = new(StringComparer.OrdinalIgnoreCase)
    {
        "deploy_section", "schedule_deploy",
    };

    private static bool NeedsApproval(string name) => DeploysToStudents.Contains(name);

    /// <summary>
    /// How many tool calls one turn may make before the loop stops.
    ///
    /// A small model that has lost the thread repeats itself rather than
    /// stopping, and a runaway loop against a teacher's course is the failure
    /// nobody would forgive. Reading, planning and then acting is three.
    /// </summary>
    private const int MostStepsPerTurn = 6;

    public AssistAgent(IChatModel model, IToolServer tools, JsonArray schemas, string courseCode, int section)
    {
        _model = model;
        _tools = tools;
        _schemas = schemas;
        _messages.Add(new JsonObject
        {
            ["role"] = "system",
            ["content"] = SystemPrompt(courseCode, section),
        });
    }

    /// <summary>
    /// The system prompt, exposed because it is part of the cached prefix:
    /// the window fingerprints it alongside the schemas, so a wording change
    /// here retires stale caches honestly instead of restoring a prefix no
    /// conversation will match.
    ///
    /// It no longer says plan-first-and-wait. Publishing and unpublishing run
    /// without ceremony now — backed up, undoable, and invisible to students
    /// until a deploy — and the deploy gate is a button this class enforces,
    /// not a behaviour the model has to be trusted to follow.
    /// </summary>
    public static string SystemPrompt(string courseCode, int section) =>
        $"You are Plantoir's assistant, helping a teacher with {courseCode} section {section}. " +
        "Choose exactly one tool at a time and fill in its arguments from what the teacher said. " +
        "Publishing and unpublishing are safe to do straight away — every change is backed up " +
        "and undo_last_change takes it back — so do what was asked without asking permission first. " +
        "Never guess a course, a section, a page title " +
        "or a date — if you are not certain, look it up or ask. " +
        "If no tool fits, say so plainly instead of inventing one.\n" +
        // Two words that sound alike and are not. The teacher gets this
        // explained once per section by explain_publishing; the model
        // needs it every turn, because it is the distinction it is
        // likeliest to collapse.
        "PUBLISHING a page decides whether students can see it in the site. " +
        "DEPLOYING sends the whole site to the web. They are different acts. " +
        "After a change, Plantoir opens the preview by itself so the teacher can look it over. " +
        "Do not offer to deploy unless they ask; when they do ask, say plainly that " +
        "deploying puts the change in front of students immediately and that reviewing " +
        "the preview first is the safer order — then do as they decide.";

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

    /// <summary>
    /// The promise card — what the window tells a teacher this assistant is
    /// good at, in the wordings that work. It lives HERE, beside the loop
    /// that keeps the promises, because the tests pin the two together:
    /// every task on this card has a test proving the loop does its part.
    /// Each line is a shape the local model routes reliably, and naming the
    /// page ("Unit 2, Day 3") is what keeps it from having to guess — so the
    /// examples all show it.
    /// </summary>
    public const string ExampleRequests =
        "Here's what I'm good at. These wordings work well — copy one and change the details:\n\n" +
        "**Publishing a class**\n" +
        "  • Publish Unit 2, Day 3, and everything it links to\n" +
        "  • Publish tomorrow's class\n\n" +
        "**Taking something back down**\n" +
        "  • Unpublish Unit 2, Day 3\n" +
        "  • I published Unit 4, Day 1 by mistake — unpublish it\n\n" +
        "**Looking before you leap**\n" +
        "  • What would publishing Unit 3, Day 1 change?\n" +
        "  • What would students see in this section right now?\n\n" +
        "**Afterwards**\n" +
        "  • Rebuild the preview\n" +
        "  • Undo that\n\n" +
        "**Putting it in front of students**\n" +
        "  • Deploy this section now\n" +
        "  • Deploy tomorrow's class at 6:30 AM\n" +
        "  • Cancel that scheduled deploy\n\n" +
        "Deploying is the one that students actually notice, so I'll always ask you to look at the " +
        "preview first — and you press the button, not me.\n\n" +
        "Name the page if you can — “Unit 2, Day 3” rather than “tomorrow's one” — and I'll be quicker " +
        "and more certain. Bigger jobs — re-dating a term, rolling a course over, adding a unit's worth " +
        "of pages — are beyond me, and want one of the more capable assistants in the same right-click " +
        "menu.";

    /// <summary>
    /// Where a running tool's own narration goes — the toolchain's milestone
    /// lines, relayed by the server as progress. A rebuild can spend minutes
    /// recreating its container and reinstalling the toolchain before it
    /// builds anything; without these lines that time is indistinguishable
    /// from a hang. May be called from any thread.
    /// </summary>
    public Action<string>? OnToolProgress { get; set; }

    /// <summary>
    /// The app, not the server, owns building and deploying — the assistant
    /// AUTOMATES Plantoir rather than duplicating it.
    ///
    /// The first live test did it the other way: rebuild_preview built in the
    /// server's own container run, invisible, while the chat showed dots —
    /// and finished with the result sitting on disk where nobody could see
    /// it. The main window already knows how to build a section with its
    /// console on screen and the preview in front of the teacher. So
    /// rebuild_preview and deploy_section never reach the server from here:
    /// they press Plantoir's own buttons. The server keeps those tools for
    /// the clients that have no window — Claude Code, and deploys scheduled
    /// for half six in the morning.
    /// </summary>
    public Action? ShowPreviewInApp { get; set; }

    /// <summary>Deploy through the main window's own flow, console and all. Any thread.</summary>
    public Action? StartDeployInApp { get; set; }

    /// <summary>
    /// Whether this section's preview is on screen right now, asked of the
    /// window. It decides what a page edit must do about the preview: the
    /// served site is a COPY, merged at build time, so a running preview
    /// never notices an edit to the course folder on its own — the teacher
    /// unpublished a page, watched the preview, and nothing changed.
    /// </summary>
    public Func<bool>? PreviewIsShowing { get; set; }

    /// <summary>
    /// Stop the section's preview in the main window. A page edit does what
    /// a person would do: stop the preview, change the files, start the
    /// preview again. No server-side build, no live-reload cleverness — the
    /// served site is a merged COPY that never notices course-folder edits,
    /// so the only honest preview is a restarted one.
    /// </summary>
    public Action? StopPreviewInApp { get; set; }

    /// <summary>
    /// Tools that change pages. They run on the server as pure file edits —
    /// <c>preview: false</c>, so the server builds nothing — and then the
    /// app's own preview is put on screen to show what changed.
    /// </summary>
    private static readonly HashSet<string> EditsPages = new(StringComparer.OrdinalIgnoreCase)
    {
        "publish_pages", "unpublish_pages", "publish_class_on", "undo_last_change",
    };

    /// <summary>The page-editing tools that accept a preview flag to decline the server's build.</summary>
    private static readonly HashSet<string> TakesPreviewFlag = new(StringComparer.OrdinalIgnoreCase)
    {
        "publish_pages", "unpublish_pages", "publish_class_on",
    };

    private JsonObject? _awaiting;      // a write the teacher has not agreed to yet

    public bool IsAwaitingApproval => _awaiting is not null || _offeringPreview;

    /// <summary>
    /// Say something to the assistant and get back everything that happened.
    ///
    /// The date rides along on every user turn, because the model has no
    /// other way to know it and "publish tomorrow's class" is the request
    /// this window exists for — without it, every trial fabricated a date
    /// from the schema's examples (2023-09-15, in 2026).
    ///
    /// APPENDED, not prepended, and not in the system prompt. Prepended, the
    /// date crowds out the request: measured routing fell from 91% to 76%,
    /// with "deploy at 6:30 tomorrow" answered by a publish tool. In the
    /// system prompt it would sit ahead of the tool definitions and
    /// invalidate the saved prompt cache every midnight. Appended, routing
    /// measured 94% and every date came out right.
    ///
    /// Only what the MODEL sees carries it; the window shows the teacher
    /// their own words.
    /// </summary>
    public async Task<List<Line>> Say(string text, CancellationToken cancellation)
    {
        if (PreviewAskedForPlainly(text) is { } handled) return handled;

        var today = DateTime.Now;
        _dateline = $" (Today is {today:yyyy-MM-dd}, a {today.DayOfWeek}.)";
        _messages.Add(new JsonObject
        {
            ["role"] = "user",
            ["content"] = text + _dateline,
        });
        return await Run(cancellation);
    }

    /// <summary>This turn's date note, remembered so a parroting reply can have it stripped.</summary>
    private string _dateline = "";

    /// <summary>
    /// The commonest command, answered without the model.
    ///
    /// Measured, after the routing cue for it was already in place: "Preview
    /// the site" still went to check_section three trials out of four — "the
    /// site" pulls toward that tool's own wording — and the teacher got a
    /// statistics lecture instead of a preview, after a twenty-second wait.
    /// Every phrase in this set means exactly one thing, so ordinary string
    /// matching answers it: instantly, every time, with the model never
    /// consulted. The model still handles anything that carries more than
    /// the command itself.
    /// </summary>
    private static readonly HashSet<string> PreviewCommands = new()
    {
        "preview", "preview the site", "preview my site", "preview the section", "preview it",
        "show me the preview", "show the preview", "open the preview", "start the preview",
        "launch the preview", "rebuild the preview", "refresh the preview", "update the preview",
    };

    private List<Line>? PreviewAskedForPlainly(string text)
    {
        if (ShowPreviewInApp is null || !PreviewCommands.Contains(Plainly(text))) return null;

        ShowPreviewInApp.Invoke();
        const string said = "The preview is opening in Plantoir's main window — the build shows its progress there.";
        // The exchange still goes in the transcript the model sees, so a
        // follow-up question knows the preview is already on screen.
        _messages.Add(new JsonObject { ["role"] = "user", ["content"] = text });
        _messages.Add(new JsonObject { ["role"] = "assistant", ["content"] = said });
        return new List<Line> { new("assistant", said) };
    }

    /// <summary>Lower-cased, letters only, courtesy words trimmed — the command underneath.</summary>
    private static string Plainly(string text)
    {
        var letters = new System.Text.StringBuilder();
        foreach (char c in text.ToLowerInvariant())
            letters.Append(char.IsLetter(c) ? c : ' ');
        string plain = string.Join(' ', letters.ToString().Split(' ', StringSplitOptions.RemoveEmptyEntries));
        foreach (string opener in new[] { "please ", "can you ", "could you ", "would you " })
            while (plain.StartsWith(opener, StringComparison.Ordinal)) plain = plain[opener.Length..];
        if (plain.EndsWith(" please", StringComparison.Ordinal)) plain = plain[..^" please".Length];
        return plain;
    }

    /// <summary>
    /// The teacher agreed to the write that was waiting. Run it, then carry on.
    /// </summary>
    public async Task<List<Line>> Approve(CancellationToken cancellation)
    {
        if (_offeringPreview)
        {
            _offeringPreview = false;
            ShowPreviewInApp?.Invoke();
            const string opening = "The preview is starting in Plantoir's main window — the build shows its progress there.";
            _messages.Add(new JsonObject { ["role"] = "assistant", ["content"] = opening });
            return new List<Line> { new("assistant", opening) };
        }

        if (_awaiting is not { } call) return new List<Line>();
        _awaiting = null;

        var lines = new List<Line>();
        string result = await RunTool(call, lines, cancellation);
        lines.Add(new Line("tools", result));
        if (TurnEnded(lines)) return lines;
        return lines.Concat(await Run(cancellation)).ToList();
    }

    /// <summary>The teacher said no. Tell the model, so it does not simply try again.</summary>
    public async Task<List<Line>> Decline(CancellationToken cancellation)
    {
        if (_offeringPreview)
        {
            _offeringPreview = false;
            const string later = "All right — say “preview the site” whenever you want it back.";
            _messages.Add(new JsonObject { ["role"] = "assistant", ["content"] = later });
            return new List<Line> { new("assistant", later) };
        }

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

            var calls = reply["tool_calls"] as JsonArray;
            bool acting = calls is { Count: > 0 };

            // Content alongside a tool call is almost always the request
            // parroted back — measured as "Unpublishing Unit 4, Day 5
            // (Today is 2026-08-14, a Friday.)", dateline and all, shown to
            // the teacher who had just typed it. The tool's own result says
            // what happened; the parrot adds nothing, so it is not shown.
            // The dateline is stripped from what IS shown, for the same
            // reason: it was written for the model, not the teacher.
            string said = reply["content"]?.GetValue<string>() ?? "";
            if (_dateline.Length > 0) said = said.Replace(_dateline, "");
            if (!acting && said.Trim().Length > 0) lines.Add(new Line("assistant", said.Trim()));

            if (!acting) return lines;

            // One at a time, so a teacher reading the transcript can follow it.
            var call = calls![0] as JsonObject;
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
            if (TurnEnded(lines)) return lines;
        }

        lines.Add(new Line("assistant",
            "I’ve gone round several times without finishing. Tell me what you’d like me to do next."));
        return lines;
    }

    /// <summary>
    /// Whether the last tool handed its work to the main window — and if so,
    /// the turn is over. Asking the model "what next?" after "the preview is
    /// opening in the main window" got the same sentence restated, so the
    /// teacher read it twice and paid ten seconds for the echo.
    /// </summary>
    private bool _handedToApp;

    private bool TakeHandedToApp()
    {
        bool handed = _handedToApp;
        _handedToApp = false;
        return handed;
    }

    /// <summary>
    /// Close out a turn whose last tool handed its work to the app. After a
    /// page edit, the closing line is a QUESTION — restart the preview? —
    /// answered by the same buttons as a tool approval.
    /// </summary>
    private bool TurnEnded(List<Line> lines)
    {
        if (!TakeHandedToApp()) return false;
        if (_offeringPreview)
            lines.Add(new Line("assistant",
                "Shall I start the preview so you can look the change over?",
                NeedsApproval: true, Pending: "start the preview"));
        return true;
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

        // Building and deploying are done by pressing Plantoir's own buttons,
        // once, where the teacher can watch — never by the server in a hidden
        // container run whose transcript lands in this chat.
        // These answers appear in the transcript word for word, so they are
        // written for the teacher — and they END the turn. Asked "what next?"
        // after reading one of these, a small model restates it, and the
        // teacher saw the same sentence twice. There is nothing next: the
        // main window has the work.
        if (name.Equals("rebuild_preview", StringComparison.OrdinalIgnoreCase) && ShowPreviewInApp is not null)
        {
            ShowPreviewInApp.Invoke();
            _handedToApp = true;
            return Answer(call, "The preview is opening in Plantoir's main window — the build shows its progress there.");
        }
        if (name.Equals("deploy_section", StringComparison.OrdinalIgnoreCase) && StartDeployInApp is not null)
        {
            StartDeployInApp.Invoke();
            _handedToApp = true;
            return Answer(call, "The section is deploying from Plantoir's main window — its progress is shown there.");
        }

        // A page edit does what a person would do: stop the preview, change
        // the files, start the preview again. The server never builds
        // (preview declined), so the work happens once, in the main window.
        bool edits = EditsPages.Contains(name);
        if (TakesPreviewFlag.Contains(name)) arguments["preview"] = false;
        if (edits && PreviewIsShowing?.Invoke() == true) StopPreviewInApp?.Invoke();

        string result = await _tools.CallTool(name, arguments, OnToolProgress, cancellation);
        _messages.Add(new JsonObject
        {
            ["role"] = "tool",
            ["tool_call_id"] = call["id"]?.DeepClone(),
            ["content"] = result,
        });
        if (edits)
        {
            _handedToApp = true;
            _offeringPreview = true;
        }
        return result;
    }

    /// <summary>
    /// A restart OFFERED, not performed. The preview was stopped for the
    /// edit; whether to spend the minutes rebuilding it now is the
    /// teacher's call — they may have three more changes coming, and one
    /// rebuild at the end beats four along the way.
    /// </summary>
    private bool _offeringPreview;

    /// <summary>Record a tool's answer without having called the server.</summary>
    private string Answer(JsonObject call, string text)
    {
        _messages.Add(new JsonObject
        {
            ["role"] = "tool",
            ["tool_call_id"] = call["id"]?.DeepClone(),
            ["content"] = text,
        });
        return text;
    }
}
