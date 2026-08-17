---
title: The Sine Law
publish: true
created: __CREATED__
tags:
  - concepts
---
The surveying triangles at the boards had no right angle anywhere,
and the primary ratios from Grade 10 refused to start — opposite and
hypotenuse mean nothing without a hypotenuse. Oblique triangles need
their own tools. Label a triangle the standard way — side $a$ facing
angle $A$, side $b$ facing $B$, side $c$ facing $C$ — and:

$$
\frac{a}{\sin A} = \frac{b}{\sin B} = \frac{c}{\sin C}
$$

Every side, divided by the sine of the angle it faces, gives the same
number. Drag a vertex around in [[Using Desmos|Desmos]] or any
dynamic geometry tool and watch the three fractions move in lockstep;
that hidden constant is the whole law.

## When it applies

Each equation in the chain has four parts, so you can solve one as
soon as three are known. That means the sine law needs a *matched
pair* — a side together with the angle facing it — plus one more
angle or side. Two angles and any side works (the third angle comes
free from the 180° sum). A matched pair plus one extra side works
too. But two sides with only the angle *between* them known gives no
complete fraction to stand on — that arrangement belongs to
[[The Cosine Law]]. Before either law, always ask: does some known
side face a known angle?

In practice: with $\angle A = 44°$, $\angle B = 71°$, and $a = 12$ m,

$$
b = \frac{12 \sin 71°}{\sin 44°} \approx 16.3 \text{ m}
$$

— and since $71° > 44°$, the answer *had* to beat 12 m. Run that
bigger-angle-faces-bigger-side comparison before every calculation;
it costs one second and catches flipped fractions instantly.

## The ambiguous case

> [!warning] Two triangles can hide in one question
> Solving for an *angle* with the sine law can return a disguised
> pair. Given $\angle A = 35°$, $a = 7$, and $b = 10$:
> $\sin B = \frac{10 \sin 35°}{7} \approx 0.8194$, and as
> [[Special Angles]] showed, two angles under 180° share that sine —
> $B \approx 55°$ or $B \approx 125°$. Check both against the angle
> budget: $35° + 55°$ and $35° + 125°$ each stay under 180°, so
> *both* triangles genuinely exist, with different shapes and
> different third sides.

Picture side $a$ as a swinging arm hinged at $C$: too long to miss,
it can touch the base on the near side of vertical or the far side.
When a question hands you two sides and a *non-included* angle, name
both candidates, test both, and report every triangle that survives.
Finding the second triangle your groupmate missed — or the one you
missed — is [[Mistakes Are Data]] in its natural habitat.

The sine law carried the measuring work in [[How High Is That|How High Is That?]], and
[[Trig Ratios and Laws Practice]] mixes it with the cosine law so
that *choosing* becomes part of the skill.

%%curriculum-start%%
## Curriculum connection

![[D1.6]]

![[D1.7]]
%%curriculum-end%%
