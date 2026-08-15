---
title: The Sine Law
publish: true
created: __CREATED__
tags:
  - concepts
---
The ratios in [[The Primary Trigonometric Ratios]] need a right
angle to stand on — opposite and hypotenuse only make sense when a
hypotenuse exists. But at the boards, surveying setups kept
producing triangles with no right angle anywhere. Acute triangles
need their own tools, and the sine law is the first.

Label an acute triangle the standard way — side $a$ opposite angle
$A$, side $b$ opposite $B$, side $c$ opposite $C$. Then:

$$
\frac{a}{\sin A} = \frac{b}{\sin B} = \frac{c}{\sin C}
$$

Each side, divided by the sine of the angle across from it, gives
the same number — a hidden constant of the triangle. Dragging a
vertex in dynamic geometry software and watching all three fractions
move in lockstep is the fastest way to believe it.

## When the sine law applies

The law is a chain of equal fractions, and a fraction pair can only
be solved when three of its four parts are known. So the sine law
needs a *matched pair* — an angle together with its opposite side —
plus one more angle or side. Two angles and any side? Sine law. A
matched pair and one extra side? Sine law. But two sides with only
the angle *between* them known gives the law nothing to grab — that
is [[The Cosine Law]]'s territory.

## Using it

In $\triangle ABC$, $\angle A = 48°$, $\angle B = 62°$, and
$a = 15$ cm. Find $b$. The matched pair is $a$ and $A$:

$$
\frac{b}{\sin 62°} = \frac{15}{\sin 48°} \implies
b = \frac{15 \sin 62°}{\sin 48°} \approx 17.8 \text{ cm}
$$

Sanity-check before the calculator confirms it: $62° > 48°$, and
larger angles sit across from larger sides, so $b$ *had* to come
out bigger than 15. That one-second comparison catches a transposed
ratio faster than any re-computation.

> [!success]- Quick self-check (click to expand)
> Same triangle: find $c$. First,
> $\angle C = 180° - 48° - 62° = 70°$. Then
> $c = \dfrac{15 \sin 70°}{\sin 48°} \approx 19.0$ cm — the largest
> side, opposite the largest angle, exactly as it should be.

[[Trig Ratios and Laws Practice]] mixes right-triangle and sine-law
problems so that *choosing* the tool becomes part of the practice,
and [[Inaccessible Heights]] supplies the triangles nobody can walk
through the middle of.

%%curriculum-start%%
## Curriculum connection

![[C3.1]]

![[C3.3]]
%%curriculum-end%%
