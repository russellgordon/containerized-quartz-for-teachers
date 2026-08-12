---
title: How Fast Is It Changing?
draft: false
created: __CREATED__
tags:
  - explorations
enableToc: true
---
A ball is dropped from a tower, and the distance it has fallen after
$t$ seconds is $d = 5t^2$ metres. The question sounds innocent: how
fast is it falling at *exactly* $t = 3$?

## The task

Speed is distance over time — but at exactly $t = 3$, no time passes
and no distance falls. So sneak up on it: compute the average speed
from $t = 3$ to $t = 4$. From $3$ to $3.5$. To $3.1$. To $3.01$.
Draw each of these as a line through the graph's point at $t = 3$ —
what are the lines doing as the interval shrinks? Your group owes
the room a single defensible number: the speed at the instant
$t = 3$, with the argument for why that number and no other. Then
push: does the same sneaking-up work at $t = 1$? On a curve that is
not a parabola? And the uncomfortable one — is "instantaneous speed"
even a real thing, if computing it head-on divides zero by zero?

> [!tip]- Facilitation notes — for the teacher
> Insist on the table before the picture: the numerical parade makes
> the limit feel inevitable before anyone says "limit". The
> productive fight is over whether the number the parade points at
> is *the answer* or merely *never quite reached* — let both camps
> argue; the resolution (every tolerance anyone names is eventually
> beaten) is the epsilon idea wearing street clothes. Approaching
> from the left ($t = 2.9$, then $2.99$) is the natural check —
> encourage it. Fast groups: find the instantaneous speed at $t = 1$
> and $t = 2$, conjecture the pattern, and test the conjecture — a
> derivative discovered a year early.

## What mathematics tends to surface

The averages parade in an orderly way, each one closer to the last,
and the pattern points at a single value like a compass needle.
Geometrically, the lines through the point — secants — tilt toward a
limiting line that touches the curve only there: the tangent. The
instantaneous speed *is* that tangent's slope, reached by approach
rather than by direct computation — the first genuinely new idea of
the unit, and the doorway to calculus. [[Rates of Change]] gives the
approach its vocabulary.

## Where it leads

Every function this course has built now gets asked the same
question — how fast, right now? — and [[The Signature Function]]
demands your answer for a phenomenon of your own. Next year the
sneaking-up gets a name, a notation, and an entire course; today
your group computed its first derivative without permission.

> [!note] The answer is not on this page
> No worked solution appears here. The number — and the argument
> that forces it — belongs to your group at the boards.

%%curriculum-start%%
## Curriculum connection

![[D1.6]]

![[D1.7]]

![[D1.8]]
%%curriculum-end%%
