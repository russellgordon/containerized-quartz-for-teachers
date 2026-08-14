# AI Assist — what we built, what worked, what didn't

*Windows side, 2026-08-14, branch `ai-assist`. A handoff: the goal, the
strategy, the measurements, and — at greater length, because they are worth
more — the things that went wrong and why.*

> Read [`AI-ASSIST.md`](AI-ASSIST.md) first for the feasibility work that
> preceded this. It has the model comparison and the numbers that decided the
> architecture. This document is what happened when it was built.
>
> Nothing here is on `main` or in 1.0.

---

## 1. What we are trying to do

A teacher writes their course in Obsidian: a folder of Markdown, one page per
class, shared pages for concepts and tasks. Plantoir turns that into a
website, one per section.

Two jobs in that workflow are pure tedium, and they are the two teachers
actually complain about:

* **Dating.** A class page's `created:` date is what orders it on the site. A
  course rolled over to a new year needs every one of them moved onto the days
  that class actually meets — 26 pages, by hand, from a timetable spreadsheet.
* **Publishing.** Making tomorrow's class visible means flipping a flag on
  that page *and* on every page it links to, then checking nothing else broke.

The goal is a teacher saying **"publish tomorrow's class"** and it happening,
with a plan they read first.

The hard constraint is who the teacher is. They may have no AI account, no API
key, and no reliable internet — a Chromebook cart and a school firewall. So
the assistant has to run **on their own computer, offline**, and the model has
to be small enough to live inside the container budget Plantoir already has.

There is a second path for teachers who do have an account: the same tools are
driven by Claude Code (and shortly Gemini and ChatGPT) from the same menu. The
built-in assistant is the floor, not the ceiling.

---

## 2. The constraints, because they explain every decision

| Constraint | Value | Where it comes from |
|---|---|---|
| Container memory | **4 GB** | macOS pins Colima at `--memory 4` in every launcher; WSL2 takes ~half of an 8 GB machine |
| CPU | **2 cores, no GPU** | Same |
| Throughput | **~21 tokens/second** | Measured repeatedly on this hardware |
| Context | 16,384 tokens | Our choice; 8,192 proved too small (see §6) |
| Model | Qwen2.5-1.5B-Instruct Q4_K_M, 1,117,320,736 bytes | Measured winner in `AI-ASSIST.md` |
| `--no-mmap` | Mandatory | Without it a 3B "needed" 4 GB and died at 3 with `ExitCode=255`, `OOMKilled=false`, nothing in the log |

**21 tokens/second is the number that governs everything.** Every token of
tool definition is ~48 ms of a teacher's life, once per cold cache. Most of
what follows is a consequence of that single figure.

---

## 3. The architecture as built

```
Plantoir (WinUI 3)
  └─ AssistWindow          one section, its own window, chat bubbles
       ├─ LocalModel       llama.cpp in Docker-in-WSL2, Qwen2.5-1.5B
       ├─ McpClient        stdio JSON-RPC to plantoir-mcp
       └─ AssistAgent      the loop, and the approval gate

plantoir-mcp (console exe, ships beside the app)
  └─ PlantoirTools         34 tools over Plantoir.Core
                           ALSO what Claude Code drives
```

**One tool surface, two clients.** The built-in assistant and Claude Code
drive the same server. The safety rules live in the tools, so they cannot
drift between the two.

**The window is separate on purpose.** The teacher needs the section's preview
on screen while they talk about it. A pane inside the main window would put
the conversation and the thing it is about in competition for the same space.

---

## 4. The strategy, and the one finding it rests on

From `AI-ASSIST.md` §3, and it has held up under everything since:

> **The model is a router, not a planner. Every unit of reasoning moved out of
> the model and into ordinary code is a unit of reliability bought back.**

Given `resolve_links`, `set_draft` and `publish_section` separately, and asked
to publish tomorrow's class *and everything it links to*, the 3B model chose
`publish_section` **8 times out of 8** — skipping the link resolution
entirely. Perfectly consistent, and wrong. Given a single
`publish_class(course, section, page, include_linked)` that resolves links
itself, it was correct **8 out of 8**.

Everything else follows:

* **Coarse tools.** One call does the whole job. The link resolution, the
  date inheritance, the index update, the backup are ordinary testable C#.
* **Every write has a `plan_` twin** that changes nothing, written to be read
  aloud.
* **Publish and unpublish are separate verbs, never a boolean.** The one
  genuinely dangerous failure observed was polarity inversion: asked to HIDE a
  page, the model called publish with "include everything it links to" set. A
  boolean is a coin flip under pressure; a verb is not.
* **Nothing destructive exists.** No delete, no rename, no archive. The model
  reliably declined "delete the Unit 1 folder" — not from judgement, but
  because it had no tool for it. Absence is the strongest guardrail available.
* **The approval gate reads the server, not a list.** Every non-read-only tool
  waits for a button. Derived from the server's own `readOnlyHint` — see §6
  for why a hand-maintained list was a bad idea.

---

## 5. What worked

**The tools.** Verified live against real courses: re-dating 26 classes onto a
real timetable (checked against the teacher's own spreadsheet with an
independent parser), a course rollover, per-section publishing byte-verified
by MD5, undo, and backups before every write. This half is solid.

**The vocabulary split.** `publish:` decides whether a page is built into the
site; **deploy** sends the built site to Netlify/Cloudflare/a folder. One word
for both had the assistant and the teacher meaning different things by "I
published tomorrow's class". The briefing explains it in four sentences at the
top of every conversation.

**Trimming the tool surface.** The single most effective change:

| Surface | Tools | Tokens | Cold read @ 21 tok/s |
|---|---|---|---|
| Everything (Claude Code) | 34 | 9,032 | 430s |
| Local model, trimmed | 15 | 2,783 | 133s |

Fewer tools is **better routing and a shorter prompt at once** — accuracy and
speed are the same dial, not a trade-off. Descriptions sent to the local model
are also cut to what a router needs (trigger phrasings + one sentence); the
rest is instruction for Claude, and the local model does not need to be
trusted with it because the approval gate enforces it in code.

**Teachers' own words in the descriptions.** See §6 for the failure that
motivated this.

**Prompt cache warming, once it primed the right thing.** After a matched
warm-up a real turn takes **1.8s**. That is the target hit.

---

## 6. What did not work, and why

This is the useful half. Most of these were found by testing, and several were
introduced by the fix for the previous one.

### 6.1 Routing collapses as the surface grows

The investigation measured 27/27 on a **five-tool** surface. Re-measured
against the **shipped** surface (`research/ai-assist/shipped-surface-suite.py`):
**31/45, 69%**. The failures are exactly the phrasings a teacher uses:

| Probe | Result |
|---|---|
| "Publish tomorrow's class… also make sure every page it links to is published" | 3/3 ✅ |
| **"Put up Unit 3, Day 2… along with everything it points at"** | **0/3 ❌** → `list_pages` |
| "Hide tomorrow's class again — the page is 'Ohm's Law'" | 3/3 ✅ |
| **"Take Unit 4, Day 5 back down, students shouldn't see it yet"** | **0/3 ❌** → `list_pages` |
| "I posted Unit 2, Day 3 by mistake. Make it a draft again" | 3/3 ✅ |

Precise phrasing works. Colloquial phrasing falls through to a browse tool —
safe, but useless. **Mitigation so far:** the trigger phrasings are written
into the tool descriptions verbatim (`TEACHERS SAY: "put up…", "take back
down…"`), and the window opens with a menu of wordings that work. **Not
re-measured since.** That is the most valuable open experiment.

### 6.2 WSL2 kills the container, and the fix for the leak reintroduced it

Worth reading twice, because it happened **three times**.

The container is started detached (`docker run -d`). WSL2 shuts the distro
down when no session holds it open — taking dockerd and every container with
it. Symptom: the model loads, answers a health check, reports Ready, and dies
~25 seconds later mid-answer. The app reports *"an error occurred while
sending the request"*, which points at the network and has nothing to do with
it — Windows reaches the container on `127.0.0.1` perfectly well while it is
alive.

1. **Fixed** by holding a WSL session open for the life of the conversation.
2. **Then four keepalives leaked** — they slept blindly for six hours and
   relied on being killed, and the window's shutdown fired that kill on a
   background task and returned, so closing the app could beat it.
3. **The leak fix reintroduced the original bug.** The keepalive was changed
   to watch the container and exit when it vanishes — but it starts *before*
   `docker run`, so on its first tick it saw nothing and exited immediately.

Now: sleeps first, leaves only once the container has been **seen and then
gone**, gives up after five minutes if it never appears. Verified alive at 20,
40, 60, 90 and 120 seconds, polled from Windows alone.

> Nothing else in the toolchain hits this, because the preview and deploy
> launchers stay attached to their container for the whole run. Only a
> detached, long-lived container needs the door held open.

### 6.3 The warm-up warmed a prompt nothing used

The worst one, because it looked like it was working.

The warm-up primed `[tools] + "Say ready."` with **no system message**. Every
real turn sends `[tools] + [system prompt] + text`, and llama.cpp renders
tools and system prompt into the same leading block — so the two prefixes
diverge almost at the first token. Three minutes spent, nothing cached that
any conversation would ask for, and the teacher paid again.

Measured on a fresh server:

| | warm-up | then a real turn |
|---|---|---|
| Without the system message | 20.7s | **29.6s** — paid in full, again |
| With it | 29.0s | **1.8s** |

**Sixteen times**, on a prefix far smaller than the real one.

> A test of a cache is order-dependent. The first attempt ran the matched case
> first, which cached the prefix and made the mismatched case look fast. The
> order of the test was part of the test.

### 6.4 llama.cpp's progress logging is too sparse to drive a bar

It reports `prompt processing … progress = 0.33` — but only once per completed
batch. Measured against a real prompt: **nothing for 81 seconds, one reading
of 32%, then silence** until the answer arrived. A bar driven by that sits at
zero, jumps a third of the way, and freezes — worse than no bar, because it
looks like a fault.

The bar is now **projected** from measured constants (~3.6 chars/token, ~21
tok/s) against the actual schema size, and corrected by a real reading
whenever one appears. Verified accurate: it predicted 2m 53s; the teacher saw
97% at 2m 48s.

### 6.5 Interface failures that measurement would not have caught

* **A progress bar that never entered the visual tree.** Added to
  `body.Parent as StackPanel`; `Parent` is not reliably set the instant an
  element joins a `Children` collection, so it went nowhere. The download ran
  showing the one frozen line the bar existed to replace.
* **Sixty seconds of a still window.** No thinking indicator at all. Silence
  and a crash look identical; a teacher who cannot tell them apart closes the
  window. Now: animated dots plus an elapsed count after five seconds.
* **"Ready." said before a three-minute wait.** The one line meant to orient a
  teacher, misleading them by three minutes.
* **Model-directed text shown to a teacher.** `explain_publishing` answers a
  returning section with *"this has been explained already — don't repeat it,
  carry on with what the teacher asked"*. That is addressed to a **model**,
  and the window printed it verbatim.
* **Markdown rendered as punctuation.** `TextBlock.Text` shows `**bold**`
  literally, so the emphasis in the most important sentence in the window
  arrived as asterisks.

### 6.6 Bigger models are not obviously the answer

Researched but **not measured here** (2026-08):

* **Qwen3-1.7B — 55.49% on BFCL.** Worse than what we run.
* **Qwen3.5-4B — 97.5%** in one practical eval, Q4_K_M is 2.74 GB. Fits the
  memory budget, but ~2.5× the parameters at 21 tok/s makes a cold read
  intolerable.
* **xLAM-2 and Hammer 2.1** top the Berkeley leaderboard at their sizes, yet
  scored **15%** and **20%** in a practical eval — attributed to **chat
  template incompatibility**, not model quality. Leaderboard position is a
  poor proxy for "works in llama.cpp with `--jinja`".

**Speed is the binding constraint before accuracy is.** Trimming the surface
helps both; a bigger model helps one and hurts the other.

### 6.7 Smaller traps worth knowing

* **Context.** A 18,030-token prompt was **refused outright** against a 16,384
  context. The untrimmed surface plus a real conversation was heading there.
* **`--parallel`.** The image now defaults to **four** slots, so `-c 8192`
  quietly allocated 32,768 tokens of KV cache. One window is one conversation:
  `--parallel 1`.
* **`schtasks` date format is locale-dependent** and rejects every other one.
  This machine wanted `yyyy/MM/dd`, not the documented `dd/MM/yyyy`. The code
  tries formats until Windows accepts one.
* **Deprecation.** `--no-mmap` now warns in favour of `--load-mode`. Still
  works; changing it is untested.

---

## 7. Where it stands, and what is unproven

**Working and verified:** the tool layer, the approval gate, publish/unpublish
polarity, undo, backups, per-section isolation, scheduled deploys (verified
firing unattended with Plantoir closed), the sidebar clock badge, the
container lifecycle, the download and its progress bar, the warm-up bar's
accuracy.

**Unproven, in the order I would test them:**

1. **Does a disk-cache restore actually skip the warm-up?**
   `--slot-save-path` is wired up and the save call works, but a restore has
   never been observed shortening a session. If it works, the three minutes is
   paid once ever rather than once per session. This is the biggest single win
   available.
2. **Is a real warm turn under ten seconds on the FULL 2,783-token prefix?**
   1.8s was measured on a smaller synthetic prefix. The real one is untimed.
3. **Did the phrasing work fix the 69%?** Re-run
   `research/ai-assist/shipped-surface-suite.py` against the trimmed
   11-or-15-tool surface. Nobody has.
4. **Class insertion against a real course.** Renaming classes rewrites links
   across a 132-page course; the tests use four synthetic classes.

---

## 8. If you change one thing

**Re-measure the routing.** §6.1 is the only failure that is about the *idea*
rather than the plumbing, and the mitigation is unverified. Everything else
here is engineering that can be fixed by engineering.

If routing is still poor after the phrasing work, the levers in order of
expected value:

1. **Trim further** — 15 tools is not a floor. Publish, unpublish, plan, undo,
   rebuild is arguably six.
2. **A two-stage router** — one small call to pick a *category*, then a second
   with only that category's tools. Two short prompts beat one long one when
   prompt length is the cost.
3. **Only then, a different model** — and measure it in llama.cpp with
   `--jinja`, not on a leaderboard.

## 9. Rules that earned their place

* **Measure before believing, and measure the thing itself.** Reasoning
  produced "60 seconds of a dead window", a bar that could never move, and a
  warm-up that warmed nothing. Every one was found by running it.
* **Never withhold a capability as a safety mechanism.** Deploying was trimmed
  out of the local surface for speed, which silently removed a feature the
  teacher had asked for by name. The approval gate is the safety mechanism.
* **A promise the tools do not keep is worse than jargon.** The briefing said
  "I never deploy" after deploy went back in. A teacher who believes it will
  not think to check.
* **Tests pin meaning, not sentences** — but when they pin a sentence, the
  sentence is user-facing and the pin is the point.
