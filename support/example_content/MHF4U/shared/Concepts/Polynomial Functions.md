---
title: Polynomial Functions
draft: false
created: __CREATED__
tags:
  - concepts
---
During [[The Polynomial Sort]], your group split twelve graphs into
piles and had to defend the piles out loud. The rule you invented —
"count the wiggles, watch the ends" — is this whole topic wearing
informal clothes. This page gives your rule its official vocabulary.

A **polynomial** is a sum of terms, each one a constant times a power
of $x$ with a whole-number exponent: $x^3 - 5x^2 + 2x - 1$ qualifies;
$\sqrt{x}$, $\frac{1}{x}$, and $2^x$ do not. You have known polynomials
for years without the name — every line and every parabola is one. The
**degree** is the highest power, and it is the single most informative
number on the page.

## What the degree controls

Far from the origin the leading term drowns out everything else, so
the degree and the sign of the leading coefficient $a_n$ decide the
**end behaviour** between them:

| Degree | $a_n > 0$              | $a_n < 0$              |
| ------ | ---------------------- | ---------------------- |
| Even   | up on both ends        | down on both ends      |
| Odd    | down-left, up-right    | up-left, down-right    |

Closer in, the degree sets budgets rather than certainties: a degree
$n$ polynomial has *at most* $n$ x-intercepts and *at most* $n - 1$
turning points. A quartic may use its whole budget or almost none of
it — $x^4$ has one intercept and one turning point — but it can never
overspend. When you sketch, the ends are guaranteed; the middle is
where the choices live.

## What a polynomial cannot do

Half of recognising a polynomial graph is knowing what to rule out.
A polynomial never repeats itself the way a sinusoid does, and it
never levels off toward an asymptote the way an exponential does — it
always, eventually, commits to leaving. Domain is all real numbers,
no exceptions, no gaps. If a graph in [[Graph Talks]] flattens toward
a horizontal line or cycles forever, you can say "not a polynomial"
before you say anything else, and that is a real answer.

[[Polynomial Graphing Practice]] turns end behaviour and budget
arguments into a reflex; [[Zeros and Multiplicity]] takes over where
the graph meets the x-axis.

%%curriculum-start%%
## Curriculum connection

![[C1.1]]

![[C1.2]]

![[C1.3]]

![[C1.4]]
%%curriculum-end%%
