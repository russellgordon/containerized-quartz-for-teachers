---
title: Equivalent Algebraic Expressions
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Two groups simplified the same expression at the boards and arrived
at answers that looked nothing alike — and both survived every test
the class threw at them. That standoff is the topic. Two expressions
are *equivalent* when they take the same value for every input both
are allowed. "Looks different" is not evidence.

## Two tests, one warning

To show two expressions are equivalent, simplify both until they
match — that is a proof. To show they are *not*, find one input where
they disagree — that is also a proof. But matching at a few inputs
proves nothing by itself: it builds confidence, not certainty. Are
$\frac{2x^2 - 4x - 6}{x + 1}$ and $8x^2 - 2x(4x - 1) - 6$ equivalent?
The second collapses to $2x - 6$. The first factors:

$$
\frac{2(x - 3)(x + 1)}{x + 1} = 2x - 6, \quad x \ne -1
$$

Almost equivalent — but at $x = -1$ the first expression has no
value at all. That fine print is the theme of this whole page.

## Radicals without fear

Because $\sqrt{ab} = \sqrt{a} \times \sqrt{b}$ for $a, b \ge 0$, a
radical can be split at any square factor: $\sqrt{24} =
\sqrt{4}\,\sqrt{6} = 2\sqrt{6}$. The same law tidies products —
expand like any binomials, then simplify each radical:

$$
(2 + \sqrt{6})(3 - \sqrt{12})
= 6 - 2\sqrt{12} + 3\sqrt{6} - \sqrt{72}
= 6 - 4\sqrt{3} + 3\sqrt{6} - 6\sqrt{2}
$$

No like terms among $\sqrt{3}$, $\sqrt{6}$, and $\sqrt{2}$ — so that
is the finished form, even though it looks unfinished.

## Rational expressions and their fine print

Rational expressions add, subtract, multiply, and divide like
numerical fractions — common denominators and all — with one extra
duty: state the *restrictions*, the input values that make any
denominator zero, and state them from the *original* expression,
before anything cancels. A cancelled factor is a crime scene tidied
up; the restriction is the record that it happened.

> [!success]- Check your understanding
> Simplify $\dfrac{2x}{4x^2 + 6x} - \dfrac{3}{2x + 3}$.
>
> Factor the first denominator: $4x^2 + 6x = 2x(2x + 3)$, so the
> first fraction is $\dfrac{2x}{2x(2x + 3)} = \dfrac{1}{2x + 3}$ —
> recording $x \ne 0$ and $x \ne -\frac{3}{2}$ on the way past. Then
> $\dfrac{1}{2x + 3} - \dfrac{3}{2x + 3} = \dfrac{-2}{2x + 3}$, with
> $x \ne 0, -\frac{3}{2}$.

A claim built for [[Always, Sometimes, Never]]: "two expressions that
agree at $x = 1$ are equivalent." Sometimes — and the
counter-examples you build to say so are exactly the thinking
[[Mistakes Are Data]] celebrates. These skills surface all
semester, whenever simplifying is the road through a problem.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.2]]

![[A3.3]]

![[A3.4]]
%%curriculum-end%%
