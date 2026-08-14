---
title: Writing a Test Plan
draft: false
created: __CREATED__
tags:
  - tutorials
---
"I tested it" usually means "I ran it once with a number I liked". A
test plan is the written version of the question *what would have to
happen for this to be wrong?* — decided before you run anything, so
that the program cannot talk you out of it.

## The four columns

| Scenario | Input | Expected | Actual |
| --- | --- | --- | --- |
| Typical adult ticket | `35` | `$12.00` | |
| Child boundary, below | `12` | `$8.00` | |
| Child boundary, at | `13` | `$12.00` | |
| Senior boundary | `65` | `$9.00` | |
| Not a number | `twelve` | Asks again, does not crash | |
| Nothing typed | *(Return)* | Asks again, does not crash | |
| Impossible age | `-4` | Rejected with a message | |

The expected column is filled in **before** running, by hand or from
the specification. That order is the whole method: a value you work out
after seeing the output is not a test, it is a transcript.

## Choosing the rows

- **One typical case** per branch of the program, so every path runs at
  least once.
- **The boundaries**, and both sides of each. If the rule changes at
  13, test 12 and 13. Nearly every off-by-one error in this course
  lives at exactly that pair.
- **The empty case**: no input, an empty file, an empty list.
- **The hostile case**: letters where a number belongs, a missing file,
  a number far outside anything sensible.

Seven rows chosen this way beat thirty typical ones.

## Running it

Fill the Actual column honestly, including the rows that pass. A row
where actual differs from expected is not a failure of the plan — it is
the plan doing its only job. Fix, then re-run **every** row, because
fixes break neighbours.

Keep the table with the program. When you hand work in, it shows what
you checked; when you come back in three weeks, it tells you what
"working" meant. [[The Bad Input Hunt]] is where these rows come from
for a program somebody else wrote, and [[Testing and Debugging]] is the
wider habit this belongs to.

%%curriculum-start%%
## Curriculum connection

![[B4.4]]

![[A4.5]]
%%curriculum-end%%
