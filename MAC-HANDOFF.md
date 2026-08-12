# macOS App — Handoff

The running ledger of work that originated on the **Windows side** and
needs (or deserves a look from) the **macOS app**. The reverse of
[`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md): read this when syncing the
mac app after Windows-side sessions. Each entry names the commit that
landed the Windows/shared work, what the mac side should do, and where
the reference implementation lives. Remove entries once the mac side has
picked them up.

## To implement

- **Preview builds are never deploy-fresh** (from `94e25f8`, 2026-08-11).
  Deploying right after previewing published the preview's build, whose
  pages carry Quartz's live-reload client (`new WebSocket('ws://localhost:…')`)
  — so the PUBLISHED site knocked on every visitor's localhost and
  Chromium-family browsers prompted "wants to access other apps and
  services on this device" on first load. The shared `scripts/deploy.py`
  now detects the client and re-emits a production build before
  uploading, which already protects the mac app functionally — but the
  mac app's own deploy-freshness check shares the Windows one's blind
  spot (it compares only content dates). Mirror the Windows fix so the
  app's ordinary, visible build-first step runs instead of the silent
  in-deploy rebuild: a built `public/index.html` containing
  `ws://localhost:` is never fresh. Reference:
  `windows-app/Plantoir.Core/Models/BuildFreshness.cs`
  (`BuiltForPreview`) and the `APreviewBuildIsNeverDeployFresh` test in
  `windows-app/Plantoir.Tests/ModelTests.cs`.

- **Font samples show the course's own name** (Windows, 2026-08-11).
  Once a course name is set (typed in the wizard, or stored in settings),
  the header font sample renders THAT name in the candidate typeface
  instead of the "Grade 11 Computer Science" stand-in — the teacher sees
  their actual site title. The stand-in remains only while no name
  exists; the body-sentence sample is unchanged; samples update live as
  the name is edited. Mirror in the mac wizard's FontChoiceEditorView
  and Course Settings. Reference: `SampleHeaderText()` in
  `windows-app/Plantoir/Views/NewCourseDialog.cs` and
  `windows-app/Plantoir/Views/CourseSettingsView.xaml.cs`.

- **Explain a disabled Create button in the wizard** (from `2d10e4c`,
  2026-08-11). On Windows, a filled-in New Course form with a DUPLICATE
  course code left Create greyed with no explanation — the sections
  field explained its problems inline while the code field stayed
  silent. Windows now shows the reason under the code field ("A course
  named ICS4U already exists — choose a different code."), single-sourced
  with the check that gates the button. Worth checking whether the mac
  wizard has the same silent-disable and wants the same inline
  explanation. Reference: `CourseCodeProblem()` / `RefreshCodeValidation()`
  in `windows-app/Plantoir/Views/NewCourseDialog.cs`.

## Already shared — no mac code needed, just awareness

- **Course-catalog repairs** (`37dc6c8`): MTH1W read "Mathematics,
  Grade 9, Grade 9, Destreamed" (short name "Math,") and PLF4M had the
  same doubled-grade + trailing-comma pattern; both repaired in
  `support/ontario_secondary_courses.json`. The mac app picks this up by
  rebuilding (bundled support folder). No other entries matched either
  pattern.

- **Toolchain hash changed** (`94e25f8`): `scripts/deploy.py` changed,
  so the next preview/deploy on any machine rebuilds the Docker image
  once.

- **Windows caught up with rows 91–96** (`e7076ae`): Starting Content
  toggles, structure lock, LCS terminology switch, and the neutral
  factory defaults are now mirrored on Windows (including the
  `WizardDefaults` pairing and a Windows `ExampleContentCatalog`).
  Nothing to do on mac — listed so the mac side knows the wizards agree
  and that changes to `DEFAULT_*`/`LCS_*` in `scripts/setup_course.py`
  must now be mirrored in BOTH apps' `WizardDefaults`.
