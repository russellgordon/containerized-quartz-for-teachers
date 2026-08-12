---
title: Rational Functions Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Rational Functions]] and [[Asymptotes]],
with the inequalities from
[[Polynomial and Rational Inequalities]] at the end. Name every
asymptote and hole before you sketch — the naming is most of the
sketch.

## Asymptotes and key features

1. For $f(x) = \dfrac{1}{x^2 - 4}$: state the vertical and
   horizontal asymptotes, the y-intercept, and the domain.
2. For $f(x) = \dfrac{2x}{x - 3}$: state the asymptotes and both
   intercepts.
3. For $f(x) = \dfrac{x - 2}{3x + 4}$: state the asymptotes and both
   intercepts.
4. Describe the graph of $f(x) = \dfrac{x^2 - 1}{x - 1}$ completely.
   Something here is not an asymptote.

> [!success]- Answer 1
> The denominator factors as $(x-2)(x+2)$, and neither factor
> cancels: vertical asymptotes $x = 2$ and $x = -2$. The
> denominator's degree beats the numerator's, so the horizontal
> asymptote is $y = 0$. y-intercept: $f(0) = -\frac{1}{4}$. Domain:
> all reals except $\pm 2$. The function keeps the same sign as
> $x^2 - 4$: negative between the asymptotes, positive outside.

> [!success]- Answer 2
> Vertical asymptote $x = 3$; equal degrees top and bottom, so the
> horizontal asymptote is the ratio of leading coefficients,
> $y = 2$. The numerator is zero at $x = 0$, so the graph passes
> through the origin — x-intercept and y-intercept in one point.

> [!success]- Answer 3
> Vertical asymptote where $3x + 4 = 0$: $x = -\frac{4}{3}$. Equal
> degrees: horizontal asymptote $y = \frac{1}{3}$. x-intercept from
> the numerator: $x = 2$. y-intercept:
> $f(0) = \frac{-2}{4} = -\frac{1}{2}$.

> [!success]- Answer 4
> The numerator factors as $(x-1)(x+1)$ and the $x - 1$ *cancels* —
> so there is no vertical asymptote. The graph is the line
> $y = x + 1$ with a single point missing: a hole at $(1, 2)$. The
> domain still excludes $x = 1$; simplifying changes the formula,
> never the domain.

## Equations

5. Solve $\dfrac{x - 2}{x - 3} = 0$, and explain why
   $\dfrac{1}{x - 3} = 0$ has no solution.
6. Solve $\dfrac{x}{x + 2} = 3$.
7. Use division to write $f(x) = \dfrac{x^2 + 2x - 7}{x - 2}$ as a
   polynomial plus a rational remainder term, and describe how the
   graph behaves for very large $|x|$.

> [!success]- Answer 5
> A rational expression is zero only when its numerator is zero:
> $x = 2$ (and the denominator is fine there: $2 - 3 \ne 0$). For
> $\frac{1}{x-3}$, the numerator is the constant 1, which is never
> zero — no roots, which is why that graph never touches the x-axis.

> [!success]- Answer 6
> Multiply both sides by $x + 2$ (noting $x \ne -2$):
> $x = 3x + 6$, so $-2x = 6$ and $x = -3$. Audit against the
> original: $\frac{-3}{-1} = 3$. ✓ The candidate survived the check,
> so it is a solution — the check is not optional politeness.

> [!success]- Answer 7
> Dividing: $x^2 + 2x - 7 = (x - 2)(x + 4) + 1$, so
> $f(x) = x + 4 + \dfrac{1}{x - 2}$. For large $|x|$ the fraction
> fades to nothing, so the graph hugs the line $y = x + 4$ — an
> asymptote that is a slanted line. Verify the division:
> $(x-2)(x+4) + 1 = x^2 + 2x - 8 + 1 = x^2 + 2x - 7$. ✓

## Inequalities

8. Solve $\dfrac{1}{x + 2} < 3$.
9. Solve $\dfrac{x + 1}{x - 1} \ge 2$.

> [!success]- Answer 8
> Do not multiply by $x + 2$ — its sign is unknown. Move everything
> left: $\frac{1}{x+2} - 3 = \frac{1 - 3(x+2)}{x+2} =
> \frac{-3x - 5}{x + 2} < 0$. Boundaries: zero at
> $x = -\frac{5}{3}$, break at $x = -2$. Testing the three
> intervals: at $x = -3$, $\frac{4}{-1} < 0$ ✓; at $x = -1.8$,
> $\frac{0.4}{0.2} > 0$ ✗; at $x = 0$, $\frac{-5}{2} < 0$ ✓.
> Solution: $x < -2$ or $x > -\frac{5}{3}$. Both boundaries
> excluded — one is a strict inequality's zero, the other does not
> exist.

> [!success]- Answer 9
> Subtract 2:
> $\frac{x + 1 - 2(x - 1)}{x - 1} = \frac{3 - x}{x - 1} \ge 0$.
> Boundaries: zero at $x = 3$, break at $x = 1$. Test $x = 2$:
> $\frac{1}{1} > 0$ ✓; outside that interval the expression is
> negative (test $x = 0$: $\frac{3}{-1} < 0$; test $x = 4$:
> $\frac{-1}{3} < 0$). Include $x = 3$ (the $\ge$ allows equality),
> never $x = 1$. Solution: $1 < x \le 3$.
