# Windows Testing Brief — WSL2 Container Runtime Path

> **Audience:** a Claude Code session running on the maintainer's Windows 11 Pro
> machine. This file gives you the context needed to test (and fix) recent
> changes to this toolchain's Windows launchers. Read this fully before
> touching anything.

## Mission

The toolchain recently **dropped its Docker Desktop requirement**. On
Windows, the PowerShell launchers (`setup.ps1`, `preview.ps1`, `deploy.ps1`)
now provision and use the **Docker Engine inside WSL2** automatically. That
code was written and parse-checked on macOS but has **never executed on a
real Windows machine**. Your job: exercise it end to end on this machine,
find what breaks, fix it, and report.

## Background (5-minute orientation)

- This repo publishes teaching websites from Obsidian vaults using a Docker
  container (`rwhgrwhg/teaching-quartz`, on Docker Hub) that wraps a patched
  Quartz v4.5.0. Full architecture docs: [`documentation/README.md`](documentation/README.md),
  especially [`documentation/03-launcher-scripts.md`](documentation/03-launcher-scripts.md)
  (the section "Container runtime bootstrap" describes exactly what you are testing).
- The teacher-facing flow is: `setup.bat` (interactive course wizard) →
  `preview.bat COURSE SECTION` (build + serve on `http://localhost:8081`) →
  `deploy.bat COURSE SECTION` (delta deploy to Netlify).
- Each `.bat` is a thin wrapper that runs the `.ps1` beside it.
- The macOS counterpart of this change (Colima) is **already tested and
  working** — treat the `.sh` scripts as the reference for intended behaviour.

## What the new Windows code does

In each of the three `.ps1` scripts, near the top, there is an identical
block: `Ensure-ContainerRuntime` plus helpers. Its intended behaviour:

1. **Fast path:** if a native `docker` (docker.exe) works, use it unchanged.
2. Otherwise require `wsl` + an installed distribution (else print
   `wsl --install` guidance and exit).
3. Probe `wsl -e docker info` as the default user, then as root
   (`$global:WslUserArgs = @('-u','root')`).
4. If the engine is missing inside WSL, offer to install it:
   `apt-get install docker.io` as root, then `usermod -aG docker <user>`.
5. Start it with `wsl -u root -e sh -c "service docker start"` and poll.
6. On success, define `function global:docker { & wsl $global:WslUserArgs -e docker @args }`
   so every later `docker …` call in the script transparently routes through
   WSL. Bind-mount paths are translated with `Get-MountPath` (wslpath →
   `/mnt/c/...`). `deploy.ps1` additionally has two
   `System.Diagnostics.ProcessStartInfo` invocations that bypass PowerShell
   command resolution — these use `$DOCKER_EXE` / `$DOCKER_PREFIX` variables
   instead.

## Environment notes for this machine

- Windows 11 Pro (build 26100), PowerShell 5.1 minimum target (also test
  under `pwsh` 7 if installed).
- Clone/pull this repo; **test the repo's `.ps1` files directly**. Note that
  the published Docker Hub image still exports the *old* launchers via
  `export-scripts`, so do not test with exported copies.
- The repo stores files with **LF line endings** (depending on
  `core.autocrlf`, your checkout may or may not have CRLF). PowerShell
  handles LF `.ps1` fine. If a `.bat` misbehaves with LF endings, invoke the
  `.ps1` directly (`powershell -NoProfile -ExecutionPolicy Bypass -File .\setup.ps1`)
  and note the finding — in production, teachers receive CRLF copies (the
  image build runs `unix2dos`).
- The container image itself needs no changes; `rwhgrwhg/teaching-quartz:latest`
  from Docker Hub is fine for all tests.
- `courses/` is gitignored — a fresh clone has no courses. The setup wizard
  offers to install an Example Course (**EXC2O**); say yes and use it as the
  test fixture throughout.

## Test plan (in order)

Work through these scenarios; after each, note PASS/FAIL and any output worth
keeping.

**1. Static review.** Read `Ensure-ContainerRuntime` in all three `.ps1`
files and flag anything that cannot work on PowerShell 5.1 before running
anything.

**2. Specific mechanisms I could not verify from macOS** — test these in an
interactive PowerShell first:
   - Empty-array argument flattening: `$e = @(); wsl $e -e echo hi` — confirm
     no stray empty argument reaches wsl (this pattern underpins
     `Test-WslDockerReady` and the `docker` function).
   - `$env:WSL_UTF8='1'; wsl -l -q` — confirm clean, parseable distro names.
   - `Get-Command docker -CommandType Application` behaves on PS 5.1 when no
     docker.exe exists (should return nothing, not throw).
   - After `usermod -aG docker <user>`, does `wsl -e docker info` work
     without `wsl --shutdown`? (The scripts fall back to root if not — confirm
     the fallback engages.)

**3. Scenario: engine not installed.** If this machine's WSL distro has no
Docker engine (or remove it: `wsl -u root -e sh -c "apt-get remove -y docker.io"`),
run `.\preview.ps1 EXC2O 1 --build-only` (after setup) or `.\setup.ps1` and
confirm the install offer appears, works, and the run continues to success.

**4. Scenario: engine stopped.** `wsl --shutdown`, then run a launcher —
confirm it starts the engine itself and proceeds.

**5. Scenario: engine running (fast path).** Re-run immediately — confirm no
install/start work is repeated.

**6. End-to-end teacher flow.**
   - `.\setup.bat` → install the Example Course (EXC2O).
   - `.\preview.bat EXC2O 1` → confirm the container is created with a
     `/mnt/c/...` mount, the build succeeds, and `http://localhost:8081`
     renders in a Windows browser (WSL2 localhost forwarding).
   - Check interactive fidelity through the `wsl`-routed `docker exec -it`:
     wizard prompts, and especially the arrow-key colour scheme picker if you
     run a full course setup.
   - `.\preview.bat EXC2O 1 --build-only` then, **only if a Netlify token for
     a throwaway account is available**, `.\deploy.bat EXC2O 1`. Deploys
     create real Netlify sites — skip otherwise and note as untested.

**7. Edge cases.**
   - Run from a folder whose path contains spaces (e.g.
     `C:\Users\<me>\Class Websites Test\`) — mount translation and quoting.
   - Move the folder, run again — the mount-mismatch recreation logic should
     trigger with `/mnt/c/...` comparisons.
   - `deploy.ps1`'s token-injection steps (the `ProcessStartInfo` ones) — the
     `$DOCKER_PREFIX` quoting through `wsl.exe` is the riskiest untested
     code; verify `/tmp/netlify_pat` arrives in the container intact
     (test with a dummy: pipe text through the same command shape).

## When you find problems

- Fix them in the working tree, keeping the structure parallel across the
  three `.ps1` files (the block is intentionally identical in each) and
  consistent with the `.sh` reference behaviour.
- Commit to a branch named `windows-wsl2-fixes` with clear messages; do not
  push to `main` directly.
- Finish with a summary: scenarios run, PASS/FAIL each, fixes made, and
  anything that remains untested (e.g., a true fresh `wsl --install` if this
  machine already had WSL).

## Ground rules

- Never uninstall WSL or delete existing WSL distros without asking first.
- Don't publish the Docker image (`publish.sh` is macOS-side and out of scope).
- Netlify deploys are opt-in only (they create public sites).
- The `.sh` files are macOS-only — do not "fix" them on Windows.
