---
title: The Specification
publish: true
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Individually · launched in Unit 1 and due at the end of it · a written
> specification for a device you do **not** build · assessed on whether
> somebody else could build it and prove it works

## What you are making

A document. That is the whole task, and it is deliberately
uncomfortable: for two years the evidence of your learning has been
something on a bench, and this time it is six or seven pages that
somebody else could build from without asking you a single question.

Choose a small device — a bench tool, a monitor for something in your
house, a fix for an annoyance in this shop. Then write the specification
a manufacturer would need: what it must do, the conditions it must do it
in, the interfaces it presents to the world, the components you have
selected and why, and the acceptance tests that decide whether a built
unit passes or fails.

The rule that makes this hard: **every requirement must be testable**.
"Reliable" is not a requirement. "Operates continuously for
$72\ \text{h}$ at $40\ ^\circ\text{C}$ ambient without exceeding
$70\ ^\circ\text{C}$ on any component surface" is a requirement, and you
can already see how it would be checked.

## Milestones

- [ ] **The sentence.** One sentence naming what the device does and
      for whom. Written first, changed as often as you like, never
      skipped.
- [ ] **Block diagram**, with every arrow labelled by what travels
      along it — volts, bits, or watts.
- [ ] **Requirements list**, numbered, every entry testable, split into
      what the device must do and the conditions it must survive.
- [ ] **Interfaces**, stated precisely: supply voltage and current
      range, connector, signal levels, protocol, and what happens when
      each one is connected wrongly.
- [ ] **Component selection** for at least four parts, each with a real
      part number, a datasheet reference, and the calculation or the
      tolerance figure that justified it.
- [ ] **Power budget**, as a table: every block, its current, and the
      total with margin stated.
- [ ] **Acceptance tests** — a numbered procedure another person could
      run with our bench equipment, each with a pass criterion in
      numbers.
- [ ] **Peer build check**: another bench runs your acceptance tests as
      written and reports what they could not do.

## How it is assessed

The criteria table below, weighted as [[How Marks Work]] sets out. Two
things worth saying plainly.

First, this is assessed as growth, not as a first attempt. The version
that counts is the one after your peer check, and the evidence of your
thinking between those two versions belongs in your [[Tech Journal]] —
what somebody could not do with your document, what you had assumed, and
what you rewrote. A specification that improved for stated reasons
outscores one that was tidy from the beginning.

Second, false precision costs you marks. A number you cannot source is
worse than an honest range: if a datasheet gives a figure, cite it; if
your figure came from a calculation, show it; if you are estimating,
label the estimate and say what you would measure to replace it. That
habit is the whole of [[Reading a Datasheet Like an Engineer]].

## Success criteria

| Quality | What it looks like in your document |
| --- | --- |
| One clear job | The opening sentence names a device, a person, and a difficulty |
| Testable requirements | Every requirement has a number, a unit, and a condition |
| Honest interfaces | Voltages, connectors, and protocols stated, including failure cases |
| Justified components | Real part numbers, with the calculation or tolerance that chose them |
| A power budget that adds up | Every block accounted for, margin stated as a figure |
| Runnable acceptance tests | Another bench ran them without asking you anything |
| Sourced numbers | Datasheet figures cited, calculations shown, estimates labelled |
| Evidence of revision | The journal shows what changed after the peer check, and why |

> [!warning]- If you cannot decide what to specify
> Pick the smallest annoyance you have personally experienced this
> month, and specify the device that removes it. A cable that keeps
> falling off a bench, a plant nobody remembers to water, a door that
> gets left open. Small and real beats large and imagined every time,
> because a real annoyance comes with real conditions attached —
> temperature, duty cycle, who has to use it — and those conditions are
> most of what a specification is made of. If you are still stuck after
> ten minutes, that is a [[Getting Unstuck]] situation, and the
> procedure there applies to writing as much as to circuits.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.5]]

![[B3.1]]

![[D3.3]]

![[B2.1]]

![[D2.2]]
%%curriculum-end%%
