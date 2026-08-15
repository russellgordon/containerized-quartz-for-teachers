---
title: Linear Systems
publish: true
created: __CREATED__
tags:
  - concepts
---
At the boards during [[Crossing Paths]], your group tracked two
walkers on the same grid and asked when both would be in the same
place at the same time. That question — one moment where two
different stories are true at once — is what a *linear system* is.

A system of linear equations is two lines considered together:

$$
y = 2x + 1 \qquad y = -x + 7
$$

A *solution* to the system is a point $(x, y)$ that satisfies both
equations at once. Not one, not mostly both — both. On the graph,
that is the point where the lines cross: $(2, 5)$ here, because
$5 = 2(2) + 1$ and $5 = -(2) + 7$ are both true statements.

## What can happen when two lines meet

| Situation | What you see | Solutions |
| --- | --- | --- |
| Different slopes | lines cross once | exactly one point |
| Same slope, different intercepts | parallel lines | none |
| Same line written two ways | one line atop the other | every point on it |

The middle row surprises people. $y = 2x + 1$ and $y = 2x - 4$ never
meet, so the system has no solution — no moment where both stories
hold. The last row hides in disguise: $y = 2x + 1$ and $2y - 4x = 2$
look different but describe the same line, which is one reason it
pays to translate equations between forms — $y = mx + b$,
$Ax + By + C = 0$ — before judging a system by its looks.

## Solving by graphing — and where it runs out

Graph both lines, read the crossing point, then verify by
substituting into both equations. When the intersection lands on a
grid point this works beautifully, and [[Using Desmos]] makes the
picture nearly instant.

But nudge one equation and the crossing point slides to something
like $(1.2, 2.6)$ — a spot your eyes cannot certify from a sketch.
Graphs show you roughly *where*; they cannot always tell you
*exactly*. That gap is what [[Solving Systems Algebraically]]
closes.

Estimating from the picture first is still worth it — a rough graph
tells you what answer would be reasonable, the same instinct
[[Estimation Duels]] trains. Then [[Linear Systems Practice]] offers
a mixture of graph-friendly and graph-hostile systems, to build
judgement about which tool a given problem deserves.

%%curriculum-start%%
## Curriculum connection

![[B1.2]]

![[B1.5]]
%%curriculum-end%%
