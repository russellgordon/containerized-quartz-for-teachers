---
name: example-content
description: Build or revise a per-course-code example-content payload (support/example_content/<CODE>) — the ready-made course a teacher can pre-populate. Use whenever adding example content for an Ontario course code.
---

# Building example content for a course code

A payload is a complete, working course a teacher keeps: real pages, a real
semester, real curriculum. **ADA1O is the reference implementation** — when
in doubt, open it and copy its shape. `support/example_course/EXC2O` is the
older standalone example course; match its depth and warmth, not its
mechanics.

The payload owns the course's ENTIRE structure (the wizard asks no
structure questions when pre-populating), so nothing may ship empty and no
folder should exist without purpose. Machinery lives in
`scripts/setup_course.py` (`install_example_content` and friends) and needs
NO changes for a new course code — a new payload is pure content.

## Phase 1 — Research the curriculum (verbatim or not at all)

Launch a research agent (WebSearch/WebFetch) to capture, from the
Ministry's own published document, for the exact course code:
strand titles; every OVERALL expectation (code + verbatim text); every
SPECIFIC expectation (code + verbatim text, including the italic
parenthetical examples); teacher prompts verbatim; the "By the end of this
course, students will:" stems; and the citation (document title, year,
copyright holder, the dcp.edu.gov.on.ca course URL, and the source PDF URL
with page range). Old curricula live at
`edu.gov.on.ca/eng/curriculum/secondary/*.pdf`; newer ones on
`dcp.edu.gov.on.ca`. Two-column PDFs detach teacher prompts from their
expectations — cross-check against a layout-preserving extraction. Anything
unverifiable gets flagged and is NOT published as Ministry wording.

Save the result as a structured markdown file (see the format the ADA1O
generator parses) — it is both the generator's input and the audit trail.

## Phase 2 — Design the course

Choose folders that fit the SUBJECT, not the template. ADA1O's line-up for
drama: Concepts, Conventions, Warm-Ups, Discussions, Portfolios, Tutorials,
Setup, Style, Tasks, Curriculum; shared files Learning Goals.md and Help
Sessions.md; per-section All Classes + Key Links.md + Private Notes.md +
Scratch Page.md. A science course would swap Conventions/Warm-Ups for
Investigations/Exercises (see EXC2O). If a folder has no reason to exist in
this subject, it does not exist.

Plan a **semestered arc, September to at latest January**: four units,
roughly 26 classes (7/7/6/6 works), each unit building to a performance or
summative task, the last unit culminating. Name class pages
`Unit N, Day M.md`. Write the arc down before authoring — it is the
skeleton everything hangs from, and class-page links are the schedule.

**Lean constructivist in the lesson plans.** Students meet an idea by
working a problem, exploration, or activity BEFORE the idea gets its
formal name and definition; consolidation compares student methods rather
than presenting one; practice follows sense-making, never replaces it.
Concretely: a class page's agenda should read "exploration → discuss →
name it → practise", not "lesson → examples → worksheet"; tasks are open
enough to have multiple entry points; concept pages can assume the reader
has already met the idea in class and now wants it stated cleanly.

**For mathematics courses in particular, stress active learning as
researched by Jo Boaler, Carmel Schettino, and Peter Liljedahl.** That
means, concretely, woven through the pages rather than name-dropped:
thinking tasks worked in VISIBLY RANDOM GROUPS at VERTICAL WHITEBOARDS
before any formal notes (Liljedahl's Building Thinking Classrooms);
consolidation "from the bottom" comparing student methods, then brief
"notes to my future forgetful self" written by students, and
check-your-understanding questions in place of graded homework; mistakes
framed as growth and no speed worship — depth, visuals, and multiple
methods over memorised procedure (Boaler); discussion-based, relational
problem solving where student conjectures drive the room (Schettino).
Credit the researchers sparingly in teacher-facing footnotes, the way the
payloads cite other sources — the pedagogy should be IN the class pages'
shape, not lectured about.

**For English courses in particular**, when texts come up — novels, short
stories, poetry, essays, anything read or discussed — preference Canadian
writers, and be sure to include Indigenous writers and Indigenous ways of
knowing (as substantive presence in the reading and discussion pages, not
a token mention). Verify any author or title named actually exists and is
correctly attributed before publishing it.

**For Computer Science courses in particular**, use Python for example
code and for teaching programming concepts. (This matches the
mathematics payloads' coding pages, which are also Python.)

## Phase 3 — Manifest

`manifest.json`: `shared_folders`, `shared_files`, `per_section_folders`,
`per_section_files`, `hidden`, `expandable`, `curriculum_folder`. This is
the whole structure — mirror ADA1O's hidden/expandable choices (Curriculum
and the utility files hidden; content folders expandable; All Classes
visible but not expandable). Layout: `shared/` → course root;
`per_section/` → every sectionN/.

## Phase 4 — Generate the Curriculum folder by script

Adapt an existing generator (re-derive from the pages themselves): one
page per overall expectation (`A1. <Title>.md`, `transcludeTitleSize:
h3`) and per specific expectation (`A1.1.md`, `h4`), each with tags
(`A1`, `strand-a`) and the verbatim text ending in a ` ^text` block
anchor — **and NOTHING after the anchor**. No callouts, notes, teacher
prompts, supports pointers, or addendum labels beneath individual
expectations, ever: repeated per-page callouts make the course pages
noisy, and the linter rejects them. Anything contextual — where teacher
supports live, an addendum's provenance, a strand's special status —
belongs ONCE on `About These Expectations.md` (citation, both URLs, ©
line, why codes matter). Plus `index.md` (strand mermaid graph + every
expectation transcluded in document order). Curriculum pages have NO
`created:` line.

## Phase 5 — Author the content

**The style contract** (gold standard: `ADA1O/shared/Conventions/Tableau.md`):

- Frontmatter: `title:` matching filename, `draft: false`,
  `created: __CREATED__` (literal), `tags:`, `enableToc: true` only with
  4+ H2s. No H1 in the body. Canadian spelling. Spaced em dashes — like
  this. ~80-column wrap. Direct, warm, concrete, second person to
  students. No filler: every page something a real teacher would keep.
- Each page demonstrates ONE Obsidian feature that genuinely serves it
  (table, callout, folded callout, small mermaid, checklist, footnote);
  vary across pages. Features the subject has no use for (equations in
  drama, code in English) appear ONLY on `Style/What This Site Can Do.md`,
  demonstrated but honestly framed as "not used in this course".
- Exercises folders: answer callouts are titled plainly (`> [!success]-
  Answer 3`) with NO "(click to expand)" hint — repeated per answer it is
  noise. Instead the Exercises `index.md` opens, right after the
  frontmatter, with the standard how-to message (copy it from an existing
  payload's Exercises index): a `[!tip] How to use these pages` callout
  (answer first on paper; reading worked answers only feels like
  learning) followed by a folded `[!success]- Try it: click this line`
  demo. The linter enforces the no-hint rule. One-off folded self-checks
  on concept pages may keep a brief "(click to expand)" affordance hint.
- Curriculum references: end-of-page block
  `%%curriculum-start%%` / `## Curriculum connection` / blank-line-separated
  `![[A2.2]]` transclusions of SPECIFIC expectations / `%%curriculum-end%%`.
  Inline prose links to curriculum pages must be piped
  (`[[C3.1|safe practice]]`) so they degrade to readable words when the
  teacher declines curriculum pages. Never let a curriculum reference sit
  outside these two forms.
- Piped wikilinks inside table cells escape the pipe: `[[Page\|words]]`.
- **Mathematics that must render** (KaTeX is strict about markdown's
  seams): display math is a SINGLE physical line, or an unindented
  multi-line block OUTSIDE callouts — a 4-space-indented continuation
  line becomes a markdown code block and splits the `$$` pair, and any
  multi-line `$$` inside a `>` callout breaks the same way. Multi-step
  derivations go on one line as
  `$$\begin{aligned} f'(x) &= … \\ &= … \end{aligned}$$`. Currency
  NEVER uses `\$` inside a math span (markdown eats the escape and the
  span shatters): a pure amount is escaped prose (`\$14`), an amount
  inside an expression is `\textdollar 14`. The container render gate
  (Phase 7) catches violations.
- Link only to pages that will exist. Maintain the full page inventory
  BEFORE fanning out authoring agents; hand every agent the complete
  sanctioned link list.

**Required pages beyond the subject folders**: the Setup set (How <X> Class
Works, the safety/trust agreement in subject-appropriate form, What to
Wear/Bring, How Marks Work, Getting Help), the Style set (How This Site Is
Organised, What This Site Can Do, Writing About <Subject>), Help
Sessions.md, Learning Goals.md (transcluding 2–3 overall expectations
inside a curriculum block, with plain-words fallback text outside it), a
Tutorials `Using This Site.md`, and per-section: `index.md` (the landing
page — `title: Section __SECTION_NUMBER__`, "# Most Recent Class"
transcluding the NEWEST PUBLISHED class page of the payload's semester
(not Day 1, and not the draft finale) + a `%%` teacher comment about
advancing it + `![[Help Sessions]]` + `![[Key Links]]`) and a populated
`Key Links.md`, whose FIRST entry is
`[[Curriculum/index|Curriculum Expectations]]` wrapped in curriculum
markers — this link is a must in every payload (the linter enforces it),
and it is easy to lose when adapting a previous payload's pages, because
stripping curriculum blocks wholesale deletes it. Every folder's
`index.md` MUST have `title: <Folder Name>` — a literal `title: index`
shows "index" as the page name on the built site.

**Older curricula without printed codes** (pre-2020 documents like the
2005 mathematics one): assign positional codes in the style teachers
commonly use (strands lettered in document order, overalls and specifics
numbered within), and disclose that ONCE, in a warning callout on
`About These Expectations` — never as a repeated per-page callout, which
is noise. Ministry addenda get a short labelled note on the pages they
added. Sample problems embedded in expectation text are part of the
verbatim wording and stay.

**Class pages** (18–30 lines): frontmatter adds `transcludeTitleSize: h2`,
`enableToc: false`, `excludeBacklinks: true`, `tags: [unit-N]`; body is a
numbered Agenda of links + a "Things to do before our next class" checkbox
list (journal prompts often); one curriculum transclusion per unit, on the
day its task launches; exactly ONE page in the whole payload is
`draft: true` — the final class page, carrying a `%%` comment explaining
drafts. No absolute dates anywhere in prose.

**Fan-out**: hand-write the gold-standard exemplar and the landing/setup
pages yourself; batch the rest to 2–3 parallel agents, each prompt carrying
the style contract, the reading list (Tableau.md, the curriculum file, an
EXC2O register sample), the sanctioned link list, and per-page briefs with
assigned curriculum codes. Review their output — spot-read for voice, run
the linter.

## Phase 6 — Dates (they carry meaning)

- Class pages: `created: __CREATED_CLASS_K__`, K = chronological position
  (1 = first class). The installer turns these into every-other-weekday
  07:00 dates from September 8 of the current school year, so All Classes
  sorts newest-first.
- Every other page keeps `created: __CREATED__`. The installer then gives
  each shared page the date of the FIRST class that links to it — category
  listings sort in teaching order. So: **when a class first uses a page,
  link it from that class page.** A content page no class links to keeps
  the install-time date (fine for pure reference pages; the linter lists
  them so you can check the list is intentional).
- Per-section pages may also use `__SECTION_NUMBER__`.

## Phase 7 — Lint, verify, ship

1. `python3 .claude/skills/example-content/lint_payload.py <CODE>` — must
   end "clean"; read the "no class links" notes and confirm each is a
   deliberate reference page.
2. Installer E2E without Docker: import `scripts/setup_course.py` via
   importlib, call `install_example_content` into a temp dir for both
   curriculum states; assert no curriculum folder/links remain when
   declined, dates stagger, re-runs write 0 files.
3. App suite (`ExampleContentTests` counts bundled pages):
   `cd mac-app && xcodebuild -project Plantoir.xcodeproj -scheme Plantoir
   -configuration Debug test -only-testing:QuartzTeachersTests`.
4. `script -q /dev/null ./verify.sh` — the toolchain gate.
5. Container E2E: verify.sh leaves a dev-test container running; drive the
   baked wizard (`printf 'n\n<CODE>\n'` + many newlines, through
   `script -q /dev/null docker exec -it <container> python3
   /opt/scripts/setup_course.py --host-os mac`), then
   `./preview.sh <CODE> 1 --build-only --image quartz-teacher:dev-test`,
   then inspect the built HTML: landing transclusions render, the draft
   finale is NOT published, `%%` comments invisible, All Classes and one
   category listing sort correctly (check the `page-listing` region of the
   HTML, not the whole page — index prose also mentions page names), and
   `grep -rl katex-error <public dir>` finds NOTHING — a katex-error span
   means an equation shattered at a markdown seam (see the math rules in
   Phase 5).
6. Clean up: `docker rm -f <container>`, `rm -rf courses/<CODE>`.
7. No GUI-IMPROVEMENTS entry for a content-only payload (the spec tracks
   behaviour); commit with a message naming the course code.

## Converting an existing complete course into a payload

The SNC1W payload was made by CONVERTING the EXC2O example course rather
than authoring from scratch — worth repeating when a finished course
already holds the content. The conversion is mechanical, and the linter
is the contract; what EXC2O needed:

- Real `created:` dates → sentinels: class pages get
  `__CREATED_CLASS_K__` by sorting their dates (K = chronological
  position); everything else gets `__CREATED__`. Pages with NO created
  line get `created: __CREATED__` ADDED — that upgrade lets the
  installer date them to the class that first links them, so category
  listings sort in teaching order.
- End-of-page "## Curriculum" listings wrapped in
  `%%curriculum-start%%`/`%%curriculum-end%%`; the Key Links first
  entry replaced with the canonical marked
  `[[Curriculum/index|Curriculum Expectations]]`; standalone prose
  pointers at the curriculum wrapped too, so a curriculum-free install
  leaves no dangling sentence.
- The finale class becomes the `draft: true` example (with the standard
  `%%` comment), and the landing transclusion steps back to the newest
  PUBLISHED class.
- Section landing title becomes `title: Section __SECTION_NUMBER__`.
- Content the course holds beyond its scheduled classes (EXC2O has a
  space/electricity library its 26 agendas never link) is fine — the
  linter's "no class links" notes list it; confirm the list reads as
  deliberate extras, not forgotten links.

## Known traps

- Wizard structure prompts are SKIPPED when pre-populating — a payload
  mistake ships silently; that is what the linter's manifest checks catch.
- The `%%curriculum-start%%` markers must be balanced per file, on their
  own lines.
- Escaped pipes: agents reliably forget them in tables; the linter catches.
- The colour-scheme picker needs a TTY — always `script -q /dev/null` when
  driving the wizard non-interactively.
- Shell cwd resets between tool calls; `preview.sh` must run from the repo
  root (or a working folder).
- The Docker image bakes `support/` — payload edits change the recipe hash
  and force a rebuild on next use; that is expected, not a bug.
