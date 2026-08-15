---
title: The Cosine Law
publish: true
created: __CREATED__
tags:
  - concepts
---
At the boards, a triangle arrived as two sides and the angle wedged
between them — and [[The Sine Law]] could not start, because no known
side faced a known angle. The tool for exactly this arrangement looks
like an old friend with a correction bolted on:

$$
a^2 = b^2 + c^2 - 2bc \cos A
$$

## Pythagoras, corrected

Set $A = 90°$ and $\cos A = 0$: the correction term vanishes and the
law *is* the Pythagorean theorem. For angles under 90° the cosine is
positive and the correction subtracts — the side facing a sharp angle
is shorter than Pythagoras would guess. Past 90° the cosine goes
negative, the subtraction becomes addition, and the facing side grows.
The law is Pythagoras that knows what angle it is looking at.

With $b = 6$ m, $c = 9$ m, and $\angle A = 75°$ between them:

$$
a^2 = 36 + 81 - 2(6)(9)\cos 75° \approx 89.1
\quad\Longrightarrow\quad a \approx 9.4 \text{ m}
$$

Given all three sides instead, rearrange to hunt an angle:

$$
\cos A = \frac{b^2 + c^2 - a^2}{2bc}
$$

Hunt the *largest* angle first — it faces the longest side — and a
negative cosine on the way out is not an error; it is the law
reporting an obtuse angle, exactly as [[Special Angles]] said it
would.

## Choosing your tool

> [!tip] One question decides
> Does some known side face a known angle? **Yes** — sine law (or
> primary ratios, if a right angle is present). **No** — cosine law:
> two sides and the contained angle give a side; three sides give an
> angle. After the cosine law's first move, a matched pair exists and
> the sine law reopens for the rest of the triangle.

Three-dimensional problems — a cliff across a river, a tower seen
from two places — fall to the same two laws. The skill is spotting
the *pair* of triangles that share an edge: solve the one you can,
carry the shared edge to the other, and the third dimension never
needs new mathematics. That carrying move is worth narrating out loud
when you write solutions — it is the step
[[Showing Your Thinking]] exists for.

The tool-choosing habit — and the triangles of
[[How High Is That?]] — get their workout in
[[Trig Ratios and Laws Practice]].

%%curriculum-start%%
## Curriculum connection

![[D1.6]]

![[D1.7]]
%%curriculum-end%%
