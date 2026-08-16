# The assistant contract — what both apps must agree on

Two JSON files, both **generated from the macOS app** and both read by the
Windows test suite. They exist so that "implement what changed on the mac"
ends in a green Windows suite instead of a day of clicking.

| File | What it holds |
|---|---|
| [`assist-wording.json`](assist-wording.json) | Every sentence the assistant says to a teacher about deploying, previewing and agreeing to things, with `{course}` and `{section}` where values go. |
| [`assist-cases.json`](assist-cases.json) | The behaviour: which phrasings are matched in code rather than routed, which tools wait for a button, which tools the local model is shown, and what must happen in what ORDER when the assistant deploys. |

## What is generated and what is written by hand

`assist-wording.json` is generated in full. `assist-cases.json` is mixed, and
the boundary is a TOP-LEVEL key — the file names them under `generated.keys`:

| Key | Comes from |
|---|---|
| `cardPhrasings` | `AssistCardCommand.fixedShapes` |
| `tools` | `AssistToolRunner.tools` / `.localTools` / `.mcpOnlyTools`, and each definition's `needsApproval` and `planTwinName` |
| `nearMisses`, `scenarios` | **Hand-written intent.** The generator preserves them; nothing in the code says what a near miss is, or what ORDER events must happen in — those are decisions, and decisions are why this repository has handoff documents. |

## Regenerating

```bash
Plantoir --assist-contract contracts
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

Two things NOT to take from here, because they are genuinely per-platform:

- **How the preview is stopped and started.** WSL2, ConPTY and the preview
  leases have real Windows mechanics; `assist-cases.json` says the ORDER the
  events must occur in, not how to make them happen.
- **Anything the model decides.** Routing accuracy is measured, not asserted —
  see [`research/README.md`](../research/README.md). A contract can say that
  "deploy now" never reaches the model; it cannot say what the model would do
  with a sentence it does reach.

## The rule this exists to enforce

A sentence a teacher reads is a specification. Kept in the Swift that says it,
the Swift test that pins it, `GUI-IMPROVEMENTS.md` where it is specified and
`WINDOWS-HANDOFF.md` where Windows is told to copy it, it is four copies and
three of them were already drifting — the same deploy failure was told two ways
("that section's console" / "that section's window") depending only on which
function ran it. Now it is written once in `AssistWording`, and everything else
is generated from it or tested against it.
