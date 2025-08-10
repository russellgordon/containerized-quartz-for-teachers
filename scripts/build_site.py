import os
import shutil
import argparse
import frontmatter
import subprocess
import json
import re
from pathlib import Path

# --- ADD: Patch typography fonts in quartz.config.ts -------------------------
def _escape_font(val: str) -> str:
    # Guard against stray quotes in family names
    return val.replace('"', r'\"')

def patch_typography_fonts(quartz_config_path: Path, header_font: str, body_font: str, code_font: str):
    """
    Updates the typography block in quartz.config.ts to use the selected fonts.
      typography: {
        header: "<header_font>",
        body: "<body_font>",
        code: "<code_font>",
      },
    Tries targeted replacements first; if not found, replaces the whole block.
    """
    if not quartz_config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {quartz_config_path}")
        return

    try:
        with open(quartz_config_path, "r", encoding="utf-8") as f:
            content = f.read()

        hf = _escape_font(header_font)
        bf = _escape_font(body_font)
        cf = _escape_font(code_font)

        changed = False

        # Targeted replacements within existing typography block
        def replace_field(src: str, field: str, value: str) -> tuple[str, bool]:
            # Replace the value of e.g. header: "Old"
            pattern = re.compile(
                rf'(typography\s*:\s*\{{[\s\S]*?{field}\s*:\s*)"(.*?)"',
                flags=re.DOTALL
            )
            new_src, n = pattern.subn(rf'\1"{value}"', src, count=1)
            return new_src, (n > 0)

        new_content, hit_h = replace_field(content, "header", hf)
        new_content, hit_b = replace_field(new_content, "body", bf)
        new_content, hit_c = replace_field(new_content, "code", cf)

        changed = hit_h or hit_b or hit_c

        if not changed:
            # Replace the entire typography block if targeted replacements failed
            block_re = re.compile(r'typography\s*:\s*\{[\s\S]*?\}\s*,?', flags=re.DOTALL)
            new_block = (
                'typography: {\n'
                f'        header: "{hf}",\n'
                f'        body: "{bf}",\n'
                f'        code: "{cf}",\n'
                '      },'
            )
            new_content2, n2 = block_re.subn(new_block, new_content, count=1)
            if n2 == 0:
                # As a last resort, try to inject a typography block next to colors/theme
                # Insert after "theme: {" opening if present
                theme_open = re.search(r'(theme\s*:\s*\{)', new_content)
                if theme_open:
                    insert_at = theme_open.end()
                    new_content2 = new_content[:insert_at] + "\n      " + new_block + new_content[insert_at:]
                    changed = True
                else:
                    new_content2 = new_content
            else:
                changed = True
            new_content = new_content2

        if changed:
            result = subprocess.run(
                ["tee", str(quartz_config_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to update typography fonts in quartz.config.ts:", result.stderr.decode())
            else:
                print(f"✅ Set fonts → header: '{header_font}', body: '{body_font}', code: '{code_font}'")
        else:
            print("ℹ️ Typography fonts already match desired values (no change).")

    except Exception as e:
        print(f"⚠️ Error patching typography fonts: {e}")
# --- END ADD -----------------------------------------------------------------


# --- ADD: Patch base.scss internal link highlight ---
def patch_internal_link_highlight(base_scss_path: Path):
    """Comment out background-color for .internal links in base.scss."""
    if not base_scss_path.exists():
        print(f"⚠️ base.scss not found at {base_scss_path}")
        return
    try:
        with open(base_scss_path, "r", encoding="utf-8") as f:
            content = f.read()

        pattern = re.compile(
            r'(&\.internal\s*\{[^}]*?)background-color:\s*var\(--highlight\);\s*',
            flags=re.DOTALL
        )

        replacement = r'\1/*    background-color: var(--highlight); */\n'

        new_content = pattern.sub(replacement, content)

        if new_content != content:
            result = subprocess.run(
                ["tee", str(base_scss_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch base.scss internal link highlight:", result.stderr.decode())
            else:
                print("✅ Patched base.scss to comment out internal link background-color")
        else:
            print("ℹ️ base.scss internal link background-color already commented out (no change).")
    except Exception as e:
        print(f"⚠️ Error patching base.scss: {e}")
# --- END ADD ---

# --- ADD: Append transclusion styles to base.scss ---
def append_transclusion_styles(base_scss_path: Path):
    """
    Appends styles for transcluded content to the bottom of base.scss, idempotently.
    """
    if not base_scss_path.exists():
        print(f"⚠️ base.scss not found at {base_scss_path}")
        return
    try:
        marker = "/* Additions for containerized Quartz for teachers styles */"
        block = (
            "\n\n"
            "/* Additions for containerized Quartz for teachers styles */\n"
            "a.transclude-src {\n"
            "  display: none;\n"
            "}\n\n"
            "blockquote.transclude {\n"
            "  padding-left: 0;\n"
            "  border-left: none;\n"
            "}\n\n"
            "#quartz-body > div.center > div.page-header > div > h1 {\n"
            "  font-size: 2rem;\n"
            "}\n"
        )

        with open(base_scss_path, "r", encoding="utf-8") as f:
            content = f.read()

        if marker in content:
            print("ℹ️ Transclusion styles already present in base.scss (no change).")
            return

        new_content = content + block
        result = subprocess.run(
            ["tee", str(base_scss_path)],
            input=new_content.encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        if result.returncode != 0:
            print("❌ Failed to append transclusion styles to base.scss:", result.stderr.decode())
        else:
            print("✅ Appended transclusion styles to base.scss")
    except Exception as e:
        print(f"⚠️ Error appending transclusion styles: {e}")
# --- END ADD ---

# --- ADD: Patch ContentMeta.tsx date format ---
def patch_date_format(date_tsx_file_path: Path):
    """Update formatDate in Date.tsx to show full weekday, month, and day."""
    if not date_tsx_file_path.exists():
        print(f"⚠️ Date.tsx not found at {date_tsx_file_path}")
        return
    try:
        with open(date_tsx_file_path, "r", encoding="utf-8") as f:
            content = f.read()

        pattern = re.compile(
            r'export function formatDate\(d: Date, locale: ValidLocale = "en-US"\): string \{\s*return d\.toLocaleDateString\(locale, \{\s*year: "numeric",\s*month: "short",\s*day: "2-digit",\s*\}\s*\)\s*\}',
            flags=re.DOTALL
        )

        replacement = (
            'export function formatDate(d: Date, locale: ValidLocale = "en-US"): string {\n'
            '  return d.toLocaleDateString(locale, {\n'
            '    weekday: "long",\n'
            '    year: "numeric",\n'
            '    month: "long",\n'
            '    day: "numeric",\n'
            '  })\n'
            '}'
        )

        new_content = pattern.sub(replacement, content)

        if new_content != content:
            result = subprocess.run(
                ["tee", str(date_tsx_file_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch Date.tsx date format:", result.stderr.decode())
            else:
                print("✅ Patched Date.tsx to show full weekday/month/day date format")
        else:
            print("ℹ️ Date.tsx date format already matches desired settings.")
    except Exception as e:
        print(f"⚠️ Error patching Date.tsx date format: {e}")
# --- END ADD ---

# --- ADD: Patch listPage.scss meta width ---
def patch_list_page_meta_width(list_page_scss_path: Path):
    """Add width: 240px; to .meta in listPage.scss."""
    if not list_page_scss_path.exists():
        print(f"⚠️ listPage.scss not found at {list_page_scss_path}")
        return
    try:
        with open(list_page_scss_path, "r", encoding="utf-8") as f:
            content = f.read()

        pattern = re.compile(
            r'(&\s*\.meta\s*\{\s*margin:\s*0\s*1em\s*0\s*0;\s*opacity:\s*0\.6;\s*\})',
            flags=re.DOTALL
        )

        replacement = (
            "& .meta {\n"
            "      margin: 0 1em 0 0;\n"
            "      opacity: 0.6;\n"
            "      width: 240px;\n"
            "    }"
        )

        new_content = pattern.sub(replacement, content)

        if new_content != content:
            result = subprocess.run(
                ["tee", str(list_page_scss_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch listPage.scss .meta width:", result.stderr.decode())
            else:
                print("✅ Patched listPage.scss to set .meta width to 240px")
        else:
            print("ℹ️ listPage.scss .meta already has desired width.")
    except Exception as e:
        print(f"⚠️ Error patching listPage.scss: {e}")
# --- END ADD ---

def adjust_created_modified_priority(config_path: Path):
    """Remove 'git' from Plugin.CreatedModifiedDate priority array."""
    if not config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {config_path}")
        return

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Replace only inside Plugin.CreatedModifiedDate block
        new_content = re.sub(
            r'Plugin\.CreatedModifiedDate\(\{\s*priority:\s*\["git",\s*"frontmatter",\s*"filesystem"\]\s*,?\s*\}\)',
            'Plugin.CreatedModifiedDate({\n        priority: ["frontmatter", "filesystem"],\n      })',
            content
        )

        if new_content != content:
            result = subprocess.run(
                ["tee", str(config_path)],
                input=new_content.encode(),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to update CreatedModifiedDate priority:", result.stderr.decode())
            else:
                print("✅ Updated CreatedModifiedDate priority to exclude 'git'")
        else:
            print("ℹ️ No matching CreatedModifiedDate priority array found — no changes made.")

    except Exception as e:
        print(f"❌ Error adjusting CreatedModifiedDate priority: {e}")

# --- ADD: Resolve per-section emoji from course_config.json ------------------
def resolve_section_emoji(config: dict, section_number: int) -> str:
    """
    Returns the emoji to use for the page title, preferring the per-section choice,
    then the course default, falling back to 📚.
    """
    try:
        emojis = config.get("emojis", {})
        if isinstance(emojis, dict):
            default_emo = emojis.get("default") or "📚"
            sec_map = emojis.get("sections") or {}
            sec_emo = sec_map.get(f"section{section_number}")
            chosen = (sec_emo or default_emo or "📚").strip()
            return chosen if chosen else "📚"
    except Exception:
        pass
    return "📚"
# --- END ADD -----------------------------------------------------------------

def update_page_title(config_path: Path, course_code: str, section_number: int, emoji: str):
    if not config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {config_path}")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    updated = False
    # --- MODIFIED: use resolved emoji instead of hard-coded 📚 ---
    safe_emoji = (emoji or "📚").strip()
    new_title = f'{safe_emoji} {course_code.upper()} S{section_number}'

    for line in lines:
        if "pageTitle:" in line:
            new_lines.append(f'  pageTitle: "{new_title}",\n')
            updated = True
        else:
            new_lines.append(line)

    if updated:
        content = ''.join(new_lines)
        result = subprocess.run(["tee", str(config_path)], input=content.encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode != 0:
            print("⚠️ Error updating pageTitle in quartz.config.ts:", result.stderr.decode())
        else:
            print(f"✅ Updated pageTitle to '{new_title}' in quartz.config.ts")
    else:
        print("⚠️ Could not find pageTitle in quartz.config.ts to update")


def toggle_custom_og_images(config_path: str, enable: bool):
    with open(config_path, 'r') as file:
        lines = file.readlines()

    modified_lines = []
    changed = False

    for line in lines:
        stripped = line.strip()
        if re.search(r'Plugin\.CustomOgImages\(\)', stripped):
            if enable and stripped.startswith("//"):
                line = line.replace("//", "", 1)
                changed = True
            elif not enable and not stripped.startswith("//"):
                line = "//" + line
                changed = True
        modified_lines.append(line)

    if changed:
        content = ''.join(modified_lines)
        result = subprocess.run(["tee", config_path], input=content.encode(), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if result.returncode != 0:
            print("⚠️ Error updating quartz.config.ts:", result.stderr.decode())
        else:
            print("✅ Updated quartz.config.ts to", "enable" if enable else "disable", "social media previews")
    else:
        print("No changes needed to quartz.config.ts")


def kill_existing_quartz():
    try:
        output = subprocess.check_output(["lsof", "-ti", ":8081"])
        pids = output.decode().strip().split("\n")
        for pid in pids:
            if pid:
                subprocess.run(["kill", "-9", pid])
                print(f"🛑 Killed existing process on port 8081 (PID: {pid})")
    except subprocess.CalledProcessError:
        pass


# --- HARDENING TWEAK #1: Future-proof omit replacement (update all matches) --
def update_quartz_layout(quartz_layout_path: Path, hidden_components: list):
    if not quartz_layout_path.exists():
        print(f"⚠️ quartz.layout.ts not found at {quartz_layout_path}")
        return

    normalized_hidden = [
        item[:-3] if item.endswith(".md") else item
        for item in hidden_components
    ]

    content = Path(quartz_layout_path).read_text(encoding="utf-8")
    formatted = ", ".join(f'"{n}"' for n in normalized_hidden)
    replacement_line = f"const omit = new Set([{formatted}])"

    # Match both:
    #   const omit = new Set([...])
    #   const omit = new Set<string>([ ... ])
    # and keep the CQ4T-OMIT-ANCHOR line if it's directly above.
    pattern_omit = re.compile(
        r'(?P<anchor>^[ \t]*//[ \t]*CQ4T-OMIT-ANCHOR:.*?\n)?'  # optional anchor line
        r'[ \t]*const[ \t]+omit[ \t]*=[ \t]*new[ \t]+Set'     # const omit = new Set
        r'(?:<[^>]*>)?'                                       # optional generic, e.g., <string>
        r'[ \t]*\([ \t]*\[[\s\S]*?\][ \t]*\)[ \t]*;?',        # ([ ... ])
        flags=re.DOTALL | re.MULTILINE,
    )

    def _repl(m: re.Match) -> str:
        anchor = m.group('anchor') or ''
        return f"{anchor}{replacement_line}"

    new_content, replaced_count = pattern_omit.subn(_repl, content, count=0)  # replace ALL

    if replaced_count == 0:
        # If not found, insert right after the imports block (or at top)
        m = re.search(r'^(?:import .*?;\s*)+', content, flags=re.MULTILINE | re.DOTALL)
        insert_at = m.end() if m else 0
        new_content = (
            content[:insert_at]
            + ("" if insert_at == 0 else "\n")
            + replacement_line
            + "\n"
            + content[insert_at:]
        )

    result = subprocess.run(
        ["tee", str(quartz_layout_path)],
        input=new_content.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    if result.returncode != 0:
        print("❌ Failed to write omit list to quartz.layout.ts:", result.stderr.decode())
    else:
        plural = "entries" if replaced_count != 1 else "entry"
        print(f"✅ Updated quartz.layout.ts omit set ({replaced_count} {plural} replaced or inserted).")
# -----------------------------------------------------------------------------

def inject_custom_footer_components(quartz_layout_path: Path, footer_component_path: Path, footer_html: str):
    if quartz_layout_path.exists():
        with open(quartz_layout_path, "r", encoding="utf-8") as f:
            layout_content = f.read()

        modified_layout = re.sub(
            r'footer:\s*Component\.Footer\(\{[\s\S]*?\}\)',
            'footer: Component.Footer()',
            layout_content
        )

        result = subprocess.run(
            ["tee", str(quartz_layout_path)],
            input=modified_layout.encode(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        if result.returncode != 0:
            print("❌ Failed to update quartz.layout.ts:", result.stderr.decode())
        else:
            print("✅ Updated quartz.layout.ts to use Component.Footer()")
    else:
        print(f"⚠️ quartz.layout.ts not found at {quartz_layout_path}")

    if footer_component_path.exists():
        with open(footer_component_path, "r", encoding="utf-8") as f:
            footer_code = f.read()

        # Use a JS template literal to preserve multi-line HTML and quotes safely
        safe_html = footer_html.replace("`", "\\`")

        replacement = f"""<footer class={{displayClass ?? ""}}>
                <div dangerouslySetInnerHTML={{{{ __html: `{safe_html}` }}}} />
              </footer>"""

        modified_code = re.sub(
            r'<footer class=\{.*?\}>(.*?)</footer>',
            replacement,
            footer_code,
            flags=re.DOTALL
        )

        result = subprocess.run(
            ["tee", str(footer_component_path)],
            input=modified_code.encode(),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        if result.returncode != 0:
            print("❌ Failed to update Footer.tsx:", result.stderr.decode())
        else:
            print("✅ Injected custom HTML into Footer.tsx")
    else:
        print(f"⚠️ Footer.tsx not found at {footer_component_path}")


COLOUR_JSON_CANDIDATES = [
    Path("support/colour_schemes.json"),
    Path("/opt/support/colour_schemes.json"),
    Path(__file__).resolve().parent.parent / "support" / "colour_schemes.json",
    Path(__file__).resolve().parent / "support" / "colour_schemes.json",
]

def load_colour_schemes():
    for p in COLOUR_JSON_CANDIDATES:
        if p.exists():
            try:
                with open(p, "r", encoding="utf-8") as f:
                    data = json.load(f)
                if isinstance(data, dict) and "schemes" in data:
                    return data["schemes"]
                return data
            except Exception as e:
                print(f"⚠️ Failed to load colour_schemes.json from {p}: {e}")
    print("⚠️ colour_schemes.json not found — using existing Quartz colors.")
    return []

def find_scheme_by_id(schemes, scheme_id):
    for s in schemes:
        if s.get("id") == scheme_id:
            return s
    return None

def format_colors_block(colors: dict) -> str:
    def dict_to_ts(d, indent="          "):
        order = ["light", "lightgray", "gray", "darkgray", "dark", "secondary", "tertiary", "highlight", "textHighlight"]
        lines = []
        for k in order:
            if k in d:
                v = d[k]
                if isinstance(v, str):
                    lines.append(f'{indent}{k}: "{v}",')
        return "\n".join(lines)

    lm = colors.get("lightMode", {})
    dm = colors.get("darkMode", {})

    return (
        "      colors: {\n"
        "        lightMode: {\n"
        f"{dict_to_ts(lm)}\n"
        "        },\n"
        "        darkMode: {\n"
        f"{dict_to_ts(dm)}\n"
        "        },\n"
        "      },"
    )

def _replace_colors_block_ts(content: str, new_colors_block: str) -> str:
    m = re.search(r'colors\s*:\s*\{', content)
    if not m:
        return content

    start = m.start()
    brace_open = content.find('{', m.end() - 1)
    if brace_open == -1:
        return content

    depth = 1
    i = brace_open + 1
    n = len(content)
    while i < n and depth > 0:
        ch = content[i]
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
        i += 1

    if depth != 0:
        return content

    brace_close = i - 1
    end = brace_close + 1
    if end < n and content[end] == ',':
        end += 1

    return content[:start] + new_colors_block + content[end:]

def apply_color_scheme_to_quartz_config(quartz_config_path: Path, scheme_colors: dict):
    if not quartz_config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {quartz_config_path}")
        return

    with open(quartz_config_path, "r", encoding="utf-8") as f:
        content = f.read()

    new_colors_block = format_colors_block(scheme_colors)

    updated = _replace_colors_block_ts(content, new_colors_block)
    if updated == content:
        updated = re.sub(
            r'(theme:\s*\{\s*[\s\S]*?typography:\s*\{[\s\S]*?\},\s*)',
            r'\1\n' + new_colors_block + "\n",
            content,
            count=1
        )

    result = subprocess.run(
        ["tee", str(quartz_config_path)],
        input=updated.encode(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    if result.returncode != 0:
        print("⚠️ Error writing colors to quartz.config.ts:", result.stderr.decode())
    else:
        print("✅ Applied selected colour scheme to quartz.config.ts")


BACKLINKS_TS_CANDIDATES = [
    Path("support/Backlinks.tsx"),
    Path("/opt/support/Backlinks.tsx"),
    Path(__file__).resolve().parent.parent / "support" / "Backlinks.tsx",
    Path(__file__).resolve().parent / "support" / "Backlinks.tsx",
]

def install_patched_backlinks(output_dir: Path):
    target = output_dir / "quartz" / "components" / "Backlinks.tsx"
    src = None
    for p in BACKLINKS_TS_CANDIDATES:
        if p.exists():
            src = p
            break

    if src is None:
        print("ℹ️ Patched Backlinks.tsx not found — leaving Quartz default.")
        return

    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, target)
        try:
            rel = target.relative_to(output_dir)
        except Exception:
            rel = target
        print(f"✅ Installed patched Backlinks.tsx → {rel}")
    except Exception as e:
        print(f"❌ Failed to install patched Backlinks.tsx: {e}")


LOCALES_SRC_CANDIDATES = [
    Path("support/locales"),
    Path("/opt/support/locales"),
    Path(__file__).resolve().parent.parent / "support" / "locales",
    Path(__file__).resolve().parent / "support" / "locales",
]

def install_locales(output_dir: Path):
    target = output_dir / "quartz" / "i18n" / "locales"
    src = None
    for p in LOCALES_SRC_CANDIDATES:
        if p.exists() and p.is_dir():
            src = p
            break
    if src is None:
        print("ℹ️ Locales folder not found — leaving Quartz default locales.")
        return
    try:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(src, target, dirs_exist_ok=True)
        try:
            rel = target.relative_to(output_dir)
        except Exception:
            rel = target
        print(f"✅ Installed custom locales → {rel}")
    except Exception as e:
        print(f"❌ Failed to install custom locales: {e}")


# NEW: process frontmatter for draft/created fields
def process_frontmatter(file_path: Path, section_number: int):
    if file_path.suffix.lower() != ".md":
        return
    try:
        post = frontmatter.load(file_path)
    except Exception as e:
        print(f"⚠️ Could not read frontmatter from {file_path}: {e}")
        return

    draft_key = f"draftSection{section_number}"
    created_key = f"createdSection{section_number}"

    if draft_key in post:
        post["draft"] = post[draft_key]
    if created_key in post:
        post["created"] = post[created_key]

    for key in list(post.keys()):
        if re.match(r"draftSection\d+", key) or re.match(r"createdSection\d+", key):
            del post[key]

    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(frontmatter.dumps(post))
    except Exception as e:
        print(f"⚠️ Could not write updated frontmatter to {file_path}: {e}")

# --- ADD: Remove Graph from the right column in quartz.layout.ts (prints once) ---
_GRAPH_REMOVAL_LOGGED = False

def remove_graph_from_right(layout_path: Path):
    """Remove Component.Graph(...) from the 'right' layout array in quartz.layout.ts."""
    global _GRAPH_REMOVAL_LOGGED

    if not layout_path.exists():
        return

    try:
        with open(layout_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Target only the right: [ ... ] block and remove any Component.Graph(...) entry inside it
        def _strip_graph_block(match: re.Match) -> str:
            before, inside, after = match.group(1), match.group(2), match.group(3)
            # Remove lines containing Component.Graph(...) with optional config and trailing comma/newlines
            cleaned = re.sub(
                r'^\s*Component\.Graph\(\s*(?:\{[\s\S]*?\}\s*)?\)\s*,?\s*\n?',
                '',
                inside,
                flags=re.MULTILINE
            )
            # Tidy extraneous blank lines
            cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
            return before + cleaned + after

        new_content = re.sub(
            r'(right:\s*\[\s*)(.*?)(\s*\],)',
            _strip_graph_block,
            content,
            flags=re.DOTALL
        )

        if new_content != content:
            # Use tee to avoid silent write failures in this environment
            subprocess.run(
                ["tee", str(layout_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
            )
            if not _GRAPH_REMOVAL_LOGGED:
                print(f"🗑️  Removed Graph component from {layout_path}")
                _GRAPH_REMOVAL_LOGGED = True
    except Exception as e:
        print(f"⚠️ Could not modify {layout_path} to remove Graph: {e}")
# --- END ADD ---

# --- ADD: Patch folder page title and defaults on first build/full rebuild ---
def patch_folder_page_title(folder_page_path: Path):
    """Set folder page frontmatter title to `${folder}`."""
    if not folder_page_path.exists():
        print(f"⚠️ folderPage.tsx not found at {folder_page_path}")
        return
    try:
        with open(folder_page_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Replace: title: `${i18n(locale).pages.folderContent.folder}: ${folder}`,
        pattern = re.compile(
            r'(frontmatter:\s*\{\s*[^}]*?title:\s*)`?\$\{i18n\(locale\)\.pages\.folderContent\.folder\}\s*:\s*\$\{folder\}`?(\s*,)',
            flags=re.DOTALL
        )
        new_content = pattern.sub(r'\1`${folder}`\2', content)

        if new_content != content:
            result = subprocess.run(
                ["tee", str(folder_page_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch folderPage.tsx:", result.stderr.decode())
            else:
                print("✅ Patched folderPage.tsx to use folder name as title")
        else:
            print("ℹ️ folderPage.tsx already uses folder name as title (no change).")
    except Exception as e:
        print(f"⚠️ Error patching folderPage.tsx: {e}")

def patch_folder_content_defaults(folder_content_path: Path):
    """Set FolderContent defaultOptions.showFolderCount to false."""
    if not folder_content_path.exists():
        print(f"⚠️ FolderContent.tsx not found at {folder_content_path}")
        return
    try:
        with open(folder_content_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Only change inside the defaultOptions object
        pattern = re.compile(
            r'(const\s+defaultOptions\s*:\s*FolderContentOptions\s*=\s*\{\s*[^}]*?showFolderCount:\s*)true',
            flags=re.DOTALL
        )
        new_content = pattern.sub(r'\1false', content)

        if new_content != content:
            result = subprocess.run(
                ["tee", str(folder_content_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch FolderContent.tsx:", result.stderr.decode())
            else:
                print("✅ Set FolderContent default showFolderCount to false")
        else:
            print("ℹ️ FolderContent defaultOptions already set as desired (no change).")
    except Exception as e:
        print(f"⚠️ Error patching FolderContent.tsx: {e}")
# --- END ADD ---

# --- ADD: Patch ContentMeta defaultOptions based on course_config.show_reading_time ---
def patch_content_meta_options(date_tsx_file_path: Path, show_reading_time: bool):
    """
    Ensure ContentMeta defaultOptions reflects teacher preference:
      showReadingTime := show_reading_time
      showComma       := show_reading_time
    Runs EVERY build so a changed preference takes effect without a full rebuild.
    """
    if not date_tsx_file_path.exists():
        print(f"⚠️ ContentMeta.tsx not found at {date_tsx_file_path}")
        return
    try:
        with open(date_tsx_file_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Capture the defaultOptions block and rewrite only showReadingTime/showComma within it
        def repl(match: re.Match) -> str:
            head, body, tail = match.group(1), match.group(2), match.group(3)
            desired = "true" if show_reading_time else "false"
            body2 = re.sub(r'(showReadingTime\s*:\s*)(true|false)', r'\1' + desired, body)
            body3 = re.sub(r'(showComma\s*:\s*)(true|false)', r'\1' + desired, body2)
            return head + body3 + tail

        new_content = re.sub(
            r'(const\s+defaultOptions\s*:\s*ContentMetaOptions\s*=\s*\{)([\s\S]*?)(\})',
            repl,
            content,
            count=1
        )

        if new_content != content:
            result = subprocess.run(
                ["tee", str(date_tsx_file_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch ContentMeta.tsx to adjust reading time estimates:", result.stderr.decode())
            else:
                label = "show" if show_reading_time else "hide"
                print(f"✅ Patched ContentMeta defaultOptions to {label} reading-time")
        else:
            print("ℹ️ ContentMeta defaultOptions already match desired settings for showing reading time (no change).")
    except Exception as e:
        print(f"⚠️ Error patching ContentMeta.tsx: {e}")
# --- END ADD ---

# --- ADD: Patch renderPage.tsx to allow transcludeTitleSize frontmatter ---
def patch_render_page_transclude_title(render_page_tsx_path: Path):
    """
    Change tagName: "h1" to tagName: page.frontmatter?.transcludeTitleSize ?? "h1"
    in the node.children = [ { type: "element", tagName: "h1", ... } ] block.
    """
    if not render_page_tsx_path.exists():
        print(f"⚠️ renderPage.tsx not found at {render_page_tsx_path}")
        return
    try:
        with open(render_page_tsx_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Target the first occurrence within node.children creation
        pattern_specific = re.compile(
            r'(node\.children\s*=\s*\[\s*\{\s*type:\s*"element",\s*tagName:\s*)"h1"(\s*,\s*properties:\s*\{\s*\}\s*,\s*children\s*:\s*\[)',
            flags=re.DOTALL
        )
        replaced = pattern_specific.sub(
            r'\1page.frontmatter?.transcludeTitleSize ?? "h1"\2',
            content,
            count=1
        )

        if replaced == content:
            # Fallback: replace the first tagName: "h1" occurrence only
            pattern_fallback = re.compile(r'(tagName:\s*)"h1"')
            replaced, n = pattern_fallback.subn(
                r'\1page.frontmatter?.transcludeTitleSize ?? "h1"',
                content,
                count=1
            )
            if n == 0:
                print("ℹ️ Could not locate target 'tagName: \"h1\"' to replace in renderPage.tsx (no change).")
                return

        result = subprocess.run(
            ["tee", str(render_page_tsx_path)],
            input=replaced.encode("utf-8"),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        if result.returncode != 0:
            print("❌ Failed to patch renderPage.tsx for transcludeTitleSize:", result.stderr.decode())
        else:
            print("✅ Patched renderPage.tsx to use frontmatter transcludeTitleSize for tagName")
    except Exception as e:
        print(f"⚠️ Error patching renderPage.tsx: {e}")
# --- END ADD ---

# --- HARDENING TWEAK #2: Preflight to ensure omit anchor exists --------------
def ensure_quartz_layout_anchor(quartz_layout_path: Path) -> bool:
    """
    Make sure quartz.layout.ts contains an 'omit' Set declaration.
    If missing, warn (likely setup.sh wasn't run) and inject a safe default.
    """
    if not quartz_layout_path.exists():
        print(f"⚠️ quartz.layout.ts not found at {quartz_layout_path}")
        return False

    txt = quartz_layout_path.read_text(encoding="utf-8")
    if "const omit = new Set" in txt:
        return True

    print("⚠️ Expected omit set not found in quartz.layout.ts.")
    print("   Did you run setup.sh? (which runs setup_course.py)")
    # Insert a default omit line after imports to unblock the build
    m = re.search(r'^(?:import .*?;\s*)+', txt, flags=re.MULTILINE | re.DOTALL)
    insert_at = m.end() if m else 0
    injected = txt[:insert_at] + ("" if insert_at == 0 else "\n") + "const omit = new Set([])\n" + txt[insert_at:]
    quartz_layout_path.write_text(injected, encoding="utf-8")
    print("ℹ️ Inserted a default omit set; running setup.sh is still recommended.")
    return True
# -----------------------------------------------------------------------------

def build_section_site(course_code: str, section_number: int, include_social_media_previews: bool, force_npm_install: bool, full_rebuild: bool):
    base_dir = Path("/teaching/courses")
    course_dir = base_dir / course_code
    section_name = f"section{section_number}"

    visible_output_root = course_dir / "merged_output"
    hidden_output_root = course_dir / ".merged_output"

    if visible_output_root.exists() and not hidden_output_root.exists():
        try:
            print(f"📦 Migrating existing output '{visible_output_root.name}' → '{hidden_output_root.name}'...")
            visible_output_root.rename(hidden_output_root)
            print("✅ Migration complete.")
        except Exception as e:
            print(f"⚠️ Migration failed (will continue using hidden target): {e}")

    output_dir = hidden_output_root / section_name
    config_file = course_dir / "course_config.json"

    if not course_dir.exists():
        print(f"❌ Course folder '{course_code}' not found in {base_dir}")
        return
    if not (course_dir / section_name).exists():
        print(f"❌ Section folder '{section_name}' not found in {course_dir}")
        return
    if not config_file.exists():
        print(f"❌ course_config.json not found in {course_dir}")
        return

    section_dir = course_dir / section_name

    with open(config_file, "r", encoding="utf-8") as f:
        config = json.load(f)

    shared_folders = config.get("shared_folders", [])
    shared_files = config.get("shared_files", [])
    per_section_folders = config.get("per_section_folders", [])
    per_section_files = config.get("per_section_files", [])
    hidden_list = config.get("hidden", [])
    expandable_list = config.get("expandable", [])
    # NEW: teacher preference for reading-time
    show_reading_time = bool(config.get("show_reading_time", False))

    shared_paths = [course_dir / folder for folder in shared_folders]

    print(f"\n📁 Shared folders to include for '{section_name}':")
    for folder in shared_paths:
        print(f" - {folder.name}")

    quartz_src = Path("/opt/quartz")

    if full_rebuild or not output_dir.exists():
        if output_dir.exists():
            print(f"\n🧹 Full rebuild: clearing output directory at: {output_dir}")
            shutil.rmtree(output_dir)
        output_dir.mkdir(parents=True)
        print(f"📂 Created fresh (hidden) output directory: {output_dir}")

        print(f"📦 Copying Quartz scaffold from {quartz_src}...")
        for item in quartz_src.iterdir():
            dest = output_dir / item.name
            if item.is_dir():
                shutil.copytree(item, dest, symlinks=False)
                print(f"  📁 Copied directory: {item.name}")
            else:
                shutil.copy2(item, dest)
                print(f"  📄 Copied file: {item.name}")

        # --- ADD: Remove Graph once on first build / full rebuild ---
        remove_graph_from_right(output_dir / "quartz.layout.ts")
        # ------------------------------------------------------------

        install_locales(output_dir)
        # Adjust CreatedModifiedDate priority on first build/full rebuild
        config_path = output_dir / "quartz.config.ts"
        adjust_created_modified_priority(config_path)

        # --- ADD: Patch folder page & defaults on first build/full rebuild ---
        folder_page_tsx = output_dir / "quartz" / "plugins" / "emitters" / "folderPage.tsx"
        patch_folder_page_title(folder_page_tsx)

        folder_content_tsx = output_dir / "quartz" / "components" / "pages" / "FolderContent.tsx"
        patch_folder_content_defaults(folder_content_tsx)
        # --------------------------------------------------------------------
        
        # --- ADD: Patch Date.tsx date format & listPage.scss meta width ---
        date_tsx = output_dir / "quartz" / "components" / "Date.tsx"
        patch_date_format(date_tsx)

        list_page_scss = output_dir / "quartz" / "components" / "styles" / "listPage.scss"
        patch_list_page_meta_width(list_page_scss)
        # --------------------------------------------------------------------
        
        # --- ADD: Patch base.scss internal link highlight ---
        base_scss = output_dir / "quartz" / "styles" / "base.scss"
        patch_internal_link_highlight(base_scss)
        # ---------------------------------------------------

        # --- ADD: Append transclusion styles to base.scss ---
        append_transclusion_styles(base_scss)
        # ----------------------------------------------------

        # --- ADD: Patch renderPage.tsx for transcludeTitleSize ---
        render_page_tsx = output_dir / "quartz" / "components" / "renderPage.tsx"
        patch_render_page_transclude_title(render_page_tsx)
        # ---------------------------------------------------------

        # --- ADD: Apply selected fonts to quartz.config.ts on first build/full rebuild ---
        fonts_cfg = config.get("fonts", {})
        section_key = f"section{section_number}"
        section_fonts = (fonts_cfg.get("sections") or {}).get(section_key) or fonts_cfg.get("default")

        if section_fonts:
            patch_typography_fonts(
                quartz_config_path=config_path,
                header_font=section_fonts.get("header", "Schibsted Grotesk"),
                body_font=section_fonts.get("body", "Source Sans Pro"),
                code_font=section_fonts.get("code", "IBM Plex Mono"),
            )
        else:
            print("ℹ️ No font selections found in course_config.json — leaving Quartz defaults.")
        # -------------------------------------------------------------------------------

    else:
        print(f"♻️ Reusing existing (hidden) output directory: {output_dir}")
        # Ensure we still have paths used later in the function
        base_scss = output_dir / "quartz" / "styles" / "base.scss"

    # --- ALWAYS: Apply teacher preference to ContentMeta on each build ---
    content_meta_tsx = output_dir / "quartz" / "components" / "ContentMeta.tsx"
    patch_content_meta_options(content_meta_tsx, show_reading_time)
    # --------------------------------------------------------------------

    install_patched_backlinks(output_dir)

    content_root = output_dir / "content"
    if content_root.exists():
        print(f"\n🧹 Clearing previous content folder at: {content_root}")
        shutil.rmtree(content_root)
    content_root.mkdir(exist_ok=True)
    print(f"📂 Created fresh content folder: {content_root}")

    section_index = section_dir / "index.md"
    if section_index.exists():
        dest = content_root / "index.md"
        shutil.copy2(section_index, dest)
        process_frontmatter(dest, section_number)
        print(f"  🏠 Copied section index.md to content/index.md")
    else:
        print("⚠️ Section index.md not found — site may not render correctly.")

    print(f"\n📥 Copying shared folders into {content_root}...")
    for src_folder in shared_paths:
        print(f"🔍 Processing: {src_folder}")
        for root, dirs, files in os.walk(src_folder):
            rel_path = Path(root).relative_to(course_dir)
            dest_path = content_root / rel_path
            dest_path.mkdir(parents=True, exist_ok=True)
            for file in files:
                src_file = Path(root) / file
                dest_file = dest_path / file
                shutil.copy2(src_file, dest_file)
                process_frontmatter(dest_file, section_number)

    print(f"\n📥 Copying shared files into {content_root}...")
    for file_name in shared_files:
        src = course_dir / file_name
        dest = content_root / file_name
        if src.exists():
            shutil.copy2(src, dest)
            process_frontmatter(dest, section_number)
            print(f"  📄 Copied shared file: {file_name}")

    print(f"\n📥 Copying per-section folders...")
    for folder in per_section_folders:
        src = section_dir / folder
        dest = content_root / folder
        if src.exists():
            shutil.copytree(src, dest, dirs_exist_ok=True)
            for root, dirs, files in os.walk(dest):
                for file in files:
                    process_frontmatter(Path(root) / file, section_number)
            print(f"  📁 Copied per-section folder: {folder}")

    print(f"\n📥 Copying per-section files...")
    for file_name in per_section_files:
        src = section_dir / file_name
        dest = content_root / file_name
        if src.exists():
            shutil.copy2(src, dest)
            process_frontmatter(dest, section_number)
            print(f"  📄 Copied per-section file: {file_name}")

    # Copy course config into output
    shutil.copy2(config_file, output_dir / "course_config.json")
    print("✅ Copied course_config.json to output directory")

    # Update Quartz layout & footer
    quartz_layout_ts = output_dir / "quartz.layout.ts"
    quartz_footer_tsx = output_dir / "quartz/components/Footer.tsx"
    ensure_quartz_layout_anchor(quartz_layout_ts)  # HARDENING: make sure anchor exists
    update_quartz_layout(quartz_layout_ts, hidden_list)  # ensure omit is present and updated
    footer_html = config.get("footer_html", "")
    inject_custom_footer_components(quartz_layout_ts, quartz_footer_tsx, footer_html)

    # Update page title (now with per-section emoji)
    config_path = output_dir / "quartz.config.ts"
    # --- ADD: resolve emoji then pass into title update ---
    page_emoji = resolve_section_emoji(config, section_number)
    update_page_title(config_path, course_code, section_number, page_emoji)

    # Apply per-section colour scheme, if configured
    color_map = config.get("color_schemes", {})
    section_key = f"section{section_number}"
    chosen_scheme_id = color_map.get(section_key)
    if chosen_scheme_id:
        schemes = load_colour_schemes()
        scheme = find_scheme_by_id(schemes, chosen_scheme_id)
        if scheme and "colors" in scheme:
            apply_color_scheme_to_quartz_config(config_path, scheme["colors"])
            print(f"🎨 Applied colour scheme for {section_key}: {scheme.get('name', chosen_scheme_id)}")
        else:
            print(f"⚠️ Scheme '{chosen_scheme_id}' not found or missing 'colors' — leaving default Quartz colors.")
    else:
        print(f"ℹ️ No colour scheme selected for {section_key} — leaving default Quartz colors.")

    # Toggle CustomOgImages emitter
    if config_path.exists():
        toggle_custom_og_images(str(config_path), include_social_media_previews)
    else:
        print("Warning: quartz.config.ts not found to toggle CustomOgImages")

    # Kill existing Quartz server
    kill_existing_quartz()

    # Install npm dependencies if needed
    node_modules_dir = output_dir / "node_modules"
    package_json = output_dir / "package.json"
    package_lock = output_dir / "package-lock.json"

    needs_install = (
        force_npm_install or
        not node_modules_dir.exists() or
        not package_lock.exists() or
        package_lock.stat().st_mtime < package_json.stat().st_mtime
    )

    if needs_install:
        print("\n📦 Installing dependencies...")
        subprocess.run(["npm", "install", "--no-audit", "--silent"], cwd=output_dir, check=True)
    else:
        print("✅ Skipping npm install (dependencies already present)")

    # Launch preview
    print("\n🚀 Launching Quartz preview on http://localhost:8081\n")
    subprocess.run(["npx", "quartz", "build", "--serve", "--port", "8081"], cwd=output_dir)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build Quartz site for a course section.")
    parser.add_argument("--course", required=True, help="Course code (e.g., ICS3U)")
    parser.add_argument("--section", required=True, type=int, help="Section number (e.g., 1)")
    parser.add_argument("--include-social-media-previews", action="store_true", help="Enable social media preview images via CustomOgImages emitter")
    parser.add_argument("--force-npm-install", action="store_true", help="Force npm install even if dependencies are present")
    parser.add_argument("--full-rebuild", action="store_true", help="Clear the full output folder and re-copy Quartz scaffold")
    args = parser.parse_args()

    build_section_site(
        course_code=args.course,
        section_number=args.section,
        include_social_media_previews=args.include_social_media_previews,
        force_npm_install=args.force_npm_install,
        full_rebuild=args.full_rebuild
    )