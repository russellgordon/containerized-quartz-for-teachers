import os
import shutil
import argparse
import frontmatter
import subprocess
import json
import re
from pathlib import Path

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

def prompt_for_hidden_components(content_dir: Path):
    print("\n🕵️ Select files and folders to hide from the sidebar (Explorer):")
    hidden = []
    for item in sorted(content_dir.iterdir()):
        if item.name in {"index.md", ".gitkeep"} or item.name.startswith("."):
            continue
        response = input(f"Hide '{item.name}' from Explorer? [y/N]: ").strip().lower()
        if response == "y":
            hidden.append(item.name)
    return hidden

def prompt_for_expandable_components(content_dir: Path):
    print("\n📂 Select files and folders that should be *expandable* in the Explorer sidebar:")
    expandable = []
    for item in sorted(content_dir.iterdir()):
        if item.name in {"index.md", ".gitkeep"} or item.name.startswith("."):
            continue
        response = input(f"Make '{item.name}' expandable? [y/N]: ").strip().lower()
        if response == "y":
            expandable.append(item.name)
    return expandable

def update_quartz_layout(quartz_layout_path: Path, hidden_components: list):
    if not quartz_layout_path.exists():
        print(f"⚠️ quartz.layout.ts not found at {quartz_layout_path}")
        return

    with open(quartz_layout_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        if "const omit = new Set(" in line:
            formatted_names = ', '.join(f'"{name}"' for name in hidden_components)
            new_lines.append(f'const omit = new Set([{formatted_names}])\n')
        else:
            new_lines.append(line)

    with open(quartz_layout_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    print("✅ Updated quartz.layout.ts with Explorer omit list.")

def build_section_site(course_code: str, section_number: int, reset_hidden: bool, include_social_media_previews: bool, reset_expandable: bool):
    base_dir = Path("/teaching/courses")
    course_dir = base_dir / course_code
    section_name = f"section{section_number}"
    section_dir = course_dir / section_name
    output_dir = course_dir / f"{section_name}_output"
    hidden_path = course_dir / "hidden_explorer_components.json"
    expandable_path = course_dir / "expandable_explorer_components.json"

    if not course_dir.exists():
        print(f"❌ Course folder '{course_code}' not found in {base_dir}")
        return
    if not section_dir.exists():
        print(f"❌ Section folder '{section_name}' not found in {course_dir}")
        return

    config_file = course_dir / ".shared_folders.json"
    if not config_file.exists():
        print(f"❌ Shared folder config file not found: {config_file}")
        return
    with open(config_file, "r", encoding="utf-8") as f:
        config = json.load(f)
        shared_folders = config.get("shared_folders", [])
    shared_paths = [course_dir / folder for folder in shared_folders]

    print(f"\n📁 Shared folders to include for '{section_name}':")
    for folder in shared_paths:
        print(f" - {folder.name}")

    if output_dir.exists():
        print(f"\n🧹 Clearing previous build directory at: {output_dir}")
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True)
    print(f"📂 Created fresh output directory: {output_dir}")

    quartz_src = Path("/opt/quartz")
    print(f"📦 Copying Quartz scaffold from {quartz_src}...")
    for item in quartz_src.iterdir():
        dest = output_dir / item.name
        if item.is_dir():
            shutil.copytree(item, dest, symlinks=False)
            print(f"  📁 Copied directory: {item.name}")
        else:
            shutil.copy2(item, dest)
            print(f"  📄 Copied file: {item.name}")

    all_sources = shared_paths
    content_root = output_dir / "content"
    content_root.mkdir(exist_ok=True)
    print(f"\n📥 Copying shared content into {content_root}...")

    for src_folder in all_sources:
        print(f"🔍 Processing content from: {src_folder}")
        for root, dirs, files in os.walk(src_folder):
            rel_path = Path(root).relative_to(course_dir)
            dest_path = content_root / rel_path
            dest_path.mkdir(parents=True, exist_ok=True)

            if root == str(src_folder):
                folder_title = rel_path.name
                index_md = dest_path / "index.md"
                if not index_md.exists():
                    with open(index_md, "w", encoding="utf-8") as f:
                        f.write(f"---\ntitle: {folder_title}\n---\n")
                        f.write(f"This is the **{folder_title}** folder. Add Markdown files to this folder to build out your site.\n")
                    print(f"  📝 Created index.md in {dest_path}")

            for filename in files:
                src_file = Path(root) / filename
                dest_file = dest_path / filename
                if filename.endswith(".md"):
                    try:
                        post = frontmatter.load(src_file)
                        section_key = f"createdForSection{section_number}"
                        if section_key in post.metadata:
                            post.metadata["created"] = post.metadata.pop(section_key)
                        with open(dest_file, "w", encoding="utf-8") as f:
                            f.write(frontmatter.dumps(post))
                        print(f"    ✅ Copied markdown: {rel_path / filename}")
                    except Exception as e:
                        print(f"⚠️ Skipping malformed Markdown file: {src_file} ({e})")
                else:
                    shutil.copy2(src_file, dest_file)
                    print(f"    📄 Copied asset: {rel_path / filename}")

    print(f"\n📥 Copying section-specific content from {section_dir} into {content_root}...")
    for item in section_dir.iterdir():
        if item.name == "quartz.layout.ts":
            shutil.copy2(item, output_dir / item.name)
            print(f"  🎨 Copied quartz.layout.ts to {output_dir}")
        elif item.is_file() and item.suffix == ".md":
            try:
                post = frontmatter.load(item)
                section_key = f"createdForSection{section_number}"
                if section_key in post.metadata:
                    post.metadata["created"] = post.metadata.pop(section_key)
                dest = content_root / item.name
                with open(dest, "w", encoding="utf-8") as f:
                    f.write(frontmatter.dumps(post))
                print(f"  📄 Copied section Markdown file to content/: {item.name}")
            except Exception as e:
                print(f"⚠️ Skipping malformed Markdown file: {item} ({e})")
        elif item.is_file():
            shutil.copy2(item, content_root / item.name)
            print(f"  📦 Copied section asset: {item.name}")

    print(f"\n✅ Site for {section_name} built at: {output_dir}")

    # Load or prompt hidden items
    if reset_hidden or not hidden_path.exists():
        hidden_list = prompt_for_hidden_components(content_root)
        with open(hidden_path, "w", encoding="utf-8") as f:
            json.dump(hidden_list, f, indent=2)
        print(f"✅ Saved hidden Explorer components to: {hidden_path}")
    else:
        with open(hidden_path, "r", encoding="utf-8") as f:
            hidden_list = json.load(f)
        print(f"📄 Loaded hidden Explorer components from: {hidden_path}")

    # Load or prompt expandable items
    if reset_expandable or not expandable_path.exists():
        expandable_list = prompt_for_expandable_components(content_root)
        with open(expandable_path, "w", encoding="utf-8") as f:
            json.dump(expandable_list, f, indent=2)
        print(f"✅ Saved expandable Explorer components to: {expandable_path}")
    else:
        with open(expandable_path, "r", encoding="utf-8") as f:
            expandable_list = json.load(f)
        print(f"📄 Loaded expandable Explorer components from: {expandable_path}")

    quartz_layout_ts = output_dir / "quartz.layout.ts"
    update_quartz_layout(quartz_layout_ts, hidden_list)

    config_path = os.path.join(output_dir, "quartz.config.ts")
    if os.path.exists(config_path):
        toggle_custom_og_images(config_path, enable=include_social_media_previews)
    else:
        print("Warning: quartz.config.ts not found to toggle CustomOgImages")

    kill_existing_quartz()

    print("\n📦 Installing dependencies...")
    subprocess.run(["npm", "install", "--no-audit", "--silent"], cwd=output_dir, check=True)

    print("\n🚀 Launching Quartz preview on http://localhost:8081\n")
    subprocess.run(["npx", "quartz", "build", "--serve", "--port", "8081"], cwd=output_dir)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build Quartz site for a course section.")
    parser.add_argument("--course", required=True, help="Course code (e.g., ICS3U)")
    parser.add_argument("--section", required=True, type=int, help="Section number (e.g., 1)")
    parser.add_argument("--reset-hidden", action="store_true", help="Prompt again for hidden Explorer items")
    parser.add_argument("--reset-expandable", action="store_true", help="Prompt again for expandable Explorer items")
    parser.add_argument("--include-social-media-previews", action="store_true", help="Enable social media preview images via CustomOgImages emitter")
    args = parser.parse_args()

    build_section_site(
        course_code=args.course,
        section_number=args.section,
        reset_hidden=args.reset_hidden,
        include_social_media_previews=args.include_social_media_previews,
        reset_expandable=args.reset_expandable
    )
