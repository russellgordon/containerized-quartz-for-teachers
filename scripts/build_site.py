import os
import shutil
import argparse
import frontmatter
import subprocess
import json
import re
from pathlib import Path

def update_page_title(config_path: Path, course_code: str, section_number: int):
    if not config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {config_path}")
        return

    with open(config_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    updated = False
    new_title = f'📚 {course_code.upper()} S{section_number}'

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

def update_quartz_layout(quartz_layout_path: Path, hidden_components: list):
    if not quartz_layout_path.exists():
        print(f"⚠️ quartz.layout.ts not found at {quartz_layout_path}")
        return

    normalized_hidden = [
        item[:-3] if item.endswith(".md") else item
        for item in hidden_components
    ]

    with open(quartz_layout_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        if "const omit = new Set(" in line:
            formatted_names = ', '.join(f'"{name}"' for name in normalized_hidden)
            new_lines.append(f'const omit = new Set([{formatted_names}])\n')
        else:
            new_lines.append(line)

    with open(quartz_layout_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    print("✅ Updated quartz.layout.ts with Explorer omit list.")

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

        escaped_html = footer_html.replace("\\", "\\\\").replace('"', '\\"')

        replacement = f"""<footer class={{displayClass ?? ""}}>
                <div dangerouslySetInnerHTML={{{{ __html: "{escaped_html}" }}}} />
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

# ---------------------------
# New: Colour scheme support
# ---------------------------

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
    """
    Return a TS snippet:
        colors: {
          lightMode: { ... },
          darkMode: { ... },
        },
    """
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
    """
    Replace the entire 'colors: { ... }' block with new_colors_block using brace counting.
    Preserves a trailing comma if present.
    """
    m = re.search(r'colors\s*:\s*\{', content)
    if not m:
        return content  # colors block not found

    start = m.start()  # index of 'c' in 'colors'
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
        return content  # Unbalanced braces

    brace_close = i - 1
    end = brace_close + 1
    if end < n and content[end] == ',':
        end += 1

    return content[:start] + new_colors_block + content[end:]

def apply_color_scheme_to_quartz_config(quartz_config_path: Path, scheme_colors: dict):
    """Replace (or insert) the theme.colors block with the chosen scheme; write via tee."""
    if not quartz_config_path.exists():
        print(f"⚠️ quartz.config.ts not found at {quartz_config_path}")
        return

    with open(quartz_config_path, "r", encoding="utf-8") as f:
        content = f.read()

    new_colors_block = format_colors_block(scheme_colors)

    updated = _replace_colors_block_ts(content, new_colors_block)
    if updated == content:
        # No colors block found — insert after typography config inside theme
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

def build_section_site(course_code: str, section_number: int, include_social_media_previews: bool, force_npm_install: bool, full_rebuild: bool):
    base_dir = Path("/teaching/courses")
    course_dir = base_dir / course_code
    section_name = f"section{section_number}"

    # --- CHANGED: hide output by using a dot-folder at the vault root ---
    visible_output_root = course_dir / "merged_output"
    hidden_output_root = course_dir / ".merged_output"

    # One-time migration if the old visible folder exists
    if visible_output_root.exists() and not hidden_output_root.exists():
        try:
            print(f"📦 Migrating existing output '{visible_output_root.name}' → '{hidden_output_root.name}'...")
            visible_output_root.rename(hidden_output_root)
            print("✅ Migration complete.")
        except Exception as e:
            print(f"⚠️ Migration failed (will continue using hidden target): {e}")

    # Use the hidden root for all future builds
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
    else:
        print(f"♻️ Reusing existing (hidden) output directory: {output_dir}")

    content_root = output_dir / "content"
    if content_root.exists():
        print(f"\n🧹 Clearing previous content folder at: {content_root}")
        shutil.rmtree(content_root)
    content_root.mkdir(exist_ok=True)
    print(f"📂 Created fresh content folder: {content_root}")

    section_index = section_dir / "index.md"
    if section_index.exists():
        shutil.copy2(section_index, content_root / "index.md")
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
                shutil.copy2(Path(root) / file, dest_path / file)

    print(f"\n📥 Copying shared files into {content_root}...")
    for file_name in shared_files:
        src = course_dir / file_name
        dest = content_root / file_name
        if src.exists():
            shutil.copy2(src, dest)
            print(f"  📄 Copied shared file: {file_name}")

    print(f"\n📥 Copying per-section folders...")
    for folder in per_section_folders:
        src = section_dir / folder
        dest = content_root / folder
        if src.exists():
            shutil.copytree(src, dest, dirs_exist_ok=True)
            print(f"  📁 Copied per-section folder: {folder}")

    print(f"\n📥 Copying per-section files...")
    for file_name in per_section_files:
        src = section_dir / file_name
        dest = content_root / file_name
        if src.exists():
            shutil.copy2(src, dest)
            print(f"  📄 Copied per-section file: {file_name}")

    shutil.copy2(config_file, output_dir / "course_config.json")
    print("✅ Copied course_config.json to output directory")

    quartz_layout_ts = output_dir / "quartz.layout.ts"
    quartz_footer_tsx = output_dir / "quartz/components/Footer.tsx"
    update_quartz_layout(quartz_layout_ts, hidden_list)
    footer_html = config.get("footer_html", "")
    inject_custom_footer_components(quartz_layout_ts, quartz_footer_tsx, footer_html)

    config_path = output_dir / "quartz.config.ts"
    update_page_title(config_path, course_code, section_number)

    # --- NEW: apply per-section colour scheme, if configured ---
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

    if config_path.exists():
        toggle_custom_og_images(str(config_path), include_social_media_previews)
    else:
        print("Warning: quartz.config.ts not found to toggle CustomOgImages")

    kill_existing_quartz()

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
