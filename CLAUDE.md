# Working on Plantoir (containerized-quartz-for-teachers)

**Start here.** This file is the entry point for anyone — human or AI — working
in this repository. It carries the rules that override default behaviour, the
traps that cost real time, and a map of where everything else lives. Deep dives
are in [`documentation/`](documentation/README.md); nothing here repeats them.

## What this is

A teacher writes course notes as Markdown in Obsidian. This project turns that
into a website per class section, using a patched [Quartz
v4.5.0](https://github.com/jackyzha0/quartz/tree/v4.5.0) inside a container the
teacher never sees. There are three surfaces over the same toolchain:

| Surface | Where | What it is |
|---|---|---|
| Launchers | `setup.sh` / `preview.sh` / `deploy.sh` (+ `.ps1`, `.bat`) | The command line. Everything else drives these. |
| macOS app | `mac-app/` — SwiftUI, product name **Plantoir** | The GUI most teachers use. Carries the toolchain inside its bundle. |
| Windows app | `windows-app/` — .NET 9 / WinUI 3 | The same product, built by somebody who cannot read the Swift. |

Shared logic lives in `scripts/*.py` and runs identically on both platforms.
Neither app contains toolchain logic of its own: they write the same
`course_config.json` and run the same scripts.

## Rules that override default behaviour

1. **The GUI never mentions the machinery.** No "toolchain", "script",
   "Docker" or "container" in user-facing text — plain words only ("Building
   your website builder…", "Getting this Mac ready…"). That includes the
   assistant's own plumbing: no model names, parameter counts, tokens, context
   windows or GPU talk. It says "the small assistant" and "the larger
   assistant", and a test enforces it.
2. **A new behaviour goes into the SHARED test suite, or its intent goes into
   the other side's handoff. Never neither.** Every feature and every changed
   behaviour lands in one of two places, and which one is a judgement about
   portability, not about effort:
   - **It belongs in [`contracts/`](contracts/README.md)** if it is a sentence
     a teacher reads, a rule with inputs and expected outputs, or a sequence
     that must happen in order. Add the case, run it here, commit the diff —
     the other side then runs the identical case. Adding to `AssistWording` or
     to a contract's authored half is part of writing the feature, not a
     follow-up.
   - **It belongs in the other side's handoff** — `WINDOWS-HANDOFF.md` for
     work done on the mac, `MAC-HANDOFF.md` for work done on Windows — if it
     cannot be expressed as data: anything visual, anything with platform
     mechanics (WSL2, ConPTY, Colima, port leases), anything measured rather
     than asserted. Then write the INTENT and the desired behaviour, not just
     that it exists. `WINDOWS-HANDOFF.md` keeps the list of what the contract
     cannot carry; if your change is on that list, the handoff is where it goes.

   The failure this prevents is the quiet one: a behaviour that exists in one
   app, is described nowhere the other app's tests can reach, and is discovered
   months later as a difference nobody chose.
3. **Every macOS improvement is written up for Windows, as you go.** The
   Windows app is built from what this side learns, by somebody who cannot read
   the Swift or watch it being tested, so a change that exists only in Swift is
   one they will re-derive from scratch — usually after shipping the same bug
   once. A change is not finished until:
   - **`GUI-IMPROVEMENTS.md` has an entry whose "Notes for Windows port" column
     says something usable** — what to do differently, what is inherited
     unchanged, or the trap that would pass review. "Shared Python, nothing to
     mirror" is fine when true; an empty cell never is.
   - **anything architectural also has a section in
     [`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md)**. A log row records a decision;
     the handoff explains it well enough to implement.
   - **guidance the change made WRONG is corrected there too.** Stale advice is
     worse than none, because it gets followed.

   Say what you measured, not just what you decided — numbers travel, taste does
   not. Write down the **reasoning**, not only the behaviour: a behaviour can be
   read off the code, the reason for it cannot, and a rule whose reason has been
   lost gets "simplified" back out by the next person who reads it. Record the
   options REJECTED and why, or they get proposed again and cost the same
   afternoon twice. This applies to decisions reached by discussion as much as by
   code, and it is not contingent on being asked.
4. **Work that arrives FROM Windows is logged in
   [`MAC-HANDOFF.md`](MAC-HANDOFF.md)**, and entries there are marked `✅ DONE`
   in place rather than deleted, so the ledger keeps its own history.
5. **Colima is shared with other projects** on this machine (Supabase local dev,
   among others). Never `colima stop` unless `docker ps -q` comes back empty.
   The app's quit path and the scripts already enforce this; keep it that way.
   The Colima VM only mounts `$HOME`, so a working folder outside the home
   directory bind-mounts as an empty folder inside the container.
6. **Swift follows the project style rules**: no `map`/`filter`/`reduce`,
   `@Observable` (never `ObservableObject`), `// MARK: -` sections, clarity over
   concision.

## Setting up on a new machine

The command-line toolchain needs nothing built — the launchers download any
tools they are missing and build the Docker image locally on first run.

**macOS app.** The Xcode project file is generated, not committed, so a fresh
clone has no `.xcodeproj`: `mac-app/project.yml` is the committed source of
truth, and generated project files churn and merge badly.

```bash
brew install xcodegen
cd mac-app
./Vendor/fetch-llama.sh     # REQUIRED before generating — see below
xcodegen generate
open Plantoir.xcodeproj
```

Re-run `xcodegen generate` whenever `project.yml` changes, or when files are
added or removed (the file lists are directory-based).

`fetch-llama.sh` fetches the assistant's engine: 25 MB of llama.cpp build
output, macOS arm64, pinned to build `b10435`, deliberately not committed — this
repository ships recipes, not binaries. It is **not optional**: `project.yml`
declares `Vendor/llama` as a resource folder, so `xcodegen generate` fails with
"missing source directory" without it. Model weights are a separate matter
again; nothing in the repo or the bundle carries them, and the app downloads
them to `~/Library/Application Support/Plantoir/models` on a teacher's explicit
yes.

Debug builds are signed with a real "Apple Development" identity
(`DEVELOPMENT_TEAM` in `project.yml`) rather than ad-hoc — an ad-hoc signature
changes every rebuild, so macOS forgets permission grants (like Desktop access)
and re-asks every time. On a machine without that team's certificate, point
`DEVELOPMENT_TEAM` at your own or set `CODE_SIGN_IDENTITY: "-"` and live with
the prompts.

**Windows app.** Nothing is generated, the solution is committed, and the only
prerequisite is the **.NET 9 SDK**. It targets `net9.0-windows10.0.19041.0` /
`win-x64` and ships self-contained, Windows App SDK included, so a teacher
installs no runtime.

```powershell
cd windows-app
dotnet build Plantoir/Plantoir.csproj -c Debug
dotnet test  Plantoir.Tests/Plantoir.Tests.csproj
```

The solution also holds `PtyDriver` (the ConPTY host the app shells launchers
through) and `Plantoir.Mcp`, a standalone MCP server; `publish.ps1` builds,
bundles and signs `plantoir-mcp.exe` beside the app. **Stop any running copy
before building** — a running app holds `Plantoir.Core.dll` open and the build
fails with `MSB3027 … file is locked by: "Plantoir"`, which reads like a corrupt
build rather than the app simply being open.

## App name vs. module name

The user-facing name is **Plantoir** (bundle, binary, Dock, window title,
identifier `ca.russellgordon.Plantoir`). Internally the Swift module, source
folder and test imports are still **QuartzTeachers** — `PRODUCT_NAME: Plantoir`
plus `PRODUCT_MODULE_NAME: QuartzTeachers` in `project.yml`. Don't "fix" it:
renaming the module breaks every `@testable import QuartzTeachers` and buys
nothing a user can see. On first launch the app migrates preferences from the
old `ca.russellgordon.QuartzTeachers` domain.

## How the toolchain ships

There is no Docker Hub. The full build recipe (Dockerfile, `patches/`,
`scripts/`, `support/`, launchers) is bundled inside the app and mirrored into
each working folder's `.toolchain/`. The launchers:

- tag the image `teaching-quartz:src-<hash>`, where the hash covers every file
  in the build context — a changed recipe means a new tag, a rebuild and a
  recreated container, with no update checks anywhere;
- build with BuildKit (`docker buildx build --load`) — the legacy builder
  corrupts a layer, so don't remove that;
- name containers `teaching-quartz-<hash of pwd -P>`, one per working folder.
  The Swift side derives the identical name via POSIX `realpath` — Foundation's
  `resolvingSymlinksInPath()` strips `/private` where `pwd -P` keeps it, so
  don't swap one for the other;
- probe a free host port block per container (8081/8091/8101…), mapping to
  fixed container ports 8081–8084 for sites plus 9081–9084 for Quartz's
  live-reload websockets (`--wsPort` = port + 1000 — without it, concurrent
  previews collide on the websocket even with distinct site ports).

The image carries **wrangler**, Cloudflare's own deploy CLI, used by
`scripts/deploy.py` for the Cloudflare Pages destination (their upload protocol
— BLAKE3 hashing, short-lived JWT, batched uploads — is undocumented enough that
reimplementing it would break teachers' publishing whenever Cloudflare changed
it). It is pinned *below* 4.100 deliberately: from that version wrangler needs
Node 22, while the image ships Node 20 because that is what Quartz v4.5.0 is
known-good against. **If you raise Node, revalidate Quartz before chasing a
newer CLI.**

First-run bootstrap: if Docker isn't available, the launchers download pinned
static binaries (Colima, Lima, the Docker CLI, buildx) into `~/Library/
Application Support/Plantoir/tools` — no Homebrew, no admin rights. The image
lives inside the Colima VM's disk (`~/.colima`).

### Editing the toolchain: two traps that cost real time

A change to `scripts/`, `support/`, `patches/` or a launcher does **not** reach
a working folder until it has travelled through the app bundle. The app mirrors
its bundled copy into `.toolchain/` whenever it touches a folder, and the
launchers hash that folder to name the image. The chain is: edit → **rebuild the
app** → relaunch → next preview refreshes `.toolchain/`, changes the image tag,
recreates the container, and finally runs your change. Skip the rebuild and
everything downstream keeps running the old toolchain while looking perfectly
healthy.

**Trap 1 — Xcode may not copy your edit.** These are declared in `project.yml`
as folder references (`type: folder`), and Xcode tracks a folder reference by
the **directory**. On macOS, editing a file *inside* a directory does not change
that directory's modification time; only adding, removing or renaming an entry
does. An incremental build therefore decides the folder is unchanged and skips
the copy — the build succeeds and the app still carries the previous script.
Force it:

```bash
cd mac-app
xcodegen generate     # rewrites the project, so resources are re-copied
xcodebuild -project Plantoir.xcodeproj -scheme Plantoir -configuration Debug build
```

**Trap 2 — quit the running app first.** Xcode's Run only terminates an instance
*it* launched. If Plantoir is already running, ⌘R gives you a **second** instance
beside the first — and both rewrite `.toolchain/` whenever they touch a folder,
so a stale instance can overwrite the good scripts the new one just wrote.

```bash
osascript -e 'quit app "Plantoir"'; sleep 2
open ~/Library/Developer/Xcode/DerivedData/Plantoir-*/Build/Products/Debug/Plantoir.app
```

**Ask the app what it is actually carrying** rather than assuming — this settles
both traps in one line:

```bash
grep -c <something-from-your-edit> \
  ~/Library/Developer/Xcode/DerivedData/Plantoir-*/Build/Products/Debug/Plantoir.app/Contents/Resources/scripts/build_site.py
```

`0` means the resource copy was skipped and you are testing the old toolchain.
The same check works against a working folder's `.toolchain/`.

**A related rule for the build scripts.** Patches in `build_site.py` fall into
two groups: those inside `if full_rebuild or not output_dir.exists():` run only
when the Quartz scaffold is first copied; those in the ALWAYS section below it
run on every build. A fix that existing course folders must pick up has to go in
the ALWAYS section and be idempotent — otherwise it reaches new courses only,
and every folder built before the fix stays broken until someone passes
`--full-rebuild`.

## The local assistant

Plantoir has an on-device assistant: the teacher types "publish tomorrow's
class" and the pages are published. It is on `main` in both apps and in no
released version, because no release has been tagged yet.

One sentence explains the architecture — **the model never does anything.** It
reads a sentence and answers with the name of a function and its arguments;
every rule, safety check and file written is ordinary code that would behave
identically if the model were replaced by a dropdown menu. The deep dive is
[`documentation/10-local-ai-assistant.md`](documentation/10-local-ai-assistant.md).
Code: `mac-app/QuartzTeachers/Models/Assist/` (with `Views/Assist/`), and
`windows-app/Plantoir.Core/Assist/` plus `windows-app/Plantoir/Services/LocalModel.cs`.

**The mac runs the model natively; Windows still runs it in a container.** The
asymmetry is the largest number in the feature: Colima is a Linux VM with no
access to Metal, so the same 1.5B model on the same 3,411-token prompt took
**175 seconds in a container and 2.1 seconds natively** on an M4 Pro. The mac
spawns the bundled `llama-server` from `Resources/llama/`. Windows runs
`ghcr.io/ggml-org/llama.cpp:server` as its own container — **and should stop**:
moving its model onto the host is a decided direction, written up in
`WINDOWS-HANDOFF.md`. Do not "unify" these by putting the mac's model back in
Colima.

Four things that cost a day each if you do not know them:

- **Thinking must be off, and that takes two flags.** `--reasoning-budget 0`
  alone does NOT stop a Qwen3 chat template opening a `<think>` block; it only
  caps how long the thinking runs once opened. Same prompt, same server: budget
  alone 16.08 s and 512 completion tokens, `--reasoning off` 8.35 s and 44.
  Across the 29-probe suite the identical weights score **97% with thinking off
  and 39% with it on**. `AssistServerHost.serverArguments` passes both flags and
  `AssistModelTierTests.testThinkingIsTurnedOff` asserts both. This shipped wrong
  for days because llama.cpp parses the thinking OUT of `message.content`: the
  answer looks clean and is merely slow, so the honest check is the
  completion-token count and the clock, never the text.
- **The tier ladder was measured, and two candidates were vetoed.** There is no
  3B rung. Qwen2.5-3B inverted polarity on 9 of 10 trials of one hide request;
  Llama-3.2-3B on 10 of 10 — two unrelated families, the same sentence, both
  publishing a page the teacher asked to hide. Zero inversions is a veto rather
  than a tiebreaker, because an inversion is the one failure that reports
  success. Changing a model, quant or context size means re-running the suite.
- **Steer the model with code, not with tool descriptions.** Adding one
  clarifying sentence to `publish_pages`' description, to fix a single typo
  probe, took the promise-card score from 110/110 to 90/110 and broke three
  probes that had been perfect. A small model reads a sentence naming another
  tool as a recommendation, not a boundary. The rule went into Swift instead.
- **Adding a tool is a routing change.** The local model is shown 13 of the 20
  tools that exist (`AssistToolRunner.localTools`); an MCP client is shown 23
  (`.mcpTools`, the 20 plus three that ask for judgement about meaning). More
  choices is the classic way a router degrades.

On the mac the MCP server IS the app: `Plantoir --mcp-stdio <working-folder>`
serves the same tools to Claude Code, so there is no second binary to sign or
forget. Windows ships `plantoir-mcp.exe` instead.

## Example content and skeletons

`support/example_content/<CODE>/` holds ready-made course content, one folder
per Ontario course code (ADA1O is the template to copy; **37 codes** have
payloads today — count the folders rather than trusting a number). Each payload
is `manifest.json` plus `shared/` and `per_section/` trees, and the manifest is
the course's ENTIRE structure when a teacher pre-populates: the wizard asks no
structure questions, so a payload must be complete. Conventions the installer
relies on are in
[`.claude/skills/example-content/SKILL.md`](.claude/skills/example-content/SKILL.md)
— use that skill for any payload work rather than reasoning from scratch.

Adding a course code is pure content: drop in a payload, no code changes. The
wizard discovers it by the manifest's existence, and the payload automatically
retires that code's skeleton.

Every other Ontario code (~1,900 of them) gets a **skeleton** from
`support/skeletons/<family>/`: `families.json` maps 499 three-letter prefixes to
50 families, with a generic fallback. The skeletons are **generated, never
hand-edited** — `.claude/skills/example-content/generate_skeletons.py` holds
eleven shapes and writes ~1,950 pages; `lint_skeletons.py` is the gate. A
mistake there is a mistake in nineteen hundred courses.

## Testing — what gates what

| Change | Gate |
|---|---|
| Toolchain (launchers, `scripts/`, Dockerfile, patches) | `./verify.sh` — builds a fresh `quartz-teacher:dev-test` image from the working tree, checks the baked files match, drives the real launchers. Needs a TTY; from a non-interactive shell: `script -q /dev/null ./verify.sh` |
| macOS app | `cd mac-app && xcodebuild -project Plantoir.xcodeproj -scheme Plantoir -configuration Debug test -only-testing:QuartzTeachersTests` |
| Windows app | `cd windows-app && dotnet test Plantoir.Tests/Plantoir.Tests.csproj` |
| Assistant routing | **Nothing.** Measured by hand — see below. |

`verify.sh` **does not run on Windows** (bash, and it expects `docker` on PATH;
in the normal Windows setup Docker Engine lives inside WSL2). Toolchain changes
made on Windows have no automated gate: verify them by driving a real publish
through the app, and re-run `verify.sh` from the mac after the next sync.

**Windows tests touching process-wide state must not run in parallel.** Preview
leases and the publish registry are statics and xUnit parallelises test
*classes*, so any class touching them belongs in the shared serialized
collection (`SharedActivityState` in `ModelTests.cs`). Skipping that produces an
intermittent failure that looks exactly like a production bug and is not one.

**Assistant changes** are covered by the mac unit suite for everything provable
without a model — the tier ladder, the server flags, the tool surface, the
approval gate. Nothing gates ROUTING: whether the model still picks the right
tool is measured by hand against a local `llama-server`, with the suites and
results in [`research/ai-assist/`](research/README.md).

**Launchers are snapshots.** Working folders copy them at setup; the app
refreshes any that differ from its bundled copies. A launcher fix reaches folders
through the app bundle — rebuild the app to test it end to end.

## Where the truth lives, per kind of truth

The same rule used to be written in four places at once, and three of them
would drift — a sentence in the Swift that says it, in the test that pins it,
in the log row that specified it, and in the handoff telling Windows to copy
it. So each kind of truth now has **one** home, and everywhere else points at
it rather than restating it:

| The question | The one place that answers it |
|---|---|
| What does the assistant SAY to a teacher? | `AssistWording` in the mac app → generated into [`contracts/assist-wording.json`](contracts/assist-wording.json). |
| What must HAPPEN, and in what order? | [`contracts/assist-cases.json`](contracts/assist-cases.json) — run by both test suites. |
| What is the launcher asked to do, what is a teacher told about what they typed, which progress markers are shared? | [`contracts/app-rules.json`](contracts/app-rules.json). |
| WHY is it that way, and what was rejected? | [`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md) for anything an implementer needs; a code comment for anything a reader of that file needs. |
| WHAT changed, WHEN, and what it cost | [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md) — a dated log. **Append-only history, not a specification**: a row records what was true that day, and is not edited when the behaviour changes again. Never quote a row as the current wording. |
| How does the whole feature work? | [`documentation/10-local-ai-assistant.md`](documentation/10-local-ai-assistant.md). |
| What did we MEASURE? | [`research/`](research/README.md) — routing accuracy, model tiers, preview staleness. Never asserted in a test; each file states its own conditions. |
| Which rules override default behaviour? | This file. |

The practical rule that falls out of it: **if you are about to type one of the
assistant's sentences into a document or a test, don't — name it instead.**
`AssistWording.deployWasCancelled`, or `wording.deployWasCancelled` in the
contract. A quoted copy is the one that keeps passing after the product's
words change.

## The two handoff documents, and where a Windows session begins

There are exactly **two**, and they point in opposite directions:

- [`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md) — mac → Windows. Everything this
  side learned, written for somebody who cannot read the Swift.
- [`MAC-HANDOFF.md`](MAC-HANDOFF.md) — Windows → mac. Work that originated
  over there and needs attention here; entries are marked `✅ DONE` in place
  rather than deleted.

(The old `AI-ASSIST-HANDOFF.md` is gone: it was a record of how the assistant
was built, and it now lives in
[`research/ai-assist/HISTORY.md`](research/ai-assist/HISTORY.md).)

**Starting work on the Windows app? Read in this order.** It is the shortest
path from nothing to a change that will not be re-derived:

1. **This file**, for the rules that override default behaviour.
2. **[`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md)** — architecture, the config
   contract, and the reasoning behind the decisions. Long, and the section
   headings are enough to navigate.
3. **[`contracts/README.md`](contracts/README.md)**, then the three JSON files.
   These are the acceptance list: wire them into `Plantoir.Tests` and the
   assistant's behaviour is tested rather than eyeballed. **Do not retype the
   sentences or the scenarios into your test files** — deserialise them.
4. **[`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md)**, newest rows first, for
   what changed recently and why. Read it as history; where a row and the
   contract disagree, the contract is what is true now.
5. **[`windows-app/PROGRESS.md`](windows-app/PROGRESS.md)** for where that app
   actually stands.

Two known-failing cases are waiting in `contracts/assist-cases.json` — "deploy
with a preview running" and "deploy while that section is already busy" — and
they are a fair first task: implementing them fixes a real bug on that side.

## Where everything else lives

| Read this | When |
|---|---|
| [`documentation/`](documentation/README.md) | How the toolchain works, numbered 01–10: overview, image, launchers, course setup, build pipeline, Quartz customizations, deployment, config reference, mac app, local AI assistant. |
| [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md) | The dated log of every GUI change, with a required "Notes for Windows port" column. Append here for any GUI change — and read it as HISTORY: it used to be described as "the spec", and `contracts/` is what a test should be written against now. |
| [`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md) | Architecture, the config contract, platform notes, and the WSL2 background — start here for Windows work, and write architectural decisions into it. |
| [`contracts/`](contracts/README.md) | What the two apps must agree on, as data both test suites run: the assistant's sentences and behaviour cases, and the app-wide rules — launcher arguments, validation messages, progress markers, preview ports. Generated from the macOS app; never hand-edited. |
| [`MAC-HANDOFF.md`](MAC-HANDOFF.md) | The mirror: work that originated on Windows or in shared `scripts/` and needs the mac's attention. Read it when syncing the two sides. |
| [`RELEASING.md`](RELEASING.md) | Cutting a release: signing, bundling, and the frozen asset names both platforms depend on. |
| [`TODO.md`](TODO.md) | Deferred work, with the research already done so picking one up is cheap. |
| [`research/`](research/README.md) | Measurement records the code cites as evidence — the assistant's model choices and the preview-staleness findings. Not an automated gate; each file states its own conditions. |
| [`mac-app/README.md`](mac-app/README.md) · [`windows-app/PROGRESS.md`](windows-app/PROGRESS.md) | Per-app build, test and layout notes. |
| [`README.md`](README.md) | The teacher-facing introduction. Written for them, not for us — it deliberately says nothing about the assistant until a release ships it. |
| `.claude/skills/` | Task-specific procedures: `example-content` (payloads and skeletons), `mac-app` (building so it can actually be run), `cut-release`. Invoke the skill rather than reconstructing its steps. |
