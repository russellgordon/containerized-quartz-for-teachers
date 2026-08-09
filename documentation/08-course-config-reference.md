# 8. `course_config.json` Reference

[◀ Previous: Deployment](07-deployment.md) · [Back to index](README.md) · [Next: The macOS App ▶](09-mac-app.md)

`courses/<CODE>/course_config.json` is the single source of truth for a
course. It is **written** by the setup wizard
([`setup_course.py`](04-course-setup.md)), **read and auto-extended** by the
build ([`build_site.py`](05-build-pipeline.md) appends newly discovered
folders/files), and **statically imported** by the patched Explorer
components at Quartz build time
([customizations C2-1](06-quartz-customizations.md#c2-applied-on-every-build)).

A representative example:

```json
{
  "course_code": "ICS3U",
  "course_name": "Introduction to Computer Science",
  "custom_short_name": "",
  "locale": "en-US",
  "emojis": { "sections": { "section1": "🖥️", "section3": "🔬" } },
  "num_sections": 2,
  "section_numbers": [1, 3],
  "shared_folders": ["Concepts", "Examples", "Exercises", "Ontario Curriculum", "Tutorials"],
  "shared_files": ["Learning Goals.md"],
  "per_section_folders": ["All Classes"],
  "per_section_files": ["Key Links.md"],
  "hidden": ["Ontario Curriculum", "Learning Goals.md", "Media"],
  "expandable": ["Concepts", "Examples", "Exercises", "Tutorials"],
  "expandOnFolderClick": false,
  "footer_html": "…licence notice…",
  "show_reading_time": false,
  "fonts": {
    "default": { "header": "Montserrat", "body": "Lora", "code": "JetBrains Mono" },
    "sections": { "section1": { "header": "Montserrat", "body": "Lora", "code": "JetBrains Mono" } }
  },
  "show_section_marker": { "sections": { "section1": true, "section3": false } },
  "color_schemes": { "section1": "nordic-frost", "section3": "mlb-toronto-blue-jays" }
}
```

## Key-by-key

| Key | Type | Written by | Consumed by | Meaning |
|---|---|---|---|---|
| `course_code` | string | setup | build | Uppercased code, e.g. `ICS3U`. The 4th character, if a digit, encodes grade (1→9 … 4→12) and selects "course mode"; a non-digit (e.g. `CODING`) selects "club mode". |
| `course_name` | string | setup | setup (titles) | Human name used in generated `index.md` titles. |
| `custom_short_name` | string | setup (club mode only) | build | ≤ 12-char label shown beside the header emoji instead of the course code. Empty → fall back to title-cased code. |
| `locale` | string | setup | build → `quartz.config.ts` | One of Quartz's 27 locale codes; drives UI strings ([teacher-customized](06-quartz-customizations.md#d-locale-files-replaced-at-build-time)) and date formats. |
| `emojis.sections.section<N>` | string | setup | build (page title) | Single emoji per section, e.g. `"📚"`. Legacy `emojis.default` is honoured as a fallback. |
| `num_sections` | int | setup | setup (prompt default) | Count of sections; normalized to `len(section_numbers)`. |
| `section_numbers` | int[] | setup | launchers + build (validation) | The teacher's actual timetable section numbers, e.g. `[1,3,4]`. Only these sections can be built or deployed. |
| `shared_folders` | string[] | setup + build discovery | build | Course-root folders copied into every section's site. `Media` never appears here (symlinked instead). |
| `shared_files` | string[] | setup + build discovery | build | Course-root loose `.md` files copied into every section's site. |
| `per_section_folders` | string[] | setup + build discovery | build | Folder names expected inside each `section<N>/`, copied only into that section's site. |
| `per_section_files` | string[] | setup + build discovery | build | Loose `.md` files inside each `section<N>/`. |
| `hidden` | string[] | setup + build (auto-adds `Media`) | build → Explorer omit set | Items filtered out of the sidebar. Still built, linkable, and searchable. |
| `expandable` | string[] | setup + build discovery | patched Explorer (statically imported) | Folders rendered as collapsible trees; all other folders render as plain links to their index page. |
| `expandOnFolderClick` | bool | setup | build → `folderClickBehavior` + `data-expand-on-navigate` | `true`: clicking a folder name expands it. `false` (default): name navigates; only the chevron expands. |
| `footer_html` | string | setup | build → `Footer.tsx` | Raw HTML injected into every page's footer. |
| `show_reading_time` | bool | setup | build → `ContentMeta.tsx` | Show "N min read" on pages. |
| `fonts.default` / `fonts.sections.section<N>` | object | setup | build → `quartz.config.ts` typography | `header`, `body`, `code` font family names (Google Fonts or system stacks). Section entry wins over default. |
| `show_section_marker.sections.section<N>` | bool | setup | build (page title + index title) | Whether the header shows `S<N>` and the home title keeps ", Section N". The build also accepts several legacy shapes (plain bool, flat map, alternate key names). |
| `color_schemes.section<N>` | string | setup | build → `quartz.config.ts` colors | Scheme id from `support/colour_schemes.json` (43 available). |

## Files that travel alongside it

| Path (under `courses/`) | Purpose |
|---|---|
| `<CODE>/course_config.backup.json` | Automatic backup written before build-time discovery updates the config. |
| `<CODE>/.merged_output/section<N>/` | Generated Quartz site for the section (scaffold + merged content + `public/`). Safe to delete; rebuilt on demand. |
| `<CODE>/.netlify_sites/section<N>.json` | Netlify site marker (site id/URL) so re-deploys target the same site. |
| `<CODE>/Media/` | Shared binary assets; symlinked into every build, always hidden from the sidebar. |
| `<CODE>/.obsidian/` | Obsidian vault settings (seeded from `support/obsidian_defaults`). |
| `_backups/<CODE>/<timestamp>.zip` | Full course backups made by the setup wizard before re-runs. |
| `.internal/profile.json` | Teacher profile (last name for Netlify site naming). |
| `.gitignore` | Auto-maintained to exclude `.internal/` and `_backups/`. |

## Frontmatter conventions recognized in content

These are read from individual Markdown files rather than the config, but
belong in the same mental model:

| Frontmatter key | Where | Effect |
|---|---|---|
| `draftSection<N>` / `createdSection<N>` | shared content | Per-section publication state; collapsed to `draft`/`created` when building section N ([mechanism](05-build-pipeline.md#frontmatter-processing)). |
| `draft`, `created` | any page | Standard Quartz meaning; `created` is the displayed and sort date ([C1-3](06-quartz-customizations.md#c1-applied-on-first-build--full-rebuild)). |
| `renderFolderPages: false` | a folder's `index.md` | Suppresses the auto-generated file listing on that folder page ([A3](06-quartz-customizations.md#a3-foldercontenttsx-folder-listing-page)). |
| `excludeBacklinks: true` | any page | Hides the "When did we do this?" backlinks panel on that page ([D1](06-quartz-customizations.md#d1-patched-backlinkstsx-supportbacklinkstsx)). |
| `transcludeTitleSize: h2` | a transcluded page | Heading level used for the page's title when embedded via `![[…]]` ([C1-10](06-quartz-customizations.md#c1-applied-on-first-build--full-rebuild)). |

---

[◀ Previous: Deployment](07-deployment.md) · [Back to index](README.md) · [Next: The macOS App ▶](09-mac-app.md)
