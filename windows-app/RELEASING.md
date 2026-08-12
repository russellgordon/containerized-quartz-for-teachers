# Releasing Plantoir for Windows

The product version lives in ONE place: `<Version>` in
`Plantoir/Plantoir.csproj`. The About panel reads it, `publish.ps1` names
the bundle after it, and the git tag must match it. Keep it in lockstep
with the mac app's marketing version — one product, one version series,
one GitHub release carrying both platforms' assets.

## Checklist

1. **Bump the version** in `Plantoir/Plantoir.csproj` (`<Version>`), commit.
2. **Full test pass**: `dotnet test Plantoir.Tests` (all green), plus a
   hand smoke of create → preview → deploy on a real course.
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

## Notes

- The PRI249 "Invalid qualifier: SOCIAL-EMOTIONAL LEARNING SKILLS"
  warning during publish is noise: the resource indexer misreads an
  example-content filename as a language qualifier. Harmless.
- GitHub's asset size limit (2 GB) is nowhere near a concern.
- With a valid Artifact Signing signature + timestamp, SmartScreen
  warnings fade as reputation accrues to the signing identity; the
  "Unblock" instructions on plantoir.app can be softened after the first
  signed release proves out on a fresh machine.
