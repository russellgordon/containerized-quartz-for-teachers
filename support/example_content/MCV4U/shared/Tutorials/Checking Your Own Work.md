---
title: Checking Your Own Work
publish: true
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Nobody marks your checker but you. Every mathematician you will ever
meet runs one — a quiet second pass that catches errors before they
matter — and the earlier you build yours, the sooner tests stop being
scary. Four habits make up the whole machine.

## Interrogate the candidate — into everything

Solved an optimization? The derivative handed you a *candidate*, not
an answer — nudge the variable a little each way and the function
itself will referee: at a true maximum, both nudges lose. A claimed
derivative can be cross-examined the same way, no answer key
required: if you believe $f'(3) = 6$, then
$\frac{f(3.001) - f(3)}{0.001}$ had better come out a whisker from 6.
The definition is a referee you carry everywhere. The same reflex
checks a model: feed your braking-car curve a radar reading you did
*not* use to build it, and see whether the position it predicts
matches the data.

## Estimate first, compare after

Before solving, write down a rough expected size — the reflex
[[Estimation Duels]] trains. The tangent slope of $y = x^2$ at
$x = 3$ must land between 5 and 7, because the secants on either
side bracket it; if your algebra hands you 12, one of you is wrong,
and now you know to look. This check only works if the estimate came
*before* the answer did.

## Check the units — and the species

Units are a free error detector. If a velocity answer arrives in
metres when the question asked for metres per second, something
upstream broke — and the units caught it without you rereading a
single step. In the vector unit the check grows teeth: a dot product
is a *scalar* — if yours came out with components, something broke;
a cross product is a *vector* — if yours came out as a plain number,
same alarm. Answers here have a species as well as a size, and
saying both out loud is the cheapest check in the course. Carry them
through every line, as [[Showing Your Thinking]] insists.

## Ask whether the graph agrees with its own story

After building a sign chart, interrogate the sketch. A positive
derivative promises a climbing curve — if your sketch falls where
your chart says positive, one of them is lying, and it is not the
chart. A velocity graph that never touches zero belongs to a
position graph with no turning point; a descent model whose height
dips below the runway is promising a landing that goes through the
ground, and the sketch objects instantly. A graph that disagrees
with its own situation is the cheapest alarm in [[Curve Sketching]]
— and the question behind it is the one [[What Makes a Model Good]]
asks of every model: does it tell the truth about the world it
claims to describe?
