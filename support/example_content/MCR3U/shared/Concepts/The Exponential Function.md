---
title: The Exponential Function
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
When your group graphed the layer counts from
[[Folding Paper to the Moon]], the dots hugged the floor and then
left the page — a shape no line or parabola makes. Join those dots
and you have $f(x) = 2^x$: the exponential function. In general,

$$
f(x) = a^x, \qquad a > 0,\ a \ne 1
$$

is a function — each input gets exactly one output — and thanks to
[[Rational Exponents]] it now makes sense at *every* real input, not
just whole numbers.

## The tell: a constant ratio

A linear function grows by *adding* the same amount each step; an
exponential grows by *multiplying* by the same factor each step. That
is how you unmask one in a table of values: first differences equal
means linear, second differences equal means quadratic, but a
constant *ratio* between consecutive outputs means exponential. The
values $3, 6, 12, 24$ whisper "ratio 2" — no graph required.

## Key properties

For $f(x) = a^x$, every member of the family shares:

- domain: all real numbers; range: $y > 0$ — the output is a power
  of a positive base, and no such power is zero or negative
- $y$-intercept 1, because $a^0 = 1$
- horizontal asymptote $y = 0$ — the graph approaches the axis and
  never arrives
- increasing everywhere when $a > 1$; decreasing everywhere when
  $0 < a < 1$ — never flat, which is why $a = 1$ is excluded

And the recipe from [[Transformations of Functions]] applies without
amendment: $y = a \cdot 2^{k(x - d)} + c$ moves this parent exactly
as it moved $x^2$ and $\sqrt{x}$. Note where the asymptote goes — it
rides the vertical shift up to $y = c$, which drags the range along.

## Growth, decay, and the real world

Real situations arrive as *initial amount times repeated multiplier*:
a town growing 3% per year is $P(t) = P_0(1.03)^t$; a medication with
a half-life of 6 hours is $M(t) = M_0\left(\frac{1}{2}\right)^{t/6}$.
Questions about the future are answered by substituting into the
equation; questions in reverse ("when does it reach 28°C?") are
answered from the graph or by systematic guess-and-check —
[[Using Desmos]] handles both gracefully.

> [!success]- Check your understanding
> A ball dropped from 2 m rebounds to 60% of its previous height on
> each bounce. How high is bounce four?
> Each bounce multiplies by 0.6, so
> $h = 2(0.6)^4 = 2(0.1296) \approx 0.26$ m. Sanity check: four
> multiplications by a number below 1 *should* leave under an eighth
> of the original height, and it does.

Whether a situation is genuinely exponential — and what its domain
honestly means — is the heart of [[Double or Nothing]], and the same
mathematics runs [[Money Over Time|compound interest]].
[[Exponential Models Practice]] covers the full span, from properties
to predictions.

%%curriculum-start%%
## Curriculum connection

![[B1.1]]

![[B1.4]]

![[B2.1]]

![[B3.3]]
%%curriculum-end%%
