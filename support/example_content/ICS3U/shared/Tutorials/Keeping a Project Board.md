---
title: Keeping a Project Board
publish: true
created: __CREATED__
tags:
  - tutorials
---
A three-week project fails quietly in week one, when everybody is
"working on it" and nobody can say what is finished. A board fixes
that, and it can be a sheet of paper.

## Three columns and a rule

```
TO DO                 DOING                  DONE
─────                 ─────                  ────
Read the file         Ask for the year       Menu prints
Average per month     (Priya, Wed)           Sample data made
Handle a bad year
Write the usage note
```

The rule: **one card per person in DOING**. Anything else is not a
plan, it is a wish list. A card moves left to right and never
backwards; if it has to come back, it was two cards.

## Writing a card that works

A good card is a thing that can be *finished*, phrased so that two
people agree when it is:

- "Handle a year with no readings" — finishable, checkable.
- "Work on input" — neither.

Put a name and a date on every card in DOING. Not to police anybody:
so that on Thursday, the question is "how is the bad-year card going?"
rather than "how is it going?", which is a question nobody can answer
usefully.

## Milestones

Mark the two or three moments the project must pass through, and put
them on the board where everyone sees them:

| Milestone | What has to be true |
| --- | --- |
| Spec agreed | The client has said yes to what we described |
| Walking skeleton | It runs end to end, badly, with fake data |
| Feature complete | Every promised feature exists |
| Tested and documented | Test plan filled in, usage note written |

The walking-skeleton milestone is the one that saves projects. A
program that runs end to end on Day 3 — reading nothing, printing
placeholders — turns every later card into an improvement instead of a
gamble.

## The status update

Once a week, three lines, in writing:

1. What moved to DONE.
2. What is in DOING, and who has it.
3. What is blocked, and what would unblock it.

Line 3 is the one that matters. A team that says "blocked on the sample
data" on Tuesday loses an hour; a team that says it on Friday loses the
week. [[The Community App]] asks for exactly these three lines, and
your [[Code Journal]] is where the practice starts.

%%curriculum-start%%
## Curriculum connection

![[B4.3]]

![[B4.6]]

![[B1.2]]
%%curriculum-end%%
