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
    BLUE = "\033[94m"
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

def prompt_type_list(prompt_text, default_list=None, add_md_extension=False):
    print(f"\n{prompt_text}")
    if default_list:
        for item in default_list:
            print(f" - {item}")
    print("Enter comma-separated names or leave blank to accept default:")
    entry = input("> ").strip()
    if not entry:
        return default_list if default_list else []
    raw = [name.strip() for name in entry.split(",") if name.strip()]
    return [name + ".md" if add_md_extension and not name.endswith(".md") else name for name in raw]

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
        suffix = "  ← recommended pairing" if default_idx and (i == default_idx) else ""
        print(f"  {i}. {hdr}  —  {body}{suffix}")
    print("  7. System fonts (Helvetica, Arial)")
    print("  8. Enter a custom pair (e.g., 'DM Sans, Inter')")

def _print_code_font_menu(default_idx: int | None = None):
    print("\n👨‍💻 Choose a code font (monospaced, Google Fonts):")
    for i, name in enumerate(CODE_FONTS, start=1):
        suffix = "  ← default" if default_idx and (i == default_idx) else ""
        print(f"  {i}. {name}{suffix}")
    print("  7. Enter a custom code font (e.g., 'Cascadia Code')")

def prompt_font_pairing(previous_default: dict | None) -> tuple[str, str]:
    """
    Returns (header, body)
    """
    recommended_idx = 1  # Highlight the first pairing by default
    _print_font_pair_menu(default_idx=recommended_idx)
    if previous_default:
        print(f"\nLast used fonts: header='{previous_default.get('header')}', body='{previous_default.get('body')}'")

    while True:
        choice = input("Select 1-8 [Default: 1]: ").strip()
        if choice == "":
            choice = "1"
        if choice in [str(i) for i in range(1, 9)]:
            choice = int(choice)
            if 1 <= choice <= 6:
                hdr, body = FONT_PAIRINGS[choice - 1]
                print(f"✅ Selected: Header '{hdr}' with Body '{body}'")
                return hdr, body
            if choice == 7:
                print("Using system-safe fonts. (Quartz will use CSS fallbacks.)")
                return "Helvetica, Arial", "Helvetica, Arial"
            if choice == 8:
                hdr = input("Enter header font family (comma-separated list OK): ").strip()
                body = input("Enter body font family (comma-separated list OK): ").strip()
                hdr = hdr if hdr else "Schibsted Grotesk"
                body = body if body else "Source Sans Pro"
                print(f"✅ Selected: Header '{hdr}' with Body '{body}'")
                return hdr, body
        print("Please choose a number between 1 and 8.")

def prompt_code_font(previous_default: str | None) -> str:
    _print_code_font_menu(default_idx=None)
    if previous_default:
        print(f"\nLast used code font: '{previous_default}'")
    while True:
        choice = input("Select 1-7 [Default: 3 (IBM Plex Mono)]: ").strip()
        if choice == "":
            return "IBM Plex Mono"
        if choice in [str(i) for i in range(1, 8)]:
            choice = int(choice)
            if 1 <= choice <= 6:
                print(f"✅ Selected code font: '{CODE_FONTS[choice - 1]}'")
                return CODE_FONTS[choice - 1]
            if choice == 7:
                custom = input("Enter code font family (comma-separated list OK): ").strip()
                custom = custom if custom else "IBM Plex Mono"
                print(f"✅ Selected code font: '{custom}'")
                return custom
        print("Please choose a number between 1 and 7.")

def select_fonts_for_sections(num_sections: int, saved_config: dict) -> dict:
    """
    Prompts for per-section font choices, suggesting consistency across sections.
    Returns a dict like:
    {
      "default": {"header": "...", "body": "...", "code": "..."},
      "sections": {"section1": {...}, "section2": {...}}
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

    for i in range(1, num_sections + 1):
        section_key = f"section{i}"
        prior = ((saved_config.get("fonts") or {}).get("sections") or {}).get(section_key, {})
        print(f"\nSection {i}:")
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

# ---------- Main setup flow (baseline preserved + color selection added) ----

def setup_course():
    print("\U0001F4DA Welcome to the Course Setup Script!\n")

    base_path = Path("/teaching/courses")
    default_code = "ICS3U"
    course_code = prompt_with_default("Enter the course code (e.g. ICS3U)", default_code).upper()
    course_path = base_path / course_code
    course_path.mkdir(parents=True, exist_ok=True)

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

    num_sections = int(prompt_with_default("How many sections are you teaching of this course?", saved_config.get("num_sections", 2)))

    # ---- New: per-section colour scheme selection (interactive) ----
    schemes = load_colour_schemes()
    previous_map = saved_config.get("color_schemes", {})
    color_schemes_map = {}
    if schemes:
        print("\n🎨 Choose a colour scheme for each section.\n")
        for i in range(1, num_sections + 1):
            section_key = f"section{i}"
            default_scheme_id = previous_map.get(section_key)
            chosen_id = interactive_pick_scheme_for_section(
                schemes, section_number=i, default_id=default_scheme_id
            )
            # If user cancels, keep previous; else pick current or fallback to first
            if not chosen_id:
                chosen_id = default_scheme_id or (schemes[0].get("id") if schemes else None)
            color_schemes_map[section_key] = chosen_id
        clear_screen()

    # ---- New: typography selection (after colours) ----
    fonts_config = select_fonts_for_sections(num_sections, saved_config)

    # ---------- Original prompts (unchanged) ----------
    shared_folders = prompt_type_list(
        "Enter folder names to be shared across all sections – defaults are:",
        saved_config.get("shared_folders", DEFAULT_SHARED_FOLDERS)
    )
    shared_files = prompt_type_list(
        "Enter Markdown file names to be shared across all sections – defaults are:",
        saved_config.get("shared_files", DEFAULT_SHARED_FILES),
        add_md_extension=True
    )
    per_section_folders = prompt_type_list(
        "Enter folder names to be duplicated per section – defaults are:",
        saved_config.get("per_section_folders", DEFAULT_PER_SECTION_FOLDERS)
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

    hidden_items = prompt_select_multiple("Select folders/files to HIDE from the sidebar:", all_selected, default_hidden)
    visible_items = [item for item in all_selected if item not in hidden_items]

    default_expandable = [
        "Concepts", "Discussions", "Examples", "Exercises", "Portfolios",
        "Recaps", "Setup", "Style", "Tasks", "Tutorials"
    ] if not saved_config else saved_config.get("expandable", [])

    expandable_items = prompt_select_multiple("Select folders/files that should be EXPANDABLE:", visible_items, default_expandable)

    # ---------- New: Stateful footer prompt (replaces previous footer block) ----------
    footer_html = prompt_footer_html_stateful(saved_config)

    # ---------- New: Ask about showing reading-time estimates (stateful) ----------
    # Default to previous choice if present; otherwise default to False (hidden)
    show_reading_time_default = bool(saved_config.get("show_reading_time", False))
    show_reading_time = prompt_yes_no_default(
        "Show page read time estimates to students?",
        show_reading_time_default
    )

    # ---------- Save configuration (preserving new color_schemes + fonts) ----------
    config = {
        "course_code": course_code,
        "course_name": course_name,
        "num_sections": num_sections,
        "shared_folders": shared_folders,
        "shared_files": shared_files,
        "per_section_folders": per_section_folders,
        "per_section_files": per_section_files,
        "hidden": hidden_items,
        "expandable": expandable_items,
        "footer_html": footer_html,
        # New flag stored for build_site.py to consume
        "show_reading_time": show_reading_time,
        # New: fonts configuration to be applied by build_site.py per section
        "fonts": fonts_config,
    }
    if schemes:
        config["color_schemes"] = color_schemes_map or previous_map

    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)

    # Get current timestamp in ISO8601 with milliseconds and timezone offset
    # Determine timestamp with correct timezone
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
        folder_path = course_path / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        index_md_path = folder_path / "index.md"
        if not index_md_path.exists():
            with open(index_md_path, "w", encoding="utf-8") as f:
                f.write("---\n")
                f.write(f"title: {folder}\n")
                for i in range(1, num_sections + 1):
                    f.write(f"createdSection{i}: {now_str}\n")
                    f.write(f"draftSection{i}: false\n")
                f.write("---\n")
                f.write(f"This is the **{folder}** folder. Add Markdown files to this folder to build out your site.\n")
    
    for file in shared_files:
        file_path = course_path / file
        if not file_path.exists():
            with open(file_path, "w", encoding="utf-8") as f:
                f.write("---\n")
                f.write(f"title: {file.replace('.md', '')}\n")
                for i in range(1, num_sections + 1):
                    f.write(f"createdSection{i}: {now_str}\n")
                    f.write(f"draftSection{i}: false\n")
                f.write("---\n")
                f.write(f"This is the shared file **{file}**.\n")
    
    # ---------- Create per-section structure (with created + draft) ----------
    for i in range(1, num_sections + 1):
        section_name = f"section{i}"
        section_path = course_path / section_name
        section_path.mkdir(exist_ok=True)
    
        index_md_path = section_path / "index.md"
        if not index_md_path.exists():
            with open(index_md_path, "w", encoding="utf-8") as f:
                f.write("---\n")
                f.write(f"title: Grade 11 {course_name}, Section {i}\n")
                f.write(f"created: {now_str}\n")
                f.write("draft: false\n")
                f.write("---\n")
    
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

    # ---------- Patch Quartz Explorer (baseline behavior preserved) ----------
    quartz_layout_path = Path("/opt/quartz/quartz.layout.ts")
    if quartz_layout_path.exists():
        with open(quartz_layout_path, "r", encoding="utf-8") as f:
            content = f.read()

        explorer_code = '''
Component.Explorer({
    title: "Navigate this site",
    folderClickBehavior: "link", 
    filterFn: (node) => {
        console.log("Explorer node:", node)
        const omit = new Set(["" ])
        if (node.isFolder) {
            return !omit.has(node.fileSegmentHint)
        } else {
            return !omit.has(node.data.title)
        }
    } 
})'''.strip()

        modified_content = re.sub(r'Component\.Explorer\(\)', explorer_code, content)

        try:
            subprocess.run(
                ["tee", str(quartz_layout_path)],
                input=modified_content.encode("utf-8"),
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            print(f"✅ Replaced Component.Explorer() for sidebar navigation in {quartz_layout_path}")
        except subprocess.CalledProcessError as e:
            print(f"❌ Failed to write updated layout. Error:\n{e.stderr.decode()}")
    else:
        print(f"⚠️ quartz.layout.ts not found at: {quartz_layout_path}")

    print(f"\n✅ Course '{course_code}' set up successfully at: {course_path}")

if __name__ == "__main__":
    setup_course()
