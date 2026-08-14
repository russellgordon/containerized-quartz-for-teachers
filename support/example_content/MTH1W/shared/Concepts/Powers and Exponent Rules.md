---
title: Powers and Exponent Rules
publish: true
created: __CREATED__
tags:
  - concepts
---
A power is repeated multiplication with the bookkeeping done for you:
$2^5$ means five factors of $2$. Counting the small cubes in
[[The Painted Cube]] gave you $n^3$ for exactly this reason — length,
width, and height each contribute one factor of $n$. Everything else
on this page follows from patterns you can extend yourself; none of it
needs to be decreed.

## Pattern your way down the ladder

| Power | Value | Each step down… |
| --- | --- | --- |
| $2^4$ | $16$ | |
| $2^3$ | $8$ | …divides by $2$ |
| $2^2$ | $4$ | …divides by $2$ |
| $2^1$ | $2$ | …divides by $2$ |
| $2^0$ | $1$ | the pattern insists |
| $2^{-1}$ | $\frac{1}{2}$ | keep going |
| $2^{-2}$ | $\frac{1}{4}$ | and going |

Nobody has to *declare* that $2^0 = 1$ or that a negative exponent
means a reciprocal — the pattern leaves no other choice. Run the same
ladder with base $10$ or base $\frac{1}{2}$ on a whiteboard and watch
the same structure appear. That is the honest reason behind
[[B2.1|the relationship between an exponent and a power's value]].

## The rules are just counting factors

Write out $2^3 \times 2^4$ in full: three factors of $2$, then four
more. Seven factors total, so $2^3 \times 2^4 = 2^{3+4} = 2^7$.
Division cancels matching factors, so exponents subtract:
$\frac{2^7}{2^3} = 2^{7-3}$. A power of a power stacks copies, so
exponents multiply: $(2^3)^4 = 2^{12}$. If you ever blank on a rule,
do not reach for memory — write out five seconds of factors and count.
The rule will reassemble itself in front of you, and the same counting
works when the base is a variable, which is how these rules
[[B2.2|simplify numeric and algebraic expressions]] alike.

Growing patterns in [[Visual Patterns]] that double are your first
sighting of powers in the wild, and powers of $10$ are the engine of
[[Scientific Notation]]. [[Exponent Practice]] builds the fluency.

%%curriculum-start%%
## Curriculum connection

![[B2.1]]

![[B2.2]]
%%curriculum-end%%
