# To Do

Ideas and deferred work, in no particular order. Add items freely; remove
an item when it ships (finished behaviour is recorded in
[`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md), not here).

- **Stopping a preview orphans its server inside the container** —
  proven empirically 2026-08-11. The app's stop (and clicking away from
  a section, which stops the preview) terminates only the HOST-side
  `preview.sh` process; inside the container the whole serve chain
  (`python3 → npm exec quartz → node → esbuild`) keeps running — the
  orphaned server still answered HTTP 200 after the host script died.
  Bounded in practice: it idles (file-watcher CPU is negligible, though
  it holds node's RAM), the next preview of the same section SIGKILLs
  whatever holds its ports first (`kill_existing_quartz` in
  `build_site.py`), and closing the folder's last window stops the
  whole container. A kill mid-BUILD likewise orphans the build, which
  burns real CPU until it completes, then exits. A proper fix: give the
  launcher a stop mode (e.g. `preview.sh --stop CODE N`) that kills the
  container-side processes for that section's ports, and have the app
  call it whenever a preview stops. Do the same on Windows when this is
  fixed.

- **Container recreation can kill live previews** — noted 2026-08-11.
  Every launcher "ensures" the working folder's container, and on a
  toolchain-recipe hash or mount mismatch it recreates it (`docker rm
  -f`) — taking any live preview servers down with it. In steady state
  hashes match and this never triggers; it can bite mid-session only in
  rare cases (e.g. an app update refreshing `.toolchain` while another
  window previews). A thorough fix would make the ensure-container step
  decline (or warn) when the container hosts running previews. Low
  priority — rare, and the next preview self-heals.

- **Publish stops an active preview itself** — deferred 2026-08-11. The
  idea: the Publish button stays enabled while a preview runs; clicking it
  stops this section's preview, waits for it to end, then publishes —
  saving the teacher the Stop Preview click. A first attempt was rolled
  back: pressing Publish while a preview was still *building* (not yet
  serving) left the app in an indeterminate state. The tricky moment is a
  build-phase preview — the console's ownership, the preview lease, the
  waiting-for-server state, and the publish's own needs-rebuild decision
  are all in flight at once, so stopping and handing off needs a real
  design pass rather than a stop-and-wait bolted onto `startDeploy`. Not
  urgent.
