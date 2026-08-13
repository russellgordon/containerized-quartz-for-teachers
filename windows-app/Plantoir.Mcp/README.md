# plantoir-mcp

An [MCP](https://modelcontextprotocol.io) server that exposes one Plantoir
working folder to an AI assistant, so a teacher can say

> Publish tomorrow's class — Unit 2, Day 3 in ICS3U section 1 — and everything
> it links to.

…and have it happen, after confirming a plain-words summary of what will
change.

This is **step 1 of the plan in [`AI-ASSIST.md`](../../AI-ASSIST.md)**, and it
deliberately contains no AI model of its own. It is useful immediately for a
teacher who already has Claude Desktop or Claude Code, it can be tested with
ordinary code, and building it first forces the tool surface to be right before
anything depends on it.

Status: **works, not yet shipped.** It lives on the `ai-assist` branch and is
not part of the 1.0 release.

---

## Building and running

```powershell
cd windows-app
dotnet build Plantoir.Mcp/Plantoir.Mcp.csproj
dotnet test  Plantoir.Tests/Plantoir.Tests.csproj      # the logic is covered here
```

The server takes the working folder it serves and nothing else:

```powershell
plantoir-mcp --folder "C:\Users\me\Documents\Teaching"
```

`PLANTOIR_FOLDER` works as an alternative. The folder is fixed at startup and
never changes — a server that could be re-pointed mid-session would make every
path check meaningless.

For a release build:

```powershell
dotnet publish Plantoir.Mcp/Plantoir.Mcp.csproj -c Release -r win-x64
# macOS: -r osx-arm64
```

It publishes self-contained and single-file, so a teacher installs no runtime.

### Pointing a client at it

Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "plantoir": {
      "command": "C:\\Program Files\\Plantoir\\plantoir-mcp.exe",
      "args": ["--folder", "C:\\Users\\me\\Documents\\Teaching"]
    }
  }
}
```

Claude Code:

```powershell
claude mcp add plantoir -- "C:\Program Files\Plantoir\plantoir-mcp.exe" --folder "C:\Users\me\Documents\Teaching"
```

Teachers should never have to write that by hand. Phase 3 of the proposal is
Plantoir writing this snippet itself from an "AI Automation" settings pane.

---

## The tools

| Tool | Changes anything? | What it does |
|---|---|---|
| `list_courses` | no | Codes, names, sections, publish destination |
| `list_pages` | no | Pages in a section; `matching` filters, output is capped |
| `read_page` | no | One page's Markdown including frontmatter |
| `plan_publish_class` | **no** | What publishing would do — resolves links, names every file |
| `plan_hide_class` | **no** | The same for hiding |
| `publish_class` | yes | Backs up, un-drafts, rebuilds, publishes |
| `hide_class` | yes | Backs up, drafts, rebuilds, publishes |
| `back_up_course` | yes (additive) | A whole-course backup, restorable from Plantoir |

`publish_class` and `hide_class` take `republish: false` to change the pages
without rebuilding — useful when several changes are being made in a row.

---

## Why the surface looks like this

Every rule below is the direct consequence of something measured on the
`ai-assist` branch. The numbers are in [`AI-ASSIST.md`](../../AI-ASSIST.md);
the reasoning is repeated here because this is the file someone will read
before changing the tools.

**The tools do the work; the assistant only picks one.** Given fine-grained
tools (`resolve_links`, `set_draft`, `publish_section`) and asked to publish a
class "and everything it links to", a small model chose `publish_section` and
skipped the link resolution — 8 times out of 8. Given a single coarse
`publish_class` that resolves links itself, it was right 8 times out of 8. So
link resolution, the backup, the rebuild and the publish are **one** operation
here. Resist the urge to split them for tidiness: every unit of reasoning moved
out of the model and into ordinary code is a unit of reliability bought back.

**Publishing and hiding are separate tools, not one tool with a flag.** The
one genuinely dangerous failure observed was polarity inversion — asked to
*hide* a page, the model called publish, with "include everything it links to"
set. It got the same prompt right on another run, so it is inconsistent rather
than deterministic, which is worse. A boolean can be flipped; a verb in the
tool name cannot.

**Nothing named is taken on trust.** Asked to "clean up my course" — a request
naming no course at all — the model proposed backing up `MCV4U`, a code it
invented. Every course code, section number and page title is checked against
what is on disk, and a miss is a refusal that names what *does* exist. A title
matching two pages is refused rather than resolved by picking one.

**There is no delete, archive, rename or overwrite tool, and that is the
point.** The model reliably declined "delete the Unit 1 folder" — not from
judgement, but because it had no tool for it. Absence is the strongest
guardrail available. Please keep it.

**Every write backs the course up first.** Not as a separate tool call the
assistant might skip: `publish_class` and `hide_class` call it themselves, and
abort if it fails. Row 106 built whole-course backups anticipating exactly
this ("an LLM can make a mess that is hard to undo"), so undo is a real button.

**Every write has a `plan_` twin that changes nothing.** The assistant is
expected to plan, show the teacher, and only then act; the descriptions say so
and the plan output is written to be read aloud.

---

## The one genuinely subtle thing: which draft key

A page's visibility is controlled by different frontmatter keys depending on
where the page lives, and getting it wrong hides a page in a class the teacher
never mentioned.

- A page under `section<N>/` — a class page, `Key Links.md` — belongs to
  exactly one section and carries a plain **`draft:`**.
- A page at course level — `Concepts/`, `Discussions/` — is copied into
  **every** section at build time and carries **`draftSection<N>:`**, one per
  section. That is what lets "Ohm's Law" be published in section 1 and still
  drafted in section 2.

`build_site.py`'s `process_frontmatter` copies `draftSection<N>` over `draft`
for the section being built, then strips every `draftSection*` key from the
built copy. Source files keep both; only the build output is flattened.

`PagePaths.SectionOf` decides this from the layout on disk — never from
anything the caller claims — and `PageFrontmatter.DraftKeyFor` turns it into a
key. This is not something a model should ever be asked to work out.

Edits are **line-level**. Round-tripping the teacher's frontmatter through a
YAML library would reorder keys, requote strings, reflow the tag list and drop
their comments — a diff full of changes nobody asked for, in files Obsidian has
open. `PageFrontmatter` finds the line, changes the value after the colon, and
leaves every other byte alone, CRLF included.

---

## A naming trap, written down so nobody rediscovers it

**Never call `Path.GetFileNameWithoutExtension` on a wikilink target.**

Curriculum expectation pages are genuinely named `A1.1`, `B2.4`, `E2.6`, and
concept pages link to them (`- [[E2.6]] — ![[E2.6#^text]]`). Asking for the
"extension" of `E2.6` gives `.6`, and the name without it is `E2` — so every
curriculum link resolves to nothing, silently, and a concept page's
expectations vanish from every plan. Strip a trailing `.md` and nothing else.

The same trap is why attachments (`![[diagram.png]]`) are detected against a
**fixed list** of extensions rather than by taking whatever follows the last
dot. Attachments resolve to `LinkOutcome.Attachment`: they ride along with the
page that embeds them and have no draft flag of their own, so they are not
reported as missing pages.

## Known limits

- **The GUI cannot see this server, and it cannot see the GUI.** Busy-tracking
  (`CourseActivity`, `PreviewLeases`) is in-process. Overnight this is moot —
  the app is closed — but publishing from both at once could corrupt a build.
  v2 is a lease file under the working folder that both the apps and this
  server honour; it is a shared-design item, in the proposal.
- **Cloudflare courses are refused.** A Pages-scoped token cannot list its own
  account, so the account ID lives in Plantoir's settings; the server says so
  and points at the app. Netlify and local-folder publishing work.
- **stdin is closed for launcher runs on purpose.** `deploy.ps1` prompts for a
  token it cannot find, and a prompt nobody can answer would hang the tool call
  indefinitely while the assistant reports "still working". With stdin at EOF
  it fails immediately and the server can say the useful thing: publish once
  from Plantoir so the token gets stored.
- **Not tested against a real MCP client yet** — only against real JSON-RPC
  over stdio, driven the way a client drives it.

---

## Notes for anyone changing this

- **stdout belongs to the protocol.** All logging goes to stderr via
  `LogToStandardErrorThreshold = LogLevel.Trace` in `Program.cs`. One stray
  `Console.WriteLine` corrupts the session for the whole client.
- **`[McpServerTool]`'s `Destructive` defaults to `true`.** Set it explicitly.
- **A tool parameter is optional only if it has a C# default value.**
  Nullability alone does not do it — `string? x` without `= null` is still
  required, and the SDK throws at call time.
- **Progress** comes from an `IProgress<ProgressNotificationValue>` parameter,
  which the SDK excludes from the schema. Do not use MCP logging notifications;
  they are deprecated as of spec 2026-07-28.
- **Tool classes are constructed per invocation**, so state belongs in the
  injected singleton (`AssistWorkspace`), not in the tool class.
- The SDK's stdio transport **exits when stdin closes**, so a test harness must
  hold stdin open rather than piping a finite file.
