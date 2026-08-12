---
title: Equations of Lines
draft: false
created: __CREATED__
tags:
  - concepts
---
At the boards today, the challenge was to describe a straight path
so precisely that another group could walk it — using only vector
language. Every group converged on the same two ingredients: a point
to start from, and a direction to keep. That pair *is* a line, and
writing it down gives the vector equation:

$$\vec{r} = \vec{r}_0 + t\,\vec{m}$$

Start at the point $\vec{r}_0$, walk multiples $t$ of the direction
vector $\vec{m}$. Every value of the parameter $t$ lands on the
line; negative $t$ walks backward; $t$ sweeps through all real
numbers and the whole line appears. It is
[[Adding and Scaling Vectors|adding and scaling]] doing geometry.

## Three costumes for one line

Take the line through $(1, 2)$ with direction $(3, 1)$. It owns
three equivalent descriptions:

| Form | The line through $(1, 2)$, direction $(3, 1)$ |
| --- | --- |
| Vector | $\vec{r} = (1, 2) + t(3, 1)$ |
| Parametric | $x = 1 + 3t, \quad y = 2 + t$ |
| Scalar | $x - 3y + 5 = 0$ |

The parametric form is the vector form read one coordinate at a
time. The scalar form comes from eliminating $t$ — solve each
parametric equation for $t$, set the results equal, tidy up. Each
costume answers a different question fastest: the vector form knows
*direction*, the parametric form generates points on demand, and
the scalar form tests a point's membership instantly. Moving fluently
among them is the skill; none of them is "the" equation.

## The surprise in three-space

Lift everything into three dimensions and the vector and parametric
forms come along without complaint — the line through $(3, 2, -1)$
and $(0, 2, 1)$ has direction $(-3, 0, 2)$ and equation
$\vec{r} = (3, 2, -1) + t(-3, 0, 2)$. But the scalar form does
*not* survive the trip. A single scalar equation in $x$, $y$, $z$
has too many solutions to be a line — its solution set is a whole
[[Equations of Planes|plane]] — so no single scalar equation can
pin down a line in three-space. The best scalar language can do is
name a line as the meeting of *two* planes: two equations, jointly
satisfied. Check it against the crease where two walls of the room
meet — each wall is one equation, the crease needs both.

That asymmetry — vector forms generalise, scalar forms buckle — is
the reason vector equations run the rest of the unit. Explore it
with your own hands in [[Using Desmos]] before trusting it, sketch
your findings, and then take on [[Lines and Planes Practice]]. The
[[The Flight Path]] task starts here: an approach path is nothing
but a point and a direction.

%%curriculum-start%%
## Curriculum connection

![[C3.1]]

![[C4.1]]

![[C4.2]]
%%curriculum-end%%
