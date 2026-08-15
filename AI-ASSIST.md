# AI Assist — feasibility investigation

*Windows side, 2026-08-13, branch `ai-assist`. An evidence-gathering exercise
into one question: can a **small offline model, embedded in Plantoir's own
Docker image**, reliably drive Plantoir on behalf of a teacher who has no AI
account, no API key, and no internet requirement?*

> **Status.** All four steps of §6 are now **built** on this branch: the MCP
> server (`windows-app/Plantoir.Mcp/`, see its
> [README](windows-app/Plantoir.Mcp/README.md)), the local model runner
> (`Plantoir/Services/LocalModel.cs`), the conversation loop
> (`Services/AssistAgent.cs`), and a window to hold it
> (`Views/AssistWindow.xaml`), reached from **Revise with AI…** on a
> section's context menu. Folded into `main` on 2026-08-14, after the
> live-testing day recorded in `AI-ASSIST-HANDOFF.md` §10; not yet in any
> tagged release.
>
> **Not yet exercised end to end:** the model download is ~1.1 GB and happens
> only on a teacher's explicit yes, so the install-and-first-answer path has
> not been run. Everything up to it has: the server answers real JSON-RPC,
> and the app's client is verified against the running server.
>
> Building it confirmed the §3 finding in a way worth recording: the tool
> surface that fell out of "the model must not plan" is also *simpler* than
> the fine-grained one it replaced, and the code that resolves links and
> picks the right frontmatter key is ordinary, testable, boring code. The
> reliability was not bought with complexity.
>
> **Two things below are now out of date, and deliberately left as written**
> — they are the record of what was measured, not a description of what
> exists. Tool names have moved on (`set_draft` became `publish_pages` /
> `unpublish_pages`; `publish_section` became `deploy_section`), and the
> frontmatter flag those trials exercised was `draft:`, which is now
> `publish:` with the opposite polarity. The finding the trials produced —
> that the model inverts polarity often enough to matter — is exactly why
> every write has a `plan_` twin and a teacher's yes in front of it.

**Short answer: yes — but only if the model is never allowed to think.** Every
measurement below points the same way: a ~1.5B model is a reliable *router*
and an unreliable *planner*. Build it so the tools do the work and the model
only picks one, and it holds up. Ask it to sequence steps or infer intent, and
it fails in ways that would edit a teacher's course wrongly.

---

## 1. The budget is smaller than it looks

The constraint is not the teacher's laptop; it is the VM Plantoir already runs
inside.

| Layer | What it gets | Where that comes from |
|---|---|---|
| macOS | **4 GB, 2 CPUs** | Hardcoded: `colima start --cpu 2 --memory 4` in all three launchers |
| Windows | ~50% of host RAM | WSL2 default — measured 7.6 GB on this 15.7 GB machine |
| Windows @ 8 GB host | **~4 GB** | The stated hardware floor |

So on macOS the ceiling is 4 GB **even on a 64 GB Mac Studio**, because the
launcher fixes it. Both platforms converge on roughly the same budget, and the
toolchain (Node, esbuild, Quartz) has to live there too.

That budget is workable for one reason: **AI Assist and a site build never
need to run at the same time.** The teacher asks, the model routes, the tools
run. They take turns.

### A trap worth writing down

llama.cpp **mmaps** the model file by default, and in a memory-capped
container the page cache for that file counts against the cgroup limit. A 3B
model appeared to need 4 GB and died at 3 GB with `ExitCode=255`,
`OOMKilled=false` — no OOM message, no error in the log, just gone.

Passing **`--no-mmap`** drops the same model's real requirement from ~4 GB to
**2.48 GB** and it runs stably. Any embedded runtime must set this.

---

## 2. What was measured

Everything below ran in a container capped to the target hardware —
`--memory` set as shown, `--cpus=2`, no GPU — against a Plantoir-shaped tool
set (`publish_class`, `reschedule_classes`, `back_up_course`, `set_draft`,
`list_courses`) and nine teacher-voice requests, three trials each.

| Model | Weights | Runtime RAM | Routing accuracy | Malformed calls | Wrong arg types |
|---|---|---|---|---|---|
| **Qwen2.5-1.5B-Instruct** Q4_K_M | 941 MB | **1.08 GB** | **27/27 (100%)** | **0** | **0** |
| Llama-3.2-3B-Instruct Q4_K_M | 1.9 GB | 2.48 GB | 27/27 (100%) | 0 | 27 (all) |
| Llama-3.2-1B-Instruct Q4_K_M | 771 MB | 0.73 GB | 21/27 (78%) | 2 | 28 |

**Qwen2.5-1.5B is the clear winner, and it is not close.** It matches the
model twice its size on accuracy while using less than half the memory, and it
is the only one of the three that emits correct JSON types — `"section": 1`
and `"draft": false`, where both Llama models produced `"1"` and `"true"` as
strings on *every single response*. It also correctly extracted `"Ohm's Law"`,
which the 3B truncated to `"Ohm"` at the apostrophe.

The 1B is disqualified, and instructively so: it published the **wrong course**
(asked for ICS3U, emitted MCV4U), and when asked about tomorrow's *weather* it
invented `set_draft(course="teacher", page="weather", draft=true)`.

### Speed (2 CPU cores, no GPU)

| | Prompt eval | Generation | First request | Warm request |
|---|---|---|---|---|
| Llama-3.2-3B | 19.7 tok/s | 5.9 tok/s | ~35–50 s | 8–12 s |
| Qwen2.5-1.5B | — | — | ~17 s | **2–6 s** |
| Llama-3.2-1B | 58.3 tok/s | 15.5 tok/s | ~13 s | 1–4 s |

**Prompt caching is what makes this usable.** The tool definitions cost ~600
tokens and dominate the first call; llama.cpp caches that prefix, so every
later request in the session only pays for what changed. Measured directly on
the 3B: first request 35 s, the next five 4.5 s each. A teacher waits once per
session, not once per request.

---

## 3. The finding that decides the architecture

Given the *same* request and the *same* model, changing only the **shape of
the tool surface** flipped the result completely.

**Fine-grained tools — the model must plan.** Given `resolve_links`,
`set_draft` and `publish_section` separately, and asked to *"publish tomorrow's
class and make sure every page it links to is published"*, the 3B chose
`publish_section` **8 times out of 8** — skipping the link resolution entirely.
Perfectly consistent, and wrong. It latched onto the most salient verb and
ignored the rest of the sentence.

**One coarse tool — the model only routes.** Replace those with a single
`publish_class(course, section, page, include_linked)` and it produced the
correct call with correct arguments **8 times out of 8**, including parsing
`"Unit 2, Day 3"` with its comma intact and setting `include_linked: true`
from *"make sure every page it links to is published"*.

> **The model is a router, not a planner. Every unit of reasoning moved out of
> the model and into ordinary Python is a unit of reliability bought back.**

This is good news for the CSV-reschedule case, with one caveat in §5: the date
arithmetic, class renumbering and link rewriting are all deterministic code.
The model's only job is recognising "this is a reschedule, here is the file".

---

## 4. Where it fails — and why the design must assume it will

Routing accuracy of 100% on well-formed requests is not the whole story.
Adversarial probes (7 cases × 3 trials) scored **13/21**, and the failures are
more interesting than the number.

**It correctly refuses what it cannot do.** *"Delete the Unit 1 folder"* →
declined 3/3, because no delete tool exists. *"What's the weather tomorrow?"*
→ declined 3/3. Typos and texting-style phrasing (*"publsh tomorows class for
mcv4u sec 1"*) routed correctly 3/3.

**But it strongly prefers acting over declining.** *"Can you clean up my
course?"* — which names no course at all — produced
`back_up_course(course="MCV4U")` on every attempt. **It invented a course
code.** Backing up is harmless, so the damage here is nil; the behaviour is
not.

**And polarity can invert.** This is the serious one:

> *"Hide tomorrow's class again in SNC1W — the page is Ohm's Law."*
> → `publish_class(course="SNC1W", section=1, page="Ohm's Law", include_linked=true)`

The teacher asked to **hide** a page. The model chose to **publish** it, and to
publish everything it links to. In a classroom that is the difference between a
test still being drafted and a test students can read. The same prompt chose
`set_draft` correctly on an earlier run, so this is **inconsistent, not
deterministic** — which is worse, because it cannot be tested away.

### What that implies, concretely

1. **No destructive tool may be exposed to the model. Ever.** The model
   declines what it has no tool for — so simply never give it deletion,
   overwriting, or archiving. That single rule converts most misfires into
   harmless ones, and it is why *"delete the Unit 1 folder"* was safe.
2. **Nothing writes without confirmation.** The model's output is a *proposal*.
   Plantoir shows it in plain words — "Publish **Ohm's Law** and the 3 pages it
   links to, in **SNC1W Section 1**?" — and nothing happens until the teacher
   agrees. The hide/publish inversion is caught by a teacher reading one
   sentence.
3. **Validate every named entity against reality** before showing the
   proposal. A course code that does not exist in the working folder, or that
   appears nowhere in what the teacher typed, is a refusal — not a guess.
4. **Back up first.** Row 106 already built this. Any tool that writes more
   than one file calls `back_up_course` first, so "undo" is a real button.

Row 106 was built for exactly this scenario — *"teachers will be encouraged to
use an LLM for bulk edits, and an LLM can make a mess that is hard to undo"*.
That entry anticipated this feature.

---

## 5. What was **not** tested, and matters

Being straight about the gaps, because they are where the risk now sits:

- **The reschedule itself.** I tested that the model *routes* a CSV request to
  a `reschedule_classes` tool. I did **not** build that tool, and it is the
  hard part: parsing a teacher's real CSV (whatever columns they typed),
  matching rows to existing class pages, renumbering, and rewriting links
  without breaking the schedule invariant in `DEVELOPERS.md` (class pages'
  links *are* the schedule; every shared page inherits the date of the first
  class linking to it). **If the CSV is messy enough that the model has to
  interpret it, that is planning, and §3 says it will fail.** The honest
  scope is: the tool must accept a well-formed CSV, and Plantoir must show the
  teacher a table of "these dates will change" before touching anything.
- **A real vault.** Every test used synthetic prompts. Nothing ran against
  actual course files.
- **Long sessions.** All tests were single-turn. Multi-turn context growth,
  and whether routing degrades as the conversation fills, is unmeasured.
- **Model licensing.** Qwen2.5 is Apache 2.0, which is clean for a tool given
  away to teachers. Not verified in detail.
- **The download story.** Per the brief this is opt-in, so nothing ships in the
  base image. Roughly **1 GB** for the model, plus a runtime: the stock
  `llama.cpp:server` image is 1.21 GB, but a CPU-only build is a fraction of
  that and is what should actually ship.

---

## 5a. The built surface, re-measured against the same model

Everything above tested *hand-written* tool definitions. Once the server
existed, its real `tools/list` output was fed to the same Qwen2.5-1.5B in the
same capped container (4 GB, 2 CPUs, `--no-mmap`) — eight tools, ~1,580 prompt
tokens, 15 teacher-voice cases, 3 trials each.

**The two design changes did what they were meant to do.**

| | Before (hand-written tools) | After (the shipped surface) |
|---|---|---|
| Polarity inversions on *hide* | **1** (`publish_class`, `include_linked=true`) | **0 / 9** |
| Invented a course code | **3/3** on "clean up my course" | **0 / 3** |
| Malformed calls | 0 | **0 / 45** |
| Arguments needing type coercion | 0 | **0 / 45** |
| Wrong *write* proposed | — | **0 / 45** |

Splitting `publish`/`hide` into separate verbs removed the inversion entirely:
across nine hide trials in three phrasings, it never once reached for a publish
tool. And the invention failure was cured by something duller than expected —
*giving it a `list_courses` tool*. Asked to "clean up my course", it now looks
the courses up instead of making one up, 3 times out of 3.

**Raw routing "accuracy" fell to 31/45 (69%), and that number is misleading.**
All fourteen misses are the model calling a **read-only** tool: `list_pages` to
find the page it was asked about, or `list_courses`. Not one miss proposed a
write, a wrong page, or a destructive action. The failure mode moved from
*guessing* to *looking things up*, which is the direction you want it to move.

Two honest caveats about that 69%:

- **Every test is single-turn.** In a real client, `list_pages` would be turn
  one of two and the right call would follow. The harness scores turn one and
  stops, so it counts a sensible first step as a failure. The true multi-turn
  number is somewhere above 69% and was not measured.
- **"Decline" got rarer, and that is a real loss.** Asked to delete a folder,
  the model used to say it could not; now it calls `list_courses` instead.
  Nothing destructive happens either way — there is still no delete tool — but
  the teacher gets a course list rather than "I can't do that", which is worse
  manners. Steering for it belongs in the system prompt of whatever drives the
  server, not in the tool surface.

**Speed got worse, and the tool surface is why.** Warm requests ran 3–9 s
typical (a few at 18 s while the machine was also compiling), against 2–6 s
for the smaller hand-written set. Eight tools with prose descriptions cost
~1,580 prompt tokens versus ~600. Prompt caching still absorbs it after the
first call — the cold first request was 87 s — but **tool descriptions are not
free, and every tool added slows every request**. Worth remembering before
adding a ninth.

## 6. Recommendation

**Feasible, at about 1 GB and 2–6 seconds a request, with Qwen2.5-1.5B-Instruct
(Q4_K_M) on llama.cpp with `--no-mmap`.** It fits the 8 GB floor with room to
spare, it is fast enough to feel responsive, and on well-formed requests it was
perfect across 27 trials.

**On offline versus cloud — the brief asked me to recommend. Recommend
offline-only, and not as a compromise.** A local model is genuinely sufficient
for the routing job, which is the whole job under this architecture; the ceiling
that would justify a cloud fallback is one we should not be approaching anyway,
because it is the planning work that the design deliberately moves into Python.
Offline also removes an entire category of problem for the audience: teacher
course material can name students, and an Ontario teacher sending it to a
third-party API raises MFIPPA questions that no feature is worth. "It never
leaves your computer" is both true and a selling point. The MCP server should
still exist and be documented, so a power user can point their own assistant at
it — but that is their choice and their privacy trade, made explicitly.

**Suggested shape, in order:**

1. ~~**Build the MCP server first, with no model at all.**~~ **Done** —
   `windows-app/Plantoir.Mcp/`, commit `b3b7fc0`. Useful immediately for the
   bring-your-own-assistant path, testable with ordinary code, and it forced
   the tool surface to be right. Coarse tools, nothing destructive,
   everything validated. Publishing and hiding ended up as *separate tools*
   rather than one tool with a polarity flag — the §4 inversion made that
   choice for us.
2. **Add confirm-before-write in the app** — the proposal panel, in Plantoir's
   plain-words voice, with a backup taken first.
3. **Only then embed the model**, opt-in, downloaded on first use.
4. Leave the CSV reschedule until 1–3 are solid, and design its tool to take a
   *well-formed* CSV, showing a diff table before it writes.

The thing to hold onto: this works because the model is doing something small.
Every time the design asks it to do something bigger, the measurements say it
will get it wrong — quietly, and about a third of the time.
