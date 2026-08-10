# 2. The Docker Image

[◀ Previous: Overview](01-overview.md) · [Back to index](README.md) · [Next: Launcher Scripts ▶](03-launcher-scripts.md)

The image is the entire runtime environment, and it is **built locally on
each machine** from the [`Dockerfile`](../Dockerfile) — no registry of ours
is involved. A working folder carries the build recipe in `.toolchain/`
(kept current by the macOS app); a repository copy IS the recipe. The image
tag is `teaching-quartz:src-<hash>` where the hash covers the recipe's
contents, so an updated recipe produces a new tag, the launcher builds it,
and the container is recreated to match — the whole chain keyed off one
thing: the version of the app.

What a build still fetches from the network, the first time: the
`python:3.11-slim` base image, apt and NodeSource packages, the pinned
Quartz v4.5.0 clone from GitHub, and npm dependencies. After that the build
is cached and everything runs offline.

## Anatomy of the Dockerfile

The image is layered as follows (in order):

1. **Base: `python:3.11-slim`** — Debian slim with Python 3.11. Python is
   needed for the three orchestration scripts; 3.11 also provides `zoneinfo`
   for timezone-correct timestamps.
2. **`pip install python-frontmatter`** — the one Python dependency. It
   parses and rewrites the YAML frontmatter block at the top of each Markdown
   file (used heavily for the per-section `draft`/`created` machinery).
3. **Node.js 20 + tools** — installed from NodeSource. Quartz is a Node
   program (`npx quartz build`). Also installed: `git` (needed to clone
   Quartz), `lsof` (used to kill a previous preview server holding port
   8081), and `dos2unix`/`unix2dos` (line-ending conversion, below).
4. **Clone Quartz v4.5.0 → `/opt/quartz`** — a pinned checkout:
   ```dockerfile
   RUN git clone --branch v4.5.0 https://github.com/jackyzha0/quartz.git quartz
   ```
   Pinning matters because most customizations are regex patches that target
   the exact source text of this version
   (see [Quartz Customizations](06-quartz-customizations.md)).
5. **Overwrite three Quartz components with patched versions** from
   [`patches/`](../patches/):
   - `patches/Explorer.tsx` → `quartz/components/Explorer.tsx`
   - `patches/FolderContent.tsx` → `quartz/components/pages/FolderContent.tsx`
   - `patches/explorer.inline.ts` → `quartz/components/scripts/explorer.inline.ts`

   These three are replaced wholesale (rather than patched at build time)
   because their changes are structural — new imports, reordered rendering
   logic — and would be fragile to express as regex edits. They implement the
   *expandable vs. plain-link folder* behaviour in the sidebar; the details
   are in [customizations §A](06-quartz-customizations.md#a-components-replaced-at-image-build-time).
6. **`cp -r /opt/quartz /opt/quartz-site`** — a spare copy of the scaffold
   (not used by the current build path, which copies from `/opt/quartz`
   directly).
7. **Copy the three Python scripts** into `/opt/scripts/`:
   `setup_course.py`, `build_site.py`, `deploy.py`.
8. **Copy `support/` → `/opt/support/`** — data files consumed by the
   scripts:
   - `ontario_secondary_courses.json` — 1,930 Ontario course codes mapped to
     formal and short names, so the wizard can auto-fill "ICS3U →
     Introduction to Computer Science, Grade 11".
   - `colour_schemes.json` — 43 named colour schemes (a Quartz default, a
     dozen designed palettes, and one per MLB team), each defining the nine
     Quartz theme colours for light and dark mode.
   - `locales/` — all 27 Quartz locale files with teacher-oriented wording
     (see [customizations §D](06-quartz-customizations.md#d-locale-files-replaced-at-build-time)).
   - `Backlinks.tsx` — a patched Backlinks component installed at build time.
   - `obsidian_defaults/.obsidian/` — Obsidian vault settings seeded into new
     courses (e.g. `attachmentFolderPath: "Media"` so pasted screenshots land
     in the shared Media folder).
   - `example_course/EXC2O/` — the complete example course installable from
     the setup wizard.
9. **Bake the launcher scripts into `/opt/export/`** and register an
   `export-scripts` command. This is the distribution trick that means
   teachers never clone this repo:
   ```bash
   docker run --pull=always --rm -v "$PWD:/out" rwhgrwhg/teaching-quartz:latest export-scripts
   ```
   copies `setup/preview/deploy` in all three flavours (`.sh`, `.bat`, `.ps1`)
   into the teacher's current folder. During the image build, `unix2dos`
   converts the `.bat` and `.ps1` files to CRLF line endings — `cmd.exe` can
   misparse LF-only batch files, and the repo itself stores everything with
   LF.
10. **Default state**: working directory `/teaching`, command `/bin/bash`.
    The launchers start the container with `tail -f /dev/null` so it idles
    indefinitely, and every operation is a `docker exec` into it.

## What is *not* in the image

- **Course content.** The host `courses/` folder is bind-mounted at
  `/teaching/courses` at run time; the container is stateless apart from it.
- **Quartz's npm dependencies.** `node_modules` is installed per section
  output folder on first build (and cached thereafter). This keeps the image
  smaller and lets each section pin its own dependency tree.
- **Secrets.** The Netlify token lives in the host's keychain and is injected
  per invocation (see [Deployment](07-deployment.md#token-handling)).

## Building the image

The launchers build the image when the expected tag is missing, with
BuildKit (`docker buildx build --load`) — the legacy builder silently
mangles the `export-scripts` layer. `verify.sh` exercises exactly this
build against a `dev-test` tag and remains the gate for toolchain changes.
The `--image REF` flag on each launcher substitutes a specific already-built
image, which is how `verify.sh` drives the launchers against its own build.

Historical note: the image was previously published to Docker Hub by a
`publish.sh` script and pulled by teachers, with digest-comparison update
checks. That whole apparatus — and its staleness problems — is gone; the
recipe travels with the app instead.

---

[◀ Previous: Overview](01-overview.md) · [Back to index](README.md) · [Next: Launcher Scripts ▶](03-launcher-scripts.md)
