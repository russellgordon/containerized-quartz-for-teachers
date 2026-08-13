# macOS App — Handoff

The running ledger of work that originated on the **Windows side** and
needs (or deserves a look from) the **macOS app**. The reverse of
[`WINDOWS-HANDOFF.md`](WINDOWS-HANDOFF.md): read this when syncing the
mac app after Windows-side sessions. Each entry names the commit that
landed the Windows/shared work, what the mac side should do, and where
the reference implementation lives. Remove entries once the mac side has
picked them up. (Cross-side rebases rewrite commit hashes, so treat the
hashes as hints from the moment of writing — the file and test
references are the durable pointers.)

## To implement

- **Cloudflare Pages as a third publishing destination** (Windows +
  shared, 2026-08-12). Commits `0306c98` (container side), `4575647`
  (account fallback), `e6611cc` (Windows UI). **The shared half is
  already done and the mac inherits it** — `scripts/deploy.py` and the
  `Dockerfile` are common to both apps. The mac side needs two things:
  `deploy.sh`, and the GUI.

  **What already works, in shared code.** `deploy.py --target cloudflare`
  discovers the account, creates or reuses this section's Pages project,
  hands the built folder to wrangler, and prints `Live URL: https://…` —
  the label both apps' parsers already read, so no parser change was
  needed on either side. Per-section state lives in
  `courses/<CODE>/.cloudflare_sites/section<N>.json`, deliberately
  mirroring the existing `.netlify_sites/` marker.

  **Design decisions, and why — please keep these rather than re-deciding:**

  1. *Publishing rides on wrangler, not a reimplementation.* Cloudflare's
     direct-upload protocol is multi-stage and undocumented: BLAKE3 hashes
     computed over base64-of-contents plus the file extension, a
     short-lived upload JWT that can expire mid-upload on a large site,
     and batched asset uploads. Community write-ups exist, but a
     reimplementation would break teachers' publishing silently whenever
     Cloudflare changed it. wrangler is Cloudflare's own supported
     implementation and already handles those edges.
  2. *wrangler is pinned at 4.80.0 — and pinned BELOW 4.100 on purpose.*
     From 4.100 wrangler requires Node 22; the image ships Node 20 because
     that is what Quartz v4.5.0 is known-good against. Raising Node to
     chase a newer CLI would mean revalidating every teacher's site build.
     Install and `--version` were verified on `node:20-slim` before
     committing. **If you bump Node, revisit this pin — and revalidate
     Quartz first.**
  3. *A token scoped to Pages CANNOT list its own account.* This was
     found by testing a real token: `/user/tokens/verify` reports
     `active`, while `/accounts` returns success with an EMPTY list and
     `/memberships` returns 403. The first cut treated "no accounts" as
     "bad token" and would have sent teachers off to re-mint a perfectly
     good one. **Validity and account lookup are now separate questions**
     — validity against `/user/tokens/verify`, the account by discovery →
     remembered value → asking. Please do not collapse them again.
  4. *Because of (3), the account ID must be collected in the GUI.* The
     app publishes with nothing attached that can answer a console
     prompt, so the launcher's prompt is unreachable from the GUI. On
     Windows it is a field in the Publishing section, validated live (32
     hex characters) with Save/Create gated on it, and passed to the
     launcher as `--account`. It is stored in **app settings, not course
     settings**, because it identifies the teacher rather than the course
     — the same reasoning that puts the token in the OS keychain — so it
     is entered once and used by every course.
  5. *The 25 MB per-file cap is checked before anything uploads.*
     Cloudflare refuses larger files, and the failure otherwise surfaces
     from deep inside the upload as an unhelpful error. `deploy.py` lists
     the offending files by name and suggests compressing the video or
     publishing that section to Netlify, which allows larger files. This
     is the one real functional difference between the destinations and
     is worth saying plainly in the mac UI too.
  6. *Tokens are stored under separate keychain entries.* A teacher
     publishing some courses to Netlify and others to Cloudflare keeps
     both, and `--reset-token --target cloudflare` clears only the
     Cloudflare one (plus its remembered account).

  **What the mac side must write.** `deploy.sh` needs the `--target`
  and `--account` flags, its own keychain entry for the Cloudflare token
  (plus one for the remembered account ID), token validation against
  `/user/tokens/verify`, and the same env hand-off into the container:
  `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`, with
  `--target cloudflare` passed to `deploy.py`. **`deploy.sh` was left
  deliberately untouched on the Windows side** — shipping an edit to a
  launcher that could not be tested here would be worse than shipping
  none. GUI-wise: the third picker option, the account field with live
  validation, the milestone list (never saying "Netlify" — pinned by a
  test on Windows), and a decline path if the account is missing.
  Reference: `windows-app/Plantoir/Views/PublishingChoiceView.cs`,
  `SectionDetailView.xaml.cs` (`Deploy_Click`),
  `Plantoir.Core/Scripting/TaskMilestones.cs`,
  `CourseConfiguration.CloudflareAccountProblem`.

  **Status: PUBLISHED END TO END and working** (Windows, 2026-08-12).
  MCV4U Section 1 from a real workspace went live at
  `mcv4u-s1-2026-gordon.pages.dev` (HTTP 200, correct Quartz title),
  driven from the app's Publish button, not a script. Observed:

  - First publish ~140 s including the one-off toolchain image rebuild;
    a second publish ~23 s, reusing the project rather than creating a
    second one (exactly one project in the account afterwards).
  - The progress bar tracked "Step 8 of 8" through the
    `BuildAndDeployToCloudflare` list, and the completion panel showed
    "Your website is live" with the clickable pages.dev link — the
    Netlify live-link panel works unchanged, because `deploy.py` prints
    the `Live URL:` label the parser already reads.
  - The marker file came out as intended:
    `{name, id, subdomain, account_id}`.

  **The build-counter question is settled, empirically.** The deployment
  record for a Direct Upload reports `deployment_trigger.type: ad_hoc`
  and its stages come back `clone_repo=idle, build=idle, deploy=success`
  — **no Cloudflare build runs**, so the free plan's 500-builds-per-month
  limit does not apply to how Plantoir publishes. A teacher republishing
  many times a day across several classes is in no danger of it. (The
  limit is documented as applying to builds triggered by a git push,
  which this path never does.) Worth not re-investigating on the mac.

  Remaining unknown: behaviour at the 25 MB per-file cap has still only
  been checked by the pre-flight guard in `deploy.py`, not by actually
  pushing an oversized file.

  **Mirror the standing size note too** (`8883ad9`). Whenever Cloudflare
  is the chosen destination, the Publishing section shows a permanent
  orange line — not the validation warning, which comes and goes, but a
  fact about the destination that never hides:

  > One thing to know: Cloudflare won't accept any single file larger
  > than 25 MB. Documents, images, and slide decks are almost always
  > comfortably under that — a long video usually isn't. Most teachers
  > embed video from YouTube or Vimeo rather than uploading it, which
  > avoids the limit entirely.

  This is the one real functional difference between the destinations, so
  a teacher should meet it while choosing rather than when a publish
  fails. The grey caption deliberately no longer repeats it.

- **`sanitize_last_name` folds accents instead of dropping them**
  (shared, 2026-08-12, commit `0306c98`). Pre-existing bug in
  `scripts/deploy.py`, found while testing Cloudflare project naming: the
  function kept only `a-z`, so a teacher named **Côté** got `ct` in her
  site name and Müller got `mller`. In an Ontario staff list that is not
  an edge case. It now normalises (NFKD) and strips combining marks
  first, so Côté → `cote`. **This affected Netlify site names too**, and
  the mac inherits the fix automatically since `deploy.py` is shared —
  no mac code needed, but worth knowing the suggested names changed.
  Existing sites are pinned by their marker files and are unaffected.

- **About box credits match plantoir.app's footer** (Windows, 2026-08-11).
  The credits section is now: a rounded-rect callout carrying the full
  sponsor message ("Plantoir is a friendly wrapper around [Quartz], which
  Jacky Zhao builds and gives away for free. If you end up using Plantoir
  regularly, please consider [sponsoring him on GitHub] — it is his work
  that makes all of this possible."), then three plain acknowledgement
  lines: "Icon from [Phosphor Icons] (MIT)." / "Designed by
  [Russell Gordon]." / "Made with Claude." — links to quartz.jzhao.xyz
  and github.com/sponsors/jackyzha0 (in the callout), phosphoricons.com,
  russellgordon.ca. No "Built on Quartz" line: the callout already says
  whose work this stands on. (Replaces the old one-line "Please sponsor
  Jacky" credit; plantoir.app's footer matches.) Also: the
  plantoir.app/support row is REMOVED from the Windows About — help is
  coming into the app itself — leaving Email as the only contact row;
  drop the mac About's Support row to match. Mirror in the mac About
  window. Reference: `windows-app/Plantoir/Views/AboutDialog.cs`.

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

- **Font samples show the course's own computed site title** (Windows,
  2026-08-11). The header font sample renders the title the build will
  actually produce — `[Grade X ]Name[, Section N]`, i.e. the course name
  with the grade and section-marker switches applied — in the candidate
  typeface, updating live as the name, code, section numbers, or either
  toggle changes. The "Grade 11 Computer Science" stand-in remains only
  while the form is blank; the body-sentence sample is unchanged. In
  Course Settings each section's sample uses that section's own toggles.
  The compute is `CourseConfiguration.ComputedSiteTitle` (Core),
  mirroring `computed_landing_title` in `scripts/build_site.py` and
  pinned by a six-case theory test. Mirror in the mac wizard's
  FontChoiceEditorView and Course Settings. References:
  `SampleHeaderText()` in `windows-app/Plantoir/Views/NewCourseDialog.cs`
  and `windows-app/Plantoir/Views/CourseSettingsView.xaml.cs`;
  `ComputedSiteTitleMatchesTheBuild` in
  `windows-app/Plantoir.Tests/CourseConfigurationTests.cs`.

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

- **Worth checking: the same test race may exist on the mac**
  (`3bbb1a7`, 2026-08-13). A Windows test failed about one run in three
  with a baffling null. The cause was not the production code: preview
  leases and the publish registry are **process-wide statics**, the test
  runner runs test classes in parallel, and the lease-tests class reset
  that shared state around every one of its methods — wiping the lease
  another class was mid-assertion on. Fixed by putting both classes in a
  serialized collection. If the mac's tests around `CourseActivity` /
  preview leases share process-wide state and run in parallel, the same
  intermittent failure is possible there; it is the kind that gets
  written off as "flaky CI" for months. Worth ten minutes to check.

- **`MCP-PROPOSAL.md` is waiting on a mac-side opinion** (2026-08-12).
  A design (nothing built) for letting AI assistants drive Plantoir over
  MCP — "publish the Science courses overnight and un-draft tomorrow's
  class plus everything it links to". The proposal's central question is
  for the mac side: whether to ship **one** self-contained .NET binary
  serving both platforms, or reimplement the tool contract in Swift. It
  ends with four explicit questions. Nothing blocks on it, but it should
  not get lost between syncs.

- **The Windows icon derives from `mac-app/Plantoir.icon`** (2026-08-11).
  `windows-app/Plantoir/Assets/make-icon.ps1` turns a full-bleed 1024px
  Icon Composer export into the exe/.ico and About-panel assets, applying
  the macOS rounded-rect silhouette; `site/icon.png` on plantoir.app
  comes from the same export. If the icon art ever changes, tell the
  Windows side so those derived assets are regenerated — nothing updates
  them automatically.

- **Auto-update plans need appcast coordination** (2026-08-12). Windows
  will adopt WinSparkle (paired with an Inno Setup installer, planned
  after v1.0); if/when the mac app adopts Sparkle, BOTH appcasts should
  live on plantoir.app in this repo's `site/` — use per-platform file
  names from the start (`appcast-windows.xml`, `appcast-macos.xml`) so
  the two update feeds never collide, and add the release-time appcast
  edit to the shared checklist in `windows-app/RELEASING.md` when the
  first one lands.

- **The mac release asset must be named exactly `Plantoir-macOS.zip`**
  (2026-08-11; SPECCED — the mac ships a zip, not a dmg: Safari
  auto-unzips, average users fumble the dmg ritual, and Sparkle handles
  zips natively). plantoir.app now lives in `site/` in this repo
  (Netlify deploys it on push) and its download cards link straight to
  `releases/latest/download/<asset-name>` — GitHub's evergreen URL that
  only works while every release names its assets identically. Windows
  ships `Plantoir-win-x64.zip`; the mac card expects
  `Plantoir-macOS.zip`. The names are frozen: renaming an asset silently
  breaks the site's download button.

- **The release process is shared — read `windows-app/RELEASING.md`**
  (2026-08-11). The decisions that bind both sides: ONE product version
  series in lockstep (Windows reads `<Version>` in `Plantoir.csproj`;
  keep the mac marketing version matching), ONE GitHub release per
  version carrying BOTH platforms' assets (plantoir.app's download cards
  point at `releases/latest`), tag `v<version>`. Release notes are
  drafted by Claude via the `cut-release` skill
  (`.claude/skills/cut-release/`) — teacher-friendly bullets from the
  commit log plus a SHA-256 downloads table; the mac asset should be
  attached to the same release and hashed into the same table. Also:
  the spec's `.claude/skills/example-content/` skill did not arrive in
  the merged repo — bring it over if it lives only on the mac checkout.

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
