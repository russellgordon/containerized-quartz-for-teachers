---
title: Number Strings
publish: true
created: __CREATED__
tags:
  - number-talks
---
A string is a chain of related problems, served one at a time:
$\log_2 8$, then $\log_2 32$, then $\log_2 256$, then
$\log_2 \sqrt{32}$. Each answer is a stepping stone to the next —
and in Grade 12, the strings are quietly rebuilding the laws of
logarithms from scratch.

## How we play

1. One problem at a time. Solve it in your head; thumb when ready.
2. A few people defend their methods; each goes on the board.
3. Before computing the next from scratch, ask: what can I reuse?

> [!example]- The string, walked
> - "$\log_2 8$: 2 to what power makes 8? Three."
> - "$\log_2 32 = 5$. Same question, two doublings later."
> - "$\log_2 256$: I doubled my way up and got 8 — which is
>   $3 + 5$. And 256 is $8 \times 32$. Multiplying the inputs
>   *added* the answers."
> - "$\log_2 \sqrt{32}$: whatever this is, doubling it has to give
>   back 5, because $\sqrt{32} \times \sqrt{32} = 32$. So it is
>   $\frac{5}{2}$ — a root became a half."
>
> Nobody was taught a law that day. The string cornered each one,
> and [[Laws of Logarithms]] just wrote down what the room had
> proven.

## One variation

Run a string on the circle: $\sin\frac{\pi}{6}$, then
$\sin\frac{\pi}{3}$, then $\sin\left(\frac{\pi}{6} + \frac{\pi}{3}\right)$.
The last one is $\sin\frac{\pi}{2} = 1$ — but the first two answers
add to about $1.37$. Whatever the sine of a sum is, it is *not* the
sum of the sines, and the room has just knocked on the front door of
[[Compound Angles]].

> [!tip] Lazy, in the best way
> Mathematicians refuse to compute what they can deduce. If a problem
> feels brand new, look back along the string — it rarely is.
