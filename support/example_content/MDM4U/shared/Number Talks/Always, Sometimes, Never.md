---
title: Always, Sometimes, Never
publish: true
created: __CREATED__
tags:
  - number-talks
---
A claim goes up — "a probability is the number of favourable outcomes
divided by the total number of outcomes" — and everyone must file it
under *always*, *sometimes*, or *never*. "Sometimes" is not a shrug:
it obliges you to produce a case where the claim holds, one where it
fails, and the exact boundary between them.

## How we play

1. Classify silently first. Gut verdicts welcome; they get audited.
2. "Always" and "never" demand an argument covering every case.
3. "Sometimes" demands an example, a counter-example, and the
   boundary.

> [!example]- The counting-outcomes claim, argued
> - "Always. A fair die has six outcomes and three of them are even,
>   so $P(\text{even}) = \frac{3}{6} = \frac{1}{2}$. Every fair-die
>   question I have ever seen works this way."
> - "Not always. Roll two dice and ask for a total of 7. The possible
>   totals are 2 through 12, which is 11 outcomes, so the claim says
>   $\frac{1}{11}$, about 0.09. Simulate it and you get about 0.17
>   every time. The claim just lost."
> - "Because the eleven totals are not equally likely. A total of 2
>   can happen one way; a total of 7 can happen six ways. Go back to
>   the 36 *ordered pairs*, which genuinely are equally likely, and
>   the count works perfectly: $\frac{6}{36} = \frac{1}{6}$, about
>   0.17, exactly what the simulation said."
> - "So: *sometimes*, and the boundary is razor sharp — the claim
>   holds precisely when the outcomes you are counting are equally
>   likely. 'The bus is either on time or late, so it is 50-50' is
>   the same error in a coat."

## One variation

A claim from the statistics weeks: "if two variables have a
correlation near 1, one of them causes the other." Not *never* —
sometimes the cause is real and the correlation is how you found it.
Not *always* — ice cream sales and drownings rise together every
summer, and neither causes the other; the heat causes both. So
*sometimes*, and here the boundary is the uncomfortable part: the
correlation coefficient itself contains no information about which
case you are in. It is a number about the *shape of a cloud of
points*, and it will report 0.98 just as cheerfully for a coincidence
as for a mechanism. [[Correlation and Causation]] is where the room
learns what evidence actually settles it, and
[[The Spurious Correlation Hunt]] is where you go looking for
beautiful lies.

> [!tip] "Sometimes" is where the mathematics is
> The boundary of a claim is its content. Everyone can already say
> "correlation is not causation"; almost nobody can say what *would*
> establish causation, or name the third variable in a specific case.
> The slogan is free. The boundary is the course.
