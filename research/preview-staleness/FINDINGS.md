# The preview shows stale content — findings, and where to look next

**Written for whoever picks this up next.** Russell hit this repeatedly on
2026-08-15: edit a page (by hand or through the assistant), preview it, and see
the site as it was BEFORE the edit. Pressing the toolbar Reload button shows
the new content.

Several fixes have landed and the symptom was still reported afterwards. This
is what is *established*, what is *assumed*, and the one hypothesis I would
test first — which, if right, lets a good deal of the current machinery be
deleted rather than hardened.

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
