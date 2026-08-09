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

## Planned

- **Windows equivalent of the GUI** — a native Windows counterpart to the
  macOS app, wrapping the same toolchain via the PowerShell launchers /
  WSL2 Docker Engine. Details to be discussed; every behaviour in the table
  above applies unless noted.
