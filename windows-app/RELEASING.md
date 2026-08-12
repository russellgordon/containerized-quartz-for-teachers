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
3. **Build the signed bundle** (one-time setup: the Azure Artifact
   Signing runbook; per-session: `az login`):

       powershell -File publish.ps1 -Sign

   The script refuses to package a signature without a timestamp. Output:
   `dist/Plantoir-<version>-win-x64.zip` + its SHA-256.
4. **Verify like a teacher** (the only test that reproduces what they
   see): copy the zip to a machine — or at least a fresh folder —
   download it through a browser if possible, extract, right-click
   `Plantoir.exe` → Properties → Digital Signatures → signature OK,
   timestamp present, no street address in the certificate subject.
5. **Tag and release**:

       git tag v<version>
       git push origin main v<version>
       gh release create v<version> dist/Plantoir-<version>-win-x64.zip \
         --title "Plantoir <version>" --notes "..."

   The mac side attaches its own asset (dmg/zip) to the SAME release, so
   plantoir.app's two download cards can both point at
   `releases/latest`.
6. **Update plantoir.app**: the version-note line (version + date) in
   `index.html`; redeploy the site.
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
