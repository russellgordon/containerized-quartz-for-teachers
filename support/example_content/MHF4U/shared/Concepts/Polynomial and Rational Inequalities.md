---
title: Polynomial and Rational Inequalities
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Designing for [[The Rollercoaster]], your group needed to know where
the track sat *above* the ground — not where it touched, but the
whole stretch between touches. That is the shift this page names: an
equation asks "where exactly?", an inequality asks "over what
region?" — and the answers are different kinds of objects.

## Solutions are intervals

The solution to $f(x) = 0$ is a handful of numbers. The solution to
$f(x) > 0$ is a set of *intervals* — every $x$ where the graph rides
above the axis. A continuous function can only change sign where it
crosses zero, so the zeros carve the number line into pieces, and on
each piece the sign is constant. Find the boundaries, then test one
value per piece: one honest test value speaks for its whole interval.

## The sign chart

To solve $x^3 + x^2 > 0$, factor to $x^2(x + 1) > 0$; the zeros are
$-1$ and $0$ (multiplicity 2). Then chart the pieces:

| Interval       | Test value | $x^2(x+1)$          | Sign |
| -------------- | ---------- | -------------------- | ---- |
| $x < -1$       | $-2$       | $4 \times (-1)$      | $-$  |
| $-1 < x < 0$   | $-0.5$     | $0.25 \times 0.5$    | $+$  |
| $x > 0$        | $1$        | $1 \times 2$         | $+$  |

Solution: $x > -1$ with $x \ne 0$. Notice the even multiplicity at 0
announcing itself — the graph touches without crossing, so the sign
refuses to change there. The chart is not just bookkeeping; done at
the boards, it is a picture of the argument, and it agrees with the
graph in [[Using Desmos]] every time.

## When the function breaks

For a rational inequality, the sign can flip at a zero *or* at a
vertical asymptote, so both kinds of boundary go on the chart. Two
rules keep you honest:

- Never multiply both sides by an expression containing $x$ — you do
  not know its sign, so you do not know whether the inequality flips.
  Move everything to one side and chart the sign instead.
- Boundary points from the denominator are never included in the
  solution, even for $\ge$ — the function does not exist there.

Solving $\frac{x+1}{x-1} \ge 2$ this way — subtract 2, simplify,
chart — lands in [[Rational Functions Practice]], alongside its
polynomial cousins in [[Polynomial Graphing Practice]]. A wrong
interval on a first attempt is data, not damage: it tells you exactly
which boundary you mishandled.

%%curriculum-start%%
## Curriculum connection

![[C4.1]]

![[C4.2]]

![[C4.3]]
%%curriculum-end%%
