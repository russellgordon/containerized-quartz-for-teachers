# Cutting a release — the short version

For future-you, mid-school-year, who remembers nothing. Full story with
all the whys: [`windows-app/RELEASING.md`](windows-app/RELEASING.md).

1. **Everything merged and green?** Mac and Windows work both on `main`;
   `dotnet test` passes in `windows-app/`.

2. **Bump the version**: `<Version>` in
   `windows-app/Plantoir/Plantoir.csproj` (say `1.0.1`). Commit. The mac
   app's marketing version should say the same number.

3. **Build the signed bundle** — in PowerShell:

       az login
       cd windows-app
       powershell -File publish.ps1 -Sign

   It fails fast, with the fix in the message, if anything is missing.
   The bundle lands in `windows-app\dist\`.

4. **Try it like a teacher**: put the zip on a machine (or at least a
   fresh folder), extract, run. Right-click the exe → Properties →
   Digital Signatures → OK + timestamped.

5. **Tell Claude: "cut the release."** It drafts teacher-friendly notes
   from the commits, adds the SHA-256 table, shows you the draft, and
   only after your OK: updates the site's version line, tags
   `v<version>`, and publishes to GitHub. The push makes Netlify redeploy
   plantoir.app by itself, and the site's download buttons serve the new
   files automatically (evergreen links — as long as the assets keep
   their exact names: `Plantoir-win-x64.zip`, `Plantoir-macOS.dmg`).

6. **Same release, mac asset too** — both platforms ship on one GitHub
   release page, the mac file named exactly `Plantoir-macOS.dmg`.

That's it. Steps 5–6 take five minutes; step 3 takes a coffee.
