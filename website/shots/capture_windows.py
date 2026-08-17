#!/usr/bin/env python3
"""Take every Windows app screenshot plantoir.app uses, autonomously.

Run it from the top of the repository on a Windows machine::

    python website/shots/capture_windows.py

What it does:
1. Locates or builds the Windows application executable (Plantoir.exe).
2. Runs Plantoir.exe with `--capture-marketing-shots site/img` to capture
   the 5 app-window marketing shots (courses, new-course, progress, preview,
   assistant) in both Light and Dark mode.
3. Scales and optimizes all captured PNGs and produces WebP companions
   via `images.prepare()`.
4. Rebuilds the marketing site (`website/build.py`).
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

REPO = Path(__file__).resolve().parent.parent.parent
WEBSITE = REPO / "website"
IMAGE_DIR = REPO / "site" / "img"

sys.path.insert(0, str(Path(__file__).resolve().parent))
from images import prepare, WIDEST_WINDOW_PIXELS  # noqa: E402


def announce(message: str) -> None:
    print(f"\n▶︎ {message}", flush=True)


def run_command(command: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess:
    print(f"   $ {' '.join(command)}", flush=True)
    return subprocess.run(command, cwd=cwd or REPO, check=True)


def find_or_build_plantoir_exe() -> Path:
    candidates = [
        REPO / "windows-app" / "Plantoir" / "bin" / "Release" / "net9.0-windows10.0.19041.0" / "win-x64" / "publish" / "Plantoir.exe",
        REPO / "windows-app" / "Plantoir" / "bin" / "Debug" / "net9.0-windows10.0.19041.0" / "win-x64" / "publish" / "Plantoir.exe",
    ]
    for candidate in candidates:
        if candidate.exists():
            return candidate

    announce("Building Plantoir Windows application (Release)")
    run_command([
        "powershell", "-ExecutionPolicy", "Bypass", "-File",
        str(REPO / "windows-app" / "publish.ps1")
    ])
    return candidates[0]


def main() -> int:
    announce("Photographing Plantoir on Windows")
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    plantoir_exe = find_or_build_plantoir_exe()

    announce("Running MarketingShotCapturer via Plantoir.exe")
    run_command([
        "powershell", "-Command",
        f"Start-Process '{plantoir_exe}' -ArgumentList '--capture-marketing-shots', '{IMAGE_DIR.resolve()}' -Wait -NoNewWindow"
    ])

    announce("Optimizing Windows screenshots and generating WebPs")
    shot_ids = ["courses", "new-course", "progress", "preview", "assistant"]
    for shot_id in shot_ids:
        for theme in ("light", "dark"):
            png_path = IMAGE_DIR / f"{shot_id}-windows-{theme}.png"
            if png_path.exists():
                prepare(png_path, WIDEST_WINDOW_PIXELS)
                print(f"   ✓ Prepared {png_path.name} + WebP")
            else:
                print(f"   ⚠️ Missing {png_path.name}", file=sys.stderr)

    announce("Rebuilding plantoir.app")
    run_command([sys.executable, str(WEBSITE / "build.py")])

    print("\n✅ Windows screenshots captured and marketing website updated successfully!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
