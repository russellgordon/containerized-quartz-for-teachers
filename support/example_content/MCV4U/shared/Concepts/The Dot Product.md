---
title: The Dot Product
publish: true
created: __CREATED__
tags:
  - concepts
---
The boards question that opened class looked innocent: *what should
multiplying two vectors even mean?* Numbers multiply into numbers —
but arrows have direction, and every group's proposal had to decide
what direction does to a product. The dot product is the answer
mathematics settled on, and its defining choice is bold: two vectors
in, one **scalar** out. The directions do not survive; they get
*measured*.

$$\vec{a} \cdot \vec{b} = |\vec{a}||\vec{b}|\cos\theta$$

where $\theta$ is the angle between the vectors. The $\cos\theta$ is
the measuring device: it rewards vectors for pointing the same way,
ignores the part of each vector that is perpendicular to the other.
Pulling a wagon, only the part of your pull along the ground moves
the wagon forward — the dot product of force and displacement is
exactly the work that gets done, and raising the handle shrinks it.

## Two formulas, one number

The geometric formula needs the angle. The miracle is that
components compute the same number without ever finding it:

$$\vec{a} \cdot \vec{b} = a_1b_1 + a_2b_2 + a_3b_3$$

Multiply matching coordinates, add. For $(1, 2, 2)$ and
$(2, 2, 1)$: $2 + 4 + 2 = 8$. Set the two formulas equal and the
angle falls out — $\cos\theta = \frac{8}{3 \times 3}$, so
$\theta \approx 27°$. An angle in three-space, measured without a
protractor, in a space nobody can fully draw. This is the trick the
rest of the unit runs on.

## What the sign tells you

Because $|\vec{a}|$ and $|\vec{b}|$ are positive, the sign of the
dot product belongs entirely to $\cos\theta$:

| $\vec{a} \cdot \vec{b}$ | Angle between | Meaning |
| --- | --- | --- |
| positive | less than $90°$ | broadly agreeing directions |
| zero | exactly $90°$ | perpendicular — **orthogonal** |
| negative | more than $90°$ | broadly opposed directions |

The middle row does the most work in this course: a dot product of
zero is a perpendicularity *test*, no picture required. It is how
[[Equations of Planes]] will define a plane with one vector.

The properties got the [[True or False]] treatment before anyone
trusted them: commutative — true, both formulas are symmetric;
$\vec{a} \cdot \vec{a}$ — always $|\vec{a}|^2$, a vector dotted with
itself squares its own length; associative — *not even a
well-formed question*, since $\vec{a} \cdot \vec{b}$ is a scalar and
cannot dot anything further. Knowing why that last one fails is
worth more than ten computations. [[Dot and Cross Product Practice]]
covers angles, work, and projections; the product that *keeps*
direction instead of measuring it is [[The Cross Product]].

%%curriculum-start%%
## Curriculum connection

![[C2.4]]

![[C2.5]]

![[C2.8]]
%%curriculum-end%%
