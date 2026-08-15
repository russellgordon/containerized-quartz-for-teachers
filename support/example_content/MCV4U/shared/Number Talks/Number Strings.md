---
title: Number Strings
publish: true
created: __CREATED__
tags:
  - number-talks
---
A string is a chain of related problems, served one at a time: the
value of $\frac{x^2 - 9}{x - 3}$ at $x = 4$, then at $x = 3.1$, then
at $x = 3.01$, then at $x = 3$. Each answer is a stepping stone to
the next — and in this course, the strings are quietly rebuilding
calculus from scratch.

## How we play

1. One problem at a time. Solve it in your head; thumb when ready.
2. A few people defend their methods; each goes on the board.
3. Before computing the next from scratch, ask: what can I reuse?

> [!example]- The string, walked
> - "At $x = 4$: top is 7, bottom is 1. Seven."
> - "At $x = 3.1$: I noticed the top factors — it is
>   $(x - 3)(x + 3)$, so away from 3 the whole thing is just
>   $x + 3$. That makes this one $6.1$, no long division required."
> - "At $x = 3.01$: $6.01$. I can feel where this string is going."
> - "At $x = 3$: nothing. Zero over zero — the one input the
>   shortcut is not allowed to touch, because the cancelled factor
>   is zero exactly there. The function has no value at 3. But the
>   string just showed its *destination*: 6.1, 6.01, 6.001 — the
>   outputs are converging on 6 from an input we can never use."
>
> Nobody was taught a definition that day. The string cornered it,
> and [[The Limit]] just wrote down what the room had proven: a
> function can have an unmistakable destination at a point where it
> has no value.

## One variation

Run a string on slopes instead: the derivative of $x^2$ is $2x$ — of
$x^3$ is $3x^2$ — of $x^5$ is $5x^4$ — so what is the derivative of
$x^{100}$? Every thumb in the room goes up. Then the sting in the
tail: what about $\sqrt{x}$, which is $x^{1/2}$? If the pattern
holds, the exponent drops out front and steps down by one:
$\frac{1}{2}x^{-1/2}$ — a root became a half, and the conjecture
just claimed territory nobody tested it on. Whether it is *entitled*
to that territory is the question [[Derivative Rules]] settles.

> [!tip] Lazy, in the best way
> Mathematicians refuse to compute what they can deduce. If a problem
> feels brand new, look back along the string — it rarely is.
