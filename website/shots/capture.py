#!/usr/bin/env python3
"""Take every screenshot plantoir.app uses, without anyone touching a mouse.

Run it from the top of the repository::

    python3 website/shots/capture.py            # everything
    python3 website/shots/capture.py --app      # just the app windows
    python3 website/shots/capture.py --sites    # just the class websites

What it does, in order:

1. **Provisions a demo working folder** (``~/Teaching`` by default) by driving
   the app's own new-course panel for ENG2D, MCV4U and SCH3U -- three subjects
   chosen so the class sites between them show prose, typeset mathematics and
   chemistry. Skipped when the courses are already there.
2. **Builds and publishes** each of those sections, so the address bar in a
   screenshot reads like a real class site rather than like localhost.
3. **Photographs the app** by running the marketing UI tests, once with the
   Mac in light appearance and once in dark.
4. **Photographs the class sites** in Safari, and on an iPhone in the
   Simulator, again in both appearances.
5. **Rebuilds the site** so the new images are in the pages.

Everything it borrows, it puts back: the Mac's appearance, the app's
remembered window size, the frontmost application, and any Safari window it
opened. It also holds off sleep while it runs, so a capture started at night
survives the displays going dark -- though the Mac itself must stay awake and
unlocked.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from appearance import Appearance          # noqa: E402
from images import prepare, WIDEST_PHONE_PIXELS, WIDEST_WINDOW_PIXELS  # noqa: E402
from safari import SafariWindow            # noqa: E402

REPO = Path(__file__).resolve().parent.parent.parent
WEBSITE = REPO / "website"
IMAGE_DIR = REPO / "site" / "img"
SCRATCH = Path(os.environ.get("TMPDIR", "/tmp")) / "plantoir-marketing-shots"

MAC_APP = REPO / "mac-app"
APP_BUNDLE_DEFAULTS_DOMAIN = "ca.russellgordon.Plantoir"

DEFAULT_WORKSPACE = Path.home() / "Teaching"

# The courses the marketing shots are taken from, and the Netlify site each is
# published to. The naming pattern is the one Russell asked for.
DEMO_COURSES = [
    {"code": "ENG2D", "site": "eng2d-gordon-2026-27"},
    {"code": "MCV4U", "site": "mcv4u-gordon-2026-27"},
    {"code": "SCH3U", "site": "sch3u-gordon-2026-27"},
]

# The simulator used for the phone shot, and the RocketSim helper that draws
# the device around it.
SIMULATOR_DEVICE = "iPhone 17"
ROCKETSIM = Path("/Applications/RocketSim.app/Contents/Helpers/rocketsim")

# Window frames the app remembers between launches. The UI tests override them
# for the duration of a capture; these are saved and put back afterwards so a
# capture run does not resize the windows somebody was working in.
REMEMBERED_FRAME_KEYS = [
    "NSWindow Frame SwiftUI.ModifiedContent<QuartzTeachers.WindowRootView, "
    "SwiftUI._FlexFrameLayout>-1-AppWindow-1",
    # The assistant keeps its own frame under its own key rather than an
    # autosave name — SwiftUI owns the autosave name for that window and
    # overwrites anything put there.
    "AssistantWindowFrame-ENG2D-1",
]

# Where the assistant window should sit for its portrait. Written into the
# app's own preference before the run and put back afterwards, because a
# launch argument does not reliably win against a value the app applies by
# hand after the window is shown.
ASSISTANT_FRAME = "{{500, 60}, {520, 900}}"


# ---------- Running things ----------

def announce(message: str) -> None:
    print(f"\n▶︎ {message}", flush=True)


def run(command: list[str], **keywords) -> subprocess.CompletedProcess:
    print(f"   $ {' '.join(str(part) for part in command)}", flush=True)
    return subprocess.run(command, **keywords)


def stay_awake() -> subprocess.Popen:
    """Hold off sleep -- including display sleep, which is what triggers the
    screen lock that would otherwise break a capture running overnight."""
    return subprocess.Popen(["caffeinate", "-disu", "-w", str(os.getpid())])


# ---------- The app's remembered window sizes ----------

def read_defaults(key: str) -> str | None:
    result = subprocess.run(
        ["defaults", "read", APP_BUNDLE_DEFAULTS_DOMAIN, key],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        return None
    return result.stdout.rstrip("\n")


def write_defaults(key: str, value: str | None) -> None:
    if value is None:
        subprocess.run(
            ["defaults", "delete", APP_BUNDLE_DEFAULTS_DOMAIN, key],
            capture_output=True,
        )
        return
    subprocess.run(
        ["defaults", "write", APP_BUNDLE_DEFAULTS_DOMAIN, key, value],
        capture_output=True,
    )


class RememberedWindowFrames:
    """Puts back whatever window sizes the app had before the capture."""

    def __enter__(self) -> "RememberedWindowFrames":
        self.saved: dict[str, str | None] = {}
        for key in REMEMBERED_FRAME_KEYS:
            self.saved[key] = read_defaults(key)
        return self

    def __exit__(self, exc_type, exc_value, traceback) -> bool:
        for key, value in self.saved.items():
            write_defaults(key, value)
        return False

    def stage_assistant_frame(self) -> None:
        """Put the assistant window where its portrait wants it."""
        write_defaults("AssistantWindowFrame-ENG2D-1", ASSISTANT_FRAME)


# ---------- The UI tests ----------

def run_ui_test(test_identifier: str, workspace: Path, label: str,
                allow_failure: bool = False) -> Path:
    """Run one marketing UI test and return its result bundle.

    With ``allow_failure`` the bundle is returned even when a test failed. The
    captures are independent of one another, and a run where the assistant was
    slow to start should still deliver the five shots that did work rather
    than throwing them away with the sixth.
    """
    bundle = SCRATCH / f"{label}.xcresult"
    if bundle.exists():
        shutil.rmtree(bundle)
    bundle.parent.mkdir(parents=True, exist_ok=True)

    environment = os.environ.copy()
    # xcodebuild does not hand its own environment to the test runner. A
    # variable named TEST_RUNNER_<NAME> arrives there as <NAME>, which is the
    # documented way in; the unprefixed one is set too, for a test run started
    # by hand from Xcode.
    environment["MARKETING_WORKSPACE"] = str(workspace)
    environment["TEST_RUNNER_MARKETING_WORKSPACE"] = str(workspace)

    result = run(
        [
            "xcodebuild",
            "-project", str(MAC_APP / "Plantoir.xcodeproj"),
            "-scheme", "Plantoir",
            "-configuration", "Debug",
            "test",
            "-only-testing:" + test_identifier,
            "-resultBundlePath", str(bundle),
        ],
        cwd=MAC_APP,
        env=environment,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        failures = [line for line in result.stdout.splitlines() if " error: " in line]
        for line in failures[:10]:
            print(f"   ✗ {line.strip()}", file=sys.stderr)
        if not failures:
            print("\n".join(result.stdout.splitlines()[-30:]), file=sys.stderr)
        if not allow_failure:
            raise SystemExit(f"The UI test {test_identifier} failed.")
        print(f"   Some captures failed; keeping the ones that worked.", file=sys.stderr)
    return bundle


def export_attachments(bundle: Path, suffix: str) -> list[str]:
    """Copy a result bundle's screenshots into site/img/<name>-<suffix>.png."""
    exported = SCRATCH / f"{bundle.stem}-attachments"
    if exported.exists():
        shutil.rmtree(exported)
    run(
        ["xcrun", "xcresulttool", "export", "attachments",
         "--path", str(bundle), "--output-path", str(exported)],
        capture_output=True, check=True,
    )

    manifest_path = exported / "manifest.json"
    if not manifest_path.exists():
        return []

    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    saved: list[str] = []
    with manifest_path.open(encoding="utf-8") as handle:
        manifest = json.load(handle)
    for entry in manifest:
        for attachment in entry.get("attachments", []):
            readable = attachment.get("suggestedHumanReadableName", "")
            shot_name = readable.split("_")[0]
            if not shot_name or not readable.endswith(".png"):
                continue
            source = exported / attachment["exportedFileName"]
            destination = IMAGE_DIR / f"{shot_name}-{suffix}.png"
            shutil.copy2(source, destination)
            prepare(destination, WIDEST_WINDOW_PIXELS)
            saved.append(destination.name)
    return saved


# ---------- Provisioning and publishing ----------

def app_bundle_resources() -> Path:
    """The Resources folder of the Debug build the UI tests run against."""
    candidates = sorted(
        (Path.home() / "Library/Developer/Xcode/DerivedData").glob(
            "Plantoir-*/Build/Products/Debug/Plantoir.app/Contents/Resources"
        )
    )
    if not candidates:
        raise SystemExit(
            "No built Plantoir.app found. Build it first:\n"
            "  cd mac-app && xcodebuild -project Plantoir.xcodeproj -scheme Plantoir "
            "-configuration Debug build"
        )
    return candidates[-1]


def mirror_toolchain(workspace: Path) -> None:
    """Put the app's build recipe into the demo folder's `.toolchain/`.

    The app does this itself whenever it touches a working folder — except
    under a UI test, where it deliberately leaves the folder alone so test
    fixtures can keep their stub launchers. The demo folder is a real folder
    being driven by a UI test, so it falls in the gap: without this, creating
    a course fails with "this folder is missing the toolchain's build recipe",
    and the test then waits half an hour for a course that will never appear.

    The file list is the one `WorkspaceModel.refreshToolchain` uses. Keep them
    in step: a file missing here is a recipe the demo folder builds without.
    """
    resources = app_bundle_resources()
    toolchain = workspace / ".toolchain"
    toolchain.mkdir(parents=True, exist_ok=True)

    root_files = [
        "Dockerfile",
        "setup.sh", "preview.sh", "deploy.sh",
        "setup.bat", "preview.bat", "deploy.bat",
        "setup.ps1", "preview.ps1", "deploy.ps1",
    ]
    for name in root_files:
        source = resources / name
        if source.exists():
            shutil.copy2(source, toolchain / name)

    for folder in ["patches", "scripts", "support"]:
        source = resources / folder
        if not source.exists():
            continue
        subprocess.run(
            ["rsync", "-a", "--delete", f"{source}/", str(toolchain / folder) + "/"],
            check=True,
        )
    print(f"   Mirrored the build recipe into {toolchain}")


def workspace_has_course(workspace: Path, code: str) -> bool:
    return (workspace / "courses" / code / "course_config.json").exists()


def ensure_launchers(workspace: Path) -> None:
    """A brand-new folder needs the three launchers before anything else."""
    resources = app_bundle_resources()
    for name in ["setup.sh", "preview.sh", "deploy.sh"]:
        destination = workspace / name
        source = resources / name
        if source.exists():
            shutil.copy2(source, destination)
            destination.chmod(0o755)


def provision(workspace: Path) -> None:
    announce(f"Provisioning the demo courses in {workspace}")
    workspace.mkdir(parents=True, exist_ok=True)
    ensure_launchers(workspace)
    mirror_toolchain(workspace)

    missing = []
    for course in DEMO_COURSES:
        if not workspace_has_course(workspace, course["code"]):
            missing.append(course["code"])
    if not missing:
        print("   All three courses are already there — nothing to do.")
        return

    print(f"   Missing: {', '.join(missing)}. This runs the real setup and takes a while.")
    with RememberedWindowFrames():
        run_ui_test(
            "QuartzTeachersUITests/DemoWorkspaceProvisioning/testCreateDemoCourses",
            workspace,
            "provision",
        )


def build_section(workspace: Path, code: str) -> None:
    """Build a section's site, which is what publishing needs.

    ``--build-only`` writes the pages without then serving them, so this can
    wait for the command to finish rather than watching for files to appear.
    """
    built = workspace / "courses" / code / ".merged_output" / "section1" / "public" / "index.html"
    if built.exists():
        print(f"   {code} is already built.")
        return

    print(f"   Building {code} — the first one also builds the site builder…")
    result = subprocess.run(
        ["./preview.sh", code, "1", "--build-only"],
        cwd=workspace,
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
        timeout=3600,
    )
    if result.returncode != 0 or not built.exists():
        print("\n".join(result.stdout.splitlines()[-30:]), file=sys.stderr)
        raise SystemExit(f"{code} did not build; nothing to publish.")


def remember_teacher_name(workspace: Path, last_name: str = "gordon") -> None:
    """Answer the one question a first publish asks about the teacher.

    Publishing asks for a last name once per working folder, to suggest a site
    name from it. Writing the answer straight into the profile it would save
    means the only thing left on the prompt queue is the site name — and a
    queue of answers that can slip by one is a queue that names a site after
    the wrong prompt.
    """
    profile = workspace / "courses" / ".internal" / "profile.json"
    if profile.exists():
        return
    profile.parent.mkdir(parents=True, exist_ok=True)
    profile.write_text(json.dumps({"teacher_last_name": last_name}, indent=2), encoding="utf-8")
    profile.chmod(0o600)


def publish_section(workspace: Path, code: str, site_name: str) -> None:
    print(f"   Publishing {code} to {site_name}.netlify.app…")
    answers = f"{site_name}\n\n\n\n"
    result = subprocess.run(
        ["./deploy.sh", code, "1"],
        cwd=workspace,
        input=answers,
        capture_output=True,
        text=True,
    )
    print("\n".join(result.stdout.splitlines()[-15:]))
    if result.returncode != 0:
        raise SystemExit(f"Publishing {code} failed.")


def publish_demo_sites(workspace: Path) -> None:
    announce("Building and publishing the demo class sites")
    mirror_toolchain(workspace)
    remember_teacher_name(workspace)
    for course in DEMO_COURSES:
        build_section(workspace, course["code"])
        publish_section(workspace, course["code"], course["site"])


# ---------- Capturing ----------

def clear_built_site(workspace: Path, code: str, section: int) -> None:
    """Throw away one section's built pages, so previewing it really builds.

    The progress capture needs a build that takes long enough to photograph.
    Quartz serves the PREVIOUS build the moment the container is up, so a
    section that has been previewed before comes back almost at once — the
    first two attempts at this photographed the finished site and filed it as
    progress. Deleting the output is what makes the picture honest.
    """
    built = workspace / "courses" / code / ".merged_output" / f"section{section}"
    if built.exists():
        shutil.rmtree(built)
        print(f"   Cleared the built pages for {code} section {section}, so its preview really builds.")


def capture_app(workspace: Path, only: str | None = None) -> None:
    """Photograph the app, once per appearance.

    ``only`` names a single test to run — `test6Assistant`, say — so a shot
    that needs another attempt does not cost a re-run of the five that were
    already right.
    """
    announce("Photographing the app")
    clear_built_site(workspace, "ENG2D", 2)
    target = "QuartzTeachersUITests/MarketingScreenshots"
    if only:
        target = f"{target}/{only}"
    with RememberedWindowFrames() as frames:
        frames.stage_assistant_frame()
        for dark in (False, True):
            suffix = "dark" if dark else "light"
            print(f"   {suffix} appearance")
            with Appearance(dark=dark):
                time.sleep(3)
                bundle = run_ui_test(
                    target,
                    workspace,
                    f"app-{suffix}",
                    allow_failure=True,
                )
            saved = export_attachments(bundle, suffix)
            print(f"   saved {len(saved)} image(s): {', '.join(saved)}")


def site_address(code: str) -> str:
    for course in DEMO_COURSES:
        if course["code"] == code:
            return f"https://{course['site']}.netlify.app"
    raise SystemExit(f"No demo site is configured for {code}.")


def browser_shots() -> list[dict]:
    """The shots taken in a browser, from the manifest the pages read.

    Each names the course and the page to open. Two of them open the course's
    own "What This Site Can Do" page rather than its front page, because that
    is where the typeset mathematics and the chemistry notation are — a course
    home page shows the shape of a site but not what it can carry.
    """
    manifest = json.loads((WEBSITE / "shots.json").read_text(encoding="utf-8"))
    wanted: list[dict] = []
    for shot in manifest["shots"]:
        if shot["capture"].get("kind") == "browser":
            wanted.append(shot)
    return wanted


def capture_sites() -> None:
    announce("Photographing the class websites")
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    shots = browser_shots()
    for dark in (False, True):
        suffix = "dark" if dark else "light"
        print(f"   {suffix} appearance")
        with Appearance(dark=dark):
            time.sleep(3)
            with SafariWindow(1280, 860) as window:
                for shot in shots:
                    capture = shot["capture"]
                    url = site_address(capture["course"]) + capture.get("path", "/")
                    window.load(url, settle_seconds=8.0)
                    destination = IMAGE_DIR / f"{shot['id']}-{suffix}.png"
                    window.capture(destination)
                    prepare(destination, WIDEST_WINDOW_PIXELS)
                    print(f"   saved {destination.name}")
        capture_phone(dark=dark)


def simulator_udid(device_name: str) -> str:
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        capture_output=True, text=True, check=True,
    )
    catalogue = json.loads(result.stdout)["devices"]
    newest = ""
    for runtime in sorted(catalogue.keys()):
        for device in catalogue[runtime]:
            if device["name"] == device_name:
                newest = device["udid"]
    if not newest:
        raise SystemExit(f"No simulator named {device_name} is available.")
    return newest


def capture_phone(dark: bool) -> None:
    """One iPhone screenshot of a class site, inside a device."""
    suffix = "dark" if dark else "light"
    udid = simulator_udid(SIMULATOR_DEVICE)
    was_booted = simulator_is_booted(udid)

    if not was_booted:
        run(["xcrun", "simctl", "boot", udid], capture_output=True)
        time.sleep(30)
    run(["open", "-g", "-a", "Simulator"], capture_output=True)
    time.sleep(5)

    run(["xcrun", "simctl", "ui", udid, "appearance", "dark" if dark else "light"],
        capture_output=True)
    run(["xcrun", "simctl", "status_bar", udid, "override",
         "--time", "9:41", "--batteryState", "charged", "--batteryLevel", "100",
         "--dataNetwork", "wifi", "--wifiBars", "3", "--cellularBars", "4"],
        capture_output=True)

    url = site_address("ENG2D") + "/"
    run(["xcrun", "simctl", "openurl", udid, url], capture_output=True)
    time.sleep(15)
    dismiss_safari_onboarding(udid)

    destination = IMAGE_DIR / f"site-phone-{suffix}.png"
    with destination.open("wb") as handle:
        result = subprocess.run(
            # --udid, not the focused simulator. Without it RocketSim
            # photographs whichever simulator is in front — which, on a Mac
            # with another one already booted, was somebody else's home
            # screen rather than the class site.
            [str(ROCKETSIM), "screenshot", "--udid", udid,
             "--background", "transparent", "--bezel", "device"],
            stdout=handle, stderr=subprocess.PIPE, text=False,
        )
    if result.returncode != 0:
        print(f"   RocketSim could not draw the device: {result.stderr.decode()[:300]}",
              file=sys.stderr)
        # A plain simulator screenshot is better than no phone shot at all.
        run(["xcrun", "simctl", "io", udid, "screenshot", str(destination)],
            capture_output=True)
    prepare(destination, WIDEST_PHONE_PIXELS)
    print(f"   saved {destination.name}")

    if not was_booted:
        run(["xcrun", "simctl", "shutdown", udid], capture_output=True)


def simulator_is_booted(udid: str) -> bool:
    result = subprocess.run(
        ["xcrun", "simctl", "list", "devices", "--json"],
        capture_output=True, text=True, check=True,
    )
    catalogue = json.loads(result.stdout)["devices"]
    for devices in catalogue.values():
        for device in devices:
            if device["udid"] == udid:
                return device["state"] == "Booted"
    return False


def dismiss_safari_onboarding(udid: str) -> None:
    """Close the first-run popover Mobile Safari shows over the page."""
    if not ROCKETSIM.exists():
        return
    subprocess.run(
        [str(ROCKETSIM), "interact", "tap", "--udid", udid, "--label", "Close"],
        capture_output=True,
    )
    time.sleep(1.5)


# ---------- Putting the site back together ----------

def rebuild_site() -> None:
    announce("Rebuilding the site")
    run([sys.executable, str(WEBSITE / "build.py")], cwd=REPO)


def preflight_permissions() -> None:
    """Trip both permission dialogs immediately, so a human can grant them
    and walk away instead of finding one part way through an hour-long run.

    Each dialog blocks whatever triggers it until a human answers, and macOS
    only asks once it is actually needed -- Safari's the first time this
    process sends it an AppleEvent, XCTest's the first time xcodebuild enables
    UI automation. Left alone, that means the Safari prompt appears minutes
    into a --sites run and the XCTest one minutes into --app, which is the
    opposite of "grant it and leave".

    The XCTest half is tripped with the fixture-based smoke test rather than
    anything from MarketingScreenshots: it launches against a disposable
    workspace built into the test bundle, needs no demo folder, no network,
    and no already-published sites, and normally finishes in well under a
    minute. Any UI test would trigger the SAME dialog -- xcodebuild asks
    before the test's own logic runs -- so this one is chosen for speed, not
    for anything it captures.
    """
    announce("Requesting permissions up front (Safari control, then UI automation)")
    print("   If a system dialog appears for either one, approve it now.")

    try:
        subprocess.run(
            ["osascript", "-e", 'tell application "Safari" to activate'],
            capture_output=True, text=True, timeout=60,
        )
    except subprocess.TimeoutExpired:
        print("   Safari did not respond within a minute -- the dialog may still be waiting.")

    result = run(
        ["xcodebuild", "-project", str(MAC_APP / "Plantoir.xcodeproj"),
         "-scheme", "Plantoir", "-configuration", "Debug", "test",
         "-only-testing:QuartzTeachersUITests/QuartzTeachersUITests/testSidebarShowsExampleCourse"],
        cwd=MAC_APP, capture_output=True, text=True, timeout=300,
    )
    if result.returncode != 0:
        print("   The preflight test did not pass -- if a permission dialog is still on screen, "
              "answer it and re-run.", file=sys.stderr)
    else:
        print("   Both permissions are in place.")


def main() -> int:
    parser = argparse.ArgumentParser(description="Capture every screenshot plantoir.app uses.")
    parser.add_argument("--workspace", default=str(DEFAULT_WORKSPACE),
                        help="the demo working folder (must be inside your home folder)")
    parser.add_argument("--provision", action="store_true", help="only create the demo courses")
    parser.add_argument("--publish", action="store_true", help="only build and publish the demo sites")
    parser.add_argument("--app", action="store_true", help="only photograph the app")
    parser.add_argument("--only", default=None,
                        help="with --app, run one capture (e.g. test6Assistant) instead of all of them")
    parser.add_argument("--sites", action="store_true", help="only photograph the class websites")
    arguments = parser.parse_args()

    workspace = Path(arguments.workspace).expanduser()
    if Path.home() not in workspace.parents:
        raise SystemExit("The demo folder has to be inside your home folder, or the site builder sees it as empty.")

    everything = not (arguments.provision or arguments.publish or arguments.app or arguments.sites)
    SCRATCH.mkdir(parents=True, exist_ok=True)

    keeping_awake = stay_awake()
    try:
        preflight_permissions()
        if everything or arguments.provision:
            provision(workspace)
        if everything or arguments.publish:
            publish_demo_sites(workspace)
        if everything or arguments.app:
            capture_app(workspace, only=arguments.only)
        if everything or arguments.sites:
            capture_sites()
        if everything or arguments.app or arguments.sites:
            rebuild_site()
    finally:
        keeping_awake.terminate()

    announce("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
