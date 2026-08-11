# 7. Deployment to Netlify (`deploy.py`)

[◀ Previous: Quartz Customizations](06-quartz-customizations.md) · [Back to index](README.md) · [Next: course_config.json Reference ▶](08-course-config-reference.md)

`scripts/deploy.py` publishes the built `public/` folder for one section to
Netlify. It deliberately does **not** use the Netlify CLI — it speaks the
Netlify REST API directly with Python's standard library (`urllib`), which
keeps the container free of another Node toolchain and gives precise control
over the deploy method.

## Prerequisites and inputs

- The static site must already exist at
  `courses/<CODE>/.merged_output/section<N>/public/` (the launcher runs the
  build first / tells you to).
- `NETLIFY_AUTH_TOKEN` must be in the environment. The deploy **launcher**
  owns the token (macOS Keychain / Windows Credential Manager — see
  [launcher scripts](03-launcher-scripts.md#deploysh)) and injects it; the
  Python script refuses to run without it and never stores it.

## First deploy: site creation and naming

On first deploy of a section, the script creates a Netlify site via
`POST /api/v1/sites` (or under a team with `--team <slug>`). The suggested
site name encodes everything a teacher needs to recognize it later:

```
<course>-s<section>-<year>-<lastname>     e.g.  ics3u-s1-2025-gordon
```

- The teacher's last name is asked once and cached in
  `courses/.internal/profile.json` (a hidden folder that deploy also adds to
  `courses/.gitignore`, along with `_backups/`).
- Names are sanitized to Netlify's subdomain rules, and name collisions
  (Netlify site names are global) trigger a retry prompt with an
  auto-suggested `-02`, `-03`, … suffix.

The created site's identity is saved as a **marker file** at
`courses/<CODE>/.netlify_sites/section<N>.json` so subsequent deploys go to
the same site. (An older layout stored the marker inside the merged output —
which gets wiped by `--full-rebuild`; markers found there are silently
migrated to the stable location. This is also why marker storage lives under
the *course* folder, not the *output* folder.)

The `*.netlify.app` address need not be the address anyone shares: a
teacher can attach a **custom domain** to the site in Netlify and record
it per section in `course_config.json`
(`custom_domains.sections.section<N>`) — the app's published-site links
then wear that domain (host swapped, path preserved, https). `deploy.py`
itself does not consume the key; the domain is configured on Netlify's
side as usual.

## Every deploy: the delta algorithm

Netlify supports a
[file-digest deploy method](https://docs.netlify.com/api/get-started/#deploy-with-the-api):

1. **Manifest.** The script walks `public/`, SHA-1-hashes every file, and
   posts `{"files": {"/index.html": "<sha1>", …}}` to
   `POST /sites/<id>/deploys`.
2. **Required list.** Netlify replies with the digests it has *not* seen
   before — typically a small fraction of the site.
3. **Uploads.** Each required file is `PUT` to
   `/deploys/<id>/files/<path>` as a raw octet stream. Only one upload is
   needed per unique digest even if several paths share content.

Deploys always go to **production** (no draft deploys), matching the
"publish what I previewed" mental model.

<a name="why-determinism-matters"></a>

### Why determinism matters

The delta algorithm is the reason several build-side customizations exist:

- the [stable OverflowList id](06-quartz-customizations.md#b2-stable-id-in-overflowlisttsx)
  (a random id changed every page, every build),
- `TZ=UTC` and a fixed `SOURCE_DATE_EPOCH` in the build environment,
- dropping git/filesystem dates in favour of frontmatter
  ([C1-2/C1-3](06-quartz-customizations.md#c1-applied-on-first-build--full-rebuild)),
- the Curriculum `created` sync being conditional ("only if newer") rather
  than a blind bump on every build.

With those in place, an unchanged page hashes identically build after build,
and a typical daily deploy uploads a handful of files instead of the whole
site.

### Diagnostics

`--diagnose` prints a category breakdown (html / styles / scripts / images /
fonts / …) of what Netlify requested and writes the full ordered list to
`public/_required_last_deploy.txt`. This exists to answer the question "why
did that deploy upload 400 files?" — the usual culprit being some
nondeterminism reintroduced into the build.

### Rate limiting

Netlify's API rate-limits aggressively enough that a class-worth of teachers
deploying at a workshop can hit HTTP 429. API errors are enriched with a
friendly explanation derived from the `X-RateLimit-Reset` header: the current
local time and when the window resets (converted to the teacher's timezone
via `HOST_TZ_OFFSET`). Vendor-specific values like `Retry-After` counts are
deliberately omitted to avoid confusion.

---

[◀ Previous: Quartz Customizations](06-quartz-customizations.md) · [Back to index](README.md) · [Next: course_config.json Reference ▶](08-course-config-reference.md)
