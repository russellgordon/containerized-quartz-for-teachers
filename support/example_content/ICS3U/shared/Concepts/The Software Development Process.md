---
title: The Software Development Process
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Every group that has ever started [[The Community App]] by opening a
blank file and typing has arrived at the same place a week later: a
program that does something impressive and not the thing that was
asked for. The process below is not bureaucracy. It is the accumulated
memory of everybody who has lost that week.

## The phases, in the order they bite

| Phase | The question it answers | What it produces |
| --- | --- | --- |
| Problem definition | Whose problem, in their words? | a short written statement |
| Analysis | What must be true for this to count as solved? | a specification |
| Design | What are the pieces, and how do they fit? | pseudocode, flow chart, structure chart |
| Writing code | Does the design survive contact with Python? | the program |
| Testing | Does it work for inputs you did not choose? | a test plan with results |
| Implementation | Can the person actually use it without you? | a handover and instructions |
| Maintenance | What happens when something changes? | fixes, notes, a way to reach you |

The order is real. Skipping design does not save time; it moves the
design work into the middle of coding, where it is far more expensive.
And the last row is the one students underestimate: software that
somebody uses gets changed, and most of the cost of a program in the
world is spent after it first works.

## Milestones and products

A **milestone** is a date something is finished — client agreed, design
approved, first working version, tested, handed over. A **product** is
the thing itself: the specification, the chart, the code, the bug list,
the instructions. Milestones let you say honestly whether you are on
track; products are what you actually hand in and what your client
actually receives.

For a three-week project, a schedule that fits on one page is enough:

| Week | Milestone | Product due |
| --- | --- | --- |
| 1 | Client and problem agreed | problem statement in their words |
| 1 | Design approved | pseudocode plus a structure chart |
| 2 | First version runs end to end | the program, rough but complete |
| 3 | Tested with the client | test plan with actual results |
| 3 | Handed over | working program and instructions |

Notice that "runs end to end" comes before "polished". A thin version
of every piece beats one beautiful piece and four missing ones — you
cannot test what does not exist, and your client cannot react to a
description.

## Specifications come from people

The analysis phase is mostly listening. You are trying to turn "it
would be nice if it kept track of the equipment" into statements
specific enough to test:

- Ask, and record the answer in their words, not your paraphrase.
- Ask what happens *now*, without software — the current routine
  contains the requirements.
- Ask about the awkward cases: what if the same item is signed out
  twice, what if a name is spelled differently, what if the file is
  lost.
- Show something early. A sketch on paper gets more correction than a
  question does.
- Write it down and read it back. "So the program should…" is the
  cheapest bug fix available.

Questionnaires, a short interview, or watching the task being done are
all legitimate techniques, and the interview is the one this course
practises: [[What Would You Ask]] for the reps,
[[Interviewing Your Client]] for the method, and
[[The Client Interview]] for the real thing.

## Saying where you are

A status update is three lines, written weekly, and it is a skill worth
more than most people expect:

1. **Done** — what is finished and testable, not what you worked on.
2. **Next** — the single next milestone and when you expect it.
3. **Blocked** — what you need from somebody else, by when.

Written like that, it takes two minutes and it protects everyone: your
client learns early if a feature is not coming, and you get a record of
your own progress for your [[Code Journal]]. The alternative — silence
until the deadline — is how projects fail politely.

Use the whole process for real on [[The Toolbox]] and
[[The Community App]], and keep the testing half honest with
[[Testing and Debugging]].

%%curriculum-start%%
## Curriculum connection

![[B4.1]]

![[B4.2]]

![[B4.3]]

![[B4.6]]
%%curriculum-end%%
