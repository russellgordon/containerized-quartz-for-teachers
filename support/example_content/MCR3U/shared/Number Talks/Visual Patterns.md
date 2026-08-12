---
title: Visual Patterns
draft: false
created: __CREATED__
tags:
  - number-talks
---
Three figures made of tiles go up on the board: figure 1 has 3,
figure 2 has 6, figure 3 has 12 — each figure holding two complete
copies of the one before it. Two questions, always the same: how many
tiles in figure 10? and how many in figure $n$? Last year's patterns
grew by adding; these grow by *multiplying* — and that is the point.

## How we play

1. Study the figures in silence. See the *structure*, not the total.
2. Predict figure 10 from how you see the pattern growing.
3. Defend your count of figure $n$ by pointing at the picture.

> [!example]- Three ways to see figure 10
> - "Every figure is two of the one before, so figure 10 is the seed
>   of 3 doubled nine times: $3 \times 2^9 = 1536$."
> - "Ten doublings of 3 is 3072, but that overshoots by one doubling
>   — the seed itself uses no doubling: $\frac{3 \times 2^{10}}{2} = 1536$."
> - "Each figure is 3 clusters, and the clusters double: figure 10 is
>   3 clusters of $2^9$ tiles each."
>
> Three expressions — $3 \times 2^{n-1}$, $\frac{3 \times 2^n}{2}$,
> $3 \cdot 2^{n-1}$ counted by clusters — one pattern. The
> [[Exponent Laws]] show they were always the same count.

## One variation

Table the totals — 3, 6, 12, 24 — and difference them. The
differences are 3, 6, 12: the pattern's growth *is the pattern
itself*, one step behind. A constant ratio is the geometric
sequence's fingerprint — the same one [[Patterns That Count]] dusts
for, and [[Sequences and Their Rules]] names.

> [!tip] The general lives inside the specific
> Nobody counts figure 10 tile by tile. The way you *see* figure 3 —
> two of yesterday, three doubling clusters — is already the formula
> for figure $n$. Say what you see, and the algebra writes itself.
