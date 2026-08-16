# The assistant contract — what both apps must agree on

Two JSON files, both **generated from the macOS app** and both read by the
Windows test suite. They exist so that "implement what changed on the mac"
ends in a green Windows suite instead of a day of clicking.

| File | What it holds |
|---|---|
| [`assist-wording.json`](assist-wording.json) | Every sentence the assistant says to a teacher about deploying, previewing and agreeing to things, with `{course}` and `{section}` where values go. |
| [`assist-cases.json`](assist-cases.json) | The behaviour: which phrasings are matched in code rather than routed, which tools wait for a button, which tools the local model is shown, and what must happen in what ORDER when the assistant deploys. |
| [`class-planning.json`](class-planning.json) | Which page titles carry numbers, what "the next class" would be called, and — the highest-stakes data here — the ORDER renames must run in when room is made for a class. |
| [`schedule-rules.json`](schedule-rules.json) | How a teacher's own list of class dates is read: every accepted date form, how an ambiguous `08/09/2026` column is settled or asked about, and what a pasted Google Sheet address becomes. |
| [`app-rules.json`](app-rules.json) | Everything outside the assistant: what `deploy.sh` is asked to do for a given configuration, what a teacher is told about an Account ID or a custom domain they typed, the progress markers and **where each marker's text comes from**, and the preview's ports. |

## What is generated and what is written by hand

`assist-wording.json` is generated in full. `assist-cases.json` is mixed, and
the boundary is a TOP-LEVEL key — the file names them under `generated.keys`:

| Key | Comes from |
|---|---|
| `cardPhrasings` | `AssistCardCommand.fixedShapes` |
| `tools` | `AssistToolRunner.tools` / `.localTools` / `.mcpOnlyTools`, and each definition's `needsApproval` and `planTwinName` |
| `nearMisses`, `scenarios` | **Hand-written intent.** The generator preserves them; nothing in the code says what a near miss is, or what ORDER events must happen in — those are decisions, and decisions are why this repository has handoff documents. |

In `app-rules.json` the same split applies: `milestones` is a readout of
`TaskMilestones` and is overwritten; `deployArguments`, `configurationRules`,
`previewPorts` and `markerOrigins` are authored and preserved. The rule behind
the split is worth stating once — **a readout of the code cannot fail when the
code changes**, so anything that must catch a regression is written by hand and
executed against the real function.

### The one in `app-rules.json` that is easiest to get wrong

`markerOrigins` says, for every progress marker, where its text actually comes
from. It decides whether your app must match the string exactly:

- **`shared-python`** — printed by `scripts/*.py`, identical output on both
  platforms. Match it to the character. Seventeen of the twenty-five are these.
- **`launcher`** — printed by `setup.sh` / `preview.sh` / `deploy.sh`, which
  have separately written `.ps1` counterparts. These **deliberately differ**:
  the mac watches for "Setting up this Mac" and Windows for "Setting up this
  PC". Seven of the twenty-five.
- **`elsewhere`** — printed by the Docker build or a tool; check by hand.

A mac test verifies the classification against the actual files, so a marker
that moves from a launcher into shared Python (or the reverse) fails here
rather than silently changing what Windows should be matching. Getting this
wrong crashes nothing: the progress bar simply stops moving, which reads as a
slow build.

## Regenerating

```bash
Plantoir --write-contracts contracts
```

The bundled binary writes both files from the app's own types — `AssistWording`,
`AssistCardCommand`, `AssistToolSurface`. `AssistContractTests` runs the same
generator in-process and fails when what is committed no longer matches, naming
that command. **So a changed sentence fails on the mac first**, in the same run
that changed it, and arrives on the Windows side as a diff in this folder
rather than as a bug report from a teacher.

## Why these are not in `support/`

`support/` is bundled into the app and mirrored into every teacher's working
folder as `.toolchain/`. Test data does not belong in a teacher's course folder,
and anything put there gets copied to every machine that runs a build.

## Reading them from the Windows suite

Both files are plain data — an xUnit `[Theory]` with a `MemberData` source that
deserialises the JSON is the whole integration. Nothing here is macOS-specific:
the sentences are the product's, and the sequences are the toolchain's.

The full list of what the contract cannot cover — and therefore what each side
still tests for itself — is in
[`WINDOWS-HANDOFF.md`](../WINDOWS-HANDOFF.md), under "Do not re-derive the
assistant's tests". Two of them matter enough to repeat:

- **How the preview is stopped and started.** WSL2, ConPTY and the preview
  leases have real Windows mechanics; `assist-cases.json` says the ORDER the
  events must occur in, not how to make them happen.
- **Anything the model decides.** Routing accuracy is measured, not asserted —
  see [`research/README.md`](../research/README.md). A contract can say that
  "deploy now" never reaches the model; it cannot say what the model would do
  with a sentence it does reach.

## Coverage: every mac test file, and where it stands

No stone unturned — this table is the audit, and a file missing from it is a
gap nobody has looked at. Counts are test functions, taken 2026-08-16.

**Shared through a contract** (the Windows suite can run the same cases):

| Area | Contract | Mac tests it draws on |
|---|---|---|
| The assistant's sentences | `assist-wording.json` | AssistToolRunner, AssistAgent |
| Deploy/preview order, cards, cancels | `assist-cases.json` → `scenarios` | AssistToolRunner (49), AssistScenario |
| Card phrasings and near misses | `assist-cases.json` → `cardPhrasings` | AssistAgent (8) |
| Tool lists, approvals, plan twins | `assist-cases.json` → `tools` | AssistToolRunner |
| Arrow-key history | `assist-cases.json` → `promptHistory` | AssistPromptHistory (15) |
| Launcher arguments | `app-rules.json` → `deployArguments` | CloudflareDeploy (13) |
| Validation messages | `app-rules.json` → `configurationRules` | CourseConfiguration (10), CustomDomain (4) |
| Progress milestones and marker origins | `app-rules.json` → `milestones`, `markerOrigins` | TaskMilestone (12) |
| Failure explanations | `app-rules.json` → `failureExplanations` | FailureExplainer (8) |
| Whether a deploy must build first | `app-rules.json` → `buildFreshness` | BuildFreshness (6) |
| Preview ports and the websocket offset | `app-rules.json` → `previewPorts` | PreviewLease (7) |
| The browser-safe address | `app-rules.json` → `linkRules` | BrowserSafeURL (2) |
| Reading a teacher's date list | `schedule-rules.json` | SectionScheduleSource (23) |
| Naming, numbering, making room | `class-planning.json` | ClassPlanning (13), NextClass (13) |

**Not shared, and why.** Each of these is a deliberate decision, not an
oversight:

| Area | Tests | Why it stays local |
|---|---|---|
| Windows, sheets, layout, hit areas, fonts, chat bubbles | ~71 | Platform look and feel. The mac's numbers were measured against Messages; matching them on WinUI would produce something that looks foreign. What must be TRUE of the assistant's window is in `WINDOWS-HANDOFF.md`. |
| Script runner and preview stopper mechanics | 34 + 2 | ConPTY against a pseudo-terminal, WSL2 against Colima. The OUTPUT they parse is shared (see `markerOrigins`); the machinery is not. |
| Scheduled deploys | 23 | launchd against Task Scheduler — nothing about the mechanism ports. The plan's REFUSALS (a section never deployed cannot be scheduled) are worth mirroring by hand. |
| Model tiers, plan mode, activity | 30 | Measured on this hardware. See `research/`; a tier ladder measured on an M4 Pro says nothing about a teacher's laptop with integrated graphics. |
| Backup, archive, restore | 26 | Portable in principle — the naming and pruning rules are ordinary logic. **Next candidate.** Not yet done. |
| Example content, skeletons, course names | 25 | Both apps read the SAME files under `support/`. The data is its own contract; run the same validity checks against it rather than copying expectations here. |
| Workspace initialisation, folder containers | 18 | Filesystem shapes that differ (`~/Library/Application Support` against `%LOCALAPPDATA%`). |
| Section adding and numbering | 21 | Partly shared through `configurationRules`; the rest writes files and is worth mirroring by hand. |
| Curriculum mentions, section restore | 19 | MCP-only tools and section-scoped restore — no Windows counterpart yet. |
| Sidebar filtering, transcript building, console focus | 20 | Small and local; port if the behaviour is ever questioned. |

## The rule this exists to enforce

A sentence a teacher reads is a specification. Kept in the Swift that says it,
the Swift test that pins it, `GUI-IMPROVEMENTS.md` where it is specified and
`WINDOWS-HANDOFF.md` where Windows is told to copy it, it is four copies and
three of them were already drifting — the same deploy failure was told two ways
("that section's console" / "that section's window") depending only on which
function ran it. Now it is written once in `AssistWording`, and everything else
is generated from it or tested against it.
