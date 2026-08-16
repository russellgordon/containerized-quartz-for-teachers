"""Build the starting skeletons that every Ontario course code gets.

Thirty-seven course codes have real example content. Every other code — around
1,900 of them — used to start as empty folders with a one-line stub in
each. This generator writes a SKELETON for each subject family instead: the
same shape the example courses use (a semester of class pages, a Key Links
sidebar, the site tour, a curriculum folder) with placeholder content a
teacher edits rather than invents.

The skeletons are generated rather than hand-written because the shapes
repeat: a chemistry course and a biology course want the same folders with
different words in them, and fifty families times about thirty-nine pages —
1,944 files as it stands — is not something to maintain by hand. Run this
after editing the tables below:

    python3 .claude/skills/example-content/generate_skeletons.py

It writes support/skeletons/<family>/ and support/skeletons/families.json.
"""

import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "support" / "skeletons"

# Named as the example-content payloads name it, so every course built by
# this software puts its expectations in the same place.
CURRICULUM_FOLDER = "Curriculum"

UTILITY_FILES = ["Key Links.md", "Private Notes.md", "Scratch Page.md"]
SHARED_FILES = ["Learning Goals.md", "Help Sessions.md"]


# ---------------------------------------------------------------------------
# Shapes: the folders a kind of course wants, and the words it works in.
# ---------------------------------------------------------------------------

SHAPES = {
    "performance-arts": {
        "folders": ["Concepts", "Conventions", "Warm-Ups", "Discussions", "Portfolios", "Tasks"],
        "room": "studio",
        "agreement": "Our Studio Agreement",
        "agenda": [
            "Warm-up together — %WARMUP%",
            "Explore: try it before it has a name — %DOING%",
            "Name it: the idea behind what just happened — %IDEA%",
            "Work time in small groups",
            "Share, and respond to one another's work",
        ],
        "homework": [
            "Write two lines in your journal about what changed today.",
            "Bring one question you want the group to try next class.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": False},
    },
    "studio-arts": {
        "folders": ["Concepts", "Techniques", "Studio Time", "Critiques", "Portfolios", "Tasks"],
        "room": "studio",
        "agreement": "Our Studio Agreement",
        "agenda": [
            "Look together: one work, three minutes, no talking",
            "Demonstration of today's technique — %DOING%",
            "Studio time — %PRACTICE%",
            "Clean-up, with ten minutes to spare",
            "Quick critique: two works, two comments each — %CRITIQUE%",
        ],
        "homework": [
            "Photograph today's work for your portfolio.",
            "Find one example of this technique somewhere in the world.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": False},
    },
    "science": {
        "folders": ["Concepts", "Investigations", "Exercises", "Discussions", "Portfolios", "Tasks"],
        "room": "lab",
        "agreement": "Safety in the Lab",
        "agenda": [
            "Warm-up question on the board",
            "Investigation: predict, then test — %DOING%",
            "Consolidate: compare methods, then name the idea — %IDEA%",
            "Practice: a short set — %PRACTICE%",
            "Exit question",
        ],
        "homework": [
            "Finish the data table from today's investigation.",
            "Read the concept page for the idea we named today.",
        ],
        "shows": {"maths": True, "chemistry": False, "code": False},
    },
    "mathematics": {
        "folders": ["Concepts", "Thinking Tasks", "Exercises", "Discussions", "Portfolios", "Tasks"],
        "room": "classroom",
        "agreement": "How We Work Together",
        "agenda": [
            "Thinking task at the boards, in visibly random groups — %DOING%",
            "Consolidate from the bottom: compare the methods that appeared",
            "Name it, and write notes to your future forgetful self — %IDEA%",
            "Check your understanding: three questions — %PRACTICE%",
        ],
        "homework": [
            "Finish your notes to your future forgetful self.",
            "Try the check-your-understanding questions we did not reach.",
        ],
        "shows": {"maths": True, "chemistry": False, "code": False},
    },
    "computing": {
        "folders": ["Concepts", "Examples", "Exercises", "Projects", "Discussions", "Tasks"],
        "room": "lab",
        "agreement": "How We Work Together",
        "agenda": [
            "Read code together: what does this do, and how do you know? — %DOING%",
            "Try it: change one thing and predict what happens",
            "Name the idea — %IDEA%",
            "Build: work time on the current project — %PRACTICE%",
            "Share one thing that broke, and what fixed it",
        ],
        "homework": [
            "Commit what you have, even if it does not run yet.",
            "Write one sentence about the bug that cost you the most time.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": True},
    },
    "humanities": {
        "folders": ["Concepts", "Sources", "Discussions", "Writing", "Portfolios", "Tasks"],
        "room": "classroom",
        "agreement": "How We Discuss Difficult Things",
        "agenda": [
            "Read the source: five minutes, pencil in hand — %DOING%",
            "Talk in threes: what is this source claiming, and who made it?",
            "Whole-group discussion — %DISCUSSION%",
            "Name the idea, and where it turns up again — %IDEA%",
            "Write: one paragraph, one claim, one piece of evidence — %PRACTICE%",
        ],
        "homework": [
            "Finish the paragraph you started in class.",
            "Bring one source that complicates today's claim.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": False},
    },
    "language": {
        "folders": ["Concepts", "Vocabulary", "Conversations", "Readings", "Portfolios", "Tasks"],
        "room": "classroom",
        "agreement": "How We Work Together",
        "agenda": [
            "Warm-up: two minutes of talk, no notes",
            "New vocabulary, in a sentence you would actually say — %DOING%",
            "Read together, and listen once without the text — %READ%",
            "Practise in pairs — %PRACTICE%",
            "Share: one sentence each, out loud",
        ],
        "homework": [
            "Add today's words to your own vocabulary page.",
            "Listen to something in the language for five minutes.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": False},
    },
    "workshop": {
        "folders": ["Concepts", "Techniques", "Safety", "Projects", "Portfolios", "Tasks"],
        "room": "shop",
        "agreement": "Safety Rules and Sign-Off",
        "agenda": [
            "Safety check: today's tools, today's hazards — %SAFETY%",
            "Demonstration — %DOING%",
            "Work time on the current project — %PRACTICE%",
            "Clean-up and tool count",
            "Log what you did, in your own words — %PORTFOLIO%",
        ],
        "homework": [
            "Update your project log with today's step.",
            "Read the safety page for the tool we use next class.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": False},
    },
    "business": {
        "folders": ["Concepts", "Cases", "Exercises", "Projects", "Portfolios", "Tasks"],
        "room": "classroom",
        "agenda": [
            "A case: what would you do, and what would it cost? — %DOING%",
            "Compare decisions, and the reasoning behind them",
            "Name the idea — %IDEA%",
            "Practice: a short set — %PRACTICE%",
            "Work time on the current project",
        ],
        "agreement": "How We Work Together",
        "homework": [
            "Finish the case questions we did not reach.",
            "Bring one real business decision from the news.",
        ],
        "shows": {"maths": True, "chemistry": False, "code": False},
    },
    "physical-education": {
        "folders": ["Concepts", "Activities", "Fitness", "Reflections", "Portfolios", "Tasks"],
        "room": "gym",
        "agreement": "How We Play Together",
        "agenda": [
            "Warm-up and movement preparation",
            "Skill focus for today — %IDEA%",
            "Activity or game — %DOING%",
            "Cool-down",
            "Reflect: one thing that improved, one thing to work on — %REFLECT%",
        ],
        "homework": [
            "Log this week's activity in your portfolio.",
            "Bring the equipment you need for next class.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": False},
    },
    "general": {
        "folders": ["Concepts", "Activities", "Discussions", "Portfolios", "Tasks"],
        "room": "classroom",
        "agreement": "How We Work Together",
        "agenda": [
            "Warm-up",
            "Explore: work with the idea before it is named — %DOING%",
            "Name it, together — %IDEA%",
            "Work time",
            "Share what you found",
        ],
        "homework": [
            "Finish what you started in class today.",
            "Bring one question for next class.",
        ],
        "shows": {"maths": False, "chemistry": False, "code": False},
    },
}


# ---------------------------------------------------------------------------
# Families: what a course of this kind is called, and which shape it takes.
# `folders` overrides the shape's list when the subject names things its own
# way — a music course rehearses repertoire; a drama course has conventions.
# ---------------------------------------------------------------------------

def family(label, subject, shape, **overrides):
    entry = {"label": label, "subject": subject, "shape": shape}
    entry.update(overrides)
    return entry


FAMILIES = {
    # The Arts
    "drama": family("Drama", "drama", "performance-arts"),
    "music": family("Music", "music", "performance-arts",
                    folders=["Concepts", "Repertoire", "Warm-Ups", "Listening", "Portfolios", "Tasks"],
                    agreement="Our Ensemble Agreement"),
    "dance": family("Dance", "dance", "performance-arts",
                    folders=["Concepts", "Technique", "Warm-Ups", "Choreography", "Portfolios", "Tasks"]),
    "visual-arts": family("Visual Arts", "visual art", "studio-arts"),
    "media-arts": family("Media Arts", "media art", "studio-arts",
                         folders=["Concepts", "Techniques", "Production", "Critiques", "Portfolios", "Tasks"]),
    "integrated-arts": family("Integrated Arts", "the arts", "performance-arts"),

    # Business
    "business": family("Business Studies", "business", "business"),

    # Canadian and world studies
    "geography": family("Geography", "geography", "humanities",
                        folders=["Concepts", "Sources", "Fieldwork", "Discussions", "Portfolios", "Tasks"]),
    "history": family("History", "history", "humanities"),
    "civics-politics": family("Civics and Politics", "civics", "humanities"),
    "law": family("Law", "law", "humanities",
                  folders=["Concepts", "Cases", "Discussions", "Writing", "Portfolios", "Tasks"]),
    "economics": family("Economics", "economics", "humanities",
                        folders=["Concepts", "Data", "Discussions", "Writing", "Portfolios", "Tasks"]),

    # English and literacy
    "english": family("English", "English", "humanities",
                      folders=["Concepts", "Readings", "Discussions", "Writing", "Portfolios", "Tasks"]),
    "english-language-learning": family("English Language Learning", "English", "language"),
    "literacy": family("Literacy", "literacy", "general",
                       folders=["Concepts", "Readings", "Writing", "Portfolios", "Tasks"]),

    # French and other languages
    "french": family("French", "French", "language"),
    "international-languages": family("International Languages", "the language", "language"),
    "indigenous-languages": family("Indigenous Languages", "the language", "language"),
    "classical-languages": family("Classical Languages", "the language", "language",
                                  folders=["Concepts", "Vocabulary", "Translation", "Readings", "Portfolios", "Tasks"]),

    # Guidance, co-op, interdisciplinary
    "guidance-careers": family("Guidance and Career Education", "career education", "general",
                               folders=["Concepts", "Activities", "Reflections", "Portfolios", "Tasks"]),
    "cooperative-education": family("Cooperative Education", "co-op", "general",
                                    folders=["Concepts", "Placements", "Reflections", "Portfolios", "Tasks"]),
    "interdisciplinary": family("Interdisciplinary Studies", "this course", "general"),
    "essential-skills": family("Essential Skills", "this course", "general",
                               folders=["Concepts", "Activities", "Practice", "Portfolios", "Tasks"]),

    # Social sciences and humanities
    "social-sciences": family("Social Sciences", "social science", "humanities"),
    "food-and-nutrition": family("Food and Nutrition", "food and nutrition", "workshop",
                                 folders=["Concepts", "Techniques", "Kitchen Safety", "Recipes", "Portfolios", "Tasks"],
                                 room="kitchen", agreement="Safety in the Kitchen"),
    "fashion-and-textiles": family("Fashion and Textiles", "textiles", "studio-arts"),
    "family-studies": family("Family Studies", "family studies", "humanities"),

    # Computing
    "computer-science": family("Computer Studies", "computer science", "computing"),
    "computer-engineering": family("Computer Engineering", "computer engineering", "computing",
                                   folders=["Concepts", "Examples", "Builds", "Safety", "Portfolios", "Tasks"],
                                   room="lab", agreement="Safety Rules and Sign-Off"),

    # Mathematics
    "mathematics": family("Mathematics", "mathematics", "mathematics"),

    # Indigenous studies
    "indigenous-studies": family("First Nations, Métis, and Inuit Studies",
                                 "this course", "humanities"),

    # Health and physical education
    "physical-education": family("Health and Physical Education", "health and physical education",
                                 "physical-education"),

    # Sciences
    "science": family("Science", "science", "science"),
    "biology": family("Biology", "biology", "science",
                      folders=["Concepts", "Investigations", "Fieldwork", "Exercises", "Portfolios", "Tasks"]),
    "chemistry": family("Chemistry", "chemistry", "science", chemistry=True),
    "physics": family("Physics", "physics", "science"),
    "earth-and-space": family("Earth and Space Science", "earth and space science", "science",
                              folders=["Concepts", "Investigations", "Observations", "Exercises", "Portfolios", "Tasks"]),
    "environmental-science": family("Environmental Science", "environmental science", "science",
                                    folders=["Concepts", "Investigations", "Fieldwork", "Discussions", "Portfolios", "Tasks"]),

    # Technological education
    "construction": family("Construction Technology", "construction", "workshop"),
    "technological-design": family("Technological Design", "design", "workshop",
                                   folders=["Concepts", "Techniques", "Drawings", "Projects", "Portfolios", "Tasks"],
                                   room="design lab"),
    "hospitality": family("Hospitality and Tourism", "hospitality", "workshop",
                          folders=["Concepts", "Techniques", "Kitchen Safety", "Service", "Portfolios", "Tasks"],
                          room="kitchen", agreement="Safety in the Kitchen"),
    "communications-technology": family("Communications Technology", "communications technology",
                                        "studio-arts",
                                        folders=["Concepts", "Techniques", "Production", "Critiques", "Portfolios", "Tasks"]),
    "green-industries": family("Green Industries", "green industries", "workshop",
                               folders=["Concepts", "Techniques", "Safety", "Growing", "Portfolios", "Tasks"],
                               room="greenhouse"),
    "manufacturing": family("Manufacturing Technology", "manufacturing", "workshop"),
    "transportation": family("Transportation Technology", "transportation technology", "workshop"),
    "health-care": family("Health Care", "health care", "workshop",
                          folders=["Concepts", "Techniques", "Safety", "Practice", "Portfolios", "Tasks"],
                          room="lab"),
    "child-and-gerontology": family("Child Development and Gerontology", "this course", "humanities"),
    "hairstyling": family("Hairstyling and Aesthetics", "hairstyling and aesthetics", "workshop",
                          folders=["Concepts", "Techniques", "Safety", "Clients", "Portfolios", "Tasks"],
                          room="salon"),
    "exploring-technology": family("Technological Education", "technology", "workshop"),

    # Anything unrecognised
    "general": family("This Course", "this course", "general"),
}


# ---------------------------------------------------------------------------
# Which family a course code belongs to. Three-letter prefixes first, then
# the discipline letter, then the generic skeleton.
# ---------------------------------------------------------------------------

PREFIX_RULES = [
    # The Arts
    (("AD",), "drama"),
    (("AM",), "music"),
    (("AT",), "dance"),
    (("AV", "AW"), "visual-arts"),
    (("ASM",), "media-arts"),
    (("AEA", "ALC"), "integrated-arts"),
    # Business
    (("B",), "business"),
    # Canadian and world studies
    (("CG",), "geography"),
    (("CHV",), "civics-politics"),
    (("CP",), "civics-politics"),
    (("CH",), "history"),
    (("CL",), "law"),
    (("CI",), "economics"),
    (("CCL",), "french"),
    # English
    (("ESL", "ELD", "EAN"), "english-language-learning"),
    (("ELS",), "literacy"),
    (("E",), "english"),
    (("OLC",), "literacy"),
    # Languages
    (("FCC", "FFA", "FFP"), "english-language-learning"),
    (("F",), "french"),
    (("LN",), "indigenous-languages"),
    (("LV",), "classical-languages"),
    (("L",), "international-languages"),
    # Guidance, co-op, interdisciplinary, essential skills
    (("G",), "guidance-careers"),
    (("D",), "cooperative-education"),
    (("ID",), "interdisciplinary"),
    (("K",), "essential-skills"),
    # Social sciences and humanities
    (("HF",), "food-and-nutrition"),
    (("HN", "HLS"), "fashion-and-textiles"),
    (("HP", "HHD", "HHG", "HHS", "HIF", "HIP"), "family-studies"),
    (("H",), "social-sciences"),
    # Computing
    (("ICS", "ICD"), "computer-science"),
    # Mathematics
    (("M",), "mathematics"),
    # Indigenous studies
    (("N",), "indigenous-studies"),
    # Health and physical education
    (("P",), "physical-education"),
    # Sciences
    (("SBI",), "biology"),
    (("SCH",), "chemistry"),
    (("SPH",), "physics"),
    (("SES",), "earth-and-space"),
    (("SVN",), "environmental-science"),
    (("S",), "science"),
    # Technological education
    (("TC", "TWJ"), "construction"),
    (("TD",), "technological-design"),
    (("TE",), "computer-engineering"),
    (("TF", "ZTD"), "hospitality"),
    (("TG",), "communications-technology"),
    (("TH",), "green-industries"),
    (("TM", "ZTP"), "manufacturing"),
    (("TO",), "child-and-gerontology"),
    (("TP", "ZTO"), "health-care"),
    (("TT",), "transportation"),
    (("TX",), "hairstyling"),
    (("T",), "exploring-technology"),
]


def family_for(prefix: str) -> str:
    """The family a three-letter course-code prefix belongs to."""
    for patterns, name in PREFIX_RULES:
        for pattern in patterns:
            if prefix.startswith(pattern):
                return name
    return "general"


def resolved(name: str) -> dict:
    """A family with its shape's defaults filled in."""
    entry = dict(FAMILIES[name])
    shape = dict(SHAPES[entry["shape"]])
    for key, value in shape.items():
        entry.setdefault(key, value)
    entry["shows"] = dict(shape["shows"])
    if entry.get("chemistry"):
        entry["shows"]["chemistry"] = True
    return entry


# ---------------------------------------------------------------------------
# What each folder is for. The first line goes on the folder's landing page;
# the second says what belongs there, in this subject's words.
# ---------------------------------------------------------------------------

FOLDER_BLURBS = {
    "Concepts": ("One page per idea, written once and linked from everywhere it comes up.",
                 "When an idea in {subject} needs explaining more than once, it belongs here rather than inside a lesson plan — then every class that touches it can link to the same page."),
    "Conventions": ("The shared vocabulary of the form, one page per convention.",
                    "A convention is a way of making meaning that everyone in the room agrees on. Name each one, show it, and link to it from the day it is first used."),
    "Repertoire": ("The pieces this course works on, one page each.",
                   "Give each piece a page: what it asks of the players, where the hard passages are, and what to listen for."),
    "Technique": ("How the body does it — one page per technique.",
                  "Technique pages age well. Write them once, with what to look for and what usually goes wrong, and link to them whenever the technique returns."),
    "Techniques": ("How each thing is done, one page per technique.",
                   "A technique page is worth writing the first time you demonstrate something, because you will demonstrate it again next year."),
    "Warm-Ups": ("Short openers, filed so they can be found again.",
                 "The warm-up that worked is worth keeping. One page each, with how long it takes and what it prepares."),
    "Listening": ("What the class listens to, and what to listen for.",
                  "A listening page names the recording, gives the timings that matter, and asks one question worth answering."),
    "Choreography": ("The work being made, one page per piece.",
                     "Record what the piece is about, its structure, and the decisions the group has made so far."),
    "Studio Time": ("What happens in the working part of the class.",
                    "Studio pages hold the brief, the constraints, and the deadline — the things students ask about after they have started."),
    "Production": ("The work being made, from brief to final cut.",
                   "One page per production: the brief, the plan, the roles, and where the files live."),
    "Critiques": ("How work gets talked about here.",
                  "A critique page holds the protocol and the questions, so the conversation is about the work rather than about who made it."),
    "Investigations": ("Hands-on work, one page per investigation.",
                       "Each page carries the question, the safety notes, the procedure, and what to record — everything a student needs to run it without you standing beside them."),
    "Fieldwork": ("Work done outside the {room}.",
                  "Fieldwork pages hold the site, what to bring, what to record, and how the data gets back into the course."),
    "Observations": ("What was seen, and when.",
                     "Observation pages are dated records — sky, weather, growth, whatever this course watches over time."),
    "Exercises": ("Practice sets, with the answers folded away.",
                  "Practice comes after sense-making, never instead of it. Write the answers in folded callouts so a student has to try first."),
    "Thinking Tasks": ("Problems worth thinking about, one page each.",
                       "A thinking task has a low floor and a high ceiling: everyone can start, and nobody finishes it in one move."),
    "Examples": ("Worked examples, one page each.",
                 "An example page shows the whole thing working, then explains why it works — in that order."),
    "Exercises ": ("Practice sets.", "Practice pages."),
    "Projects": ("The bigger pieces of work, one page each.",
                 "A project page holds the brief, the checkpoints, and how it will be assessed — written before the project starts."),
    "Builds": ("What gets built, one page per build.",
               "Each build page carries the circuit or the assembly, the parts list, and the test that says it works."),
    "Safety": ("What can hurt you here, and how not to be hurt.",
               "Safety pages are the ones students will actually reread. One page per tool or hazard, plain and short, with the sign-off recorded."),
    "Kitchen Safety": ("Food safety and kitchen hazards.",
                       "One page per hazard — heat, blades, allergens, temperatures — plain and short, with the sign-off recorded."),
    "Recipes": ("What the class cooks, one page each.",
                "A recipe page holds the method, the timings, the yield, and the technique it is really teaching."),
    "Service": ("Working with guests.",
                "Service pages hold the standards, the sequence, and the words to use when something goes wrong."),
    "Growing": ("What is planted, and how it is doing.",
                "Growing pages are dated: what went in, what was done to it, and what happened."),
    "Drawings": ("Drawings and drawing standards.",
                 "One page per drawing convention or per project's drawing set, so a standard is settled once."),
    "Clients": ("Working with clients.",
                "Client pages hold the consultation questions, the record of what was done, and the aftercare given."),
    "Practice": ("Supervised practice, one page per skill.",
                 "Each page names the skill, the steps, and what competent looks like."),
    "Cases": ("Real situations to reason about, one page each.",
              "A case page gives the facts, the question, and nothing else — the reasoning is the students' work."),
    "Data": ("The numbers this course argues with.",
             "One page per dataset or indicator: where it comes from, what it measures, and what it does not."),
    "Sources": ("The documents, images, and data this course reads.",
                "Every source gets a page with its provenance — who made it, when, and why — because that is half of what students are learning to ask."),
    "Readings": ("What the class reads, one page each.",
                 "A reading page carries the text or the link, the questions worth asking of it, and the vocabulary that will trip people up."),
    "Discussions": ("Questions the class talks through, one page each.",
                    "Write the question, the reason it is worth an hour, and what was said. The record is the value."),
    "Writing": ("How writing works in this course.",
                "One page per form, per move, or per assignment — the things students ask about at 10pm the night before."),
    "Translation": ("Passages worked on together.",
                    "One page per passage, with the text, the vocabulary, and the constructions it is really teaching."),
    "Vocabulary": ("Words worth keeping, grouped so they can be found.",
                   "Vocabulary lives in lists that get revisited. Group by theme rather than by the day it appeared."),
    "Conversations": ("What to say, and how to keep going.",
                      "One page per situation, with the phrases that carry it and the ones that rescue it."),
    "Activities": ("What the class does, one page per activity.",
                   "An activity page is the thing you would hand a supply teacher: what happens, in what order, and with what."),
    "Fitness": ("Personal fitness and how it is tracked.",
                "Fitness pages hold the components, the tests, and how progress is recorded — the parts students return to."),
    "Reflections": ("Prompts students write against.",
                    "A reflection page holds the prompt and the standard for a good answer, so reflecting is not guessing."),
    "Placements": ("The workplace side of the course.",
                   "One page per placement: the employer, the expectations, the hours, and what is being learned there."),
    "Portfolios": ("The record each student builds over the course.",
                   "Portfolio pages explain what goes in, how often, and what makes an entry good. The work itself stays the student's."),
    "Tasks": ("Assessed work, one page per task.",
              "A task page carries the format, the due date, and how it will be marked — written before the task is assigned."),
    "Discussions ": ("", ""),
}


# ---------------------------------------------------------------------------
# Page templates. Placeholders are %TOKENS% rather than {braces}, because the
# pages contain LaTeX and YAML, both of which use braces in earnest.
# ---------------------------------------------------------------------------

def wrap(text: str, width: int = 76) -> str:
    """Wrap a paragraph the way the payload pages are wrapped."""
    import textwrap
    return "\n".join(textwrap.wrap(text, width=width)) if text else text


def fill(text: str, fam: dict) -> str:
    return (text
            .replace("%SUBJECT%", fam["subject"])
            .replace("%LABEL%", fam["label"])
            .replace("%ROOM%", fam["room"])
            .replace("%AGREEMENT%", fam["agreement"])
            .replace("%CURRICULUM%", CURRICULUM_FOLDER))


def page(title: str, body: str, *, tags=None, toc=False, extra_frontmatter=None,
         created="__CREATED__") -> str:
    lines = ["---", f"title: {title}", "publish: true", f"created: {created}"]
    if toc:
        lines.append("enableToc: true")
    for line in (extra_frontmatter or []):
        lines.append(line)
    if tags:
        lines.append("tags:")
        for tag in tags:
            lines.append(f"  - {tag}")
    lines.append("---")
    return "\n".join(lines) + "\n" + body.strip() + "\n"


PLACEHOLDER_NOTE = """> [!note] This page is a starting point
> Everything below is a placeholder written for a %SUBJECT% course. Edit it,
> or delete it — the site does not need this page to work. What it is
> showing you is the SHAPE: a page with a title, a short reason to exist,
> and links out to the pages that follow from it."""


def folder_index(folder: str, fam: dict) -> str:
    purpose, guidance = FOLDER_BLURBS.get(
        folder, ("Pages for this part of the course.", "Add pages here as the course goes on."))
    body = f"""{wrap(fill(purpose, fam))}

{wrap(fill(guidance, fam))}

%%
Delete this comment once the folder has real pages in it. Anything between
double percent marks is invisible on the site — see [[What This Site Can Do]].
%%

> [!tip] How this folder behaves
> Quartz lists every page in this folder automatically, newest first. You
> never maintain that list. If you delete this `index.md`, the folder still
> works — the listing simply appears without an introduction.
"""
    return page(folder, fill(body, fam), tags=[folder.lower().replace(" ", "-")])


def setup_pages(fam: dict) -> dict:
    label = fam["label"]
    pages = {}

    pages["How This Class Works.md"] = page("How This Class Works", fill("""
%PLACEHOLDER%

## The rhythm of a class

Most classes in this course follow the same shape, so you always know what
is coming:

%AGENDA_LIST%

## Where things live

- Every class has its own page under [[All Classes/index|All Classes]].
- Ideas we name live in [[Concepts/index|Concepts]], and get linked from
  every class that uses them.
- What is due, and when, lives on the task's own page in
  [[Tasks/index|Tasks]].

## What to do when you are stuck

Ask in class, ask at [[Help Sessions]], or check [[Getting Help]]. Being
stuck is ordinary. Staying stuck quietly is the only mistake.
""", fam).replace("%PLACEHOLDER%", fill(PLACEHOLDER_NOTE, fam)), toc=True, tags=["setup"])

    pages[fam["agreement"] + ".md"] = page(fam["agreement"], fill("""
%PLACEHOLDER%

This page is the one students should be able to quote back to you. Write
what you actually expect, in plain words, and keep it short enough to read
aloud on the first day.

## What we agree to

- [ ] Replace this line with your first expectation.
- [ ] Replace this line with your second.
- [ ] Replace this line with your third.

## Why it matters here

A %SUBJECT% class asks people to try things in front of each other. That
only works in a room where it is safe to be a beginner — which is a thing
the group builds, not a thing the teacher announces.

> [!warning] For teachers
> If this course has real safety requirements — equipment, materials, the
> %ROOM% itself — write them here or on their own page, and record the
> sign-off. Do not leave that to a verbal briefing.
""", fam).replace("%PLACEHOLDER%", fill(PLACEHOLDER_NOTE, fam)), toc=True, tags=["setup"])

    pages["What to Bring.md"] = page("What to Bring", fill("""
%PLACEHOLDER%

| What | When | Notes |
| --- | --- | --- |
| Replace this row | Every class | What it is for |
| Replace this row | Work days | Where to get one |

Nothing on this list should be a surprise on the day it is needed. If
something costs money, say so here, and say what happens if it is a
problem.
""", fam).replace("%PLACEHOLDER%", fill(PLACEHOLDER_NOTE, fam)), tags=["setup"])

    pages["How Marks Work.md"] = page("How Marks Work", fill("""
%PLACEHOLDER%

## What is assessed

Every assessed piece of work has its own page in [[Tasks/index|Tasks]],
and every one of those pages says how it will be marked BEFORE you start
it. If a task page does not say, ask — that is a page that needs fixing.

## What is not assessed

Practice is not assessed. Neither is being wrong on the way to being
right. That is the whole point of practice.

## Late work, and work that is not finished

Write your actual policy here, in the words you would use to a student who
is worried. A policy nobody understands is not a policy.
""", fam).replace("%PLACEHOLDER%", fill(PLACEHOLDER_NOTE, fam)), toc=True, tags=["setup"])

    pages["Getting Help.md"] = page("Getting Help", fill("""
%PLACEHOLDER%

## Before you ask

Say what you tried. "It does not work" and "I tried X, expected Y, got Z"
are the same question, but the second one gets answered in a minute.

## Ways to get help here

1. In class — put your hand up, or come and find me while others work.
2. At [[Help Sessions]] — the times are on that page, and it is fine to
   turn up with nothing prepared.
3. From each other. Explaining something is how you find out whether you
   understand it.
""", fam).replace("%PLACEHOLDER%", fill(PLACEHOLDER_NOTE, fam)), toc=True, tags=["setup"])

    return pages


TOUR_HEAD = """This page has two audiences. Students: it explains why the notes look the
way they do. Teachers: it is a working reference for everything you can put
in a page, with the source shown beside every example.

Everything below is written in **Markdown** — plain text with a few marks of
punctuation that mean something. If you can write a text message, you can
write this.

---

## Text that carries meaning

You get **bold**, *italic*, ~~struck through~~, and ==highlighted== text.
Highlighting is the one worth knowing: it catches the eye better than bold
when a single ==important phrase== has to stand out inside a paragraph.

**How that was made:**

```markdown
**bold**, *italic*, ~~struck through~~, ==highlighted==
```

Arrows written as `->` become proper arrows, and keyboard keys look like
keys: press <kbd>⌘</kbd> + <kbd>K</kbd> to search.

---

## Headings, and the table of contents

Every `##` heading becomes a link in **Navigate this page**, over on the
right. Nothing builds that list by hand — it is assembled from the headings
as the page is built, so it can never fall out of step with the page it
describes.

**How that was made:** `##` at the start of a line, and `###` for a
sub-heading.

### Turning it off

A short page reads better without a contents panel. One line in the
frontmatter does it:

```yaml
---
enableToc: false
---
```

Every class page in [[All Classes/index|All Classes]] uses this.

---

## Callouts

Callouts lift something out of the flow of the page. There are a dozen
kinds, each with its own colour and icon.

> [!note] Note
> Neutral information worth setting apart.

> [!tip] Tip
> A shortcut, a habit, or something that makes the work easier.

> [!important] Important
> The one thing to take away if you take away nothing else.

> [!warning] Warning
> Where people usually go wrong.

> [!example] Example
> A worked case.

**How that was made:** a blockquote with the kind named in brackets.

```markdown
> [!warning] Where people usually go wrong
> The text of the callout goes here.
```

### Foldable callouts

Add a `-` after the kind and the callout starts collapsed. Clicking the
title opens it. This is how answers and hints stay on the page without
giving themselves away.

> [!success]- Answer: click this line
> The hidden content sits here, out of sight until it is wanted.

```markdown
> [!success]- Answer: click this line
> The hidden content.
```

---
"""

TOUR_MATHS = """
## Mathematics

Inline maths sits inside a sentence: the slope between two points is
$m = \\frac{y_2 - y_1}{x_2 - x_1}$.

Display maths gets a line of its own, centred:

$$\\begin{aligned} (a + b)^2 &= a^2 + 2ab + b^2 \\\\ &= a^2 + b^2 + 2ab \\end{aligned}$$

**How that was made:** single dollar signs keep it in the sentence, double
ones give it a line of its own.

```markdown
Inline: $m = \\frac{y_2 - y_1}{x_2 - x_1}$

Display: $$E = mc^2$$
```

> [!warning] For teachers: display maths stays on ONE physical line
> A `$$` span broken across lines, indented four spaces, or spread down a
> callout hits a markdown seam and shatters. Multi-step working goes on one
> line inside `\\begin{aligned} … \\end{aligned}`.

---
"""

TOUR_CHEMISTRY = """
## Chemistry

Chemistry is written inside `\\ce{...}`. Everything in there is read as
chemistry, so subscripts sit low, charges sit high, states sit in brackets,
and reaction arrows are arrows:

$$\\ce{CaCO3(s) <=> CaO(s) + CO2(g)}$$

| What you type | What appears | What it means |
| --- | --- | --- |
| `$\\ce{H2O}$` | $\\ce{H2O}$ | Digits drop to subscripts |
| `$\\ce{2H2O}$` | $\\ce{2H2O}$ | A digit in front is a coefficient |
| `$\\ce{SO4^2-}$` | $\\ce{SO4^2-}$ | A charge, number before sign |
| `$\\ce{NaCl(aq)}$` | $\\ce{NaCl(aq)}$ | A state, typed literally |
| `$\\ce{2H2 + O2 -> 2H2O}$` | $\\ce{2H2 + O2 -> 2H2O}$ | The reaction arrow |
| `$\\ce{AgCl v}$` | $\\ce{AgCl v}$ | Precipitate down, gas up |

---
"""

TOUR_CODE = """
## Code

**How that was made:** three backticks and the name of a language, the
code, then three backticks to close it.

```python
def mean(values):
    return sum(values) / len(values)

print(mean([3, 4, 5]))
```

Syntax colouring follows the language you name after the opening fence and
adapts to light or dark mode.

---
"""

TOUR_TAIL = """
## Diagrams

Diagrams are **written, not drawn** — which means they can be edited in
seconds, they never need a graphics program, and a change to one shows up
in a diff.

```mermaid
graph LR
    A["A question"] --> B["Something you try"]
    B --> C["What you noticed"]
    C --> D["What you would do differently"]
```

**How that was made:** not a picture — those lines of text, between two
fence lines that say `mermaid`.

````markdown
```mermaid
graph LR
    A["A question"] --> B["Something you try"]
```
````

---

## Tables

| Column | Column | Column |
| --- | --- | --- |
| Rows of text | separated by | vertical bars |
| with a line of | dashes under | the headings |

Maths works inside table cells, and so do links — which matters more than
it sounds, because a summary table can then be a navigation aid rather than
a dead end.

> [!note] For teachers: escape the pipe inside a table cell
> A wikilink with different display words uses a pipe, and so does the
> table. Inside a cell, write `[[Page\\|the words shown]]` with a backslash,
> or the row splits into an extra column.

---

## Checklists

- [ ] A line that starts with `- [ ]`
- [x] One already done, written `- [x]`

On the site they are read-only — the boxes show what the page says, and
clicking one does nothing. Copied into a notebook, they are useful for
keeping your place.

---

## Links between pages

This is what makes the site more than a pile of documents.

- A plain link: [[How This Site Is Organised]]
- A link with different words:
  [[How This Site Is Organised|where everything lives]]

```markdown
[[How This Site Is Organised]]
[[How This Site Is Organised|different words for the link]]
```

### Transclusion — one page inside another

`![[Page name]]` pulls a whole page in live rather than copying it. Below,
the help-session times are pulled in:

![[Help Sessions]]

Change the source page and every page that embeds it updates. That is how
a section's landing page always shows the current class without anybody
maintaining a second copy of it.

### Backlinks

Scroll to the bottom of any page and you will find **Backlinks** — every
page that links *to* this one, gathered automatically. Nobody maintains
that list, which is why linking generously costs nothing.

---

## Hover previews

Hover over [[Using This Site]] without clicking. The page appears in a
small window, so checking one thing does not cost you your place.

---

## Footnotes

**How that was made:** `[^1]` where the marker goes, and a matching `[^1]:`
line anywhere in the page.[^1]

[^1]: Like this. Footnotes collect at the bottom no matter where you write
    them, so you can put the note next to the sentence it belongs to.

---

## Tags

```yaml
---
tags:
  - reference
  - setup
---
```

Every tag becomes a page listing everything filed under it.

---

## What you cannot see

Two things on this page are invisible in the browser:

1. **Comments.** Text wrapped in `%%` double percent marks `%%` never
   reaches the site. Useful for notes to yourself in a page you are still
   writing.
2. **Holding a page back.** A page with `publish: false` in its
   frontmatter is skipped entirely when the site is built. Write next
   week's lesson today and publish it when you are ready.

%% This sentence is a comment. If you can read it on the website,
something is broken. %%

> [!tip] For teachers reading this
> A shared page can be published to one section and held back from another
> using per-section `publishForSection1` / `publishForSection2` keys in the
> frontmatter — useful when two classes have drifted a few days apart.

---

## The point of all this

None of it is decoration. Each feature removes a reason for a page to go
out of date:

| Feature | The problem it solves |
| --- | --- |
| Transclusion | The same text copied into six places, five of them stale |
| Backlinks | "Where did we use this again?" |
| Diagrams as text | Rebuilding a whole diagram to change one arrow |
| Drafts | Keeping unpublished work in some other file somewhere |
| Hover previews | Losing your place to check one thing |

Write it once, link to it everywhere.
"""


def style_pages(fam: dict) -> dict:
    pages = {}
    folders = fam["folders"]
    listed = "\n".join(
        wrap("- **" + name + "** — " + fill(
            FOLDER_BLURBS.get(name, ("Pages for this part of the course.", ""))[0], fam), 74)
        .replace("\n", "\n  ")
        for name in folders)

    pages["How This Site Is Organised.md"] = page("How This Site Is Organised", fill(f"""
Everything in this course lives in one of a few places, and the sidebar on
the left mirrors them exactly.

## The folders

{listed}
- **Setup** — how the course runs: what to bring, how marks work, where to
  get help.
- **Style** — how the site itself works, including this page.
- **Tutorials** — how to use the tools this course uses.

## Classes

Each class has a page under [[All Classes/index|All Classes]], named for
its unit and day. A class page is an agenda: a numbered list of what
happened, with links to the pages it used, and a short list of things to do
before next time. Nothing is explained on a class page — it links to the
page that explains it.

## Everything else

[[Key Links]] holds the handful of pages you will want most often. The
search box finds anything by title or by text.

> [!tip] The one habit worth having
> When something is explained twice, it should be a page. Then every class
> that touches it links to the same explanation, and correcting it once
> corrects it everywhere.
""", fam), toc=True, tags=["style"])

    tour = TOUR_HEAD
    if fam["shows"]["maths"]:
        tour += TOUR_MATHS
    if fam["shows"]["chemistry"]:
        tour += TOUR_CHEMISTRY
    if fam["shows"]["code"]:
        tour += TOUR_CODE
    tour += TOUR_TAIL
    pages["What This Site Can Do.md"] = page("What This Site Can Do", fill(tour, fam),
                                             toc=True, tags=["reference", "style"])

    pages[f"Writing About {fam['label']}.md"] = page(f"Writing About {fam['label']}", fill("""
%PLACEHOLDER%

Every subject has its own way of writing, and students are usually left to
infer it. This page is where you say it out loud.

## What good writing looks like here

Replace this with the two or three moves that matter in %SUBJECT% — the
ones you find yourself writing in the margin over and over.

## Words we use precisely

| Word | What it means here |
| --- | --- |
| Replace this | With a term students use loosely |
| Replace this | With another |

## A worked example

Show one short piece of writing, then the same piece improved, and say what
changed. One before-and-after teaches more than a page of rules.
""", fam).replace("%PLACEHOLDER%", fill(PLACEHOLDER_NOTE, fam)), toc=True, tags=["style"])

    return pages


def tutorial_page(fam: dict) -> str:
    return page("Using This Site", fill("""
This site is read, not logged into. There is nothing to install and no
account to make.

## Finding things

- The **sidebar** on the left mirrors the course's folders.
- **Search** (<kbd>⌘</kbd> or <kbd>Ctrl</kbd> + <kbd>K</kbd>) finds any page
  by title or by the words inside it.
- **Backlinks**, at the bottom of every page, show which pages point here —
  which is often how you find the class where something was first used.

## Reading a class page

A class page is an agenda. The numbered list is what happened, in order,
with links to the pages used. The checklist at the bottom is what to do
before the next class.

## On a phone

Everything works on a phone. The sidebar becomes a menu at the top, and
tables scroll sideways rather than squashing.

> [!tip] Hover before you click
> On a computer, resting the pointer on a link shows the page in a small
> window. It is the fastest way to check one thing without losing your
> place.
""", fam), toc=True, tags=["tutorials"])


def curriculum_pages(fam: dict) -> dict:
    index = page(CURRICULUM_FOLDER, fill("""
This folder is where the Ministry's expectations for __COURSE_CODE__ live —
one page per expectation, so a lesson or task can link to exactly the
expectations it addresses.

**It is empty apart from one example.** Ready-made curriculum pages ship
with a handful of course codes; for the rest, this is the shape to fill in.

## How to add them

1. Open the Ministry's curriculum document for __COURSE_CODE__ and find the
   expectations for this course.
2. Make one page per expectation, named for its code — `A1.1.md`, `A1.2.md`,
   and so on. [[A1.1|The example page]] shows the shape: the verbatim
   wording, ending in a ` ^text` block anchor.
3. On a lesson or task page, transclude the ones it addresses:

```markdown
%%curriculum-start%%
## Curriculum connection

![[A1.1]]
%%curriculum-end%%
```

The markers matter: they let the whole block be removed cleanly if you ever
decide the site should not carry expectations.

> [!warning] Copy the wording exactly
> An expectation paraphrased is an expectation misquoted. Copy the
> Ministry's words as they are published, and put your own explanation on a
> concept page instead.
""", fam), toc=True)

    example = page("A1.1", """demonstrate an understanding of the thing this expectation is about, in
the Ministry's own words, copied exactly and ending with the anchor below ^text

%%
DELETE THIS PAGE once you have added real expectations. It exists to show
two things: the file is named for the expectation's code, and the wording
ends in a ` ^text` block anchor so it can be transcluded on its own.
%%
""", extra_frontmatter=["transcludeTitleSize: h4"], tags=["A1", "strand-a"])
    # Curriculum pages carry no created: line, matching the payloads.
    example = example.replace("created: __CREATED__\n", "")
    index = index.replace("created: __CREATED__\n", "")
    return {"index.md": index, "A1.1.md": example}


def shared_files(fam: dict) -> dict:
    return {
        "Learning Goals.md": page("Learning Goals", fill("""
%PLACEHOLDER%

By the end of this course you will be able to:

- Replace this with something a student would recognise as worth being able
  to do.
- Replace this with another.
- Replace this with a third.

Written in plain words on purpose. The Ministry's wording lives in
[[%CURRICULUM%/index|the curriculum folder]]; this page is the version
you would say out loud on the first day.
""", fam).replace("%PLACEHOLDER%", fill(PLACEHOLDER_NOTE, fam)), tags=["setup"]),

        "Help Sessions.md": page("Help Sessions", fill("""
**When:** replace this with your actual times.
**Where:** replace this with the room.

No appointment, no need to bring a question. Turning up and working in the
same room as other people is a legitimate reason to come.

%%
This page is transcluded onto each section's landing page with
![[Help Sessions]] — change it here and it changes everywhere.
%%
""", fam), tags=["setup"]),
    }


# Which folder each agenda line points at. Families rename folders, so a
# slot is a preference order rather than a fixed name — and a line whose
# slot no folder fills simply loses its link rather than pointing nowhere.
SLOTS = {
    "IDEA": ["Concepts"],
    "DOING": ["Investigations", "Thinking Tasks", "Examples", "Sources", "Readings",
              "Cases", "Techniques", "Technique", "Repertoire", "Conventions",
              "Activities", "Vocabulary", "Data", "Placements", "Concepts"],
    "PRACTICE": ["Exercises", "Practice", "Studio Time", "Production", "Projects",
                 "Builds", "Writing", "Recipes", "Clients", "Service", "Growing",
                 "Drawings", "Choreography", "Conversations", "Translation",
                 "Fieldwork", "Observations", "Portfolios"],
    "SAFETY": ["Safety", "Kitchen Safety"],
    "PORTFOLIO": ["Portfolios"],
    "DISCUSSION": ["Discussions", "Critiques"],
    "CRITIQUE": ["Critiques", "Discussions"],
    "WARMUP": ["Warm-Ups", "Activities"],
    "READ": ["Readings", "Listening", "Sources"],
    "REFLECT": ["Reflections", "Portfolios"],
}


def resolve_slots(line: str, folders: list) -> str:
    """Turn %SLOT% into a link to the folder that fills it, or drop it."""
    for slot, preferences in SLOTS.items():
        token = f"%{slot}%"
        if token not in line:
            continue
        target = None
        for name in preferences:
            if name in folders:
                target = name
                break
        if target:
            line = line.replace(token, f"[[{target}/index|{target}]]")
        else:
            line = line.replace(f" — {token}", "").replace(token, "")
    return line


def class_pages(fam: dict) -> dict:
    """Four units of three classes each, dated across the semester."""
    pages = {}
    ordinal = 0
    folders = fam["folders"]
    for unit in range(1, 5):
        for day in range(1, 4):
            ordinal += 1
            title = f"Unit {unit}, Day {day}"
            if ordinal == 1:
                agenda = [
                    "Welcome, and what this course actually is",
                    "Tour of the site: [[Using This Site]] and [[How This Site Is Organised]]",
                    f"Read together: [[{fam['agreement']}]]",
                    "How the course runs: [[How This Class Works]] and [[How Marks Work]]",
                    "First activity",
                ]
                homework = [
                    f"Read [[{fam['agreement']}]].",
                    "Check [[What to Bring]] before next class.",
                ]
                preamble = """%%
This is the shape every class page takes: a numbered agenda of what
happened, with links to the pages it used, then a short list of things to do
before next time. Nothing is explained here — the links do that.

Twelve of these were created for you, four units of three. Rename them,
add more, delete the ones you do not need. The dates in the frontmatter are
what puts them in order under All Classes, so a new page needs a `created:`
date of its own.
%%

"""
            else:
                agenda = list(fam["agenda"])
                # Each agenda line points at the folder it belongs to, so
                # the links on a class page lead somewhere from day one.
                agenda = [resolve_slots(item, folders) for item in agenda]
                # A unit opens and closes differently from its middle.
                if day == 1:
                    agenda[0] = f"Start of Unit {unit} — what this unit is about, and where it leads"
                if day == 3:
                    agenda[-1] = (
                        "Culminating task: what it asks, and how long you have — [[Tasks/index|Tasks]]"
                        if unit == 4 else
                        f"End of Unit {unit} — pull the thread together, and look at what is due")
                homework = list(fam["homework"])
                if unit == 4 and day == 3:
                    homework = ["Start the culminating task — the first step only.",
                                "Bring one question about it to next class."]
                preamble = ""

            numbered = "\n".join(f"{index}. {item}" for index, item in enumerate(agenda, start=1))
            checked = "\n".join(f"- [ ] {item}" for item in homework)
            body = f"""{preamble}## Agenda

{numbered}

## Things to do before our next class

{checked}
"""
            pages[f"{title}.md"] = page(
                title, body,
                created=f"__CREATED_CLASS_{ordinal}__",
                extra_frontmatter=["transcludeTitleSize: h2", "enableToc: false",
                                   "excludeBacklinks: true"],
                tags=[f"unit-{unit}"])
    return pages


def per_section_pages(fam: dict) -> dict:
    pages = {}

    pages["index.md"] = page("Section __SECTION_NUMBER__", """# Most Recent Class

![[Unit 1, Day 1]]

%%
This is what students meet first, so it should show the newest class you
have published. You do not have to keep it up to date by hand: ask the
local AI assistant to publish or unpublish a class and it repoints this
transclusion for you, and moves this page's date to match that class.
%%

![[Help Sessions]]

![[Key Links]]
""", extra_frontmatter=["enableToc: false", "excludeBacklinks: true"])

    key_links = ["%%curriculum-start%%",
                 f"- [[{CURRICULUM_FOLDER}/index|Curriculum Expectations]]",
                 "%%curriculum-end%%",
                 "- [[Learning Goals]]",
                 "- [[How This Class Works]]",
                 "- [[How Marks Work]]",
                 "- [[Getting Help]]",
                 "- [[What This Site Can Do]]"]
    pages["Key Links.md"] = page("Key Links", "\n".join(key_links),
                                 extra_frontmatter=["transcludeTitleSize: h2",
                                                    "excludeBacklinks: true"])

    pages["Private Notes.md"] = page("Private Notes", """%%
A page for your own eyes. It ships held back, so it is never published —
leave `publish: false` alone unless you mean it.
%%

Notes to yourself about this section: who needs what, what to try next time,
what did not work.
""", extra_frontmatter=["excludeBacklinks: true"]).replace("publish: true", "publish: false")

    pages["Scratch Page.md"] = page("Scratch Page", """%%
Somewhere to draft. Also held back, so nothing here is published.
%%

Paste things here while you work out where they belong.
""", extra_frontmatter=["excludeBacklinks: true"]).replace("publish: true", "publish: false")

    pages["All Classes/index.md"] = page("All Classes", """Every class in this section, newest first. The list builds itself from the
pages in this folder — you never maintain it.

%%
The order comes from each page's `created:` date, not from its name. A new
class page needs a date of its own, or it lands wherever it likes.
%%
""")

    for name, text in class_pages(fam).items():
        pages[f"All Classes/{name}"] = text
    return pages


def build_family(name: str) -> int:
    fam = resolved(name)
    root = OUT / name
    if root.exists():
        shutil.rmtree(root)

    folders = fam["folders"]
    written = 0

    def write(relative: str, text: str):
        nonlocal written
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        written += 1

    # The agenda is part of How This Class Works, and only this function
    # knows the shape's agenda.
    agenda_list = "\n".join(
        f"{index}. {resolve_slots(item, folders)}"
        for index, item in enumerate(fam["agenda"], start=1))

    for folder in folders:
        write(f"shared/{folder}/index.md", folder_index(folder, fam))
    for filename, text in setup_pages(fam).items():
        write(f"shared/Setup/{filename}", text.replace("%AGENDA_LIST%", agenda_list))
    write("shared/Setup/index.md", page("Setup", fill("""
How the course runs — the pages a student reads once in September and comes
back to in November when something has gone wrong.
""", fam)))
    for filename, text in style_pages(fam).items():
        write(f"shared/Style/{filename}", text)
    write("shared/Style/index.md", page("Style", fill("""
How this site works, and how writing works in %SUBJECT%.
""", fam)))
    write("shared/Tutorials/Using This Site.md", tutorial_page(fam))
    write("shared/Tutorials/index.md", page("Tutorials", fill("""
How to use the tools this course uses — starting with the site itself.
""", fam)))
    for filename, text in curriculum_pages(fam).items():
        write(f"shared/{CURRICULUM_FOLDER}/{filename}", text)
    for filename, text in shared_files(fam).items():
        write(f"shared/{filename}", text)
    for relative, text in per_section_pages(fam).items():
        write(f"per_section/{relative}", text)

    shared_folders = folders + ["Setup", "Style", "Tutorials", CURRICULUM_FOLDER]
    manifest = {
        "shared_folders": shared_folders,
        "shared_files": SHARED_FILES,
        "per_section_folders": ["All Classes"],
        "per_section_files": UTILITY_FILES,
        "hidden": [CURRICULUM_FOLDER] + SHARED_FILES + UTILITY_FILES,
        "expandable": folders + ["Setup", "Style", "Tutorials"],
        "curriculum_folder": CURRICULUM_FOLDER,
        "skeleton": True,
        "label": fam["label"],
    }
    write("manifest.json", json.dumps(manifest, indent=2) + "\n")
    return written


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    total = 0
    for name in sorted(FAMILIES):
        total += build_family(name)

    catalogue = json.loads((ROOT / "support" / "ontario_secondary_courses.json").read_text())
    prefixes = {}
    for code in catalogue:
        prefix = code[:3]
        if prefix not in prefixes:
            prefixes[prefix] = family_for(prefix)

    (OUT / "families.json").write_text(json.dumps({
        "default": "general",
        "prefixes": dict(sorted(prefixes.items())),
    }, indent=2) + "\n", encoding="utf-8")

    counts = {}
    for name in prefixes.values():
        counts[name] = counts.get(name, 0) + 1
    print(f"{len(FAMILIES)} families, {total} pages, {len(prefixes)} prefixes mapped")
    for name in sorted(counts, key=lambda key: -counts[key]):
        print(f"   {counts[name]:>4} prefixes -> {name}")


if __name__ == "__main__":
    main()
