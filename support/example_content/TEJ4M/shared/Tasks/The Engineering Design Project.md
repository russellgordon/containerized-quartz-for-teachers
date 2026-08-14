---
title: The Engineering Design Project
draft: false
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Individually or in pairs · the final block of the course · a device
> nobody specified for you, designed, built, documented, and defended ·
> demonstrated at [[The Engineering Review]]

## What you are making

An original device that solves a problem you chose, built from the three
years of this shop: circuitry you calculated, an interface you brought
up from a datasheet, and embedded code somebody else could maintain.

Everything you built before this was a job handed to you. This one
starts with a problem you found and a proposal you had to defend, and it
ends with a handover package — because in this trade a device that only
its maker can service is not finished, it is a hostage.

Scope it honestly. A device that does one job dependably, measured,
documented, and defended, beats an ambitious pile of wires every time.
The proposal stage exists so that somebody can tell you that before you
spend three weeks finding out.

## Milestones

- [ ] **Proposal**, in writing, at launch: the problem in one sentence;
      who has it; a block diagram; a parts list with real part numbers
      and prices; the three things most likely to go wrong; and the
      test plan that will prove the device works.
- [ ] **Specification**, in the form you learned in Unit 1 — testable
      requirements, interfaces, a power budget, and acceptance tests.
      This is where [[The Specification]] stops being an exercise.
- [ ] **Design review**, at your bench, with your calculations and
      budget open. The questions come from the published list in
      [[The Engineering Review]]; none of them is a surprise.
- [ ] **Schematic and state diagram** before the first component is
      soldered, with derating figures marked on the parts that carry
      real current.
- [ ] **Build log**, kept as you go and never written afterwards:
      dated, what you did, what failed, what you tried, what happened,
      and what you decided. Version control carries the firmware
      history, as [[Version Control for Firmware]] sets out.
- [ ] **Test plan executed**, with the data recorded — including the
      trials that failed and the measurements that disagreed with your
      predictions.
- [ ] **Handover package**: schematic matching the board, code a
      stranger could follow, the build log, the test results, and a
      plain statement of the known limitations.
- [ ] **Demonstration and defence** at [[The Engineering Review]].

## How it is assessed

The criteria table, weighted as [[How Marks Work]] sets out. Three
things are worth saying plainly.

First, the build log is assessed as work rather than as paperwork. An
engineer who cannot say what they did yesterday cannot be trusted with
tomorrow, and the log is the only honest record of the decisions you
made under time pressure.

Second, a device that does not fully work, whose log shows disciplined,
documented, well-reasoned engineering, scores well above a device that
works by accident. Cutting scope for a stated reason is engineering, and
it is assessed as engineering.

Third, this project is the main evidence in your [[Tech Journal]] for
the year. [[Showing Growth]] asks you to set it beside your first entry
from Unit 1, and [[Final Reflection]] asks what specifically you can now
do that you could not do in September.

Safety runs through every bench period: separate supplies for loads,
protection on anything inductive, current budgets checked before power,
derating figures on the parts that get warm, and the standing agreement
in [[Safety in the Lab]] applied without being asked. The discussion in
[[When Good Enough Is Not Safe]] is the question this task answers in
practice.

## Success criteria

| Quality | What it looks like at your bench |
| --- | --- |
| A problem worth solving | The one-sentence problem names a person and their difficulty |
| A defensible design | Block diagram, calculations, and power budget all agree |
| Margin chosen, not inherited | Derating figures marked, with the worst case named |
| Three strands combined | Analogue circuitry, an interface, and code, all yours |
| A log kept as it happened | Dated entries, failures included, written at the bench |
| A test plan executed | The measurements you promised, taken, including the bad ones |
| A handover a stranger could use | Schematic, code, log, results, and known limits |
| An honest account of limits | You can name what it does not do, and why |
| Professional safety practice | Supplies separated, loads protected, no reminders needed |

> [!warning]- If your scope is slipping and two periods remain
> Cut, and cut early. Decide today which single function *is* the
> device, and make that one work completely — measured, logged,
> documented, demonstrable. A finished half of an ambitious project is
> a project; an unfinished whole one is a story about what you meant to
> do. Write the cut and its reasoning into the build log, with the date
> and the state of things when you made it. Deciding what to abandon,
> on evidence and on time, is one of the harder professional skills in
> this trade, and we will assess it as such.

%%curriculum-start%%
## Curriculum connection

![[A3.5]]

![[B3.1]]

![[B3.3]]

![[B5.3]]

![[A5.3]]

![[B1.1]]

![[C1.1]]

![[D1.1]]
%%curriculum-end%%
