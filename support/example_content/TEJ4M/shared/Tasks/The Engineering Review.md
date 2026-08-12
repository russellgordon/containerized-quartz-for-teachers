---
title: The Engineering Review
draft: false
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> The last class of the course · demonstrate your capstone from
> [[The Engineering Design Project]], defend it against published
> questions, and give three other projects a real critique · handover
> packages in at the end

## What you are doing

Three things, in this order: you show that your device works, you answer
for the decisions inside it, and you give other people's work the kind
of attention you want yours to get.

The defence is the part that is new. Nobody is trying to catch you out —
every question is published below, and you have had them since the
design review in Unit 4. That is deliberate: a professional review is
not an ambush, it is a known standard applied consistently, and being
ready for it is a skill you can practise.

The critique is the part people underestimate. A room of engineers is
worth more than a room of admirers, and giving a useful criticism
kindly, in front of the person who did the work, is genuinely difficult.
We will all practise it today.

## The protocol

Each project gets fifteen minutes, in three parts.

1. **Demonstration, five minutes.** The device does its job in front of
   the room. You show one working run, one measured claim, and one
   honest failure mode — the thing you know it does badly, shown by
   you rather than found by somebody else.
2. **Defence, six minutes.** Three questions from the published list,
   chosen at the time, answered at your bench with your evidence within
   reach. "I don't know" is an acceptable answer exactly once, and only
   when followed by how you would find out.
3. **Critique, four minutes.** Two peers respond in the fixed form: one
   question, one commendation, one recommendation. In writing, signed,
   handed to the presenter.

## The questions you must be ready for

These are the whole list. Three of them will be asked.

- What does this device do, in one sentence, and for whom?
- Which requirement was hardest to meet, and how do you know you met
  it?
- Take one component that carries real current: why that part, at that
  rating, and what margin did you leave?
- Show me a calculation you did before you built, and tell me how the
  measurement compared.
- What is the worst environment this device would survive, and what
  fails first past that point?
- What happens if somebody connects it backwards, or unplugs a sensor
  while it is running?
- Which part of this would you not trust in a year, and why that part?
- What did you cut, when did you decide, and what did the decision cost
  you?
- Where in your code would a stranger get lost, and what did you do
  about it?
- If I handed your package to another student, what is the first thing
  they would have to ask you?
- What would you do differently if you started again on Monday?
- What did you learn from a failure that you could not have learned any
  other way?

## Milestones

- [ ] **Handover package complete** before the period starts:
      schematic, code, build log, test results, known limitations.
- [ ] **Demonstration rehearsed** once with a timer, out loud.
- [ ] **One honest failure mode chosen**, and the way you will show it
      decided in advance.
- [ ] **Three critiques written and delivered**, in the fixed form, for
      three different projects.
- [ ] **[[Tech Journal]] in**, checked against [[Journal Checklist]],
      with [[Final Reflection]] attached.

## How it is assessed

The criteria table, weighted as [[How Marks Work]] sets out. The
demonstration and the defence are assessed together, because a working
device you cannot account for and an accounted-for device that does not
work are the same kind of incomplete.

Your critiques are assessed too, and they are worth real weight. A
recommendation that names a specific change and a reason outranks a
compliment every time. So does a question that the presenter had not
thought of — that is the most valuable thing one engineer gives another.

## Success criteria

| Quality | What it looks like on the day |
| --- | --- |
| A demonstration that shows the truth | Working run, measured claim, and a failure you chose to show |
| A defence built on evidence | Answers point at logs, traces, and calculations in reach |
| Decisions you can own | You can say why, not just what, including what you cut |
| Honest limits | The failure mode comes from you before it comes from the room |
| A usable handover | Schematic, code, log, results, and limits, all present |
| Critique worth receiving | Specific, kind, and about the work rather than the person |
| A journal that shows the year | Growth traceable from the first entry to this one |

> [!tip]- How to answer a question you were not expecting
> Say what you know, say what you do not, and say how you would find
> out — in that order, and out loud. "I measured the running current at
> $180\ \text{mA}$ and derated the switch to half its rating, but I did
> not measure the inrush, and I would put a sense resistor in the
> ground return to catch it" is a complete and professional answer. It
> is also better than a confident guess, because a reviewer's job is to
> find out what you actually know, and everybody in the room can tell
> the difference. This is the last thing this course asks of you, and
> it is the habit that will still be useful in ten years.

%%curriculum-start%%
## Curriculum connection

![[B2.2]]

![[D3.3]]

![[D3.4]]

![[D3.5]]
%%curriculum-end%%
