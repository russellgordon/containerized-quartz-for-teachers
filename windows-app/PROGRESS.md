# Plantoir for Windows — Progress

First take built overnight 2026-08-11 by Claude Code, per
[`WINDOWS-HANDOFF.md`](../WINDOWS-HANDOFF.md). Everything below was
**verified live on the maintainer's Windows 11 machine** (WSL2 +
Ubuntu-24.04 + Docker Engine 29, no Docker Desktop) unless marked
otherwise.

## Layout

| Project | Role |
|---|---|
| `Plantoir/` | The WinUI 3 app (unpackaged, self-contained Windows App SDK, PerMonitorV2 DPI). Bundles the full toolchain recipe under `Toolchain/` and mirrors it into each working folder's `.toolchain/`. |
| `Plantoir.Core/` | All logic, UI-free: config round-trip, container naming, port leases, build freshness, archiver/restorer, section adder, ConPTY process, transcript builder, script runner, milestones, question parsing, failure explainer, catalogs, workspace/toolchain services. |
| `Plantoir.Tests/` | xUnit suite (154 tests) that runs **without Docker**: `dotnet test`. Classes touching process-wide state (preview leases, the publish registry) share a serialized collection — see `SharedActivityState`. |
| `PtyDriver/` | Console harness that drives the launchers under a ConPTY with scripted prompt replies — how the E2E runs below were performed. |

## Proven end to end

- **Launchers on real Windows** (after the fixes in the repo-root
  commits): `setup.ps1 --install-example` (image built locally from the
  recipe, per-folder container created with a `/mnt/c` mount, EXC2O
  installed), `preview.ps1 EXC2O 1` (site served; HTTP 200; the
  announced `Preview will be available at:` line parsed), and
  `deploy.ps1 EXC2O 1` (token from Windows Credential Manager, Netlify
  site created, 233 files uploaded with streaming counts, live over
  https).
- **The app itself**: launched → folder picker (all four states) →
  sidebar with EXC2O and sections → section view → **Preview built and
  embedded the live site in the app's WebView2**, via the app's own
  ConPTY runner. **Deploy runs entirely inside the app**: a repeat
  publish of EXC2O section 1 reached "Uploading your pages… 25 of 230"
  at Step 7 of 8 and the site went live over https — the upload count
  parsed straight from the launcher output. All screenshot-verified.
- **The wizard's answer pump** was driven against the real
  `setup_course.py` end to end (Enter for every prompt including the
  raw arrow-key colour picker): the interactive flow completed exit 0
  and scaffolded a full course (shared folders, per-section files,
  two section folders). This is the same `NewCourseCreator.PumpAnswers`
  the Create Course button uses.

## The hard-won platform lessons (do not relearn these)

1. **ConPTY std-handle hygiene.** A process whose own stdio is
   redirected leaks stale pipe handles into its pseudo-console child;
   `wsl.exe` then reports "the input device is not a TTY" and every
   interactive `docker exec -it` fails. A GUI app is naturally clean.
   Test harnesses must be launched with their own console
   (ShellExecute / `Start-Process`), never with redirected stdio.
2. **ConPTY soft-wrap duplication.** Re-rendered wrapped lines arrive
   with the boundary character doubled. The runner uses a 400-column
   pseudo console so no real line wraps.
3. **PowerShell 5.1 + `$ErrorActionPreference='Stop'` + wsl stderr.**
   Any redirected call site (`*> $null`) wraps wsl's stderr lines into
   terminating ErrorRecords. The launchers' global `docker` wrapper
   relaxes the preference around the wsl call.
4. **Container-name parity.** Everything hashes the folder's PHYSICAL
   path (true on-disk casing via `GetFinalPathNameByHandle`, symlinks
   resolved) plus `"\n"`, SHA-256, first 8 hex — `FolderContainers`
   in Core and all three launchers agree byte for byte.

## Spec coverage (GUI-IMPROVEMENTS.md)

Implemented in this first take: the workspace picker states (13, 14,
15, 17, 85), sidebar with footer +/− and filter (23, 52, 58), archive/
restore (54, 55), stable toolbar + one-face-changing Preview button
(19, 24), progress/milestones/step counts (16, 21, 22, 26, 51),
question dialogs with lifted defaults and cancel tokens (30–35),
finished-state link with custom-domain swap (32, 38, 87), stopped ≠
failed (39, 40), failure explanations (36), console discipline (18,
27), preview server gating and 127.0.0.1 hand-off (11), port leases
(66), per-folder containers + quit-time release (67, 69), launcher/
toolchain refresh (68, 71), settings forms with the shared vocabulary
(1–9), grade-in-title literal switch + warning (89), Revert (90), the
wizard with the example-course panel (41, 43) and validation (70),
Add Section (74, 86), Obsidian integration (80), window memory (59–65
as the app-owned list Windows needs), About (82).

Not yet: bundled-font *registration* for previews beyond per-path
FontFamily references (2 — works via `path#family`), UIA press-and-look
regression tests (52, 81), WinSparkle (deferred on both platforms),
several polish rounds that need human eyes on real hardware.

## Known rough edges for the next session

- The toolbar can truncate at narrow widths; no window min-size clamp
  is enforced yet (900×600 is only the default).
- The Preview menu (Alt+Left/Right/Ctrl+R accelerators) is not yet a
  separate menu; Back/Forward/Reload live on the toolbar only.
- The wizard's Create button was not click-driven in-app (it needs a
  code typed and a click), but its underlying `setup.ps1` + answer-pump
  path was proven live to completion via PtyDriver. A first true
  in-app click-through is the natural next check.
- Deploying a BRAND-NEW section prompts for a site name; the "Input
  required" dialog now fires for it (the first attempt exposed and
  fixed the re-binding bug), but the new-site dialog path itself has
  not yet been click-confirmed in-app — the verified deploy was a
  repeat publish to an existing site.
- `--auto-select CODE N` / `--auto-preview CODE N` /
  `--auto-deploy CODE N` are smoke-test hooks that drive the real
  button code paths.
