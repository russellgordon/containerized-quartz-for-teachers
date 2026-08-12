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

- (Nothing at the moment — all entries picked up on 2026-08-12:
  About credits + Support-row removal, the preview-build deploy-freshness
  check, the computed-title font samples — already on macOS as spec
  entry 100 — and the live code-field explanation. Spec entries 107–109
  record the mirrors.)

## Already shared — no mac code needed, just awareness

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
  attached to the same release and hashed into the same table. (The
  `.claude/skills/example-content/` skill has since arrived — the mac
  side un-ignored `.claude/skills/` and committed it.)

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
