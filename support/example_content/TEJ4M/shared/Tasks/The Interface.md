---
title: The Interface
draft: false
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> In pairs · launched in Unit 2, due at the end of it · a real
> peripheral, working, on a bus you designed · with scope evidence that
> the signals are healthy and not merely lucky

## What you are making

A microcontroller talking to a peripheral it was not sold with — a
sensor, a display, an expander, a converter — brought up from its
datasheet rather than from an example program somebody else wrote.

Getting it to answer is roughly half the task. The other half is
proving, with captured traces, that it will *keep* answering: correct
logic levels at both ends, rise times inside the specification, a clean
acknowledgement, and a signal that survives the wire length your device
would actually use.

You are not being assessed on picking a difficult peripheral. You are
being assessed on evidence.

## Milestones

- [ ] **Datasheet reading**, submitted before wiring: the supply range,
      the absolute maximum input voltage, the logic levels, the
      address or chip-select arrangement, and the timing diagram with
      the numbers you will need circled.
- [ ] **Interface plan**: a schematic of your connection, including
      pull-up values with the rise-time calculation behind them, and
      level translation if the two devices disagree about voltage.
- [ ] **First transaction**, captured on the logic analyzer, with every
      field labelled — address, direction, acknowledgement, data.
- [ ] **Working read or write**, in code kept in version control from
      the first commit, structured as
      [[Talking to a Peripheral]] describes.
- [ ] **Signal integrity evidence**: scope captures of the rise time at
      your chosen pull-up value, at the shortest and longest wiring you
      tested, with the measurements marked on the traces.
- [ ] **Stress test**: the wire length, bus speed, or supply voltage at
      which it stops working, and the trace at the moment it fails.
- [ ] **Handover note**: one page telling the next person what is
      connected where, what the pull-ups are, and what not to change.

## How it is assessed

The criteria table, weighted as [[How Marks Work]] sets out. This task
rewards the pair whose evidence is complete over the pair whose device
is impressive. A working display with no traces scores below a working
sensor with four labelled captures and a documented breaking point.

Growth is assessed from your [[Tech Journal]]. The bring-up will not go
smoothly — nobody's does — and the journal is where the wrong
assumptions get recorded as they happen: the pin you had backwards, the
address you read from the wrong table, the pull-up you inherited from a
tutorial without checking. An entry written at the bench at the moment
of confusion is worth five written afterwards from memory.

Safety is part of the assessment, not beside it. Levels checked before
connection, supply limits set first, and no probing a powered board with
loose leads. That standard is in [[Safety in the Lab]] and it does not
relax because the voltages are small.

## Success criteria

| Quality | What it looks like at your bench |
| --- | --- |
| Read from the source | The datasheet, not a tutorial, decides every connection |
| Levels verified before power | Both devices' limits written down and compared |
| Calculated pull-ups | The value follows from a rise-time calculation you can show |
| Labelled captures | Address, direction, acknowledgement, and data all identified |
| A documented breaking point | You know where it fails, and you have the trace |
| Code somebody could maintain | Named constants, one place for pin numbers, in version control |
| An honest handover note | A stranger could rewire it correctly from your page alone |
| Recorded reasoning | The journal shows what you assumed and what corrected you |

> [!example]- What "scope evidence" actually means here
> Not a photograph of a screen with a squiggle on it. A capture with
> the timebase and voltage scale visible, the measurement cursors
> placed, and a caption in your own words: *"Clock line rise time,
> $30\%$ to $70\%$, $4.7\ \text{k}\Omega$ pull-ups, $300\ \text{mm}$ of
> ribbon cable: $0.9\ \mu\text{s}$, inside the $1\ \mu\text{s}$ limit
> with little to spare — which is why the final build uses
> $2.2\ \text{k}\Omega$."* One capture like that is worth a folder of
> screenshots, because it states a number, a condition, and a decision.

%%curriculum-start%%
## Curriculum connection

![[A2.4]]

![[A3.2]]

![[B1.3]]

![[B3.4]]

![[A5.1]]

![[D1.1]]
%%curriculum-end%%
