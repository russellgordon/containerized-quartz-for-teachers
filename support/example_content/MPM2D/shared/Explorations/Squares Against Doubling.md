---
title: Squares Against Doubling
publish: true
created: __CREATED__
tags:
  - explorations
---
Two rules, one race. One squares the input; the other doubles for every
step. Before anybody graphs anything, the room is going to argue about
which one wins — and most of the room will be wrong about *when*.

## Build the tables first

In pairs, on paper, fill both columns for $x = 0$ through $10$:

| $x$ | $y = x^2$ | $y = 2^x$ |
| --- | --- | --- |
| 0 | 0 | 1 |
| 1 | 1 | 2 |
| 2 | 4 | 4 |
| 3 | 9 | 8 |
| 4 | | |
| … | | |
| 10 | | |

Before you go past $x = 4$, commit to an answer in writing: **which is
larger at $x = 10$, and by how much?** Write the number down. You will
want to see it again.

## What to notice on the way

- They are equal at $x = 2$, and equal again at $x = 4$. Between those,
  the squaring rule is ahead.
- After $x = 4$ the doubling rule takes over and never gives the lead
  back.
- By $x = 10$ it is $100$ against $1024$. By $x = 20$ it is $400$
  against more than a million.

That is the fact worth carrying out of this course: **exponential growth
beats polynomial growth eventually, and "eventually" often arrives later
than people expect** — which is exactly why it surprises them.

## Now graph both

Plot them on the same axes in [[Using Desmos]], and then argue about
these:

1. Where do the graphs cross, and does the picture agree with your
   table?
2. What does each graph do for negative $x$? One is symmetric and one is
   not — say why in terms of the rules themselves.
3. Does $y = 2^x$ ever reach zero? Ever go below it?
4. Which graph has a minimum? Which has none?

| | $y = x^2$ | $y = 2^x$ |
| --- | --- | --- |
| Shape | Parabola, symmetric | Rising curve, no symmetry |
| At $x = 0$ | 0 | 1 |
| Negative $x$ | Rises again | Shrinks towards zero |
| Ever zero? | Yes, once | Never |
| Minimum | At the vertex | None |

## Where each one shows up

Squaring describes things that grow with area or with the square of a
dimension: the area of a ripple, the distance a dropped object falls,
the strength of a signal falling off. Doubling describes things that
multiply: bacteria dividing, a rumour spreading, compound interest, a
folded sheet of paper.

Asking which model fits is a question about the *situation*, not the
numbers — and that is the question [[When Will I Use This]] keeps
returning to.

## Afterwards

In your [[Math Journal]]: the number you predicted for $x = 10$, the
real one, and what you had assumed that made the gap. The size of that
gap is the whole exploration.

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[A1.3]]
%%curriculum-end%%
