# 2. The Docker Image

[◀ Previous: Overview](01-overview.md) · [Back to index](README.md) · [Next: Launcher Scripts ▶](03-launcher-scripts.md)

The image `rwhgrwhg/teaching-quartz` is the entire runtime environment. It is
built from the [`Dockerfile`](../Dockerfile) at the repository root and
published to Docker Hub by [`publish.sh`](../publish.sh). Teachers only ever
*pull* it; this repository is needed only to *build* it.

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

## Building and publishing the image (`publish.sh`)

`publish.sh` is the maintainer-facing script (teachers never run it):

- Builds a **multi-architecture** image (`linux/amd64,linux/arm64`) with
  `docker buildx`, so Apple Silicon and Intel/Windows machines both run
  natively.
- **Date-based versioning**: tags default to `vYYYY.MM.DD`; if that tag
  already exists on Docker Hub, it auto-increments to `-b2`, `-b3`, … The
  `latest` tag is always pushed alongside.
- Defaults to `--no-cache` for reproducibility (override with
  `--allow-cache`).
- Verifies the pushed manifests with `docker buildx imagetools inspect`.

The launchers display the image's OCI labels (version, created date,
revision) at startup so a teacher can tell at a glance which build they are
running, and support `--tag`, `--image`, `--update-image`, and `--local-dev`
flags for pulling specific versions or testing a locally built image
(`docker build -t quartz-teacher:dev .`).

---

[◀ Previous: Overview](01-overview.md) · [Back to index](README.md) · [Next: Launcher Scripts ▶](03-launcher-scripts.md)
