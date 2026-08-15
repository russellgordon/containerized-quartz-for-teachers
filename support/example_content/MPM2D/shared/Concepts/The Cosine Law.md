---
title: The Cosine Law
publish: true
created: __CREATED__
tags:
  - concepts
---
Some triangles keep their secrets from the sine law. Given two
sides and the angle pinched between them, no angle faces a known
side — no matched pair, so [[The Sine Law]]'s chain of equal
fractions has nothing to hold. The cosine law was built for this:

$$
c^2 = a^2 + b^2 - 2ab\cos C
$$

Read it slowly and an old friend appears: $c^2 = a^2 + b^2$ is the
Pythagorean theorem, and $2ab\cos C$ is a correction term that
accounts for $C$ not being a right angle.[^1] Squeeze $C$ smaller
and the correction grows, pulling the far side in shorter; open $C$
wider and the correction shrinks, letting the far side stretch. The
cosine law is Pythagoras, generalised to every triangle.

## When to reach for it

- **Two sides and the contained angle** — the formula produces the
  third side directly.
- **All three sides and no angles** — rearrange to extract an angle:

$$
\cos C = \frac{a^2 + b^2 - c^2}{2ab}
$$

These are precisely the two situations with no matched angle-side
pair. Once the cosine law breaks the deadlock — one new side or one
new angle — the sine law usually finishes the triangle faster.

## Using it

Two trails leave a campsite at $65°$ to each other; hikers walk
4.0 km along one and 6.5 km along the other. How far apart are they?

$$
d^2 = 4.0^2 + 6.5^2 - 2(4.0)(6.5)\cos 65° \approx 36.3
$$

so $d \approx 6.0$ km. Keep the whole expression in the calculator
until the last step — rounding $\cos 65°$ early is the classic way
to drift off the answer, exactly the slip [[Checking Your Own Work]]
is designed to surface. A quick sketch gives sanity bounds first:
the distance must land between $2.5$ km and $10.5$ km, the
difference and sum of the two walks.

[[Trig Ratios and Laws Practice]] pairs both laws so the choosing
is practised, not just the computing — and the choice is most of
the thinking in [[Inaccessible Heights]] and [[The Math Symposium]].

[^1]: Set $C = 90°$: since $\cos 90° = 0$, the correction vanishes,
    leaving $c^2 = a^2 + b^2$. Pythagoras is the cosine law on the
    special day the angle is right.

%%curriculum-start%%
## Curriculum connection

![[C3.2]]

![[C3.3]]

![[C3.4]]
%%curriculum-end%%
