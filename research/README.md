# research/

Measurement records. Nothing here runs automatically and nothing here is a
gate — these are the files the code points at when a comment says a decision
was measured rather than reasoned. Two rules keep them useful:

1. **Every results file states its own conditions in its header** — hardware,
   engine build, flags, model, surface, trial count. A number without those is
   not a finding.
2. **Superseded runs are marked, not deleted.** A later run that reversed an
   earlier one is the most valuable thing in here, and it only reads that way
   if both are present.

## `ai-assist/` — the local assistant

Why the assistant is built the way it is: which models were tried, which were
vetoed and for what, and what the flags cost.

**Read these first**

| File | What it settles |
|---|---|
| `HISTORY.md` | The narrative: the feasibility investigation, the build handoff, and the original MCP proposal, merged with a status block saying what has since been overturned. |
| `macos-native-10-trial-comparison.txt` | **The model decision.** Ten models × 29 probes × 10 trials on one identical tool surface. The source of the 3B veto (two unrelated families inverting on the same sentence), and of Qwen3-4B replacing the 7B. Cited from `AssistModelTier.swift`. |
| `reasoning-flag-measurement.txt` | Why thinking must be turned off with **two** flags, and why the fault hid for days: llama.cpp parses the thinking out of the reply, so only the token count and the clock show it. |
| `thirteen-tool-surface-results.txt` | The **current** shipping surface, 42 probes × 10 trials on both tiers. Also records the description-steer regression: fixing one probe in a tool description broke three others. |

**Earlier runs, superseded but kept**

| File | Superseded by |
|---|---|
| `macos-native-results.txt` | The 10-trial comparison — it says so at the end. Three trials per probe, and the 3B veto it reported at 2-of-3 turned out to be 9-of-10. |
| `twenty-tool-surface-results.txt` | `thirteen-tool-surface-results.txt`. Measured the 20-tool surface, which is what the MCP client sees but not what the local model is shown. |
| `trimmed-surface-results.txt`, `shipped-surface-results.txt`, `promise-card-results.txt`, `cache-restore-results.txt` | Windows-side, in-container runs. The prompt-cache save/restore work in the last one is what running the model natively made unnecessary. |

**The harnesses** — `trimmed-surface-suite.py` (the 29-probe suite the
Windows-comparable numbers come from), `shipped-surface-suite.py`,
`routing-suite.py`, `adversarial-suite.py`, `narrow-tools.py` (the real
narrowing code, so a surface under test is the shipped one), and two
PowerShell helpers for dumping a live tool list. The 42-probe suite that
produced the newest results file was not committed; its results were.

**To re-run any of it**: start `llama-server` by hand with the flags in the
results file's header, point the suite at it, and compare like for like — the
probe set and the tool surface both have to match, or the numbers mean nothing.
A change to a tool, a tool description, a model, a quant or a context size is a
reason to re-run.

## Sources kept in the repository

| File | What it is, and why it is still here |
|---|---|
| [`../dcp.html`](../dcp.html) | A saved copy of Ontario's **Curriculum and Resources** site (`dcp.edu.gov.on.ca`), taken 2026-08-14. It is the source the CHC2D payload's expectations were transcribed from, and where the half-credit work came from — Career Studies and Civics are 55 hours each and taken back to back, which the linter's hard-coded 110 hours and the installer's fixed September anchor both got wrong. **6.4 MB, and it earns its place only while payloads are still being written**: the rule in this repository is that curriculum text is transcribed verbatim or not at all, and a live site cannot be quoted from six months later when it has changed. If payload work stops, this can go. |

Recorded 2026-08-16 after a sweep found it tracked, six megabytes, and
mentioned in no document at all — which is how a file becomes something nobody
dares delete and nobody can explain.

## `preview-staleness/`

`FINDINGS.md` — why a preview could show the page as it was before an edit:
what is established, what is assumed, and the hypothesis to test first. It also
carries a platform-independent finding worth knowing before building anything
on a file watcher: **a Colima or WSL2 bind mount does not deliver file events
for host-side writes**, so an in-container watcher never sees the teacher's
edit. Cited from `.claude/skills/mac-app/SKILL.md`.
