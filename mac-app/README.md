# Plantoir — the macOS App for Containerized Quartz for Teachers

A native macOS app (Swift / SwiftUI) that wraps the command-line toolchain in
a friendlier interface. **The app contains no toolchain logic of its own**: it
edits the same `course_config.json` the setup wizard writes, and every action
runs the real scripts:

| In the app | What actually runs |
|---|---|
| Save (course settings) | Writes `course_config.json` — the file `build_site.py` reads on the next build |
| Preview (section) | `./preview.sh CODE N --port P` under a pseudo-terminal; the site appears in an embedded web view once the announced address responds (up to four sections per folder at once, ports leased per window) |
| Deploy (section) | `./deploy.sh CODE N` with streamed output (and an input field for prompts like the first-time Netlify token) |
| New Course | Writes the chosen settings as `course_config.json`, then runs the real `./setup.sh`, answering each prompt with its default (typing the course code where needed) — scaffolding, backups, and Quartz patches all come from the actual wizard |

A window without a folder asks for a **working folder** — one containing
`setup.sh`, `preview.sh`, `deploy.sh`, and `courses/`, or an empty folder
the app offers to initialize. Working folders are **per window**: each
window restores its own folder across relaunches (frame-keyed), and a new
window inherits the folder of the window that was key when it was opened —
or shows the picker when it is the only window.

The app also owns delivery and resources: it mirrors the full toolchain
recipe into each working folder's `.toolchain/` (refreshing stale
launchers from its bundle), self-installs missing host tools to
`~/Library/Application Support/Plantoir/tools`, runs one container per
working folder (stopped when the folder's last window closes and at
quit), and stops Colima at quit only when nothing else runs in it.
Additional actions: Add Section (course context menu), Open in Obsidian
(vault registration included), an Archived sidebar group with restore,
per-section settings for grade-in-title (with a repetition warning) and a
custom domain, and a custom About panel with the Icon Composer app icon.
The complete behavioural log is `../GUI-IMPROVEMENTS.md`.

## Building

Requires Xcode 26+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). The Xcode project file is generated, not committed:

```bash
cd mac-app
xcodegen generate
open Plantoir.xcodeproj    # or: xcodebuild -scheme Plantoir build
```

## Testing

Three layers, matching how much environment each needs:

```bash
# 1. Unit tests (fast, no Docker): config round-trip, transcript handling
xcodebuild -project Plantoir.xcodeproj -scheme Plantoir test \
  -only-testing:QuartzTeachersTests/CourseConfigurationTests \
  -only-testing:QuartzTeachersTests/TranscriptBuilderTests

# 2. In-process UI walk-through (drives the real window, saves screenshots,
#    verifies the sidebar via the accessibility tree; needs a fixture folder)
TEST_RUNNER_UITEST_WORKSPACE=/path/to/fixture \
TEST_RUNNER_UITEST_SCREENSHOT_DIR=/tmp/shots \
xcodebuild -project Plantoir.xcodeproj -scheme Plantoir test \
  -only-testing:QuartzTeachersTests/InAppUserInterfaceTests

# 3. CLI-equivalence integration tests (need Docker/Colima and the repo
#    workspace; build results are compared against command-line runs)
TEST_RUNNER_INTEGRATION_WORKSPACE=/path/to/repo \
xcodebuild -project Plantoir.xcodeproj -scheme Plantoir test \
  -only-testing:QuartzTeachersTests/ScriptRunnerIntegrationTests \
  -only-testing:QuartzTeachersTests/NewCourseCreatorIntegrationTests
```

> **Tip:** stop any copy of the app running under Xcode's debugger (⏹)
> before running the UI tests — a debugged instance cannot be terminated
> by the test runner, which fails the first UI test with
> "Failed to terminate ca.russellgordon.Plantoir".

There is also a conventional **XCUITest** suite (`QuartzTeachersUITests`)
that drives the app with synthesized clicks. Running it requires a one-time
macOS approval: the first run fails with "Timed out while enabling automation
mode" until you allow it under **System Settings → Privacy & Security →
Automation/Accessibility** (macOS prompts on first attempt from a logged-in
session). The in-process suite above covers the same flows without that
requirement.

## Design notes

- `CourseConfiguration` keeps the decoded JSON as a dictionary and edits
  keys in place, so config keys added by future toolchain versions survive a
  GUI round trip untouched (verified by unit test).
- Scripts run attached to a real PTY (`PseudoTerminal` + `ScriptRunner`)
  because `docker exec -it` requires a terminal; output is cleaned for
  display by `TranscriptBuilder` (ANSI stripping, spinner collapsing —
  and note `\r\n` handling is scalar-based because Swift folds `"\r\n"`
  into a single `Character`).
- The New Course flow (`NewCourseCreator`) is deliberately "the wizard with
  every answer pre-filled": the app writes the config first, and the real
  wizard re-reads it as saved defaults, so a plain Return accepts each
  prompt. The one exception — the course-code prompt — is answered
  explicitly.
- What a new course STARTS as is decided from bundled resources too:
  `ExampleContentCatalog` looks for `support/example_content/<CODE>/`, and
  failing that `SkeletonCatalog` maps the code's three-letter prefix through
  `support/skeletons/families.json` to one of fifty subject families. The
  sheet then offers that subject's folders as the default list — a music
  course opens with Repertoire, a chemistry course with Investigations. Two
  pure functions carry the rules worth knowing:
  `SkeletonCatalog.structureToAdopt` (never overwrite a list the teacher has
  edited) and `SkeletonCatalog.sidebar` (curriculum hidden, every other
  shared folder gets a chevron, per-section folders stay plain links).
- The colour scheme picker's choices come from the repository's own
  `support/colour_schemes.json`, bundled as a resource at build time — and
  the font previews register the TTFs from `support/fonts/`, the same
  files the container draws social sharing cards with (one font source
  for both).
