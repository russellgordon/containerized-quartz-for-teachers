# Developer notes

Orientation for anyone (including future you, on a new machine) working on
this repository. Deep dives live in [`documentation/`](documentation/README.md);
this file covers the things that are easy to trip over.

## Setting up on a new machine

The command-line toolchain needs nothing built — the launcher scripts
(`setup.sh`, `preview.sh`, `deploy.sh`) download any tools they are missing
and build the Docker image locally on first run.

The macOS app is another story: **the Xcode project file is generated, not
committed**, so a fresh clone has no `.xcodeproj`. That is deliberate —
`mac-app/project.yml` is the committed source of truth (targets, resources,
build settings), and generated project files churn and merge badly. To get
building:

```bash
brew install xcodegen
cd mac-app
xcodegen generate
open Plantoir.xcodeproj
```

Re-run `xcodegen generate` any time `project.yml` changes (or when files are
added/removed, since the file lists are directory-based).

Debug builds are signed with a real "Apple Development" identity
(`DEVELOPMENT_TEAM` in `project.yml`) rather than ad-hoc — an ad-hoc
signature changes every rebuild, so macOS forgets permission grants (like
Desktop access) and re-asks on every build-and-run. On a machine without
that team's certificate, point `DEVELOPMENT_TEAM` at your own (Xcode →
Settings → Accounts shows the ID) or set `CODE_SIGN_IDENTITY: "-"` and
live with the permission prompts.

### The Windows app

The Windows app is the opposite story: nothing is generated, the solution
is committed, and the only prerequisite is the **.NET 9 SDK**. It targets
`net9.0-windows10.0.19041.0` / `win-x64` and ships **self-contained**,
Windows App SDK included, so a teacher installs no runtime; the SDK itself
arrives as the `Microsoft.WindowsAppSDK` NuGet package rather than a
machine-wide install.

```powershell
cd windows-app
dotnet build Plantoir/Plantoir.csproj -c Debug
dotnet test  Plantoir.Tests/Plantoir.Tests.csproj
```

Release packaging is separate — see
[`windows-app/RELEASING.md`](windows-app/RELEASING.md).

The solution also holds `PtyDriver` (the ConPTY host the app shells launchers
through) and, **on the `ai-assist` branch only**, `Plantoir.Mcp` — a
standalone MCP server that is not part of 1.0 and not built by the release.
See [`windows-app/Plantoir.Mcp/README.md`](windows-app/Plantoir.Mcp/README.md).

Two things that otherwise cost an afternoon:

- **Stop any running copy before building.** A running app holds
  `Plantoir.Core.dll` open and the build fails with `MSB3027 … file is
  locked by: "Plantoir"`, which reads like a corrupt build rather than the
  app simply being open.
- **Launchers reach working folders through the app**, exactly as on the
  mac: the app mirrors its bundled toolchain into each folder's
  `.toolchain/`. After changing a launcher or anything under `scripts/`,
  **rebuild the app** before testing end to end, or the working folder
  quietly keeps running the old copy.

## App name vs. module name

The app's user-facing name is **Plantoir** (bundle, binary, Dock, window
title, bundle identifier `ca.russellgordon.Plantoir`). Internally the Swift
module, source folder, and test imports are still **QuartzTeachers** — the
split is `PRODUCT_NAME: Plantoir` + `PRODUCT_MODULE_NAME: QuartzTeachers` in
`project.yml`. Don't "fix" the inconsistency: renaming the module breaks
every `@testable import QuartzTeachers` and buys nothing a user can see.
On first launch under the new identity the app migrates preferences from the
old `ca.russellgordon.QuartzTeachers` defaults domain.

## How the toolchain ships

There is no Docker Hub. The full build recipe (Dockerfile, `patches/`,
`scripts/`, `support/`, launchers) is bundled inside the app and mirrored
into each working folder's `.toolchain/`. The launchers:

- tag the image `teaching-quartz:src-<hash>`, where the hash covers every
  file in the build context — a changed recipe means a new tag, a rebuild,
  and a recreated container, with no update checks anywhere;
- build with BuildKit (`docker buildx build --load`) — the legacy builder
  corrupts a layer, so don't remove that;
- name containers `teaching-quartz-<hash of pwd -P>`, one per working
  folder. The Swift side derives the identical name via POSIX `realpath` —
  Foundation's `resolvingSymlinksInPath()` strips `/private` where `pwd -P`
  keeps it, so don't swap one for the other;
- probe a free host port block per container (8081/8091/8101…), mapping to
  fixed container ports 8081–8084 for sites plus 9081–9084 for Quartz's
  live-reload websockets (`--wsPort` = port + 1000 — without it, concurrent
  previews collide on the websocket even with distinct site ports).

The image also carries **wrangler**, Cloudflare's own deploy CLI, which
`scripts/deploy.py` uses for the Cloudflare Pages destination (Cloudflare's
upload protocol — BLAKE3 asset hashing, a short-lived upload JWT, batched
uploads — is undocumented enough that reimplementing it would break
teachers' publishing whenever Cloudflare changed it). It is pinned, and
pinned *below* 4.100 deliberately: from that version wrangler requires Node
22, while the image ships Node 20 because that is what Quartz v4.5.0 is
known-good against. **If you raise Node, revalidate Quartz before chasing a
newer CLI.** Building the image now also needs npm registry access
alongside the Debian and GitHub sources.

First-run bootstrap: if Docker isn't available, the launchers download
pinned static binaries (Colima, Lima, the Docker CLI, buildx) into
`~/Library/Application Support/Plantoir/tools` — no Homebrew, no admin
rights. The image itself lives inside the Colima VM's disk (`~/.colima`).

### Editing the toolchain: two traps that cost real time

A change to `scripts/`, `support/`, `patches/`, or a launcher does **not**
reach a working folder until it has travelled through the app bundle. The
app mirrors its bundled copy into `.toolchain/` whenever it touches a
folder, and the launchers hash that folder to name the image. So the chain
is: edit → **rebuild the app** → relaunch → next preview refreshes
`.toolchain/`, changes the image tag, recreates the container, and finally
runs your change. Skip the rebuild and everything downstream keeps running
the old toolchain while looking perfectly healthy.

**Trap 1 — Xcode may not copy your edit.** These are declared in
`project.yml` as folder references (`type: folder`), and Xcode tracks a
folder reference by the **directory**. On macOS, editing a file *inside* a
directory does not change that directory's modification time; only adding,
removing, or renaming an entry does. An incremental build therefore
decides the folder is unchanged and skips the copy — the build succeeds
and the app still carries the previous script. Force the copy:

```bash
cd mac-app
xcodegen generate     # rewrites the project, so resources are re-copied
xcodebuild -project Plantoir.xcodeproj -scheme Plantoir -configuration Debug build
```

In Xcode, Product ▸ Clean Build Folder (⇧⌘K) before ⌘R does the same job.

**Trap 2 — quit the running app first.** Xcode's Run only terminates an
instance *it* launched. If Plantoir is already running (opened from Finder,
or left over from an earlier session), ⌘R gives you a **second** instance
beside the first. That matters more here than in most apps: both instances
rewrite `.toolchain/` whenever they touch a folder, so a stale instance can
overwrite the good scripts the new one just wrote, and it still owns that
folder's container. Quit, then launch:

```bash
osascript -e 'quit app "Plantoir"'; sleep 2
open ~/Library/Developer/Xcode/DerivedData/Plantoir-*/Build/Products/Debug/Plantoir.app
```

(The `Plantoir-*` suffix is a hash of the project's path, so the glob
matches one folder — unless the repository has lived in more than one
place, in which case stale folders linger and the glob is ambiguous. Get
the exact path with
`xcodebuild -project Plantoir.xcodeproj -scheme Plantoir -showBuildSettings | grep -m1 ' BUILT_PRODUCTS_DIR'`.)

**Ask the app what it is actually carrying** rather than assuming — this
settles both traps in one line:

```bash
grep -c <something-from-your-edit> \
  ~/Library/Developer/Xcode/DerivedData/Plantoir-*/Build/Products/Debug/Plantoir.app/Contents/Resources/scripts/build_site.py
```

`0` means the resource copy was skipped and you are testing the old
toolchain. The same check works against a working folder's
`.toolchain/scripts/build_site.py` to confirm the change reached *there*.

**A related rule for the build scripts themselves.** Patches applied in
`build_site.py` fall into two groups: those inside the
`if full_rebuild or not output_dir.exists():` branch run only when the
Quartz scaffold is first copied, and those in the ALWAYS section below it
run on every build. A fix that existing course folders must pick up has to
go in the ALWAYS section and be idempotent — otherwise it reaches new
courses only, and every folder built before the fix stays broken until
someone passes `--full-rebuild`.

## Example content payloads

`support/example_content/<CODE>/` holds ready-made course content, one
folder per Ontario course code (ADA1O is the template to copy). Each payload
is `manifest.json` plus `shared/` and `per_section/` trees. The manifest is
the course's ENTIRE structure when a teacher pre-populates — folders,
files, hidden, expandable — and the wizard asks no structure questions, so
a payload must be complete: no folder should ship empty, and reference
pages (Help Sessions, a populated Key Links, the section landing page with
its transclusions) belong in every payload. Conventions the installer
relies on:

- every page's frontmatter uses the literal `created: __CREATED__` sentinel,
  and per-section pages may use `__SECTION_NUMBER__` (e.g. the section
  landing page's title);
- class pages use `created: __CREATED_CLASS_K__` (K = 1 for the first class
  of the year, in chronological order) — the installer spreads them across
  the semester as real, distinct weekday dates so the All Classes listing
  sorts newest-first; never give class pages the plain sentinel;
- class pages' links ARE the schedule: every shared page automatically
  inherits the date of the first class that links to it, so category
  listings sort in teaching order — a concept page no class links to keeps
  the install-time date instead;
- curriculum-dependent passages sit between `%%curriculum-start%%` and
  `%%curriculum-end%%` comment lines, so declining the curriculum pages
  removes them cleanly (inline `[[A2.2|words]]` links unlink automatically);
- expectation pages are verbatim Ministry text with a `^text` block anchor,
  generated once from researched wording — cite the source document on the
  payload's "About These Expectations" page.

Two more conventions, added since:

- course-level pages arrive with `createdSectionN`/`publishForSectionN` — one
  pair per section — because two sections are never quite in step. The
  payload keeps the plain sentinel; `install_payload_file` does the split,
  since a payload cannot know how many sections the teacher will choose,
  and the linter rejects per-section keys written by hand;
- `Key Links` ends with `[[What This Site Can Do]]`, so a teacher
  evaluating the software meets the site tour from the sidebar;
- chemistry is written with mhchem (`$\ce{H2O}$`), never built by hand out
  of `\text{}` — `build_site.py` enables the extension.

Adding a new course code is pure content: drop in a payload, no code
changes. The wizard (CLI and app) discovers it by the manifest's existence,
and the payload automatically retires that code's skeleton (below).

## Skeletons: what every other course code starts as

Eighteen codes have payloads. The other ~1,900 Ontario codes get a
**skeleton** from `support/skeletons/<family>/` — the same shape with
placeholder content: folders that suit the subject, four units of three
class pages, a landing page with Most Recent Class, `Key Links`, a site
tour, and a `Curriculum` folder explaining how to fill itself in.

- `support/skeletons/families.json` maps each three-letter course-code
  prefix to one of fifty families, with a generic fallback. `SkeletonCatalog`
  (app) and `find_skeleton_dir()` (Python) both read it.
- The skeletons are **generated, never hand-edited**:
  `.claude/skills/example-content/generate_skeletons.py` holds eleven shapes
  and the family table and writes ~2,000 pages. Change a shape, re-run it,
  and every family gets the fix.
- `lint_skeletons.py` is the gate — every link resolves, every page is
  titled, no template token survived, and the sidebar rule holds (curriculum
  hidden, every other shared folder expandable, per-section folders plain).
  A mistake here is a mistake in nineteen hundred courses.
- The sidebar rule is structural, not a list: see
  `SkeletonCatalog.sidebar(for:…)`, mirrored in the wizard's prompt defaults.
  A folder the teacher invents gets a chevron like any other.

## Colima is shared — handle with care

Colima on this machine is shared with other projects (e.g. Supabase local
dev). Never `colima stop` unless `docker ps -q` comes back empty — the app's
quit path and the scripts already enforce this; keep it that way. Also note
the Colima VM only mounts `$HOME`, so a working folder outside your home
directory bind-mounts as an empty folder inside the container.

## Testing

**Toolchain changes** (launchers, `scripts/`, Dockerfile, patches): run
`./verify.sh` — it builds a fresh `quartz-teacher:dev-test` image from the
working tree, checks the baked files match, and drives the real launchers
against it. This is the gate before committing toolchain changes. It needs a
TTY (`docker exec -it`); from a non-interactive shell wrap it:

```bash
script -q /dev/null ./verify.sh
```

> ⚠️ **`verify.sh` does not run on a Windows development machine.** It is
> bash and expects `docker` on `PATH`; in the normal Windows setup Docker
> Engine lives inside WSL2 and neither holds. Toolchain changes made on
> Windows therefore have **no automated gate** — verify them by driving a
> real publish (or preview) through the app end to end, and re-run
> `verify.sh` from the mac after the next sync. Worth knowing before
> assuming a green Windows test run means the toolchain is covered: the
> xUnit suite deliberately never touches Docker.

**App changes (Windows)**: the xUnit suite is fast and needs no Docker:

```powershell
cd windows-app
dotnet test Plantoir.Tests/Plantoir.Tests.csproj
```

**Tests touching process-wide state must not run in parallel.** Preview
leases and the publish registry are statics, and xUnit runs test *classes*
in parallel by default — so any class touching them belongs in the shared
serialized collection (`SharedActivityState` in `ModelTests.cs`). Skipping
that produces an intermittent failure that looks exactly like a production
bug and is not one; it cost a real debugging session to trace.

**App changes (macOS)**: the unit suite is fast and needs no Docker:

```bash
cd mac-app
xcodebuild -project Plantoir.xcodeproj -scheme Plantoir \
  -configuration Debug test -only-testing:QuartzTeachersTests
```

See [`mac-app/README.md`](mac-app/README.md) for the other layers
(in-process UI walk-through, CLI-equivalence integration tests, XCUITest)
and the environment each needs. Stop any Xcode-debugged copy of the app
before running UI tests — the test runner can't terminate it.

## Conventions

- **The GUI never mentions the machinery.** No "toolchain", "script",
  "Docker", or "container" in user-facing text — plain words only
  ("Building your website builder…", "Getting this Mac ready…"). That
  includes the assistant's own plumbing: no model names, parameter counts,
  tokens, context windows or GPU talk. It says "the small assistant" and
  "the larger assistant", and a test enforces it.
- **Every macOS improvement is written up for Windows, as you go.** The
  Windows app is built from what this side learns, by somebody who cannot
  read the Swift or watch it being tested, so a change that exists only in
  Swift is one they will re-derive from scratch — usually after shipping the
  same bug once. A change is not finished until:
  - **`GUI-IMPROVEMENTS.md` has an entry whose "Notes for Windows port"
    column says something usable** — what to do differently, what is
    inherited unchanged, or the trap that would pass review. "Shared Python,
    nothing to mirror" is fine when true; an empty cell never is.
  - **anything architectural also has a section in
    [`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md)**. A log row records a
    decision; the handoff explains it well enough to implement.
  - **guidance the change made WRONG is corrected there too.** Stale advice
    is worse than none, because it gets followed.

  Say what you measured, not just what you decided — numbers travel, taste
  does not. And write down the **reasoning**, not only the behaviour: a
  behaviour can be read off the code, the reason for it cannot, and a rule
  whose reason has been lost gets "simplified" back out by the next person
  who reads it. Record the options REJECTED and why, too — otherwise they
  get proposed again and cost the same afternoon twice. This applies to
  decisions reached by discussion as much as by code, and it is not
  contingent on being asked for it.
- **Launchers are snapshots.** Working folders copy the launchers at setup;
  the app refreshes any that differ from its bundled copies whenever it
  works in a folder. If you change a launcher, the fix reaches folders
  through the app bundle — rebuild the app to test it end to end.
- Swift code follows the style rules in the project instructions: no
  `map`/`filter`/`reduce`, `@Observable` (never `ObservableObject`),
  `// MARK: -` sections, clarity over concision.

## Documentation map

- [`documentation/`](documentation/README.md) — how the toolchain works,
  numbered 01–09 (overview, image, launchers, course setup, build pipeline,
  Quartz customizations, deployment, config reference, mac app).
- [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md) — the GUI behaviour log and
  Windows-porting spec.
- [`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md) — start here to build the
  Windows app: architecture, config contract, and platform notes.
- [`MAC-HANDOFF.md`](MAC-HANDOFF.md) — the mirror image: work that
  originated on Windows (or in shared `scripts/`) and needs the mac's
  attention. **Read it when syncing the two sides**; entries are removed
  once the mac has picked them up.
- [`WINDOWS-TESTING.md`](WINDOWS-TESTING.md) — the WSL2 container-runtime
  background and original test plan for the PowerShell launchers. They are
  now well tested on real Windows; read it for *why* they look as they do.
- [`mac-app/README.md`](mac-app/README.md) — building and testing the app,
  design notes.
- [`windows-app/PROGRESS.md`](windows-app/PROGRESS.md) — the Windows app's
  layout and current state;
  [`windows-app/RELEASING.md`](windows-app/RELEASING.md) and
  [`RELEASE-CHEATSHEET.md`](RELEASE-CHEATSHEET.md) — cutting a release
  (signing, bundling, the frozen asset names both platforms depend on).
- [`TODO.md`](TODO.md) — deferred work and ideas, with the research
  already done so picking one up is cheap.
- [`MCP-PROPOSAL.md`](MCP-PROPOSAL.md) — the original design for driving
  Plantoir from an AI assistant over MCP. Phase 1 of it is now built on the
  `ai-assist` branch; the Phase 0 question (one shared .NET binary, or a
  Swift implementation of the same contract?) still awaits a mac-side
  opinion.
- [`AI-ASSIST.md`](AI-ASSIST.md) — **on the `ai-assist` branch.** Whether a
  small offline model embedded in the toolchain image could drive Plantoir
  for a teacher with no AI account: measured memory, speed and reliability,
  the failures that shape the design, and what was not tested.
  [`windows-app/Plantoir.Mcp/README.md`](windows-app/Plantoir.Mcp/README.md)
  is the server that came out of it. Neither is on `main` or in 1.0.
