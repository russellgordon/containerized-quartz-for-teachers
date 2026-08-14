---
name: cut-release
description: Cut a Plantoir GitHub release - drafts teacher-friendly release notes from the commits since the last tag, verifies the bundle's SHA-256 into the notes, tags, and publishes via gh. Run when the user says to cut/publish a release.
---

# Cutting a Plantoir release

You are drafting for TEACHERS, not developers. The release notes are the
only part of the process that needs judgement; everything else is
mechanical. `windows-app/RELEASING.md` is the authoritative checklist —
this skill automates its steps 5–6 and the note-writing.

## Gather

1. Last release: `git describe --tags --abbrev=0` (if no tag exists,
   this is the first release — summarize the product, not the delta).
2. The story since: `git log <last-tag>..HEAD --pretty=format:'%s%n%b%n---'`
3. The bundle(s) to attach — normally `windows-app/dist/Plantoir-win-x64.zip`
   freshly produced by `publish.ps1 -Sign` (confirm with the user that
   the SIGNED bundle exists; never attach an unsigned one to a public
   release). Compute each asset's hash yourself:
   `(Get-FileHash <zip> -Algorithm SHA256).Hash.ToLower()` — from the
   EXACT file being uploaded, never trusted from memory or logs.
   Asset names are LOAD-BEARING: `Plantoir-win-x64.zip` and
   `Plantoir-macOS.zip`, exactly — plantoir.app's download links resolve
   `releases/latest/download/<asset-name>`, so a renamed asset silently
   breaks the site. Refuse to attach an asset under any other name.
4. Confirm `<Version>` in `windows-app/Plantoir/Plantoir.csproj` matches
   the intended tag, and that the working tree is clean.

## Write the notes

Style rules, in order of importance:

- **Normie-friendly**: a teacher who has never read a commit message
  must understand every line. "The sidebar no longer folds up after you
  create a course" — not "Reconcile TreeView ItemsSource in place".
- Group under at most three headings, in this order, omitting empty
  ones: **New**, **Improved**, **Fixed**.
- One line per item, plain sentences, no jargon, no file names, no
  commit hashes, no PR references.
- SKIP internal work entirely: refactors, test infrastructure, CI,
  release machinery, doc reshuffles, anything a teacher cannot observe.
  Many commits produce NO line — that is correct behaviour.
- Merge related commits into one line (three commits fixing the same
  sidebar bug are one bullet).
- Cover BOTH platforms when the release carries both assets; label
  platform-specific items "(Windows)" / "(macOS)" only when they truly
  apply to one side.
- End with a **Downloads** section listing each attached asset, its
  size, and its SHA-256 in a table:

  | File | Size | SHA-256 |
  | --- | --- | --- |
  | Plantoir-1.0.0-win-x64.zip | 58.5 MB | `043a1c…` |

  Below the table, one line: "The SHA-256 lets your IT department verify
  the download is genuine."

Show the drafted notes to the user for approval BEFORE tagging or
publishing anything.

## Publish (after approval)

1. Update the site's version line: in `site/index.html`, rewrite the
   `class="version-note"` line to the new version and release month/year
   (keep the "All releases" link). Commit it.
2. Tag and release:

```
git tag v<version>
git push origin main v<version>
gh release create v<version> <assets...> --title "Plantoir <version>" --notes-file <notes.md>
```

The push redeploys plantoir.app automatically (Netlify watches `site/`),
and the evergreen download links now serve the new assets — nothing
manual remains for the site. Remind the user only of: the mac asset (if
it attaches separately, named exactly `Plantoir-macOS.zip`), and — once
WinSparkle lands — the appcast entry.

**Redraw the brand images in the same commit as the version line.** After
editing `site/index.html` and before tagging, run:

```
python scripts/brand_images.py --install-card
```

This draws the og:image, the profile photos and the Bluesky banner from
`mac-app/Plantoir.icon`, and installs the card to `site/social-card.png`
so Netlify deploys it with the rest of the push.

The output is deterministic, so **the normal outcome is no diff at all** —
`git status` stays quiet and you commit only the version line. Do not
report that as a failure or re-run it. Files change only when the icon,
the palette or the tagline moved since the last release.

If it does produce a diff, stop and show the user the changed images
before committing: `site/social-card.png` is a public, widely-cached
og:image, and a release push deploys it. Say plainly which files changed
and why you think they did. Commit them alongside the version line so the
card and the release ship together.

Stage by path — never `git add -A`. Other work may be in the tree.

See "Brand images" in `windows-app/RELEASING.md`.
