#!/usr/bin/env python3
"""Capture a web page as a real Safari window.

Everything a visitor sees of a class site -- the type rendering, the
scrollbars, the window chrome -- comes from macOS, so the screenshots are
taken from a real browser on a real screen rather than from a headless
renderer that only approximates it.

The window this opens is a NEW one, addressed by its own id, and it is closed
again at the end. Whatever Safari windows were already open are not touched,
and the application that was in front beforehand is put back in front.
"""

from __future__ import annotations

import subprocess
import time
from pathlib import Path

from PIL import Image, ImageDraw

# macOS rounds a window's corners; a rectangular capture therefore picks up a
# few pixels of whatever was behind them. Rounding the saved image by the same
# amount turns those into transparency instead. Points, doubled below for the
# Retina capture.
CORNER_RADIUS_POINTS = 11


def osascript(script: str) -> str:
    result = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def frontmost_application() -> str:
    return osascript(
        'tell application "System Events" to get name of first process whose frontmost is true'
    )


def round_corners(path: Path, radius_pixels: int) -> None:
    """Make the four corners transparent, so no desktop shows through."""
    image = Image.open(path).convert("RGBA")
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (image.size[0] - 1, image.size[1] - 1)],
        radius=radius_pixels,
        fill=255,
    )
    image.putalpha(mask)
    image.save(path)


class SafariWindow:
    """One throwaway Safari window, used for a run of captures."""

    # MARK: - Initializer

    def __init__(self, width: int, height: int, left: int = 60, top: int = 60):
        self.width: int = width
        self.height: int = height
        self.left: int = left
        self.top: int = top
        self.window_id: str = ""
        self.previous_application: str = ""

    # MARK: - Functions

    def __enter__(self) -> "SafariWindow":
        self.previous_application = frontmost_application()
        osascript('tell application "Safari" to activate')
        self.window_id = osascript(
            'tell application "Safari"\n'
            '  make new document with properties {URL:"about:blank"}\n'
            '  return id of window 1\n'
            'end tell'
        )
        self.resize(self.width, self.height)
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> bool:
        if self.window_id:
            try:
                osascript(f'tell application "Safari" to close window id {self.window_id}')
            except subprocess.CalledProcessError:
                pass
        if self.previous_application:
            try:
                osascript(f'tell application "{self.previous_application}" to activate')
            except subprocess.CalledProcessError:
                pass
        return False

    def resize(self, width: int, height: int) -> None:
        self.width = width
        self.height = height
        right = self.left + width
        bottom = self.top + height
        osascript(
            f'tell application "Safari" to set bounds of window id {self.window_id} '
            f'to {{{self.left}, {self.top}, {right}, {bottom}}}'
        )
        time.sleep(0.4)

    def load(self, url: str, settle_seconds: float = 3.0) -> None:
        osascript(
            f'tell application "Safari" to set URL of document of window id {self.window_id} to "{url}"'
        )
        time.sleep(settle_seconds)

    def press(self, keystroke: str, using: str = "") -> None:
        """Send a keystroke to the front window through System Events.

        Safari's own AppleScript vocabulary cannot type into a page, and
        running JavaScript from an Apple Event is off by default and cannot be
        turned on programmatically. System Events can, which is how the search
        panel gets opened and typed into.
        """
        modifier = f" using {using}" if using else ""
        osascript(
            f'tell application "Safari" to activate\n'
            f'delay 0.4\n'
            f'tell application "System Events" to keystroke "{keystroke}"{modifier}'
        )
        time.sleep(1.0)

    def capture(self, destination: Path) -> Path:
        """Save the window itself, by window number.

        `screencapture -l` grabs that WINDOW's contents — the same thing the
        Option-click window capture gives: no shadow, transparent corners, and
        crucially independent of what is in front of it.

        The region capture this replaces photographed a RECTANGLE OF SCREEN. It
        depended on Safari having finished coming to the front, and when that
        lost a race the result was a screenshot of whatever was behind — once, a
        terminal window filed as a class website. A wrong screenshot that looks
        like a right one is the worst failure this harness has, so the mechanism
        that allows it is gone.
        """
        destination.parent.mkdir(parents=True, exist_ok=True)
        number = self.window_number()
        subprocess.run(
            ["screencapture", "-x", "-o", "-l", str(number), str(destination)],
            check=True,
        )
        if not destination.exists() or destination.stat().st_size == 0:
            raise SystemExit(f"screencapture wrote nothing for window {number}.")
        return destination

    def window_number(self) -> int:
        """The CoreGraphics window number for this Safari window.

        Read fresh each time: window numbers survive a page load, but not a
        window being closed and reopened, and a stale one captures nothing.
        """
        helper = Path(__file__).resolve().parent / "windowid.swift"
        result = subprocess.run(
            ["swift", str(helper), "Safari"],
            capture_output=True, text=True,
        )
        if result.returncode != 0 or not result.stdout.strip():
            raise SystemExit(f"Could not find Safari's window: {result.stderr.strip()}")
        return int(result.stdout.strip())


def image_scale(path: Path, width_in_points: int) -> int:
    """How many pixels the display draws per point, as a whole number."""
    with Image.open(path) as image:
        pixels_wide = image.size[0]
    if width_in_points <= 0:
        return 1
    return max(1, round(pixels_wide / width_in_points))
