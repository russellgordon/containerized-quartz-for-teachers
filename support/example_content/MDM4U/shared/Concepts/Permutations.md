---
title: Permutations
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The prompt at the boards looked harmless: *how many ways can eight
books be arranged on a shelf?* Your group started multiplying — eight
choices for the first slot, seven for the second, six for the third —
and then somebody asked whether swapping the two Atwoods counted as a
different arrangement. It does. That question is the whole idea of
this page: a permutation is an arrangement in which **order carries
meaning**.

## Arranging everything

Line up $n$ distinct objects and the counting principle does the rest:
$n$ choices, then $n-1$, then $n-2$, all the way down to one.

$$n! = n \times (n-1) \times (n-2) \times \cdots \times 2 \times 1$$

So eight books arrange $8! = 40\,320$ ways. Factorials climb
alarmingly fast, which is worth feeling rather than just knowing: ten
books would be $3\,628\,800$, and if you arranged one per second you
would need six weeks without sleeping.

By convention $0! = 1$. That is not a mystical claim — it is the value
that keeps every formula below honest, because there is exactly one
way to arrange nothing.

## Arranging some of them

Choose and arrange $r$ objects from $n$ distinct ones and the product
simply stops early:

$$P(n, r) = \frac{n!}{(n-r)!} = n \times (n-1) \times \cdots \times (n - r + 1)$$

Nine sprinters, three medals: $P(9,3) = 9 \times 8 \times 7 = 504$
podiums. Read the formula as a cancellation, not a mystery — the
$(n-r)!$ in the denominator deletes the tail of the product you never
started.

| Situation | Count | Why |
| --- | --- | --- |
| All $n$ arranged | $n!$ | Every slot filled, order matters |
| $r$ of $n$ arranged | $P(n,r) = \frac{n!}{(n-r)!}$ | Product stops after $r$ factors |
| $r$ of $n$ chosen only | $\binom{n}{r}$ | Order divided out — see [[Combinations]] |

## When some objects repeat

Arrange the letters of STATISTICS and $10!$ overcounts badly, because
the three S's are interchangeable, and so are the three T's, and so
are the two I's. Divide out each group's internal arrangements:

$$\frac{10!}{3!\,3!\,2!} = \frac{3\,628\,800}{72} = 50\,400$$

That division is the same manoeuvre [[Combinations]] runs, one page
from now. It is worth naming the habit: **count as though everything
were distinct, then divide by the arrangements you cannot tell
apart.**

> [!question]- Self-check: how many ways can 4 of 7 club members be
> seated in 4 labelled chairs? (click to expand)
> The chairs are labelled, so order matters — this is a permutation.
> $P(7,4) = 7 \times 6 \times 5 \times 4 = 840$. If instead the four
> were simply going on a trip together with no roles attached, the
> answer would be $\binom{7}{4} = 35$, smaller by a factor of
> $4! = 24$.

Every permutation question is a counting-principle question wearing a
formula. When you are unsure, go back to
[[The Fundamental Counting Principle]] and multiply slot by slot — it
always works, it is just slower. Drill both routes in
[[Permutations and Combinations Practice]].

%%curriculum-start%%
## Curriculum connection

![[A2.1]]

![[A2.2]]

![[A2.3]]
%%curriculum-end%%
