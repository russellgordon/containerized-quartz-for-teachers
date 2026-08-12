---
title: Always, Sometimes, Never
draft: false
created: __CREATED__
tags:
  - number-talks
---
A claim goes up — "at the top of a smooth hill, the derivative is
zero" — and everyone must file it under *always*, *sometimes*, or
*never*. "Sometimes" is not a shrug: it obliges you to produce a
case where the claim holds, one where it fails, and the exact
boundary between them.

## How we play

1. Classify silently first. Gut verdicts welcome; they get audited.
2. "Always" and "never" demand an argument covering every case.
3. "Sometimes" demands an example, a counter-example, and the boundary.

> [!example]- The hilltop claim, argued
> - "$y = 4 - x^2$ peaks at the origin, and the tangent there is
>   flat. Not *never*."
> - "Could a smooth curve peak on a slant? Walk toward the top: the
>   secants arriving from the left rise, the secants leaving to the
>   right fall. The tangent is squeezed between rising and falling —
>   it has nowhere to go but flat."
> - "'Smooth' is doing real work in that argument. $y = \lvert x \rvert$
>   turned upside down peaks at a *corner*, and a corner has no
>   slope at all — no tangent to be flat. The claim survives only
>   because 'smooth' rules the corner out."
> - "So: *always*, for smooth hills. And the converse is the
>   *sometimes* everyone should carry out the door: where the
>   derivative is zero, is there a hilltop? $y = x^3$ flattens at
>   the origin and keeps right on climbing. The boundary is whether
>   the derivative *changes sign* — flat is a candidate, not a
>   verdict."

## One variation

Claims from the vector weeks: "$\vec{u} \times \vec{v}$ equals
$\vec{v} \times \vec{u}$" — sometimes, and the boundary is sharper
than it looks. Swapping the order of a cross product flips the
answer's direction, so the two sides *disagree* whenever the answer
is a genuine arrow — and agree only when the answer is the zero
vector, which happens exactly when the two vectors are parallel.
A product that cares about order is new territory, and
[[The Cross Product]] is where the room gets to argue about why.

> [!tip] "Sometimes" is where the mathematics is
> The boundary of a claim is its content. The course before this one
> ended on a claim it could not settle: *as the interval shrinks,
> the average rate of change settles on a single value*. This course
> opens by settling it — **sometimes**, and the boundary runs
> exactly through the corners and jumps where no tangent exists.
> Drawing that line precisely is the job [[The Limit]] was invented
> for, and [[The Derivative]] lives on the "always" side of it.
