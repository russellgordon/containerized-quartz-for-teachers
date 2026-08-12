---
title: Optimization
draft: false
created: __CREATED__
tags:
  - concepts
---
In [[The Box Problem]], every group cut different squares from the
corners of the same sheet and folded up a box — and the volumes
posted at the boards disagreed wildly. Small cuts made a wide,
shallow tray; big cuts made a tall, skinny chimney; somewhere in
between, one group's box beat everyone's. The question "which cut is
*best*?" is optimization, and it is the payoff of everything since
[[The Derivative]]: at the very top of the volume curve, the tangent
is flat. Maximums hide where the derivative is zero.

## From story to function

The calculus in an optimization problem is usually the short part.
The real work is translation:

1. Name the variable you control and the quantity you want to
   maximise or minimise.
2. Write the quantity as a function of the variable — use the
   constraint to eliminate everything else.
3. State the domain the *story* allows. A cut of 15 cm from a 24 cm
   sheet is not a boxy opinion; it is impossible.
4. Differentiate, find critical numbers, and decide which one wins.

For the box: $V(x) = x(24 - 2x)^2$ on $0 < x < 12$, and
$V'(x) = (24 - 2x)(24 - 6x)$ is zero at $x = 4$ — the cut the
winning group found by folding.

## Finding and auditing the peak

A critical number is a *candidate*, not a verdict. The audit is
where the thinking lives:

> [!warning] A flat tangent is not always a summit
> $V'(x) = 0$ also happens at valley bottoms, and the extreme value
> you want sometimes sits at an endpoint of the domain instead.
> Confirm every candidate: check the sign of $V'$ on each side
> (uphill then downhill means maximum), or evaluate the function at
> every candidate and endpoint and compare. Then reread the
> question — an answer of $x = 4$ is incomplete if the question
> asked for the volume.

A wrong candidate that survives to your final answer is not a small
slip; it is the whole problem. This is a place where checking is the
mathematics — [[Mistakes Are Data]] is about exactly this habit.

Optimization is also where models earn their keep: bus fares that
maximise revenue, packaging that minimises material, a foraging bird
budgeting its minutes. The curriculum calls this
[[B2.5|applying a mathematical model]], and it is the shape of the
[[The Packaging Brief]] task — a real package, real constraints, and
a defended recommendation. A [[Would You Rather]] instinct helps
before any algebra starts: *roughly* where should the best answer
live, and why? Estimate first, optimize second, and let the estimate
audit the calculus. [[Optimization Practice]] has the full range,
from warm-ups to the bird.

%%curriculum-start%%
## Curriculum connection

![[B2.4]]

![[B2.5]]
%%curriculum-end%%
