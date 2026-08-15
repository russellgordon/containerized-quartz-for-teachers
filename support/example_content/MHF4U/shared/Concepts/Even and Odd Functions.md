---
title: Even and Odd Functions
publish: true
created: __CREATED__
tags:
  - concepts
---
In [[Which One Doesn't Belong]], one graph kept getting picked for a
reason nobody could quite name: fold it along the y-axis and the two
halves match. Another matched itself only after a half-turn about the
origin. Those two symmetries are common enough, and useful enough,
that they get names — and an algebraic test that needs no graph at
all.

## The two symmetries

A function is **even** when $f(-x) = f(x)$ for every $x$ — inputs $x$
and $-x$ always agree, so the graph mirrors across the y-axis. It is
**odd** when $f(-x) = -f(x)$ — opposite inputs give opposite outputs,
so the graph maps onto itself under a $180°$ rotation about the
origin.

The names come from the powers of $x$.[^names] A polynomial whose
terms all have even exponents is even; all odd exponents, odd. Mix
the parities and the symmetry breaks: $x^3 + x^2$ is neither, and
*neither* is the most common answer in the wild — these symmetries
are the exception, which is exactly what makes them worth reporting
when you find them.

## Testing without a graph

Substitute $-x$, simplify, and compare against the original — commit
to the algebra before you peek at a graph:

- $f(x) = x^4 - 3x^2$: $f(-x) = x^4 - 3x^2 = f(x)$. Even.
- $g(x) = x^3 - 4x$: $g(-x) = -x^3 + 4x = -g(x)$. Odd.
- $h(x) = x^3 + x^2$: $h(-x) = -x^3 + x^2$ — neither $h(x)$ nor
  $-h(x)$. Neither.

Symmetry is also information about intercepts: an odd polynomial must
pass through the origin, since $f(-0) = -f(0)$ forces $f(0) = 0$. And
the symmetries survive multiplication in a pattern worth conjecturing
at the boards before you read it anywhere: odd times odd is even,
just like the integers they are named for. That thread picks up again
in [[Combining Functions]].

A few questions in [[Polynomial Graphing Practice]] put the algebraic
test to work.

[^names]: Even before the general definition existed, mathematicians
    noticed that $x^2, x^4, x^6, \ldots$ share the mirror symmetry
    and $x, x^3, x^5, \ldots$ share the rotational one. The parity of
    the exponent became the name of the symmetry.

%%curriculum-start%%
## Curriculum connection

![[C1.9]]

![[D2.3]]
%%curriculum-end%%
