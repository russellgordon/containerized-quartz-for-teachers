---
title: Scientific Notation
publish: true
created: __CREATED__
tags:
  - concepts
---
In [[How Big Is a Million]] the class discovered that a million
seconds is about eleven and a half days — and that a billion seconds
is nearly thirty-two *years*. Numbers at that scale stop being
readable as strings of digits. Scientific notation is the fix: write
every number as

$$
a \times 10^{n}, \quad \text{where } 1 \le a < 10
$$

so that the exponent carries the *size* and the front number carries
the *detail*. A year is about $3.15 \times 10^{7}$ seconds; a human
hair is about $8 \times 10^{-5}$ metres across. One glance at the
exponent tells you the scale before you read anything else.[^1]

## The exponent does the sorting

Comparing $4.2 \times 10^{8}$ with $9.6 \times 10^{7}$ takes no
arithmetic: the exponents differ, and $10^{8}$ outranks $10^{7}$, so
the first number is larger even though $9.6$ looks bigger than $4.2$.
Only when exponents tie do the front numbers get a vote. This is the
same ladder of tens from [[Powers and Exponent Rules]] — each step of
the exponent is a factor of ten, and negative exponents walk the
ladder down below one, into the world of the very small.

Moving the decimal point is *not* the idea — it is a side effect. What
you are really doing is trading factors of ten between the two parts:
$42\,000 = 4.2 \times 10^{4}$ because $42\,000$ *is* $4.2$ scaled up
by four factors of ten. Keep that trade in mind and you will never
wonder which direction the exponent should go.

Estimates at [[Fermi Festival]] practically demand this notation —
once your answer is "about $10^{5}$ pieces of popcorn", you have said
the most important thing about it. [[Exponent Practice]] includes a
section on converting and comparing.

[^1]: Your calculator writes $3.15 \times 10^{7}$ as `3.15E7`. The
    `E` is calculator shorthand for "times ten to the" — it is not a
    variable, and writing `E7` in your own work is not scientific
    notation.

%%curriculum-start%%
## Curriculum connection

![[B2.1]]
%%curriculum-end%%
