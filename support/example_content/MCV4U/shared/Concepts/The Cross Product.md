---
title: The Cross Product
draft: false
created: __CREATED__
tags:
  - concepts
---
Today's opening problem was physical: a wrench on a stubborn bolt.
Where do you push, and which way, to turn it hardest? Push along the
handle and nothing turns at all; push perpendicular to it, out at
the end, and the bolt gives. The turning effect — torque — depends
on two vectors, and it *is* one: it points along the bolt's axis,
perpendicular to both the handle and your push. What multiplication
takes two vectors and produces a third, perpendicular to both? That
is the cross product — the product that points.

$$\vec{a} \times \vec{b} = (a_2b_3 - a_3b_2,\; a_3b_1 - a_1b_3,\; a_1b_2 - a_2b_1)$$

The formula looks like a tongue-twister; the pattern is a cycle
($1 \to 2 \to 3 \to 1$), and it exists only in three-space. For
$\vec{a} = (2, 0, 0)$ and $\vec{b} = (0, 3, 0)$ — one vector along
each of the first two axes — the product is $(0, 0, 6)$, straight up
the third. Two directions in, the missing direction out.

> [!question]- Self-check: is $(0, 0, 6)$ really perpendicular to
> both?
> Test with the tool from [[The Dot Product]]:
> $(2, 0, 0) \cdot (0, 0, 6) = 0$ and
> $(0, 3, 0) \cdot (0, 0, 6) = 0$. Both zero, both perpendicular.
> This check works on *every* cross product you will ever compute —
> dot your answer with each original vector, and anything nonzero
> means an arithmetic slip. A self-marking computation is a gift;
> take it every time.

## The magnitude is an area

The direction is perpendicular; the size has its own meaning:

$$|\vec{a} \times \vec{b}| = |\vec{a}||\vec{b}|\sin\theta$$

That $\sin\theta$ is precisely the height factor of the
parallelogram with sides $\vec{a}$ and $\vec{b}$ — so the magnitude
of the cross product *is that parallelogram's area*. Where the dot
product's $\cos\theta$ rewarded agreement, $\sin\theta$ rewards
perpendicularity: the cross product of parallel vectors is the zero
vector (no parallelogram at all), and the wrench turns hardest when
your push meets the handle at $90°$.

The properties earned an [[Always, Sometimes, Never]] round:
$\vec{a} \times \vec{b} = \vec{b} \times \vec{a}$ — *never*, unless
the result is zero; reversing the order flips the answer's
direction. Not commutative — the first product you have ever met
that cares about order, which is exactly why it can encode
orientation. [[Dot and Cross Product Practice]] has areas, torque,
and normals; [[Equations of Planes]] is where "a vector
perpendicular to two others" stops being a curiosity and becomes
the whole method.

%%curriculum-start%%
## Curriculum connection

![[C2.6]]

![[C2.7]]

![[C2.8]]
%%curriculum-end%%
