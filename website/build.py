#!/usr/bin/env python3
"""Build plantoir.app from the sources in this folder.

The finished site is written to ``site/`` at the top of the repository, which
is what Netlify deploys. Nothing here is served: page sources, the layout and
the screenshot harness stay outside the published folder.

Usage::

    python3 website/build.py             # write site/
    python3 website/build.py --check     # report problems, write nothing

A page is one file in ``website/pages/``: a short front matter block, then the
body as HTML. Everything shared -- masthead, navigation, footer, the head tags
-- lives in ``website/layout/base.html`` so it cannot drift between pages.

Screenshots are referenced by name rather than by path::

    {{shot:courses}}

which expands to a <picture> that serves the dark-appearance capture to a
visitor whose computer is set to dark, and the light one otherwise. The alt
text and caption come from ``website/shots.json``; the image dimensions are
read from the PNG itself so the page reserves the right space before the image
arrives. A named shot with no file yet builds as a labelled placeholder and a
warning, so the site can be built before the captures are taken.
"""

from __future__ import annotations

import argparse
import json
import re
import shutil
import struct
import sys
from pathlib import Path

WEBSITE = Path(__file__).resolve().parent
REPO = WEBSITE.parent
OUTPUT = REPO / "site"
IMAGE_DIR = OUTPUT / "img"


# ---------- Reading the sources ----------

def read_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def split_front_matter(text: str) -> tuple[dict, str]:
    """Separate a page's leading `---` block from its body."""
    if not text.startswith("---\n"):
        raise ValueError("a page must begin with a --- front matter block")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise ValueError("the front matter block is never closed with ---")
    header = text[4:end]
    body = text[end + 5:]

    fields: dict = {}
    for line in header.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if ":" not in stripped:
            raise ValueError(f"front matter line is not `key: value`: {line}")
        key, value = stripped.split(":", 1)
        fields[key.strip()] = value.strip()
    return fields, body


def load_pages() -> list[dict]:
    pages: list[dict] = []
    for path in sorted((WEBSITE / "pages").glob("*.html")):
        fields, body = split_front_matter(path.read_text(encoding="utf-8"))
        missing = []
        for required in ("title", "description", "nav_label"):
            if required not in fields:
                missing.append(required)
        if missing:
            raise ValueError(f"{path.name} is missing front matter: {', '.join(missing)}")
        fields["slug"] = path.stem
        fields["body"] = body
        pages.append(fields)
    return pages


# ---------- Images ----------

def png_size(path: Path) -> tuple[int, int]:
    """Width and height of a PNG, read from its header."""
    with path.open("rb") as handle:
        header = handle.read(24)
    if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG")
    width, height = struct.unpack(">II", header[16:24])
    return width, height


def picture_element(shot: dict, problems: list[str], modifier: str) -> str:
    """The <picture> for one screenshot, or a placeholder when it is missing."""
    identifier = shot["id"]
    light = IMAGE_DIR / f"{identifier}-light.png"
    dark = IMAGE_DIR / f"{identifier}-dark.png"

    classes = "shot"
    if modifier:
        classes = f"shot shot-{modifier}"

    caption = shot.get("caption", "")
    caption_html = ""
    if caption:
        caption_html = f"\n    <figcaption>{caption}</figcaption>"

    if not light.exists() or not dark.exists():
        problems.append(f"screenshot '{identifier}' has not been captured yet")
        return (
            f'<figure class="{classes}">\n'
            f'    <div class="shot-missing">Screenshot pending: {identifier}</div>'
            f'{caption_html}\n'
            f'</figure>'
        )

    width, height = png_size(light)
    # The captures are taken on a Retina display, so the pixels are twice the
    # size the page should reserve. Halving keeps the layout honest.
    display_width = width // 2
    display_height = height // 2

    # A smaller WebP is written beside every capture. Offering it first saves
    # a visitor roughly two thirds of the download; the PNG stays as the one
    # the <img> falls back to, so nothing depends on WebP being understood.
    sources: list[str] = []
    for scheme, path in (("dark", dark), ("light", light)):
        query = ' media="(prefers-color-scheme: dark)"' if scheme == "dark" else ""
        if path.with_suffix(".webp").exists():
            sources.append(
                f'      <source srcset="/img/{identifier}-{scheme}.webp" '
                f'type="image/webp"{query}>'
            )
        if scheme == "dark":
            sources.append(
                f'      <source srcset="/img/{identifier}-dark.png"{query}>'
            )
    joined = "\n".join(sources)

    return (
        f'<figure class="{classes}">\n'
        f'    <picture>\n'
        f'{joined}\n'
        f'      <img src="/img/{identifier}-light.png" alt="{shot["alt"]}"\n'
        f'           width="{display_width}" height="{display_height}" loading="lazy" decoding="async">\n'
        f'    </picture>{caption_html}\n'
        f'</figure>'
    )


# ---------- Assembling ----------

SHOT_TOKEN = re.compile(r"\{\{shot:([a-z0-9-]+)(?:\|([a-z-]+))?\}\}")


def expand_shots(body: str, shots: dict, problems: list[str], page_name: str) -> str:
    def replace(match: re.Match) -> str:
        identifier = match.group(1)
        modifier = match.group(2) or ""
        shot = shots.get(identifier)
        if shot is None:
            problems.append(f"{page_name} refers to an unknown screenshot: {identifier}")
            return ""
        return picture_element(shot, problems, modifier)

    return SHOT_TOKEN.sub(replace, body)


def demo_links_html(site: dict) -> str:
    """The list of live example class sites, or nothing when they are off.

    The sites are built and published by ``website/shots/capture.py`` when the
    screenshots are taken, and their addresses are recorded in site.json. Set
    ``show_links`` to false there and the block disappears from the page --
    which is what to do if the example sites are ever taken down.
    """
    demo = site.get("demo_sites", {})
    if not demo.get("show_links"):
        return ""

    rows: list[str] = []
    for entry in demo.get("sites", []):
        rows.append(
            f'    <li><span class="label">{entry["code"]}</span> '
            f'<a href="{entry["url"]}">{entry["label"]}</a></li>'
        )
    if not rows:
        return ""
    joined = "\n".join(rows)
    return f'<ul class="links">\n{joined}\n  </ul>'


def navigation_html(pages: list[dict], order: list[str], current_slug: str) -> str:
    links: list[str] = []
    for slug in order:
        page = None
        for candidate in pages:
            if candidate["slug"] == slug:
                page = candidate
        if page is None:
            continue
        href = "/" if slug == "index" else f"/{slug}"
        if slug == current_slug:
            links.append(
                f'<a href="{href}" aria-current="page">{page["nav_label"]}</a>'
            )
        else:
            links.append(f'<a href="{href}">{page["nav_label"]}</a>')
    return "\n      ".join(links)


def plain_navigation_html(pages: list[dict], order: list[str]) -> str:
    """The footer's copy of the navigation: no current-page marking, since
    the footer is a way out of the page rather than a description of it."""
    links: list[str] = []
    for slug in order:
        for candidate in pages:
            if candidate["slug"] == slug:
                href = "/" if slug == "index" else f"/{slug}"
                links.append(f'<a href="{href}">{candidate["nav_label"]}</a>')
    return "\n    ".join(links)


def substitute(template: str, values: dict) -> str:
    result = template
    for key, value in values.items():
        result = result.replace("{{" + key + "}}", str(value))
    return result


def output_path(slug: str) -> Path:
    if slug == "index":
        return OUTPUT / "index.html"
    return OUTPUT / slug / "index.html"


def build(check_only: bool) -> int:
    site = read_json(WEBSITE / "site.json")
    shot_list = read_json(WEBSITE / "shots.json")["shots"]
    shots = {}
    for shot in shot_list:
        shots[shot["id"]] = shot

    pages = load_pages()
    template = (WEBSITE / "layout" / "base.html").read_text(encoding="utf-8")
    problems: list[str] = []

    site_values = {
        "site_name": site["name"],
        "tagline": site["tagline"],
        "base_url": site["base_url"],
        "repo_url": site["repo_url"],
        "support_email": site["support_email"],
        "version": site["version"],
        "released": site["released"],
        "demo_links": demo_links_html(site),
    }

    written: list[Path] = []
    for page in pages:
        body = expand_shots(page["body"], shots, problems, page["slug"] + ".html")
        body = substitute(body, site_values)

        canonical = site["base_url"]
        if page["slug"] != "index":
            canonical = f"{site['base_url']}/{page['slug']}"

        values = dict(site_values)
        values.update({
            "title": page["title"],
            "description": page["description"],
            "canonical": canonical,
            "nav": navigation_html(pages, site["nav"], page["slug"]),
            "nav_plain": plain_navigation_html(pages, site["nav"]),
            "body": body,
            "body_class": page.get("body_class", ""),
        })

        html = substitute(template, values)
        leftover = re.findall(r"\{\{[a-z_]+\}\}", html)
        if leftover:
            problems.append(f"{page['slug']}.html left placeholders unfilled: {', '.join(sorted(set(leftover)))}")

        destination = output_path(page["slug"])
        if not check_only:
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(html, encoding="utf-8")
        written.append(destination)

    if not check_only:
        assets = OUTPUT / "assets"
        assets.mkdir(parents=True, exist_ok=True)
        for asset in sorted((WEBSITE / "assets").iterdir()):
            if asset.is_file():
                shutil.copy2(asset, assets / asset.name)

    for problem in problems:
        print(f"⚠️  {problem}", file=sys.stderr)

    if check_only:
        if problems:
            print(f"\n{len(problems)} problem(s) found.", file=sys.stderr)
            return 1
        print(f"✅ {len(written)} page(s) check out.")
        return 0

    print(f"✅ Built {len(written)} page(s) into {OUTPUT.relative_to(REPO)}/")
    for path in written:
        print(f"   - {path.relative_to(REPO)}")
    if problems:
        print("\nThe site was written, but the warnings above still need attention.", file=sys.stderr)
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Build plantoir.app into site/.")
    parser.add_argument(
        "--check",
        action="store_true",
        help="report problems without writing anything",
    )
    arguments = parser.parse_args()
    return build(check_only=arguments.check)


if __name__ == "__main__":
    raise SystemExit(main())
