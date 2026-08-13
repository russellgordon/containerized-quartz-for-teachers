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

For a release build, publish somewhere stable rather than leaving it in
`bin\Release`, which a `dotnet clean` wipes:

```powershell
dotnet publish Plantoir.Mcp/Plantoir.Mcp.csproj -c Release -r win-x64 -o "$HOME\Plantoir\mcp"
# macOS: -r osx-arm64
```

It publishes self-contained and single-file (~75 MB), so a teacher installs no
runtime.

**A connected client holds the binary open.** MCP servers run for the lifetime
of the client session, so re-publishing over a copy that Claude Desktop or
Claude Code still has connected fails with "the process cannot access the file
… being used by another process". Close the client session first. The client
has to be restarted to pick up a new build anyway — servers are connected at
startup.

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
| `plan_publish_pages` | **no** | What publishing would do — resolves links, names every file and key |
| `plan_hide_pages` | **no** | The same for hiding |
| `publish_pages` | yes | Backs up, un-drafts, rebuilds, publishes |
| `hide_pages` | yes | Backs up, drafts, rebuilds, publishes |
| `republish_section` | yes (site only) | Rebuild and deploy without touching any page |
| `back_up_course` | yes (additive) | A whole-course backup, restorable from Plantoir |

The write tools take a **list** of pages and accept **any** page — a class
page, a concept, an exercise, anything. Both of those came from a real session
the earlier one-class-page-at-a-time surface could not serve:

- Hiding 25 classes meant 25 calls, each republishing the site: **26 deploys
  for one logical change.** Pass them in one call instead, or use
  `republish: false` on each and finish with `republish_section`.
- A safety contract linked from *both* the first class (staying up) and a later
  one (coming down) made the task **unsatisfiable**: `includeLinked` took it
  down and nothing could put just that page back. Naming any page directly
  dissolves it. That shape — a shared page reachable from several classes — is
  the normal shape of a course, not an edge case.

`includeLinked` has **no default on any of the four**, deliberately. It used to
default to `true` for publishing and `false` for hiding, which is defensible
but was nowhere written down; a caller has to decide.

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

## Why the plan output is shaped the way it is

A real session ran `plan_publish_class` twice on the same page, with the file
edited in between, and got:

```
Nothing would change — “Unit 4, Day 5” is already published, and so are the 2 pages it links to.
```

then

```
Publish “Unit 4, Day 5” … and publish the 1 page it links to.
```

**Both answers were correct** — there is no cache anywhere in the plan path,
every call re-reads from disk, and a page had genuinely been drafted between
them. But they read as a contradiction, and the reader reasonably concluded
the plan tool could not be trusted. Which is the worst possible thing to
conclude about the one output the whole workflow says to show the teacher.

The cause was wording, and it is fixed by two rules:

1. **One count never means two things.** "the N pages they link to" is always
   the number of links followed. How many would *change* is a separate
   sentence with its own number. The old phrasing used the same shape for
   both, so a state change looked like an arithmetic error.
2. **State is stated.** Every changing page prints its key and its transition
   (`draftSection1: true → false`). A plan that says what it saw can differ
   from an earlier plan without either looking wrong — and it makes the dual
   frontmatter schema impossible to miss.

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
- **`courses/` is not in version control** — it is line 1 of the repo's
  `.gitignore`. `git status` stays clean no matter how many course files
  change, and there is no `git checkout` undo. `back_up_course` is the only
  undo, which is why every write tool calls it first. Anything scripting bulk
  edits against a course should do the same, and verify by reading files
  rather than by `git diff`.
- **A publish needs Docker and takes minutes**, and there is no way to ask how
  far along it is beyond the progress notifications.

### The TTY problem, and why it is no longer one

`docker exec -t` **refuses to start** when stdin is not a terminal. The
launchers used `-it` unconditionally, so a publish driven from this server —
or from any script, or CI — failed at the last step with "the input device is
not a TTY", *after* several minutes of Docker build. `verify.sh` had long
refused up front for exactly this reason.

The launchers now ask for a terminal only when there is one, and run Python
unbuffered when there isn't, so progress still arrives line by line. Verified:
`preview.ps1 EXC2O 1 --build-only < /dev/null` runs to completion. The
interactive path is unchanged, so the GUI (which supplies a terminal through
ConPTY) behaves exactly as before. The same fix is in `preview.sh` and
`deploy.sh` for the mac side.

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
