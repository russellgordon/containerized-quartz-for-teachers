---
title: Adding and Scaling Vectors
draft: false
created: __CREATED__
tags:
  - concepts
---
The second day of [[The Treasure Walk]] handed every group *two*
instructions — walk this vector, then walk that one — and asked the
only question that matters: where do you end up, and what single
instruction would have taken you there directly? That single
instruction is the **sum** of the two vectors, and the walking *is*
the definition: place the tail of $\vec{b}$ at the tip of $\vec{a}$,
and $\vec{a} + \vec{b}$ runs from the start of the first walk to the
end of the second. Tip to tail.

Subtraction asks a different question with the same picture:
$\vec{a} - \vec{b}$ is the vector that *corrects* $\vec{b}$ into
$\vec{a}$ — what you would still have to walk, having done
$\vec{b}$, to end up where $\vec{a}$ goes.

**Scalar multiplication** stretches: $3\vec{v}$ is three of those
walks in a row, $\frac{1}{2}\vec{v}$ is half of one, and $-\vec{v}$
is the walk taken backward — same magnitude, opposite direction. A
scalar rescales an arrow; it never turns one.

## Components do the bookkeeping

Geometry defines the operations; components make them fast. Add
coordinate by coordinate, scale coordinate by coordinate:

$$(3, -1, 2) + (1, 4, -2) = (4, 3, 0) \qquad 3(1, 4, -2) = (3, 12, -6)$$

Your group also put the tempting properties on trial rather than
assuming them: is vector addition commutative? Walking $\vec{a}$
then $\vec{b}$ traces a different path from $\vec{b}$ then $\vec{a}$
— but lands on the same spot, the far corner of the same
parallelogram. Commutative, associative, distributive over scalars:
all hold, and each one is a picture before it is a rule.

> [!example] Crossing a river
> You swim at 2 m/s straight across a river; the current carries
> you 1.5 m/s downstream. Taking "across" as $(0, 2)$ and
> "downstream" as $(1.5, 0)$, your actual velocity is the sum
> $(1.5, 2)$, with magnitude
> $\sqrt{1.5^2 + 2^2} = \sqrt{6.25} = 2.5$ m/s, angled
> $\tan^{-1}\!\left(\frac{1.5}{2}\right) \approx 36.9°$ downstream
> of straight across. You never aimed in that direction — the sum
> did. Ferries, planes in wind, and forces on a beam all work
> exactly this way.

Adding and scaling are the whole grammar of vectors — everything in
[[Equations of Lines]] and [[Equations of Planes]] is built from
"start at a point, add multiples of a direction". What addition and
scaling *cannot* do is multiply two vectors together; that takes two
new ideas, starting with [[The Dot Product]]. The warm-up section of
[[Dot and Cross Product Practice]] includes a plane flying through
wind that is worth doing before then.

%%curriculum-start%%
## Curriculum connection

![[C2.1]]

![[C2.2]]

![[C2.3]]
%%curriculum-end%%
