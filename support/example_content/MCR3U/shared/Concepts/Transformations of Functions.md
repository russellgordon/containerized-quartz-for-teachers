---
title: Transformations of Functions
draft: false
created: __CREATED__
tags:
  - concepts
---
At the boards, your group graphed $y = \sqrt{x}$, $y = \sqrt{x} + 3$,
$y = \sqrt{x - 2}$, and $y = -\sqrt{x}$ — and someone said "these are
all the same graph, just moved." That sentence is the whole topic. In
Grade 10 you learned three moves that turn $y = x^2$ into any
parabola. The news this year is better than a new set of rules: there
are no new rules. The same moves work on *every* function you will
ever meet.

## The recipe

Start from any parent function $y = f(x)$ — squaring, square root,
$\frac{1}{x}$, and soon [[The Exponential Function|exponentials]] and
[[Sinusoidal Functions|sinusoids]]. Then

$$y = a\,f(k(x - d)) + c$$

is the parent after four moves:

| Letter | The move | Watch for |
| --- | --- | --- |
| $a$ | Stretch vertically by $a$; negative flips over the x-axis | Heights multiply |
| $k$ | Compress horizontally by $k$; negative flips over the y-axis | Widths *divide* by $k$ |
| $d$ | Slide right by $d$ | Hides inside the bracket with a minus sign |
| $c$ | Slide up by $c$ | The only honest letter of the four |

The two inside letters, $k$ and $d$, act on $x$ *before* the function
does — which is why they behave backwards: $f(x - 2)$ slides right,
not left, and $f(2x)$ squeezes rather than stretches. The function is
a machine; whatever you do to the input, the graph shows the reverse.

## One point at a time

A transformation is really an instruction for moving *points*: the
point $(x, y)$ on the parent lands at
$\left(\frac{x}{k} + d,\; ay + c\right)$ on the image. To sketch
$y = -2f\!\left(\tfrac{1}{2}(x + 1)\right) + 3$, take three or four
known points of the parent and push each one through:

- [ ] Multiply each $x$ by 2 (undoing the $\tfrac{1}{2}$), then
      subtract 1.
- [ ] Multiply each $y$ by $-2$, then add 3.
- [ ] Plot the image points; join with the parent's shape in mind.
- [ ] Confirm one point in the equation — or the whole curve in
      [[Using Desmos]].

Stretch first, slide second — the same order as Grade 10, for the
same reason: sliding first drags your anchor points out of position,
and the graph betrays it immediately.

Where this pays off: every function family in this course —
exponential, sinusoidal, and the ones you meet after it — arrives as
a parent plus this recipe. Learn the recipe once and each new family
costs you one parent graph, not a chapter.
[[Transformations Practice]] turns it from a procedure into a reflex.

%%curriculum-start%%
## Curriculum connection

![[A1.8]]

![[A1.9]]
%%curriculum-end%%
