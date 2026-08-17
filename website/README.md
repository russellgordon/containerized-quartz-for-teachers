# plantoir.app

The marketing site. Sources live here; **finished pages are written into
`site/`**, which is what Netlify deploys. Nothing in this folder is served.

```bash
python3 website/build.py          # write site/
python3 website/build.py --check  # report problems, write nothing
```

## What is where

| File | What it is |
|---|---|
| `site.json` | Site-wide facts: the tagline, the repository, the current version and release month, the order of the navigation, and the live example sites. |
| `shots.json` | One entry per screenshot: its id, how it is captured, its alt text and its caption. |
| `layout/base.html` | The page skeleton every page is poured into — head tags, top bar, footer. |
| `assets/style.css` | The whole stylesheet, copied to `site/assets/`. |
| `pages/*.html` | One file per page: a front matter block, then the body. The file name is the URL (`features.html` → `/features`), except `index.html`, which is the front page. |
| `shots/` | The screenshot harness. See below. |

## Writing a page

```html
---
title: What Plantoir does — Plantoir
description: One sentence, used for search results and link previews.
nav_label: Features
---

<div class="page-head">
  <h1>What it does</h1>
  ...
```

`title`, `description` and `nav_label` are required. `body_class` is optional
(the front page uses `home`).

Inside the body you can use:

- `{{shot:courses}}` — a screenshot, by its id in `shots.json`. Add a modifier
  with a pipe: `{{shot:site-phone|device}}` for a capture that already has a
  device drawn around it, `|narrow` for one that should not be widened.
- `{{version}}`, `{{released}}`, `{{repo_url}}`, `{{support_email}}`,
  `{{tagline}}`, `{{site_name}}`, `{{base_url}}` — from `site.json`.
- `{{demo_links}}` — the list of live example class sites.

A page that leaves a `{{placeholder}}` unfilled, or names a screenshot that
does not exist, is reported. `--check` turns that into a non-zero exit, which
is what the release checklist runs.

**Add a page to `site.json`'s `nav` list** or it will be built but never
linked.

## Screenshots

Every image on the site is captured from the real app and the real class
sites, twice — once with the Mac in light appearance and once in dark. The
pages then serve the right one with `<picture>`, so no JavaScript is involved
and a visitor's choice is respected the moment the page loads.

```bash
python3 website/shots/capture.py            # everything
python3 website/shots/capture.py --app      # just the app windows
python3 website/shots/capture.py --sites    # just the class websites
```

It provisions a demo working folder (`~/Teaching` by default) with three
courses — ENG2D, MCV4U and SCH3U, chosen so that between them the class sites
show prose, typeset mathematics and chemistry notation — by driving the app's
own new-course panel. It then builds and publishes those sections, photographs
the app through the marketing UI tests, photographs the published sites in
Safari and on an iPhone in the Simulator, and rebuilds the pages.

The first run takes a long time: it builds the site builder, three courses and
three sites. Later runs reuse all of that, so a re-shoot after an interface
change is minutes.

**The captures themselves are Swift**, in
`mac-app/Tests/QuartzTeachersUITests/MarketingScreenshotTests.swift`. Each
attachment is named for its id in `shots.json`; renaming one there without
renaming it here leaves a placeholder on a published page.

### What it borrows and puts back

The Mac's appearance, the app's remembered window sizes, the frontmost
application, and any Safari window it opened. It holds off sleep while it runs
so a capture started at night survives the displays going dark — but the Mac
itself has to stay awake and unlocked.

### Why not a headless browser

The class sites are photographed in Safari on a real screen because that is
what the type rendering, the scrollbars and the window chrome actually look
like on a Mac. A headless renderer approximates all three. The phone shot uses
the Simulator with RocketSim drawing the device around it, for the same
reason.
