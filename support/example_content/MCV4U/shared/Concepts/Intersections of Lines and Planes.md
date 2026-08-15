---
title: Intersections of Lines and Planes
publish: true
created: __CREATED__
tags:
  - concepts
---
The cardboard-and-straws phase of [[Where Planes Meet]] asked your
group to build every way that lines and planes can share
three-space, and the census surprised everyone. Two lines can cross,
run parallel — or do something impossible on paper: miss each other
entirely without being parallel, like two highways at different
heights. Those are **skew lines**, and they are the first sign that
three-space plays by richer rules. Two distinct planes never manage
skewness: they are parallel, or they intersect — and when they
intersect, they share a whole *line*, the crease your two cardboard
sheets made. Three planes can meet in a point (the corner of the
room), in a line (a book's pages at the spine), in a plane, or
nowhere at all.

The catalogue matters because every intersection question has two
layers: *what kind* of meeting is possible, then *where* it happens.
Algebra answers both — solutions of the combined equations are
exactly the shared points, so the geometry is read off the algebra.

## A line meets a plane

Substitute the line's parametric form into the plane's scalar
equation and solve for the parameter. The line
$\vec{r} = (1, 1, 0) + t(0, 1, 1)$ meets the plane $x + y + z = 6$
where $1 + (1 + t) + t = 6$, so $t = 2$: the point $(1, 3, 2)$. One
value of $t$, one crossing point. Had the variable vanished, the
equation itself would have delivered the verdict: $0t = 5$ means no
solutions — the line is parallel to the plane and misses; $0t = 0$
means every $t$ works — the line lies *inside* the plane. The
algebra does not merely find the intersection; it diagnoses the
configuration.

## Three planes at once

Three scalar equations, three unknowns — elimination or
substitution, exactly the systems machinery you already own, with a
geometric reading attached to every outcome. A unique solution is a
corner point; a one-parameter family is a spine line; a
contradiction means at least two planes never meet.

> [!question]- Self-check: can you predict "no corner point" without
> solving?
> Often, yes. If the three normals $\vec{a}$, $\vec{b}$, $\vec{c}$
> satisfy $\vec{a} \cdot (\vec{b} \times \vec{c}) = 0$, the normals
> are coplanar and the three planes cannot pin down a single point —
> the configurations left are line, plane, or nothing. The test
> costs one cross product and one dot product; a solve that was
> doomed from the start costs a whole page. Check before you
> compute.

Distances belong to this family too — the distance from a point to a
plane is measured along the normal, the perpendicular being the
shortest path. It is the final move in [[The Flight Path]]: after
the approach line meets the runway plane, you certify the clearance.
[[Lines and Planes Practice]] closes with the full range —
crossings, skew tests, corner points, and distances. Consolidating
from the bottom, this page is the whole unit in one sentence: turn
geometry into equations, solve, and translate the solution back
into a picture.

%%curriculum-start%%
## Curriculum connection

![[C3.3]]

![[C4.4]]

![[C4.7]]
%%curriculum-end%%
