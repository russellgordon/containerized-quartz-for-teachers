"""Lint an example-content payload before shipping it.

Usage:  python3 .claude/skills/example-content/lint_payload.py ADA1O

Checks every rule the installer and the site build depend on. Exit code 0
means clean; 1 means problems were printed.
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]


def lint(course_code: str) -> int:
    root = REPO_ROOT / "support" / "example_content" / course_code
    if not root.is_dir():
        print(f"no payload at {root}")
        return 1

    manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    pages = sorted(root.rglob("*.md"))
    page_names = {page.stem for page in pages} | {"index"}
    curriculum_folder = manifest.get("curriculum_folder")

    problems = []
    link_pattern = re.compile(r"!?\[\[([^\]|#]+?)(?:\\?\|[^\]]*)?(?:#[^\]|]*)?\]\]")
    class_sentinel = re.compile(r"created: __CREATED_CLASS_(\d+)__")

    class_ordinals = []
    linked_from_classes = set()

    for page in pages:
        text = page.read_text(encoding="utf-8")
        rel = str(page.relative_to(root))
        is_curriculum = curriculum_folder and rel.startswith(f"shared/{curriculum_folder}/")

        # Sentinels: every created: line carries one (curriculum pages
        # normally have no created: at all).
        if "created:" in text and "created: __CREATED" not in text and not is_curriculum:
            problems.append(f"{rel}: created: without a sentinel")

        class_match = class_sentinel.search(text)
        if class_match:
            class_ordinals.append(int(class_match.group(1)))
            for link in link_pattern.finditer(text):
                linked_from_classes.add(link.group(1).strip().split("/")[-1])
            # A class page is a schedule, not a destination. Expectations
            # belong on the pages the agenda links to — the investigation,
            # the exercise set, the task — because those are what a
            # student is actually doing when the expectation is met.
            if "%%curriculum-start%%" in text:
                problems.append(
                    f"{rel}: class pages carry no curriculum connection — "
                    f"move those codes to the pages its agenda links to"
                )

        if text.count("%%curriculum-start%%") != text.count("%%curriculum-end%%"):
            problems.append(f"{rel}: unbalanced curriculum markers")

        in_fence = False
        for line in text.split("\n"):
            stripped = line.strip()
            if stripped.startswith("```") or stripped.startswith("````"):
                in_fence = not in_fence
                continue
            if in_fence or "`" in line:
                continue
            for match in link_pattern.finditer(line):
                target = match.group(1).strip().rstrip("\\")
                if target.split("/")[-1] not in page_names:
                    problems.append(f"{rel}: unknown link [[{target}]]")
            if stripped.startswith("|") and re.search(r"\[\[[^\]]*[^\\]\|[^\]]*\]\]", line):
                problems.append(f"{rel}: unescaped pipe in table: {stripped[:60]}")

    # Folder index pages must be titled after their folder — a literal
    # "title: index" shows "index" as the page name on the built site.
    for page in pages:
        if page.stem != "index" or page.parent == root:
            continue
        folder_name = page.parent.name
        if folder_name in ("shared", "per_section"):
            continue
        text = page.read_text(encoding="utf-8")
        title_match = re.search(r"^title: (.+)$", text, re.MULTILINE)
        if not title_match or title_match.group(1).strip() != folder_name:
            found = title_match.group(1).strip() if title_match else "(none)"
            problems.append(
                f"{page.relative_to(root)}: index title should be "
                f"'{folder_name}', found '{found}'"
            )

    # Expectation pages hold ONLY the verbatim expectation: frontmatter,
    # the ^text-anchored wording, nothing after — no callouts or notes.
    if curriculum_folder:
        for page in (root / "shared" / curriculum_folder).glob("*.md"):
            if page.stem in ("index", "About These Expectations", "Mathematical Process Expectations"):
                continue
            text = page.read_text(encoding="utf-8")
            if "^text" in text and text.split("^text", 1)[1].strip():
                problems.append(f"shared/{curriculum_folder}/{page.name}: content after the ^text anchor — expectation pages carry the verbatim wording only")

    # Exercises answer callouts carry no repeated "(click to expand)"
    # hint — the Exercises index opens with the how-to message instead.
    exercises_dir = root / "shared" / "Exercises"
    if exercises_dir.is_dir():
        for page in exercises_dir.glob("*.md"):
            if page.name != "index.md" and "click to expand" in page.read_text(encoding="utf-8"):
                problems.append(f"shared/Exercises/{page.name}: '(click to expand)' hint — the index teaches the pattern instead")
        index_text = (exercises_dir / "index.md").read_text(encoding="utf-8") if (exercises_dir / "index.md").exists() else ""
        if "How to use these pages" not in index_text:
            problems.append("shared/Exercises/index.md: missing the 'How to use these pages' opening message")

    # Key Links must offer the Curriculum Expectations link (inside
    # curriculum markers, so declining the curriculum removes it cleanly).
    key_links = root / "per_section" / "Key Links.md"
    if curriculum_folder and key_links.exists():
        key_links_text = key_links.read_text(encoding="utf-8")
        expected_link = f"[[{curriculum_folder}/index|Curriculum Expectations]]"
        if expected_link not in key_links_text:
            problems.append(f"per_section/Key Links.md: missing {expected_link}")
        elif "%%curriculum-start%%" not in key_links_text.split(expected_link)[0]:
            problems.append("per_section/Key Links.md: Curriculum Expectations link is not inside curriculum markers")

    # The section landing page's "Most Recent Class" must transclude the
    # newest PUBLISHED class page — the point of that heading.
    landing = root / "per_section" / "index.md"
    if landing.exists() and class_ordinals:
        newest_published = None
        for page in (root / "per_section").rglob("*.md"):
            text = page.read_text(encoding="utf-8")
            match = class_sentinel.search(text)
            if match and "draft: true" not in text:
                ordinal = int(match.group(1))
                if newest_published is None or ordinal > newest_published[0]:
                    newest_published = (ordinal, page.stem)
        if newest_published and f"![[{newest_published[1]}]]" not in landing.read_text(encoding="utf-8"):
            problems.append(
                f"per_section/index.md: Most Recent Class should transclude "
                f"the newest published class, ![[{newest_published[1]}]]"
            )

    # Class ordinals: consecutive from 1, no gaps or repeats.
    class_ordinals.sort()
    if class_ordinals != list(range(1, len(class_ordinals) + 1)):
        problems.append(f"class ordinals are not 1..N without gaps: {class_ordinals}")

    # Manifest completeness: every named folder/file exists in the payload
    # and every payload folder is named — the manifest is the WHOLE
    # structure, so nothing may be missing and nothing may ship empty.
    for folder in manifest.get("shared_folders", []):
        folder_path = root / "shared" / folder
        if not folder_path.is_dir() or not list(folder_path.glob("*.md")):
            problems.append(f"manifest folder empty or missing: shared/{folder}")
    for name in manifest.get("shared_files", []):
        if not (root / "shared" / name).exists():
            problems.append(f"manifest shared file missing: {name}")
    for folder in manifest.get("per_section_folders", []):
        folder_path = root / "per_section" / folder
        if not folder_path.is_dir() or not list(folder_path.glob("*.md")):
            problems.append(f"manifest folder empty or missing: per_section/{folder}")

    # Teaching-order dates only work when content pages are linked from
    # class pages. Warn (not fail) for shared pages never linked by any
    # class — they will carry the install-time date.
    unlinked = []
    for page in pages:
        rel = str(page.relative_to(root))
        if not rel.startswith("shared/") or page.stem == "index":
            continue
        if curriculum_folder and rel.startswith(f"shared/{curriculum_folder}/"):
            continue
        if page.stem not in linked_from_classes:
            unlinked.append(rel)

    print(f"{len(pages)} pages checked; {len(class_ordinals)} class pages")
    for problem in problems:
        print(f"PROBLEM  {problem}")
    for rel in unlinked:
        print(f"note     no class links {rel} (it will carry the install-time date)")
    print("clean" if not problems else f"{len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(lint(sys.argv[1]))
