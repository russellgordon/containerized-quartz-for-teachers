---
title: Sequences as Functions
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
A sequence is a function whose domain is the natural numbers. That
sentence sounds like a technicality and is actually the whole idea:
everything you know about functions applies, and the only difference is
that you can no longer feed it 2.5.

## Two ways to say the same rule

$$t_n = 3n + 1 \qquad\text{against}\qquad t_1 = 4,\; t_n = t_{n-1} + 3$$

The first is **explicit**: hand it $n$ and it hands back the term. The
second is **recursive**: it tells you how to get the next term from the
one before, and nothing at all about term 100 without walking there.

In function notation the explicit form is simply $f(n) = 3n + 1$, with
$n \in \mathbb{N}$. The graph is not a line — it is the points of a
line, at $n = 1, 2, 3, \dots$, with gaps between. That picture is worth
drawing once, because it is exactly what "discrete" means.

| | Explicit | Recursive |
| --- | --- | --- |
| Term 100 | Immediate | 99 steps away |
| Pattern of growth | Visible in the formula | Visible in the step |
| Some sequences | Impossible to write | Still easy |

That last row is why both survive. Some sequences have no explicit
formula anybody would want to use — and the most famous of them is next.

## Fibonacci: a rule that only looks backwards

$$t_1 = 1,\quad t_2 = 1,\quad t_n = t_{n-1} + t_{n-2}$$

$$1,\; 1,\; 2,\; 3,\; 5,\; 8,\; 13,\; 21,\; 34,\; 55,\; \dots$$

Two seeds instead of one, and each term needs the two before it. Ratios
of consecutive terms — $\tfrac{2}{1}, \tfrac{3}{2}, \tfrac{5}{3},
\tfrac{8}{5}, \dots$ — settle towards about 1.618, which is worth
computing yourself rather than being told. Related sequences behave the
same way: start with 2 and 1 instead, keep the rule, and the ratios
converge to the same number.

## Pascal's triangle, and where it hides

Each entry is the sum of the two above it — recursion again, in two
dimensions:

```
                1
              1   1
            1   2   1
          1   3   3   1
        1   4   6   4   1
      1   5  10  10   5   1
```

The rows are the coefficients of $(a+b)^n$:

$$(a+b)^3 = 1a^3 + 3a^2b + 3ab^2 + 1b^3$$

Expand $(a+b)^4$ by hand once, slowly, and then compare with row 4 —
$1, 4, 6, 4, 1$. The triangle is doing the bookkeeping of how many ways
each term can be assembled, which is why it also answers counting
questions. The diagonals hold the counting numbers and the triangular
numbers; the shallow diagonals sum to Fibonacci, which is the kind of
fact that is either a coincidence or a reason to look harder. It is the
second one.

> [!question]- Why bother with recursion when explicit is faster?
> Because most real processes are recursive. A bank balance depends on
> last month's balance; a population depends on last year's; a
> spreadsheet cell refers to the cell above it. The explicit formula,
> where one exists, is a shortcut discovered afterwards —
> [[Sequences and Their Rules]] shows how to find it for arithmetic and
> geometric sequences, and those are the two cases where the shortcut is
> easy.

%%curriculum-start%%
## Curriculum connection

![[C1.3]]

![[C1.5]]

![[C1.6]]
%%curriculum-end%%
