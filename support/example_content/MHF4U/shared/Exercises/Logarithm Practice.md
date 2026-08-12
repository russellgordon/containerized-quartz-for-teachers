---
title: Logarithm Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[The Logarithm]] and [[Laws of Logarithms]] —
evaluating, estimating, simplifying, and the equations underneath
real applications. Estimate before you compute; the estimate audits
the algebra.

## Evaluating and estimating

1. Evaluate exactly: $\log_2 32$, $\log_3\dfrac{1}{9}$,
   $\log_{10} 0.001$.
2. Between which two integers does $\log_3 29$ lie, and which is it
   closer to? Then find it to two decimal places with technology.
3. Explain why neither $\log_2 0$ nor $\log_{10}(-3)$ exists.

> [!success]- Answer 1
> Each is the question "the base to what exponent gives this?"
> $2^5 = 32$, so $\log_2 32 = 5$. $3^{-2} = \frac{1}{9}$, so
> $\log_3\frac{1}{9} = -2$. $10^{-3} = 0.001$, so
> $\log_{10} 0.001 = -3$.

> [!success]- Answer 2
> $3^3 = 27$ and $3^4 = 81$, so $\log_3 29$ is between 3 and 4 —
> and 29 sits just past 27, so much closer to 3. Systematic trial
> (or $\frac{\log 29}{\log 3}$) gives $\approx 3.07$. The estimate
> came first and vouches for the decimal.

> [!success]- Answer 3
> A positive base raised to any exponent is positive — never zero,
> never negative. So "2 to what power gives 0?" and "10 to what
> power gives $-3$?" have no answers at all. This is the same fact
> as the exponential graph's horizontal asymptote, said in algebra.

## Laws of logarithms

4. Evaluate using the laws: (a) $\log_{10} 4 + \log_{10} 25$
   (b) $\log_2 48 - \log_2 3$ (c) $\log_5 25^3$.
5. Show that $f(x) = \log_{10}(100x)$ and $g(x) = 2 + \log_{10} x$
   are the same function.

> [!success]- Answer 4
> (a) Product law: $\log_{10}(4 \times 25) = \log_{10} 100 = 2$.
> (b) Quotient law: $\log_2\frac{48}{3} = \log_2 16 = 4$.
> (c) Power law: $3\log_5 25 = 3 \times 2 = 6$.
> None of these numbers were reachable one logarithm at a time —
> the laws built easy questions out of hard-looking ones.

> [!success]- Answer 5
> Product law on $f$:
> $\log_{10}(100x) = \log_{10}100 + \log_{10}x = 2 + \log_{10}x =
> g(x)$, for every $x > 0$. Graphically: multiplying the input by
> 100 and shifting the output up 2 are the *same move* for a base-10
> logarithm — a disguise the laws see through immediately.

## Solving equations

6. Solve $3^x = 10$, exactly and then to three decimal places.
7. Solve $9^x = 27^{x - 1}$ without a calculator.
8. Solve $\log_2(3x - 1) = 4$.
9. An investment grows by $300(1.05)^n$ dollars over $n$ years. How
   long until it doubles from \$300 to \$600?

> [!success]- Answer 6
> Rewrite in logarithmic form: $x = \log_3 10$, exactly. For the
> decimal, take base-10 logarithms of both sides:
> $x = \frac{\log 10}{\log 3} = \frac{1}{\log 3} \approx 2.096$.
> Estimate check: $3^2 = 9$ sits just under 10, so $x$ just over
> 2. ✓

> [!success]- Answer 7
> Common base 3: $(3^2)^x = (3^3)^{x-1}$, so $3^{2x} = 3^{3x-3}$.
> Equal bases force equal exponents: $2x = 3x - 3$, so $x = 3$.
> Check: $9^3 = 729$ and $27^2 = 729$. ✓ With a common base
> available, no logarithm was needed.

> [!success]- Answer 8
> Exponential form: $3x - 1 = 2^4 = 16$, so $x = \frac{17}{3}$.
> Audit the argument: $3 \times \frac{17}{3} - 1 = 16 > 0$, so the
> logarithm exists and the solution stands. That check is the whole
> reason to slow down on log equations.

> [!success]- Answer 9
> Solve $300(1.05)^n = 600$: divide first, $(1.05)^n = 2$, then
> take logarithms: $n = \frac{\log 2}{\log 1.05} \approx 14.2$
> years. The 300 divided away — doubling time does not care how
> much you started with, which is the signature of exponential
> growth.
