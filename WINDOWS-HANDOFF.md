# Windows App — Handoff

Read this first if you are building the native Windows counterpart to
Plantoir (the macOS app in `mac-app/`). It gathers everything a Windows
implementation needs; the deep dives it links to are kept current.

## What you are building

A native Windows app wrapping the same toolchain the macOS app wraps. The
toolchain itself is **shared and already done**: the Docker image recipe
(`Dockerfile`, `patches/`, `scripts/`, `support/`), the Python that runs
inside the container, and the PowerShell launchers (`setup.ps1`,
`preview.ps1`, `deploy.ps1`) all live in this repository. The Windows app's
job is the interface: the same behaviours as the macOS app, driving the
`.ps1` launchers instead of the `.sh` ones.

**The specification is [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md)** — 106
numbered entries, each describing a behaviour the macOS app has and each
carrying a Windows-porting note. Work through it top to bottom; it is the
product of a great deal of live testing and every entry earned its place.

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
- `deploy_target` ("netlify" default | "local_folder") and
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
- **Edit keys in place and preserve unknown keys** — the macOS app keeps
  the decoded JSON as a dictionary precisely so future toolchain keys
  survive a settings round-trip.

## Example content (entries 92–96)

Ready-made course payloads ship in `support/example_content/<CODE>/`
(eighteen as of 2026-08-13: ADA1O, ICD2O, ICS3U, ICS4U, MCR3U,
MCV4U, MDM4U, MHF4U, MPM2D, MTH1W, SCH3U, SCH4U, SNC1W, SNC2D, TEJ2O,
TEJ3M, TEJ4M, TGJ2O — SNC1W is the example course's content converted
to payload form, so a teacher actually teaching Grade 9 science gets
it as starting content; SNC2D is its Grade 10 sequel, and SCH3U/SCH4U
carry chemistry through Grades 11 and 12). All
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
`createdSectionN`/`draftSectionN` (one pair per section — entry 122), and
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
- **Updates**: WinSparkle, sharing the appcast Sparkle will use on macOS
  (deferred on both platforms until the first release).
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
  **5,694 files** as of 2026-08-13, and still growing. The `.sh`
  launchers spawned one `shasum` process per file (36s of a 36.75s
  preview startup on an M4 Pro); they now pipe
  `find -print0 | sort -z | xargs -0 shasum` and take 0.16s.
  `Get-ToolchainHash` in the three `.ps1` launchers had the quadratic
  version of the same bug: `$combined += (Get-FileHash …).Hash` inside
  the loop, and PowerShell strings are immutable, so every one of those
  thousands of appends reallocated a string heading for a third of a
  megabyte. They now collect into `$hashes` and `-join` once. Measure this
  when you test: on macOS the batched version hashes 5,694 files in 0.25s,
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
  arrives with `createdSectionN` / `draftSectionN` for each section the
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
`createdSectionN` / `draftSectionN` pair per section, and a section added
later needs its own pair or it builds those pages with no date and no
publishing state at all. macOS does this in
`SectionAdder.extendCourseLevelPages`: walk the course folder skipping the
`sectionN` directories, and for each markdown page whose FRONTMATTER
already uses the per-section form, append a fresh
`createdSection<new>` plus a `draftSection<new>` copied from the
lowest-numbered existing section. Leave pages with a plain `created:`
alone — they already apply to every section — and never read past the
frontmatter, because the site-tour page shows `draft: true` inside a code
block as documentation.

## The local assistant: run the model natively, not in a container

**Measured on macOS 2026-08-15, and the numbers are large enough that they are
worth acting on rather than filing.** `AI-ASSIST-HANDOFF.md` §2 records the
Windows engine's constraints — 4 GB, 2 cores, no GPU, ~21 tokens/second — and
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

Worth measuring before committing to it — a machine with no usable GPU falls
back to CPU and lands somewhere between the two columns, and that is worth
knowing rather than assuming. But the container is not buying anything here
that a host process does not, and it is costing three minutes.

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

The macOS build has no 3B rung as a result; the case was deleted from the enum
rather than marked risky, on the same reasoning as having no delete tool. If
Windows ever offers a model choice, measure each candidate for inversions
specifically, and treat that as a veto rather than a score.

| Model | Routing (like-for-like) | Inversions |
|---|---|---|
| 1.5B | 81% | none |
| 3B | 70% | **2 of 3 trials** |
| 7B | 94% | none |

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
- **Keep the five most recent per course**, pruned oldest-first, and prune
  ONLY the backups: archives and the wizard's own zips live in the same area
  and their parsers deliberately reject each other's forms.

### Restore is section-scoped, though the zip holds the course

The backup contains the whole course; a conversation is about one section. A
whole-course restore would silently revert work done in a sibling section
while the chat was open — a teacher may well have been editing Section 2 in
Obsidian while talking about Section 1. So Restore puts back only the
section the conversation was about, and says so on the button.

## Testing

- The **PowerShell launchers are written but UNTESTED on real Windows** —
  see [`WINDOWS-TESTING.md`](WINDOWS-TESTING.md). Test them first; they
  are the foundation everything else drives. Two flags are newer than
  any Windows test pass and need their own checks: `deploy.ps1
  --to-folder <path>` (robocopy mirror into `<path>\sectionN`, exit
  codes below 8 are success) and `preview.ps1 CODE N --stop` (kills the
  section's container-side processes over stdin-piped Python; must
  never start the engine or a container).
- `verify.sh` is the toolchain gate on macOS/Linux; a Windows verify
  script should mirror it, including its cross-check that every helper a
  launcher calls is defined in that same launcher file (a missing helper
  is exit 127 at runtime, on the one path nobody tests).
- Mirror the macOS test discipline: the unit suite runs without Docker;
  presentation regressions get press-and-look tests (entry 81's lesson:
  button logic can be perfect while its dialog never shows).

## Documentation map

- [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md) — THE spec (106 entries).
- [`documentation/`](documentation/README.md) — toolchain deep dives 01–09.
- [`DEVELOPERS.md`](DEVELOPERS.md) — repo conventions, testing, setup.
- [`WINDOWS-TESTING.md`](WINDOWS-TESTING.md) — .ps1 launcher status.
- [`mac-app/`](mac-app/README.md) — the reference implementation; when an
  entry's Windows note is thin, read the Swift it references.
