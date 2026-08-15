---
name: mac-app
description: Working on the macOS app (mac-app/) — build it so Russell can run it on this Mac, and tell him exactly what he must do to see the change (clean build, new course, new working folder, or nothing). Use for any change under mac-app/, and for toolchain changes the app carries.
---

# Iterating on the macOS app

Russell tests by **running the app on this Mac**, not by reading a diff and
not inside Xcode's test runner. So a change is not delivered until the app is
built and he has been told, in one line, what he has to do to see it.

Two things are always his to do and never yours: **launching the app** and
**deciding when to quit a copy he has open**. Everything else — building,
cleaning, clearing stale state — do it and say you did.

## Every iteration ends the same way

1. **Build it.**
   ```bash
   cd mac-app && xcodegen generate && \
     xcodebuild -project Plantoir.xcodeproj -scheme Plantoir \
       -destination 'platform=macOS' build
   ```
   `xcodegen` first, always: the project file is generated and NOT committed,
   so a new file exists for the compiler only after it runs.

2. **Run the unit tests**, which are fast and worth having every time:
   ```bash
   xcodebuild -project Plantoir.xcodeproj -scheme Plantoir \
     -destination 'platform=macOS' -only-testing:QuartzTeachersTests test
   ```

3. **Tell him it is ready, where it is, and what he must do.** The app lands at
   `~/Library/Developer/Xcode/DerivedData/Plantoir-*/Build/Products/Debug/Plantoir.app`.
   Give him the `open` command. If a copy is already running it keeps running
   the OLD build — say so, and let him quit it.

The one-line summary is the part that saves him time. It is one of:

> Ready to run — just open it, no other setup.
> Ready — but quit the running copy first, then open it.
> Ready — you will need a NEW COURSE (code XYZ) to see this.
> Ready — you will need a NEW WORKING FOLDER to see this.

## When a clean build is required

A plain rebuild misses some things, and the symptom is always the same:
your change is definitely in the source and definitely not in the app.

Clean when you have changed:

- **`project.yml`** — build settings, or which files are bundled.
- **anything inside a FOLDER-REFERENCE resource.** `Vendor/llama` is copied
  as a whole folder (`type: folder`), and Xcode does not notice when its
  CONTENTS change. Re-running `Vendor/fetch-llama.sh` and rebuilding gets you
  the old binaries.
- **bundled toolchain files** the app carries — `../scripts`, `../support`,
  `../patches`, `../Dockerfile`, the three `../*.sh` launchers. These are
  resources; a stale copy in the bundle is a very confusing hour.

```bash
cd mac-app && xcodebuild -project Plantoir.xcodeproj -scheme Plantoir clean && \
  xcodegen generate && xcodebuild -project Plantoir.xcodeproj -scheme Plantoir \
    -destination 'platform=macOS' build
```

If that still misbehaves, remove the DerivedData folder for the project and
build again. Say that you did — it costs him a slow first build.

## When he needs a NEW COURSE

Anything installed **at course creation** only reaches a course made
afterwards. An existing course keeps the shape it was born with.

Tell him to make a new course when you changed:

- **`support/example_content/<CODE>/`** — the payload is poured in at
  creation. Name the CODE he should use, because only that code shows it.
- **`support/skeletons/`** — same, but for any code with no payload; name a
  code that has none (e.g. `AVI2O`).
- **`scripts/setup_course.py`** — folders, per-section files, sentinels,
  dates, anything the installer writes.
- **new `course_config.json` keys written by the wizard.** Alternatively he
  can hand-edit the JSON of a course he already has, which is quicker — offer
  that if it is one key.

He does NOT need a new course for:

- **`scripts/build_site.py`** — that runs at every build, so previewing an
  existing course shows it.
- **the assistant, the sidebar, settings, deploys, previews** — all read the
  course as it is.

## When he needs a NEW WORKING FOLDER

Rarely, and it is worth being sure before asking — it means recreating
courses. The launchers and `.toolchain/` are **refreshed automatically** in
any folder the app opens (`refreshLaunchersIfNeeded` / `refreshToolchain`),
so changing a `.sh` or the image recipe does **not** need one.

Only ask for a new folder when testing:

- **first-run adoption** — the picker, initialising an empty folder, what a
  brand-new folder gets.
- **per-folder behaviour itself** — container naming, the port block, two
  folders open at once.

## Other state that hides a change

Ordinary rebuilding does not clear these. Clear them yourself and say so.

| Changed | Clear |
|---|---|
| Model tier, download URL or size | `rm -rf ~/Library/Application\ Support/Plantoir/models` — otherwise the OLD weights are found and the new tier never downloads |
| Plan mode's "stop asking" answer | `defaults delete ca.russellgordon.Plantoir AssistPlanModeTurnedOff` |
| Scheduled deploys | `launchctl bootout gui/$(id -u)/ca.russellgordon.Plantoir.deploy.<CODE>.section<N>` and delete the plist in `~/Library/LaunchAgents` |
| Colima's CPU/RAM sizing | Sizing applies when the VM is CREATED, or on a start while it is stopped. `colima stop` then start, or `colima delete` for a clean one. **Ask first** — it is shared with his other toolchains |
| The Docker image | Rebuilt automatically when the recipe hash changes. `./verify.sh` forces the whole path |

## Running the tests without chasing ghosts

- **UI tests need the machine to themselves.** Two `xcodebuild test` runs at
  once make the harness see two app processes and fail with
  "Root elements for target … should be equal". If agents are running builds,
  wait for them. Run UI tests alone:
  `-only-testing:QuartzTeachersUITests`.
- **A stray preview server fails the preview tests.** `python3 -m http.server
  8081` left over from earlier work holds the port; `pkill -f "http.server"`.
- **`verify.sh` needs a terminal**: `script -q /dev/null ./verify.sh`.
- Do not report a UI-test failure as real until it has been run alone on a
  quiet machine. That mistake has been made here before.

## Things that are easy to get wrong

- **`Vendor/llama` is not committed.** A fresh clone must run
  `mac-app/Vendor/fetch-llama.sh` once or the assistant reports its engine is
  missing. The app still builds and runs without it.
- **The assistant's model is not bundled** — it downloads to Application
  Support on first use. Changing the tier means the old file is still there
  under its own name; see the table above.
- **A conversation's undo dies with its window**, and Restore only reaches
  back to the start of that conversation. When asking him to test either, say
  which window to keep open.
- **Every measurement in the assistant's documentation came from this
  48 GB M4 Pro.** Anything about memory pressure on an 8 GB Mac is unverified
  — say so rather than implying it was tested.
