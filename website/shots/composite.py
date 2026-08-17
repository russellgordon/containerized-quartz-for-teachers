#!/usr/bin/env python3
"""Build the two figures that are assembled rather than photographed.

Both make a point about COLOUR, which is why they are static images on the
marketing page: a figure showing what three courses look like would be arguing
against itself if it changed to match the reader's own colour scheme.

- `colour-schemes` fans three course home pages out like a hand of cards, so
  the different Quartz schemes sit side by side and can be compared.
- `light-and-dark` puts one site's two schemes next to each other.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

# The finished figures are the same width as every other screenshot on the
# page, so the column edges line up down the whole site.
FIGURE_WIDTH = 1700

CORNER_RADIUS = 18
SHADOW_BLUR = 26


def rounded(image: Image.Image, radius: int = CORNER_RADIUS) -> Image.Image:
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (image.width - 1, image.height - 1)], radius=radius, fill=255
    )
    result = image.convert("RGBA")
    result.putalpha(mask)
    return result


def with_shadow(card: Image.Image) -> Image.Image:
    """A soft drop shadow, so overlapping cards read as a stack."""
    from PIL import ImageFilter

    pad = SHADOW_BLUR * 2
    canvas = Image.new("RGBA", (card.width + pad * 2, card.height + pad * 2), (0, 0, 0, 0))

    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shape = Image.new("L", card.size, 0)
    ImageDraw.Draw(shape).rounded_rectangle(
        [(0, 0), (card.width - 1, card.height - 1)], radius=CORNER_RADIUS, fill=105
    )
    shadow.paste((0, 0, 0, 105), (pad, pad + 6), shape)
    shadow = shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR / 2))

    canvas = Image.alpha_composite(canvas, shadow)
    canvas.paste(card, (pad, pad), card)
    return canvas


def fan(sources: list[Path], destination: Path, visible_fraction: float = 0.42) -> Path:
    """Overlap several captures horizontally, left one behind, right one in front.

    Each card shows `visible_fraction` of its width before the next one covers
    it — enough of the left edge of each site, which is where its colours and
    its typeface live, to compare them at a glance.
    """
    cards = [rounded(Image.open(path).convert("RGBA")) for path in sources]
    if not cards:
        raise SystemExit("Nothing to fan out.")

    # Every card the same height, so the fan sits on one line.
    height = min(card.height for card in cards)
    scaled = []
    for card in cards:
        if card.height != height:
            width = round(card.width * height / card.height)
            card = card.resize((width, height), Image.LANCZOS)
        scaled.append(card)

    step = round(scaled[0].width * visible_fraction)
    total = step * (len(scaled) - 1) + scaled[-1].width

    canvas = Image.new("RGBA", (total, height), (0, 0, 0, 0))
    for index, card in enumerate(scaled):
        shadowed = with_shadow(card)
        canvas.alpha_composite(shadowed, (step * index - SHADOW_BLUR * 2,
                                          max(0, -SHADOW_BLUR * 2)))

    # Trim to the drawn area, then scale to the page's figure width.
    canvas = canvas.crop(canvas.getbbox())
    if canvas.width != FIGURE_WIDTH:
        height = round(canvas.height * FIGURE_WIDTH / canvas.width)
        canvas = canvas.resize((FIGURE_WIDTH, height), Image.LANCZOS)

    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, format="PNG", optimize=True)
    canvas.save(destination.with_suffix(".webp"), format="WEBP", quality=88, method=6)
    return destination


def side_by_side(sources: list[Path], destination: Path, gap: int = 34) -> Path:
    """Two captures next to each other, same size, nothing overlapping."""
    cards = [rounded(Image.open(path).convert("RGBA")) for path in sources]
    height = min(card.height for card in cards)
    scaled = []
    for card in cards:
        if card.height != height:
            width = round(card.width * height / card.height)
            card = card.resize((width, height), Image.LANCZOS)
        scaled.append(card)

    total = sum(card.width for card in scaled) + gap * (len(scaled) - 1)
    canvas = Image.new("RGBA", (total, height), (0, 0, 0, 0))
    offset = 0
    for card in scaled:
        canvas.alpha_composite(card, (offset, 0))
        offset += card.width + gap

    if canvas.width != FIGURE_WIDTH:
        height = round(canvas.height * FIGURE_WIDTH / canvas.width)
        canvas = canvas.resize((FIGURE_WIDTH, height), Image.LANCZOS)

    destination.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(destination, format="PNG", optimize=True)
    canvas.save(destination.with_suffix(".webp"), format="WEBP", quality=88, method=6)
    return destination
