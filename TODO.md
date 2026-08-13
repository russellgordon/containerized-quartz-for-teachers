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
