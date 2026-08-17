#!/usr/bin/env python3
"""Put the Mac into light or dark appearance, and put it back afterwards.

Screenshots have to be taken twice -- once for each colour scheme -- and the
only faithful way to do that is to set the appearance the app and the browser
will actually read. That is a machine-wide setting, so this module exists to
make sure it is always restored, including when a capture run fails part way
through.
"""

from __future__ import annotations

import subprocess


def _osascript(script: str) -> str:
    result = subprocess.run(
        ["osascript", "-e", script],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def is_dark() -> bool:
    answer = _osascript(
        'tell application "System Events" to tell appearance preferences to get dark mode'
    )
    return answer == "true"


def set_dark(dark: bool) -> None:
    value = "true" if dark else "false"
    _osascript(
        f'tell application "System Events" to tell appearance preferences to set dark mode to {value}'
    )


class Appearance:
    """A context manager that switches appearance and restores what was there.

    ``with Appearance(dark=True):`` leaves the Mac exactly as it found it,
    whatever happens inside the block -- the machine belongs to whoever is
    sitting at it, and a capture run that fails must not leave their computer
    in the wrong colour scheme.
    """

    # MARK: - Initializer

    def __init__(self, dark: bool):
        self.wanted_dark: bool = dark
        self.original_dark: bool = False

    # MARK: - Functions

    def __enter__(self) -> "Appearance":
        self.original_dark = is_dark()
        if self.original_dark != self.wanted_dark:
            set_dark(self.wanted_dark)
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> bool:
        if is_dark() != self.original_dark:
            set_dark(self.original_dark)
        return False
