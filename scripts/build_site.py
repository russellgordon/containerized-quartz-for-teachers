#!/usr/bin/env python3
import os
import shutil
import argparse
import frontmatter
import subprocess
import signal
import json
import re
from pathlib import Path
from datetime import datetime, timezone


# ---- Host OS signaling (for example command rendering) ----------------------
_HOST_OS = "unknown"
def _is_windows(host_os: str) -> bool:
    return (host_os or "").lower() == "windows"

def _cmd_example(script_base: str, course, section, host_os: str) -> str:
    return (f".\\{script_base}.bat {course} {section}") if _is_windows(host_os) else (f"./{script_base}.sh {course} {section}")
# ----------------------------------------------------------------------------

# --- ADD: PATCH LOCALE helper (placed near the bottom of file in the live code) ---
def patch_quartz_locale(quartz_config_path: Path, locale_code: str):
    """
    Ensure `locale: "<code>",` in quartz.config.ts matches `locale_code`.
    Tries a targeted replacement first; if not present, injects a locale key
    at the start of the exported config object.
    """
    if not quartz_config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {quartz_config_path}")
        return
    try:
        src = quartz_config_path.read_text(encoding="utf-8")

        # 1) Targeted replacement: locale: "..." or locale: '...'
        pattern = re.compile(r'(locale\s*:\s*)(["\'])([^"\']*)(\2)')
        def _repl(m: re.Match) -> str:
            quote = m.group(2)
            return f'{m.group(1)}{quote}{locale_code}{quote}'
        new_src, n = pattern.subn(_repl, src, count=1)

        # 2) Fallback: inject after the opening of defineConfig({ ... })
        if n == 0:
            m = re.search(r'defineConfig\(\s*\{', src)
            if m:
                insert_at = m.end()
                new_src = src[:insert_at] + f'\n  locale: "{locale_code}",' + src[insert_at:]
                n = 1
            else:
                new_src = src

        if n > 0 and new_src != src:
            result = subprocess.run(
                ["tee", str(quartz_config_path)],
                input=new_src.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to set locale in quartz.config.ts:", result.stderr.decode())
            else:
                print(f'✅ Set Quartz locale → "{locale_code}"')
        else:
            print("ℹ️ Quartz locale already set as desired (no change).")
    except Exception as e:
        print(f"⚠️ Error patching Quartz locale: {e}")

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


# --- ADD: Stop diagram labels being hyphenated ---
def append_mermaid_styles(base_scss_path: Path):
    """
    Turns hyphenation off inside mermaid diagrams, idempotently.

    Quartz hyphenates body text, which reads well in a paragraph. Inside
    a mermaid diagram it is a bug: the label of a box is not prose, and
    breaking it mid-word puts "Ca-" and "reers" on separate lines of a
    flowchart node. WebKit does this and Chromium does not, which is why
    a site can look right in Chrome and wrong in the Plantoir preview.

    Carries its own marker rather than joining the transclusion block, so
    course folders built before this existed pick it up on their next
    build instead of being skipped.
    """
    if not base_scss_path.exists():
        print(f"⚠️ base.scss not found at {base_scss_path}")
        return
    try:
        marker = "/* Diagram labels are not prose: never hyphenate them */"
        block = (
            "\n\n"
            f"{marker}\n"
            ".mermaid,\n"
            ".mermaid * {\n"
            "  -webkit-hyphens: none;\n"
            "  hyphens: none;\n"
            "}\n"
        )

        with open(base_scss_path, "r", encoding="utf-8") as f:
            content = f.read()

        if marker in content:
            print("ℹ️ Mermaid label styles already present in base.scss (no change).")
            return

        with open(base_scss_path, "w", encoding="utf-8") as f:
            f.write(content + block)
        print("✅ Appended mermaid label styles to base.scss")
    except Exception as e:
        print(f"⚠️ Error appending mermaid label styles: {e}")
# --- END ADD ---


# --- ADD: Let the right sidebar's two panels share the column ---
def append_sidebar_sharing_styles(base_scss_path: Path):
    """
    Stop a long backlinks list from crowding out the table of contents.

    The right sidebar holds "Navigate this page" above "When did we do
    this?". A page linked from many others gave the backlinks list its
    full natural height first, squeezing the table of contents down to a
    line or two with a scrollbar — on the very pages where the contents
    are most useful.

    The rules below give each panel its own scrollbar and make them share
    the column: the table of contents takes only the height it needs, up
    to half, and the backlinks take whatever is left. So a short contents
    list keeps the backlinks tucked directly beneath it, and when both are
    long they land at roughly half each.

    The cap is skipped when the contents are the only panel, so a page
    nothing links to still uses the whole column. Specificity is kept
    below Quartz's own `.toc:has(button.toc-header.collapsed)` rule, so
    collapsing the contents still works.

    Carries its own marker so existing course folders pick it up.
    """
    if not base_scss_path.exists():
        print(f"⚠️ base.scss not found at {base_scss_path}")
        return
    try:
        marker = "/* The right sidebar's two panels share the column */"
        block = (
            "\n\n"
            f"{marker}\n"
            "/* Not shrinkable: the contents keep the height they need,\n"
            "   and the cap below is what stops them taking over. */\n"
            ".right.sidebar > .toc {\n"
            "  flex: 0 0 auto;\n"
            "  min-height: 0;\n"
            "  max-height: 100%;\n"
            "}\n\n"
            ".right.sidebar > .toc:not(:only-child) {\n"
            "  max-height: 50%;\n"
            "}\n\n"
            ".right.sidebar > *:not(.toc) {\n"
            "  flex: 1 1 auto;\n"
            "  min-height: 0;\n"
            "}\n\n"
            ".right.sidebar .toc-content,\n"
            ".right.sidebar .backlinks {\n"
            "  flex: 1 1 auto;\n"
            "  min-height: 0;\n"
            "  max-height: 100%;\n"
            "  overflow-y: auto;\n"
            "}\n\n"
            "/* The lists are the real scrollers: their parents are row\n"
            "   flex containers, so the overflow happens one level in. */\n"
            ".right.sidebar .toc-content > ul,\n"
            ".right.sidebar .backlinks > ul {\n"
            "  min-height: 0;\n"
            "  max-height: 100%;\n"
            "  overflow-y: auto;\n"
            "}\n"
        )

        with open(base_scss_path, "r", encoding="utf-8") as f:
            content = f.read()

        if marker in content:
            print("ℹ️ Sidebar sharing styles already present in base.scss (no change).")
            return

        with open(base_scss_path, "w", encoding="utf-8") as f:
            f.write(content + block)
        print("✅ Appended sidebar sharing styles to base.scss")
    except Exception as e:
        print(f"⚠️ Error appending sidebar sharing styles: {e}")
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
            '}\n'
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
        print(f"⚠️ Error patching Date.tsx: {e}")
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

# --- ADD: Ensure configuration.defaultDateType === "created" -----------------
def patch_default_date_type(quartz_config_path: Path):
    """
    Ensure quartz.config.ts has configuration.defaultDateType set to "created".
    Tries to update if present; otherwise injects into the configuration block.
    Idempotent.
    """
    if not quartz_config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {quartz_config_path}")
        return

    try:
        txt = quartz_config_path.read_text(encoding="utf-8")

        # Find 'configuration: {' and match its balanced braces
        m = re.search(r'(configuration\s*:\s*\{)', txt)
        if not m:
            # No configuration block — inject one after 'theme' block or near top-level
            inject_block = 'configuration: {\n      defaultDateType: "created",\n    },'
            # Try to insert after theme: { ... }
            theme_m = re.search(r'(theme\s*:\s*\{)', txt)
            if not theme_m:
                # Insert at the start of the exported object (after first '{')
                first_brace = txt.find('{')
                if first_brace != -1:
                    new_txt = txt[:first_brace+1] + "\n  " + inject_block + "\n" + txt[first_brace+1:]
                else:
                    new_txt = txt + "\n" + inject_block + "\n"
            else:
                # Find end of theme block by counting braces
                brace_open = txt.find('{', theme_m.end()-1)
                if brace_open == -1:
                    new_txt = txt
                else:
                    depth = 1
                    i = brace_open + 1
                    n = len(txt)
                    while i < n and depth > 0:
                        ch = txt[i]
                        if ch == '{':
                            depth += 1
                        elif ch == '}':
                            depth -= 1
                        i += 1
                    end = i  # position after closing brace
                    new_txt = txt[:end] + ",\n    " + inject_block + "\n" + txt[end:]
            if new_txt != txt:
                result = subprocess.run(
                    ["tee", str(quartz_config_path)],
                    input=new_txt.encode("utf-8"),
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE
                )
                if result.returncode != 0:
                    print("❌ Failed to inject configuration.defaultDateType:", result.stderr.decode())
                else:
                    print('✅ Inserted configuration.defaultDateType = "created"')
            else:
                print("ℹ️ Could not locate an insertion point for configuration block (no change).")
            return

        # We have a configuration block — find its closing brace
        brace_open = txt.find('{', m.end()-1)
        if brace_open == -1:
            print("ℹ️ Malformed configuration block (no change).")
            return
        depth = 1
        i = brace_open + 1
        n = len(txt)
        while i < n and depth > 0:
            ch = txt[i]
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
            i += 1
        brace_close = i - 1  # index of matching '}'

        inner = txt[brace_open+1:brace_close]

        # If defaultDateType exists, replace its value; else insert it at the top
        if re.search(r'\bdefaultDateType\s*:', inner):
            inner2 = re.sub(r'(defaultDateType\s*:\s*)"(.*?)"', r'\1"created"', inner, count=1)
        else:
            # Determine indentation
            line_start = txt.rfind('\n', 0, m.start()) + 1
            base_indent = re.match(r'[ \t]*', txt[line_start:m.start()]).group(0)
            inner_indent = base_indent + "  "
            if inner.strip():
                inner2 = "\n" + inner_indent + 'defaultDateType: "created",' + "\n" + inner.lstrip()
            else:
                inner2 = "\n" + inner_indent + 'defaultDateType: "created"' + "\n" + base_indent

        new_txt = txt[:brace_open+1] + inner2 + txt[brace_close:]
        if new_txt != txt:
            result = subprocess.run(
                ["tee", str(quartz_config_path)],
                input=new_txt.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch configuration.defaultDateType:", result.stderr.decode())
            else:
                print('✅ Ensured configuration.defaultDateType = "created"')
        else:
            print("ℹ️ configuration.defaultDateType already set (no change).")

    except Exception as e:
        print(f"⚠️ Error ensuring configuration.defaultDateType: {e}")
# --- END ADD -----------------------------------------------------------------

# --- ADD: Resolve per-section emoji from course_config.json ------------------
def resolve_section_emoji(config: dict, section_number: int) -> str:
    """
    Returns the emoji to use for the page title, preferring the per-section choice.
    Falls back to a legacy course-level default only if present; otherwise '📚'.
    """
    try:
        emojis = config.get("emojis", {})
        if isinstance(emojis, dict):
            sec_map = emojis.get("sections") or {}
            sec_emo = sec_map.get(f"section{section_number}")
            if isinstance(sec_emo, str) and sec_emo.strip():
                return sec_emo.strip()
            # Back-compat: if older configs stored a course-level "default", use it as a fallback
            legacy_default = emojis.get("default")
            if isinstance(legacy_default, str) and legacy_default.strip():
                return legacy_default.strip()
    except Exception:
        pass
    return "📚"
# --- END ADD -----------------------------------------------------------------

# --- ADD: Resolve per-section 'show section marker' flag ---------------------

# --- ADD: Resolve header label (course code vs custom short name for clubs) ---
def resolve_header_label(config: dict, course_code: str) -> str:
    """Return the label that appears beside the emoji in the page title.

    If the course code's 4th character is a digit (e.g., MPM2D, ICS3U),
    we preserve the existing behavior of showing the COURSE CODE in UPPERCASE.

    If there is *no* numeric 4th character (e.g., CODING, MATH), we try to use
    a custom short name saved in course_config.json under "custom_short_name".
    If it's not present, we fall back to a title-cased version of the course code.
    """
    grade_char = course_code[3] if len(course_code) >= 4 else ""
    if grade_char.isdigit():
        return course_code.upper()
    # Club/Non-standard code
    custom = (config.get("custom_short_name") or "").strip()
    if custom:
        return custom
    return course_code.title()
def resolve_show_section_marker(config: dict, section_number: int) -> bool:
    """
    Return whether 'S{section}' should appear in the page title.
    Supports several shapes in course_config.json:

      {
        "show_section_marker": {
          "sections": { "section3": false, "section4": true },
          "default": true
        }
      }

    Also accepts:
      - {"show_section_marker": {"section3": false}}
      - {"show_section_marker": true/false}
      - Legacy/alt keys: show_section_in_title, showSectionMarkerInTitle, showSectionMarker

    Default when absent: True.
    """
    sec_key = f"section{section_number}"
    candidates = [
        "show_section_marker",
        "show_section_in_title",
        "showSectionMarkerInTitle",
        "showSectionMarker",
    ]

    for key in candidates:
        val = config.get(key)
        if isinstance(val, dict):
            # Prefer nested "sections" map
            sec_map = val.get("sections")
            if isinstance(sec_map, dict) and sec_key in sec_map:
                return bool(sec_map[sec_key])
            # Or direct section key at top-level
            if sec_key in val:
                return bool(val[sec_key])
            # Or a course-level default
            if "default" in val:
                return bool(val["default"])
        elif isinstance(val, bool):
            return val

    return True
# --- END ADD -----------------------------------------------------------------

# --- ADD: Remove section marker from a full course title ---------------------

GRADE_LABELS = {"1": "Grade 9", "2": "Grade 10", "3": "Grade 11", "4": "Grade 12"}


def resolve_show_grade_in_title(cfg, section_number):
    """Per-section, like the section marker; defaults on. An older config
    that stored one course-wide boolean is honoured."""
    raw = cfg.get("show_grade_in_title", True)
    if isinstance(raw, dict):
        return bool((raw.get("sections") or {}).get(f"section{section_number}", True))
    return bool(raw)


def computed_landing_title(cfg, section_number, show_marker):
    """
    The landing page's title, computed from the CURRENT settings at build
    time — never baked in at scaffold time. This is what makes a course
    rename reach the site, makes the grade a switch (show_grade_in_title,
    default on), and keeps the grade from doubling when the course name
    already carries one ("Computer Science, Grade 12, U").
    """
    name = str(cfg.get("course_name") or cfg.get("course_code") or "").strip()
    code = str(cfg.get("course_code") or "")
    # Deliberately literal: the switch alone decides. The app warns when
    # the name already carries the grade; what to do about it — edit the
    # name or turn the switch off — is the teacher's call, never guessed.
    prefix = ""
    if resolve_show_grade_in_title(cfg, section_number) and len(code) >= 4 and code[3].isdigit():
        prefix = GRADE_LABELS.get(code[3], "Grade ?") + " "
    title = f"{prefix}{name}"
    if show_marker:
        title = f"{title}, Section {section_number}"
    return title


def set_landing_title(index_md_path: Path, cfg, section_number, show_marker):
    """Writes the computed title into the MERGED copy of the section's
    landing page. The teacher's source index.md is never touched."""
    if not index_md_path.exists():
        return
    try:
        post = frontmatter.load(index_md_path)
        post["title"] = computed_landing_title(cfg, section_number, show_marker)
        with open(index_md_path, "w", encoding="utf-8") as f:
            f.write(frontmatter.dumps(post))
        print(f"📝 Landing page title: '{post['title']}'")
    except Exception as e:
        print(f"⚠️ Could not set the landing page title: {e}")
# --- END ADD -----------------------------------------------------------------


# --- NEW: Read/validate timetable section numbers ---------------------------
def get_allowed_section_numbers(config: dict) -> list[int]:
    """
    Returns the list of timetable section numbers for this course.
    Falls back to [1..num_sections] if 'section_numbers' is not present.
    """
    try:
        seq = config.get("section_numbers")
        if isinstance(seq, list) and seq:
            # Ensure ints
            return [int(x) for x in seq]
        n = int(config.get("num_sections", 1))
        return list(range(1, n + 1))
    except Exception:
        return [1]

def validate_requested_section(allowed: list[int], requested: int) -> bool:
    if requested in allowed:
        return True
    print("❌ The requested section is not part of this course's timetable sections.")
    print(f"   Allowed sections for this course: {allowed}")
    print("   Tip: Re-run with e.g. '--section 3' to build Section 3 if that's assigned to you.")
    return False
# ---------------------------------------------------------------------------

def update_page_title(config_path: Path, header_label: str, section_number: int, emoji: str, show_section_marker: bool = True):
    if not config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {config_path}")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    updated = False
    # --- MODIFIED: use resolved emoji & optional section marker ---
    safe_emoji = (emoji or "📚").strip()
    if show_section_marker:
        new_title = f'{safe_emoji} {header_label} S{section_number}'
    else:
        new_title = f'{safe_emoji} {header_label}'

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


def kill_existing_quartz(port: int = 8081):
    # Only OUR port: several previews can run at once, one per port, and
    # starting one must never take down another window's preview.
    #
    # Signal the process directly rather than shelling out to `kill`:
    # `kill` is a shell builtin, and the /bin/kill binary (procps) is not
    # installed in this image, so subprocess could not find it.
    try:
        output = subprocess.check_output(["lsof", "-ti", f":{port}"])
    except (subprocess.CalledProcessError, FileNotFoundError):
        return
    pids = output.decode().strip().split("\n")
    for pid in pids:
        if not pid:
            continue
        try:
            os.kill(int(pid), signal.SIGKILL)
            print(f"🛑 Killed existing process on port {port} (PID: {pid})")
        except (ValueError, ProcessLookupError, PermissionError) as e:
            print(f"⚠️ Could not stop process {pid} on port {port}: {e}")


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
        print(f"⚠️ quartz.layout.ts not found at: {quartz_layout_path}")

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
    """
    Copy a patched Backlinks.tsx into the build, but avoid touching the
    filesystem if it's already identical (reduces churn).
    """
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

        # Only copy if different or missing
        try:
            src_bytes = Path(src).read_bytes()
        except Exception:
            src_bytes = b""
        try:
            dst_bytes = Path(target).read_bytes() if target.exists() else b""
        except Exception:
            dst_bytes = b""

        if target.exists() and src_bytes == dst_bytes:
            try:
                rel = target.relative_to(output_dir)
            except Exception:
                rel = target
            print(f"✔️  Backlinks.tsx already up to date → {rel}")
            return

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


# --- NEW: helper to generate timestamp string in desired format --------------
def _current_created_timestamp() -> str:
    """
    Returns current timestamp like: 2025-08-10T12:30:24.000-0400
    Uses America/Toronto when available, otherwise system local time.
    """
    ts = None
    try:
        # Prefer explicit TZ when tzdata is available
        from zoneinfo import ZoneInfo  # Python 3.11+
        ts = datetime.now(ZoneInfo("America/Toronto"))
    except Exception:
        ts = datetime.now().astimezone()
    # Build string with fixed millisecond precision ".000" (as requested)
    return ts.strftime("%Y-%m-%dT%H:%M:%S") + ".000" + ts.strftime("%z")
# ---------------------------------------------------------------------------


# === NEW: Curriculum 'created' synchronization helpers ======================
def _is_in_curriculum_folder(path: Path) -> bool:
    """
    True if any directory segment in the file's path contains 'curriculum' (case-insensitive).
    We check parent folders only; filenames themselves do not trigger this.
    """
    parts = list(path.parts)
    # Drop filename
    if parts:
        parts = parts[:-1]
    for seg in parts:
        if "curriculum" in seg.lower():
            return True
    return False

def _fix_tz_colon(s: str) -> str:
    # Turn trailing +HHMM/-HHMM into +HH:MM/-HH:MM for fromisoformat
    return re.sub(r'([+-]\d{2})(\d{2})$', r'\1:\2', s)

def _parse_created_value(val) -> datetime | None:
    """
    Parse a frontmatter 'created' value into an aware datetime (best-effort).
    Supports:
      - 2025-08-10
      - 2025-08-10T12:34
      - 2025-08-10T12:34:56
      - 2025-08-10 12:34:56
      - 2025-08-10T12:34:56.000-0400 (no colon offset)
      - 2025-08-10T12:34:56.000-04:00
      - 2025-08-10T12:34:56Z
    Naive datetimes are assumed in America/Toronto.
    """
    if isinstance(val, datetime):
        dt = val
    elif isinstance(val, str):
        s = val.strip()
        if not s:
            return None
        # Handle Zulu
        if s.endswith("Z") or s.endswith("z"):
            s = s[:-1] + "+00:00"
        # Fix timezone offset without colon
        s = _fix_tz_colon(s)
        # Try fromisoformat
        try:
            dt = datetime.fromisoformat(s)
        except Exception:
            # Try a few common patterns
            fmts = [
                "%Y-%m-%d",
                "%Y-%m-%d %H:%M",
                "%Y-%m-%d %H:%M:%S",
                "%Y-%m-%dT%H:%M",
                "%Y-%m-%dT%H:%M:%S",
                "%Y-%m-%dT%H:%M:%S.%f",
            ]
            dt = None
            for fmt in fmts:
                try:
                    dt = datetime.strptime(s, fmt)
                    break
                except Exception:
                    continue
            if dt is None:
                return None
    else:
        return None

    # Ensure timezone-aware
    try:
        from zoneinfo import ZoneInfo
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=ZoneInfo("America/Toronto"))
    except Exception:
        if dt.tzinfo is None:
            dt = dt.astimezone()
    return dt

def _format_created_timestamp_from_dt(dt: datetime) -> str:
    """
    Format a datetime using the same canonical style as _current_created_timestamp(),
    always emitting no-colon offset and fixed '.000' milliseconds, in America/Toronto.
    """
    try:
        from zoneinfo import ZoneInfo
        dt = dt.astimezone(ZoneInfo("America/Toronto"))
    except Exception:
        if dt.tzinfo is None:
            dt = dt.astimezone()
    return dt.strftime("%Y-%m-%dT%H:%M:%S") + ".000" + dt.strftime("%z")

def _find_latest_created_in_section(content_root: Path) -> datetime | None:
    """Scan all .md under content_root and return the max frontmatter 'created' datetime (aware)."""
    latest = None
    for root, dirs, files in os.walk(content_root):
        for name in files:
            if not name.lower().endswith(".md"):
                continue
            fp = Path(root) / name
            try:
                post = frontmatter.load(fp)
                raw = post.get("created")
                dt = _parse_created_value(raw)
                if dt is not None:
                    if (latest is None) or (dt > latest):
                        latest = dt
            except Exception:
                # ignore unreadable files
                continue
    return latest

def _sync_curriculum_created(content_root: Path, latest_dt: datetime) -> tuple[int, int, int]:
    """
    For each curriculum .md file, if its 'created' is absent or older than latest_dt,
    update it to latest_dt (formatted canonically). Returns (updated, skipped, folder_count).
    """
    if latest_dt is None:
        return (0, 0, 0)

    updated = 0
    skipped = 0
    seen_folders = set()

    for root, dirs, files in os.walk(content_root):
        for name in files:
            if not name.lower().endswith(".md"):
                continue
            fp = Path(root) / name
            if not _is_in_curriculum_folder(fp):
                continue
            try:
                post = frontmatter.load(fp)
            except Exception:
                skipped += 1
                continue

            curr = _parse_created_value(post.get("created"))
            if (curr is None) or (curr < latest_dt):
                post["created"] = _format_created_timestamp_from_dt(latest_dt)
                try:
                    with open(fp, "w", encoding="utf-8") as f:
                        f.write(frontmatter.dumps(post))
                    updated += 1
                    # Track folder for summary
                    try:
                        for seg in fp.parents:
                            if "curriculum" in seg.name.lower():
                                seen_folders.add(str(seg))
                                break
                    except Exception:
                        pass
                except Exception:
                    skipped += 1
            else:
                skipped += 1

    return (updated, skipped, len(seen_folders))
# ===========================================================================


# Track curriculum folders we've already logged this build (legacy; no longer used directly)
_logged_curriculum_folders = set()

# UPDATED: process frontmatter for draft/created fields (no unconditional curriculum bump)
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

    # NOTE: Removed unconditional Curriculum timestamp bump here.
    # The new logic runs after all files are copied, syncing curriculum files
    # to the section's latest 'created' value only when newer.

    try:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(frontmatter.dumps(post))
    except Exception as e:
        print(f"⚠️ Could not write updated frontmatter to {file_path}: {e}")

# --- ADD: NEW HELPER — Rewrite wikilinks with section path to alias-only -----
def rewrite_section_wikilinks(md_path: Path):
    """
    Rewrites Obsidian wikilinks that include a section path to alias-only form.
    Examples:
      [[section2/All Classes/Thread 2, Day 8|Thread 2, Day 8]] -> [[Thread 2, Day 8]]
      ![[section1/Bananas/Benefits of Banana Consumption|Benefits of Banana Consumption]] -> ![[Benefits of Banana Consumption]]
    Only rewrites when:
      - a '|' alias exists, and
      - the target contains 'section<digits>/' somewhere in its path.
    """
    if md_path.suffix.lower() != ".md" or not md_path.exists():
        return
    try:
        text = md_path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"⚠️ Could not read {md_path} to rewrite wikilinks: {e}")
        return

    pattern = re.compile(r'(!?)\[\[([^\[\]]+?)\]\]')
    count = 0

    def _repl(m: re.Match) -> str:
        nonlocal count
        bang = m.group(1)  # '!' or ''
        inner = m.group(2) # e.g., 'section2/All Classes/Thread 2, Day 8|Thread 2, Day 8'
        if '|' not in inner:
            return m.group(0)
        target, alias = inner.split('|', 1)
        # Rewrite only if a section path is present
        if re.search(r'(?:^|/)section\d+/', target):
            count += 1
            return f"{bang}[[{alias.strip()}]]"
        return m.group(0)

    new_text = pattern.sub(_repl, text)
    if count > 0 and new_text != text:
        try:
            md_path.write_text(new_text, encoding="utf-8")
            print(f"🔗 Rewrote {count} section-path wikilink(s) in: {md_path}")
        except Exception as e:
            print(f"⚠️ Could not write rewritten wikilinks to {md_path}: {e}")
# --- END ADD -----------------------------------------------------------------

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
def patch_katex_mhchem(latex_ts_path: Path):
    """
    Turn on mhchem, the chemistry notation for KaTeX.

    Quartz renders maths at build time with rehype-katex, and KaTeX ships
    mhchem in the same package — it is simply not loaded. Without it
    `\\ce{...}` fails SILENTLY: no error, no red text, just garbage on the
    page that a proofreader skims past. With it, one import, chemistry
    gets the notation it deserves:

        $\\ce{CaCO3(s) <=> CaO(s) + CO2(g)}$

    renders with a real equilibrium arrow and upright element symbols,
    which is tedious and error-prone to hand-build out of \\text{} and
    \\rightleftharpoons.

    The import is a side effect on the shared KaTeX instance, and it runs
    in Node during the build — nothing extra is sent to a browser.
    Idempotent.
    """
    if not latex_ts_path.exists():
        print(f"⚠️ latex.ts not found at {latex_ts_path}")
        return
    try:
        with open(latex_ts_path, "r", encoding="utf-8") as f:
            content = f.read()

        if "katex/contrib/mhchem" in content:
            print("ℹ️ mhchem already enabled (no change).")
            return

        anchor = 'import rehypeKatex from "rehype-katex"'
        if anchor not in content:
            print("⚠️ Could not find the rehype-katex import; mhchem left off.")
            return

        content = content.replace(
            anchor,
            anchor + '\n// Chemistry notation for KaTeX. It ships inside the katex\n'
                     '// package and only needs loading; without it \\ce{} fails silently.\n'
                     'import "katex/contrib/mhchem"',
            1,
        )
        with open(latex_ts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ Patched latex.ts to enable mhchem chemistry notation")
    except Exception as e:
        print(f"⚠️ Error enabling mhchem: {e}")


def patch_google_font_href(theme_ts_path: Path, head_tsx_path: Path):
    """
    Stop asking Google Fonts for fonts that are not Google Fonts.

    Quartz builds one stylesheet request from all three typography
    choices. Plantoir offers system stacks such as "Helvetica, Arial"
    alongside real Google families, and Google rejects the WHOLE request
    with HTTP 400 if any family is unknown to it. The observed effect:

        GET .../css2?family=Helvetica,%20Arial:...&family=IBM%20Plex%20Mono:...
        400

    So NO font downloads — including the code font mermaid measures its
    diagram labels in. That is why a diagram came out mangled until a
    reload, and why `static/fonts/` was empty: the emitter fetches the
    same URL to self-host the fonts and got the same 400.

    A system stack needs no download; it is already on the machine. This
    filters those families out of the request and, if nothing is left to
    ask for, drops the request entirely.
    """
    if not theme_ts_path.exists():
        print(f"⚠️ theme.ts not found at {theme_ts_path}")
        return
    try:
        with open(theme_ts_path, "r", encoding="utf-8") as f:
            content = f.read()

        marker = "isDownloadableFont"
        if marker in content:
            print("ℹ️ Google Fonts request already filtered (no change).")
            return

        old = (
            "export function googleFontHref(theme: Theme) {\n"
            "  const { code, header, body } = theme.typography\n"
            "  const headerFont = formatFontSpecification(\"header\", header)\n"
            "  const bodyFont = formatFontSpecification(\"body\", body)\n"
            "  const codeFont = formatFontSpecification(\"code\", code)\n"
            "\n"
            "  return `https://fonts.googleapis.com/css2?family=${bodyFont}&family=${headerFont}&family=${codeFont}&display=swap`\n"
            "}"
        )
        if old not in content:
            print("⚠️ googleFontHref not in the expected shape; left unchanged.")
            return

        new = '''// A CSS font stack ("Helvetica, Arial") or a family already on the
// machine is not something Google Fonts can serve, and ONE unknown
// family makes it reject the whole request with 400 — taking the real
// families down with it. Only ask for what it can actually provide.
const SYSTEM_FONT_FAMILIES = new Set([
  "arial",
  "consolas",
  "courier",
  "courier new",
  "georgia",
  "helvetica",
  "helvetica neue",
  "menlo",
  "monaco",
  "monospace",
  "sans-serif",
  "serif",
  "sf mono",
  "system-ui",
  "times",
  "times new roman",
  "ui-monospace",
  "verdana",
  "-apple-system",
])

function isDownloadableFont(spec: FontSpecification): boolean {
  const name = getFontSpecificationName(spec).trim()
  if (name.length === 0) {
    return false
  }
  // A comma means a stack, not a family.
  if (name.includes(",")) {
    return false
  }
  return !SYSTEM_FONT_FAMILIES.has(name.toLowerCase().replace(/^["']|["']$/g, ""))
}

export function googleFontHref(theme: Theme) {
  const { code, header, body } = theme.typography
  const families: string[] = []
  if (isDownloadableFont(body)) {
    families.push(formatFontSpecification("body", body))
  }
  if (isDownloadableFont(header)) {
    families.push(formatFontSpecification("header", header))
  }
  if (isDownloadableFont(code)) {
    families.push(formatFontSpecification("code", code))
  }
  if (families.length === 0) {
    return ""
  }

  return `https://fonts.googleapis.com/css2?${families
    .map((family) => `family=${family}`)
    .join("&")}&display=swap`
}'''
        content = content.replace(old, new, 1)
        with open(theme_ts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ Patched theme.ts so only real Google families are requested")
    except Exception as e:
        print(f"⚠️ Error patching googleFontHref: {e}")
        return

    # With no families to fetch, the <link> must not be emitted at all.
    if not head_tsx_path.exists():
        return
    try:
        with open(head_tsx_path, "r", encoding="utf-8") as f:
            head = f.read()
        old_link = '            <link rel="stylesheet" href={googleFontHref(cfg.theme)} />'
        new_link = ('            {googleFontHref(cfg.theme) !== "" && (\n'
                    '              <link rel="stylesheet" href={googleFontHref(cfg.theme)} />\n'
                    '            )}')
        if old_link in head:
            head = head.replace(old_link, new_link, 1)
            with open(head_tsx_path, "w", encoding="utf-8") as f:
                f.write(head)
            print("✅ Patched Head.tsx to skip an empty font request")
    except Exception as e:
        print(f"⚠️ Error patching Head.tsx: {e}")


def patch_mermaid_font_wait(mermaid_ts_path: Path):
    """
    Make mermaid wait for the code font before it measures anything.

    Mermaid sizes every box by measuring its label, and Quartz tells it to
    measure in the course's code font (`--codeFont`). That font comes from
    Google Fonts with `display=swap`, which means the browser paints with
    a fallback first and swaps the real font in when it arrives. If the
    swap lands after mermaid has measured, every box was sized for the
    narrower fallback and the real text overflows it — labels come out
    clipped mid-word.

    Waiting for `document.fonts.ready` costs nothing when the font is
    already cached, and removes the race when it is not. Idempotent.
    """
    if not mermaid_ts_path.exists():
        print(f"⚠️ mermaid.inline.ts not found at {mermaid_ts_path}")
        return
    try:
        marker = "document.fonts.load"
        with open(mermaid_ts_path, "r", encoding="utf-8") as f:
            content = f.read()

        if marker in content:
            print("ℹ️ Mermaid already waits for fonts (no change).")
            return

        target = "    await mermaid.run({ nodes })"
        if target not in content:
            print("⚠️ Could not find mermaid.run call to patch; left unchanged.")
            return

        replacement = (
            "    // Mermaid measures label text to size each box, and it is\n"
            "    // told to measure in the code font. That font is served with\n"
            "    // display=swap, so without this wait it can measure the\n"
            "    // narrower fallback and size every box too small for the\n"
            "    // text that finally renders in it.\n"
            "    if (document.fonts) {\n"
            "      // document.fonts.ready only settles the loads already PENDING.\n"
            "      // If nothing on the page has demanded the code font yet, it\n"
            "      // resolves at once and mermaid measures the fallback anyway —\n"
            "      // so ask for the font first, in the weights a diagram uses.\n"
            "      const codeFamily = (computedStyleMap[\"--codeFont\"] || \"\").split(\",\")[0].trim()\n"
            "      if (codeFamily) {\n"
            "        try {\n"
            "          await Promise.all([\n"
            "            document.fonts.load(`400 16px ${codeFamily}`),\n"
            "            document.fonts.load(`700 16px ${codeFamily}`),\n"
            "          ])\n"
            "        } catch (error) {\n"
            "          // A font that will not load is not worth failing over.\n"
            "        }\n"
            "      }\n"
            "      await document.fonts.ready\n"
            "    }\n"
            "\n"
            + target
        )
        content = content.replace(target, replacement, 1)

        with open(mermaid_ts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ Patched mermaid.inline.ts to wait for fonts before measuring")
    except Exception as e:
        print(f"⚠️ Error patching mermaid font wait: {e}")


def patch_mermaid_pie_colours(mermaid_ts_path: Path):
    """
    Give pie charts a palette in which every slice is visible and legible,
    whichever colour scheme the teacher picked.

    Mermaid's base theme takes a pie chart's first slice colour from
    `primaryColor`, and Quartz sets `primaryColor` to `--light` — the page
    background. That is right for a flowchart node and wrong for a pie
    slice: slice one was drawn in the background colour, so it vanished,
    and its legend swatch with it.

    The palette is SOLVED at render time rather than hardcoded, because
    Plantoir ships 43 colour schemes and each has a light and a dark mode.
    Fixed blend fractions tuned against one scheme failed 74 of those 86
    combinations — some slices came out barely distinguishable from the
    label text. Instead: build a pool of tints of the scheme's own colours,
    keep only those with at least 4.5:1 contrast against the label text and
    1.45:1 against the page, then walk the pool taking the farthest colour
    from everything chosen so far. That anchors on the course's main accent
    and keeps every later slice as distinct as the scheme allows.

    A monochrome scheme can only give tints of one hue, so its slices
    differ by lightness alone — inherent, not a defect.

    Idempotent, and it replaces the earlier fixed-fraction version in a
    scaffold that already carries it.
    """
    if not mermaid_ts_path.exists():
        print(f"⚠️ mermaid.inline.ts not found at {mermaid_ts_path}")
        return
    try:
        with open(mermaid_ts_path, "r", encoding="utf-8") as f:
            content = f.read()

        block_start = "    // Mermaid's base theme takes a pie chart's first slice from"
        block_end = '    pieSliceColours.pieOpacity = "1"'
        version = "pie palette: solved per scheme"

        if version in content:
            print("ℹ️ Mermaid pie palette already set (no change).")
            return

        # An earlier version of this patch is in the file: take it out
        # first, or its consts would be declared twice and the build fails.
        if block_start in content and block_end in content:
            head, rest = content.split(block_start, 1)
            _, tail = rest.split(block_end, 1)
            content = head + tail.lstrip("\n")
            print("ℹ️ Replacing the earlier fixed-fraction pie palette.")

        anchor = '    const darkMode = document.documentElement.getAttribute("saved-theme") === "dark"'
        if anchor not in content:
            print("⚠️ Could not find the mermaid theme setup to patch; left unchanged.")
            return

        palette = anchor + "\n" + '''
    // Mermaid's base theme takes a pie chart's first slice from
    // primaryColor, which Quartz sets to the page background — so slice one
    // was drawn in the background colour and disappeared, legend swatch and
    // all. Build the palette from this scheme's own colours instead.
    // pie palette: solved per scheme, because Plantoir ships 43 schemes and
    // fractions tuned against one of them fail most of the others.
    const toChannels = (value: string): number[] => {
      const text = value.trim()
      if (text.startsWith("#")) {
        const hex =
          text.length === 4
            ? text[1] + text[1] + text[2] + text[2] + text[3] + text[3]
            : text.slice(1, 7)
        return [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16))
      }
      const parts = text.match(/\\d+(\\.\\d+)?/g) ?? ["0", "0", "0"]
      return [Number(parts[0]), Number(parts[1]), Number(parts[2])]
    }
    const blend = (from: string, to: string, amount: number): string => {
      const a = toChannels(from)
      const b = toChannels(to)
      return (
        "#" +
        [0, 1, 2]
          .map((i) =>
            Math.max(0, Math.min(255, Math.round(a[i] + (b[i] - a[i]) * amount)))
              .toString(16)
              .padStart(2, "0"),
          )
          .join("")
      )
    }
    const relativeLuminance = (colour: string): number => {
      const channels = toChannels(colour).map((value) => {
        const scaled = value / 255
        return scaled <= 0.03928
          ? scaled / 12.92
          : Math.pow((scaled + 0.055) / 1.055, 2.4)
      })
      return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
    }
    const contrastRatio = (one: string, two: string): number => {
      const a = relativeLuminance(one)
      const b = relativeLuminance(two)
      return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05)
    }
    const separation = (one: string, two: string): number => {
      const a = toChannels(one)
      const b = toChannels(two)
      return Math.sqrt(
        [0, 1, 2].reduce((total, i) => total + (a[i] - b[i]) ** 2, 0),
      )
    }

    const pageColour = computedStyleMap["--light"]
    const labelColour = computedStyleMap["--dark"]
    // Readable against the label text, and clearly not the page itself.
    const readable = (colour: string) =>
      contrastRatio(colour, labelColour) >= 4.5 &&
      contrastRatio(colour, pageColour) >= 1.45

    const sliceSources = [
      computedStyleMap["--secondary"],
      computedStyleMap["--tertiary"],
      computedStyleMap["--darkgray"],
      computedStyleMap["--gray"],
      labelColour,
    ]
    const slicePool: string[] = []
    for (const source of sliceSources) {
      for (let step = 0; step <= 40; step++) {
        const candidate = blend(source, pageColour, step / 40)
        if (readable(candidate) && !slicePool.includes(candidate)) {
          slicePool.push(candidate)
        }
      }
    }

    // Start on the strongest readable tint of the course's main accent, so
    // the chart still looks like this course, then keep taking the colour
    // farthest from everything already chosen.
    let anchorColour = slicePool[0]
    for (let step = 0; step <= 40; step++) {
      const candidate = blend(computedStyleMap["--secondary"], pageColour, step / 40)
      if (readable(candidate)) {
        anchorColour = candidate
        break
      }
    }
    const sliceColours: string[] = anchorColour ? [anchorColour] : []
    while (sliceColours.length < 12 && slicePool.length > 0) {
      let best = slicePool[0]
      let bestGap = -1
      for (const candidate of slicePool) {
        const gap = Math.min(...sliceColours.map((c) => separation(candidate, c)))
        if (gap > bestGap) {
          bestGap = gap
          best = candidate
        }
      }
      if (bestGap <= 0) {
        break
      }
      sliceColours.push(best)
    }

    const pieSliceColours: Record<string, string> = {}
    sliceColours.forEach((colour, index) => {
      pieSliceColours["pie" + (index + 1)] = colour
    })
    pieSliceColours.pieSectionTextColor = labelColour
    pieSliceColours.pieLegendTextColor = labelColour
    pieSliceColours.pieStrokeColor = pageColour
    pieSliceColours.pieOuterStrokeColor = computedStyleMap["--darkgray"]
    // Mermaid softens its own garish defaults by drawing slices at 0.7
    // opacity, blending them 30% into the page. These are already the
    // scheme's own colours, and the dilution broke the contrast the
    // palette was solved for.
    pieSliceColours.pieOpacity = "1"
'''
        content = content.replace(anchor, palette, 1)

        theme_anchor = '        edgeLabelBackground: computedStyleMap["--highlight"],'
        if theme_anchor not in content:
            print("⚠️ Could not find themeVariables to extend; left unchanged.")
            return
        if "...pieSliceColours," not in content:
            content = content.replace(
                theme_anchor, theme_anchor + "\n        ...pieSliceColours,", 1
            )

        with open(mermaid_ts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ Patched mermaid.inline.ts with a per-scheme pie chart palette")
    except Exception as e:
        print(f"⚠️ Error patching mermaid pie palette: {e}")


def patch_mermaid_pie_title_fit(mermaid_ts_path: Path):
    """
    Stop mermaid clipping the title off a pie chart.

    Mermaid sizes a pie chart's viewBox from the pie and its legend, then
    centres the title on the PIE — which the legend has pushed leftward.
    A title wider than the pie therefore spills past the left edge of the
    viewBox and is silently cut off, while empty space sits on the right.
    It is mermaid's own bug: both WebKit and Chromium show it.

    Nothing in CSS can fix it, because the viewBox is an attribute. So
    after mermaid has drawn, re-fit each pie chart's viewBox to what was
    actually drawn (`getBBox()` covers the title even when it lies outside
    the viewBox). Long titles then widen the chart instead of losing their
    first few words, and short ones lose the wasted margin.

    Only pie charts are touched — they are the ones mermaid mis-measures,
    and re-fitting every diagram would change layouts that are correct.
    Idempotent.
    """
    if not mermaid_ts_path.exists():
        print(f"⚠️ mermaid.inline.ts not found at {mermaid_ts_path}")
        return
    try:
        marker = 'aria-roledescription="pie"'
        with open(mermaid_ts_path, "r", encoding="utf-8") as f:
            content = f.read()

        if marker in content:
            print("ℹ️ Mermaid pie titles already re-fitted (no change).")
            return

        target = "    await mermaid.run({ nodes })"
        if target not in content:
            print("⚠️ Could not find mermaid.run call to patch; left unchanged.")
            return

        replacement = target + "\n" + (
            "\n"
            "    // Mermaid sizes a pie chart from its pie and legend, then\n"
            "    // centres the title on the pie — so a title wider than the pie\n"
            "    // spills outside the viewBox and is silently clipped, with room\n"
            "    // to spare on the right. Re-fit the box to what was drawn.\n"
            "    for (const node of nodes) {\n"
            "      const chart = node.querySelector('svg[aria-roledescription=\"pie\"]')\n"
            "      if (!chart) {\n"
            "        continue\n"
            "      }\n"
            "      const drawn = (chart as SVGGraphicsElement).getBBox()\n"
            "      const pad = 8\n"
            "      chart.setAttribute(\n"
            "        \"viewBox\",\n"
            "        `${drawn.x - pad} ${drawn.y - pad} ${drawn.width + pad * 2} ${drawn.height + pad * 2}`,\n"
            "      )\n"
            "      ;(chart as SVGElement).style.maxWidth = `${drawn.width + pad * 2}px`\n"
            "    }\n"
        )
        content = content.replace(target, replacement, 1)

        with open(mermaid_ts_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ Patched mermaid.inline.ts to re-fit pie chart titles")
    except Exception as e:
        print(f"⚠️ Error patching mermaid pie title fit: {e}")


def append_coverage_styles(base_scss_path: Path):
    """
    Styles for the curriculum coverage map.

    Colours are fixed rather than taken from the theme: the map's whole job
    is a red-to-green reading, and a colour scheme that recoloured it would
    destroy the meaning. The cells print no counts — the count reaches a
    screen reader through each cell's label, and a teacher reads it off the
    hover preview.

    The block always goes at the end of the file, so an earlier one is
    REPLACED rather than skipped: a stylesheet that survives from a previous
    build must still pick up a change made since.
    """
    marker = "/* === curriculum coverage map === */"
    if not base_scss_path.exists():
        return
    text = base_scss_path.read_text(encoding="utf-8")
    if marker in text:
        text = text[:text.index(marker)].rstrip() + "\n"
    text += f"""

{marker}
.coverage-map {{
  display: flex;
  flex-wrap: wrap;
  gap: 0.6rem;
  align-items: flex-start;
  margin: 1.4rem 0;
}}
.coverage-strand {{
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  min-width: 4.6rem;
}}
.coverage-letter {{
  font-weight: 700;
  font-size: 1.1rem;
  text-align: center;
  padding-bottom: 0.1rem;
}}
.coverage-chips {{
  display: flex;
  gap: 0.15rem;
  justify-content: center;
  margin-bottom: 0.35rem;
  flex-wrap: wrap;
}}
.coverage-chip {{
  font-size: 0.62rem;
  line-height: 1;
  padding: 0.18rem 0.24rem;
  border-radius: 0.2rem;
  color: #fff;
  text-decoration: none;
  background: #6b7280;
}}
.coverage-chip-yes {{ background: #15803d; }}
.coverage-chip-no {{ background: #b91c1c; }}
a.coverage-chip:hover {{ filter: brightness(1.15); }}
.coverage-cell {{
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.5rem 0.65rem;
  border-radius: 0.22rem;
  font-size: 0.72rem;
  line-height: 1.1;
  text-decoration: none;
  color: #fff;
  background: #9ca3af;
}}
.coverage-cell:hover {{ filter: brightness(1.12); }}
.coverage-code {{ font-weight: 600; }}
.coverage-0 {{ background: #b91c1c; }}
.coverage-1 {{ background: #ea580c; }}
.coverage-2 {{ background: #eab308; color: #1f2937; }}
.coverage-3 {{ background: #16a34a; }}
.coverage-4 {{ background: #14532d; }}
/* Assessed work is marked by a ring OUTSIDE the cell, with a gap.
   Inset rings were tried twice and failed both times: drawn on top of the
   cell's own colour they read as a hairline, and no single tone works
   against five fixed colours. Moving the ring outside solves both — the
   gap separates it from the cell colour entirely, and `var(--dark)` is
   the theme's own text colour, so it contrasts with the page background
   in every Plantoir colour scheme, light or dark, by construction. */
.coverage-cell[data-assessed="true"],
.coverage-key[data-assessed="true"] {{
  outline: 3px solid var(--dark);
  outline-offset: 2px;
}}
.coverage-rule {{
  border: none;
  border-top: 1px solid var(--lightgray);
  margin: 1.4rem 0 1rem;
}}
.coverage-legend {{
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.4rem;
  margin: 0 0 1.4rem;
  font-size: 0.85rem;
}}
.coverage-legend-row {{
  display: flex;
  align-items: center;
  gap: 0.5rem;
}}
.coverage-key {{
  display: inline-block;
  width: 1.7rem;
  height: 1.35rem;
  border-radius: 0.22rem;
  flex: none;
}}
"""
    base_scss_path.write_text(text, encoding="utf-8")
    print("✅ Appended curriculum coverage map styles to base.scss")


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
                print('ℹ️ Could not locate target \'tagName: "h1"\' to replace in renderPage.tsx (no change).')
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

# --- NEW ADD: Patch Explorer.tsx to wire expand-on-navigate flag -------------
def patch_explorer_tsx_expand_behavior(explorer_tsx_path: Path):
    """
    Ensures Explorer.tsx reads expandOnFolderClick from course_config.json and exposes it via
    data-expand-on-navigate, so explorer.inline.ts can decide whether to auto-open on navigation.
    Idempotent.
    """
    if not explorer_tsx_path.exists():
        print(f"⚠️ Explorer.tsx not found at {explorer_tsx_path}")
        return
    try:
        src = explorer_tsx_path.read_text(encoding="utf-8")
        changed = False

        # Inject const expandOnFolderClick = courseConfig.expandOnFolderClick ?? true
        if "expandOnFolderClick" not in src:
            # Prefer inserting after expandableList definition
            src2, n = re.subn(
                r'(const\s+expandableList\s*=\s*courseConfig\.expandable\s*\?\?\s*\[\]\s*)',
                r'\1\n\nconst expandOnFolderClick = courseConfig.expandOnFolderClick ?? true\n',
                src, count=1
            )
            if n == 0:
                # Fallback: insert after courseConfig import
                src2, n = re.subn(
                    r'(import\s+courseConfig\s+from\s+["\'][^"\']*course_config\.json["\']\s*)',
                    r'\1\nconst expandOnFolderClick = courseConfig.expandOnFolderClick ?? true\n',
                    src, count=1
                )
            if src2 != src:
                src = src2
                changed = True

        # Add data-expand-on-navigate to wrapper div
        if "data-expand-on-navigate" not in src:
            src2, n = re.subn(
                r'(<div\s+class=\{classNames\(displayClass,\s*"explorer"\)\}[^>]*?)>',
                r'\1 data-expand-on-navigate={expandOnFolderClick}>',
                src, flags=re.DOTALL, count=1
            )
            if n > 0:
                src = src2
                changed = True

        if changed:
            result = subprocess.run(
                ["tee", str(explorer_tsx_path)],
                input=src.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch Explorer.tsx:", result.stderr.decode())
            else:
                print("✅ Patched Explorer.tsx to wire expand-on-navigate flag")
        else:
            print("ℹ️ Explorer.tsx already has expand-on-navigate wiring (no change).")

    except Exception as e:
        print(f"⚠️ Error patching Explorer.tsx: {e}")
# -----------------------------------------------------------------------------

# --- NEW ADD: Patch explorer.inline.ts to honor expand-on-navigate -----------
def patch_explorer_inline_expand_on_navigate(inline_path: Path):
    """
    Ensures explorer.inline.ts:
      - adds 'expandOnNavigate: boolean' to ParsedOptions
      - reads dataset.expandOnNavigate into opts
      - gates auto-open on navigate with opts.expandOnNavigate
    Idempotent.
    """
    if not inline_path.exists():
        print(f"⚠️ explorer.inline.ts not found at {inline_path}")
        return
    try:
        src = inline_path.read_text(encoding="utf-8")
        changed = False

        # 1) Interface: add field if missing
        if "expandOnNavigate" not in src:
            src = re.sub(
                r'(interface\s+ParsedOptions\s*\{)([\s\S]*?)(\})',
                lambda m: m.group(1) + m.group(2) + "\n  expandOnNavigate: boolean\n" + m.group(3),
                src, count=1
            )
            changed = True

        # 2) opts object: add property if missing
        if "expandOnNavigate:" not in src:
            src = re.sub(
                r'(const\s+opts\s*:\s*ParsedOptions\s*=\s*\{[\s\S]*?)(\n\s*\})',
                r'\1\n      expandOnNavigate: (explorer.dataset.expandOnNavigate ?? "true") == "true",\2',
                src, count=1
            )
            changed = True

        # 3) Gate auto-open on navigate
        if re.search(r'if\s*\(\s*!isCollapsed\s*\|\|\s*folderIsPrefixOfCurrentSlug\s*\)\s*\{', src):
            src = re.sub(
                r'if\s*\(\s*!isCollapsed\s*\|\|\s*folderIsPrefixOfCurrentSlug\s*\)\s*\{',
                r'if (!isCollapsed || (opts.expandOnNavigate and folderIsPrefixOfCurrentSlug)) {',
                src, count=1
            )
            # Fix accidental 'and' if TS; replace with '&&'
            src = src.replace(' and folderIsPrefixOfCurrentSlug', ' && folderIsPrefixOfCurrentSlug')
            changed = True
        elif "opts.expandOnNavigate" not in src:
            # If condition already changed differently, we won't force it
            pass

        if changed:
            result = subprocess.run(
                ["tee", str(inline_path)],
                input=src.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch explorer.inline.ts:", result.stderr.decode())
            else:
                print("✅ Patched explorer.inline.ts to honor expand-on-navigate")
        else:
            print("ℹ️ explorer.inline.ts already supports expand-on-navigate (no change).")

    except Exception as e:
        print(f"⚠️ Error patching explorer.inline.ts: {e}")
        
def patch_folder_click_behavior(quartz_layout_path: Path, expand_on_name: bool):
    """
    Ensure Component.Explorer(...) uses the desired folderClickBehavior:
      - 'collapse'  → clicking the folder name toggles expansion
      - 'link'      → clicking the folder name navigates
    Patches ALL Explorer option objects it finds, idempotently.
    """
    if not quartz_layout_path.exists():
        print(f"⚠️ quartz.layout.ts not found at {quartz_layout_path}")
        return
    try:
        content = quartz_layout_path.read_text(encoding="utf-8")
        desired = "collapse" if expand_on_name else "link"

        # 1) Replace existing field values
        pattern = re.compile(
            r'(Component\.Explorer\(\s*\{[\s\S]*?folderClickBehavior\s*:\s*")(?:(?:link)|(?:collapse))(")',
            flags=re.DOTALL
        )
        new_content, n1 = pattern.subn(rf'\1{desired}\2', content, count=0)

        # 2) If the field is missing, insert it after the title field
        if n1 == 0:
            def insert_field(m: re.Match) -> str:
                block = m.group(0)
                inserted, n2 = re.subn(
                    r'(title\s*:\s*"[^"]*"\s*,?)',
                    r'\1\n    folderClickBehavior: "' + desired + '",',
                    block,
                    count=1
                )
                return inserted if n2 > 0 else block

            new_content, n2 = re.subn(
                r'Component\.Explorer\(\s*\{\s*[\s\S]*?\}\s*\)',
                insert_field,
                new_content,
                count=0
            )
            changed = (n2 > 0)
        else:
            changed = True

        if changed and new_content != content:
            result = subprocess.run(
                ["tee", str(quartz_layout_path)],
                input=new_content.encode("utf-8"),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            if result.returncode != 0:
                print("❌ Failed to patch folderClickBehavior:", result.stderr.decode())
            else:
                print(f"✅ Set folderClickBehavior → '{desired}' in quartz.layout.ts")
        else:
            print("ℹ️ folderClickBehavior already set as desired (no change).")
    except Exception as e:
        print(f"⚠️ Error patching folderClickBehavior: {e}")

# -----------------------------------------------------------------------------

# --- NEW ADD: Media handling helpers -----------------------------------------
def _ensure_media_symlink(content_root: Path, course_dir: Path):
    """
    Ensure `content/Media` is a relative symlink to the course-level `Media` folder.
    Replaces any existing real folder with a symlink (to avoid duplication).
    """
    link_path = content_root / "Media"
    target_abs = course_dir / "Media"
    rel_target = os.path.relpath(target_abs, start=content_root)

    # If a file/dir already exists at link_path, remove it first (carefully)
    if link_path.exists() or link_path.is_symlink():
        try:
            if link_path.is_symlink() or link_path.is_file():
                link_path.unlink()
            else:
                # It's a real directory; remove it to avoid duplication
                shutil.rmtree(link_path)
            print(f"♻️ Replaced existing 'Media' at {link_path} with a symlink.")
        except Exception as e:
            print(f"⚠️ Could not remove existing 'Media' at {link_path}: {e}")

    try:
        os.symlink(rel_target, link_path)
        print(f"🔗 Created symlink: {link_path} -> {rel_target}")
    except Exception as e:
        print(f"❌ Failed to create Media symlink at {link_path}: {e}")

def _filter_out_media(items: list[str]) -> list[str]:
    """Return a copy of items with 'Media' removed (case-sensitive)."""
    return [x for x in (items or []) if x != "Media"]
# -----------------------------------------------------------------------------

# === NEW: Discovery + preflight config update ================================
_IGNORED_SHARED_FOLDERS = {
    "merged_output", ".merged_output", ".obsidian", "node_modules", "Media"
}
_IGNORED_SHARED_FILES = {
    "course_config.json",
    ".DS_Store",
    "Thumbs.db",
}

def _is_hidden(name: str) -> bool:
    return name.startswith(".")

def _is_section_folder(name: str) -> bool:
    return re.fullmatch(r"section\d+", name or "") is not None

def _safe_unique_append(dst: list[str], items: list[str]) -> int:
    """Append items to dst if not present; return how many were added."""
    added = 0
    for x in items:
        if x not in dst:
            dst.append(x)
            added += 1
    return added

def discover_shared_items(course_dir: Path) -> tuple[list[str], list[str]]:
    """Scan the course root and discover shared folders & files (top-level only)."""
    found_folders = []
    found_files = []
    try:
        for item in course_dir.iterdir():
            name = item.name
            if _is_hidden(name):
                continue
            if item.is_dir():
                if name in _IGNORED_SHARED_FOLDERS or _is_section_folder(name):
                    continue
                found_folders.append(name)
            elif item.is_file():
                if name in _IGNORED_SHARED_FILES or name.startswith("hidden_explorer_components") or name.startswith("expandable_explorer_components"):
                    continue
                found_files.append(name)
    except Exception as e:
        print(f"⚠️ Could not scan course root for discovery: {e}")
    return found_folders, found_files

def discover_section_items(section_dir: Path) -> tuple[list[str], list[str]]:
    """Scan section root and discover per-section folders & files (top-level only)."""
    found_folders = []
    found_files = []
    try:
        for item in section_dir.iterdir():
            name = item.name
            if _is_hidden(name):
                continue
            if item.is_dir():
                if name == "Media":
                    continue
                found_folders.append(name)
            elif item.is_file():
                if name in {".DS_Store", "Thumbs.db", "index.md"}:
                    continue
                found_files.append(name)
    except Exception as e:
        print(f"⚠️ Could not scan section root for discovery: {e}")
    return found_folders, found_files

def _atomic_write_json_with_backup(path: Path, data: dict):
    """Write JSON atomically and back up original"""
    try:
        if path.exists():
            backup = path.with_suffix(".backup.json")
            shutil.copy2(path, backup)
            print(f"🧾 Backed up course_config.json → {backup.name}")
    except Exception as e:
        print(f"⚠️ Could not create backup: {e}")
    tmp = path.with_suffix(".json.tmp")
    try:
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
        os.replace(tmp, path)
        print("✅ Updated course_config.json with discovered items.")
    except Exception as e:
        print(f"❌ Failed to write updated course_config.json: {e}")
        try:
            if tmp.exists():
                tmp.unlink()
        except Exception:
            pass

def preflight_update_course_config(course_dir: Path, section_dir: Path, config_path: Path) -> dict:
    """Discover new items and append them to course_config.json (add-only). Return updated config dict.
    Also: any newly discovered folders are marked not hidden and added to the expandable list.
    """
    try:
        with open(config_path, "r", encoding="utf-8") as f:
            cfg = json.load(f)
    except Exception as e:
        print(f"❌ Could not read course_config.json for preflight: {e}")
        return {}

    # Read current lists (copy so we can mutate safely)
    shared_folders = list(cfg.get("shared_folders", []))
    shared_files = list(cfg.get("shared_files", []))
    per_section_folders = list(cfg.get("per_section_folders", []))
    per_section_files = list(cfg.get("per_section_files", []))
    hidden_list = list(cfg.get("hidden", []))
    expandable_list = list(cfg.get("expandable", []))

    # Discover
    disc_shared_folders, disc_shared_files = discover_shared_items(course_dir)
    disc_sec_folders, disc_sec_files = discover_section_items(section_dir)

    # Determine which folders are *new* (before mutating lists)
    new_shared_folders = [x for x in disc_shared_folders if x not in shared_folders]
    new_sec_folders = [x for x in disc_sec_folders if x not in per_section_folders]

    # Append-only updates for copy lists
    added_sf = _safe_unique_append(shared_folders, disc_shared_folders)
    added_sfi = _safe_unique_append(shared_files, disc_shared_files)
    added_psf = _safe_unique_append(per_section_folders, disc_sec_folders)
    added_psfi = _safe_unique_append(per_section_files, disc_sec_files)

    # For newly discovered folders: ensure NOT hidden + ensure in expandable
    hidden_changed = False
    expandable_changed = False
    for name in new_shared_folders + new_sec_folders:
        if name in hidden_list:
            hidden_list = [h for h in hidden_list if h != name]
            hidden_changed = True
            print(f"👁️‍🗨️ Un-hid newly discovered folder: {name}")
        if name not in expandable_list:
            expandable_list.append(name)
            expandable_changed = True
            print(f"➕ Marked newly discovered folder as expandable: {name}")

    print(f"\n📌 Auto-discovered shared folders: {disc_shared_folders or '—'}")
    print(f"📌 Auto-discovered shared files: {disc_shared_files or '—'}")
    print(f"📌 Auto-discovered per-section folders: {disc_sec_folders or '—'}")
    print(f"📌 Auto-discovered per-section files: {disc_sec_files or '—'}")

    if any([added_sf, added_sfi, added_psf, added_psfi, hidden_changed, expandable_changed]):
        cfg["shared_folders"] = shared_folders
        cfg["shared_files"] = shared_files
        cfg["per_section_folders"] = per_section_folders
        cfg["per_section_files"] = per_section_files
        if hidden_changed:
            cfg["hidden"] = hidden_list
        if expandable_changed:
            cfg["expandable"] = expandable_list
        _atomic_write_json_with_backup(config_path, cfg)
    else:
        print("ℹ️ No new items discovered; course_config.json unchanged.")

    return cfg
# =============================================================================

# === NEW: Fix Netlify static import for course_config.json ====================
def _copy_course_config_into_quartz(course_dir: Path, output_dir: Path):
    """
    Copy <course_dir>/course_config.json into <output_dir>/quartz/course_config.json.
    If missing at the course root, write a minimal default to prevent build errors.
    """
    src = course_dir / "course_config.json"
    quartz_dir = output_dir / "quartz"
    quartz_dir.mkdir(parents=True, exist_ok=True)
    dst = quartz_dir / "course_config.json"

    if src.exists():
        shutil.copy2(src, dst)
        print(f"✅ Copied course_config.json → {dst.relative_to(output_dir)}")
    else:
        fallback = {"courseCode": course_dir.name, "notes": "auto-generated fallback"}
        dst.write_text(json.dumps(fallback, indent=2), encoding="utf-8")
        print(f"ℹ️ No course_config.json found at {src}; wrote a minimal default to {dst}")

def _patch_quartz_imports_to_local_config(quartz_dir: Path):
    """
    Ensure Quartz components import course_config.json from the local quartz/ folder.
    Rewrites any existing import that targets course_config.json to the correct relative path.
    """
    targets = [
        quartz_dir / "components" / "Explorer.tsx",
        quartz_dir / "components" / "scripts" / "explorer.inline.ts",
    ]
    cfg_path = quartz_dir / "course_config.json"

    for fp in targets:
        if not fp.exists():
            continue
        rel_to_cfg = os.path.relpath(cfg_path, start=fp.parent).replace(os.sep, "/")
        try:
            src = fp.read_text(encoding="utf-8")
        except Exception as e:
            print(f"⚠️ Could not read {fp} to patch imports: {e}")
            continue

        # Replace any import ... from "....course_config.json"
        new_src, n = re.subn(
            r'(import\s+courseConfig\s+from\s+["\'])(.*?course_config\.json)(["\'])',
            rf'\1{rel_to_cfg}\3',
            src,
            flags=re.IGNORECASE,
        )

        if n == 0 and "course_config.json" not in src:
            # As a fallback, inject an import at the top
            new_src = f'import courseConfig from "{rel_to_cfg}"\n' + src

        if new_src != src:
            try:
                fp.write_text(new_src, encoding="utf-8")
                print(f"🔧 Patched import in {fp.relative_to(quartz_dir)} → {rel_to_cfg}")
            except Exception as e:
                print(f"⚠️ Could not write patched imports to {fp}: {e}")
        else:
            print(f"✔️  Import in {fp.relative_to(quartz_dir)} already points to {rel_to_cfg}")
# =============================================================================

# === NEW: Netlify link helper (no deploy here) ===============================
def _ensure_netlify_link(output_dir: Path, course_dir: Path):
    """
    Ensure output_dir contains a .netlify folder so 'netlify deploy' can diff.
    Prefer a symlink to an existing root .netlify; if that fails, copy.
    (This script does not deploy; it just makes the eventual deploy faster.)
    """
    dst = output_dir / ".netlify"
    if dst.exists():
        print("✔️  .netlify already present in output (will enable CLI diff).")
        return

    candidates = [course_dir / ".netlify", course_dir.parent / ".netlify"]
    for src in candidates:
        if src.exists() and src.is_dir():
            try:
                rel = os.path.relpath(src, start=output_dir)
                os.symlink(rel, dst)
                print(f"🔗 Linked .netlify → {rel}")
                return
            except Exception as e:
                print(f"ℹ️ Symlink failed ({e}); attempting a copy...")
                try:
                    shutil.copytree(src, dst)
                    print("📦 Copied .netlify into output directory.")
                    return
                except Exception as e2:
                    print(f"⚠️ Could not copy .netlify folder: {e2}")
    print("ℹ️ No .netlify folder found to link/copy (deploy diffs may be slower).")
# =============================================================================

# ---------------------------------------------------------------------------
# Curriculum coverage heat map
# ---------------------------------------------------------------------------
# Ontario asks two different things of a course: every SPECIFIC (minor)
# expectation should be addressed at least once, and every OVERALL (major)
# expectation must be evaluated for marks at least once. Both are easy to
# lose track of in November. This builds a page that answers them at a
# glance, from the site's own links — so it cannot drift from the course.
#
# What counts as coverage is deliberately narrow: a transclusion or link
# inside a `%%curriculum-start%%` / `%%curriculum-end%%` block. That is the
# form the course uses to say "this page addresses this expectation" on
# purpose, as opposed to a passing mention in prose.

# The generated page's title. Used by the generator, by the Key Links
# insertion, and by the Explorer omit list, so the three cannot drift.
COVERAGE_PAGE_TITLE = "Curriculum Coverage"

SPECIFIC_CODE = re.compile(r"^([A-F])(\d+)\.(\d+)$")
OVERALL_FILE = re.compile(r"^([A-F]\d+)\.\s")
CURRICULUM_BLOCK = re.compile(r"%%curriculum-start%%(.*?)%%curriculum-end%%", re.S)
BLOCK_LINK = re.compile(r"!?\[\[([^\]|#]+?)(?:\\?\|[^\]]*)?(?:#[^\]|]*)?\]\]")
TRANSCLUSION = re.compile(r"!\[\[([^\]|#]+?)(?:\\?\|[^\]]*)?(?:#[^\]|]*)?\]\]")


def _quartz_slug(relative: Path) -> str:
    """The URL Quartz gives a page: spaces become hyphens, no extension."""
    parts = list(relative.parts)
    parts[-1] = relative.stem
    return "/".join(part.replace(" ", "-") for part in parts)


def _find_curriculum_folder(content_root: Path):
    """The folder holding expectation pages, whatever the course calls it."""
    for candidate in sorted(content_root.iterdir()):
        if not candidate.is_dir():
            continue
        if "curriculum" not in candidate.name.lower():
            continue
        for page in candidate.glob("*.md"):
            if SPECIFIC_CODE.match(page.stem):
                return candidate
    return None


def _collect_expectations(curriculum_dir: Path):
    """Specific expectations by code, and overall expectations by code."""
    specific, overall = {}, {}
    for page in sorted(curriculum_dir.glob("*.md")):
        match = SPECIFIC_CODE.match(page.stem)
        if match:
            specific[page.stem] = page
            continue
        heading = OVERALL_FILE.match(page.stem)
        if heading:
            overall[heading.group(1)] = page
    return specific, overall


def _is_draft(text: str) -> bool:
    """
    Is this page held back from the built site?

    The same test Quartz's own RemoveDrafts filter applies: `draft: true`,
    or the string "true". Anything else — false, absent, a comment — is
    published.
    """
    if not text.startswith("---\n"):
        return False
    end = text.find("\n---", 4)
    if end < 0:
        return False
    for line in text[4:end].split("\n"):
        match = re.match(r"^draft:\s*(.+?)\s*$", line)
        if match:
            value = match.group(1).strip().strip('"').strip("'").lower()
            return value == "true"
    return False


def _pages_the_course_teaches(content_root: Path) -> set | None:
    """
    The pages a student actually reaches by following the schedule.

    A curriculum connection only counts when the page carrying it is
    taught: linked from a class page, or from a page a class page links
    to. That second hop is not a loophole — it is how courses are built.
    A class page's agenda links to the task; the task links to the
    reference page that carries the expectation, and the expectation was
    genuinely met by doing the task.

    Returns None when the course has no class pages at all, in which case
    the caller counts every published page — a map that hid everything
    would be worse than one that is slightly generous.
    """
    class_pages = {}
    for page in content_root.rglob("*.md"):
        if any(part.lower() in ("all classes", "classes") for part in page.parts):
            class_pages[page.stem] = page
    if not class_pages:
        return None

    by_stem = {page.stem: page for page in content_root.rglob("*.md")}

    def links_from(page: Path) -> set:
        try:
            text = page.read_text(encoding="utf-8")
        except Exception:
            return set()
        outside_fences = re.sub(r"```[\s\S]*?```", "", text)
        return {match.group(1).strip().rstrip("\\").split("/")[-1]
                for match in BLOCK_LINK.finditer(outside_fences)}

    first_hop = set()
    for page in class_pages.values():
        first_hop |= links_from(page)
    second_hop = set()
    for stem in first_hop:
        if stem in by_stem:
            second_hop |= links_from(by_stem[stem])
    return set(class_pages) | first_hop | second_hop


def _coverage_counts(content_root: Path, curriculum_dir: Path, specific: dict):
    """
    How many pages address each expectation, and which of those are assessed.

    Coverage is counted from TRANSCLUSIONS — `![[A1.1]]` — because that is
    the form a curriculum connection takes: the expectation's own wording
    quoted on the page that addresses it. A piped inline mention
    (`[[A1.1|safe practice]]`) is prose referring to an expectation, not a
    claim to have covered it, and does not count.

    The `%%curriculum-start%%` markers that wrap those transclusions in a
    PAYLOAD are removed when the course is installed, so they cannot be
    what the map keys on — but where a teacher's own vault still has them,
    links inside them count too.

    Only PUBLISHED pages count. A page still marked `draft: true` is not on
    the site a student can read, so it cannot have addressed anything yet —
    and a teacher who writes next week's lesson early should not see the map
    turn green before the class has happened. By the time this runs, the
    per-section keys have already been resolved (see `process_frontmatter`),
    so a page held back from one section is uncounted in that section's map
    and counted in the other's, which is the honest answer for each.

    A page counts once per expectation however many times it names it.

    And the page must be one the course actually TEACHES — reachable from
    a class page, directly or through one page a class page links to. A
    concept page written in August and never put in a class has not
    addressed anything yet, and the map should say so.
    """
    covered_by = {code: set() for code in specific}
    assessed_by = {code: set() for code in specific}
    taught = _pages_the_course_teaches(content_root)
    for page in sorted(content_root.rglob("*.md")):
        if taught is not None and page.stem not in taught:
            continue
        if page.parent == curriculum_dir or curriculum_dir in page.parents:
            continue
        if page.name == f"{COVERAGE_PAGE_TITLE}.md":
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except Exception:
            continue
        if _is_draft(text):
            continue
        relative = page.relative_to(content_root)
        # A page in a Tasks folder is assessed work — that is what makes an
        # overall expectation "evaluated" rather than merely "addressed".
        is_assessed = any("task" in part.lower() for part in relative.parts[:-1])

        targets = set()
        for link in TRANSCLUSION.finditer(text):
            targets.add(link.group(1).strip().rstrip("\\").split("/")[-1])
        for block in CURRICULUM_BLOCK.findall(text):
            for link in BLOCK_LINK.finditer(block):
                targets.add(link.group(1).strip().rstrip("\\").split("/")[-1])

        for target in targets:
            if target in covered_by:
                covered_by[target].add(relative.as_posix())
                if is_assessed:
                    assessed_by[target].add(relative.as_posix())
    return covered_by, assessed_by


# How a count reads in words — the legend's labels, and the wording a
# screen reader hears on a cell. Four or more is where the scale stops.
COVERAGE_WORDS = {
    0: "not yet addressed",
    1: "addressed once",
    2: "addressed twice",
    3: "addressed three times",
    4: "addressed four or more times",
}


def _coverage_cell(code: str, page: Path, content_root: Path, count: int, assessed: bool) -> str:
    """One cell: the expectation's code, coloured by how often it is addressed.

    The count is NOT printed. Fifty-odd cells each carrying a digit turns
    the map into a table of numbers, which is the one thing it is not for —
    the reading is the colour, and the exact count is a hover away. It
    still reaches a screen reader through the label, where it costs
    nothing.
    """
    level = min(count, 4)
    href = _quartz_slug(page.relative_to(content_root))
    marker = ' data-assessed="true"' if assessed else ""
    label = f"{code}, {COVERAGE_WORDS[level]}"
    if assessed:
        label += ", included in assessed work"
    return (f'<a class="internal coverage-cell coverage-{level}" href="{href}"{marker} '
            f'aria-label="{label}">'
            f'<span class="coverage-code">{code}</span></a>')


def build_curriculum_coverage(content_root: Path, course_code: str) -> bool:
    """Write the Curriculum Coverage page. Returns True when one was written."""
    curriculum_dir = _find_curriculum_folder(content_root)
    if not curriculum_dir:
        return False
    specific, overall = _collect_expectations(curriculum_dir)
    if not specific:
        return False

    covered_by, assessed_by = _coverage_counts(content_root, curriculum_dir, specific)
    folder = curriculum_dir.name

    strands = {}
    for code in specific:
        strands.setdefault(code[0], []).append(code)
    for letter in strands:
        strands[letter].sort(key=lambda code: (int(code.split(".")[0][1:]), int(code.split(".")[1])))

    columns = []
    for letter in sorted(strands):
        cells = []
        # The overall expectations of this strand, and whether an assessed
        # page addresses each one — through its own specifics or directly.
        chips = []
        for overall_code in sorted({code.split(".")[0] for code in strands[letter]},
                                   key=lambda code: int(code[1:])):
            evaluated = any(assessed_by.get(code) for code in strands[letter]
                            if code.startswith(overall_code + "."))
            page = overall.get(overall_code)
            state = "yes" if evaluated else "no"
            if page:
                href = _quartz_slug(page.relative_to(content_root))
                chips.append(f'<a class="internal coverage-chip coverage-chip-{state}" '
                             f'href="{href}">{overall_code}</a>')
            else:
                chips.append(f'<span class="coverage-chip coverage-chip-{state}">{overall_code}</span>')
        for code in strands[letter]:
            count = len(covered_by[code])
            cells.append(_coverage_cell(code, specific[code], content_root, count,
                                        bool(assessed_by[code])))
        columns.append(
            '<div class="coverage-strand">'
            f'<div class="coverage-letter">{letter}</div>'
            f'<div class="coverage-chips">{"".join(chips)}</div>'
            f'{"".join(cells)}'
            "</div>")

    total = len(specific)
    uncovered = [code for code in specific if not covered_by[code]]
    once = [code for code in specific if len(covered_by[code]) == 1]
    unevaluated = []
    for overall_code in sorted(overall, key=lambda code: (code[0], int(code[1:]))):
        related = [code for code in specific if code.startswith(overall_code + ".")]
        if related and not any(assessed_by[code] for code in related):
            unevaluated.append(overall_code)

    body = f"""---
title: Curriculum Coverage
draft: false
enableToc: true
---
Every expectation in {course_code}, coloured by how many pages address it.
The map is built from this site's own links each time the site is built, so
it cannot drift from the course.

<div class="coverage-map">{"".join(columns)}</div>

<hr class="coverage-rule">

<div class="coverage-legend">
<div class="coverage-legend-row"><span class="coverage-key coverage-0"></span> {COVERAGE_WORDS[0].capitalize()}</div>
<div class="coverage-legend-row"><span class="coverage-key coverage-1"></span> {COVERAGE_WORDS[1].capitalize()}</div>
<div class="coverage-legend-row"><span class="coverage-key coverage-2"></span> {COVERAGE_WORDS[2].capitalize()}</div>
<div class="coverage-legend-row"><span class="coverage-key coverage-3"></span> {COVERAGE_WORDS[3].capitalize()}</div>
<div class="coverage-legend-row"><span class="coverage-key coverage-4"></span> {COVERAGE_WORDS[4].capitalize()}</div>
<div class="coverage-legend-row"><span class="coverage-key coverage-2" data-assessed="true"></span> Included in assessed work — the cell carries a ring</div>
</div>

Hover any cell to preview the expectation. The row of small chips under
each strand letter is that strand's overall expectations: green when
assessed work addresses them, red when nothing marked does.

## Where this course stands

| | |
| --- | --- |
| Specific expectations | {total} |
| Not yet addressed | {len(uncovered)} |
| Addressed by exactly one page | {len(once)} |
| Overall expectations with no assessed work | {len(unevaluated)} |

## What counts

A page addresses an expectation when it **transcludes** it — when the
expectation's own wording appears on the page, under a *Curriculum
connection* heading. That is the deliberate form.

A passing mention in prose does not count. A concept page can discuss an
idea, and even link to the expectation behind it in a sentence, without
claiming to have addressed it — which is why the number here is usually
lower than the backlinks count on the expectation's own page, and why it
means more. If a page genuinely covers an expectation, put it in that
page's *Curriculum connection* rather than leaving it as a mention.

**Only pages this course teaches count.** The page carrying the
connection has to be reachable from a class page — linked from one
directly, or from a page a class page links to. A page written in August
and never put into a class has addressed nothing yet, and a page reached
only from Key Links is a reference, not a lesson.

**Only published pages count.** A page still marked `draft: true` is not on
the site yet, so it cannot have addressed anything — next week's lesson,
written early, leaves the map exactly where it was until the day it is
published.

An expectation counts as **assessed** when one of those pages is in the
Tasks folder. Ontario asks that every overall expectation be evaluated for
marks at least once; the chips under each strand letter answer that, and
the ring on a cell shows which specific expectations carry assessed work.

## Reading it honestly

Red is not failure — in September everything is red, and that is what the
first months of a course look like. What matters is the direction of
travel, and whether anything is still red in May.

A strand of red in the skills strand usually means something different:
those expectations are being met in every investigation without being
cited by code. If that is the case here, it is worth citing a few of them
where they genuinely apply rather than leaving the record silent.
"""
    (content_root / f"{COVERAGE_PAGE_TITLE}.md").write_text(body, encoding="utf-8")
    print(f"🗺️  Curriculum Coverage: {total} expectations, {len(uncovered)} not yet addressed, "
          f"{len(unevaluated)} overall expectation(s) without assessed work.")
    return True


def link_coverage_from_key_links(content_root: Path):
    """
    Put the coverage page in Key Links, directly under the curriculum entry.

    Written into the BUILT copy only: the teacher's own Key Links page is
    theirs, and a line that reappears every build would be infuriating.
    """
    key_links = content_root / "Key Links.md"
    if not key_links.exists():
        return
    text = key_links.read_text(encoding="utf-8")
    if f"[[{COVERAGE_PAGE_TITLE}]]" in text:
        return
    lines = text.split("\n")
    for index, line in enumerate(lines):
        if "Curriculum Expectations]]" in line:
            lines.insert(index + 1, f"- [[{COVERAGE_PAGE_TITLE}]]")
            key_links.write_text("\n".join(lines), encoding="utf-8")
            return


def build_section_site(
    course_code: str,
    section_number: int,
    include_social_media_previews: bool,
    force_npm_install: bool,
    full_rebuild: bool,
    build_only: bool,       # NEW: if True, do a single static build; if False (default), preview (serve) without extra build

    port: int = 8081,
):
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
        print("   Tip: run setup.sh again and include this section number in your timetable sections.")
        return
    if not config_file.exists():
        print(f"❌ course_config.json not found in {course_dir}")
        return

    section_dir = course_dir / section_name

    with open(config_file, "r", encoding="utf-8") as f:
        config = json.load(f)

    # Validate the requested section number against timetable sections
    allowed_sections = get_allowed_section_numbers(config)
    print(f"📋 Timetable sections for this course: {allowed_sections}")
    if not validate_requested_section(allowed_sections, section_number):
        return

    # === Preflight discovery → append into course_config.json =================
    print("\n🔎 Preflight: discovering new shared and per-section items...")
    config = preflight_update_course_config(course_dir, section_dir, config_file) or config
    # ========================================================================

    shared_folders = config.get("shared_folders", [])
    shared_files = config.get("shared_files", [])
    per_section_folders = config.get("per_section_folders", [])
    per_section_files = config.get("per_section_files", [])
    hidden_list = config.get("hidden", [])
    # teacher preference for reading-time
    show_reading_time = bool(config.get("show_reading_time", False))
    # NEW: per-section section-marker preference (used for header and index title)
    show_marker = resolve_show_section_marker(config, section_number)

    # Exclude 'Media' from shared folder processing (we symlink it)
    if "Media" in shared_folders:
        print("ℹ️ Skipping 'Media' in shared folders (handled via symlink).")
    shared_paths = [course_dir / folder for folder in _filter_out_media(shared_folders)]

    print(f"\n📁 Shared folders to include for '{section_name}':")
    for folder in shared_paths:
        print(f" - {folder.name}")

    quartz_src = Path("/opt/quartz")

    # Fresh/full rebuild path
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

        # Remove Graph once on first build / full rebuild
        remove_graph_from_right(output_dir / "quartz.layout.ts")

        install_locales(output_dir)

        # Adjust CreatedModifiedDate priority on first build/full rebuild
        config_path = output_dir / "quartz.config.ts"
        adjust_created_modified_priority(config_path)
        patch_default_date_type(config_path)

        # Patch folder page & defaults on first build/full rebuild
        folder_page_tsx = output_dir / "quartz" / "plugins" / "emitters" / "folderPage.tsx"
        patch_folder_page_title(folder_page_tsx)

        folder_content_tsx = output_dir / "quartz" / "components" / "pages" / "FolderContent.tsx"
        patch_folder_content_defaults(folder_content_tsx)
        
        # Patch Date.tsx date format & listPage.scss meta width
        date_tsx = output_dir / "quartz" / "components" / "Date.tsx"
        patch_date_format(date_tsx)

        list_page_scss = output_dir / "quartz" / "components" / "styles" / "listPage.scss"
        patch_list_page_meta_width(list_page_scss)
        
        # Patch base.scss + append styles
        base_scss = output_dir / "quartz" / "styles" / "base.scss"
        patch_internal_link_highlight(base_scss)
        append_transclusion_styles(base_scss)

        # Patch renderPage.tsx for transcludeTitleSize
        render_page_tsx = output_dir / "quartz" / "components" / "renderPage.tsx"
        patch_render_page_transclude_title(render_page_tsx)

        # Apply selected fonts (if configured)
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

        # NEW: copy/symlink .netlify into output so deploy CLI can diff (later step)
        _ensure_netlify_link(output_dir, course_dir)

    else:
        print(f"♻️ Reusing existing (hidden) output directory: {output_dir}")
        base_scss = output_dir / "quartz" / "styles" / "base.scss"

    # ALWAYS: Fix Netlify static import target
    _copy_course_config_into_quartz(course_dir, output_dir)
    _patch_quartz_imports_to_local_config(output_dir / "quartz")

    # Apply teacher preference to ContentMeta on each build
    content_meta_tsx = output_dir / "quartz" / "components" / "ContentMeta.tsx"
    patch_content_meta_options(content_meta_tsx, show_reading_time)

    # Mermaid diagram fixes, applied on EVERY build rather than only on a
    # full rebuild, so a course folder created before these existed heals
    # itself the next time it is previewed. Both are idempotent and cheap.
    append_mermaid_styles(base_scss)
    append_sidebar_sharing_styles(base_scss)
    mermaid_ts = output_dir / "quartz" / "components" / "scripts" / "mermaid.inline.ts"
    theme_ts = output_dir / "quartz" / "util" / "theme.ts"
    head_tsx = output_dir / "quartz" / "components" / "Head.tsx"
    patch_google_font_href(theme_ts, head_tsx)
    append_coverage_styles(output_dir / "quartz" / "styles" / "base.scss")
    latex_ts = output_dir / "quartz" / "plugins" / "transformers" / "latex.ts"
    patch_katex_mhchem(latex_ts)
    patch_mermaid_font_wait(mermaid_ts)
    patch_mermaid_pie_title_fit(mermaid_ts)
    patch_mermaid_pie_colours(mermaid_ts)

    # Patch Explorer expansion behaviour (idempotent)
    explorer_tsx = output_dir / "quartz" / "components" / "Explorer.tsx"
    explorer_inline = output_dir / "quartz" / "components" / "scripts" / "explorer.inline.ts"
    patch_explorer_tsx_expand_behavior(explorer_tsx)
    patch_explorer_inline_expand_on_navigate(explorer_inline)

    install_patched_backlinks(output_dir)

    content_root = output_dir / "content"
    if content_root.exists():
        print(f"\n🧹 Clearing previous content folder at: {content_root}")
        shutil.rmtree(content_root)
    content_root.mkdir(exist_ok=True)
    print(f"📂 Created fresh content folder: {content_root}")

    # Ensure Media symlink is present inside content/
    _ensure_media_symlink(content_root, course_dir)

    section_index = section_dir / "index.md"
    if section_index.exists():
        dest = content_root / "index.md"
        shutil.copy2(section_index, dest)
        process_frontmatter(dest, section_number)

        # The landing title comes from the current settings, not from
        # whatever was baked in at scaffold time.
        set_landing_title(dest, config, section_number, show_marker)

        # rewrite section-path wikilinks in the section index
        print("🔍 Checking for wikilinks to rewrite in content/index.md...")
        rewrite_section_wikilinks(dest)
        print(f"  🏠 Copied section index.md to content/index.md")
    else:
        print("⚠️ Section index.md not found — site may not render correctly.")

    # Copy shared folders
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

    # Copy shared files
    print(f"\n📥 Copying shared files into {content_root}...")
    for file_name in shared_files:
        src = course_dir / file_name
        dest = content_root / file_name
        if src.exists():
            shutil.copy2(src, dest)
            process_frontmatter(dest, section_number)
            print(f"  📄 Copied shared file: {file_name}")

    # Copy per-section folders
    print(f"\n📥 Copying per-section folders...")
    for folder in per_section_folders:
        src = section_dir / folder
        dest = content_root / folder
        if src.exists():
            shutil.copytree(src, dest, dirs_exist_ok=True)
            for root, dirs, files in os.walk(dest):
                for file in files:
                    fp = Path(root) / file
                    process_frontmatter(fp, section_number)
                    if fp.suffix.lower() == ".md":
                        rewrite_section_wikilinks(fp)
            print(f"  📁 Copied per-section folder: {folder}")

    # Copy per-section files
    print(f"\n📥 Copying per-section files...")
    for file_name in per_section_files:
        src = section_dir / file_name
        dest = content_root / file_name
        if src.exists():
            shutil.copy2(src, dest)
            process_frontmatter(dest, section_number)
            print("🔍 Checking for wikilinks to rewrite in per-section loose files...")
            rewrite_section_wikilinks(dest)
            print(f"  📄 Copied per-section file: {file_name}")


    # === NEW: Post-pass — sync Curriculum 'created' timestamps =================
    print("\n📆 Post-processing: syncing 'created' for Curriculum pages (if needed)...")
    latest = _find_latest_created_in_section(content_root)
    if latest is None:
        print("ℹ️ No parseable 'created' dates found in this section — leaving Curriculum files unchanged.")
    else:
        updated, skipped, folders = _sync_curriculum_created(content_root, latest)
        stamp = _format_created_timestamp_from_dt(latest)
        print(f"📆 Synced Curriculum 'created' → {stamp} for {updated} file(s) across {folders} folder(s) (skipped {skipped}).")
    # ===========================================================================

    # === Curriculum coverage heat map =========================================
    # Built from the assembled content, so it reflects exactly what this
    # section will publish. Default is ON: a course with curriculum pages
    # gets the map unless the teacher turned it off in the wizard.
    if bool(config.get("include_curriculum_coverage", True)):
        if build_curriculum_coverage(content_root, course_code):
            link_coverage_from_key_links(content_root)
    else:
        print("ℹ️ Curriculum Coverage page is switched off for this course.")
    # ==========================================================================

    # Copy course config into output root (back-compat)
    shutil.copy2(config_file, output_dir / "course_config.json")
    print("✅ Copied course_config.json to output directory (root copy)")

    # Update Quartz layout & footer
    quartz_layout_ts = output_dir / "quartz.layout.ts"
    quartz_footer_tsx = output_dir / "quartz/components/Footer.tsx"
    ensure_quartz_layout_anchor(quartz_layout_ts)  # HARDENING: make sure anchor exists

    # ensure 'Media' is always hidden in Explorer omit set
    if "Media" not in hidden_list:
        hidden_list.append("Media")

    # The Curriculum Coverage page is reached from Key Links, deliberately.
    # It is a teacher's instrument rather than a place students navigate to,
    # and it sits at the content root, so without this it would appear in
    # the sidebar above the folders — the most prominent position on the
    # site, for the page that needs it least.
    if COVERAGE_PAGE_TITLE not in hidden_list:
        hidden_list.append(COVERAGE_PAGE_TITLE)

    update_quartz_layout(quartz_layout_ts, hidden_list)  # ensure omit is present and updated
    
    # honor expandOnFolderClick from course_config.json
    expand_on_name = bool(config.get("expandOnFolderClick", False))
    patch_folder_click_behavior(quartz_layout_ts, expand_on_name)
    
    footer_html = config.get("footer_html", "")
    inject_custom_footer_components(quartz_layout_ts, quartz_footer_tsx, footer_html)

    # Update page title (now with per-section emoji and optional section marker)
    config_path = output_dir / "quartz.config.ts"
    page_emoji = resolve_section_emoji(config, section_number)
    header_label = resolve_header_label(config, course_code)
    update_page_title(config_path, header_label, section_number, page_emoji, show_marker)
    patch_default_date_type(config_path)

    # --- ADD: PATCH LOCALE in quartz.config.ts based on course_config.json ----
    locale_code = (config.get("locale") or "en-US").strip() or "en-US"
    patch_quartz_locale(config_path, locale_code)
    # --------------------------------------------------------------------------

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

    # ---- Social sharing card -------------------------------------------
    # Drawn fresh on every build, so changes to the course name, scheme,
    # fonts, emoji, or marker setting always reach the card. Written over
    # Quartz's default og-image, which the site's head already links —
    # and never allowed to fail a build: a site without a custom card
    # still has the stock one.
    try:
        import social_card
        card_path = output_dir / "quartz" / "static" / "og-image.png"
        social_card.generate_card(
            course_config=config,
            section_number=section_number,
            output_path=card_path,
        )
        print(f"🖼️  Social sharing card drawn for {section_key}.")
    except Exception as e:
        print(f"⚠️ Could not draw the social sharing card: {e}")

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

    # ===========================
    # Build or Preview (server?)
    # ===========================
    env = os.environ.copy()
    env.setdefault("TZ", "UTC")
    env.setdefault("SOURCE_DATE_EPOCH", "1704067200")  # 2024-01-01T00:00:00Z

    if build_only:
        # Static build ONLY (single build)
        print("\n🏗️  Building static site with Quartz → public/")
        subprocess.run(["npx", "quartz", "build", "--concurrency", "1"], cwd=output_dir, env=env, check=True)

        public_dir = output_dir / "public"
        if not public_dir.exists():
            print("❌ Quartz build did not emit a 'public' directory — cannot deploy.")
            return
        print("✅ Static build complete.")
    else:
        # Preview mode (default): do NOT pre-build. Build+serve once.
        # Quartz's dev server opens TWO ports: the site, and a live-reload
        # websocket (default 3001). Both must be per-preview or two serves
        # collide on the websocket even with distinct site ports.
        ws_port = port + 1000
        kill_existing_quartz(port)
        kill_existing_quartz(ws_port)
        print(f"\n🚀 Launching Quartz preview on http://localhost:{port}\n")
        subprocess.run(["npx", "quartz", "build", "--concurrency", "1", "--serve", "--port", str(port), "--wsPort", str(ws_port)], cwd=output_dir, env=env, check=True)

def main():
    parser = argparse.ArgumentParser(description="Build Quartz site for a course section (preview by default; use --build-only for a static build without preview).")
    parser.add_argument("--course", required=True, help="Course code (e.g., ICS3U)")
    parser.add_argument("--section", required=True, type=int, help="Timetable section number (e.g., 1, 3, 4)")
    parser.add_argument("--include-social-media-previews", action="store_true", help="Enable social media preview images via CustomOgImages emitter")
    parser.add_argument("--force-npm-install", action="store_true", help="Force npm install even if dependencies are present")
    parser.add_argument("--full-rebuild", action="store_true", help="Clear the full output folder and re-copy Quartz scaffold")
    # NEW: default is preview; this flag switches to a plain static build
    parser.add_argument("--build-only", action="store_true", help="Build the static site only (no preview server)")
    parser.add_argument("--port", type=int, default=8081, help="Port for the preview server (default 8081)")
    parser.add_argument("--host-os", choices=["windows","mac","linux","unknown"], default="unknown", help="Host OS passed by preview.sh/preview.ps1")
    args = parser.parse_args()
    _HOST_OS = getattr(args, 'host_os', 'unknown')

    build_section_site(
        course_code=args.course,
        section_number=args.section,
        include_social_media_previews=args.include_social_media_previews,
        force_npm_install=args.force_npm_install,
        full_rebuild=args.full_rebuild,
        build_only=args.build_only,
        port=args.port,
    )

if __name__ == "__main__":
    main()
