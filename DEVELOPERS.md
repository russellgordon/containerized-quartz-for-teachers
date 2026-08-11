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

First-run bootstrap: if Docker isn't available, the launchers download
pinned static binaries (Colima, Lima, the Docker CLI, buildx) into
`~/Library/Application Support/Plantoir/tools` — no Homebrew, no admin
rights. The image itself lives inside the Colima VM's disk (`~/.colima`).

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

Adding a new course code is pure content: drop in a payload, no code
changes. The wizard (CLI and app) discovers it by the manifest's existence.

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

**App changes**: the unit suite is fast and needs no Docker:

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
  ("Building your website builder…", "Getting this Mac ready…").
- **`GUI-IMPROVEMENTS.md` logs every GUI behaviour change** as a numbered
  table row, each with a Windows-porting note. It is the spec for the future
  Windows app — keep it current when changing app behaviour.
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
- [`WINDOWS-TESTING.md`](WINDOWS-TESTING.md) — status of the (untested)
  PowerShell launchers.
- [`mac-app/README.md`](mac-app/README.md) — building and testing the app,
  design notes.
