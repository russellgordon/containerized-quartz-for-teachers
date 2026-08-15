---
title: Visual Patterns
publish: true
created: __CREATED__
tags:
  - number-talks
---
Three figures made of blocks go up on the board: figure 1 is a
single block, figure 2 is a $2 \times 2$ square, figure 3 a
$3 \times 3$ square — each figure grown from the last by wrapping an
L-shaped border down one side and along the bottom. The totals run
1, 4, 9. Two questions, always the same: how many blocks in figure
10? and — the one this course cares about — how many blocks does
figure $n$ *gain* when it becomes figure $n+1$? The totals are old
news; the *growth* is the new mathematics.

## How we play

1. Study the figures in silence. See the *structure*, not the total.
2. Predict figure 10 from how you see the pattern growing.
3. Defend your count of the growth by pointing at the picture.

> [!example]- Three ways to see the growth
> - "Count the L: to grow figure 3 into figure 4, wrap a border of
>   $3 + 3 + 1 = 7$ blocks. In general the L holds $2n + 1$ blocks —
>   two sides of length $n$ plus the corner."
> - "Difference the totals: 1, 4, 9, 16 grows by 3, 5, 7 — the odd
>   numbers. Figure 10 is 100, and it took a 19-block L to get there
>   from 81."
> - "Compare to the slopes: the derivative of $x^2$ is $2x$, and the
>   L holds $2n + 1$. The pattern's growth is almost exactly *twice
>   the side* — off by the one corner block, and that lone block
>   matters less and less as the figures grow. A staircase's growth
>   and a curve's slope are cousins, and the family resemblance
>   sharpens as the steps shrink."

## One variation

I hand you only the *growth* numbers of a mystery pattern — say each
figure gains 5, then 9, then 13, then 17 blocks — and your group must
rebuild the totals and name the degree of the formula behind them.
Growth that climbs steadily means totals that climb like a square;
constant growth means totals on a line. Recovering the function from
its rate of change is the reverse gear this course spends a semester
installing — [[The Slope Detective]] hands your group a full case of
it, with graphs instead of blocks.

> [!tip] The general lives inside the specific
> Nobody counts figure 10 block by block. The way you *see* figure 3
> — a square that grows by wrapping an L — is already the formula
> for the growth of figure $n$. Say what you see, and the algebra
> writes itself; [[Derivative Rules]] does the same thing to whole
> families of functions, starting from patterns exactly like this
> one.
