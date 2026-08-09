# Containerized Quartz for Teachers — macOS App

A native macOS app (Swift / SwiftUI) that wraps the command-line toolchain in
a friendlier interface. **The app contains no toolchain logic of its own**: it
edits the same `course_config.json` the setup wizard writes, and every action
runs the real scripts:

| In the app | What actually runs |
|---|---|
| Save (course settings) | Writes `course_config.json` — the file `build_site.py` reads on the next build |
| Preview (section) | `./preview.sh CODE N` under a pseudo-terminal; the site appears in an embedded web view once `localhost:8081` responds |
| Deploy (section) | `./deploy.sh CODE N` with streamed output (and an input field for prompts like the first-time Netlify token) |
| New Course | Writes the chosen settings as `course_config.json`, then runs the real `./setup.sh`, answering each prompt with its default (typing the course code where needed) — scaffolding, backups, and Quartz patches all come from the actual wizard |

On first launch the app asks for your **working folder** — the one you use
with the command-line toolchain (containing `setup.sh`, `preview.sh`,
`deploy.sh`, and `courses/`) — and remembers it.

## Building

Requires Xcode 26+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`). The Xcode project file is generated, not committed:

```bash
cd mac-app
xcodegen generate
open QuartzTeachers.xcodeproj    # or: xcodebuild -scheme QuartzTeachers build
```

## Testing

Three layers, matching how much environment each needs:

```bash
# 1. Unit tests (fast, no Docker): config round-trip, transcript handling
xcodebuild -project QuartzTeachers.xcodeproj -scheme QuartzTeachers test \
  -only-testing:QuartzTeachersTests/CourseConfigurationTests \
  -only-testing:QuartzTeachersTests/TranscriptBuilderTests

# 2. In-process UI walk-through (drives the real window, saves screenshots,
#    verifies the sidebar via the accessibility tree; needs a fixture folder)
TEST_RUNNER_UITEST_WORKSPACE=/path/to/fixture \
TEST_RUNNER_UITEST_SCREENSHOT_DIR=/tmp/shots \
xcodebuild -project QuartzTeachers.xcodeproj -scheme QuartzTeachers test \
  -only-testing:QuartzTeachersTests/InAppUserInterfaceTests

# 3. CLI-equivalence integration tests (need Docker/Colima and the repo
#    workspace; build results are compared against command-line runs)
TEST_RUNNER_INTEGRATION_WORKSPACE=/path/to/repo \
xcodebuild -project QuartzTeachers.xcodeproj -scheme QuartzTeachers test \
  -only-testing:QuartzTeachersTests/ScriptRunnerIntegrationTests \
  -only-testing:QuartzTeachersTests/NewCourseCreatorIntegrationTests
```

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
- The colour scheme picker's choices come from the repository's own
  `support/colour_schemes.json`, bundled as a resource at build time.
