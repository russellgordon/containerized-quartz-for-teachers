# Proposal: AI Automation for Plantoir via an MCP Server

*From the Windows side, for consideration by the macOS side.*

> **Status, 2026-08-13.** Phase 1 **is now built**, on the `ai-assist` branch:
> `windows-app/Plantoir.Mcp/` ([README](windows-app/Plantoir.Mcp/README.md)).
> Not on `main`, not in 1.0.
>
> Two things changed from the design below, both because of measurements in
> [`AI-ASSIST.md`](AI-ASSIST.md) taken after this was written:
>
> - **The tool surface is coarser.** `resolve_links` and `set_draft` are no
>   longer separate tools. Given fine-grained tools, a small model skipped the
>   link resolution 8 times out of 8; given one `publish_class` that resolves
>   links itself, it was right 8 out of 8. Link resolution, the backup, the
>   rebuild and the publish are now one operation.
> - **Publishing and hiding are separate tools**, not one call with a flag,
>   because the model inverted the polarity of a hide request. Every write also
>   gained a `plan_` twin that changes nothing, so the teacher confirms first.
>
> The Phase 0 question below is still open and still the one that needs both
> sides.

## The idea

Teachers increasingly have an AI assistant at hand (Claude Desktop, Claude
Code). If Plantoir ships an MCP server — the standard protocol those
assistants use to call external tools — a teacher could say:

> "Publish the Science courses overnight, and make tomorrow's class —
> Unit 2, Day 3 — no longer a draft, as well as all of the pages it
> directly links to."

…and the assistant would do it: find the courses, find the page, resolve its
links, flip the `draft:` flags, and run the publishes. The assistant does the
orchestration and the scheduling ("overnight" is the AI client's job — MCP
servers expose capabilities, they don't schedule). Our job is only to expose
honest, well-described tools.

## Why Plantoir is unusually well-suited to this

Everything an assistant needs already exists *below* the GUI:

- **Content operations** are plain-file edits — Markdown frontmatter and
  `course_config.json`. No app involvement needed.
- **Publishing** is `deploy.sh` / `deploy.ps1 CODE N` — the same shared
  launchers both apps shell. The MCP server is just *another consumer of the
  launchers*, exactly like the standalone-CLI use case we already protect.
- **The model layer is reusable.** On Windows, `Plantoir.Core` (course
  discovery, config accessors, the archiver/backup machinery from row 106)
  targets plain .NET with no UI dependency.

## The proposed route — and the decision that needs both sides

Three architectures were considered:

1. **Server inside each GUI app** — rejected. Overnight automation would
   require the app running; MCP clients want to spawn a stdio child process;
   and it means writing the server twice (Swift + C#).
2. **Python server in the toolchain container** — rejected. Publishing needs
   host-side pieces (the keychain/Credential Manager token, the file copies),
   and host Python violates the zero-prerequisite rule.
3. **A small self-contained .NET console app, `plantoir-mcp`, shipped beside
   the app** — ✅ **proposed.** Stdio transport (the client config is just
   `command: <path-to-binary>, args: ["--folder", "<working folder>"]`), runs
   headless, self-contained so teachers install nothing.

**The quietly big win — and the ask:** because the server has no UI
dependency, *one C# implementation can serve both platforms*. .NET publishes
self-contained binaries for `osx-arm64`; the server would invoke `deploy.sh`
on the mac and `deploy.ps1` on Windows, and the platform-neutral logic
(frontmatter edits, link resolution, name-form parsing) is written once and
tested once. The alternative is the usual mirroring: a Swift server on mac, a
C# server on Windows, and every behavior implemented twice forever.

This is the one decision that genuinely needs both sides: **is the mac side
comfortable bundling (or shipping beside the app) a .NET-published binary?**
If yes, the Windows side builds the server and the mac side's work is
distribution + the shared safety protocol below. If no, the tool contract in
this document becomes the spec both implementations follow.

There is an official MCP C# SDK (the `ModelContextProtocol` package, an
Anthropic/Microsoft collaboration); verifying its current API against our
solution is the first build step.

## Tool surface (v1)

Read-only discovery, safe edits, backup, and publish — deliberately **no
delete tools** in v1:

| Tool | What it does |
|---|---|
| `list_courses` | Codes, names, sections, publish target — read from the config files |
| `list_pages` / `read_page` | Enumerate and read a course's Markdown; every path validated to stay inside the working folder |
| `set_draft` | Flip `draft:` in one page's frontmatter — a line-level edit that preserves the teacher's formatting, never a YAML reserialize |
| `resolve_links` | A page's direct `[[wikilink]]` targets mapped to files, matching Quartz/installer semantics exactly |
| `back_up_course` | The row-106 whole-course backup. Tool descriptions steer the assistant to back up **before** bulk edits — the "handing a pile of pages to an LLM" scenario row 106 was designed for, closing its own loop |
| `publish_section` | Runs the deploy launcher non-interactively; parses the same Live-URL / `PUBLISHED_FOLDER` markers the GUIs parse; streams MCP progress notifications (publishes take minutes, and a first run may rebuild the toolchain image) |

## The one real risk: concurrency with the GUI

Each app's busy-tracking (`CourseActivity`, preview leases) is in-process —
an external server can't see the GUI's in-flight preview, and vice versa.
Overnight this is moot (app closed); daytime overlap could corrupt a build.

- **v1:** document the constraint, plus a best-effort probe (the `--stop`
  machinery already detects container processes by working directory).
- **v2:** move the activity registry to a small **file-based protocol that
  both the app and the server honor** — e.g. a lease file under the working
  folder. **Both apps would adopt this**, so it's a shared-design item even
  if the mac side passes on the shared binary.

Other guardrails: the server is locked to one working folder passed at
startup; deploy runs with stdin closed so a missing Netlify token fails fast
with "open Plantoir and publish once to store your token" instead of hanging.

## Phases

| Phase | What | Who |
|---|---|---|
| **0 — Decisions** | Shared C# server vs per-platform; how it ships on each OS; sketch the shared activity-file protocol | Both sides |
| **1 — MVP** | `PlantoirMcp` project with the six tools; frontmatter/link logic unit-tested; manual test against Claude Desktop / Claude Code in a real workspace | Windows first |
| **2 — Safety** | File-based activity registry shared with the apps; busy declines with plain-words reasons, in the apps' voice | Both sides |
| **3 — Teacher UX** | An "AI Automation" section in each app that **writes the MCP config snippet into Claude Desktop's config for the teacher** — no hand-edited JSON, ever; a docs page; mac distribution | Both sides |

Estimated effort for Phase 1 is roughly one working session on the Windows
side; the interesting conversations are Phase 0 and the Phase 2 protocol.

## Questions for the macOS side

1. Shared .NET-published `plantoir-mcp` binary on mac — acceptable, or would
   you rather implement the tool contract in Swift?
2. Where should it live on mac — inside the app bundle, or beside it?
3. Any objections to the v1 tool surface (especially the no-delete rule and
   backup-first steering)?
4. Thoughts on the lease-file shape for the shared activity registry (v2)?
