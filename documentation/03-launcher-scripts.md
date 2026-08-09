# 3. The Launcher Scripts

[◀ Previous: The Docker Image](02-docker-image.md) · [Back to index](README.md) · [Next: Course Setup ▶](04-course-setup.md)

The launchers are the only files that live on the teacher's computer. Each
task ships in three flavours:

| Task | macOS | Windows entry point | Windows implementation |
|---|---|---|---|
| Set up a course | `setup.sh` | `setup.bat` | `setup.ps1` |
| Preview a section | `preview.sh` | `preview.bat` | `preview.ps1` |
| Deploy a section | `deploy.sh` | `deploy.bat` | `deploy.ps1` |

The `.sh` scripts target macOS; the `.bat`/`.ps1` pairs are their Windows
peers. (`deploy.sh` enforces this explicitly — it depends on the macOS
Keychain and exits with a pointer to `deploy.ps1` on any other OS.)

The `.bat` files are thin wrappers: they locate the `.ps1` file sitting next
to them and run it with `powershell -NoProfile -ExecutionPolicy Bypass`
(`setup.bat` prefers PowerShell 7's `pwsh` when available). All real Windows
logic is in the `.ps1` scripts, which mirror the bash versions.

All launchers share the same responsibilities, in order:

## 1. Detect the host OS

A small `_detect_host_os` function (`uname -s` → `mac`/`windows`/`linux`)
determines which command syntax to show in help text and, crucially, is
passed into the container as `--host-os` so the Python scripts can print
copy-pasteable follow-up commands in the right dialect (`./preview.sh …` vs
`.\preview.bat …`).

## 2. Resolve which image to use

`setup.sh` and `preview.sh` accept image-selection flags (parity between the
two, so a dev image can be exercised through the whole pipeline):

- `--tag TAG` — use `rwhgrwhg/teaching-quartz:TAG` instead of `latest`.
- `--image REF` — any image reference; a ref without `/` is treated as local
  and is not pulled.
- `--local-dev` — shorthand for the local dev image `quartz-teacher:dev`
  with pulling skipped (used after `docker build -t quartz-teacher:dev .`).
- `--update-image` — force a fresh pull.
- `--context NAME` (setup only) — select a Docker context.

The scripts then verify Docker is installed and the daemon is reachable,
pull the image if needed, and print the image's OCI version/created/revision
labels so the teacher knows exactly which build is active.

## 3. Mount-aware container lifecycle

This is the most subtle part of the launchers. There is a single long-lived
container named `teaching-quartz`, started as:

```bash
docker run -dit --name teaching-quartz \
  -v "$(pwd)/courses":/teaching/courses \
  -p 8081:8081 "$IMAGE" tail -f /dev/null
```

Because teachers may keep *different* course folders in different locations
(e.g. one folder per school year, or a separate folder for a club), every
launcher inspects the existing container before using it:

1. **No `/teaching/courses` mount at all?** Recreate the container.
2. **Mounted from a different host folder than the current one?** Recreate
   it pointing at `$(pwd)/courses`. This is what makes the scripts safe to
   copy into multiple working folders — whichever folder you run from wins.
3. **Mount correct but not writable?** (Checked by creating and deleting a
   probe file inside the container.) Recreate. This catches macOS
   permission/ACL oddities after folder moves or restores.
4. Otherwise, start the container if stopped, or reuse it as-is.

Recreating the container is cheap because all state lives in the bind mount.

## 4. Per-task specifics

### `setup.sh`

- Creates `courses/` and `courses/_backups/` on the host if missing, and
  relaxes permissions (`chmod -R u+rwX,go+rwX`) so the container user can
  write regardless of UID mismatches.
- Captures the host timezone offset (`date +%z`) into `HOST_TZ_OFFSET` so
  frontmatter timestamps written inside the container match the teacher's
  wall clock ([why this matters](05-build-pipeline.md#dates-drive-everything)).
- If `--no-backup` is being passed through, demands explicit confirmation
  first.
- Finally: `docker exec -it teaching-quartz python3 /opt/scripts/setup_course.py …`

### `preview.sh`

- Takes `COURSE SECTION` as positional arguments, plus pass-through flags
  understood by `build_site.py`: `--include-social-media-previews`,
  `--force-npm-install`, `--full-rebuild`, `--build-only`.
- Validates the requested section against `course_config.json`
  (`section_numbers`) *on the host* before ever entering the container, so a
  typo like section `2` in a course with sections `1,3,4` fails fast with a
  helpful message.
- Runs `build_site.py`, which (by default) ends by serving the site on
  `http://localhost:8081` — this is why the container publishes port 8081.

### `deploy.sh`

- Normalizes the course code to uppercase and includes a friendly guard for a
  classic Ontario data-entry error: a course code ending in the digit `0`
  where the letter `O` (an "Open" course) was intended, e.g. `ICD2O` typed as
  `ICD20`. If the `O` variant exists on disk it offers to correct it.
- Verifies the built site exists at
  `courses/<CODE>/.merged_output/section<N>/public/` and tells you to run
  preview/`--build-only` first if not.
- **Token handling** — the launcher, not the container, owns the Netlify
  Personal Access Token:
  - macOS: stored in the **macOS Keychain** under the service name
    `containerized-quartz-netlify` via `/usr/bin/security`.
  - Windows: stored in **Windows Credential Manager** under the same target
    name, accessed through P/Invoke (`CredRead`/`CredWrite`) from PowerShell.
  - Both migrate tokens from a legacy obfuscated file store
    (`courses/.internal/tokens.json`, XOR+base64 with a key file) into the
    OS credential store, then delete the legacy entry.
  - On first run the script opens the Netlify token-creation page, validates
    the pasted token against `GET /api/v1/user`, and saves it.
    `--reset-token` (or `--logout`) clears it.
  - The token is injected into the container by piping it to a root-only
    temp file (`umask 077`) and reading it inside the `docker exec` shell
    into the `NETLIFY_AUTH_TOKEN` environment variable — it never appears in
    a process argument list on the host.
- Finally runs `deploy.py` inside the container
  (see [Deployment](07-deployment.md)).

## A note on line endings

The repository stores every file with LF endings. At image-build time,
`unix2dos` converts the exported `.bat`/`.ps1` copies to CRLF (Windows batch
files can misbehave with bare LF). So the copies a teacher receives via
`export-scripts` intentionally differ from the repo versions in line endings
only.

---

[◀ Previous: The Docker Image](02-docker-image.md) · [Back to index](README.md) · [Next: Course Setup ▶](04-course-setup.md)
