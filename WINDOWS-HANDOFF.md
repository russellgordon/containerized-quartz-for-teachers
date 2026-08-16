# Windows App — Handoff

Read this first when working on the Windows app — `windows-app/`, WinUI 3,
first take built 2026-08-11 — and especially when syncing it after a run of
macOS-side sessions. It gathers everything a Windows implementation needs; the
deep dives it links to are kept current. For what is already covered, see
`GUI-IMPROVEMENTS.md`'s **Windows status** section rather than working through
this file top to bottom.

## What you are building

A native Windows app wrapping the same toolchain the macOS app wraps. The
toolchain itself is **shared and already done**: the Docker image recipe
(`Dockerfile`, `patches/`, `scripts/`, `support/`), the Python that runs
inside the container, and the PowerShell launchers (`setup.ps1`,
`preview.ps1`, `deploy.ps1`) all live in this repository. The Windows app's
job is the interface: the same behaviours as the macOS app, driving the
`.ps1` launchers instead of the `.sh` ones.

**The specification is [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md)** — every
numbered entry describes a behaviour the macOS app has, and every one carries
a Windows-porting note. Work through it top to bottom; it is the product of a
great deal of live testing and each entry earned its place.

**This file is kept current as the macOS side changes**, rather than written
once. The macOS working rule is that a change is not finished until its log
entry has a usable Windows note, anything architectural has a section here,
and any guidance the change made WRONG has been corrected. So if something
here contradicts what you find in the repository, the repository is right and
this file has a bug — say so, because that is a defect on the macOS side, not
a judgement call on yours.

## The three load-bearing rules

1. **The GUI never mentions the machinery.** No "toolchain", "script",
   "Docker", "container", or "WSL" in user-facing text. Plain words:
   "Building your website builder…", "Getting this Mac ready…" (yours will
   say "this PC"). **The visible verbs are now BOTH, and they mean different
   things** (entries 140 and 143, reversing entry 103): a PAGE is
   *published* — the `publish:` frontmatter flag deciding whether students
   see it — and the SITE is *deployed* to Netlify, Cloudflare or a folder.
   One word for both makes "I published tomorrow's class" mean a flag to one
   person and a live site to another. Internal names, script file names and
   config keys keep "deploy" throughout.
2. **Use the script logic itself as much as possible.** The app runs the
   real launchers and answers their real prompts; it does not reimplement
   them. Progress comes from parsing their output (milestone markers,
   `#N [k/n]` build steps, "N of M" upload counts, the announced preview
   address).
3. **Free resources whenever possible.** Close a folder's last window →
   stop that folder's container. Quit the app → stop the engine only if
   nothing else is using it.

## Architecture the app must reproduce

- **Working folders**: a folder holding `courses/`, the three launchers,
  and `.toolchain/` (the full image recipe, mirrored there by the app from
  its own bundled copy — refresh any launcher/recipe file that differs
  whenever the app works in a folder).
- **Local image builds, no registry**: the launchers hash the recipe
  (every file in the build context, pruning `.git`, `courses`, `mac-app`,
  `node_modules`, `.merged_output`) and tag `teaching-quartz:src-<hash8>`.
  A changed recipe → new tag → rebuild → recreated container. The `.ps1`
  launchers already implement this (`Get-ToolchainHash`).
- **One container per working folder**: named
  `teaching-quartz-<first 8 hex of SHA-256 of the folder's physical path + newline>`.
  The app must derive the identical name the launcher derives — beware
  path canonicalization differences (macOS needed POSIX `realpath`; check
  what PowerShell's `pwd -P` equivalent emits on Windows).
- **Port blocks**: each container publishes a probed host block
  (bases 8081, 8091, 8101, 8111, 8121, 8131): base..base+3 → container
  8081–8084 (four concurrent previews per folder) and base+1000..+1003 →
  9081–9084 (Quartz's live-reload websockets). The app leases ports per
  folder (`PreviewLeases` in the macOS app), parses the announced
  "Preview will be available at:" address rather than assuming it, and
  refuses a duplicate preview of the same section in the same folder.
- **Course activity registry** (entry 104): one cross-window record of
  which courses are previewing (the port leases already know) or
  publishing (begin/end records around the publish flow, ended on EVERY
  exit path). "Add Section…" declines while its course is active, with a
  short line naming the blocker ("Available once preview completed").
  Staleness lesson: read the enabled state when the menu OPENS, or make
  registry changes re-render whatever hosts the menu — a state captured
  at an earlier render shows yesterday's answer.
- **Stopping a preview reclaims the container side** (entry 105): killing
  the host-side launcher orphans the build or server INSIDE the
  container (an orphaned build burns real CPU). `preview.ps1 CODE N
  --stop` kills that section's container-side processes (found by
  working directory, so other sections are safe) and never starts
  anything. Call it fire-and-forget — output discarded — wherever a
  preview ends: stop button, navigating away, window close.
- **Backups and archives** (entry 106): three zip kinds share
  `courses/_backups/<CODE>/`, told apart ONLY by name —
  `<CODE>_backup_<timestamp>.zip` (teacher-made backups),
  `<CODE>_<timestamp>.zip` / `<CODE>-sectionN_<timestamp>.zip`
  (archives from removals), `<timestamp>.zip` (the wizard's automatic
  zips, never listed). Backups get their own sidebar group above
  Archived. Restoring a backup archives the current course FIRST, then
  replaces the course folder's CONTENTS in place — never the folder
  itself (see the Obsidian note below) — and keeps the zip. Deleting a
  backup or an archive is the app's only true deletion; the archive
  confirmation states a FACT about what remains (live course / other
  copies / only remaining copy — a whole-course archive covers a
  section archive, never the reverse).
- **Container engine**: Docker Engine in WSL2. The macOS zero-prerequisite
  bootstrap (static Colima/Lima/docker/buildx downloads into the app's own
  Application Support folder) needs a Windows analogue — silent WSL2 +
  engine setup, per entry 72's note. Stop-at-quit analogue:
  `wsl --terminate` only when nothing else runs in the distro.
- **BuildKit is mandatory** — the legacy builder corrupts a layer.

## Config is the contract

`course_config.json` is shared between the app, the wizard, and the build.
See [`documentation/08-course-config-reference.md`](documentation/08-course-config-reference.md).
Keys the Windows settings UI must round-trip (per-section maps use
`{"sections": {"sectionN": value}}`):

- `course_code`, `course_name`, `locale`, `section_numbers`, `num_sections`
- `emojis.sections` — header emoji per section (system emoji panel: Win+.)
- `color_schemes` — flat map sectionN → scheme id (`support/colour_schemes.json`)
- `fonts.sections` — header/body/code display names (files in `support/fonts/`,
  name → file by stripping spaces; "Helvetica, Arial" means system default)
- `show_section_marker.sections` — the "S1" in the site header
- `show_grade_in_title.sections` — grade prefix on the landing title
  (legacy: a single course-wide bool; honour it). LITERAL behaviour: the
  switch alone decides; the UI shows an orange warning when the course
  name already contains the grade label, and the teacher resolves it.
- `custom_domains.sections` — the app swaps published-site links' host to
  this domain (path kept, https); entries are normalized (scheme and path
  stripped) on the way in
- `shared_folders`, `shared_files`, `per_section_folders`,
  `per_section_files`, `hidden`, `expandable`, `expandOnFolderClick`,
  `show_reading_time`, `footer_html`
- `deploy_target` ("netlify" default | "cloudflare_pages" | "local_folder") and
  `deploy_folder_path` (entries 101–102) — folder deploys pass
  `--to-folder <path>` to the launcher, which robocopy-mirrors each
  section into `<path>\sectionN`; completion is announced by a
  `PUBLISHED_FOLDER=` line the app turns into a Show-in-Explorer button.
  The Publishing choice appears in BOTH the settings form and the
  new-course wizard (share the control); an empty, missing, or
  unwritable folder blocks save/create with an inline message and is
  checked the moment a folder is chosen; folder-mode progress labels
  never mention Netlify; and the completion adds a note that the pages
  only render properly once uploaded to a web host
- `prepopulate_example_content`, `include_curriculum_pages` (entries
  92–93) — written by the new-course wizard, read by the shared Python
  wizard as its defaults; both forced false when no example content
  exists for the course code
- `use_lcs_terminology` (entry 94) — whether the factory structure
  defaults use LCS's own set-up; the two factory sets live as
  `DEFAULT_*` vs `LCS_*` constants in `scripts/setup_course.py` and the
  Windows equivalent of `WizardDefaults` must mirror them exactly
- `custom_short_name` — the ≤12-character label shown beside the header
  emoji instead of the course code, in club mode. Already implemented on
  Windows (`CourseConfiguration.cs`); listed here because this table is the
  contract and it was missing from it
- `include_curriculum_coverage` and `include_coverage_notes` (entries 125,
  130) — whether the generated `Curriculum Coverage` map page is produced, and
  whether it carries its explanatory sections or the map alone. Read by
  `build_site.py`, both defaulting true. **Not yet implemented on Windows**:
  neither key appears anywhere in `windows-app/`, so a teacher who turns the
  map off on a Mac and opens the same course on Windows can silently have it
  turned back on by a settings save
- **Edit keys in place and preserve unknown keys** — the macOS app keeps
  the decoded JSON as a dictionary precisely so future toolchain keys
  survive a settings round-trip. The shared Python wizard does the same in
  the other direction: it copies through every key it does not own, which is
  what lets an app-written setting survive a wizard re-run.

## Example content (entries 92–96)

Ready-made course payloads ship in `support/example_content/<CODE>/` — 37 of
them as of 2026-08-15 and growing, so read the directory rather than any list
written here; detection is by the presence of `manifest.json`, which is what
the code does anyway. (SNC1W is the example course's content converted to
payload form, so a teacher actually teaching Grade 9 science gets it as
starting content; SNC2D is its Grade 10 sequel, and SCH3U/SCH4U carry
chemistry through Grades 11 and 12.) All
the installing, date logic, and curriculum handling is shared Python —
Windows needs exactly three UI behaviours:

- **Detection**: example content exists for a code when the bundled
  `support/example_content/<CODE>/manifest.json` exists; the curriculum
  toggle additionally needs the manifest's `curriculum_folder` to be
  non-empty (reference logic: `ExampleContentCatalog.swift`).
- **Starting Content section** in the new-course wizard: "Pre-populate
  course with example content" (default ON) with "Include Ontario
  curriculum pages" beneath it (default ON, disabled when the first is
  off). When no content exists for the code, this is where the SKELETON
  toggle goes instead (entry 123) — "Start from a <subject> skeleton" —
  and the quiet "empty folders" caption is now the last resort, for a code
  with neither.
- **Structure lock**: when pre-populating, HIDE the folders/files
  editor behind a caption — the payload's manifest is the entire
  structure authority and the Python wizard skips all structure
  prompts.

Authoring new payloads is content work, governed by the repo-local
skill `.claude/skills/example-content/` and checked by its
`lint_payload.py` — no app code changes on either platform. The same skill
holds the skeleton generator and `lint_skeletons.py`; the skeletons are
generated output, so never hand-edit `support/skeletons/`.

Two payload conventions have changed since these entries, both handled by
shared Python: course-level pages now arrive with
`createdSectionN`/`publishForSectionN` (one pair per section — entry 122), and
`Key Links` ends with the site tour (entry 121).

## Behaviours with platform-specific mechanics

- **Obsidian integration** (entry 80): `obsidian://open?path=…` only works
  for vaults REGISTERED in Obsidian's registry — on Windows,
  `%APPDATA%/obsidian/obsidian.json`, same JSON shape. Port the whole
  dance: quit Obsidian if running (its in-memory vault list ignores
  registry edits), seed `support/obsidian_defaults/.obsidian` if the
  course has none, write the registry entry, then open the URI. Sections
  open at their `index.md` (Obsidian opens files, not folders). Enable
  the File Explorer's auto-reveal by patching the vault's
  `workspace.json` whenever Obsidian is closed (a pre-seeded layout is
  discarded on a vault's first open — verified). One more watcher
  lesson (entry 106): Obsidian's file watcher is anchored to the vault
  FOLDER's identity — replace the folder and an open vault shows stale
  files until reopened; replace only its contents and Obsidian
  refreshes itself. Any feature that rewrites a course wholesale (like
  restoring a backup) must swap contents, never the folder.
- **Window restoration** (entries 64–65, 98–99, 106): keep per-window
  state in the app's own store, keyed by something the platform restores
  faithfully. Each entry now carries, beside the folder: the expanded
  course codes, whether the Archived and Backups groups are open, and
  the sidebar selection (`course|CODE`, `section|CODE|N`, `archived|ID`,
  `backup|ID`) — restore all of it when a window claims its entry. Two rules learned the hard
  way: resolve claims on the platform's restoration-complete signal
  rather than polling, and while a claim may still arrive show a quiet
  loading state, never the folder picker the claim is about to replace.
  The scenario test suite in the macOS app is the porting spec.
- **New windows** (entry 84): inherit the folder of the window that was
  key when the command ran; with no windows open, show the folder picker.
  Decide the folder BEFORE first paint or the picker flashes.
- **Updates**: WinSparkle, with its own feed at `site/appcast-windows.xml`
  alongside the mac's `site/appcast-macos.xml` — **per-platform file names from
  the start**, so the two update feeds can never collide. (An earlier draft of
  this line said the two would share one appcast; that is exactly the collision
  the mac side asked to avoid. Deferred on both platforms until the first
  release.)
- **Stable code signing** (entry from the signing fix): sign dev builds
  with a stable identity or Windows will re-prompt for permissions —
  same class of problem as macOS ad-hoc signing.
- **Social cards** (entry 88): nothing to do — `scripts/social_card.py`
  runs inside the container on every build. Only caveat: the colour-emoji
  font path probed is Debian's; it is inside the image, not on Windows.
- **The recipe hash is on the hot path** (entry 118) — and it was slow
  on BOTH platforms, for the same reason in two dialects. The image tag
  is a SHA-256 over every file in `.toolchain/`, and the recipe carries
  the eighteen example-content payloads and the fifty subject skeletons:
  **11,378 files** as of 2026-08-15, and still growing — it was 5,694 two days
  earlier, which is the rate that makes this matter. The `.sh`
  launchers spawned one `shasum` process per file (36s of a 36.75s
  preview startup on an M4 Pro); they now pipe
  `find -print0 | sort -z | xargs -0 shasum` and take 0.16s.
  `Get-ToolchainHash` in the three `.ps1` launchers had the quadratic
  version of the same bug: `$combined += (Get-FileHash …).Hash` inside
  the loop, and PowerShell strings are immutable, so every one of those
  thousands of appends reallocated a string heading for a third of a
  megabyte. They now collect into `$hashes` and `-join` once. Measure this
  when you test: on macOS the batched version hashed 5,694 files in 0.25s,
  so anything near a second on Windows means the fix did not take.
  **This change is committed but never executed — there is no PowerShell
  on the Mac it was written on.** Please run it early and confirm two
  things: that a preview still starts promptly, and that the tag it
  prints is UNCHANGED from before the edit. The characters and their
  order are meant to be identical, so the tag should be too; if it is
  not, every Windows teacher takes one needless image rebuild.
  Whatever else changes here, keep any per-file work out of a
  per-invocation loop — this cost half a minute before every preview and
  publish, and it grows with each payload added.

## Fixed in shared code — nothing to port (entries 111–121)

A run of rendering and content defects was found and fixed on the macOS
side. All of it lives in shared Python or in the payloads, so Windows
inherits it by rebuilding the image. Listed so you are not surprised by
diffs, and so nobody re-fixes them:

- **Mermaid diagram labels were hyphenated mid-word** ("Ca-reers"). Not
  an engine bug: Quartz hyphenates body text and it leaked into diagram
  labels. WebKit acts on it, Chromium ignores it — which is why the same
  site looked right in Chrome and wrong in a preview.
- **Mermaid measured labels before the code font loaded**, sizing every
  box for the fallback so long labels were clipped. It now waits for
  `document.fonts.ready` first. Google Fonts serves the code font with
  `display=swap`, so this is a real race on any platform.
- **Pie chart titles were clipped** — mermaid centres the title on the
  pie, which the legend pushes leftward, and never widens the chart. The
  viewBox is now re-fitted to what was drawn.
- **A pie chart's first slice was drawn in the page background colour**
  and vanished, legend swatch and all: mermaid takes `pie1` from
  `primaryColor`, which Quartz sets to `--light`. The palette is now
  solved per colour scheme at render time, and it must stay that way —
  fractions tuned against one scheme failed 74 of the 86
  scheme-and-mode combinations.
- **The right sidebar's backlinks crowded out the table of contents** on
  much-linked pages. They now share the column, each with its own
  scrollbar.
- **Payload rules now enforced by `lint_payload.py`**: class pages carry
  no curriculum connection (those codes belong on the pages the agenda
  links to), and no page stands on its own — every page must be reachable
  from a class page within two hops, with Key Links not counting. Both
  are in the example-content skill.
- **Chemistry is typeset with mhchem.** `build_site.py` adds
  `import "katex/contrib/mhchem"` to `latex.ts`, so `$\ce{CaCO3(s) <=>
  CaO(s) + CO2(g)}$` renders properly. The three chemistry payloads were
  converted outright — 1,533 spans — and the skill now forbids formulae
  built by hand out of `\text{}`.
- **`What This Site Can Do` is the LAST entry of every payload's
  `Key Links`**, so a teacher evaluating the app meets the site tour from
  the sidebar. Enforced by the linter.
- **Per-section publishing in the installer**: a course-level page now
  arrives with `createdSectionN` / `publishForSectionN` for each section the
  teacher chose, rather than one shared pair. Payloads keep the plain
  sentinel — the split happens at install time, because a payload cannot
  know the section count.

## Two things that DO need porting (entries 122–123)

**1. Subject skeletons in the New Course dialog (entry 123).** Every
Ontario course code that has no example content now starts from a skeleton
shaped for its subject — 50 families over 499 three-letter prefixes, living
in `support/skeletons/` with a `families.json` prefix map. The installer
side is shared Python and comes free, so a course created through the CLI
wizard already gets it. The dialog needs the macOS `SkeletonCatalog`
equivalent: read `families.json`, map the code's first three letters to a
family (falling back to `default`), read that family's `manifest.json`, and
seed the four structure lists from it when the code changes. Show a toggle
naming the subject ("Start from a music skeleton"), and write
`use_skeleton` into `course_config.json` so the wizard's own prompt agrees.
Three rules matter: a code WITH example content is never offered a
skeleton; a folder list the teacher has edited is never overwritten; and
the sidebar is decided structurally rather than by a fixed list — hidden is
`Media` plus the family's own `hidden` entries that the course actually
has, and expandable is every shared folder that is not hidden, so a folder
the teacher invents gets a chevron like any other. Per-section folders
(All Classes) are never expandable. macOS decides all three in two pure
functions, `SkeletonCatalog.structureToAdopt` and `SkeletonCatalog.sidebar`
— those are the pieces worth copying.

**2. Adding a section must extend the course-level pages (entry 122).** The section
folder is only half the job: every page at the course level — the shared
folders and files, everything outside `sectionN/` — carries a
`createdSectionN` / `publishForSectionN` pair per section, and a section added
later needs its own pair or it builds those pages with no date and no
publishing state at all. macOS does this in
`SectionAdder.extendCourseLevelPages`: walk the course folder skipping the
`sectionN` directories, and for each markdown page whose FRONTMATTER
already uses the per-section form, append a fresh
`createdSection<new>` plus a `publishForSection<new>` copied from the
lowest-numbered existing section. Leave pages with a plain `created:`
alone — they already apply to every section — and never read past the
frontmatter, because the site-tour page shows `publish: false` inside a code
block as documentation.

> **The key changed name AND polarity (entries 140/141), so an implementation
> written against the older text of this section would be wrong twice.** The
> flag is `publish:` / `publishForSection<N>:`, and `draft: true` ≡
> `publish: false`. The legacy `draft` spellings are still READ — a course
> nobody has touched behaves exactly as it did — but they are **never
> written**. Read new-then-legacy-inverted, write new only:
> `PageFrontmatter.PublishKeyFor` on the Windows side,
> `SectionAdder.swift` on the mac's.

## The local assistant: run the model natively, not in a container

> **DECIDED, 2026-08-15: Windows should move its model out of the container
> too.** What follows was written as a recommendation with measurements behind
> it; the mac has since shipped the native arrangement, it works well, and the
> Swift implementation is now the reference for how the assistant should be
> built. This is no longer "worth measuring before committing to" — it is the
> direction. Measure your own hardware to size the tiers, not to decide whether
> to move.

**Measured on macOS 2026-08-15, and the numbers are large enough that they are
worth acting on rather than filing.** The feasibility work
(`research/ai-assist/HISTORY.md`, part 2 §2) records the Windows engine's
constraints — 4 GB, 2 cores, no GPU, ~21 tokens/second — and
observes that "21 tokens/second is the number that governs everything." It
does govern everything. It is also an artefact of running the model inside a
container, not a property of the hardware.

The macOS build runs the same model (Qwen2.5-1.5B-Instruct Q4_K_M, byte for
byte the same 1,117,320,736-byte file) natively, with Metal. Same prompt, the
same 3,411-token tool surface:

| | Docker-in-WSL2, 2 cores, no GPU | Native, Metal (M4 Pro) |
|---|---|---|
| Cold prompt read (3,411 tokens) | **175–179 s** | **2.1 s** |
| Generation | **5.5 tok/s** in the assist loop | **158 tok/s** |
| A ~50-token tool call | ~9 s | ~0.3 s |

Two consequences worth having:

1. **The three-minute wait is not inherent.** It is the cost of reading the
   tool definitions on two virtual CPU cores. Given a GPU it is seconds.
2. **The whole disk-cache save/restore mechanism becomes unnecessary.** §10.1
   calls it "the biggest win available" and it is — when the thing being
   avoided costs 175 seconds. When it costs two, the machinery (per-course and
   per-section cache files, tool-schema fingerprints in the file name, an
   empty-save that silently poisons the next session) is more failure surface
   than it is worth. The macOS build does not have it. It warms the prefix in
   the background when the window opens instead, which is a dozen lines.

**Windows can almost certainly have this too.** llama.cpp publishes native
Windows builds beside the macOS one in the same release — as of `b10435`,
`llama-<build>-bin-win-cuda-13.4-arm64.zip`, `win-cpu-arm64`, and Vulkan
builds for AMD and Intel GPUs. Running `llama-server.exe` on the host, out of
WSL2 entirely, should collapse the same two numbers. The rest of the design
does not care where the server is: it is the same OpenAI-shaped HTTP endpoint
either way, so `LocalModel` should need little more than a different way of
starting the process.

A machine with no usable GPU falls back to CPU and lands somewhere between the
two columns; that is worth knowing rather than assuming, and it is what decides
the tier ladder on Windows. But the container is not buying anything here that
a host process does not, and it is costing three minutes.

### The requirement: pick whatever makes it FASTEST on Windows

Stated plainly by the maintainer, 2026-08-16, and it is a requirement rather
than a preference: **choose the design that gives the fastest possible
performance on Windows.** The mac's answer was to take the model out of Colima
and run it on Metal. Yours will not be Metal — it should be whatever Windows
offers that wins, and the only way to know which that is is to measure on real
teacher-grade hardware.

**Why this is worth an afternoon of measurement rather than a default.** The
container costs more than it looks. Same model, same 3,411-token prompt, on an
M4 Pro: **175 seconds inside Colima against 2.1 seconds natively** — 5.5
tokens/second against 158. That is not a tuning difference, it is the
difference between a feature a teacher uses and one they close the window on.
A Linux VM has no access to the host's GPU; the same will be true of yours.

**The candidates, in the order worth trying.** llama.cpp publishes Windows
builds for all of these in the same release as the macOS one, and the server
speaks the same OpenAI-shaped HTTP either way, so `LocalModel` should need
little more than a different way of starting the process:

| Backend | Where it wins | What to check |
|---|---|---|
| **CUDA** | An NVIDIA GPU, which many teacher laptops with discrete graphics have | Needs the right driver; the build is large. Fastest by a distance when present. |
| **Vulkan** | Broadest coverage — AMD, Intel Arc, and NVIDIA without CUDA | The pragmatic default if you ship ONE build. Measure it against CPU on integrated graphics before assuming it wins. |
| **DirectML / ONNX Runtime** | A Windows-native path across vendors | A different runtime and a different model format — only worth it if it measurably beats Vulkan on the machines teachers actually have. |
| **CPU** | The floor, and the fallback that must always work | Measure it. On a modern laptop with a 1.5B model at short context it may be perfectly usable, and it is the only path with no driver story. |

**Do not ship a backend you have not measured on integrated graphics.** The
teacher this feature is for is more likely to have an Intel iGPU than a 4090,
and a design that is fast on the developer's machine and unusable on theirs is
worse than one that is merely adequate everywhere.

**Two rungs, chosen from the hardware — same as the mac.** `app-rules.json` →
`modelTiers` carries the requirements: a smaller assistant and a larger one,
the rung picked by reading the machine rather than by asking the teacher, and
the interface saying only "the small assistant" and "the larger assistant".
The mac's own thresholds (under 16 GB / 16 GB and up) and its models are in
that file marked **macReference — do not copy**. Yours depend on what your
backend needs resident, and on a GPU there is VRAM to account for as well as
system memory, which the mac's unified memory does not have to separate.

**What must NOT change with the backend**, because these were measured and cost
days to find:

- **Zero polarity inversions is a veto**, not a tiebreaker. Two 3B-class models
  were rejected on it alone. Re-run the routing suite whenever the model, the
  quant or the context size changes — a faster model that publishes a page the
  teacher asked to hide is not faster, it is broken.
- **Thinking off takes TWO flags** if you follow the mac to Qwen3
  (`--reasoning off` AND `--reasoning-budget 0`). See the section below; it is
  a 97%-to-39% difference and it looks fine while being wrong.
- **The teacher never learns the model's name.** A faster backend does not buy
  a licence to say "CUDA" or "Qwen" in the interface.

When you have measured, write the numbers into `MAC-HANDOFF.md` — tokens per
second per backend, on named hardware. The mac side has no way to find out what
a Windows teacher's machine does, and those numbers are the only thing that
makes the next decision on either side a measurement rather than a guess.

### What moving out of the container changes, beyond the speed

Six things the mac learned the hard way, each of which applies the moment the
server is a host process:

1. **`--no-mmap` stops being required, and should go.** It exists because
   llama.cpp memory-maps the model and, inside a memory-capped container, the
   page cache for that file counts against the cgroup limit — a 3B model
   appeared to need 4 GB and died at 3 GB with no OOM message. There is no
   cgroup on the host. macOS passes no such flag.
2. **The prompt-cache save/restore machinery can be deleted**, as above: it
   buys 175 seconds in a container and two seconds outside one, and it carries
   real failure surface (an empty save silently poisons the next session).
   Warm the prefix in the background when the window opens instead.
3. **The model file moves to the host** — one file per machine, in the app's
   own data directory, surviving app updates — and you get to verify the
   download by exact byte count, which is worth doing: a captive portal or a
   proxy answers 200 with something that is not a model, and the resulting
   failure surfaces much later and looks like anything but a bad download.
4. **A second executable ships**, and it must be signed with the rest — the
   same lesson `plantoir-mcp.exe` already taught, since an unsigned binary
   beside signed ones is what SmartScreen objects to. Pin the llama.cpp build
   number the way the mac does (`b10435`), because an engine that changes under
   you between two builds makes every measurement meaningless.
5. **Which backend is a real choice, not a detail.** llama.cpp publishes CUDA,
   Vulkan and CPU builds for Windows. The mac has one answer (Metal, every
   layer, `--n-gpu-layers 999`); Windows has to decide what a teacher's Dell
   with integrated graphics actually gets, and whether you ship more than one
   backend or one that degrades. That is the measurement worth running.
6. **If Windows follows the mac to Qwen3, the reasoning flags become
   load-bearing.** `LocalModel` passes neither `--reasoning` nor
   `--reasoning-budget` today, which is CORRECT for Qwen2.5 (no thinking
   template) and would become a 97%-to-39% bug the day the model changes. Two
   flags, `--reasoning off` **and** `--reasoning-budget 0`; the per-request
   equivalent is `chat_template_kwargs {"enable_thinking": false}`. Confirm
   `--reasoning` exists in your build's `--help` — it is newer than the budget
   flag — and check the completion-token count and the clock, not whether a
   tool call came back.

The Swift implementation is the reference for all of this:
`mac-app/QuartzTeachers/Models/Assist/AssistServerHost.swift` (starting and
health-checking the process, and the flag list with its reasons),
`AssistModelTier.swift` (the ladder, the vetoes, and how the tier is chosen
from physical memory), and `AssistModelStore.swift` (download, verification,
where the weights live).

### One assistant at a time, machine-wide

The downloaded model is shared — **one file per machine**, in Application
Support, whatever course or section is being worked on, and it survives app
updates. What is NOT shared is the RUNNING copy: each assistant window starts
its own engine and loads the weights again. Two windows is twice the resident
memory, which on a 16 GB machine is most of it and undoes the point of sizing
the model to the hardware.

So the macOS build allows exactly one assistant window at a time, across the
whole app. The menu item for every other section is **dimmed, with a line
saying which section to close** — "Close the assistant for ICS3U Section 1
first". Dimmed alone tells somebody they cannot do the thing; naming the
holder tells them what to do about it.

Three details worth copying rather than re-deriving:

- **Claim when the WINDOW opens, not when the engine is ready.** A teacher
  three minutes into a 2.5 GB download has the assistant open as far as they
  are concerned, and a second window started meanwhile is exactly what this
  prevents.
- **Release unconditionally on close.** A claim that leaks locks the feature
  out until the app restarts, which is a far worse failure than briefly
  allowing a second window. For the same reason a NEWER claim replaces a
  stale one rather than being refused.
- **The section that already holds it stays enabled**, because choosing it
  brings the existing window forward — which is what a teacher expects from
  a menu item naming a window they can see.

Read the registry during the row's RENDER, not inside the button's closure,
or the menu shows the answer from whenever the row last drew. That is the
same staleness trap `CourseActivity` documents for "Add Section…".

**This governs the built-in assistant only.** Claude Code driving the same
tools over MCP has no engine of its own, so nothing about it multiplies
memory and nothing about it should be blocked.

### Your two findings, re-measured natively — one held, one did not

Both were re-run on macOS against the same suite (3B, 3 trials, results in
`research/ai-assist/macos-native-results.txt`):

- **The date must be appended, not prepended: HELD.** Prepending cost 13–14
  points, against the 15 you measured. Treat this as a property of the model.
- **Rewriting the schema examples to the real course: DID NOT reproduce.** You
  saw `ICS3U` copied out of the examples 9 times out of 9; natively, the 3B
  copied it **0 times in 87 responses** with `ICS3U` still present in 14 places
  in the schema, and accuracy barely moved. **This is not grounds to remove the
  rewriting** — your finding was earned on the 1.5B, which is a different model
  from the one that failed to reproduce it, and the macOS build keeps the
  rewriting for exactly that reason. It is grounds to re-test it on whichever
  model you actually ship.

### And one finding of our own, which matters more than either

**Do not assume a bigger model is a safer one.** Qwen2.5 **3B inverts
polarity**: asked to hide a page it called `publish_pages`, in two of three
trials, and answered three separate hide requests with `undo_last_change`. That
is the one genuinely dangerous failure — the reason publish and unpublish are
separate verbs rather than one tool with a boolean — and the 3B also scored
BELOW the 1.5B on the like-for-like probe set (70% against 81%).

Be precise about WHY it is the dangerous one, because the obvious reason is
wrong and stating it wrongly will lead somebody to weigh it against a score.
A wrong publish does not put anything in front of students: **publishing marks
a page for inclusion, deploying is the separate act that reaches them**, and
undo takes a publish back. The veto is that an inversion is the only failure
that does not announce itself. Every other misroute runs a visibly wrong tool;
this one reports success while leaving the section in the OPPOSITE state to
the one the teacher asked for — and the next deploy then carries that out
faithfully, days later, with nothing to prompt a second look. A model that
will do the opposite of what it was told is not one whose remaining 70% can
be trusted.

The macOS build has no 3B rung as a result; the case was deleted from the enum
rather than marked risky, on the same reasoning as having no delete tool. If
Windows ever offers a model choice, measure each candidate for inversions
specifically, and treat that as a veto rather than a score.

The table below was three trials per probe. It was re-run at **ten** trials on
macOS across ten models on 2026-08-15
(`research/ai-assist/macos-native-10-trial-comparison.txt`), and the veto got
stronger, not weaker:

| Model | Routing (like-for-like) | Inversions |
|---|---|---|
| Qwen2.5 1.5B | 79% | none |
| Qwen2.5 3B | 72% | **9 of 10** |
| **Llama-3.2 3B** | 72% | **10 of 10** |
| Qwen2.5 7B | 94% | none |
| **Qwen3 4B (reasoning off)** | **100%** | **none** |

Two things in that table matter more than the numbers. First, a **second,
unrelated family at the same size inverts on the same sentence** — 'Hide
tomorrow's class again … the page is "Ohm's Law"' — which says the failure
belongs to that generation of 3B models rather than to one vendor. Llama-3.2 3B
also typed `"section": "1"` as a string on essentially every call. Second, it is
**not** a size law: a 2025-era 4B is clean at 100%. So measure the model you
intend to ship; do not reason from parameter count in either direction.

What macOS ships today: **Qwen2.5 1.5B under 16 GB, Qwen3 4B at 16 GB and up**,
no 3B rung, and the 7B dropped because the 4B beat it on accuracy, latency,
download and memory at once. The 8 GB tier is a deliberate hold rather than a
result — Qwen3 4B at 8k context measures 3.87 GB resident, which is 48% of an
8 GB Mac that is also running a container, and that has not been tried on real
8 GB hardware.

### Turning thinking off takes TWO flags, and we shipped the wrong one

**Check this in your launcher before you read any further** — it is one word,
it costs half the assistant's response time, and it is invisible in review.

`llama-server` has two separate settings and only one of them stops the model
thinking:

```
--reasoning [on|off|auto]   whether the chat template thinks at all
                            (default: auto — decided by the template)
--reasoning-budget N        how long it may think once it has started
                            (0 = stop immediately, -1 = unrestricted)
```

The macOS app shipped for several days passing `--reasoning-budget 0` alone,
on the reasonable-sounding belief that a budget of zero meant no thinking. It
does not. Qwen3's template still opened a `<think>` block on every turn and
filled it to the cap. Measured on one prompt against the same tool surface,
same weights, same temperature:

| Flags | Time | Completion tokens | Tool call |
|---|---|---|---|
| `--reasoning-budget 0` | 16.1 s | **512** | correct |
| `--reasoning off` | 8.4 s | **44** | correct |
| both | 8.4 s | 44 | correct |

The useful reply is 44 tokens. The other 468 were thinking nobody sees. Half
the wait, for a flag.

**Why it survived review, which is the transferable part.** The budget flag
does not produce a wrong answer — it produces a slow one, and the two obvious
checks both come back green:

- *"Did a tool call come back?"* Yes. 512 tokens is enough to think AND still
  route correctly on a short prompt.
- *"Is there a `<think>` tag in `message.content`?"* No — because at the
  default `--reasoning-format`, llama.cpp PARSES the thinking out of the
  content into `reasoning_content`. Its absence from the content proves the
  parser ran, not that the model stayed quiet.

The honest check is **the completion-token count and the clock**, not the
text. A router that is thinking looks exactly like a router that is not, only
slower — and "slower" is precisely the complaint that started this whole
piece of work. If the 3-minute Windows wait has any of this in it, this is a
one-word fix.

The 39%-vs-97% figure quoted above is the same fault at its severe end: on a
longer prompt the budget is consumed BEFORE the model reaches the call, and
no tool call arrives at all. Sixteen seconds is the mild end.

We now pass **both**, and a test asserts both for every tier:

```
"--reasoning", "off",           // stops the template thinking at all
"--reasoning-budget", "0",      // catches a template that ignores the above
```

The budget stays deliberately. A future model whose template does not honour
`--reasoning` would otherwise regress silently — which is exactly how this
one shipped. Two caveats for your side: `--reasoning` is NEWER than
`--reasoning-budget`, so confirm it exists in your build's `--help` before
adding it (ours is b10435); and check the flag against your own engine rather
than trusting this table, because the behaviour is the template's, not the
model's.

## The assistant's division of labour — the rule everything else follows

**The model picks which Swift function to run, and fills in its arguments.
Nothing else.** Every rule about what an action MEANS lives in code. If you
take one thing from this file, take this: it is what makes a small local
model viable, and every problem worth having came from violating it.

The split is measured, not aesthetic. Across the same runs the model:

- **misrouted five of the eleven suggested phrasings in EVERY trial** — it is
  bad at choosing;
- produced **zero wrong courses, zero wrong dates, zero type errors, zero
  invented dates** — it is good at filling in.

So take the choosing away wherever it can be taken, keep the filling in.

Three consequences that follow, each of which cost something to learn:

1. **Tools are coarse.** Given `resolve_links`, `set_publish` and
   `publish_section` separately, and asked to publish tomorrow's class *and
   everything it links to*, the model chose `publish_section` 8 times out of
   8 — skipping the link resolution. Perfectly consistent, and wrong. One
   `publish_class_on` that resolves links itself: right 8 of 8.
2. **Fixed phrasings never reach the model.** The card's unambiguous shapes
   are matched in code. If you reword one, update the matcher too, or the
   shortcut silently stops firing and the phrasing quietly starts being
   routed instead — it will look correct and behave worse.
3. **Absence is the guardrail.** There is no delete tool, so "delete the
   Unit 1 folder" cannot be honoured however confidently it is asked. Not
   judgement — no route.

### Rules belong in the tool, never in an argument

`publish_pages` and `unpublish_pages` used to take an `includeLinked`
boolean with no default, so the MODEL decided. That is the same reasoning
this design exists to keep out of the model, and a boolean is the thing that
inverted polarity on the 3B. It is gone, and the rules are now code:

**Publishing always publishes the pages it links to.** Never publish a page
whose links lead somewhere students cannot see — that is the whole point.

**Unpublishing is NOT the mirror**, and this asymmetry is deliberate:

- unpublish the named page(s);
- also unpublish a linked page **only if that page is linked to ONLY by the
  page(s) being unpublished**. If anything else still links to it, it stays —
  otherwise you create the dead links the publish rule exists to prevent;
- **never** unpublish, whatever the link count: a folder's landing page
  (`index.md` — Concepts, Investigations…), any page in that section's **Key
  Links**, or any **Curriculum** page (detect with `build_site.py`'s own
  rule: any folder segment containing "curriculum").

The plan should say what it **kept** and why — "Ohm's Law stays: Unit 3,
Day 2 still links to it" — not only what it removed. A teacher needs to see
the tool reasoned about it, or they will check by hand and the rule has
bought nothing.

#### Never ask the model for something the window already knows

The tools take `course` and `section` as arguments, and for a long time the
model filled them in. It should never have been asked: the assistant window is
opened FOR one section and its title says so.

The failure this produced is instructive because it is not a stupid one.
**"Unpublish Unit 4, Day 12" was read as section 4**, and the teacher was told
their course has no Section 4 — a perfectly reasonable misreading of a page
name that begins with a number, and one that no amount of describing the
argument would prevent on the next page name that does. It happened more than
once before it was fixed.

So the agent overwrites both arguments with the window's own before anything
runs. It cannot cost routing accuracy, because it changes nothing the model
reads — only what is done with what it said.

**Do this in the agent, not in the tool.** The same tools answer Claude Code
over MCP, where the course and section genuinely ARE the caller's to choose.
It is the window that is about one section, so the window is what binds them.

Worth a sweep of your own surface for the same shape: any argument the
surrounding context already determines should be overwritten on the way in
rather than described more carefully in a schema.

#### A corollary, learned the expensive way: do not fix routing with words

When a probe routes to the wrong tool, the tempting fix is a sentence in the
tool's description telling the model when NOT to use it. **Measure that
before you keep it.** We did, and it was worse.

The case: `publish_pages` takes an optional date range, and a typo'd "publsh
tomorows class … and the stuff it links to" chose it 10/10 with no page named
and an open-ended start date — one lesson turning into the rest of the term.
Adding *"NOT for one day's class — for a single day use publish_class_on"* to
the description fixed that probe and **broke three others**: "Publish Unit 2,
Day 3", a named page with no date in it whatsoever, went to
`publish_class_on` 10 times out of 10, and the window's own suggestion cards
fell from 110/110 to 90/110. A small model reads a sentence naming another
tool as a recommendation rather than a boundary, and it does not reliably
notice which half of a sentence applies to it.

The wording was reverted to the byte and the rule became a conditional in the
tool: an open-ended publish (no pages named, a start date, no end date) is
REFUSED, with a message saying to use `publish_class_on` for one day or to
give both dates for a stretch. Three properties make that better than the
sentence:

- it changes nothing the model reads, so it **cannot** cost routing accuracy
  and needs no re-measurement;
- it is exact, where a description is a hint;
- the refusal comes back as ordinary text, so the model corrects itself on
  the next turn rather than failing at the teacher.

Applied to publishing only. An open-ended UNPUBLISH hides work rather than
exposing it, the same backup undoes it, and a teacher clearing a section back
to a date is a real thing to want.

**The general rule: prompt text is a gamble that has to be re-measured across
the whole suite; a conditional is not.** If you change any description, re-run
every probe, not the one you were fixing — that is the only reason we caught
this instead of shipping a regression that looked like a fix.

#### And when you REMOVE a tool, audit the refusals that pointed at it

Cutting `remember_timetable` from the local list was right — dates the model
supplies are dates it may have invented — but it left three refusals saying
"record them with `remember_timetable` first". The model can no longer see
that tool. **A remedy naming something unreachable is worse than no remedy**,
because the next move available to a model that cannot follow the instruction
is to improvise the dates, which is the exact failure the removal was meant to
prevent.

Two things had to follow the cut, and only one of them was obvious:

1. The messages now name no tool. They say what is missing and that the app is
   asking the teacher — which also stays true over MCP, where the client's
   tool list is different again.
2. **Something else has to actually ask.** On macOS a schedule sheet collects
   dates (typed, from a file, or from a shared sheet link); the tool leaves a
   request and whichever assistant window is showing that section presents it.
   That sheet existed and was already attached to the window — the call that
   sets the request was simply never written, so nothing ever opened it. It
   looked finished from every angle except running it.

So: **if Windows has no equivalent way to ask, `remember_timetable` must stay
on its local list.** The cut is only safe because something else asks. And the
audit worth running after any removal is not "does the surface still route"
but "can every refusal still be acted on by the surface that receives it".

### What the assistant's window must BE — and what it need not look like

Decided 2026-08-16, in answer to "must the bubbles match?" — **no.** The mac's
bubble geometry (13pt insets, 17pt corner radius, Messages' grey and its light
blue selection) was measured against Messages on the same screen, and copying
those numbers onto Windows would produce something that looks like a Mac
application running in the wrong place. **Build a chat that looks at home on
Windows.** WinUI's own type ramp, its own spacing, its own accent colour. Read
the mac's chat sections below for what the arrangement has to achieve, and
ignore the numbers.

What is NOT negotiable is the shape of the interaction, because that is the
product rather than the platform:

1. **It is a CHAT.** Not a form, not a command palette, not a properties panel
   with a text box on it. A teacher types a sentence and gets a sentence back.
2. **Everything goes through the chat — input and output both.** No result
   appears only in a status bar, a toast, a dialog, or a log pane. If the
   assistant did something, the conversation says so, in the conversation.
3. **The one exception is confirming an action**, where buttons appear — as
   they do on the mac for a deploy or a plan. A teacher agreeing to publish to
   students should not have to type "yes" and hope it was understood.
4. **What the teacher chose with a button goes into their chat history**, in
   their own bubble, as though they had typed it. Reading back a conversation
   where the assistant asked, nothing answered, and something plainly happened
   is worse than not being able to read it back at all. The two contract
   scenarios "the deploy card is agreed to" and "the deploy card is cancelled"
   assert exactly this, so your suite can check it rather than your eyes.
5. **A thinking indicator is a MUST.** The local model takes seconds and the
   toolchain takes minutes, and a window that sits still through either one is
   indistinguishable from a window that has crashed. The mac shows one
   indicator for BOTH thinking and running a tool, deliberately: a teacher does
   not care which of the two the assistant is busy with, and two indicators
   invite the question. It hides while a card is waiting for a button — nothing
   is happening then, the teacher is.
6. **Up and Down walk back through what was asked before, as a Terminal
   does — the SAME KEYS as the mac.** Not a per-platform choice: a teacher who
   learns Up on one machine and finds it somewhere else on the other has
   learned nothing. It is also a requirement rather than a nicety — it is how
   somebody re-runs the thing they just ran with one word changed. The
   semantics are in `contracts/assist-cases.json` under `promptHistory`: eight
   step-by-step cases, the key names, and the two situations where the arrows
   must instead do their ordinary job and move the caret (a box holding more
   than one line, and nowhere further to walk — pass the key on rather than
   swallowing it, because a key that silently does nothing reads as a dropped
   keystroke). The two cases that get missed: the half-typed line is put aside
   and handed back rather than lost, and typing ends the walk so Down cannot
   silently replace what was just written.

And the rule that governs all of it, from row 1 of the improvement log: **the
window never names the machinery.** No tool names, no model names, no tokens,
no containers. "The small assistant" and "the larger assistant".

### The parts of those four areas that could NOT be a contract

`shared-rules.json` carries the rules. These are the neighbouring pieces that
are yours, written here because "not in the contract" must never mean "nobody
mentioned it".

**Scheduled deploys — the mechanism, and one refusal that may differ.** Writing
a plist and writing a scheduled task have nothing in common, so only the
refusals are shared. But one of them is a genuine fork: the mac refuses
Cloudflare with no Account ID **because it can pass `--account` in the plist and
therefore has to ask once, up front**. If a Windows scheduled task still cannot
be handed an account, then Cloudflare is not schedulable there at all — and the
right answer is a refusal that SAYS so, not a task that fails at 06:30 in
silence. Check it, and record what you find in `MAC-HANDOFF.md`; the contract
case says which of the two you are looking at.

Two more that stay yours: the plan's own words (the mac's says what has to be
true of the Mac — awake, plugged in, lid open — and yours will say something
different about sleep and Modern Standby), and cancelling, which on the mac is
`launchctl bootout` plus deleting the plist.

**The sidebar filter — the empty state.** The contract says WHAT matches. It
does not say what a teacher sees when nothing does, because that is a view: the
mac shows a short sentence rather than an empty pane, and the rule behind it is
that an empty list looks like a broken app while a sentence looks like an
answer. Say something; the words are yours.

**The transcript — everything except the stripping.** What is stripped is
shared (a colour code is a colour code). How much scrollback is kept, when the
view follows the tail, whether it scrolls on focus — all yours, and all
different in WinUI.

**Curriculum — the plan, not the recognition.** What COUNTS as an expectation
is shared and must be, because `build_site.py` decides what ships and an app
that disagreed would report coverage the site does not have. What a coverage
plan SAYS to a teacher, and how it is offered, is yours.

### Two things to MEASURE on Windows rather than copy from the mac

Both are in the contracts, and both would be wrong to implement by reading the
mac's answer. They are small, and each is an hour that turns into a day when
skipped.

**1. Whether the browser needs `127.0.0.1` instead of `localhost`.**
`app-rules.json` → `linkRules.browserSafe` says the mac rewrites the preview
address before handing it to the browser. The reason is specific to Safari: it
tries IPv6 (`::1`) first for "localhost", the container publishes the port on
IPv4 only, and the failure reads to a teacher as "the server dropped the
connection" — not as anything to do with addresses. **Find out what Edge does**
before deciding you need the same rewrite. Open a preview, then try
`http://localhost:<port>` in Edge by hand. If it connects first time, drop the
rewrite and say so in `MAC-HANDOFF.md` — that is a finding, not an omission,
and the contract should then note that the rule is mac-only. If Edge behaves
the same way, keep it and the contract stays as it is.

**2. Which progress markers you must match, and which are yours to write.**
`app-rules.json` → `markerOrigins` classifies all twenty-five. Seventeen come
from `scripts/*.py`, which both platforms run, and must match to the
character. Seven come from the launchers, which exist separately as `.sh` and
`.ps1` — those you write, and they already differ: the mac watches for
"Setting up this Mac" where `setup.ps1` prints "Setting up this PC". One is
"elsewhere" (`Quartz v4`, from the Docker build) and wants a human to look.

**Do NOT copy the mac's seven launcher markers into your milestone lists.**
Read your own `.ps1` files and match what they actually print. This fails
silently in the worst way: the app does not crash, the progress bar simply
stops advancing part-way and then jumps at the end, which reads as a slow
build rather than as a bug — and the only way to notice is to watch a whole
deploy with the old and new bars side by side.

### Do not re-derive Plantoir's tests — read `contracts/`

**This is the section that saves you a day per sync.** Six JSON files, written
by the macOS binary, meant to be read by `Plantoir.Tests`. It started as the
assistant's contract and is now the whole product's:

| File | What it holds |
|---|---|
| `contracts/assist-wording.json` | Every sentence the assistant says to a teacher — nineteen, with `{course}` and `{section}` where values go. |
| `contracts/assist-cases.json` | The nine phrasings matched in code, the four near misses that must NOT match, the three tool lists with approvals and plan twins, eight scenarios as `given` / `when` / `expectEvents` / `expectReply`, and the arrow-key prompt history. |
| `contracts/app-rules.json` | Launcher arguments per configuration, the validation a teacher reads, failure output turned into a sentence, whether a deploy must build first, the progress markers and where each one's text comes from, the preview's ports. |
| `contracts/schedule-rules.json` | Every accepted date form, how an ambiguous `08/09/2026` column is settled or asked about, what a pasted Google Sheet address becomes. |
| `contracts/class-planning.json` | Which titles carry numbers, what the next class is called, and the ORDER renames must run in. |
| `contracts/course-management.json` | The three kinds of zip and how they are told apart, the section number offered next and the refusals, grade labels from a course code. |
| `contracts/shared-rules.json` | What a scheduled deploy refuses and in what ORDER, what the sidebar filter shows, what is stripped from the launchers' output, and what counts as a curriculum expectation. |

An xUnit `[Theory]` with a `MemberData` source that deserialises these is the
whole integration. Nothing in them is macOS-specific: the sentences are the
product's and the sequences are the toolchain's.

**Why this exists.** Every wording change on the mac used to reach you as prose
in `GUI-IMPROVEMENTS.md` and a paragraph here, which you then retyped as tests
by hand — a day of it, and the sentences drifted the moment one side edited
without telling the other. They had been living in four places at once, and
three were already wrong: the identical deploy failure said "the output is in
that section's console in Plantoir" from one code path and "…that section's
window in Plantoir" from another, so which sentence a teacher got depended only
on whether a window happened to be open.

**How it stays true.** `Plantoir --write-contracts contracts` writes all three
files from `AssistWording`, `AssistCardCommand`, the tool surface and
`TaskMilestones`, and the contract tests run the same generator in-process and
fail when what is committed disagrees. A changed sentence therefore fails on the mac in the same
run that changed it, and reaches you as a **diff in `contracts/`** in the same
commit as the Swift. Verified by breaking a sentence on purpose: the suite
failed naming the key and the command to regenerate.

**Four things to know before you use them.**

- **Never hand-edit the GENERATED keys** — `cardPhrasings`, `tools`,
  `milestones`. Those are readouts of mac code; the next regeneration
  overwrites your edit and the diff looks like vandalism.
- **Write the entry to the template.** `MAC-HANDOFF.md` opens with "How to
  write an entry" — title and source, what it fixed and WHY (including what
  was rejected), numbers with the hardware they came from, the file and test
  names to look at, and whether the mac must match it or merely know. That
  file also has a **"Contract cases waiting on the mac"** section at the top,
  which is where a proposed case gets named.
- **You CAN propose an authored case.** `scenarios`, `nearMisses`,
  `promptHistory` and the case lists in the other files survive a mac
  regeneration untouched, so a behaviour you invent can be written as a case
  here — and the MAC suite will then fail until the mac implements it. That is
  the mechanism working, and it has been verified by doing it on purpose. Name
  the case so it reads as a proposal and log it in `MAC-HANDOFF.md`, or the
  failure looks like damage rather than a request.
- **`expectEvents` is an ORDER, not a set.** Every incorrect ordering passes a
  test that only checks all three events occurred — which is exactly how the
  mac shipped a preview that stopped after the writes it was meant to protect.
- **The event names are the contract's own**, deliberately not Swift's. Map
  `stopPreview.begins` / `stopPreview.ends` / `deploy` / `write` /
  `startPreview` / `runLauncherDirectly` onto whatever your app calls them.
  Two `given` flags decide the interesting cases: `sectionWindowOpen: false`
  is the headless path (`Plantoir.Mcp`, and a scheduled deploy), and
  `previewRunning: true` is the case Windows currently gets wrong.
- **Replies are NAMED, not quoted** — `wording.deployed`, not the sentence.
  Look them up in the wording file and substitute `{course}` and `{section}`
  yourself. A test that quotes its own copy of a sentence is how this problem
  started.

**What the contract CANNOT do, so you still write these tests yourself.**
The list is short but each item is a real gap, and a gap nobody names is a gap
both sides assume the other is covering:

| Not in the contract | Why not, and what to do instead |
|---|---|
| **Routing accuracy** | Whether the model picks the right tool for a sentence it actually sees is a measurement, not an assertion — it varies by model, quant and context size. Measured against a real `llama-server`; see [`research/`](research/README.md). The contract can say "deploy now" never reaches the model; it cannot say what the model does with a sentence that does. |
| **Anything with platform mechanics** | How a preview is stopped (WSL2, ConPTY, port leases, container naming) is yours. The contract says a stop must FINISH before a deploy begins; it cannot say what finishing means on your side. |
| **That an await is really an await** | This is the subtle one. The ordering assertion only proves anything if your fake preview emits the stop as TWO events with a real suspension between them, as the mac's does (`stopPreview.begins` … `stopPreview.ends`). A fire-and-forget stop that happens to complete quickly will satisfy a single-event fake and ship the bug the ordering was written to catch. |
| **Transcript composition** | The scenarios assert that named lines appear IN ORDER, never that they are adjacent or last. After an approval the tool's own result is the final line on the mac, and your renderer may differ. Order is portable; arrangement is not. |
| **Anything visual** | Bubble geometry, toolbar disabled states, progress headers, window layout. The contract has no vocabulary for these and should not grow one — that is what `GUI-IMPROVEMENTS.md` is for, and what a screenshot settles in a minute. |
| **Launcher arguments** | That a Cloudflare course deploys to Cloudflare is enforced on the mac by one function (`DeployCommand.arguments`) and by a unit test, not by the contract. If your `Plantoir.Mcp` or scheduled task composes its own arguments, write that test on your side — the bug is silent, and the site simply appears on the wrong host. |
| **Plan mode's offer to stop asking** | Tier-dependent (the smaller assistant cannot turn plan mode off at all), so it is a mac measurement and a mac rule until Windows has measured its own tiers. |

If you find yourself wanting to add one of these to the contract, the answer is
usually a second file rather than a stretched first one — `contracts/windows-*.json`
for behaviour only your side has.

### The assistant presses the app's own buttons — Deploy included

**Windows got here first and the mac has copied it.** `AssistAgent.RunTool`
already intercepts `rebuild_preview` and `deploy_section` and calls
`ShowPreviewInApp` / `StartDeployInApp` instead of the server, for the reason
written in that file: a build nobody can see might as well not have happened.
That is the right design. This section is the mac's version of it, the two
bugs it fixed on the way, and the one half of it Windows is still missing.

On the mac the mechanism is a registry of closures, `SectionWindowControllers`
(renamed from `SectionPreviewControllers` when Deploy joined the preview
there). A section window registers `isPreviewRunning`, `startPreview`,
`stopPreview` and `deploy` while it is on screen; the assistant looks up the
window for the course and section it is about and calls them directly, in
order, on the main actor. A registry rather than a flag a view observes,
because the assistant needs "stop, then write, then start" to MEAN that, and
an observer acts whenever the UI framework next evaluates a body — which may
be after the writes. Your `Action?` properties are the same idea; keep them.

**What was wrong on the mac, and is worth checking on yours.**

1. **A deploy nobody could watch.** `deploy_section` ran `deploy.sh` in a
   script runner the assistant made for itself. It worked — and showed
   nothing. No console, no progress header, no live-site link at the end, for
   a job that takes minutes. The teacher had a spinner in the chat and a
   section window still saying "No Preview Running". You do not have this
   bug; this is the bug your design avoids.
2. **A running preview refused the deploy.** The assistant-side path asked
   `CourseActivity.busyDescription` first, which reports a course busy while
   any of its sections is previewing — so the one moment a teacher most often
   asks to deploy was the one moment it would not. Worse, the refusal was
   that helper's own string, "Available once preview completed": written to
   sit under a greyed-out menu item, and meaningless read out in a
   conversation. **Any string you show in the chat has to be a sentence that
   survives being read on its own** — menu labels, tooltips and button titles
   do not qualify, however true they are.

**What the mac does now, and what Windows still needs.** The assistant does
what the teacher would do with the two buttons: **Stop Preview if one is
running, wait for it, then Deploy.** Windows stops the preview only for page
EDITS — `if (edits && PreviewIsShowing?.Invoke() == true) StopPreviewInApp?.Invoke();`
— and never for a deploy. And `StartDeployForAutomation()` calls `Deploy_Click`
directly, which walks straight past `DeployButton.IsEnabled = !IsBusy`: the
guard that stops a teacher deploying mid-preview does not apply to the
assistant, because a disabled button only disables clicking. So a Windows
teacher who asks the assistant to deploy while previewing gets a deploy and a
preview in the same container at once, which is exactly what that guard
exists to prevent.

Two things to get right when you fix it:

- **Await the stop.** `StopPreviewIfRunning()` is `void` today. Stop mode
  finds a section's processes BY WORKING DIRECTORY and so catches builds as
  well as servers — a stop still finishing when the deploy's build begins
  kills the build, and what gets deployed is the last `public/` that was
  allowed to complete: the site as it was before. This is the same finding as
  the preview-staleness work, arriving somewhere new.
- **The approval sentence is written per tool, in the teacher's words, and it
  does not restate the request.** The card is two bubbles:
  `wording.deployApproval`, then `wording.deployQuestion` — the consequence,
  one piece of advice a teacher can act on, and the question. **The sentences
  themselves are in `contracts/assist-wording.json` and are not repeated here**,
  because a document that quotes them becomes wrong the day they change; what
  is here is the reasoning, which does not.

  It was cut down over two passes, and both rejected drafts are worth knowing.
  It began as a label with warnings stapled on — the act, then that this is the
  one thing that changes what students see, that Plantoir cannot take it back
  for you, and that looking the preview over first would be the safer order.
  That announces a limitation of the app to somebody who has already decided,
  and second-guesses the order they work in. The middle draft named the act
  ("OK, I'll deploy … to Netlify.") and read oddly against the question that
  follows: agreeing to do a thing and then asking permission for it. **If your
  card carries its own heading or repeats the act, you will meet the same
  awkwardness.** What it cost: the destination is no longer named in the
  conversation, so a teacher with one course on Netlify and another on
  Cloudflare is told what will happen but not where — the section window's own
  progress names it. `schedule_deploy` DOES still name its destination, because
  that one is agreed to now and runs when nobody is watching.

  `AssistAgent.AskFirst` currently builds "I'd like to run **deploy section**.
  Shall I go ahead?" by underscore-swapping the TOOL NAME, which puts machinery
  in front of a teacher at the exact moment they are agreeing to something.
- **Cancel is answered by kind**: `wording.deployWasCancelled` for a deploy,
  `wording.planWasCancelled` for a plan. The asymmetry is deliberate and is the
  part to understand — a plan described changes to pages, so whether they
  happened is genuinely in doubt and the reassurance IS the answer, while a
  deploy that never started needs no reassuring about. Read which kind is
  pending BEFORE clearing it; that is the one way to get this branch wrong.
  Both are scenarios in `assist-cases.json`, so your suite can simply run them.
- **Do NOT say that the preview stopped.** The mac shipped a sentence for it
  and removed it the same day, on sight: read in place it was three lines of
  machinery after the one line that mattered. `wording.deployed` is the entire
  answer to what was asked. The teacher is looking at the window it happened
  in, and an assistant that explains what it had to do in order to obey is
  talking about itself. The stop still happens; it is simply not narrated.

**One place decides the launcher's arguments.** The mac's assistant path built
its own `deploy.sh` arguments and never passed `--target cloudflare` or
`--account`, so **a Cloudflare course deployed by the assistant went to
Netlify** — no error anywhere, the site simply appeared on the wrong host,
because Netlify is the launcher's default and every course written before
Cloudflare existed relies on that. It now calls `DeployCommand.arguments`,
the same function the Deploy button and the scheduled-deploy alarm call. If
`Plantoir.Mcp` or your scheduled task composes its own arguments anywhere,
that is the same bug waiting. The milestone list has the identical trap: the
assistant's copy had no Cloudflare case, so a Cloudflare deploy narrated
itself as a Netlify one.

**Awaiting the deploy is optional; reporting it honestly is not.** The mac
waits and answers "ICS3U Section 1 is deployed. Students can reach it now."
Windows answers "The section is deploying from Plantoir's main window", which
is a fair answer and ends the turn cleanly. What must not happen is telling a
teacher a section IS deployed while the upload has three minutes left — they
go and look at a site that is not there. If you do start awaiting it, send the
destination refusals (no publishing folder, no Cloudflare account) back as
chat text rather than as a dialog on a window the teacher is not looking at;
the mac keeps the dialog for the button and returns a flag on the result so
the assistant can say the same thing in words.

**The fallback still matters.** With no section window open there is nothing
to press, and the assistant runs the launcher itself. That path is not dead
code — it is what Claude Code over MCP uses, and what a deploy scheduled for
half six in the morning uses. Keep it working, and keep it asking the same
place for its arguments.

### The model's list is SHORTER than the server's

Two lists, deliberately. `definitions` is what the local model sees;
`mcpDefinitions` is what Claude Code sees over MCP. Same tools, same runner,
same rules — the model is simply shown fewer.

- **The `plan_` twins are hidden from the model.** Plan mode calls them from
  CODE when the model picks a write, so the model never needs to name one.
  They were about 30% of the prompt buying nothing. Claude Code KEEPS them:
  it has no plan mode and genuinely needs to ask "what would that do?".
- **`remember_timetable` is hidden from the model.** It takes dates as
  strings, so dates the model supplies are dates it may have invented — and
  a wrong one schedules a class on the wrong day silently. The schedule UI
  owns that path. `read_remembered_timetable` stays, because reading is safe.

Result: 20 tools down to **13** for the model — the six `plan_` twins and
`remember_timetable` are the seven taken off the list. (An earlier draft of
this note said 12; the cuts named above come to 13, and the code and its
tests say 13.) The thirteen are `list_pages`, `read_page`, `check_section`,
`publish_class_on`, `publish_pages`, `unpublish_pages`, `rebuild_preview`,
`undo_last_change`, `deploy_section`, `schedule_deploy`,
`cancel_scheduled_deploy`, `read_remembered_timetable`, `add_next_class`.
Worth doing on Windows too — the routing figures were measured at 15, so a
surface that grows past that is spending accuracy, and one that shrinks below
it should be spending less.

### The class timetable, and the chore it removes

Stored once per section in `courses/<CODE>/.internal/timetable/section<N>.json`
— dates, where they came from in the teacher's words, when recorded. Under
`.internal/` so it travels through backup, archive and restore. A partial
list is refused whole rather than half-stored: a half-remembered timetable
gets trusted and then dates the wrong classes.

**Parsing lives in Swift, never in the model.** This dissolves the question
of whether a bigger model could accept looser input: the model never sees a
date it did not read from the teacher's own file, so the small local model is
exactly as capable here as any cloud one, and it cannot hallucinate a date.
Sources: a shared Google Sheet link (fetched as CSV), a `.csv`/`.ics` file,
or pasted text.

**Ambiguous day/month ordering is ASKED, not guessed.** Any value with a
number past 12 settles the whole column silently, so most teachers never see
the question. When nothing settles it, quote the teacher's OWN date back —
"Is 08/09/2026 the 8th of September, or the 9th of August?" — apply the
answer to every row, and record the choice in the stored source string. Never
per-row, and a column written both ways round is a corrupt file, not an
ambiguity. Guessing here dates a term months out and nobody notices until a
class page appears on the wrong day.

**`add_next_class` — the chore this is all for.** A teacher finishing a
lesson wants tomorrow's page to exist, numbered and dated, without opening
frontmatter. The rule, and the second half is the part to get right:

- the NAME continues the highest unit, then the highest day inside it:
  Unit 3, Day 2 → Unit 3, Day 3;
- the DATE comes from **position in the timetable, not from the numbering**.
  Count the section's class pages, add one, take that date. Fifteen pages →
  the sixteenth date. A page called "Field Trip" consumes a date without
  moving the numbering, which falls out of counting pages rather than parsing
  names.

Refuse usefully at both edges: no timetable stored ("I don't know when ICS3U
Section 1 meets…"), and a timetable that has run out ("…has 40 class pages
and 40 dates, so there is no date left. Add more class dates."). "Index out
of range" helps nobody.

### The section index follows its newest class — the invariant, and its limit

A section's `index.md` is what a student lands on, and it opens by
transcluding one class page under "Most Recent Class". Every example course
used to carry a note telling the teacher to repoint it by hand after each
lesson. It is now maintained, and the rule is stated as an INVARIANT rather
than as a fix to the case that revealed it:

> **The section index transcludes the most recent class page students can
> see, and carries that class's date.**

Written that way, publishing a newer class is covered by the same sentence as
unpublishing the current one. Written as "unpublishing repoints the index",
the publish direction stays broken and nobody notices until a teacher
publishes tomorrow's class and the front page still shows last week's.

Three implementation points that will bite otherwise:

- **Match the transclusion by class TITLE, not by position.** The same index
  transcludes Help Sessions and Key Links. Repointing one of those at a lesson
  is a far worse bug than the one being fixed.
- **Read "which class is newest now" back from the section on disk**, after
  the pages are written — not from the plan. A second calculation is a second
  thing to get wrong.
- **Write the index inside whatever your undo records.** Ours goes into the
  same change object as the pages, so "Undo that" takes the landing page back
  with them. An undo that restores the lessons and leaves the front page
  pointing at the wrong one is a worse state than either of the two it was
  between.

A section with no dated visible class is left alone rather than pointed
somewhere arbitrary.

#### The road not taken: do NOT do this at build time

The obvious extension is to have the site builder repoint the index, which
would also cover a teacher who edits `publish:` by hand in Obsidian rather
than asking the assistant. **Considered and rejected, deliberately.**

It breaks the contract the whole toolchain rests on: **what is in the vault is
what gets published.** The builder works on a merged COPY, so it would not
rewrite the teacher's files — which sounds like it escapes the objection, and
is actually worse. The published site would then show a page the vault does
not contain, and the teacher would have no way to find where it came from:
they would read their own `index.md`, see it pointing at Unit 4, Day 12, look
at the live site showing Unit 4, Day 19, and have nothing to blame.

So the automation fires only where a teacher can see it fire: when the
assistant changes a class's visibility. Editing frontmatter by hand leaves the
index exactly as written, which is the correct behaviour for a tool whose
promise is that the vault is the truth. **This is a live constraint, not a
historical note** — the same argument applies to any future "the builder could
just fix it up" idea, and there will be more of them.

## Quartz serves the OLD site before it builds the new one

This one is inside Quartz, so it is yours as much as ours, and it is invisible
until somebody edits a page and looks.

`quartz build --serve` does this, in this order (its own `cli/handlers.js`):

```
server.listen(argv.port)
console.log("Started a Quartz server listening at http://localhost:PORT")
await build(clientRefresh)
```

**It starts serving the existing `public/` before it rebuilds it.** So the
moment a preview launches, the server answers `200` — with the PREVIOUS build.
The fresh one lands seconds later.

Anything that decides "the preview is ready" from the server responding will
therefore show the site as it was BEFORE the teacher's change, with nothing on
screen to suggest it. Ours did, and the symptoms were maddening in a specific
way worth recognising:

- editing a page, previewing, and seeing the old page;
- stopping and starting the preview, and still seeing the old page;
- **doing the same thing slowly and having it work**, because the build had
  quietly finished in the meantime;
- pressing Reload by hand and having it come right.

We suspected three innocent components before finding this — the merge, the
build, and our own web view — and every one of them was provably correct: the
merged content, the built `public/`, and the file timestamps all showed a
current site while the screen showed an old one.

Two rules follow:

1. **Wait for the BUILD, not for the server — and watch the OUTPUT FILE, not
   the console.** Note the time before launching the build, then wait until
   `<section>/public/index.html` is newer than that. It means exactly what has
   to be true before a teacher is shown anything, and unlike Quartz's progress
   lines it cannot be changed by a version bump or swallowed by a spinner. We
   tried matching its emit line first; the file is strictly better.
1b. **Clear the web view's caches before loading, not just its cache policy.**
   A Quartz site is a single-page app: a no-cache policy governs the main HTML
   request while the scripts, styles and the content the page fetches for
   itself still come from the cache — so a fresh index.html can still assemble
   the previous site out of parts. This looked exactly like a build problem
   and was not. Clear disk, memory and fetch caches; leave local storage and
   cookies alone so the preview keeps its light/dark setting.

2. **Reload only when you never saw that line.** We first reloaded
   unconditionally, as cheap insurance, and it was worse than the problem it
   insured against: every preview in the app flickered, for a case that by
   then could not happen. The signal tells you which situation you are in, so
   let it decide — no line, no certainty, so reload; line, so leave the
   teacher's page alone.

Bound the wait (we allow 120 seconds) so a Quartz that never prints the line
cannot leave a teacher watching a spinner: show the preview anyway, and that
is exactly the case the conditional reload covers.

## What the conversation looks like, and why

The assistant window is a CHAT, not a form with a log under it. That was a
deliberate change and it is worth stating why before the numbers: a teacher
asking for something, being told what would happen, and agreeing to it is a
conversation, and a window that looks like one is a window they already know
how to use. Nothing here has to be taught.

**One decision is yours, not ours.** These specs describe macOS Messages,
because that is the chat every Mac teacher already has open. The Windows
equivalent may be better served by looking like Windows — Teams and Phone Link
have their own bubble idiom, and a Mac-shaped chat on Windows can read as
foreign rather than familiar. What must carry across is the STRUCTURE (who is
on which side, what counts as a message, when a turn ends); the exact
curvature is a local decision. If you do choose to mimic your platform's
chat, measure it the way we measured ours — see the last paragraph.

### The two sides

| | Teacher | Assistant |
|---|---|---|
| Side | right | left |
| Fill | blue, RGB **(20, 147, 255)** | dark: **(59, 59, 61)**; light: **#E9E9EB** — flat, never translucent |
| Text | white | the ordinary label colour |

**Do not use the system accent colour for the teacher's side.** We did, and it
is a latent bug rather than a shade being slightly off: the accent is whatever
the user chose in system settings, and set to graphite it makes the teacher's
bubbles the same grey as the assistant's — at which point the left/right,
blue/grey distinction the whole window depends on silently disappears. The
blue is its own constant.

**The assistant's grey is a constant too, not a translucent token.** Ours was
"a system grey at 16% opacity" for a while, and a translucent fill can only
ever be as light as the window behind it allows — measured side by side on
the same backdrop it sat visibly darker than Messages'. Flat colours, both
appearances.

### The bubble

Ten rounds of measuring against the real thing, each round correcting the one
before (`GUI-IMPROVEMENTS.md` rows 177–178 have the blow-by-blow). The final
geometry, in points at 13pt text:

| | |
|---|---|
| Corner radius | **17** — an absolute of the design; it does NOT scale with the font |
| Radius rule | `min(17, height/2, width/2)` — single-line bubbles fall out as capsules, no separate branch |
| Visible text inset, each side | 13 |
| Text inset, top and bottom | 7 |
| Tail size | an absolute, like a pen width — one size on every bubble (`tailScale` = 17) |
| Tail drop BELOW the body | 5.1 (0.30 × tailScale) |
| Corner landing on the bottom line | 0.47 × radius — the one tail number that follows the radius |
| Tail tip, INSIDE the body's edge | 6.5 (0.38 × tailScale) |
| Hook rejoins the bottom edge | 14.5 in (0.85 × tailScale); root width ≈ 6.5 |

The two costliest wrong assumptions, both of which survived several rounds:

- **Nothing scales with the font.** The radius measured the same across two
  text sizes; so did the whole tail. An early pass scaled both down by our
  smaller font and every bubble read as subtly wrong beside Messages. (The
  OLD version of this section said the opposite — "scale the proportions to
  the corner radius". That advice cost us three passes. Constants.)
- **Cross-app constants come only from screenshots with BOTH apps in them.**
  Deriving one from two separate captures needs each capture's
  pixels-per-point; we guessed one wrongly and shipped a tail a fifth too
  large. Same screenshot, same screen — the scale cancels out.

Drawing the outline (still one continuous path, not a rectangle plus a
triangle):

- **The corner-to-tail joint is about the TANGENT.** The silhouette reaches
  its deepest inset exactly at the bottom line while travelling straight
  DOWN. A corner that lands travelling horizontally meets the tail in a cusp
  and the tail reads as a comma stuck under the bubble.
- **The jog into the tail gets exactly the radius of height**, held nearly
  flat for the first half with the dive concentrated in the last (a cubic
  with vertical end-tangents; late control ~0.215 of the span, early ~0.30).
  A longer span drifts early and reads as a diagonal cut into the side; a
  weighting that carries inset early reads as the bubble bulging.
- **No sharp vertices anywhere.** The tip is rounded about 1.5pt across, and
  the hook meets the bottom edge in a small curve, not a corner.
- **The underside of the tail is CONCAVE** — a diagonal with a mild sag
  toward the bubble, not a deep scoop. That curve, not the tip, is what makes
  the shape read as a tail.
- **Draw inside the bounds you are given.** Ours drew past its rect at first
  and was clipped — a clipped tail is severed, not pointed.

### Selecting text in a bubble

Messages pins its selection colours the way it pins its bubble colours:
light-appearance selection blue **(174, 218, 255)** behind the selected run
in BOTH appearances, with the selected glyphs painted in the bubble's own
fill. The system's dark-mode selection colour is a grey-slate that reads as
broken beside it. Two porting notes: our UI toolkit's built-in text selection
drew an unstylable grey and we had to drop to the native text control to
style it at all — check yours early; and the hook that styles selection must
be one that runs when selection machinery actually attaches (ours had a
first attempt that configured a text editor that did not exist yet, and it
failed silently).

### Tails mark turns, not messages

One tail per RUN: on the last thing a participant said before the other one
answered. A tail on every bubble makes three sentences look like three
separate attempts to get a word in — and it is the kind of thing that looks
fine in a screenshot of two messages and wrong in a real conversation.

The newest message always has a tail, since its turn has not been answered
yet. Anything nobody SAID — we have one such item, a note that a restore
happened — wears no tail and does not end anyone's turn; the rule looks past
it to the next thing that was actually said.

### What counts as a message

More things than you would first assume, and this is the part that matters
most for how the window reads:

- **What the assistant says.** Obviously.
- **What the teacher types.** Obviously.
- **Tool results.** "The preview is rebuilding now" is the assistant
  ANSWERING. That it came from a tool is machinery, and the teacher is not the
  audience for machinery. As plain lines with an icon these read as a log
  spliced through a conversation.
- **The plan.** It used to live only in the approval card, so pressing Go or
  Cancel destroyed the description of what had just been agreed to — and with
  it the context for everything after. A conversation you cannot scroll back
  through is not a conversation.
- **The question.** "Shall I go ahead?" / "Shall I deploy?" is its own
  message, which is what lets the card below be nothing but buttons.
- **The teacher's ANSWER.** Pressing Go records "Go" as a teacher message, in
  their bubble on their side. Reading back a conversation where the assistant
  asked, nothing answered, and yet something plainly happened is worse than
  not being able to read it back at all.

The general rule: **anything that is part of the conversation belongs IN the
conversation, and a control that owns text destroys that text when it
resolves.** Leave controls the choice and nothing else.

### The typing indicator

**A THOUGHT bubble, not a speech bubble** — a capsule with two plain circles
stepping down toward the speaker, the comic-strip sign for thinking, shown on
the assistant's side whenever the model is thinking or a tool is running —
both are waits with nothing on screen, and a teacher does not care which.
Ours wore the speech tail for a while and it read as off without anyone
being able to say why: a tailed bubble means SAID, circles mean composing.

Measured from a screen recording of Messages, as ratios of the capsule's
height (which equals a single-line message bubble, so the indicator occupies
the slot of exactly the thing it stands for): capsule ~1.7× as wide as tall;
dots 0.24 of the height with a gap about half a dot; the larger circle 0.41,
poking about two points past the lower corner; the smaller 0.14, below and
outside with a sliver of gap. Each dot lags the one before it (about 0.18s)
so the three read as a wave rather than a blink.

**Draw the capsule and both circles as ONE geometry filled once** (whatever
your platform's path-union is). As separate shapes, any translucency doubles
where they overlap and the join shows as a brighter seam.

### The box you type in

- A rounded field — continuous rounded rectangle, radius 17 — with the send
  button INSIDE its right end, rather than a plain field with a button parked
  beside it.
- **Never disable it to mean "busy".** A disabled field cannot hold keyboard
  focus, so the system moves focus to the next thing it can find; ours landed
  on the first disclosure group in the suggestion shelf, which looks like a
  bug in something else entirely. Typing and SENDING are separate
  permissions: the box stays live so a teacher can write their next message
  while they wait — every messaging app allows this — and only the send waits
  for the run to finish.
- **Focus returns to it after every send.** Two commands in a row should not
  need a click in between. This is also what keeps the arrow-key history
  usable, since that depends on the field having focus.
- Up and Down walk the teacher's own previous messages; see the history rules
  recorded in `GUI-IMPROVEMENTS.md` row 157.

### Two small things that are easy to skip

- **Emphasis has to be rendered.** Plans mark their headings bold, and in
  SwiftUI `Text(someStringVariable)` does not parse markdown at all — only
  string literals do — so it reached the teacher as literal asterisks until
  the text was parsed explicitly. Whatever your toolkit is, check how it
  treats a runtime string; several style literals only.
- **The suggestion chips take the pointing-hand cursor.** A plain button style
  keeps the look and suppresses the cursor, so it has to be put back by hand.

### How to get this right in less time than we did

Measure — and close the loop. Guessing produced wrong shapes; one screenshot
and a twenty-line script that read the pixels produced right ones in minutes.
The full method, each part of which was learned by paying for its absence:

1. **Trace silhouettes, don't eyeball.** Per-row min/max of the fill colour
   gives the exact edge profile; every number in the tables above came out
   that way.
2. **Only same-screenshot comparisons.** Both apps in one capture, or the
   pixels-per-point uncertainty eats the answer.
3. **Render YOUR result and measure it the same way.** The passes that
   shipped wrong all trusted arithmetic about what the code would draw;
   the passes that stuck rendered the real control offscreen and walked its
   pixels against the reference trace. Insets especially: native text
   controls put slack around their glyphs that no spec predicts — our final
   paddings are asymmetric (12 leading, 9 trailing) purely to cancel what
   the label actually draws, and only the render-measure loop could have
   found that.
4. **Expect the reference to correct you more than once.** Ten passes, each
   started by a human eye catching what the previous measurement missed, and
   each ending with the pixels agreeing the eye was right.

## Plan mode, undo, and how often to back up

Three decisions taken on the macOS side on 2026-08-15 that Windows should
match, because they are about how much to trust a local router rather than
about either platform.

### Plan mode: the model says what it heard before it acts

A local router is wrong sometimes. Measured over 290 trials, the small model
puts about **one request in five** on the wrong tool. Plan mode turns that
from something that happens into something a teacher declines: a write runs
its `plan_` twin first, the plan is shown in the twin's own words, and
nothing happens until they press Go.

- **Writes only.** Reads answer immediately. Gating "what do students see
  right now?" makes every question two clicks and teaches people to press Go
  without reading — which costs the gate its whole value.
- **Always on for the small model.** On the 1.5B it cannot be turned off at
  all; 79% is not a rate at which anyone should be handed a "stop asking"
  button. The macOS build ignores a remembered "off" answer when it finds
  itself on that tier, so a teacher who turned it off on a capable machine
  does not inherit that on an 8 GB one.
- **Offered off after five in a row, once, on the capable model only.** Trust
  is earned rather than assumed, and the offer arrives while five correct
  plans are still fresh rather than months later in a settings pane. A Cancel
  RESETS the run: somebody who has just stopped the assistant doing the wrong
  thing must not then be asked whether they would like it to stop asking.
- **Deploys always ask, plan mode or not.** A deploy puts work in front of
  students immediately and cannot be taken back by us.

### Undo is not version control, and it should not pretend to be

Worth stating because it is easy to assume otherwise: **courses are not git
repositories.** Nothing in the toolchain runs `git init`. The undo history is
in-memory before/after snapshots of the files each tool touched, held as a
stack for the life of the conversation, and it is gone when the window
closes.

It has one property worth copying exactly: before restoring a file it
compares what is on disk to what it wrote, and **skips anything the teacher
has edited since**. Publishing a class, then spending ten minutes writing it
in Obsidian, then saying "undo that" must not cost those ten minutes.

### Back up once per conversation, not once per command

The macOS build originally zipped the whole course before EVERY write. On an
Obsidian vault full of images that is slow and large, and a chat with six
commands made six near-identical copies.

It now backs up **lazily, once per conversation**: the first write makes the
zip, later writes reuse it, and a conversation that only reads makes none.
That single zip is also what the assistant's **Restore** offers — putting the
section back to how it was when the chat started, which is the safety net
that makes "just do it" mode reasonable to offer at all.

Two details that make the backups usable rather than merely present:

- **Provenance rides in the file name**, so a teacher choosing among several
  can tell what made each one and why — Plantoir before an assistant chat
  about a particular section, or themselves on purpose. A list of five
  identical-looking timestamps is not a choice anybody can make.
- **Prune only the ASSISTANT's own backups**, keeping its five most recent
  per course. A teacher's backup is a decision — they pressed Back Up because
  they were about to do something they were unsure of — and deleting it on a
  schedule they never agreed to is the app overruling them about their own
  work. The assistant's are different in kind: it saves one per conversation
  whether or not anybody asked, so clearing up after itself is its job. A
  teacher with twenty of their own keeps all twenty, and they never crowd out
  the assistant's five, because the two are counted separately.
- And prune ONLY backups at that: archives and the wizard's own zips live in
  the same folder and their parsers deliberately reject each other's forms.

### Restore is section-scoped, though the zip holds the course

The backup contains the whole course; a conversation is about one section. A
whole-course restore would silently revert work done in a sibling section
while the chat was open — a teacher may well have been editing Section 2 in
Obsidian while talking about Section 1. So Restore puts back only the section
the conversation was about, and says so on the button.

**Section-scoped means more than the section's folder**, and this is the part
easy to get wrong. The assistant can publish or unpublish a COURSE-LEVEL
shared page for one section, and that lives in the shared file's frontmatter
as `publishForSection<N>` — outside the section folder entirely. Restoring
only `section<N>/` would leave that half of the conversation's work in place.

The macOS build restores both: the section folder's contents, and — in every
shared page — only the keys carrying THIS section's number, spliced back from
the backup's own lines rather than re-derived. Copying the lines verbatim has
three consequences worth keeping: the older `draftSection<N>` spelling
survives untouched where a course still uses it, a key the conversation ADDED
is removed again, and every other section's keys plus the whole page body stay
byte for byte.

The section folder is emptied and refilled rather than swapped, for the same
reason `restoreBackup` documents: Obsidian holds the folder open.

**Say the surprising part in the confirmation, not in a doc.** Anything the
teacher changed in that section during the conversation goes back too,
including work done in Obsidian, and Plantoir cannot bring that part back.
That sentence belongs in the alert.

## Testing

- The **PowerShell launchers are tested on real Windows** — all three have
  been driven end to end through the app: course creation, preview (including
  `--stop` reclaiming container-side processes), and publishing to all three
  destinations, most recently a live Cloudflare Pages publish. The WSL2
  background and the original test plan are the appendix at the end of this
  file; read it for *why* the launchers look as they do, not as a to-do list.
  (An earlier version of this bullet said they were UNTESTED and told you to
  test them first. That was a week out of date and would have sent a session
  down a dead end.)
- `verify.sh` is the toolchain gate on macOS/Linux; a Windows verify
  script should mirror it, including its cross-check that every helper a
  launcher calls is defined in that same launcher file (a missing helper
  is exit 127 at runtime, on the one path nobody tests).
- Mirror the macOS test discipline: the unit suite runs without Docker;
  presentation regressions get press-and-look tests (entry 81's lesson:
  button logic can be perfect while its dialog never shows).

## Documentation map

- [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md) — THE spec (179 entries as of
  2026-08-15). Its **Windows status** section is where coverage is tracked.
- [`documentation/`](documentation/README.md) — toolchain deep dives 01–10.
- [`CLAUDE.md`](CLAUDE.md) — the repository's entry point: conventions,
  testing, setup, and the traps that cost time.
- [`RELEASING.md`](RELEASING.md) — cutting a release, both platforms.
- [`research/ai-assist/`](research/README.md) — the assistant's
  measurements, and `HISTORY.md`, which is the feasibility work, the build
  handoff and the original MCP proposal in one place.
- The WSL2 launcher background is the **appendix at the end of this file**.
- [`mac-app/`](mac-app/README.md) — the reference implementation; when an
  entry's Windows note is thin, read the Swift it references.


---

# Appendix — WSL2 background and the original .ps1 test plan

*Folded in from the former `WINDOWS-TESTING.md` on 2026-08-15. Read it for **why** the
launchers look the way they do — the WSL2 container-runtime reasoning, the
`ProcessStartInfo` token injection, the path translation — not as a to-do list.
The launchers have since been driven end to end on real Windows 11, including a
live Cloudflare Pages publish. Two facts in it were corrected on the way in: the
token file is `/tmp/deploy_pat` (renamed when Cloudflare support arrived, since
one file now serves both providers), and deploys are no longer Netlify-only.*

> **Status (2026-08-13): the launchers are no longer untested.** All three
> have been exercised repeatedly on real Windows 11 through the app —
> course creation, preview (including `--stop` reclaiming container-side
> processes), and publishing to all three destinations, most recently a
> live Cloudflare Pages publish end to end. Treat this file as **the WSL2
> background and the original test plan**, not as a to-do list: the
> historical detail on the Docker-Engine-in-WSL2 path, port blocks, and
> line-ending traps is still the best explanation of *why* the Windows
> launchers look the way they do.
>
> One thing it does NOT cover, and worth knowing: `verify.sh`, the
> toolchain gate named in [`CLAUDE.md`](CLAUDE.md), **cannot run
> on Windows** — it is bash and expects `docker` on `PATH`, where here it
> lives inside WSL2. Toolchain changes made on Windows are verified by
> driving a real publish through the app instead.

> **Audience:** a Claude Code session running on the maintainer's Windows 11 Pro
> machine. This file gives you the context needed to test (and fix) this
> toolchain's Windows launchers.
> Read this fully before touching anything. If you are building the Windows
> APP, start with [`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md).

### Mission

The toolchain recently **dropped its Docker Desktop requirement**. On
Windows, the PowerShell launchers (`setup.ps1`, `preview.ps1`, `deploy.ps1`)
now provision and use the **Docker Engine inside WSL2** automatically. That
code was written and parse-checked on macOS but has **never executed on a
real Windows machine**. Your job: exercise it end to end on this machine,
find what breaks, fix it, and report.

### Background (5-minute orientation)

- This repo publishes teaching websites from Obsidian vaults using a Docker
  container that wraps a patched Quartz v4.5.0. There is **no registry**:
  the launchers hash the folder's build recipe and build the image locally
  as `teaching-quartz:src-<hash8>` (`Get-BuildContext` / `Get-ToolchainHash`
  / `Build-ImageIfMissing` in the `.ps1` files). Full architecture docs:
  [`documentation/README.md`](documentation/README.md),
  especially [`documentation/03-launcher-scripts.md`](documentation/03-launcher-scripts.md)
  (the section "Container runtime bootstrap" describes exactly what you are testing).
- The teacher-facing flow is: `setup.bat` (interactive course wizard) →
  `preview.bat COURSE SECTION` (build + serve; the launcher prints the
  host address — each working folder gets its own probed port block) →
  `deploy.bat COURSE SECTION` (delta deploy — Netlify by default,
  `--target cloudflare`, or `--to-folder <path>`).
- Each `.bat` is a thin wrapper that runs the `.ps1` beside it.
- The macOS counterpart of this change (Colima) is **already tested and
  working** — treat the `.sh` scripts as the reference for intended behaviour.

### What the new Windows code does

In each of the three `.ps1` scripts, near the top, there is an identical
block: `Ensure-ContainerRuntime` plus helpers. Its intended behaviour:

1. **Fast path:** if a native `docker` (docker.exe) works, use it unchanged.
2. Otherwise require `wsl` + an installed distribution (else print
   `wsl --install` guidance and exit).
3. Probe `wsl -e docker info` as the default user, then as root
   (`$global:WslUserArgs = @('-u','root')`).
4. If the engine is missing inside WSL, offer to install it:
   `apt-get install docker.io` as root, then `usermod -aG docker <user>`.
5. Start it with `wsl -u root -e sh -c "service docker start"` and poll.
6. On success, define `function global:docker { & wsl $global:WslUserArgs -e docker @args }`
   so every later `docker …` call in the script transparently routes through
   WSL. Bind-mount paths are translated with `Get-MountPath` (wslpath →
   `/mnt/c/...`). `deploy.ps1` additionally has two
   `System.Diagnostics.ProcessStartInfo` invocations that bypass PowerShell
   command resolution — these use `$DOCKER_EXE` / `$DOCKER_PREFIX` variables
   instead.

### Environment notes for this machine

- Windows 11 Pro (build 26100), PowerShell 5.1 minimum target (also test
  under `pwsh` 7 if installed).
- Clone/pull this repo; **test the repo's `.ps1` files directly** (in
  production they reach teachers via the app's `.toolchain/` mirror).
- The repo stores files with **LF line endings** (depending on
  `core.autocrlf`, your checkout may or may not have CRLF). PowerShell
  handles LF `.ps1` fine. If a `.bat` misbehaves with LF endings, invoke the
  `.ps1` directly (`powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1`)
  and note the finding — in production, teachers receive CRLF copies (the
  image build runs `unix2dos`).
- The container image is **built locally by the launcher on first run**
  (BuildKit required — `Ensure-Buildx`); expect the first run to take a few
  minutes and to need the network. A changed recipe changes the tag and
  rebuilds.
- `courses/` is gitignored — a fresh clone has no courses. The setup wizard
  offers to install an Example Course (**EXC2O**); say yes and use it as the
  test fixture throughout.

### Test plan (in order)

Work through these scenarios; after each, note PASS/FAIL and any output worth
keeping.

**1. Static review.** Read `Ensure-ContainerRuntime` in all three `.ps1`
files and flag anything that cannot work on PowerShell 5.1 before running
anything.

**2. Specific mechanisms I could not verify from macOS** — test these in an
interactive PowerShell first:
   - Empty-array argument flattening: `$e = @(); wsl $e -e echo hi` — confirm
     no stray empty argument reaches wsl (this pattern underpins
     `Test-WslDockerReady` and the `docker` function).
   - `$env:WSL_UTF8='1'; wsl -l -q` — confirm clean, parseable distro names.
   - `Get-Command docker -CommandType Application` behaves on PS 5.1 when no
     docker.exe exists (should return nothing, not throw).
   - After `usermod -aG docker <user>`, does `wsl -e docker info` work
     without `wsl --shutdown`? (The scripts fall back to root if not — confirm
     the fallback engages.)

**3. Scenario: engine not installed.** If this machine's WSL distro has no
Docker engine (or remove it: `wsl -u root -e sh -c "apt-get remove -y docker.io"`),
run `.\preview.ps1 EXC2O 1 --build-only` (after setup) or `.\setup.ps1` and
confirm the install offer appears, works, and the run continues to success.

**4. Scenario: engine stopped.** `wsl --shutdown`, then run a launcher —
confirm it starts the engine itself and proceeds.

**5. Scenario: engine running (fast path).** Re-run immediately — confirm no
install/start work is repeated.

**6. End-to-end teacher flow.**
   - `.\setup.bat` → install the Example Course (EXC2O).
   - `.\preview.bat EXC2O 1` → confirm the container is created with a
     `/mnt/c/...` mount, the build succeeds, and `http://localhost:8081`
     renders in a Windows browser (WSL2 localhost forwarding).
   - Check interactive fidelity through the `wsl`-routed `docker exec -it`:
     wizard prompts, and especially the arrow-key colour scheme picker if you
     run a full course setup.
   - `.\preview.bat EXC2O 1 --build-only` then, **only if a Netlify token for
     a throwaway account is available**, `.\deploy.bat EXC2O 1`. Deploys
     create real Netlify sites — skip otherwise and note as untested.

**7. Edge cases.**
   - Run from a folder whose path contains spaces (e.g.
     `C:\Users\<me>\Class Websites Test\`) — mount translation and quoting.
   - Move the folder, run again — the container NAME is derived from the
     folder's path hash, so a moved folder gets a brand-new container (and
     the old one is left stopped); confirm the new one mounts the new
     `/mnt/c/...` path.
   - Two working folders at once: confirm each gets its own container
     (`teaching-quartz-<hash>`) and its own host port block (bases 8081,
     8091, …, each with a +1000 websocket block), and that two previews can
     run simultaneously.
   - `.\preview.ps1 EXC2O 1 --port 8082` — the per-preview port flag.
   - After any build, confirm the merged output contains the generated
     social sharing card (`.merged_output/section1/quartz/static/og-image.png`
     should be a title card in the course's colours, not the stock Quartz
     crystal — the card is drawn by `scripts/social_card.py` inside the
     container, so no Windows-side work is involved).
   - `deploy.ps1`'s token-injection steps (the `ProcessStartInfo` ones) — the
     `$DOCKER_PREFIX` quoting through `wsl.exe` is the riskiest untested
     code; verify `/tmp/deploy_pat` arrives in the container intact
     (test with a dummy: pipe text through the same command shape).

### When you find problems

- Fix them in the working tree, keeping the structure parallel across the
  three `.ps1` files (the block is intentionally identical in each) and
  consistent with the `.sh` reference behaviour.
- Commit to a branch named `windows-wsl2-fixes` with clear messages; do not
  push to `main` directly.
- Finish with a summary: scenarios run, PASS/FAIL each, fixes made, and
  anything that remains untested (e.g., a true fresh `wsl --install` if this
  machine already had WSL).

### Ground rules

- Never uninstall WSL or delete existing WSL distros without asking first.
- Images are only ever built locally; there is nothing to publish.
- Netlify deploys are opt-in only (they create public sites).
- The `.sh` files are macOS-only — do not "fix" them on Windows.

---

### Results — 2026-08-11 (Claude Code, maintainer's Windows 11 machine)

Run on Windows 11 Pro 26200, WSL 2.5.10 (no distro pre-installed —
Ubuntu-24.04 installed for the tests), Docker Engine 29.1.3 inside WSL,
PowerShell 5.1. Fixes were committed to **main** at the maintainer's
direction (overriding this brief's branch instruction). Interactive
runs were driven through `windows-app/PtyDriver`, a ConPTY harness that
gives the launchers a real TTY.

**1. Static review — FAIL → fixed.** Beyond parse-checks (clean), five
faults found and repaired: (a) preview.ps1's image resolution was
inverted — every run without `--image` printed "missing the toolchain's
build recipe" and exited 1; (b) a single trailing flag arrived as a
STRING, so `$Flags[0]` indexed characters ("Unknown option: -") — now
always an array; (c) the three scripts hashed different paths for the
container name (setup hashed the invocation directory before its
Set-Location; casing changed the hash) — all three now hash the
folder's physical path via GetFinalPathNameByHandle, after
Set-Location; (d) no exit-code propagation from the final docker exec;
(e) `Ensure-Buildx` guarded WSL work with an always-true null check.
Also: under `$ErrorActionPreference='Stop'`, PS 5.1 turns wsl.exe
stderr into TERMINATING errors at any redirected call site — probes
that legitimately fail (inspecting a not-yet-built image) killed the
script. The global docker wrapper now relaxes the preference around the
wsl call. Two milestone lines the app watches for were added
("Setting up this PC - a one-time step ...", and preview's
"Starting container if needed ...").

**2. Mechanism checks — PASS.** Empty-array flattening (`wsl $e -e
echo hi` → clean), `WSL_UTF8=1` distro names parse, `Get-Command
docker` returns nothing without throwing when no docker.exe exists.
usermod fallback untested (the test distro runs as root by default).

**3. Engine not installed — PASS (command path).** `apt-get install
docker.io` inside WSL (the script's exact command) installed engine
29.1.3; the interactive install-offer prompt itself was not exercised
end-to-end (the engine was installed before the first full run).

**4. Engine stopped — PASS.** `service docker start` + poll brought the
engine up from cold.

**5. Fast path — PASS.** With the engine running, no install/start work
repeats; runs go straight to the container checks.

**6. End-to-end teacher flow — PASS.**
- `setup.ps1 --install-example`: image built locally from the recipe
  (BuildKit via buildx in WSL), container `teaching-quartz-<hash8>`
  created with `/mnt/c/...` mount, EXC2O installed, and
  `EXAMPLE_COURSE_CODE=EXC2O` printed for the app.
- `preview.ps1 EXC2O 1`: "Preview will be available at:
  http://localhost:8081/" announced; page served HTTP 200 with the
  correct title through WSL2 localhost forwarding.
- Interactive fidelity through the wsl-routed `docker exec -it`:
  works under a pseudo console — with one CRITICAL caveat: the process
  that creates the ConPTY must not itself have redirected stdio, or
  the child inherits stale pipe handles and wsl reports "the input
  device is not a TTY". (The Plantoir app, a GUI process, is naturally
  clean.)
- `deploy.ps1 EXC2O 1` with a throwaway token pre-stored in Credential
  Manager: Netlify site created, 233 files uploaded with streaming
  counts, "✅ Deploy complete.", exit 0, site live over https. The
  first-run token-paste prompt was not exercised (token pre-stored);
  `/tmp/deploy_pat` injection via ProcessStartInfo worked — the token
  reached the container intact.

**7. Edge cases.** Two-folder concurrency, moved-folder recreation,
spaces-in-path, and `--port` were NOT yet exercised on this machine
(the per-folder hash and port-block logic are covered by unit tests in
`windows-app/Plantoir.Tests`). The generated social card was verified
present after the build (`.merged_output/section1/quartz/static/
og-image.png`, 28 KB, drawn in-container). Remaining scenarios are the
first candidates for the next session.

**Untested overall:** a true fresh `wsl --install` (WSL itself was
already present), the docker-group/usermod fallback, and pwsh 7 runs
(everything above ran under Windows PowerShell 5.1).
