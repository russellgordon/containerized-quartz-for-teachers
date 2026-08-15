---
title: The Circle on the Grid
publish: true
created: __CREATED__
tags:
  - explorations
enableToc: true
---
Mark home at the origin of a grid. Somewhere out there is every point
that sits *exactly* 5 units from home — not roughly, exactly. Your
job is to find them. All of them.

## The task

Plot every point you can that is exactly 5 from the origin. Start
wherever certainty is cheap, and build outward. Then three claims to
settle as a group: how many of your points have whole-number
coordinates — and are you sure you have them all? what shape do the
points make, and why must it be that shape? and the big one — write a
*test*, using only arithmetic, that decides whether any point
$(x, y)$ belongs to your collection, without a ruler ever touching
the page.

> [!question]- Getting started (click to expand)
> - Four points cost nothing: they sit on the axes. Where?
> - Try $x = 3$. How high can you go before the distance from home
>   stops being 5? What right triangle just appeared?
> - "Exactly 5" is a claim about a hypotenuse. Which two legs?
> - Found one point off the axes? Symmetry hands you seven more for
>   free — say why.

## What mathematics tends to surface

Every point you test drops a perpendicular to the axes and becomes a
right triangle with hypotenuse 5 — so the Pythagorean theorem is
secretly the membership test, and writing it down for a general point
is the distance formula of [[Midpoint and Length]] arriving a day
early. The test itself, $x^2 + y^2 = 25$, is an equation whose graph
*is* the shape on your board — the idea at the heart of
[[The Equation of a Circle]]. The 3-4-5 triangle explains why twelve
lattice points appear, and why they come in symmetric families.

## An extension

Move home to $(6, 8)$ and collect the points exactly 5 from *there*.
What survives from your old test, and what has to change? Then a
harder honesty question: is the origin itself 5 units from your new
circle — in what sense? Sharpen your answers against
[[Circle and Coordinate Practice]] when the technique lands.

> [!note] The answer is not on this page
> No list of points and no equation is printed here. The test is
> yours to build and defend at the boards.

%%curriculum-start%%
## Curriculum connection

![[B2.2]]

![[B2.3]]
%%curriculum-end%%
