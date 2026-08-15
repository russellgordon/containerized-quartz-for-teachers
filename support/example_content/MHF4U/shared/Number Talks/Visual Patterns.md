---
title: Visual Patterns
publish: true
created: __CREATED__
tags:
  - number-talks
---
Three figures made of blocks go up on the board: figure 1 is a
single block, figure 2 stacks a $2 \times 2$ square under it, figure
3 slides a $3 \times 3$ square under that — a square pyramid growing
one storey per figure. The totals run 1, 5, 14. Two questions,
always the same: how many blocks in figure 10? and how many in
figure $n$? Last year's patterns grew by doubling; these grow like a
*polynomial* — and proving which polynomial is the point.

## How we play

1. Study the figures in silence. See the *structure*, not the total.
2. Predict figure 10 from how you see the pattern growing.
3. Defend your count of figure $n$ by pointing at the picture.

> [!example]- Three ways to see figure 10
> - "Layer by layer: the storeys of figure 10 are the squares
>   $1, 4, 9, \ldots, 100$, so add the first ten squares — 385."
> - "Difference the totals: 1, 5, 14, 30 grows by 4, 9, 16 — the
>   pattern's growth is the squares themselves, one storey at a
>   time. Ride the differences up to figure 10."
> - "Difference *again*: second differences 5, 7, 9; third
>   differences constant. Constant third differences is the
>   fingerprint of a cubic — so fit one. It comes out to
>   $\frac{n(n+1)(2n+1)}{6}$, and $\frac{10 \cdot 11 \cdot 21}{6} = 385$."

## One variation

Run the fingerprint argument in reverse: I hand you only the totals
of a mystery figure pattern, and your group must name the *degree*
of the polynomial behind it before anyone builds a formula. Constant
first differences means linear; constant second, quadratic; constant
third, cubic — the same dusting-for-degree your group does with
graphs in [[The Polynomial Sort]], done here with a table.

> [!tip] The general lives inside the specific
> Nobody counts figure 10 block by block. The way you *see* figure 3
> — storeys of squares, growth that is itself a pattern — is already
> the formula for figure $n$. Say what you see, and the algebra
> writes itself; [[Polynomial Functions]] just gives the result its
> family name.
