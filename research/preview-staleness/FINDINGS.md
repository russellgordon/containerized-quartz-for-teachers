# The preview shows stale content — findings, and where to look next

**Written for whoever picks this up next.** Russell hit this repeatedly on
2026-08-15: edit a page (by hand or through the assistant), preview it, and see
the site as it was BEFORE the edit. Pressing the toolbar Reload button shows
the new content.

Several fixes have landed and the symptom was still reported afterwards. This
is what is *established*, what is *assumed*, and the one hypothesis I would
test first — which, if right, lets a good deal of the current machinery be
deleted rather than hardened.

> **Update, 2026-08-15 (later session): the hypothesis was tested.** The port
> mismatch is real, but live reload turns out to be dead for a deeper reason,
> and the timing machinery must stay. See "The hypothesis, tested" at the end.

---

## The symptom, precisely

- Edit a page in Obsidian, or unpublish one with the assistant.
- Preview the section — or stop and restart an existing preview.
- The page shown is the previous build.
- **Pressing Reload shows the correct content**, every time.
- Doing the same thing SLOWLY (waiting several seconds between steps) also
  works.

That last pair is the important shape: the content is *available*, and time or
a manual reload is enough to get it. Nothing is broken about the build.

---

## Verified, with how it was checked

| Claim | How |
|---|---|
| The merge is current | `.merged_output/section1/content/index.md` matched the source and was newer |
| The build is current | `public/index.html` was newer than every source `.md` |
| Unpublished pages really are excluded | all four hidden pages present in `content/`, absent from `public/` |
| `content/` is wiped per build | `shutil.rmtree(content_root)` in `build_site.py` (~line 3568) |
| **Quartz serves the OLD site before rebuilding** | its own `cli/handlers.js`: `server.listen(port)` → prints "Started a Quartz server listening at …" → **then** `await build(clientRefresh)` |

That last row is the root of the original bug: for the first seconds of a
preview, the server answers `200` with the *previous* build.

**The site on disk was right the whole time. Only the screen was wrong.**
Three innocent components were suspected and cleared before that was accepted;
when the disk and the screen disagree, prove which is lying before fixing
either.

---

## What has been fixed, and why each was needed

1. **The web view never reloaded** (`WebPreviewController.loadIfNeeded`).
   It skipped the load when the URL matched the one showing — and a preview
   keeps its port across a stop and a start, so a rebuilt site has the same
   address. `forgetLoadedPage()` is now called when a preview stops.
2. **WebKit's caches.** A request's `cachePolicy` governs only the MAIN
   request, and a Quartz site is a single-page app: the HTML arrived fresh
   while scripts, styles and fetched content came from cache, so the page
   assembled the old site out of parts. Disk, memory, fetch and offline caches
   are now cleared before every load and every Reload. Local storage and
   cookies are deliberately kept (the site's light/dark setting lives there).
3. **The stop raced the build.** `preview.sh --stop` finds processes by
   working directory and, in its own words, "catches builds as well as
   servers", so a stop still running killed the rebuild that followed it. The
   stop is now awaited, and the guard sits at `startPreview` — where a preview
   BEGINS — rather than at each caller.
4. **Waiting for the build before showing anything.** Now keyed on the built
   `public/index.html` mtime CHANGING from what it was before the build
   started.

### A trap inside fix 4, worth not repeating

The first version of that check compared the file's mtime against a timestamp
taken on the Mac. **The file is written inside the Linux VM, whose clock is its
own.** When the VM runs ahead — it does after the Mac sleeps — the previous
build's file already looks newer than "now", so the check passed instantly and
showed exactly the stale page it was written to prevent. Waiting for the value
to *differ* asks nothing of either clock.

---

## The hypothesis I would test first

**Quartz's live reload probably cannot work in this setup, because of the
container-to-host port mapping.** If that is right, fixing it removes the need
for the timing logic altogether: the page would simply refresh itself when a
build lands, which is what Quartz is designed to do.

The numbers, all verified in the source:

- `build_site.py` (~line 3795): `ws_port = port + 1000`, and Quartz is started
  with `--serve --port <container port> --wsPort <container ws port>`. The
  container ports are **8081–8084** and **9081–9084**.
- `preview.sh` (~line 601) publishes them to a per-folder host block:
  `-p $((HOST_BASE + 1000))-$((HOST_BASE + 1003)):9081-9084`, with
  `HOST_BASE` one of **8081, 8091, 8101, 8111, 8121, 8131**.
- `preview.sh` (~line 715) resolves the HOST preview port properly, with
  `docker port`, and announces that — so the page is loaded from, say,
  `localhost:8091`.

But the live-reload client is told the port **Quartz was given**, which is the
CONTAINER's — 9081. On the host, container 9081 is published at
`HOST_BASE + 1000`. So:

- working folder on base **8081** → host ws port 9081 → matches → live reload
  works;
- any other folder (**8091**, 8101, …) → host ws port 9091 → the page dials
  **9081** → nothing listening → **live reload fails silently.**

The same reasoning applies to the second, third and fourth preview in a
folder: container 8082 → ws 9082 → host `HOST_BASE + 1001`.

**Predictions this makes, which are how to test it cheaply:**

- Live reload works in one particular working folder and not in others.
- Editing a page in Obsidian while a preview runs updates the page by itself
  in the working folder, and never in the others.
- In the failing case, the page's console shows a websocket connection error
  to `ws://localhost:9081`.

If it holds, the fix is to tell Quartz the ws port the BROWSER must dial (the
host one) rather than the one it binds inside the container — or to publish
the ws ports so the two numbers agree. Note the two are not independent:
Quartz both binds `--wsPort` inside the container and hands it to the client.
Making them differ may need a small patch to the client script, alongside the
patches already applied in `patches/`.

**If it holds, delete rather than keep:** the whole of Phase 2 in
`SectionDetailView.waitForPreviewServer` — the mtime comparison and the
bounded fallback — exists only because nothing tells the page when the build
has landed. Live reload is that signal, from the tool that knows.

---

## Where the code is

| What | Where |
|---|---|
| Waiting for the build, then showing the preview | `mac-app/QuartzTeachers/Views/Section/SectionDetailView.swift`, `waitForPreviewServer` |
| Cache clearing and loading | `mac-app/QuartzTeachers/Views/Section/WebPreviewController.swift` |
| Stopping, and waiting for a stop | `mac-app/QuartzTeachers/Scripting/PreviewStopper.swift` |
| The assistant's stop → write → start cycle | `mac-app/QuartzTeachers/Models/Assist/AssistToolRunner.swift`, `bringThePreviewUpToDate` |
| Ports, and the launcher's own stop mode | `preview.sh` |
| Quartz invocation and ws port | `scripts/build_site.py`, ~line 3790 |

## One caution

Everything above about Quartz's ordering and the port arithmetic was read from
source and verified. **The live-reload hypothesis itself was not tested** — I
ran out of session before I could bring a preview up and watch the websocket.
Treat it as the most promising lead rather than as a finding, and check the
predictions before building on it.

---

## The hypothesis, tested (2026-08-15, later session)

A real preview was brought up (`./preview.sh EXC2O 1`, container
`teaching-quartz-b18df4b3`, host base 8081 — the one folder where the port
arithmetic lines up) and the websocket was watched directly.

### The port mismatch is real — and worse than predicted

The served page bakes the CONTAINER's ws port, verified by fetching the live
page:

```
$ curl -s http://localhost:8081/ | grep -o "new WebSocket('[^']*')"
new WebSocket('ws://localhost:9081')
```

That number never varies with the host mapping, so every folder's pages dial
host port 9081 — which belongs to whichever folder holds the 8081 block. A
preview in any OTHER folder therefore connects to a *different folder's*
reload server: not silence, **crosstalk** — folder A's rebuild would reload
folder B's page. (During testing, the zombie container below was exactly such
a wrong-number destination, happily accepting connections.)

Russell's actual working folder (`~/Desktop/AI assistant testing`, container
`teaching-quartz-e61f3cd1`, created 2026-08-15 16:38 UTC) sits on host base
**8101** — its pages load from `localhost:8101+` while dialing
`ws://localhost:9081`. It was the failing case throughout. (It is on 8101,
not 8081, so the leaked stub server below never touched it.)

### But live reload is dead even where the port matches

With a client connected to `ws://localhost:9081` (verified OPEN) on the
correctly-mapped folder:

- **Editing merged content from the Mac** — append to
  `.merged_output/section1/content/Learning Goals.md` on the host — produced
  **no rebuild and no ws message** in 45 seconds.
- **The identical edit from inside the container** (`docker exec … >> the same
  file`) produced "Detected change, rebuilding…" and a ws message within a
  second.

Quartz's content watcher (chokidar 4.0.3, `build.ts` ~line 142, default
backend, no polling) runs inside the Linux VM; **file events from Mac-side
writes do not cross the Colima bind mount.** Every edit that matters —
Obsidian, the assistant — is a Mac-side write.

### Two more gaps, even if events flowed

1. **Nothing re-merges while a serve runs.** Quartz watches the merged
   `content/`, but the teacher edits the course folder; the merge runs once,
   at preview start (`build_site.py`), before the ws server even exists. A
   working live reload would still never see an Obsidian edit.
2. **No reconnect.** The injected client (`quartz/plugins/index.ts`,
   `getStaticResourcesFromPlugins`) is three lines with no retry. The app's
   stop→write→start cycle kills the ws server, so a page already on screen
   can never hear the new one.

### Verdict

**Phase 2 of `waitForPreviewServer` stays.** The mtime-change wait is
currently the only correct "build has landed" signal; live reload cannot
replace it without all four of:

1. `CHOKIDAR_USEPOLLING=1` in the container environment — chokidar 4.0.3
   still honors it (verified in its `index.js`), and polling is the standard
   answer to event-less bind mounts;
2. patching the injected client to derive the ws URL from the page's own
   location — `ws://` + `location.hostname` + `:` + (`Number(location.port)
   + 1000`) — valid in every folder because both mappings preserve the
   +1000 offset by construction (`build_site.py`: `ws_port = port + 1000`;
   `preview.sh`: `8081+k → HOST_BASE+k` and `9081+k → HOST_BASE+1000+k`).
   Apply it the way `patch_explorer_inline_expand_on_navigate` does — at
   build time in `build_site.py` — so existing `.merged_output` folders heal
   without `--full-rebuild`;
3. a re-merge watcher, so course-folder edits reach `content/` during a
   serve;
4. reconnect logic in the client, or accepting that live reload only covers
   the keep-the-server-running case.

Items 3 and 4 are architecture changes, not patches. Until someone wants
live reload badly enough to do all four, the current machinery is the fix.

### The symptom, caught live — and the actual bug (2026-08-15, evening)

With a watcher logging the served body's hash, the built file's mtime, the
container state and the port listeners once a second, and the app's unified
log streaming beside it, Russell reproduced the symptom (unpublish "Unit 4,
Day 10", CIA4U s1): the preview reloaded by itself, still showed Day 10, and
a manual Reload showed Day 9.

The chain log acquitted everything below the app: write 15:21:27, merge :28,
new build served :33 — and the build correctly excluded the page. The unified
log then showed THREE `WebPageProxy::loadRequest` navigations, and the middle
one is the whole bug:

1. `15:20:54` — first preview start; loads the fresh build. Correct.
2. `15:21:24.99` — **after the stop's `forgetLoadedPage()` but before the old
   server died**, one more SwiftUI update on the outgoing web view reloaded
   the OLD site — the visible "reload", showing Day 10 — and re-armed
   `lastRequestedURL`.
3. `15:21:36` — Russell's manual Reload. The app's own post-build show at :33
   had compared URLs (same address — a section keeps its port), found them
   equal, and silently skipped; the fallback reload was correctly gated off
   because the build HAD been seen finishing.

So fix 1's `forgetLoadedPage()` encoded "must reload" as cleared state, and a
stray load in the stop-to-start window can re-arm that state. The repair is
`WebPreviewController.showFreshBuild(url)`: when Phase 3 confirms the server,
the fresh site is loaded EXPLICITLY instead of trusting the mounting view's
equality check. It sets the last-requested URL itself, so the view's
`loadIfNeeded` becomes the no-op and this stays one load per rebuild — no
return of the unconditional-reload flicker. A unit test replays the trap
(request the address, let the navigation begin, then `showFreshBuild` must
start another).

**Verified fixed, same evening, same instrumentation.** Russell repeated the
unpublish in the rebuilt app: old server down 16:52:00, write :02, new build
served :06 — and the app issued its own load at 16:52:06.224, the moment the
build landed. The phantom load still fired (16:51:58) and no longer matters:
the explicit load replaces it. No manual Reload was needed.

### Housekeeping found along the way

- **A leaked UI-test stub server was squatting on the preview port.** A
  `python -m http.server 8081 --bind 127.0.0.1` from a
  `QuartzTeachersUITests` xctrunner fixture (`cq4t-fixture-…/stub-site`,
  started 05:55 this morning) was still running. Its specific `127.0.0.1`
  bind beats Colima's wildcard forward, so ALL localhost traffic to 8081 got
  "Stub site" instead of the container — any preview in the 8081-block
  folder while it ran was hijacked outright. **Killed.** The UI tests should
  tear this down (and ideally not use real preview ports).
- **A zombie preview container is still running**: `teaching-quartz-08ececcb`
  (working folder `~/Desktop/moremore`, whose `courses/` is now empty) has a
  Quartz serve for ICS4U s1 whose output directory was deleted out from
  under it. It 404s everything, holds the 8091 port block, and its ws server
  answers the crosstalk calls described above. Left running; safe to
  `docker rm -f` along with the moremore folder.
