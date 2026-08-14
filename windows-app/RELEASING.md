# Releasing Plantoir for Windows

The product version lives in ONE place: `<Version>` in
`Plantoir/Plantoir.csproj`. The About panel reads it, `publish.ps1` names
the bundle after it, and the git tag must match it. Keep it in lockstep
with the mac app's marketing version — one product, one version series,
one GitHub release carrying both platforms' assets.

## Checklist

1. **Bump the version** in `Plantoir/Plantoir.csproj` (`<Version>`), commit.
2. **Full test pass**: `dotnet test Plantoir.Tests` (all green), plus a
   hand smoke of create → preview → publish on a real course.

   > The hand smoke is **not optional, and not a formality**. The bundle
   > carries the whole toolchain recipe (Dockerfile, `scripts/`,
   > `patches/`, launchers) inside the app, and the xUnit suite
   > deliberately never touches Docker — so a green test run says nothing
   > about the thing teachers actually run. `verify.sh`, the real
   > toolchain gate, is bash and expects `docker` on `PATH`, which does
   > not hold on Windows where Docker Engine lives in WSL2. **On Windows
   > the hand smoke is the only toolchain verification there is.** If the
   > release changes anything under `scripts/`, the Dockerfile, or a
   > launcher, smoke the publishing destination(s) it touches — there are
   > three now (Netlify, Cloudflare Pages, a folder), and they take
   > different code paths.
3. **Build the signed bundle**:

       powershell -File publish.ps1 -Sign

   One-time tooling on a new machine (the Azure account/identity setup
   itself lives in the private Artifact Signing runbook):

       winget install --exact --id Microsoft.AzureCLI   # then open a NEW terminal
       dotnet tool install --global sign --prerelease

   Per session: `az login` (as the Azure signing account). The script
   preflights all three — missing tool or stale login fails in seconds
   with the remedy, before the minutes-long build. It signs with the
   RFC 3161 timestamp and refuses to package a signature without one.
   Output: `dist/Plantoir-<version>-win-x64.zip` + its SHA-256.
4. **Verify like a teacher** (the only test that reproduces what they
   see): copy the zip to a machine — or at least a fresh folder —
   download it through a browser if possible, extract, right-click
   `Plantoir.exe` → Properties → Digital Signatures → signature OK,
   timestamp present, no street address in the certificate subject.
5. **Tag and release** — ask Claude to "cut the release": the
   `cut-release` skill (`.claude/skills/cut-release/`) drafts
   teacher-friendly release notes from the commits since the last tag
   (grouped New / Improved / Fixed, internal work omitted), appends a
   Downloads table with each asset's size and SHA-256 computed from the
   exact files being uploaded, shows the draft for approval, then tags
   and publishes via `gh release create`. Manual equivalent:

       git tag v<version>
       git push origin main v<version>
       gh release create v<version> dist/Plantoir-<version>-win-x64.zip \
         --title "Plantoir <version>" --notes "..."

   The mac side attaches its own asset to the SAME release.

   **Asset names are LOAD-BEARING and must never change**:
   `Plantoir-win-x64.zip` (publish.ps1 emits exactly this) and
   `Plantoir-macOS.zip`. plantoir.app's download cards point at
   `releases/latest/download/<asset-name>` — GitHub's evergreen URL that
   serves the newest release's asset, so teachers click Windows or macOS
   and get the file, no GitHub in sight. Renaming an asset silently
   breaks the site's download link.
6. **plantoir.app updates itself**: the site lives in `site/` in this
   repo, and Netlify deploys it on every push (one-time setup: in the
   Netlify UI, link the site to the GitHub repo, publish directory
   `site/`, no build command). Cutting the release edits the
   version-note line in `site/index.html` and pushes — nothing manual.
   It also redraws the brand images and installs the card:

       python scripts/brand_images.py --install-card

   Safe to run every time: the output is deterministic, so unless the
   icon, palette or tagline changed this leaves the working tree clean
   and there is nothing to commit. See **Brand images** below.
7. **Update the WinSparkle appcast** once in-app updates land (see
   below): add an `<item>` for the new version to `appcast.xml` on
   plantoir.app, pointing at the GitHub release asset URL.

## Bundle format

Currently a plain zip of the self-contained publish folder (~58 MB
zipped, ~157 MB installed; no .NET or Windows App SDK install needed —
everything travels in the folder). The planned move to WinSparkle
auto-updates pairs naturally with an Inno Setup installer
(`PlantoirSetup-<version>.exe`): WinSparkle downloads and RUNS the
update it fetches, which a zip cannot do. When that lands, `publish.ps1`
gains an installer step after signing (and the installer itself gets
signed too); the zip can remain as a portable alternative.

## Brand images

Everything that carries the Plantoir mark — the `og:image` served at
plantoir.app, the Bluesky and Instagram profile photos, the Bluesky
banner — is drawn by one script from one source:

    python scripts/brand_images.py --install-card

It reads the artwork straight out of `mac-app/Plantoir.icon` (the same
bundle Icon Composer edits) and the palette out of the constants at the
top of the script, which mirror the CSS custom properties in
`site/index.html`. The four images land in `brand/`; `--install-card`
additionally copies the card to `site/social-card.png`, which Netlify
serves as the `og:image`. Nothing is fetched at run time; the Poppins
weights it needs are committed in `support/fonts/`.

**Cutting a release runs this** (step 6), and that is safe because the
output is **deterministic** — identical inputs give byte-identical PNGs.
A release that changed nothing about the artwork leaves the working tree
clean and there is nothing to commit. A diff appears only when the icon,
the palette or the tagline actually moved, which is exactly when you want
to notice. So: if `git status` is quiet after this step, that is the
expected result, not a sign it failed.

If it *does* produce a diff, look at the images before committing them —
the push deploys the card to a public URL.

Two things worth knowing about the card in particular:

- The original card was hand-made and has no source. The generated one
  is measured to match it — tile 260&nbsp;px at 108,185; wordmark Poppins
  **Medium 96**&nbsp;px; tagline Regular 33&nbsp;px on a 46&nbsp;px
  leading; domain line Medium 26&nbsp;px; rule 8&nbsp;px — and every text
  element now matches the original's ink coverage exactly. It is still
  **not** byte-identical: glyph advance widths accumulate slightly
  differently, so letters drift a pixel or two toward the end of a line.
  Background and rule are pixel-identical. Look at both before you commit.

  The brand uses Poppins **Regular and Medium only — no SemiBold**. That
  is measured from the original card, not assumed. Do not "correct" it to
  600 because `site/index.html` sets `h1 { font-weight: 600 }`; the card
  is a separate artifact and was not rendered from that stylesheet.
- That file is public and every social platform that has scraped
  plantoir.app has it cached. Replacing it is an outward-facing change,
  not a refactor. Platforms re-scrape on their own schedule, so the old
  card can keep appearing in link previews for a while after deploy.

The two greens are not interchangeable and both appear on the card:
`--green-deep` (#2D6620) sets the wordmark, `--green` (#3E8C26) sets the
rule, the link, and the mark itself. The mark reads #3E8D26 rather than
the pure green in `icon.json` because the layer's translucency blends it
into the background — a rendering behaviour that cannot be recovered
from the JSON, so it is pinned as a constant in the script.

## Notes

- The PRI249 "Invalid qualifier: SOCIAL-EMOTIONAL LEARNING SKILLS"
  warning during publish is noise: the resource indexer misreads an
  example-content filename as a language qualifier. Harmless.
- GitHub's asset size limit (2 GB) is nowhere near a concern.
- With a valid Artifact Signing signature + timestamp, SmartScreen
  warnings fade as reputation accrues to the signing identity; the
  "Unblock" instructions on plantoir.app can be softened after the first
  signed release proves out on a fresh machine.
