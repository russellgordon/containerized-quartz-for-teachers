---
title: Factors and Intercepts
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Factoring looks like an algebra chore until you notice what it tells you
about the graph. The factored form of a quadratic hands you the
$x$-intercepts directly — no table of values, no guessing — and that is
the connection this whole unit turns on.

## Why factors give you the zeros

A product is zero only when one of its parts is zero. So for

$$y = (x - 3)(x + 5)$$

the graph touches the $x$-axis exactly where $x - 3 = 0$ or $x + 5 = 0$,
which is at $x = 3$ and $x = -5$. Nothing was computed; the factored form
simply says it.

Read that backwards and it is just as useful: a parabola crossing at
$-2$ and $4$ must have factors $(x + 2)$ and $(x - 4)$, so its equation
is $y = a(x+2)(x-4)$ for some $a$ — and one more point pins $a$ down.

| What you are given | What you can read off immediately |
| --- | --- |
| $y = a(x - r)(x - s)$ | Zeros at $r$ and $s$ |
| Zeros at $r$ and $s$ | The factors, up to the value of $a$ |
| $y = a(x - h)^2$ | One zero, at $h$ — the vertex sits on the axis |
| No real factors | The parabola never crosses the $x$-axis |

## The axis of symmetry comes free

A parabola is symmetric, so its axis runs exactly halfway between the
zeros:

$$x = \frac{r + s}{2}$$

For $y = (x-3)(x+5)$ that is $x = \frac{3 + (-5)}{2} = -1$. Substituting
$x = -1$ gives the vertex's $y$-value, and now you have the vertex
without completing the square or memorising $-\frac{b}{2a}$ — though
that formula is the same fact wearing different clothes.

## Sketching from $y = ax^2 + bx + c$

Standard form hides the zeros, so you choose a route. Three work, and
knowing which to reach for is the skill:

1. **Factor it**, when it factors. Zeros, then axis, then vertex. The
   fastest route when it is available.
2. **Complete the square** into vertex form $y = a(x-h)^2 + k$. Always
   works, gives the vertex directly, and the arithmetic is the slowest
   of the three.
3. **Use the formulas**: axis at $x = -\frac{b}{2a}$, then substitute
   for the vertex, and the quadratic formula for the zeros if you need
   them. Always works, and it is the route worth having when the zeros
   are irrational.

Whichever you take, four features finish a sketch: the direction of
opening (the sign of $a$), the $y$-intercept (which is just $c$), the
axis of symmetry, and the vertex — plus the zeros if they exist.

> [!tip] Check with the $y$-intercept
> In standard form, $c$ is the $y$-intercept, immediately. After
> factoring or completing the square, multiply your answer back out
> mentally and check that $c$ survived. It is a five-second test that
> catches most sign errors before they reach the graph.

## When there are no real zeros

If the quadratic does not factor and the quadratic formula gives a
negative under the root, the parabola never meets the $x$-axis. That is
information, not a failure — the discriminant is telling you the graph
sits entirely above or entirely below the axis, and the vertex tells you
which. [[Quadratic Relations]] has the discriminant in full.

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[A3.6]]
%%curriculum-end%%
