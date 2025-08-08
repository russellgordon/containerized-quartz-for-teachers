import os
import json
import subprocess
from pathlib import Path
import re

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

def prompt_with_default(prompt_text, default_value):
    response = input(f"{prompt_text} [Default: {default_value}]: ").strip()
    return response if response else default_value

def prompt_select_multiple(prompt_text, options, default_selection=None):
    BLUE = "\033[94m"
    RESET = "\033[0m"

    # Highlight "HIDE" or "EXPANDABLE" in blue if present in prompt_text
    prompt_text = prompt_text.replace("HIDE", f"{BLUE}HIDE{RESET}")
    prompt_text = prompt_text.replace("EXPANDABLE", f"{BLUE}EXPANDABLE{RESET}")

    print(f"\n{prompt_text}")
    for idx, option in enumerate(options):
        if default_selection and option in default_selection:
            print(f"{BLUE}{idx + 1}. {option}{RESET}")
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

    shared_folders = prompt_type_list("Enter folder names to be shared across all sections – defaults are:", saved_config.get("shared_folders", DEFAULT_SHARED_FOLDERS))
    shared_files = prompt_type_list("Enter Markdown file names to be shared across all sections – defaults are:", saved_config.get("shared_files", DEFAULT_SHARED_FILES), add_md_extension=True)
    per_section_folders = prompt_type_list("Enter folder names to be duplicated per section – defaults are:", saved_config.get("per_section_folders", DEFAULT_PER_SECTION_FOLDERS))
    per_section_files = prompt_type_list("Enter Markdown file names to be duplicated per section – defaults are:", saved_config.get("per_section_files", DEFAULT_PER_SECTION_FILES), add_md_extension=True)

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

    config = {
        "course_code": course_code,
        "course_name": course_name,
        "num_sections": num_sections,
        "shared_folders": shared_folders,
        "shared_files": shared_files,
        "per_section_folders": per_section_folders,
        "per_section_files": per_section_files,
        "hidden": hidden_items,
        "expandable": expandable_items
    }

    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2)

    for folder in shared_folders:
        folder_path = course_path / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        index_md_path = folder_path / "index.md"
        if not index_md_path.exists():
            with open(index_md_path, "w", encoding="utf-8") as f:
                f.write(f"---\ntitle: {folder}\n---\n")
                f.write(f"This is the **{folder}** folder. Add Markdown files to this folder to build out your site.\n")

    for file in shared_files:
        file_path = course_path / file
        if not file_path.exists():
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(f"---\ntitle: {file.replace('.md', '')}\n---\n")
                f.write(f"This is the shared file **{file}**.\n")

    for i in range(1, num_sections + 1):
        section_name = f"section{i}"
        section_path = course_path / section_name
        section_path.mkdir(exist_ok=True)

        index_md_path = section_path / "index.md"
        if not index_md_path.exists():
            with open(index_md_path, "w", encoding="utf-8") as f:
                f.write(f"---\ntitle: Grade 11 {course_name}, Section {i}\n---\n")

        for folder in per_section_folders:
            folder_path = section_path / folder
            folder_path.mkdir(parents=True, exist_ok=True)
            index_md = folder_path / "index.md"
            if not index_md.exists():
                with open(index_md, "w", encoding="utf-8") as f:
                    f.write(f"---\ntitle: {folder}\n---\n")
                    f.write(f"This is the **{folder}** folder. Add Markdown files to this folder to build out your site.\n")

        for file in per_section_files:
            file_path = section_path / file
            if not file_path.exists():
                with open(file_path, "w", encoding="utf-8") as f:
                    f.write(f"---\ntitle: {file.replace('.md', '')}\n---\n")
                    f.write(f"This is the per-section file **{file}**.\n")

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
