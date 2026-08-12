# To Do

Ideas and deferred work, in no particular order. Add items freely; remove
an item when it ships (finished behaviour is recorded in
[`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md), not here).

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
