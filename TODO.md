# To Do

Ideas and deferred work, in no particular order. Add items freely; remove
an item when it ships (finished behaviour is recorded in
[`GUI-IMPROVEMENTS.md`](GUI-IMPROVEMENTS.md), not here).

- **`brand_images.py` is mid-change, and `cut-release` already depends on
  it** — noted 2026-08-14. The release skill instructs
  `python scripts/brand_images.py --install-card` in the same commit as the
  version line, and says the normal outcome is no diff at all. That script
  is currently modified in the working tree with a new `brand/` directory
  beside it. Cutting a release before that work lands would commit a
  half-finished generator alongside the version bump — and `site/social-card.png`
  is a public, widely-cached og:image, so a wrong one is expensive to undo.
  Let the brand work land first.

- **Nothing verifies that a release actually reached plantoir.app** — noted
  2026-08-14. The `cut-release` skill ends by saying the push "redeploys
  plantoir.app automatically (Netlify watches `site/`)" and stops there. No
  check that Netlify's build succeeded, and no check that the live site
  serves the new version. The download links on that page are load-bearing
  for every teacher, so a cheap post-push fetch of `https://plantoir.app`
  confirming the `version-note` line matches the tag would be worth having.

- **Container recreation can kill live previews** — noted 2026-08-11.
  Every launcher "ensures" the working folder's container, and on a
  toolchain-recipe hash or mount mismatch it recreates it (`docker rm
  -f`) — taking any live preview servers down with it. In steady state
  hashes match and this never triggers; it can bite mid-session only in
  rare cases (e.g. an app update refreshing `.toolchain` while another
  window previews). A thorough fix would make the ensure-container step
  decline (or warn) when the container hosts running previews. Low
  priority — rare, and the next preview self-heals.

- **Write the publishing documentation for plantoir.app** — noted
  2026-08-12, once Cloudflare Pages shipped. The app now offers three
  destinations and the picker's captions can only carry so much; the
  website should explain the choice properly. Worth covering: which
  destination suits whom (Netlify as the default; Cloudflare Pages for
  unmetered bandwidth and a free per-section address; a folder for
  teachers whose board gives them their own web space); how to create a
  token for each, with the exact permission Cloudflare needs (Account →
  Cloudflare Pages → Edit) and the fact that a Pages token cannot list
  its own account, which is why the app asks for an Account ID once; and
  the 25 MB per-file limit — documents, images, and slide decks are
  comfortably under it, long-form video is not, and embedding from
  YouTube or Vimeo (what most teachers do anyway) sidesteps it entirely.
  The in-app orange note says the short version; the site should say the
  rest. Screenshots of the Publishing section would help.

- **Hosting options for teachers who can't use Cloudflare or Netlify** —
  researched 2026-08-12, for the documentation above. **The most useful
  finding reframes the question: the "a folder on this PC" destination is
  already the universal answer.** Any teacher with web space of any kind —
  board-provided, a university account, cPanel shared hosting, a NAS —
  can publish to a folder and upload it however they like. No new
  integration is needed for the "my board gives me space" case, and the
  documentation should say so prominently rather than implying Netlify or
  Cloudflare are the only ways.

  That leaves two narrower cases. *Can't create an account with a US
  service* (board policy, privacy rules): the honest answer is that most
  alternatives are also US-hosted, so the realistic options are the folder
  route or a jurisdiction-specific host — **Codeberg Pages** (run by a
  German non-profit) is the notable non-US free option, though it is
  git-based like GitHub Pages. *Wants something free and simpler*:
  **Neocities** is the interesting one — free tier, ad-free, explicitly
  education-friendly, a privacy pledge including no AI training on user
  content, and, unusually for a small host, a documented HTTP API plus a
  CLI with a recursive directory push, which is exactly the shape
  Plantoir needs. Its free tier is small (~1 GB, no custom domain
  without paying) and its branding is hobbyist, so it suits a class site
  more than a department site.

  Ranked for *integration* effort, ignoring what is already built:
  Cloudflare (done), GitHub Pages (deferred above, subpath question
  open), Neocities (small, API-shaped, needs verification), Codeberg
  (git-based, EU). **Vercel stays ruled out** — its Hobby plan forbids
  commercial use in terms broad enough to cover a salaried teacher's
  work; see the earlier assessment. Low-cost rather than free, if a
  teacher will pay a little: Bunny.net storage plus CDN is about a dollar
  a month, and any cPanel host at a few dollars a month already works
  today through the folder route.

  **Caveat on the numbers:** much of the comparison material online is
  affiliate SEO content of low reliability. The Cloudflare, Netlify and
  GitHub figures cited elsewhere in this file were verified directly
  against the vendors; the Neocities and Codeberg specifics were not, and
  need checking before either is documented as a recommendation, let
  alone integrated.

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

- **AI Assist — the rest of it**, deferred 2026-08-13, all on the
  `ai-assist` branch, none of it in 1.0. Step 1 (the MCP server) **is
  built** — see [`AI-ASSIST.md`](AI-ASSIST.md) for the measurements and
  [`windows-app/Plantoir.Mcp/README.md`](windows-app/Plantoir.Mcp/README.md)
  for what shipped. What remains, in the order the evidence suggests:

  **(a) A confirmation panel in the app.** The server already produces the
  proposal — `plan_publish_class` returns a plain-words sentence naming
  every file that would change. Nothing renders it yet. This is the piece
  that makes the whole feature safe, because the one dangerous failure
  measured was polarity inversion (a *hide* request answered with a
  publish), and a teacher reading one sentence catches it where no test
  can. Needed before any in-app assistant, not before the
  bring-your-own-assistant path, which already confirms in the client.

  **(b) The embedded model, opt-in.** Qwen2.5-1.5B-Instruct Q4_K_M on
  llama.cpp with `--no-mmap` — 1.08 GB resident, 2–6 s a warm request,
  100% routing across 27 trials. Roughly 1 GB downloaded on first use plus
  a CPU-only llama.cpp build; nothing ships in the base image. The budget
  is tight and fixed: macOS pins Colima at `--memory 4` regardless of host
  RAM, so both platforms have about 4 GB, and AI Assist and a site build
  must take turns. Offline-only is the recommendation, and not as a
  compromise — course material can name students, which makes sending it
  to a third-party API an MFIPPA question no feature is worth.

  **(c) The CSV reschedule.** Deliberately last. The routing works; the
  tool does not exist. The hard part is parsing a teacher's real CSV and
  rewriting links without breaking the schedule invariant in
  `DEVELOPERS.md` (class pages' links *are* the schedule). Design it to
  accept a *well-formed* CSV and show a diff table before it writes — if
  the CSV is messy enough that the model has to interpret it, that is
  planning, and the measurements say planning is where it fails.

  **(d) The shared activity lease.** The server cannot see the GUI's
  in-flight previews or publishes and vice versa; `CourseActivity` and
  `PreviewLeases` are in-process on both platforms. Overnight this is moot,
  daytime overlap could corrupt a build. A lease file under the working
  folder that both apps and the server honour — a shared-design item, so
  agree the file shape with the mac side first.

- **A "prepare for start of year" operation, and the audit behind it** —
  deferred 2026-08-13, from a real session on the `ai-assist` branch.

  A teacher asked for "every class past Unit 1, Day 1, and everything those
  link to, into draft". Applied exactly, that rule left **32 course-level
  pages still published** that no class page links to at all — a whole
  unit's concepts, plus unassigned tasks and portfolio pages. The teacher
  spotted one (`Concepts/Astronomical Phenomena`, reachable only from an
  investigation that is itself unreferenced) and the rest fell out of an
  audit script.

  **The lesson: link-reachability is a weak proxy for "not yet taught."** A
  link-following rule cannot see a page no class links to, and those are
  precisely the pages a teacher has written ahead. If Plantoir grows a bulk
  start-of-year operation, base it on unit number, date, or an explicit
  teacher-facing "not yet taught" flag — not on what is reachable.

  The other half is worth building on its own: an **audit** that
  cross-references every course-level page against every wikilink in every
  class page and reports three groups — deliberately protected, unreachable
  from any class, and linked-but-missed. The third group being empty is what
  proved the job complete; the second is what proved the *rule* incomplete.
  That is a read-only check the MCP server could offer directly, and it is
  the sort of thing a teacher would want before a term starts regardless of
  whether any AI is involved.
