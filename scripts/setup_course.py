import os
import json
import subprocess
from pathlib import Path
import re
import sys
import tty
import termios
from datetime import datetime, timezone, timedelta
import textwrap
import zipfile  # NEW: for backups
import argparse  # NEW: for --no-backup flag
import shutil   # NEW: needed for copying example course
import random   # NEW: for generating alternate example course code
import string   # NEW: for generating alternate example course code

DEFAULT_SHARED_FOLDERS = [
    "Concepts", "Discussions", "Examples", "Exercises", "Media",
    "Ontario Curriculum", "College Board Curriculum", "Portfolios",
    "Recaps", "Setup", "Style", "Tasks", "Tutorials"
]

DEFAULT_SHARED_FILES = [
    "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md"
]

DEFAULT_PER_SECTION_FOLDERS = ["All Classes"]

DEFAULT_PER_SECTION_FILES = [
    "Private Notes.md", "Scratch Page.md", "Key Links.md"
]

COURSE_LOOKUP_PATH = Path("/opt/support/ontario_secondary_courses.json")

# ---------- NEW: Backup exclusion set ---------------------------------------
BACKUP_DEFAULT_EXCLUDES = {
    "node_modules",
    ".git",
    ".quartz-cache",
    ".cache",
    "dist",
    "build",
    "out",
    ".DS_Store",
    "__pycache__",
    ".merged_output",  # constructed output – exclude from backups
}

def _iter_nonempty(p: Path) -> bool:
    """Return True if directory exists and has at least one entry."""
    if not p.exists() or not p.is_dir():
        return False
    try:
        next(p.iterdir())
        return True
    except StopIteration:
        return False

def backup_existing_course_dir(course_dir: Path, backup_root: Path, excludes: set[str] | None = None) -> Path | None:
    """
    If course_dir exists and is non-empty, create a zip backup at:
      backup_root / course_dir.name / YYYY-MM-DD_HHMMSS.zip
    Skips folders/files listed in `excludes` (merged_output, caches, etc.).
    Returns the created zip path, or None if nothing was backed up.
    """
    excludes = (excludes or set()) | BACKUP_DEFAULT_EXCLUDES

    if not _iter_nonempty(course_dir):
        return None

    backup_base = backup_root / course_dir.name
    backup_base.mkdir(parents=True, exist_ok=True)
    ts = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d_%H%M%S")
    zip_path = backup_base / f"{ts}.zip"

    print(f"🛟 Backing up existing course folder: {course_dir}")
    print(f"    → Excluding: {', '.join(sorted(excludes)) or '(none)'}")
    print(f"    → Writing:   {zip_path}")

    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for root, dirs, files in os.walk(course_dir):
            # Prune excluded directories in-place
            dirs[:] = [d for d in dirs if d not in excludes]
            rel_root = os.path.relpath(root, course_dir)
            if rel_root == ".":
                rel_root = ""
            for name in files:
                if name in excludes:
                    continue
                src = Path(root) / name
                rel = Path(rel_root) / name
                try:
                    if src.is_file():
                        zf.write(src, rel.as_posix())
                except FileNotFoundError:
                    # Ignore broken symlinks / races
                    pass

    print("✅ Backup complete.\n")
    return zip_path

# ---------- Colour scheme support (added) -----------------------------------

CANDIDATE_COLOUR_JSON_PATHS = [
    Path("support/colour_schemes.json"),
    Path("/opt/support/colour_schemes.json"),
    Path(__file__).resolve().parent.parent / "support" / "colour_schemes.json",
    Path(__file__).resolve().parent / "support" / "colour_schemes.json",
]

def load_colour_schemes():
    for p in CANDIDATE_COLOUR_JSON_PATHS:
        if p.exists():
            with open(p, "r", encoding="utf-8") as f:
                data = json.load(f)
            # Accept either list or {"schemes":[...]}
            if isinstance(data, dict) and "schemes" in data:
                data = data["schemes"]
            return data
    print("⚠️  colour_schemes.json not found. Skipping scheme selection.")
    return []

def hex_to_rgb(s):
    s = s.strip()
    if s.startswith("#") and len(s) == 7:
        return int(s[1:3], 16), int(s[3:5], 16), int(s[5:7], 16)
    if s.startswith("#") and len(s) == 4:
        r = int(s[1]*2, 16)
        g = int(s[2]*2, 16)
        b = int(s[3]*2, 16)
        return r, g, b
    if s.lower().startswith("rgba"):
        try:
            nums = s[s.find("(")+1:s.find(")")].split(",")
            r, g, b = [int(float(x.strip())) for x in nums[:3]]
            return r, g, b
        except Exception:
            pass
    return (128, 128, 128)

def bg_rgb(r, g, b): 
    return f"\x1b[48;2;{r};{g};{b}m"

RESET = "\033[0m"
BOLD  = "\x1b[1m"

def block(color_hex, width=10):
    r, g, b = hex_to_rgb(color_hex)
    return f"{bg_rgb(r,g,b)}{' ' * width}{RESET}"

def clear_screen():
    sys.stdout.write("\x1b[2J\x1b[H")
    sys.stdout.flush()

def getch():
    """Read single keypress (supports arrow left/right) without Enter."""
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    try:
        tty.setraw(fd)
        ch1 = sys.stdin.read(1)
        if ch1 == '\x1b':  # escape
            ch2 = sys.stdin.read(1)
            if ch2 == '[':
                ch3 = sys.stdin.read(1)
                if ch3 == 'C': return 'RIGHT'
                if ch3 == 'D': return 'LEFT'
            return 'ESC'
        if ch1 in ('\r', '\n'):
            return 'ENTER'
        return ch1
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)

def render_scheme_preview_for_section(scheme, idx, total, section_number):
    name = scheme.get("name", scheme.get("id", f"Scheme {idx+1}"))
    colors = scheme.get("colors", {})
    lm = colors.get("lightMode", {})
    dm = colors.get("darkMode", {})

    clear_screen()
    print(f"{BOLD}Colour Scheme for Section {section_number}{RESET}")
    print(f"{BOLD}({idx+1}/{total}) {name}{RESET}\n")

    keys = ["light", "lightgray", "gray", "darkgray", "dark", "secondary", "tertiary", "textHighlight"]

    def column(mode_dict, title):
        print(f"{BOLD}{title}:{RESET}")
        for k in keys:
            sw = block(mode_dict.get(k, "#888888"))
            # Plain text key name with a simple color block beside it
            print(f"  {k:<13} {sw}")
        print()

    column(lm, "Light Mode")
    column(dm, "Dark Mode")

    print("Use ← / → (or 'p' / 'n') to browse, Enter to select. Press 'q' to keep previous choice.")

def interactive_pick_scheme_for_section(schemes, section_number, default_id=None):
    if not schemes:
        return default_id
    start = 0
    if default_id:
        for i, s in enumerate(schemes):
            if s.get("id") == default_id:
                start = i
                break

    i = start
    total = len(schemes)
    while True:
        render_scheme_preview_for_section(schemes[i], i, total, section_number)
        key = getch()
        if key in ('RIGHT', 'n'):
            i = (i + 1) % total
        elif key in ('LEFT', 'p'):
            i = (i - 1 + total) % total
        elif key in ('q', 'Q', 'ESC'):
            return default_id
        elif key == 'ENTER':
            return schemes[i].get("id")

# ---------- Original helpers (preserved) ------------------------------------

def prompt_with_default(prompt_text, default_value):
    response = input(f"{prompt_text} [Default: {default_value}]: ").strip()
    return response if response else default_value

def prompt_select_multiple(prompt_text, options, default_selection=None):
    BLUE = "\033[34m"
    RESET_LOCAL = "\033[0m"

    # Highlight "HIDE" or "EXPANDABLE" in blue if present in prompt_text
    prompt_text = prompt_text.replace("HIDE", f"{BLUE}HIDE{RESET_LOCAL}")
    prompt_text = prompt_text.replace("EXPANDABLE", f"{BLUE}EXPANDABLE{RESET_LOCAL}")

    print(f"\n{prompt_text}")
    for idx, option in enumerate(options):
        if default_selection and option in default_selection:
            print(f"{BLUE}{idx + 1}. {option}{RESET_LOCAL}")
        else:
            print(f"{idx + 1}. {option}")

    if default_selection:
        default_indices = [str(options.index(item) + 1) for item in default_selection if item in options]
        print(f"Enter comma-separated numbers (e.g., 1,3,5) or leave blank to accept default: {','.join(default_indices)}")
    else:
        print("Enter comma-separated numbers (e.g., 1,3,5) or leave blank for none:")

    selection = input("> ").strip()
    if not selection and default_selection is not None:
        return default_selection
    if not selection:
        return []

    try:
        indices = [int(i) - 1 for i in selection.split(",")]
        return [options[i] for i in indices if 0 <= i < len(options)]
    except Exception:
        print("Invalid input. Please try again.")
        return prompt_select_multiple(prompt_text, options, default_selection)

def prompt_type_list(prompt_text, default_list=None, add_md_extension=False, forbidden_names=None):
    """
    Prompt the user for a comma-separated list of items.
    - If forbidden_names is provided, any matches are removed and a warning is printed.
    - If add_md_extension is True, ensure items end with .md.
    """
    forbidden_names = set((forbidden_names or []))
    print(f"\n{prompt_text}")
    if default_list:
        for item in default_list:
            print(f" - {item}")
    print("Enter comma-separated names or leave blank to accept default:")
    entry = input("> ").strip()
    if not entry:
        # Remove forbidden names from defaults silently but warn if they were present
        defaults = default_list if default_list else []
        filtered = [x for x in defaults if x not in forbidden_names]
        removed = [x for x in defaults if x in forbidden_names]
        if removed:
            print(f"ℹ️  Skipping reserved name(s): {', '.join(removed)}")
        return filtered

    raw = [name.strip() for name in entry.split(",") if name.strip()]
    # Remove forbidden names from provided list and warn
    cleaned = []
    removed = []
    for name in raw:
        if name in forbidden_names:
            removed.append(name)
            continue
        cleaned.append(name + ".md" if add_md_extension and not name.endswith(".md") else name)

    if removed:
        print(f"⚠️  The following name(s) are reserved and will be skipped: {', '.join(removed)}. A course-level 'Media' folder is created automatically for storing images/videos and is hidden from the site sidebar.")

    return cleaned

def get_course_name_from_json(course_code):
    if not COURSE_LOOKUP_PATH.exists():
        return None
    try:
        with open(COURSE_LOOKUP_PATH, "r", encoding="utf-8") as f:
            course_data = json.load(f)
        course_info = course_data.get(course_code.upper())
        if not course_info:
            return None

        print(f"\n🔎 Found course info for {course_code}:")
        formal = course_info["formal_name"]
        short = course_info["short_name"]

        if input(f"Use formal name \"{formal}\"? (y/n): ").strip().lower() == "y":
            return formal
        if input(f"Use short name \"{short}\"? (y/n): ").strip().lower() == "y":
            return short
        return input("Enter a custom course name: ").strip()
    except Exception:
        return None

# ---------- New helpers: stateful footer prompt -----------------------------

def capture_multiline() -> str:
    """Capture multi-line input until a single line 'EOF' is entered."""
    print("\nPaste your footer HTML below.")
    print("When finished, type a single line: EOF")
    lines = []
    while True:
        try:
            line = input()
        except EOFError:
            break
        if line.strip() == "EOF":
            break
        lines.append(line)
    return "\n".join(lines).strip()

def prompt_footer_html_stateful(saved_config: dict) -> str:
    current = (saved_config.get("footer_html") or "").strip()
    if current:
        preview = textwrap.shorten(current.replace("\n", " "), width=80, placeholder="…")
        print(f"\n🦶 A custom footer is already set:\n   {preview}")
        choice = input("Press ENTER to keep it, 'e' to edit, or 'c' to clear: ").strip().lower()
        if choice == "":
            print("✅ Keeping existing footer.")
            return current
        if choice == "c":
            print("🧹 Footer cleared.")
            return ""
        if choice != "e":
            print("↪️ Unrecognized choice; keeping existing footer.")
            return current

        # Edit path
        print("\nEnter the full HTML content you want to display in the footer (example shown):")
        print('The resources on this site by Russell Gordon are licensed under '
              '<a href="http://creativecommons.org/licenses/by/4.0/?ref=chooser-v1" '
              'target="_blank" rel="license noopener noreferrer" style="display:inline-block;">'
              'CC BY 4.0</a> unless otherwise noted.')
        new_html = capture_multiline()
        if not new_html:
            print("↪️ No changes entered; keeping existing footer.")
            return current
        print("✅ Footer updated.")
        return new_html

    # No footer set yet — original y/n flow
    yn = input("\nWould you like to add custom footer HTML? (y/n) [Default: n]: ").strip().lower()
    if yn == "y":
        print("\nEnter the full HTML content you want to display in the footer (example shown):")
        print('The resources on this site by Russell Gordon are licensed under '
              '<a href="http://creativecommons.org/licenses/by/4.0/?ref=chooser-v1" '
              'target="_blank" rel="license noopener noreferrer" style="display:inline-block;">'
              'CC BY 4.0</a> unless otherwise noted.')
        return capture_multiline()
    return ""

# ---------- New helper: yes/no boolean with default -------------------------

def prompt_yes_no_default(prompt_text: str, default: bool) -> bool:
    """
    Ask a yes/no question with a boolean default.
    Example prompt: 'Show page read time estimates to students?'
    Displays [Default: y] or [Default: n] accordingly.
    """
    default_label = "y" if default else "n"
    resp = input(f"\n{prompt_text} (y/n) [Default: {default_label}]: ").strip().lower()
    if resp == "":
        return default
    if resp in ("y", "yes"):
        return True
    if resp in ("n", "no"):
        return False
    print("↪️ Unrecognized input; keeping default.")
    return default

# ---------- New helper: Explorer expansion behaviour (stateful) -------------

def prompt_explorer_expansion_behavior(saved_config: dict) -> bool:
    """
    Returns True if folder should expand when name OR chevron is clicked.
    Returns False if folder should expand ONLY when chevron is clicked.
    Default: False (expand only on chevron).
    """
    last = saved_config.get("expandOnFolderClick")
    default = bool(last) if last is not None else False  # default to chevron-only
    default_idx = 1 if default else 2

    print("\n🧭 Explorer item expansion behaviour")
    print("When clicking folders in the sidebar, choose what should happen:")
    print(f"  1. Expand when chevron or name is clicked{'  ← default' if default_idx == 1 else ''}")
    print(f"  2. Expand only when chevron is clicked{'  ← default' if default_idx == 2 else ''}")

    choice = input(f"Select 1-2 [Default: {default_idx}]: ").strip()
    if choice == "":
        return default
    if choice == "1":
        return True
    if choice == "2":
        return False

    print("↪️ Unrecognized input; keeping default.")
    return default

# ---------- New: Font selection helpers -------------------------------------

FONT_PAIRINGS = [
    # (Header, Body)
    ("Playfair Display", "Source Sans 3"),
    ("Source Serif 4", "Inter"),
    ("Montserrat", "Lora"),
    ("Raleway", "Roboto"),
    ("Poppins", "Merriweather"),
    ("Archivo", "Noto Sans"),
]

CODE_FONTS = [
    "JetBrains Mono",
    "Fira Code",
    "IBM Plex Mono",
    "Source Code Pro",
    "Inconsolata",
    "Ubuntu Mono",
]

def _print_font_pair_menu(default_idx: int | None = None):
    print("\n🅰️  Choose a header/body font pairing (Google Fonts):")
    for i, (hdr, body) in enumerate(FONT_PAIRINGS, start=1):
        marker = "  ← default" if default_idx == i else ""
        print(f"  {i}. {hdr}  —  {body}{marker}")
    marker7 = "  ← default" if default_idx == 7 else ""
    marker8 = "  ← default" if default_idx == 8 else ""
    print(f"  7. System fonts (Helvetica, Arial){marker7}")
    print(f"  8. Enter a custom pair (e.g., 'DM Sans, Inter'){marker8}")

def _print_code_font_menu(default_idx: int | None = None):
    print("\n👨‍💻 Choose a code font (monospaced, Google Fonts):")
    for i, name in enumerate(CODE_FONTS, start=1):
        marker = "  ← default" if default_idx == i else ""
        print(f"  {i}. {name}{marker}")
    marker7 = "  ← default" if default_idx == 7 else ""
    print(f"  7. Enter a custom code font (e.g., 'Cascadia Code'){marker7}")

def prompt_font_pairing(previous_default: dict | None) -> tuple[str, str]:
    """
    Returns (header, body). If a previous default exists, it becomes the real default:
      - If it matches one of the 1–6 pairings, that index is default.
      - If it's Helvetica/Arial, option 7 is default.
      - Otherwise, option 8 (custom) is default, pressing ENTER keeps the prior values.
    """
    # Compute which option should be the default based on previous_default
    def find_pair_index(h: str, b: str) -> int | None:
        for i, (hdr, body) in enumerate(FONT_PAIRINGS, start=1):
            if hdr == h and body == b:
                return i
        return None

    prev_header = (previous_default or {}).get("header")
    prev_body   = (previous_default or {}).get("body")

    default_idx: int
    if prev_header and prev_body:
        if prev_header.strip() == "Helvetica, Arial" and prev_body.strip() == "Helvetica, Arial":
            default_idx = 7
        else:
            idx = find_pair_index(prev_header.strip(), prev_body.strip())
            default_idx = idx if idx is not None else 8
    else:
        default_idx = 7  # first run: show system default as recommended pairing

    _print_font_pair_menu(default_idx=default_idx)
    if previous_default:
        print(f"\nLast used fonts: header='{prev_header}', body='{prev_body}'")

    prompt_label = f"Select 1-8 [Default: {default_idx}]: "
    while True:
        choice = input(prompt_label).strip()
        if choice == "":
            # User accepts the default
            if 1 <= default_idx <= 6:
                return FONT_PAIRINGS[default_idx - 1]
            if default_idx == 7:
                return "Helvetica, Arial", "Helvetica, Arial"
            # default_idx == 8 → keep the previous custom values if available
            if prev_header and prev_body:
                return prev_header, prev_body
            # fallback if somehow no previous custom
            return "Schibsted Grotesk", "Source Sans Pro"

        if choice in [str(i) for i in range(1, 9)]:
            n = int(choice)
            if 1 <= n <= 6:
                hdr, body = FONT_PAIRINGS[n - 1]
                print(f"✅ Selected: Header '{hdr}' with Body '{body}'")
                return hdr, body
            if n == 7:
                print("Using system-safe fonts. (Quartz will use CSS fallbacks.)")
                return "Helvetica, Arial", "Helvetica, Arial"
            if n == 8:
                # Let the user easily keep prior custom values via defaults
                hdr = prompt_with_default("Enter header font family", prev_header or "Schibsted Grotesk")
                body = prompt_with_default("Enter body font family",   prev_body   or "Source Sans Pro")
                print(f"✅ Selected: Header '{hdr}' with Body '{body}'")
                return hdr, body

        print("Please choose a number between 1 and 8.")

def prompt_code_font(previous_default: str | None) -> str:
    # Determine default index from previous_default
    if previous_default and previous_default in CODE_FONTS:
        default_idx = CODE_FONTS.index(previous_default) + 1
    elif previous_default:
        default_idx = 7  # custom previously used
    else:
        default_idx = 3  # IBM Plex Mono

    _print_code_font_menu(default_idx=default_idx)
    if previous_default:
        print(f"\nLast used code font: '{previous_default}'")

    prompt_label = f"Select 1-7 [Default: {default_idx}]: "
    while True:
        choice = input(prompt_label).strip()
        if choice == "":
            # Accept default
            if 1 <= default_idx <= 6:
                return CODE_FONTS[default_idx - 1]
            if default_idx == 7:
                return previous_default or "IBM Plex Mono"
            # Fallback
            return "IBM Plex Mono"

        if choice in [str(i) for i in range(1, 8)]:
            n = int(choice)
            if 1 <= n <= 6:
                print(f"✅ Selected code font: '{CODE_FONTS[n - 1]}'")
                return CODE_FONTS[n - 1]
            if n == 7:
                custom = prompt_with_default("Enter code font family", previous_default or "IBM Plex Mono")
                print(f"✅ Selected code font: '{custom}'")
                return custom

        print("Please choose a number between 1 and 7.")

def select_fonts_for_sections(section_numbers: list[int], saved_config: dict) -> dict:
    """
    Prompts for per-section font choices, suggesting consistency across sections.
    Returns a dict like:
    {
      "default": {"header": "...", "body": "...", "code": "..."},
      "sections": {"section3": {...}, "section4": {...}}
    }
    """
    print("\n🔤 Typography")
    print("You'll now choose fonts. We strongly recommend keeping font choices consistent across sections.\n")

    prev = (saved_config.get("fonts") or {}).get("default") or {}
    header, body = prompt_font_pairing(prev)
    code_font = prompt_code_font(prev.get("code") if prev else None)

    fonts = {
        "default": {"header": header, "body": body, "code": code_font},
        "sections": {}
    }

    prev_sections = ((saved_config.get("fonts") or {}).get("sections") or {})

    for sec in section_numbers:
        section_key = f"section{sec}"
        prior = prev_sections.get(section_key, {})
        print(f"\nSection {sec}:")
        print(f"Press ENTER to use default → header='{header}', body='{body}', code='{code_font}'")
        if prior:
            print(f"(Last time you used: header='{prior.get('header')}', body='{prior.get('body')}', code='{prior.get('code')}')")

        use_default = input("Keep defaults for this section? (y/ENTER to keep, 'n' to customize): ").strip().lower()
        if use_default in ("", "y", "yes"):
            fonts["sections"][section_key] = {"header": header, "body": body, "code": code_font}
        else:
            sh, sb = prompt_font_pairing(prior or fonts["default"])
            sc = prompt_code_font((prior or fonts["default"]).get("code"))
            fonts["sections"][section_key] = {"header": sh, "body": sb, "code": sc}

    return fonts
    
# ---------- Header emoji selection helpers (per-section only) ----------------

PRESET_HEADER_EMOJIS = [
    "📚", "🎓", "🏫", "✏️", "📝", "📐",
    "📊", "🧪", "🔬", "🔭", "🧬", "🖥️",
]

def _looks_like_single_emoji(s: str) -> bool:
    """
    Heuristic to accept a single emoji (optionally with variation selectors/skin tone).
    Rejects spaces/alphanumerics; allows one primary symbol plus modifiers.
    Note: complex ZWJ sequences (e.g., family emojis) are intentionally rejected.
    """
    s = (s or "").strip()
    if not s or any(ch.isspace() for ch in s):
        return False
    for ch in s:
        if ch.isalnum():
            return False
    SKIN_TONES = {0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF}
    ZWJ = 0x200D
    VARIATION_SELECTORS = {0xFE0E, 0xFE0F}
    base_count = 0
    for ch in s:
        cp = ord(ch)
        if cp in VARIATION_SELECTORS or cp == ZWJ or cp in SKIN_TONES:
            continue
        base_count += 1
        if base_count > 1:
            return False
    return base_count == 1

def prompt_single_emoji(prompt_text: str, default_emoji: str) -> str:
    """Prompt for one emoji with a menu of presets or custom entry; stateful default supported."""
    print(f"\n{prompt_text}")
    print("Choose one of the presets, or enter your own single emoji.")
    for i, emo in enumerate(PRESET_HEADER_EMOJIS, start=1):
        print(f"  {i:>2}. {emo}")
    print("  13. Enter a custom emoji")
    choice = input(f"Select 1-13 [Default: {default_emoji}]: ").strip()

    if choice == "":
        return default_emoji
    if choice.isdigit():
        n = int(choice)
        if 1 <= n <= 12:
            return PRESET_HEADER_EMOJIS[n - 1]
        if n == 13:
            custom = input("Enter a single emoji: ").strip()
            if _looks_like_single_emoji(custom):
                return custom
            print("⚠️ That doesn't look like a single emoji. Keeping default.")
            return default_emoji
    if _looks_like_single_emoji(choice):
        return choice
    print("⚠️ Invalid selection. Keeping default.")
    return default_emoji

def select_header_emojis_for_sections(section_numbers: list[int], saved_config: dict) -> dict:
    """
    Returns:
    {
      "sections": { "section1": "📚", "section3": "🔬", ... }
    }
    (No course-level default is stored.)
    """
    print("\n🔣 Section Header Emojis")
    print("Pick a single emoji for each section. (e.g., 📚)")
    print("Tip: Press ENTER to keep the shown default from a previous run.\n")

    prev_emojis = (saved_config.get("emojis") or {})
    # Back-compat: if an older config had a course-level default, we only use it as a suggestion
    prev_default = prev_emojis.get("default")
    prev_sections = prev_emojis.get("sections") if isinstance(prev_emojis.get("sections"), dict) else {}

    result_sections = {}
    for sec in section_numbers:
        section_key = f"section{sec}"
        prior_for_section = prev_sections.get(section_key)
        suggested = prior_for_section or prev_default or PRESET_HEADER_EMOJIS[0]
        chosen = prompt_single_emoji(
            f"Choose header emoji for Section {sec}:", suggested
        )
        result_sections[section_key] = chosen

    return {"sections": result_sections}


# ---------- Hardened Explorer patch helpers ---------------------------------

EXPLORER_BLOCK = """Component.Explorer({
    title: "Navigate this site",
    folderClickBehavior: "link",
    filterFn: (node) => {
      // CQ4T-OMIT-ANCHOR: do not remove this line; build script overwrites this Set
      const omit = new Set<string>([""]);
      if (node.isFolder) {
        return !omit.has(node.fileSegmentHint);
      } else {
        return !omit.has(node.data.title);
      }
    },
  })"""

def _patch_explorer_with_anchor(layout_src: str) -> tuple[str, bool]:
    """
    Replace the Explorer component (simple or configured) with our anchored version.
    Returns (new_src, changed).
    """
    changed = False

    # 1) Replace the simplest call: Component.Explorer()
    new_src, n1 = re.subn(r'Component\.Explorer\(\s*\)', EXPLORER_BLOCK, layout_src)
    if n1 > 0:
        return new_src, True

    # 2) Replace any configured Explorer: Component.Explorer({ ... })
    new_src, n2 = re.subn(r'Component\.Explorer\(\s*\{[\s\S]*?\}\s*\)', EXPLORER_BLOCK, new_src)
    if n2 > 0:
        return new_src, True

    # 3) If there's an Explorer somewhere *without* our anchor but our regex failed, try a lighter touch:
    #    Ensure an omit Set line with anchor exists inside any existing filterFn.
    def ensure_anchor_in_filterfn(m: re.Match) -> str:
        block = m.group(0)
        if "CQ4T-OMIT-ANCHOR" in block:
            return block  # already anchored

        # Try to insert our omit line after the opening brace of filterFn
        block2, n = re.subn(
            r'(filterFn\s*:\s*\(\s*node\s*\)\s*=>\s*\{\s*)',
            r'\1\n      // CQ4T-OMIT-ANCHOR: do not remove this line; build script overwrites this Set\n'
            r'      const omit = new Set<string>([""]);\n',
            block,
            count=1
        )
        return block2 if n > 0 else block

    new_src2, n3 = re.subn(r'Component\.Explorer\(\s*\{[\s\S]*?\}\s*\)', ensure_anchor_in_filterfn, layout_src)
    if n3 > 0 and new_src2 != layout_src:
        return new_src2, True

    return layout_src, changed

def ensure_quartz_explorer_anchor():
    """Idempotently ensure quartz.layout.ts includes the omit anchor block."""
    quartz_layout_path = Path("/opt/quartz/quartz.layout.ts")
    if quartz_layout_path.exists():
        with open(quartz_layout_path, "r", encoding="utf-8") as f:
            content = f.read()

        new_content, changed = _patch_explorer_with_anchor(content)

        if changed:
            try:
                subprocess.run(
                    ["tee", str(quartz_layout_path)],
                    input=new_content.encode("utf-8"),
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                print(f"✅ Ensured Explorer has omit anchor in {quartz_layout_path}")
            except subprocess.CalledProcessError as e:
                print(f"❌ Failed to write updated layout. Error:\n{e.stderr.decode()}")
        else:
            if "CQ4T-OMIT-ANCHOR" in content:
                print("ℹ️ Explorer already contains omit anchor (no change).")
            else:
                print("⚠️ Could not locate Component.Explorer() to patch. You may need to update quartz.layout.ts manually.")
    else:
        print(f"⚠️ quartz.layout.ts not found at: {quartz_layout_path}")

# ---------- NEW: Example Course installer -----------------------------------

EXAMPLE_COURSE_CODE = "EXC2O"

CANDIDATE_EXAMPLE_SOURCE_PATHS = [
    Path("support/example_course") / EXAMPLE_COURSE_CODE,
    Path("/opt/support/example_course") / EXAMPLE_COURSE_CODE,
    Path(__file__).resolve().parent.parent / "support" / "example_course" / EXAMPLE_COURSE_CODE,
    Path(__file__).resolve().parent / "support" / "example_course" / EXAMPLE_COURSE_CODE,
]

def _find_example_source_dir() -> Path | None:
    for p in CANDIDATE_EXAMPLE_SOURCE_PATHS:
        if p.exists() and p.is_dir():
            return p
    return None

def _generate_alt_example_code(dest_root: Path) -> str:
    """
    Generate a 5-char alternative course code ending with '2O' that does not collide.
    Uses three random uppercase letters for the prefix.
    """
    letters = string.ascii_uppercase
    for _ in range(100):
        prefix = "".join(random.choice(letters) for _ in range(3))
        candidate = f"{prefix}2O"
        if not (dest_root / candidate).exists():
            return candidate
    # Fallback deterministic slug if somehow everything collides
    i = 1
    while (dest_root / f"EX{i:02d}2O").exists():
        i += 1
    return f"EX{i:02d}2O"

def maybe_install_example_course(courses_root: Path) -> bool:
    """
    Offer to install the Example Course (EXC2O) for new users.
    Copies support/example_course/EXC2O → /teaching/courses/EXC2O (or alt code if taken).
    If installed, ensure the Quartz Explorer omit anchor is present, show hint, and exit.
    Returns True if installed, False otherwise.
    """
    print("\n📦 Optional: Install an Example Course")
    print("The 'EXC2O' course (stands for 'Example Course') demonstrates how content is organized in Obsidian and how Quartz renders it into a site.")
    print("Recommended if you're NEW to this workflow — you can remove it later.")
    install = prompt_yes_no_default("Install the Example Course now?", default=False)
    if not install:
        return False

    src = _find_example_source_dir()
    if not src:
        print("⚠️ Could not find example course content at expected locations. Skipping installation.")
        return False

    dest_code = EXAMPLE_COURSE_CODE
    dest = courses_root / dest_code
    if dest.exists():
        # Generate an alternate code preserving '2O' as the final two characters
        alt = _generate_alt_example_code(courses_root)
        print(f"ℹ️ A course named '{dest_code}' already exists. Using alternate code: {alt}")
        dest_code = alt
        dest = courses_root / dest_code

    try:
        shutil.copytree(src, dest, dirs_exist_ok=False)
        print(f"✅ Example Course installed to: {dest}")
    except FileExistsError:
        print(f"⚠️ Destination {dest} already exists; skipping copy.")
    except Exception as e:
        print(f"❌ Failed to install Example Course: {e}")
        return False

    # Ensure Quartz Explorer has the omit anchor so hidden items work in preview
    ensure_quartz_explorer_anchor()

    # Print final hint and exit early (as requested)
    print("✅ Example Course installed: EXC2O")
    print("ℹ️ To preview this site, run:")
    print("   ./preview.sh EXC2O 1")
    print("   (Then open http://localhost:8081 in your browser.)")
    sys.exit(0)
    return True  # not reached

# ---------- NEW: Timetable section numbers prompt ---------------------------

def prompt_section_numbers(num_sections: int, saved_config: dict) -> list[int]:
    """
    Ask the teacher to enter the timetable section numbers (e.g., 1,3,4).
    Enforces uniqueness and exact count == num_sections.
    """
    prev = saved_config.get("section_numbers")
    if isinstance(prev, list) and prev:
        default_list = [int(x) for x in prev]
    else:
        default_list = list(range(1, num_sections + 1))
    default_str = ",".join(str(x) for x in default_list)

    print(f"\nYou indicated you teach {num_sections} section(s).")
    print("Enter the timetable section numbers for YOUR sections (e.g., 1,3,4).")
    entry = input(f"> [Default: {default_str}]: ").strip()

    if not entry:
        return default_list

    try:
        parts = [p.strip() for p in entry.split(",") if p.strip() != ""]
        nums = [int(p) for p in parts]
    except ValueError:
        print("Invalid input. Please enter comma-separated integers like 1,3,4.")
        return prompt_section_numbers(num_sections, saved_config)

    if len(nums) != num_sections:
        print(f"Please provide exactly {num_sections} unique numbers.")
        return prompt_section_numbers(num_sections, saved_config)
    if len(set(nums)) != len(nums):
        print("Duplicate numbers detected. Please enter unique section numbers.")
        return prompt_section_numbers(num_sections, saved_config)
    if any(n <= 0 for n in nums):
        print("Section numbers must be positive integers.")
        return prompt_section_numbers(num_sections, saved_config)

    return nums

# ---------- NEW: Obsidian defaults copier -----------------------------------

CANDIDATE_OBSIDIAN_DEFAULTS_PATHS = [
    Path("support/obsidian_defaults") / ".obsidian",
    Path("/opt/support/obsidian_defaults") / ".obsidian",
    Path(__file__).resolve().parent.parent / "support" / "obsidian_defaults" / ".obsidian",
    Path(__file__).resolve().parent / "support" / "obsidian_defaults" / ".obsidian",
]

def _find_obsidian_defaults_dir() -> Path | None:
    for p in CANDIDATE_OBSIDIAN_DEFAULTS_PATHS:
        if p.exists() and p.is_dir():
            return p
    return None

def copy_obsidian_defaults(course_dir: Path) -> None:
    """
    Copy support/obsidian_defaults/.obsidian into the given course_dir.
    - If course_dir/.obsidian already exists, merge without overwriting existing files.
    - If not found, print a warning and continue silently.
    """
    src = _find_obsidian_defaults_dir()
    if not src:
        print("⚠️  Obsidian defaults not found (support/obsidian_defaults/.obsidian). Skipping.")
        return

    dest = course_dir / ".obsidian"
    copied_count = 0
    skipped_count = 0

    dest.mkdir(parents=True, exist_ok=True)

    for root, dirs, files in os.walk(src):
        rel_root = Path(root).relative_to(src)
        target_root = dest / rel_root
        target_root.mkdir(parents=True, exist_ok=True)
        for fname in files:
            sfile = Path(root) / fname
            dfile = target_root / fname
            if dfile.exists():
                skipped_count += 1
                continue  # do not clobber teacher's existing settings
            try:
                shutil.copy2(sfile, dfile)
                copied_count += 1
            except Exception as e:
                print(f"⚠️  Could not copy '{sfile}' → '{dfile}': {e}")

    if copied_count > 0:
        print(f"✅ Obsidian defaults installed to {dest} ({copied_count} new file(s); {skipped_count} skipped).")
    else:
        print(f"ℹ️  Obsidian defaults already present at {dest} (no changes).")

# ---------- Main setup flow (baseline preserved + backups + defaults) -------

def setup_course(no_backup: bool = False):
    print("📚 Welcome to the Course Setup Script!\n")

    base_path = Path("/teaching/courses")

    # --- NEW: Offer to install the Example Course (EXC2O) -------------------
    try:
        maybe_install_example_course(base_path)
    except SystemExit:
        # early exit is expected after example install
        return
    except Exception as e:
        print(f"⚠️ Example Course installation step encountered an error and will be skipped: {e}")

    default_code = "ICS3U"
    course_code = prompt_with_default("Enter the course code (e.g. ICS3U)", default_code).upper()
    course_path = base_path / course_code

    # --- NEW: Automatic backup BEFORE any mutations -------------------------
    try:
        if course_path.exists() and not no_backup:
            backup_root = base_path / "_backups"
            backup_existing_course_dir(course_path, backup_root)
    except Exception as e:
        print(f"⚠️ Backup warning: {e}")
        print("   Proceeding without backup due to the error above.")

    # Ensure the course directory exists (original behavior)
    course_path.mkdir(parents=True, exist_ok=True)

    # --- NEW: Always ensure a course-level Media folder & announce purpose ---
    media_path = course_path / "Media"
    media_path.mkdir(parents=True, exist_ok=True)
    # Drop a .gitkeep so it appears in version control even when empty
    try:
        (media_path / ".gitkeep").touch(exist_ok=True)
    except Exception:
        pass
    print("\n🗂️  'Media' folder")
    print("A course-level folder named 'Media' has been ensured at:")
    print(f"   {media_path}")
    print("Use it to store larger binary assets (images, short videos, PDFs).")
    print("It is automatically hidden from the site's Explorer and shared across all sections.")
    print("Note: You do not need to add 'Media' to any folder lists below—it's created for you.\n")

    # --- NEW: Copy Obsidian defaults into the new/existing course folder ----
    # This seeds sensible defaults (e.g., attachments saved to 'Media').
    try:
        copy_obsidian_defaults(course_path)
    except Exception as e:
        print(f"⚠️  Unable to install Obsidian defaults: {e}")

    config_path = course_path / "course_config.json"
    saved_config = {}
    if config_path.exists():
        with open(config_path, "r", encoding="utf-8") as f:
            saved_config = json.load(f)

    if saved_config.get("course_name"):
        course_name = prompt_with_default("Enter the formal course name", saved_config["course_name"])
    else:
        looked_up_name = get_course_name_from_json(course_code) or "Course Website"
        course_name = prompt_with_default("Enter the formal course name", looked_up_name)

    # Count first (kept for compatibility / UX), then timetable section numbers
    num_sections = int(prompt_with_default("How many sections are you teaching of this course?", saved_config.get("num_sections", 2)))
    section_numbers = prompt_section_numbers(num_sections, saved_config)
    # Normalize num_sections to entered list length
    num_sections = len(section_numbers)

    # ---- Per-section colour scheme selection (interactive) ----
    schemes = load_colour_schemes()
    previous_map = saved_config.get("color_schemes", {})
    color_schemes_map = {}
    if schemes:
        print("\n🎨 Choose a colour scheme for each section.\n")
        for sec in section_numbers:
            section_key = f"section{sec}"
            default_scheme_id = previous_map.get(section_key)
            chosen_id = interactive_pick_scheme_for_section(
                schemes, section_number=sec, default_id=default_scheme_id
            )
            # If user cancels, keep previous; else pick current or fallback to first
            if not chosen_id:
                chosen_id = default_scheme_id or (schemes[0].get("id") if schemes else None)
            color_schemes_map[section_key] = chosen_id
        clear_screen()

    # ---- Typography selection (after colours) ----
    fonts_config = select_fonts_for_sections(section_numbers, saved_config)
    
    # ---- Per-section header emoji selection (stateful) ----
    emojis_config = select_header_emojis_for_sections(section_numbers, saved_config)

    # ---------- Original prompts (unchanged except for Media handling) ----------
    # Remove 'Media' from defaults so it never appears in the selection prompt
    shared_default_candidates = saved_config.get("shared_folders", DEFAULT_SHARED_FOLDERS)
    shared_default_filtered = [x for x in (shared_default_candidates or []) if x != "Media"]

    shared_folders = prompt_type_list(
        "Enter folder names to be shared across all sections – defaults are:",
        shared_default_filtered,
        forbidden_names=["Media"]  # prevent user from adding 'Media'
    )
    shared_files = prompt_type_list(
        "Enter Markdown file names to be shared across all sections – defaults are:",
        saved_config.get("shared_files", DEFAULT_SHARED_FILES),
        add_md_extension=True
    )
    per_section_folders = prompt_type_list(
        "Enter folder names to be duplicated per section – defaults are:",
        saved_config.get("per_section_folders", DEFAULT_PER_SECTION_FOLDERS),
        forbidden_names=["Media"]  # prevent user from adding 'Media'
    )
    per_section_files = prompt_type_list(
        "Enter Markdown file names to be duplicated per section – defaults are:",
        saved_config.get("per_section_files", DEFAULT_PER_SECTION_FILES),
        add_md_extension=True
    )

    all_selected = shared_folders + shared_files + per_section_folders + per_section_files

    default_hidden = [
        "Media", "Ontario Curriculum", "College Board Curriculum",
        "SIC Drop-In Sessions.md", "Grove Time.md", "Learning Goals.md",
        "Private Notes.md", "Scratch Page.md", "Key Links.md"
    ] if not saved_config else saved_config.get("hidden", [])

    # IMPORTANT: 'Media' will NOT appear in this prompt because it's not in all_selected,
    # but we still want it hidden in config. We'll enforce that after the prompt.
    hidden_items = prompt_select_multiple("Select folders/files to HIDE from the sidebar:", all_selected, default_hidden)
    visible_items = [item for item in all_selected if item not in hidden_items]

    default_expandable = [
        "Concepts", "Discussions", "Examples", "Exercises", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials"
    ] if not saved_config else saved_config.get("expandable", [])

    expandable_items = prompt_select_multiple("Select folders/files that should be EXPANDABLE:", visible_items, default_expandable)

    # ---------- Explorer expansion behaviour (stateful, applies to all sections) ----------
    expand_on_click = prompt_explorer_expansion_behavior(saved_config)

    # ---------- Stateful footer prompt ----------
    footer_html = prompt_footer_html_stateful(saved_config)

    # ---------- Show reading-time estimates (stateful) ----------
    show_reading_time_default = bool(saved_config.get("show_reading_time", False))
    show_reading_time = prompt_yes_no_default(
        "Show page read time estimates to students?",
        show_reading_time_default
    )

    # Ensure 'Media' is always in hidden list even though it wasn't prompted
    if "Media" not in hidden_items:
        hidden_items.append("Media")

    # ---------- Save configuration (now includes section_numbers) ----------
    config = {
        "course_code": course_code,
        "course_name": course_name,
        "emojis": emojis_config,
        "num_sections": num_sections,
        "section_numbers": section_numbers,  # NEW: timetable-based identifiers
        "shared_folders": shared_folders,
        "shared_files": shared_files,
        "per_section_folders": per_section_folders,
        "per_section_files": per_section_files,
        "hidden": hidden_items,
        "expandable": expandable_items,
        # NEW: global Explorer expansion behaviour for this course
        "expandOnFolderClick": expand_on_click,
        "footer_html": footer_html,
        # New flag stored for build_site.py to consume
        "show_reading_time": show_reading_time,
        # New: fonts configuration to be applied by build_site.py per section
        "fonts": fonts_config,
    }
    previous_map = saved_config.get("color_schemes", {}) or {}
    if schemes:
        # Use the choices gathered earlier in this run
        config["color_schemes"] = color_schemes_map
    else:
        # No schemes available now; keep whatever was previously saved
        config["color_schemes"] = previous_map

    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
        f.write("\n")  # nice-to-have: trailing newline

    # Get current timestamp in ISO8601 with milliseconds and timezone offset
    tz_offset_str = os.environ.get("HOST_TZ_OFFSET")
    if tz_offset_str and len(tz_offset_str) == 5 and tz_offset_str[1:].isdigit():
        sign = 1 if tz_offset_str[0] == '+' else -1
        hours = int(tz_offset_str[1:3])
        minutes = int(tz_offset_str[3:])
        tzinfo = timezone(sign * timedelta(hours=hours, minutes=minutes))
        now_str = datetime.now(tzinfo).strftime("%Y-%m-%dT%H:%M:%S.000%z")
    else:
        now_str = datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S.000%z")
    
    # ---------- Create shared structure (with createdSectionN + draftSectionN) ----------
    for folder in shared_folders:
        folder_path = Path("/teaching/courses") / course_code / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        index_md_path = folder_path / "index.md"
        if not index_md_path.exists():
            with open(index_md_path, "w", encoding="utf-8") as f:
                f.write("---\n")
                f.write(f"title: {folder}\n")
                for sec in section_numbers:
                    f.write(f"createdSection{sec}: {now_str}\n")
                    f.write(f"draftSection{sec}: false\n")
                f.write("---\n")
                f.write(f"This is the **{folder}** folder. Add Markdown files to this folder to build out your site. Optionally, you can remove this `index.md` file and Quartz will then show only a listing of files that exist in this folder instead.\n")
    
    for file in shared_files:
        file_path = Path("/teaching/courses") / course_code / file
        if not file_path.exists():
            with open(file_path, "w", encoding="utf-8") as f:
                f.write("---\n")
                f.write(f"title: {file.replace('.md', '')}\n")
                for sec in section_numbers:
                    f.write(f"createdSection{sec}: {now_str}\n")
                    f.write(f"draftSection{sec}: false\n")
                f.write("---\n")
                f.write(f"This is the shared file **{file}**.\n")
    
    # ---------- Create per-section structure (with created + draft) ----------
    # Determine grade level from 4th character of course code
    grade_map = {
        "1": "Grade 9",
        "2": "Grade 10",
        "3": "Grade 11",
        "4": "Grade 12"
    }
    grade_char = course_code[3] if len(course_code) >= 4 else ""
    grade_label = grade_map.get(grade_char, "Grade ?")

    for sec in section_numbers:
        section_name = f"section{sec}"
        section_path = Path("/teaching/courses") / course_code / section_name
        section_path.mkdir(exist_ok=True)
    
        index_md_path = section_path / "index.md"
        if not index_md_path.exists():
            with open(index_md_path, "w", encoding="utf-8") as f:
                f.write("---\n")
                f.write(f"title: {grade_label} {course_name}, Section {sec}\n")
                f.write(f"created: {now_str}\n")
                f.write("draft: false\n")
                f.write("---\n")
    
        for folder in DEFAULT_PER_SECTION_FOLDERS if not DEFAULT_PER_SECTION_FOLDERS else []:
            # (kept for compatibility; actual per_section_folders handled below)
            pass

        for folder in per_section_folders:
            folder_path = section_path / folder
            folder_path.mkdir(parents=True, exist_ok=True)
            index_md = folder_path / "index.md"
            if not index_md.exists():
                with open(index_md, "w", encoding="utf-8") as f:
                    f.write("---\n")
                    f.write(f"title: {folder}\n")
                    f.write(f"created: {now_str}\n")
                    f.write("draft: false\n")
                    f.write("---\n")
                    f.write(f"This is the **{folder}** folder. Add Markdown files to this folder to build out your site.\n")
    
        for file in per_section_files:
            file_path = section_path / file
            if not file_path.exists():
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write("---\n")
                    f.write(f"title: {file.replace('.md', '')}\n")
                    f.write(f"created: {now_str}\n")
                    f.write("draft: false\n")
                    f.write("---\n")
                    f.write(f"This is the per-section file **{file}**.\n")

    # ---------- Patch Quartz Explorer (hardened + idempotent) ----------
    ensure_quartz_explorer_anchor()

    print(f"\n✅ Course '{course_code}' set up successfully at: {course_path}")

def parse_args():
    parser = argparse.ArgumentParser(description="Course setup with automatic backups")
    parser.add_argument("--no-backup", action="store_true", help="Skip creating a backup of the existing course folder.")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    setup_course(no_backup=args.no_backup)
