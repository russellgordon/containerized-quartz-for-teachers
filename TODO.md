# To Do

Ideas and deferred work, in no particular order. Add items freely; remove
an item when it ships (finished behaviour is recorded in
[`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md), not here).

- **Container recreation can kill live previews** — noted 2026-08-11.
  Every launcher "ensures" the working folder's container, and on a
  toolchain-recipe hash or mount mismatch it recreates it (`docker rm
  -f`) — taking any live preview servers down with it. In steady state
  hashes match and this never triggers; it can bite mid-session only in
  rare cases (e.g. an app update refreshing `.toolchain` while another
  window previews). A thorough fix would make the ensure-container step
  decline (or warn) when the container hosts running previews. Low
  priority — rare, and the next preview self-heals.

- **GitHub Pages as a third publishing destination** — deferred 2026-08-12.
  Requested by CLI-era users (summer 2025). Feasible and well-bounded, but
  not now. What's known: the Quartz-docs GitHub-template route (build stock
  Quartz in Actions CI) does NOT fit — Plantoir builds patched Quartz
  v4.5.0 locally, so the right route is push-the-built-output to a branch
  Pages serves, written once in the shared `deploy.py` (git is already in
  the container). Videos are fine: GitHub Pages serves 206 Partial Content
  with proper Content-Range (verified empirically 2026-08-12), which is
  what Safari's `<video>` needs; limits are 100 MB/file (hard), ~1 GB/site,
  100 GB/month soft bandwidth — same soft cap as Netlify free. Token story
  parallels Netlify: fine-grained PAT (`contents: read/write`, one repo);
  repo creation + Pages enablement automatable via API. The UI seam already
  exists from rows 101–102 (`deploy_target` picker, milestones, launcher
  flag). Open questions, answerable with a one-session hand-run spike
  (push a built Test 3 section to a throwaway repo) BEFORE any UI work:
  (1) subpath hosting — each section would live at
  `username.github.io/<repo>`, and our patched build has never carried a
  path component in `baseUrl`; (2) Quartz's trailing-slash caveat on Pages
  (`file.html`, no redirect — mostly bites hand-written external links);
  (3) deploy latency (~a minute to go live — milestone wording should say
  "on its way", and the output needs a `.nojekyll`). Shared work: deploy.py
  plus both GUIs — write a proposal note for the mac side (like
  MCP-PROPOSAL.md) when picking this up.

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
