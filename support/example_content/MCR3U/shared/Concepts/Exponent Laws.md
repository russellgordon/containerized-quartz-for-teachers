---
title: Exponent Laws
publish: true
created: __CREATED__
tags:
  - concepts
---
In [[Folding Paper to the Moon]], the layer count doubled past every
estimate in the room, and keeping track meant multiplying powers of 2
at speed. The laws below are not new facts to memorise — each one is
just *counting factors*, and if you can rebuild a law in ten seconds
you never need to trust your memory of it.

## Laws you can rebuild

| Law | In symbols | Rebuild it by |
| --- | --- | --- |
| Product | $x^a \cdot x^b = x^{a+b}$ | counting factors: $a$ of them, then $b$ more |
| Quotient | $x^a \div x^b = x^{a-b}$ | cancelling $b$ factors from the top |
| Power of a power | $\left(x^a\right)^b = x^{ab}$ | $a$ factors, written down $b$ times |

The third law is quietly the most useful in this course: it lets one
function wear different bases. Since $9 = 3^2$,

$$
9^x = \left(3^2\right)^x = 3^{2x}
$$

— the same function in different clothes, a costume change you will
use when comparing exponential models.

## Zero and below

What should $2^0$ mean? Do not decree it — descend to it. Each step
down the list divides by 2:

$$
2^3 = 8, \quad 2^2 = 4, \quad 2^1 = 2, \quad 2^0 = 1, \quad
2^{-1} = \tfrac{1}{2}, \quad 2^{-2} = \tfrac{1}{4}
$$

The pattern forces $2^0 = 1$, and keeps going: a negative exponent
means *reciprocal*, never "negative number". So
$2^{-3} = \frac{1}{8}$, a small positive number. This
descend-the-pattern move shows up regularly in [[Number Strings]] —
by the third time you run it, the laws feel inevitable rather than
imposed.

[[Exponent Laws Practice]] mixes numeric and algebraic work, and
[[Rational Exponents]] takes the next step down this same road: what
must $4^{1/2}$ mean?

%%curriculum-start%%
## Curriculum connection

![[B1.3]]

![[B2.4]]
%%curriculum-end%%
