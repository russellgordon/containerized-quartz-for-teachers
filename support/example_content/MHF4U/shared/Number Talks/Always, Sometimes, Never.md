---
title: Always, Sometimes, Never
publish: true
created: __CREATED__
tags:
  - number-talks
---
A claim goes up — "a polynomial function of odd degree has at least
one $x$-intercept" — and everyone must file it under *always*,
*sometimes*, or *never*. "Sometimes" is not a shrug: it obliges you
to produce a case where the claim holds, one where it fails, and the
exact boundary between them.

## How we play

1. Classify silently first. Gut verdicts welcome; they get audited.
2. "Always" and "never" demand an argument covering every case.
3. "Sometimes" demands an example, a counter-example, and the boundary.

> [!example]- The odd-degree claim, argued
> - "$y = x^3$ crosses at the origin. $y = x^3 + 5$ still crosses,
>   just further left. Not *never*."
> - "Could a cubic dodge the axis the way $y = x^2 + 1$ does? Its
>   ends point opposite ways — one arm is eventually below the axis
>   and the other eventually above."
> - "And a polynomial has no breaks — no asymptote to hide behind,
>   no gap to jump through. A curve that starts below and ends above
>   must cross somewhere."
> - "So: *always*, and the end behaviour forces it. The even-degree
>   version is the *sometimes* — $x^2 + 1$ never lands, $x^2 - 1$
>   lands twice, and the boundary is whether the range reaches zero."

## One variation

Claims from the rest of the course: "a rational function has a
vertical asymptote" — sometimes. $\frac{1}{x^2 + 1}$ never does,
because its denominator never reaches zero; and
$\frac{x^2 - 4}{x - 2}$ hides a hole where the asymptote should be,
because the factor cancels. Saying *which* denominator zeros survive
is the exact line [[Asymptotes]] teaches you to draw, and the graphs
of [[Rational Functions]] live on either side of it.

> [!tip] "Sometimes" is where the mathematics is
> The boundary of a claim is its content. One claim this course
> walks right up to without settling: *as the interval shrinks, the
> average rate of change settles on a single value*. Deciding
> exactly when that is true is, almost word for word, the question
> calculus asks — [[Rates of Change]] takes you to its edge.
