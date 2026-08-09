# GUI Improvement Log

A running log of improvement instructions for the graphical interfaces to
this toolchain. Two purposes:

1. Track what has been asked for and where it stands in the **macOS app**
   (`mac-app/`).
2. Serve as a **specification feed for the planned Windows equivalent** of
   the GUI — every entry here describes behaviour the Windows app must also
   have, unless marked macOS-only.

Baseline: both GUIs are thin wrappers. They collect input and present
output; all real work happens in the command-line toolchain (scripts on
macOS; the WSL2-backed equivalents on Windows). See
[`documentation/09-mac-app.md`](documentation/09-mac-app.md) for the design
principle and [`mac-app/README.md`](mac-app/README.md) for architecture.

| # | Date | Instruction | macOS status | Notes for Windows port |
|---|------|-------------|--------------|------------------------|
| 1 | 2026-08-09 | When a course code is entered in the New Course wizard, suggest the default course name the way the command-line wizard does (lookup in `support/ontario_secondary_courses.json`; offer formal and short names). | ✅ Implemented — auto-fills the formal name for known codes (never overwriting a teacher-typed name), with formal/short suggestion buttons. `CourseNameCatalog` + wizard `autoFillCourseName()`; unit + UI tested. | Bundle the same JSON; same rules: uppercase/trim the code before lookup, auto-fill only over emptiness or a previous auto-fill, offer both name variants. |
| 2 | 2026-08-09 | Show live previews of the chosen header and code fonts (fonts bundled with the app, registered at launch — pattern from the Canopy app's `CustomFontList`). | ✅ Implemented — all 18 wizard font families bundled (from google/fonts, OFL/UFL licences included) and registered via `CTFontManagerRegisterFontsForURL` (`BundledFontList`); `FontChoiceEditorView` renders header, body, and code sample lines in the actual typefaces, falling back to the system font if unavailable. Unit test asserts all 18 families register. | Ship the same 18 font files + licences; register per-process at app start (Windows: `AddFontResourceEx`/`PrivateFontCollection` or framework equivalent); render header/body/code sample lines; "Helvetica, Arial" previews as a system sans. |
| 3 | 2026-08-09 | Distinguish previews from settings: font samples inside a rounded rect with a slightly darker background and horizontal padding; no divider between "Header & body fonts" and its sample, between "Code font" and its sample, or between "Colour scheme" and its swatch preview. Add a short prompt explaining the footer box (that you can type in it, and what belongs there). | ✅ Implemented — `SampleBox` (rounded rect, `.quaternary` background, inset); each picker + its preview share one form row so no divider appears between them; `FooterEditorView` adds an explanatory prompt above the box and a placeholder example inside it when empty (used in both settings and the wizard). | Same grouping rule: a setting and its preview belong to one visual row with no separator; previews get a recessed rounded background; the footer editor needs a prompt + in-box placeholder. |
| 4 | 2026-08-09 | Establish the standard: ALL example/preview content goes inside the inset `SampleBox` — including the colour scheme swatches. Short "e.g. …" hints use the "Preview:" text style (callout size, secondary colour) and sit UN-inset directly under their setting: applied to Course code, Course name, and Timetable section numbers in the wizard, and to the "Show section marker" toggle (wizard and per-section settings), moving the examples out of the control labels. | ✅ Implemented — colour swatches moved inside `SampleBox`; new `ExampleCaption` view encodes the hint style; field/toggle labels shortened with captions beneath, sharing the control's form row. | Two-tier standard: rendered previews → inset recessed box; textual "e.g." hints → un-inset caption (small/secondary) directly under the control, never embedded in the control's label. |

| 5 | 2026-08-09 | Bump form sub-headings up a bit (Basics, Appearance); move the "(applied to every section — fine-tune later in Settings)" note out of the Appearance heading to sit beneath it, in the same style as the "e.g." hints. | ✅ Implemented — new `FormSectionHeader` view (title3 semibold title + optional callout/secondary caption) applied to every form section in the wizard, course settings, and per-section settings; the Appearance caption uses the header's caption slot. | Section headers one step larger than body, semibold; explanatory notes about a whole section belong in a caption line under the heading (hint style), never inside the heading text. |

| 6 | 2026-08-09 | Put the wizard's content-structure lists under a "Structure" `FormSectionHeader`, with "(defaults are fine for most courses)" moved below the heading as a hint. | ✅ Implemented — a Structure section with caption "Defaults are fine for most courses"; the four folder/file list editors stay collapsed inside a "Folders and files" disclosure to keep the wizard compact. | Same: Structure section with the caption under the heading; keep the long lists collapsed by default. |

## Planned

- **Windows equivalent of the GUI** — a native Windows counterpart to the
  macOS app, wrapping the same toolchain via the PowerShell launchers /
  WSL2 Docker Engine. Details to be discussed; every behaviour in the table
  above applies unless noted.
