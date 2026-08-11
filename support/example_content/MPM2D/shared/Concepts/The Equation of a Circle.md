---
title: The Equation of a Circle
draft: false
created: __CREATED__
tags:
  - concepts
---
At the boards in [[The Circle on the Grid]], your group hunted for
every point exactly 5 units from the origin. The grid points came
first — $(3, 4)$, $(5, 0)$, $(-4, 3)$, $(0, -5)$ — and then the
shape they were tracing appeared: a circle, centred at home.

## From promise to equation

A circle is not a formula first. It is a promise: *every point on me
is the same distance from the centre.* Put the centre at the origin,
call the distance $r$, and ask what the promise says about a point
$(x, y)$ on the circle. Its distance from $(0, 0)$ is
$\sqrt{x^2 + y^2}$ — the length formula from
[[Midpoint and Length]] with one end at home. Set that equal to $r$
and square both sides:

$$
x^2 + y^2 = r^2
$$

The equation of a circle is the Pythagorean theorem, sworn to hold
at every single point of the curve. $(3, 4)$ is on the circle of
radius 5 because $9 + 16 = 25$. $(4, 4)$ is not, because
$16 + 16 = 32 \ne 25$ — that point sits $\sqrt{32} \approx 5.66$
units from home, just outside.

## Reading the equation both ways

Given a radius, write the equation: radius 7 gives
$x^2 + y^2 = 49$. Given an equation, extract the radius:
$x^2 + y^2 = 20$ has radius $\sqrt{20} = 2\sqrt{5} \approx 4.47$ —
not 20, and not 10.

> [!warning] The number on the right is $r^2$, not $r$
> This is the most common slip with circles. Before sketching, say
> the radius out loud: "$x^2 + y^2 = 36$ ... radius 6." If the
> radius you state does not square back to the right-hand side, one
> of them is wrong — a ten-second catch.

To sketch, mark the centre, step out $r$ in all four axis
directions, and join the four points with a smooth curve. Deciding
whether a point lies on, inside, or outside the circle needs no
picture at all — substitute and compare with $r^2$, since inside
means closer to home than $r$ and outside means farther.

[[Circle and Coordinate Practice]] mixes all these directions of
travel, and [[Using Desmos]] will confirm any sketch in seconds.

%%curriculum-start%%
## Curriculum connection

![[B2.3]]

![[B2.4]]
%%curriculum-end%%
