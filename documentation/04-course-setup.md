# 4. Course Setup (`setup_course.py`)

[◀ Previous: Launcher Scripts](03-launcher-scripts.md) · [Back to index](README.md) · [Next: The Build Pipeline ▶](05-build-pipeline.md)

`scripts/setup_course.py` (run inside the container by `setup.sh`) is an
interactive wizard. It has two jobs: **scaffold the course folder structure**
that Obsidian will edit, and **record every choice in
[`course_config.json`](08-course-config-reference.md)** for the build script
to consume. It is *stateful*: re-running it on an existing course pre-fills
every prompt with the previous answers, so it doubles as a "settings editor".

## Flow, step by step

### 0. Offer the example course

Before anything else, the wizard offers to install the **EXC2O Example
Course** ("Example Course", Grade 10 Open — a plausible Ontario course code)
from `/opt/support/example_course/`. If accepted, it copies the whole course
(content, `.obsidian` settings, and a filled-in `course_config.json` with two
sections) into `/teaching/courses/`, applies the two on-image Quartz patches
(below), prints the preview command, and exits. If a course named `EXC2O`
already exists, it generates a random alternative code still ending in `2O`
(e.g. `KQX2O`) so a teacher can install multiple sandboxes.

### 1. Course identity

- Prompts for the **course code** (default `ICS3U`), uppercased.
- Looks the code up in `ontario_secondary_courses.json` (1,930 entries) and
  offers the formal name ("Introduction to Computer Science, Grade 11,
  University Preparation"), the short name ("Introduction to Computer
  Science"), or a custom name.
- **Club support**: if the 4th character of the code is not a digit (course
  codes like `ICS3U` encode grade in position 4; a club might be `CODING`),
  the wizard offers a **custom short label** (≤ 12 characters) to display in
  the site header instead of the uppercased code, and omits the
  "Grade N" prefix from the generated home-page title.

### 2. Safety: automatic backup

If the course folder already exists and `--no-backup` was not given, the
entire course is zipped to `courses/_backups/<CODE>/<timestamp>.zip` *before
any mutation*, excluding caches and generated output (`node_modules`,
`.merged_output`, `.git`, etc.). This makes the wizard safe to re-run.

### 3. Course-level conventions

- Ensures a **`Media/` folder** at the course root. This is the designated
  home for binary assets (screenshots, videos, PDFs). It is special-cased
  throughout the toolchain: always shared, always hidden from the site
  sidebar, never copied (it is symlinked into the build,
  [see why](05-build-pipeline.md#media-handling)), and the wizard refuses to
  let it appear in any folder list.
- Seeds **Obsidian defaults** (`support/obsidian_defaults/.obsidian/`) into
  the course folder *without overwriting existing files*. The important
  setting is `attachmentFolderPath: "Media"` — a screenshot pasted into
  Obsidian is saved to the shared `Media/` folder automatically. It also
  ships the Minimal theme and disables live preview.

### 4. Appearance and localization (all per-section where sensible)

- **Locale**: choice of the 27 locales Quartz supports, presented with
  human-readable names and flags. Stored as e.g. `"locale": "en-GB"` and
  applied to `quartz.config.ts` at build time (affects UI strings and date
  formatting).
- **Colour scheme per section**: a full-screen interactive picker (raw
  terminal mode, arrow keys) that renders live swatches of all nine theme
  colours in light and dark mode using 24-bit ANSI escape codes — this is
  why the main README recommends iTerm2 over Apple's Terminal. The 43
  schemes come from `support/colour_schemes.json`. Different sections get
  different schemes so a teacher (and their students) can tell sections
  apart at a glance.
- **Fonts**: a curated list of six Google-Font header/body pairings plus
  system-font and custom options, and six monospaced code fonts. Choices are
  stored under a course-wide `default` with per-section overrides.
- **Header emoji per section** and **section marker visibility per section**
  (whether the header reads "📚 ICS3U S1" or just "📚 ICS3U").

### 5. Content structure

The wizard then asks which folders/files exist and how they behave:

- **Shared folders** (default: Concepts, Discussions, Examples, Exercises,
  Ontario Curriculum, Recaps, Setup, Style, Tasks, Tutorials, …) — content
  common to all sections.
- **Shared files** — loose Markdown files common to all sections.
- **Per-section folders** (default: "All Classes" — the day-by-day lesson
  log) and **per-section files** (e.g. "Key Links.md") — these exist
  separately inside each `section<N>/` folder.
- **Hidden items** — folders/files to omit from the site's sidebar
  (Explorer). Hidden ≠ unpublished: pages in hidden folders still build and
  are reachable via links and search; they just do not clutter navigation.
  Curriculum folders and private notes default to hidden.
- **Expandable items** — folders that behave as *expandable trees* in the
  sidebar. Non-expandable folders render as plain links to the folder's
  index page. This distinction drives the patched Explorer component
  ([customizations §A](06-quartz-customizations.md#a-components-replaced-at-image-build-time)).
- **Explorer click behaviour** — whether clicking a folder *name* expands it
  (chevron-and-name) or navigates to it (chevron-only expansion).
- **Footer HTML** — optional raw HTML (e.g. a CC-BY licence notice) injected
  into every page's footer at build time.
- **Reading-time estimates** — whether pages show "N min read".

### 6. Timetable sections

The wizard asks how many sections the teacher has **and which timetable
numbers they are** (e.g. a teacher with sections 1, 3, and 4 enters `1,3,4`).
Folders `section1/`, `section3/`, `section4/` are created; `section2` simply
never exists. All later commands validate the section argument against this
list.

### 7. Scaffolding written to disk

For each **shared folder**: the folder plus an `index.md` whose frontmatter
contains *per-section* draft and creation keys:

```yaml
---
title: Examples
createdSection1: 2025-09-02T08:30:00.000-0400
draftSection1: false
createdSection3: 2025-09-02T08:30:00.000-0400
draftSection3: false
---
```

This `<key>Section<N>` convention is the heart of multi-section publishing:
one physical file carries independent publication state for every section,
and the build for section N collapses `draftSectionN`/`createdSectionN` into
the plain `draft`/`created` keys Quartz understands
([details](05-build-pipeline.md#frontmatter-processing)). Timestamps use the
host's timezone offset (passed in as `HOST_TZ_OFFSET`).

For each **section**: `section<N>/` with an `index.md` (site home page,
titled e.g. "Grade 11 Introduction to Computer Science, Section 1") and the
per-section folders/files, each with plain `created`/`draft` frontmatter
(no `SectionN` suffix needed — the file already belongs to exactly one
section).

### 8. Patch the in-container Quartz scaffold

Finally, the wizard applies two idempotent patches to the pristine Quartz
checkout at `/opt/quartz` (the template that every build copies from):

1. **Explorer omit anchor** — replaces `Component.Explorer()` in
   `quartz.layout.ts` with a configured call containing a `filterFn` and a
   marked line (`// CQ4T-OMIT-ANCHOR`) declaring `const omit = new Set([...])`.
   At build time, `build_site.py` rewrites this set with the course's hidden
   items. The anchor comment makes the rewrite target unambiguous.
2. **OverflowList stable ID** — replaces `const id = randomIdNonSecure()`
   with a constant in `OverflowList.tsx`, so rebuilt pages do not differ
   just because a random DOM id changed (fewer files re-uploaded on deploy).

Both are described fully in
[customizations §B](06-quartz-customizations.md#b-patches-applied-at-setup-time-to-the-scaffold).

---

[◀ Previous: Launcher Scripts](03-launcher-scripts.md) · [Back to index](README.md) · [Next: The Build Pipeline ▶](05-build-pipeline.md)
