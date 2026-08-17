#!/usr/bin/env python3
"""Get a screenshot ready to be served.

A capture comes off the screen at the display's own resolution, which is about
twice what the page ever needs and several times the file size a visitor
should be asked to download. Every saved shot is therefore scaled down to
twice its largest drawn size and written twice: a PNG, and a WebP the page
offers first.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

# Twice the widest the page ever draws each kind of shot, so a Retina screen
# still gets a pixel per pixel and nobody downloads more than that.
WIDEST_WINDOW_PIXELS = 1700
WIDEST_PHONE_PIXELS = 720


def prepare(path: Path, widest: int = WIDEST_WINDOW_PIXELS) -> Path:
    """Scale a capture down if it is oversized, then write PNG and WebP."""
    with Image.open(path) as opened:
        image = opened.convert("RGBA")

    if image.width > widest:
        height = round(image.height * widest / image.width)
        image = image.resize((widest, height), Image.LANCZOS)

    image.save(path, format="PNG", optimize=True)
    image.save(path.with_suffix(".webp"), format="WEBP", quality=88, method=6)
    return path
