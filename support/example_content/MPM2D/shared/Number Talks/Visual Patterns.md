---
title: Visual Patterns
publish: true
created: __CREATED__
tags:
  - number-talks
---
Three figures made of tiles go up on the board: figure 1 has 3, figure
2 has 8, figure 3 has 15 — each an $n$-by-$n$ square with an arm of
$n$ tiles on two sides. Two questions, always the same: how many tiles
in figure 10? and how many in figure $n$? Last year's patterns grew by
a constant amount each step. These do not — and that is the point.

## How we play

1. Study the figures in silence. See the *structure*, not the total.
2. Predict figure 10 from how you see the pattern growing.
3. Defend your count of figure $n$ by pointing at the picture.

> [!example]- Three ways to see figure 10 (click to expand)
> - "A square and two arms: $10^2 + 2 \times 10 = 120$."
> - "Slide one arm under the square — it becomes a 10-by-12
>   rectangle: $10 \times 12 = 120$."
> - "Finish the big square and cut the corner: $11^2 - 1 = 120$."
>
> Three expressions — $n^2 + 2n$, $n(n+2)$, $(n+1)^2 - 1$ — one
> pattern. Expanding shows they were always the same count.

## One variation

Table the totals — 3, 8, 15, 24 — and difference them. The first
differences climb (5, 7, 9); the *second* hold steady at 2. A constant
second difference is the quadratic's fingerprint — the same one
[[The Handshake Problem]] leaves, and [[Quadratic Relations]] names.

> [!tip] The general lives inside the specific
> Nobody counts figure 10 tile by tile. The way you *see* figure 3 —
> square plus arms, rectangle, almost-square — is already the formula
> for figure $n$. Say what you see, and the algebra writes itself.

%%curriculum-start%%
## Curriculum connection

![[A1.2]]
%%curriculum-end%%
