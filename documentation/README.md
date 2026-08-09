# Technical Documentation

**Audience:** computer science teachers who want to understand how this toolchain
actually works under the hood — not just how to use it. (For usage instructions,
see the main [README](../README.md); for the workshop walkthrough, see
[PRESENTATION](../PRESENTATION.md).)

This documentation explains the purpose, rationale, and mechanism of every part
of the system, including a complete enumeration of the customizations made to
the stock [Quartz v4.5.0](https://github.com/jackyzha0/quartz/tree/v4.5.0)
static-site generator.

## Reading order

| # | Document | What it covers |
|---|----------|----------------|
| 1 | [Overview & Design Rationale](01-overview.md) | Why this exists, the problems it solves, and the high-level architecture |
| 2 | [The Docker Image](02-docker-image.md) | What is baked into the `teaching-quartz` container and how it is built and published |
| 3 | [The Launcher Scripts](03-launcher-scripts.md) | The host-side `setup` / `preview` / `deploy` scripts for macOS and Windows |
| 4 | [Course Setup](04-course-setup.md) | The interactive wizard (`setup_course.py`) and the folder structure it creates |
| 5 | [The Build Pipeline](05-build-pipeline.md) | How `build_site.py` merges content and produces a per-section Quartz site |
| 6 | [Quartz Customizations](06-quartz-customizations.md) | **The complete list** of every change made to stock Quartz v4.5.0, with purpose and mechanism |
| 7 | [Deployment to Netlify](07-deployment.md) | How `deploy.py` performs delta deploys against the Netlify API |
| 8 | [`course_config.json` Reference](08-course-config-reference.md) | Every key in the per-course configuration file |
| 9 | [The macOS App](09-mac-app.md) | The native GUI wrapper (`mac-app/`) and how it drives the same scripts |

## The one-paragraph summary

A teacher writes course notes as Markdown files in an
[Obsidian](https://obsidian.md) vault, organized into *shared* folders (content
common to every section of a course) and *per-section* folders. A Docker
container — which bundles Python, Node.js, and a patched copy of Quartz
v4.5.0 — merges the shared and section content into a single content tree,
applies roughly thirty targeted patches to Quartz's configuration and
components (colour scheme, fonts, locale, sidebar behaviour, date handling,
and more, all driven by a per-course `course_config.json`), and builds a
static website. The teacher previews the site locally on port 8081, then
deploys it to Netlify using a hash-based delta upload that only transfers
files that actually changed.

## Map of the moving parts

```
HOST (teacher's computer)                CONTAINER (teaching-quartz)
─────────────────────────                ───────────────────────────
setup.sh / setup.ps1      ──docker exec──▶  /opt/scripts/setup_course.py
preview.sh / preview.ps1  ──docker exec──▶  /opt/scripts/build_site.py
deploy.sh / deploy.ps1    ──docker exec──▶  /opt/scripts/deploy.py
                                             │
courses/  ◀──────bind mount──────▶  /teaching/courses/
  ICS3U/                                     │
    course_config.json    ◀── written by setup, read by build
    section1/ … Examples/ …                  │
    .merged_output/section1/  ◀── Quartz scaffold + merged content
        public/           ◀── built site  ──▶  Netlify API
```
