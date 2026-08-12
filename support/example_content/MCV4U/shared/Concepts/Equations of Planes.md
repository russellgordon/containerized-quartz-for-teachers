---
title: Equations of Planes
draft: false
created: __CREATED__
tags:
  - concepts
---
In [[Where Planes Meet]], your group held a sheet of cardboard flat
and stood a drinking straw perpendicular to it — and discovered that
the straw is a better description of the sheet than the sheet is.
Tilt the cardboard and the straw tilts with it; every direction
lying *in* the sheet is perpendicular to the straw. That straw is
the plane's **normal vector**, and one normal plus one known point
nails the plane completely.

The algebra is one dot product. A point $P$ lies on the plane
exactly when the vector from the known point to $P$ is perpendicular
to the normal $\vec{n} = (A, B, C)$ — a
[[The Dot Product|dot product of zero]]. Expand that condition and
it tidies into the scalar equation:

$$Ax + By + Cz + D = 0$$

The normal's components sit in plain sight as the coefficients: one
normal to $3x + 5y - 2z = 6$ is $(3, 5, -2)$, readable without any
work. Every scalar multiple of a normal is another normal — the
straw can be any length — which is why $6x + 10y - 4z = 12$ is the
same plane wearing doubled coefficients.

## Building a plane from three points

Three points, as long as they refuse to line up, determine a plane —
a camera tripod stands firm where a four-legged chair wobbles. The
recipe: two vectors in the plane, then [[The Cross Product]] to
manufacture the normal.

> [!example] The plane through $(1, 0, 0)$, $(0, 2, 0)$, $(0, 0, 3)$
> Two in-plane vectors, first point to the others:
> $\vec{u} = (-1, 2, 0)$ and $\vec{v} = (-1, 0, 3)$. The normal is
> $\vec{n} = \vec{u} \times \vec{v} = (6, 3, 2)$. With point
> $(1, 0, 0)$: $6x + 3y + 2z = 6$. Audit before trusting — the
> second point gives $3(2) = 6$, the third gives $2(3) = 6$. All
> three check. An unaudited plane equation is a conjecture, not an
> answer.

## Vector and parametric forms

Planes also take the point-plus-directions costume from
[[Equations of Lines]] — but a plane is two-dimensional, so it needs
*two* direction vectors and two parameters:

$$\vec{r} = \vec{r}_0 + s\,\vec{u} + t\,\vec{v}$$

Two independent sliders, a whole flat sheet of reachable points. To
convert back to scalar form, cross the two direction vectors for the
normal. One line either way — and both directions of travel are
rehearsed in [[Lines and Planes Practice]]. What happens when
planes and lines share the room — crossing, missing, colliding — is
[[Intersections of Lines and Planes]].

%%curriculum-start%%
## Curriculum connection

![[C3.2]]

![[C4.3]]

![[C4.5]]

![[C4.6]]
%%curriculum-end%%
