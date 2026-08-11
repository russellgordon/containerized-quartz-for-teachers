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

**The specification is [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md)** — 90
numbered entries, each describing a behaviour the macOS app has and each
carrying a Windows-porting note. Work through it top to bottom; it is the
product of a great deal of live testing and every entry earned its place.

## The three load-bearing rules

1. **The GUI never mentions the machinery.** No "toolchain", "script",
   "Docker", "container", or "WSL" in user-facing text. Plain words:
   "Building your website builder…", "Getting this Mac ready…" (yours will
   say "this PC").
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
- **Edit keys in place and preserve unknown keys** — the macOS app keeps
  the decoded JSON as a dictionary precisely so future toolchain keys
  survive a settings round-trip.

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
  discarded on a vault's first open — verified).
- **Window restoration** (entries 64–65): keep per-window state in the
  app's own store, keyed by something the platform restores faithfully.
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

## Testing

- The **PowerShell launchers are written but UNTESTED on real Windows** —
  see [`WINDOWS-TESTING.md`](WINDOWS-TESTING.md). Test them first; they
  are the foundation everything else drives.
- `verify.sh` is the toolchain gate on macOS/Linux; a Windows verify
  script should mirror it, including its cross-check that every helper a
  launcher calls is defined in that same launcher file (a missing helper
  is exit 127 at runtime, on the one path nobody tests).
- Mirror the macOS test discipline: the unit suite runs without Docker;
  presentation regressions get press-and-look tests (entry 81's lesson:
  button logic can be perfect while its dialog never shows).

## Documentation map

- [`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md) — THE spec (90 entries).
- [`documentation/`](documentation/README.md) — toolchain deep dives 01–09.
- [`DEVELOPERS.md`](DEVELOPERS.md) — repo conventions, testing, setup.
- [`WINDOWS-TESTING.md`](WINDOWS-TESTING.md) — .ps1 launcher status.
- [`mac-app/`](mac-app/README.md) — the reference implementation; when an
  entry's Windows note is thin, read the Swift it references.
