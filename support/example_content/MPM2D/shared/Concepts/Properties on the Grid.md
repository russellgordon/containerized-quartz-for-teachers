---
title: Properties on the Grid
draft: false
created: __CREATED__
tags:
  - concepts
---
"It looks like a rectangle" is an observation. "The diagonals share
a midpoint and adjacent sides have perpendicular slopes" is
evidence. Analytic geometry turns the first into the second: once a
figure's vertices have coordinates, its properties stop being
impressions and become claims you can *verify* — which is the
standard [[What Makes a Proof Convincing]] keeps asking about.

## The toolkit

Every verification job on the grid runs on three measurements, all
built from [[Midpoint and Length]] and slope:

- [ ] **Length** — are these sides equal? Distance formula.
- [ ] **Slope** — are these sides parallel (equal slopes) or
      perpendicular (slopes multiplying to $-1$)?
- [ ] **Midpoint** — do the diagonals bisect each other (share one
      midpoint)?

The skill is matching claim to tool. "Isosceles" is a length
question. "Right angle" is a slope question. "The diagonals bisect
each other" is a midpoint question wearing a fancy verb.

## A verification, start to finish

Claim: $A(0, 0)$, $B(6, 3)$, $C(4, 7)$, $D(-2, 4)$ form a
rectangle. Plan first, compute second — a rectangle needs opposite
sides parallel and one right angle, so slopes can do the whole job:

$$
m_{AB} = \frac{3 - 0}{6 - 0} = \frac{1}{2} \qquad
m_{BC} = \frac{7 - 3}{4 - 6} = -2
$$

$$
m_{CD} = \frac{4 - 7}{-2 - 4} = \frac{1}{2} \qquad
m_{DA} = \frac{0 - 4}{0 - (-2)} = -2
$$

Opposite sides are parallel, and $\frac{1}{2} \times (-2) = -1$
makes adjacent sides perpendicular — a parallelogram with a right
angle. Rectangle, verified. (Is it a square? That is now a length
question: $AB = \sqrt{45}$ but $BC = \sqrt{20}$, so no.)

The closing sentence matters as much as the arithmetic. Numbers
alone are not a conclusion; the because-sentence tying them to the
claim is — that habit is [[Showing Your Thinking]], applied to
geometry. And a multi-step plan stated *before* the computing starts
separates an investigation from a lucky wander. It is exactly the
skill [[The Quadrilateral Case File]] will demand when you are
handed four mystery vertices and asked what the figure truly is.

%%curriculum-start%%
## Curriculum connection

![[B3.2]]

![[B3.3]]
%%curriculum-end%%
