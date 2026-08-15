---
title: What Vectors Are
publish: true
created: __CREATED__
tags:
  - concepts
---
[[The Treasure Walk]] began with an instruction that was almost
enough: *walk 20 metres.* Twenty metres **which way?** Every group
that guessed a direction ended up somewhere different, and the
treasure stayed buried. The fix was an instruction with two parts —
20 metres, bearing N 40° W — and that two-part quantity is a
**vector**: a magnitude and a direction, welded together. A plain
number with no direction attached (the 20 alone, a temperature, a
mass) is called a **scalar** by contrast.

The world is full of quantities that are secretly vectors: a
displacement, a force on a bridge member, the velocity your phone's
GPS reports, the nudge a game engine gives a sprite. Whenever "how
much" is not enough without "which way", a vector is underneath.

> [!question]- Self-check: a friend is 69 km from Lindsay, Ontario.
> Where are they? (click to expand)
> You cannot say — and that is the point. Sixty-nine kilometres is
> only a magnitude; without a direction it describes an entire
> circle of possible positions around Lindsay. Position needs a
> vector: 69 km *on a stated bearing* pins your friend to one spot.

## Arrows, honestly drawn

On paper a vector is a directed line segment — an arrow. Its length
is the magnitude, written $|\vec{v}|$; its direction can be given as
a rotation like $320°$ or a bearing like N 40° W. And here is the
convention that makes the algebra work: an arrow slid to a new
position *without turning or stretching* is still the **same
vector**. Vectors have magnitude and direction, but no fixed
address.

## Components: arrows as coordinates

Geometry draws vectors; algebra prefers to file them. Put the tail
at the origin and record where the tip lands: the vector with
magnitude 10 pointing $36.9°$ above the positive $x$-axis files as
$(8, 6)$, because $10\cos 36.9° \approx 8$ and
$10\sin 36.9° \approx 6$. The translation runs both ways — from
$(8, 6)$, the Pythagorean theorem recovers
$|\vec{v}| = \sqrt{8^2 + 6^2} = 10$ and
$\tan^{-1}\!\left(\frac{6}{8}\right)$ recovers the direction.

Best of all, nothing stops at two dimensions. A vector in three-space
is a triple like $(1, 2, 2)$, with magnitude
$\sqrt{1 + 4 + 4} = 3$ by the same theorem used twice — and suddenly
you can do geometry in a space you cannot fully draw. That is the
quiet superpower of the whole unit: components turn pictures into
arithmetic, and arithmetic works in any number of dimensions.

[[Adding and Scaling Vectors]] is what these arrows can *do*; the
warm-up questions in [[Dot and Cross Product Practice]] rehearse the
translations both ways.

%%curriculum-start%%
## Curriculum connection

![[C1.1]]

![[C1.2]]

![[C1.3]]

![[C1.4]]
%%curriculum-end%%
