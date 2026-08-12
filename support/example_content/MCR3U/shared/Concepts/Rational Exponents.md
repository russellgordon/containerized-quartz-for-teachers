---
title: Rational Exponents
draft: false
created: __CREATED__
tags:
  - concepts
---
The [[True or False]] claim on the board was "$4^{1/2} = 2$", and the
room split. The winning argument used no calculator, only the product
law from [[Exponent Laws]]: whatever $4^{1/2}$ means, the law demands

$$
4^{1/2} \times 4^{1/2} = 4^{1/2 + 1/2} = 4^1 = 4
$$

so $4^{1/2}$ must be the positive number that multiplies by itself to
make 4. It is $\sqrt{4} = 2$ — not by decree, but because nothing
else keeps the laws consistent.

## What a fractional exponent must mean

Run the same argument with three copies and $27^{1/3} \times
27^{1/3} \times 27^{1/3} = 27$, so $27^{1/3} = \sqrt[3]{27} = 3$. In
general, for $x > 0$,[^1]

$$
x^{1/n} = \sqrt[n]{x}
$$

A fractional exponent is a root. The laws did not gain an exception —
they gained territory.

## Reading m over n

A numerator bigger than 1 just adds a power:
$x^{m/n} = \left(\sqrt[n]{x}\right)^m$. Take the root *first* — it
keeps the numbers small enough for mental math:

$$27^{2/3} = \left(\sqrt[3]{27}\right)^2 = 3^2 = 9 \qquad 16^{-3/4} = \frac{1}{\left(\sqrt[4]{16}\right)^3} = \frac{1}{2^3} = \frac{1}{8}$$

The negative sign still means reciprocal, exactly as it did for
integer exponents. And the laws mix freely with variables:
$\left(x^6 y^3\right)^{1/3} = x^2 y$, and
$x^3 \div x^{1/2} = x^{5/2}$.

When a rational exponent stalls you, unpack it in this order —
reciprocal, root, power — and say each step aloud. Writing that
three-word order in your margin is a classic note to your future
forgetful self. [[Exponent Laws Practice]] interleaves integer and
rational exponents so the two never drift into separate skills.

[^1]: Why insist on $x > 0$? On its own, $(-8)^{1/3} = -2$ looks
    harmless — but the laws would let you rewrite $\frac{1}{3}$ as
    $\frac{2}{6}$ and compute
    $\left((-8)^2\right)^{1/6} = 64^{1/6} = 2$. One expression, two
    values, and the one-output guarantee from [[What Is a Function]]
    collapses. Keeping bases positive keeps the whole system honest.

%%curriculum-start%%
## Curriculum connection

![[B1.2]]

![[B1.3]]
%%curriculum-end%%
