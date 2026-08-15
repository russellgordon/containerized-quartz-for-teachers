---
title: Quadratic Functions Revisited
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
You built parabolas all through Grade 10; today at the boards they
came back wearing [[Function Notation|function notation]] and
answering harder questions. The parabola itself has not changed. What
changes this year is fluency: choosing the *form* of a quadratic to
match the question being asked.

## Three forms, three superpowers

| Form | Looks like | Reveals instantly |
| --- | --- | --- |
| Standard | $f(x) = ax^2 + bx + c$ | the $y$-intercept, $c$ |
| Vertex | $f(x) = a(x - h)^2 + k$ | the max or min, at $(h, k)$ |
| Factored | $f(x) = a(x - r)(x - s)$ | the zeros, $r$ and $s$ |

Factored form also explains *families*: every quadratic with zeros
$-1$ and $3$ is $f(x) = a(x + 1)(x - 3)$ for some $a$ — same
anchors, different stretch. One extra point pins down the member.
Through $(1, 8)$: substituting gives $a(2)(-2) = 8$, so $a = -2$ and
$f(x) = -2(x + 1)(x - 3)$.

## Max and min without a graph

Completing the square converts standard form to vertex form even when
$a \ne 1$ — factor $a$ out of the $x$-terms first:

$$\begin{aligned} f(x) &= 2x^2 - 12x + 7 = 2(x^2 - 6x) + 7 = 2(x - 3)^2 - 18 + 7 \\ &= 2(x - 3)^2 - 11 \end{aligned}$$

Minimum value $-11$, at $x = 3$. A slicker route when it applies:
*partial factoring*. Write $f(x) = 3x^2 - 6x + 5$ as
$3x(x - 2) + 5$; the function takes the value 5 at both $x = 0$ and
$x = 2$, symmetry puts the vertex halfway between at $x = 1$, and
$f(1) = 2$. In an application, this vertex *is* the answer — the
maximum profit, the peak height — so translate back into a sentence
when you get there.

## Counting zeros before finding them

The discriminant $b^2 - 4ac$ announces how many $x$-intercepts a
quadratic has before you hunt for them: positive means two, zero
means exactly one, negative means none. Vertex form tells the same
story geometrically — a vertex below the axis on a parabola opening
up must cross twice. Predicting the count *first*, then verifying, is
a favourite move in [[Graph Talks]], and it is
[[Checking Your Own Work]] built into the solving itself: if you
predicted two zeros and found one, something is asking to be
re-examined.

These moves get exercised whenever quadratics appear this semester —
[[Function Notation Practice]] and [[Transformations Practice]] both
lean on them.

%%curriculum-start%%
## Curriculum connection

![[A2.1]]

![[A2.2]]

![[A2.3]]

![[A2.4]]
%%curriculum-end%%
