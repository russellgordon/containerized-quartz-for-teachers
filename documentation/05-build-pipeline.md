# 5. The Build Pipeline (`build_site.py`)

[◀ Previous: Course Setup](04-course-setup.md) · [Back to index](README.md) · [Next: Quartz Customizations ▶](06-quartz-customizations.md)

`scripts/build_site.py` (2,300+ lines) is the engine of the toolchain. Given
a course code and section number, it assembles a complete, customized Quartz
site at `courses/<CODE>/.merged_output/section<N>/` and either serves it
(preview mode, the default) or builds it statically (`--build-only`, used by
deploy).

```
course_config.json ─┐
shared folders ─────┤                       ┌─▶ preview: quartz build --serve :8081
section<N>/ ────────┼─▶ .merged_output/section<N>/ ─┤
patched Quartz ─────┤        (scaffold + content)   └─▶ deploy:  quartz build → public/
support files ──────┘
```

## Stage 1: Validation and preflight discovery

After checking that the course, section folder, and `course_config.json`
exist, and that the requested section is one of the course's
`section_numbers`, the script performs **preflight discovery**:

<a name="preflight-discovery"></a>

It scans the course root and section folder for top-level folders/files that
are *not yet listed* in `course_config.json` and appends them (add-only —
nothing is ever removed automatically). Newly discovered folders are marked
visible and expandable by default. The updated config is written atomically
with a `course_config.backup.json` safety copy.

**Rationale:** teachers create folders in Obsidian mid-course. Without
discovery, every new folder would require re-running the setup wizard;
with it, the folder just shows up on the next preview. Reserved names
(`Media`, `.obsidian`, `.merged_output`, `node_modules`, `course_config.json`,
OS junk files) are excluded from discovery.

## Stage 2: Scaffold management

The output folder `.merged_output/section<N>/` is created on first build (or
wiped and recreated with `--full-rebuild`) by copying everything from
`/opt/quartz` — the pinned v4.5.0 checkout that already carries the
[image-level patches](06-quartz-customizations.md#a-components-replaced-at-image-build-time)
and [setup-time patches](06-quartz-customizations.md#b-patches-applied-at-setup-time-to-the-scaffold).

On a fresh scaffold, the script immediately applies the **first-build
patches** (Graph removal, locales, date-handling config, folder-page
behaviour, date format, styles, transclusion support, fonts — all enumerated
in [customizations §C1](06-quartz-customizations.md#c1-applied-on-first-build--full-rebuild)).
On subsequent builds the scaffold (including its `node_modules`) is reused
for speed, and only the **every-build patches**
([§C2](06-quartz-customizations.md#c2-applied-on-every-build)) run — these
are the ones driven by settings a teacher might change between builds
(colour scheme, footer, title, locale, reading time, Explorer behaviour,
hidden list).

All patches are **idempotent**: each one detects "already applied" and does
nothing, so running the build repeatedly is safe.

> **Why `tee`?** Many patch functions write files via
> `subprocess.run(["tee", path], input=…)` rather than Python file writes.
> This is a defensive choice from debugging bind-mount write issues —
> `tee` reports failures loudly and behaves consistently on the mounted
> filesystem.

## Stage 3: Content assembly

The `content/` folder inside the output is **deleted and rebuilt from
scratch on every build** — content is cheap to copy, and this guarantees
deletions and renames in the vault propagate.

<a name="media-handling"></a>

1. **Media symlink.** `content/Media` is created as a *relative symlink* to
   the course-level `Media/` folder rather than a copy. Media is the largest
   folder in a course (images, video); with, say, three sections, copying
   would quadruple disk usage and slow every build. A symlink means zero
   copies and instant availability. (`Media` is also forced into the hidden
   list so it never appears in the sidebar.)
2. **Section home page.** `section<N>/index.md` is copied to
   `content/index.md` — the site's front page.
3. **Shared folders and files** are copied in, preserving structure.
4. **Per-section folders and files** are copied from `section<N>/`.

During copying, every Markdown file passes through two transformations:

<a name="frontmatter-processing"></a>

### Frontmatter processing (the multi-section trick)

For the section being built (say section 3), each file's frontmatter is
rewritten:

- `draftSection3` → `draft` (and `createdSection3` → `created`)
- *All* `draftSectionN`/`createdSectionN` keys are then deleted.

So a shared file marked `draftSection1: false, draftSection3: true` is
published on Section 1's site but excluded (Quartz omits `draft: true` pages
entirely) from Section 3's — one file, independent publication state per
section. This mechanism is why the workshop "quest" about a missing
*Thread 2, Day 11* page has the answer it does: the page was still marked
draft for that section.

### Wikilink rewriting

In Obsidian, a link from shared content into section content looks like
`[[section2/All Classes/Thread 2, Day 8|Thread 2, Day 8]]`. In the built
site there is no `section2/` prefix — the section's content *is* the site
root. The build rewrites any aliased wikilink whose target contains a
`section<digits>/` path down to its alias: `[[Thread 2, Day 8]]`. Quartz
then resolves it by file name, which works because that file was copied into
the content tree. (The same is done for transclusions, `![[…]]`.)

<a name="dates-drive-everything"></a>

### Curriculum date synchronization

Pages listing folder contents in Quartz sort by date, and this toolchain
[configures dates to mean *created*](06-quartz-customizations.md#c1-applied-on-first-build--full-rebuild)
(from frontmatter, never from git). Curriculum-expectation pages are written
once at course setup and never touched again, which would leave them sorted
to the bottom of list pages forever. The build therefore finds the **newest
`created` timestamp anywhere in the section's content**, then bumps every
file inside any folder whose name contains "curriculum" up to that
timestamp (only if older). Curriculum pages thus float alongside current
content without the teacher ever editing them.

## Stage 4: Configuration patching

The remaining per-section settings from `course_config.json` are applied to
the scaffold: the sidebar omit set, folder click behaviour, footer HTML,
page title (emoji + course code or custom label + optional `S<N>` marker),
locale, per-section colour scheme, and the social-media-preview emitter
toggle. Each is detailed in
[customizations §C2](06-quartz-customizations.md#c2-applied-on-every-build).

Additionally, `course_config.json` itself is copied to
`<output>/quartz/course_config.json` and the patched Explorer components'
import paths are pointed at it — the Explorer *reads course configuration at
site-build time* to know which folders are expandable.

## Stage 5: Dependencies and the actual Quartz build

- `npm install` runs only when needed: missing `node_modules`, missing/stale
  `package-lock.json`, or `--force-npm-install`.
- The environment sets `TZ=UTC` and a fixed `SOURCE_DATE_EPOCH`
  (2024-01-01), nudging build tooling toward reproducible output —
  part of the [determinism strategy](07-deployment.md#why-determinism-matters)
  that keeps Netlify uploads small.
- **Preview mode (default):** kills any process holding port 8081 (`lsof`),
  then runs `npx quartz build --concurrency 1 --serve --port 8081`. The
  teacher browses `http://localhost:8081`; Quartz rebuilds on file changes.
- **Build-only mode:** `npx quartz build --concurrency 1`, then verifies
  `public/` exists. This is the path `deploy` uses.

> **Why `--concurrency 1`?** Quartz's parallel transpile workers can stall
> or crash silently inside a resource-constrained Docker container. A serial
> build is modestly slower but reliable.

---

[◀ Previous: Course Setup](04-course-setup.md) · [Back to index](README.md) · [Next: Quartz Customizations ▶](06-quartz-customizations.md)
