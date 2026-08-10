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
- `--port N` (preview only) — serve on port N. The container publishes
  8081–8084 (plus 9081–9084 for each preview's live-reload websocket), so up
  to four previews can run at once — the macOS app uses this to preview
  sections side by side in separate windows. Each preview only ever stops a
  server on its own port.
- `--context NAME` (setup only) — select a Docker context.

The scripts then ensure a container runtime is available (next section),
pull the image if needed, and print the image's OCI version/created/revision
labels so the teacher knows exactly which build is active.

### Staying up to date

An image that is already on the machine used to be accepted without
question, so a teacher kept whichever build they first downloaded and
later fixes never reached them. `setup.sh` and `preview.sh` (and their
`.ps1` peers) now compare two things:

1. **The published version against the installed one.** The digest from
   the registry is compared with the digest of the local image. If they
   differ, the teacher is told a newer version exists and asked whether to
   install it — never installed behind their back, and never asked at all
   when the run is not interactive (it prints how to update instead) or
   when the image is a local build with no registry to consult. If the
   machine is offline the check simply passes, so being away from a
   network never blocks a build.

2. **The container against the image it should be running.** A container
   keeps running the version it was created from, so pulling a new image
   changes nothing by itself. When the container's image ID differs from
   the image the launcher resolved, the container is recreated. This is
   not asked about: the container holds no state of its own — everything
   lives in the mounted `courses/` folder — and running a version other
   than the chosen one is simply wrong.

`deploy.sh` does neither, deliberately: it resolves no image of its own,
and interrupting a publish to install an update would be a poor moment to
ask.

<a name="container-runtime-bootstrap"></a>

## 3. Container runtime bootstrap (no Docker Desktop)

Docker Desktop is deliberately not required. Every launcher carries an
`ensure_container_runtime` (bash) / `Ensure-ContainerRuntime` (PowerShell)
step that runs before the first `docker` command and removes what used to be
a manual step ("open Docker Desktop and wait for the engine to start"):

**Fast path (both platforms).** If `docker info` already succeeds — any
working engine, including Docker Desktop or Rancher Desktop if a teacher
happens to have one — the launcher uses it as-is and does nothing else.

**macOS: [Colima](https://github.com/abiosoft/colima).** Colima runs a
lightweight Linux VM with a Docker engine inside, driven entirely from the
command line. The bash launchers:

1. Verify Homebrew exists (with a friendly pointer to its installer if not).
2. `brew install colima docker` for whichever is missing (quietly, with
   Homebrew's output captured and shown only on failure, and
   `HOMEBREW_NO_ASK=1` so dependency prompts cannot stall a teacher).
3. Start Colima — the first-ever start passes `--cpu 2 --memory 4` so the VM
   has enough memory for Quartz builds; later starts reuse the saved profile.
4. Poll `docker info` for up to a minute. If the VM claims to be running but
   the daemon never answers (a known Colima state after the Mac sleeps or
   shuts down uncleanly, where a plain `colima start` no-ops), force a clean
   `colima stop --force && colima start` cycle and wait again before giving
   up with manual-recovery instructions.

One consequence worth knowing: Colima's VM mounts the teacher's home
directory by default, so the working folder containing `courses/` must live
somewhere under `$HOME` (Desktop and Documents both qualify) for the bind
mount to work.

**Colima is treated as shared infrastructure.** Other Colima-based
toolchains (for example, a local Supabase development stack) may be using
the same VM on the same machine, so the launchers are deliberately polite
about it: a running engine is always used as-is, the scripts *start* Colima
when needed but never shut it down, and the only disruptive action — the
force-restart in step 4 — happens exclusively when the Docker daemon is
already dead, i.e. when no Colima-based tool is functional anyway
(containers with restart policies come back automatically afterwards).
Whichever toolchain creates the VM first determines its CPU/RAM size; this
toolchain's `--cpu 2 --memory 4` first-start default is modest, so if a
heavier toolchain shares the VM, resize it once with
`colima stop && colima start --cpu 4 --memory 8` (the new size is saved).

**Windows: Docker Engine inside WSL2.** Colima does not support Windows, but
it is not needed there — WSL2 is itself a lightweight, Microsoft-supplied
Linux VM, i.e. exactly the role Colima plays on macOS. The PowerShell
launchers:

1. Check for a native working `docker` first (fast path above).
2. Verify `wsl` exists and a distribution is installed; if not, point the
   teacher at the one-time `wsl --install` + reboot.
3. Probe for a running engine inside WSL (as the default user, then as root).
4. If the engine is absent, offer to install it right there
   (`apt-get install docker.io` as root inside the distro, then add the
   default user to the `docker` group); if merely stopped, start it with
   `service docker start` and poll until it answers.
5. Once the WSL engine is up, define a PowerShell function named `docker`
   that forwards every call through `wsl -e docker …`. Because functions
   take precedence over external commands, the rest of the script (and its
   dozens of existing `docker` call sites) work unchanged. Bind-mount paths
   are translated with `wslpath` (`C:\Users\me\courses` →
   `/mnt/c/Users/me/courses`), since the WSL engine sees Windows drives
   under `/mnt`. Published ports still appear on `localhost` thanks to
   WSL2's automatic localhost forwarding, so the preview URL is unchanged.

## 4. Mount-aware container lifecycle

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

## 5. Per-task specifics

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
