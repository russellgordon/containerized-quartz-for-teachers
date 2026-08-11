# 6. Quartz Customizations — the Complete List

[◀ Previous: The Build Pipeline](05-build-pipeline.md) · [Back to index](README.md) · [Next: Deployment ▶](07-deployment.md)

This document enumerates **every deviation from stock Quartz v4.5.0**
([source](https://github.com/jackyzha0/quartz/tree/v4.5.0)) made by the
toolchain, verified by diffing against a clean v4.5.0 checkout. Anything not
listed here is unmodified upstream Quartz.

Customizations are applied at four different moments, which is the key to
understanding the system:

| Layer | When applied | How | Where the change lives |
|---|---|---|---|
| **A** | Docker image build | Whole-file replacement (`COPY` in Dockerfile) | `patches/` → `/opt/quartz/quartz/components/` |
| **B** | Course setup | Idempotent regex patch of `/opt/quartz` | `setup_course.py` |
| **C** | Site build (first build / every build) | Idempotent regex patch of the per-section output copy | `build_site.py` |
| **D** | Site build | Whole-file replacement from `support/` | `build_site.py` + `support/` |

Because every build starts from the layer-A/B scaffold and then applies C
and D, a teacher's output folder always contains the union of all four
layers.

---

## A. Components replaced at image build time

These three files in [`patches/`](../patches/) overwrite their stock
counterparts inside the image. Together they implement the **two-tier
sidebar**: some folders are *expandable trees*, others are *plain links*.

### A1. `Explorer.tsx` (sidebar component, server side)

Stock behaviour: every folder in the Explorer is a collapsible tree node.

Changes:

1. **Imports `course_config.json`** (copied into the Quartz source tree at
   build time) and reads its `expandable` list.
2. Adds an `isExpandable(name)` helper (case-insensitive comparison via
   `localeCompare` with `sensitivity: "base"`).
3. Emits the expandable list into the DOM as a `data-expandable` attribute
   on the Explorer's `<nav>`, for the client-side script (A2) to consume.
4. **Ignores the per-layout `title` option** — the heading always comes from
   the locale file, which layer D rewrites to "Navigate this site". This
   guarantees consistent, teacher-friendly wording regardless of layout
   config.

### A2. `explorer.inline.ts` (sidebar behaviour, client side)

This script builds the sidebar DOM in the browser from a trie of all content
files. Changes:

1. **Imports `course_config.json`** the same way and defines
   `isExpandableName()`.
2. **Non-expandable folders are stripped of tree UI**: their chevron icon
   and nested `<ul>` (the "folder outer" element) are removed, so the folder
   renders as a plain entry — clicking it navigates to the folder's index
   page rather than expanding children. This is the mechanism behind the
   *expandable vs. link* distinction chosen in the setup wizard.
3. **Two-tier top-level sort**: at the sidebar's root level, entries are
   re-ordered into (1) non-expandable folders A→Z, (2) expandable folders
   A→Z, (3) loose files. Rationale: plain-link folders (Tutorials as a
   simple page, say) read like top-level navigation items, while expandable
   trees (Examples, Exercises) form a second visual group; mixing them
   alphabetically felt random to students.
4. Minor type fix: `order: ("sort" | "filter" | "map")[]` (stock v4.5.0 has
   a mis-parenthesized type annotation).

### A3. `FolderContent.tsx` (folder listing page)

Stock behaviour: a folder page always renders "N items under this folder"
plus a listing of the folder's contents.

Changes:

1. **`showFolderCount` defaults to `false`** — the "N items under this
   folder" line is noise for students.
2. **New frontmatter flag `renderFolderPages`** on a folder's `index.md`:
   set it falsy (`false`, `"no"`, `"off"`, `0`) to suppress the automatic
   page listing entirely, leaving only the index page's own prose. This lets
   a teacher write a fully curated folder landing page without an
   auto-generated file dump below it.

---

## B. Patches applied at setup time to the scaffold

Applied by `setup_course.py` to `/opt/quartz` (the template each build
copies), so they exist before any site is built. Both are idempotent.

### B1. Explorer "omit anchor" in `quartz.layout.ts`

Stock `quartz.layout.ts` calls `Component.Explorer()`. Setup replaces it with
a configured call whose `filterFn` consults a marked set:

```ts
Component.Explorer({
    folderClickBehavior: "link",
    filterFn: (node) => {
      // CQ4T-OMIT-ANCHOR: do not remove this line; build script overwrites this Set
      const omit = new Set<string>([""]);
      if (node.isFolder) {
        return !omit.has(node.fileSegmentHint);
      } else {
        return !omit.has(node.data.title);
      }
    },
  })
```

At build time, layer C rewrites the `const omit = new Set([...])` line with
the course's actual hidden items. The `CQ4T-OMIT-ANCHOR` comment
("Containerized Quartz 4 Teachers") gives the rewrite a stable landmark, and
`build_site.py` contains a preflight that re-injects a default set if the
anchor has gone missing (e.g. someone hand-edited the file).

**Purpose:** implements the "hide from sidebar" feature — hidden pages still
build and remain reachable by link and search; they are only filtered out of
Explorer navigation.

### B2. Stable ID in `OverflowList.tsx`

Stock: `const id = randomIdNonSecure()` — a fresh random DOM id for the
sidebar's overflow list on *every build*, which changes every generated HTML
page even when content is untouched.

Patch: `const id = "j8p48f"` (an arbitrary fixed string).

**Purpose:** build determinism. Netlify's delta deploy uploads only files
whose SHA-1 changed ([details](07-deployment.md#why-determinism-matters));
a random id in the markup of every page would defeat that entirely.

---

## C. Patches applied at build time to the output copy

All are functions in `build_site.py`, applied with regexes tolerant of
re-application (each detects "already patched" and no-ops).

<a name="c1-applied-on-first-build--full-rebuild"></a>

### C1. Applied on first build / `--full-rebuild`

These target files a teacher's settings never change between builds, so they
only need to run when the scaffold is (re)created.

| # | Patch | File touched | What & why |
|---|---|---|---|
| C1-1 | **Remove the Graph view** | `quartz.layout.ts` | Deletes `Component.Graph(...)` from the right sidebar. The force-directed graph is Quartz's signature feature for personal wikis, but for a linear course site it is visual noise that confuses students more than it helps. |
| C1-2 | **Drop git from date priority** | `quartz.config.ts` | `Plugin.CreatedModifiedDate` priority `["git","frontmatter","filesystem"]` → `["frontmatter","filesystem"]`. The output folder is not a git repo, and even if it were, file copy times would be meaningless. Frontmatter `created` (written by setup, managed per-section) is the source of truth. |
| C1-3 | **`defaultDateType: "created"`** | `quartz.config.ts` | Stock shows *modified* dates. A class website should show when material was posted/covered — the `created` date — not when a typo was last fixed. This pairs with the [Curriculum date sync](05-build-pipeline.md#dates-drive-everything). |
| C1-4 | **Folder page title = folder name** | `quartz/plugins/emitters/folderPage.tsx` | Title template `"Folder: X"` → just `"X"`. Cosmetic: "Exercises", not "Folder: Exercises". |
| C1-5 | **`showFolderCount: false`** | `quartz/components/pages/FolderContent.tsx` | Belt-and-suspenders re-application of A3's default (protects against the file being replaced by an upstream copy). |
| C1-6 | **Long-form dates** | `quartz/components/Date.tsx` | `formatDate` options `{year, month: "short", day}` → `{weekday: "long", year, month: "long", day: "numeric"}`. Lesson pages read "Friday, September 12, 2025" — teachers and students think in weekdays. |
| C1-7 | **Wider list-page meta column** | `quartz/components/styles/listPage.scss` | Adds `width: 240px` to `.meta` so the long-form dates from C1-6 fit on one line in folder listings. |
| C1-8 | **No highlight box on internal links** | `quartz/styles/base.scss` | Comments out `background-color: var(--highlight)` on `a.internal`. Course pages are dense with wikilinks; the tinted background on every one made pages look blotchy. |
| C1-9 | **Transclusion styles** | `quartz/styles/base.scss` (appended block) | Hides the "link to original" anchor (`a.transclude-src`), removes the blockquote border/indent from transcluded content, and sizes the page-header `h1` at 2 rem. Together these make `![[Other Page]]` embeds read as seamless parts of the host page — used to assemble daily lesson pages from reusable pieces. |
| C1-10 | **`transcludeTitleSize` frontmatter flag** | `quartz/components/renderPage.tsx` | Stock renders a transcluded page's title as a hard-coded `<h1>`. Patched to `page.frontmatter?.transcludeTitleSize ?? "h1"`, so a page can declare e.g. `transcludeTitleSize: h2` and nest correctly in the host page's heading hierarchy. |
| C1-11 | **Typography fonts** | `quartz.config.ts` | Writes the section's header/body/code font choices (from the setup wizard) into the `typography` block. |
| C1-12 | **`.netlify` link** | output root | Symlinks (or copies) an existing `.netlify` folder into the output so Netlify CLI tooling can diff, if present. Convenience only — the bundled deployer does not need it. |

<a name="c2-applied-on-every-build"></a>

### C2. Applied on every build

These reflect settings a teacher may change at any time; running them every
build means a re-run of the setup wizard (or a hand edit of
`course_config.json`) takes effect on the next preview with no
`--full-rebuild` needed.

| # | Patch | File touched | What & why |
|---|---|---|---|
| C2-1 | **Local `course_config.json` + import rewiring** | `quartz/course_config.json`, `Explorer.tsx`, `explorer.inline.ts` | Copies the course config into the Quartz source tree and rewrites the A1/A2 imports to the correct relative path. Required because the patched Explorer *statically imports* the config: it must resolve at Quartz's own build time, including on Netlify-less machines. |
| C2-2 | **Reading time toggle** | `quartz/components/ContentMeta.tsx` | Sets `showReadingTime` (and its trailing comma display) in `defaultOptions` to match `show_reading_time`. |
| C2-3 | **Expand-on-navigate wiring** | `Explorer.tsx`, `explorer.inline.ts` | Injects `expandOnFolderClick` from course config as a `data-expand-on-navigate` attribute and gates the client script's "auto-open folders on the current page's path" logic behind it. Without the gate, navigating to a page inside a folder always sprang that folder open even when the teacher chose chevron-only expansion. |
| C2-4 | **Patched Backlinks component** | `quartz/components/Backlinks.tsx` | Whole-file replacement from `support/Backlinks.tsx` — see D below. |
| C2-5 | **Sidebar omit set** | `quartz.layout.ts` | Rewrites the B1 anchor's `const omit = new Set([...])` with the course's `hidden` list (with `Media` always appended). This is the moment "hide from sidebar" choices become real. |
| C2-6 | **Folder click behaviour** | `quartz.layout.ts` | Sets `folderClickBehavior` on every `Component.Explorer({...})` to `"collapse"` (name click expands) or `"link"` (name click navigates), per `expandOnFolderClick`. |
| C2-7 | **Custom footer** | `quartz.layout.ts`, `quartz/components/Footer.tsx` | Normalizes the layout to `Component.Footer()` and replaces the footer JSX with the teacher's raw HTML (via `dangerouslySetInnerHTML`, backtick-escaped). Typically a licence notice. |
| C2-8 | **Page title** | `quartz.config.ts` | Sets `pageTitle` to `"<emoji> <label> S<N>"` — per-section emoji, the uppercased course code (or the club's custom short label when the code has no grade digit), and the optional section marker. |
| C2-9 | **Locale** | `quartz.config.ts` | Sets `locale:` to the configured code (affects all UI strings via the layer-D locale files, plus date formatting). |
| C2-10 | **Colour scheme** | `quartz.config.ts` | Replaces the entire `colors: { lightMode: {...}, darkMode: {...} }` block with the section's chosen scheme from `colour_schemes.json` (brace-counting replacement, not regex, to handle the nested object safely). |
| C2-11 | **Social-media previews toggle** | `quartz.config.ts` | Comments/uncomments the `Plugin.CustomOgImages()` emitter line per the `--include-social-media-previews` flag. Generating Open Graph images roughly doubles build time, so it is opt-in and typically used only for deploys. |
| C2-12 | **Computed landing title** | `content/index.md` | The home page's frontmatter title is REPLACED with one computed from the current settings: `course_name`, the per-section grade toggle (`show_grade_in_title`), and the section-marker setting (which governs the ", Section N" suffix). Only the merged copy is written; the teacher's source file is never touched. |
| C2-13 | **Social sharing card** | `quartz/static/og-image.png` | `social_card.py` (Pillow) redraws the 1200×630 share image every build in the section's colour scheme and fonts — course name large, emoji + course code (+ marker) beneath. Replaces the stock Quartz card the site's head already links. |

### C3. Content-level transformations (every build)

Not Quartz-code patches, but part of the same customization story — they
adapt *Obsidian conventions* to *Quartz expectations* and are detailed in
[the build pipeline](05-build-pipeline.md#stage-3-content-assembly):

- `draftSectionN`/`createdSectionN` → `draft`/`created` collapse (per-section
  publishing from shared files).
- Aliased wikilinks containing `section<N>/` paths rewritten to alias-only
  form.
- Curriculum folders' `created` timestamps synced to the section's newest
  page.
- `content/Media` created as a symlink to the course-level media folder.

---

## D. Locale files replaced at build time

`support/locales/` contains all 27 Quartz locale files, installed over
`quartz/i18n/locales/` on first build. Each differs from stock in exactly
four strings, translated appropriately in every language:

| UI element | Stock (en-US) | Replaced with |
|---|---|---|
| Backlinks panel title | "Backlinks" | **"When did we do this?"** |
| Backlinks empty state | "No backlinks found" | **"Not yet addressed in class."** |
| Explorer (sidebar) title | "Explorer" | **"Navigate this site"** |
| Table of contents title | "Table of Contents" | **"Navigate this page"** |

**Rationale:** this is the toolchain's most pedagogically interesting
customization. In a course site, the pages that link *to* a concept page are
the daily lesson pages — so a concept page's backlinks panel is, in effect,
a record of **which classes covered this concept and when**. Renaming
"Backlinks" to "When did we do this?" turns a wiki feature into a student
catch-up tool, and the empty state "Not yet addressed in class." tells a
student reading ahead exactly what it means. "Explorer" and "Table of
Contents" are likewise renamed to plain-language labels.

### D1. Patched `Backlinks.tsx` (`support/Backlinks.tsx`)

Complements the locale change: adds support for an `excludeBacklinks: true`
frontmatter flag that suppresses the backlinks panel on a specific page.
Useful for pages where "when did we do this?" makes no sense (a style guide,
a syllabus) or where the link graph would mislead.

---

## E. Summary: what is *not* customized

Everything else is stock Quartz v4.5.0 — with one asset exception: `quartz/static/og-image.png` is overwritten every build by the generated social sharing card (see C2-13): the Markdown/OFM transformer
pipeline, full-text search (FlexSearch), syntax highlighting, LaTeX
rendering, callouts, popovers, RSS/sitemap emitters, mobile layout, and
light/dark mode. The customizations are deliberately thin wrappers around
configuration and presentation; the content pipeline is untouched, which is
what makes tracking upstream Quartz plausible (the cost of an upgrade is
re-validating each patch's regex against the new source text — and replacing
the three layer-A components).

---

[◀ Previous: The Build Pipeline](05-build-pipeline.md) · [Back to index](README.md) · [Next: Deployment ▶](07-deployment.md)
