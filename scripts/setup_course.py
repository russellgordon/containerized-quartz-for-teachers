import os
import json
import subprocess
from pathlib import Path
import re

DEFAULT_SHARED_FOLDERS = [
    "All Classes",
    "Concepts",
    "Discussions",
    "Examples",
    "Exercises",
    "Learning Goals",
    "Media",
    "Ontario Curriculum",
    "College Board Curriculum",
    "Portfolios",
    "Recaps",
    "Setup",
    "Style",
    "Tasks",
    "Tutorials"
]

def setup_course():
    print("📚 Welcome to the Course Setup Script!\n")

    course_code = input("Enter the course code (e.g. ICS3U): ").strip()
    course_name = input("Enter the formal course name (e.g. Introduction to Computer Science): ").strip()
    num_sections = int(input("How many sections are you teaching of this course? "))

    print("\n📁 Default shared folders:")
    for folder in DEFAULT_SHARED_FOLDERS:
        print(f" - {folder}")

    print("\nEnter the names of folders to be shared across all sections.")
    print("Use commas to separate folder names, or just press Enter to accept the default list above.")
    shared_input = input("Shared folders: ").strip()

    shared_folders = (
        [name.strip() for name in shared_input.split(",")] if shared_input else DEFAULT_SHARED_FOLDERS
    )

    # Create course directory
    base_path = Path("/teaching/courses")
    course_path = base_path / course_code
    course_path.mkdir(exist_ok=True)

    # Save shared folders config
    shared_config_path = course_path / ".shared_folders.json"
    with open(shared_config_path, "w", encoding="utf-8") as f:
        json.dump({"shared_folders": shared_folders}, f, indent=2)

    # Create shared folders with index.md
    for folder in shared_folders:
        folder_path = course_path / folder
        folder_path.mkdir(parents=True, exist_ok=True)
        index_md_path = folder_path / "index.md"
        if not index_md_path.exists():
            with open(index_md_path, "w", encoding="utf-8") as f:
                f.write(f"---\n")
                f.write(f"title: {folder}\n")
                f.write(f"---\n")
                f.write(f"This is the **{folder}** folder. Add Markdown files to this folder to build out your site.\n")

    # Create section folders and section-specific index.md
    for i in range(1, num_sections + 1):
        section_name = f"section{i}"
        section_path = course_path / section_name
        section_path.mkdir(exist_ok=True)

        index_md_path = section_path / "index.md"
        with open(index_md_path, "w", encoding="utf-8") as f:
            f.write(f"---\ntitle: Grade 11 {course_name}, Section {i}\n---\n")

    # Modify quartz.layout.ts to replace Component.Explorer()
    quartz_layout_path = Path("/opt/quartz/quartz.layout.ts")
    if quartz_layout_path.exists():
        with open(quartz_layout_path, "r", encoding="utf-8") as f:
            content = f.read()
            
            # DEBUG
            # print("EXISTING quartz.layout.ts IS:")
            # print(content)

        explorer_code = '''
Component.Explorer({
    title: "Navigate this site",
    folderClickBehavior: "link", 
    filterFn: (node) => {
        console.log("Explorer node:", node)
        // set containing names of everything you want to filter out
        const omit = new Set([""])

        // can also use node.slug or by anything on node.data
        // note that node.data is only present for files that exist on disk
        // (e.g. implicit folder nodes that have no associated index.md)
        if (node.isFolder) {
            if (omit.has(node.fileSegmentHint)) {
                return false
            } else {
                return true
            }
        } else {
            if (omit.has(node.data.title)) {
                return false
            } else {
                return true
            }
        }
    } 
})'''.strip()

        # Regex replacement for all Component.Explorer() calls
        modified_content = re.sub(r'Component\.Explorer\(\)', explorer_code, content)
        
        # DEBUG
        # print("MODIFIED quartz.layout.ts IS:")
        # print(modified_content)

        try:
            result = subprocess.run(
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
