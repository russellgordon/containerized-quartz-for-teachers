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

# An Ontario credit is 110 hours of scheduled time. A semestered day school
# runs 75-minute periods, so the arc is about 86 periods plus a three-hour
# final evaluation — the tolerance either side is one week of classes,
# because timetables really do differ.
CREDIT_HOURS = 110
PERIOD_MINUTES = 75
EXAM_HOURS = 3
MINIMUM_HOURS = 104
MAXIMUM_HOURS = 116
MINIMUM_REVIEW_CLASSES = 3


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
    page_links = {}
    class_pages = set()

    for page in pages:
        text = page.read_text(encoding="utf-8")
        rel = str(page.relative_to(root))
        is_curriculum = curriculum_folder and rel.startswith(f"shared/{curriculum_folder}/")

        # Sentinels: every created: line carries one (curriculum pages
        # normally have no created: at all).
        if "created:" in text and "created: __CREATED" not in text and not is_curriculum:
            problems.append(f"{rel}: created: without a sentinel")

        # A payload cannot know how many sections the teacher will choose,
        # so per-section keys are the INSTALLER's job — it splits a shared
        # page's created/draft into createdSectionN/draftSectionN for each
        # section. Writing them here would fix the course at one section.
        head = text.split("\n---", 1)[0] if text.startswith("---\n") else ""
        if re.search(r"^(created|draft)Section\d+:", head, re.M):
            problems.append(f"{rel}: per-section keys are written by the installer, not the payload")

        # A checklist on the site cannot be ticked — nothing is saved and
        # clicking does nothing. A page that says otherwise lies about the
        # software to the student reading it.
        lowered = text.lower()
        for phrase in ("click to check", "clicking checks", "check them off",
                       "tick them off", "tick these off", "checkboxes are clickable",
                       "clickable checklist", "click each box", "tick each box"):
            at = lowered.find(phrase)
            while at >= 0:
                # Ticking a printed copy is honest and worth saying, so the
                # sentence around the phrase decides.
                sentence = lowered[max(0, at - 120):at + 160]
                if not any(word in sentence for word in
                           ("paper", "notebook", "printed", "print it", "your own copy")):
                    problems.append(f"{rel}: says a checklist can be ticked — it is read-only")
                    break
                at = lowered.find(phrase, at + 1)

        # Mermaid prints each pie percentage at its slice's mid-angle with
        # no collision avoidance, and rounds to whole numbers.
        for block in re.findall(r"```mermaid\n(.*?)```", text, re.S):
            if not block.lstrip().startswith("pie"):
                continue
            values = [float(match.group(1)) for match
                      in re.finditer(r'^\s*"[^"]*"\s*:\s*([0-9.]+)\s*$', block, re.M)]
            total = sum(values)
            if total <= 0:
                continue
            shares = [value / total * 100 for value in values]
            vanishing = [share for share in shares if share < 0.5]
            crowded = [share for share in shares if share < 3]
            if vanishing:
                problems.append(f"{rel}: a pie slice rounds to 0% — combine it into a larger one")
            elif len(crowded) > 1:
                problems.append(f"{rel}: two pie slices under 3% will print their labels on top of each other")

        # The whole link graph, so reachability can be checked below.
        outside_fences = re.sub(r"```[\s\S]*?```", "", text)
        page_links[page.stem] = {
            link.group(1).strip().rstrip("\\").split("/")[-1]
            for link in link_pattern.finditer(outside_fences)
        }

        class_match = class_sentinel.search(text)
        if class_match:
            class_ordinals.append(int(class_match.group(1)))
            class_pages.add(page.stem)
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

    # ...and the site tour must be its LAST entry, so a teacher evaluating
    # the course meets it without hunting for it.
    if key_links.exists():
        bullets = []
        for line in key_links.read_text(encoding="utf-8").splitlines():
            if line.startswith("- "):
                bullets.append(line.strip())
        tour = "- [[What This Site Can Do]]"
        if tour not in bullets:
            problems.append(f"per_section/Key Links.md: missing {tour}")
        elif bullets[-1] != tour:
            problems.append("per_section/Key Links.md: What This Site Can Do must be the LAST entry")

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

    # Outside Key Links, no page stands on its own: every page must be
    # reachable from a class page directly, or through one page a class
    # page links to. Key Links is the sidebar's index of last resort, so
    # a page reachable only through it is still an orphan.
    first_hop = set()
    for stem in class_pages:
        first_hop |= page_links.get(stem, set())
    second_hop = set()
    for stem in first_hop:
        second_hop |= page_links.get(stem, set())
    reachable = class_pages | first_hop | second_hop
    exempt = {"index", "Key Links", "Private Notes", "Scratch Page"}
    for page in pages:
        rel = str(page.relative_to(root))
        if page.stem in exempt or page.stem in reachable:
            continue
        if curriculum_folder and rel.startswith(f"shared/{curriculum_folder}/"):
            continue
        problems.append(
            f"{rel}: nothing reaches this page — link it from a class page, "
            f"or from a page a class page links to (Key Links does not count)"
        )

    # ---- Curriculum coverage, and the hours the arc actually accounts for.
    #
    # The built site draws a Curriculum Coverage heat map from exactly these
    # numbers, so a payload can be checked here without building anything.
    # A red cell on a shipped example course teaches the wrong lesson: it
    # says a course may leave an expectation untaught.
    if curriculum_folder:
        curriculum_dir = root / "shared" / curriculum_folder
        specific = set()
        overall = set()
        for page in curriculum_dir.glob("*.md"):
            if re.fullmatch(r"[A-F]\d+\.\d+", page.stem):
                specific.add(page.stem)
            elif re.match(r"^[A-F]\d+\.\s", page.stem):
                overall.add(page.stem.split(".")[0])

        addressed_by = {code: set() for code in specific}
        assessed_by = {code: set() for code in specific}
        for page in pages:
            rel = str(page.relative_to(root))
            if curriculum_folder and rel.startswith(f"shared/{curriculum_folder}/"):
                continue
            text = page.read_text(encoding="utf-8")
            if "draft: true" in text:
                continue          # not on the site, so it addresses nothing
            is_assessed = "/Tasks/" in rel.replace("\\", "/")
            # The same pattern build_site.py counts with, block anchor and
            # all: SNC1W transcludes as `![[A1.2#^text]]`, which the site
            # counts and an anchor-blind regex here would silently miss.
            for match in re.finditer(r"!\[\[([^\]|#]+?)(?:\\?\|[^\]]*)?(?:#[^\]|]*)?\]\]", text):
                code = match.group(1).strip().split("/")[-1]
                if code in addressed_by:
                    addressed_by[code].add(rel)
                    if is_assessed:
                        assessed_by[code].add(rel)

        uncovered = sorted(code for code in specific if not addressed_by[code])
        thin = sorted(code for code in specific if len(addressed_by[code]) == 1)
        if uncovered:
            problems.append(
                f"{len(uncovered)} expectation(s) addressed by NO published page — "
                f"every specific expectation must be transcluded at least once: "
                f"{' '.join(uncovered)}"
            )
        for overall_code in sorted(overall):
            related = [code for code in specific if code.startswith(overall_code + ".")]
            if related and not any(assessed_by[code] for code in related):
                problems.append(
                    f"overall expectation {overall_code} is never reached by assessed work — "
                    f"a page in Tasks must transclude one of its specific expectations"
                )

    # ---- Hours: an Ontario credit is 110 hours of scheduled time.
    #
    # One class page is one period. The exam is not a class page, so its
    # hours are added separately; several review periods belong inside the
    # arc, before it.
    if class_ordinals:
        hours = len(class_ordinals) * PERIOD_MINUTES / 60 + EXAM_HOURS
        if not MINIMUM_HOURS <= hours <= MAXIMUM_HOURS:
            problems.append(
                f"the arc accounts for {hours:.1f} hours "
                f"({len(class_ordinals)} periods x {PERIOD_MINUTES} min + {EXAM_HOURS} h exam) — "
                f"an Ontario credit is {CREDIT_HOURS} hours, so this arc needs about "
                f"{round((CREDIT_HOURS - EXAM_HOURS) * 60 / PERIOD_MINUTES)} class pages"
            )
        review = [page for page in pages if "\n  - review\n" in page.read_text(encoding="utf-8")]
        if len(review) < MINIMUM_REVIEW_CLASSES:
            problems.append(
                f"{len(review)} review class(es) — a course ends with at least "
                f"{MINIMUM_REVIEW_CLASSES}, tagged `review`, before the final evaluation"
            )
        final = [page for page in pages
                 if "\n  - final-evaluation\n" in page.read_text(encoding="utf-8")]
        if not final:
            problems.append(
                "no final evaluation — the last thing in the course is a page in Tasks "
                "tagged `final-evaluation`, carrying the exam or culminating task"
            )

    print(f"{len(pages)} pages checked; {len(class_ordinals)} class pages")
    if curriculum_folder and specific:
        covered = len(specific) - len(uncovered)
        print(f"coverage: {covered}/{len(specific)} expectations addressed; "
              f"{len(thin)} addressed exactly once")
        if thin:
            print(f"note     addressed only once (aim for two or more): {' '.join(thin)}")
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
