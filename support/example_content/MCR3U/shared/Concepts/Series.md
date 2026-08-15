---
title: Series
publish: true
created: __CREATED__
tags:
  - concepts
---
The challenge at the boards was blunt: add every whole number from 1
to 100, no calculator, five minutes. The groups that finished early
all rediscovered the same trick — pair the ends.[^1] A *series* is
what you get when you add the terms of a sequence, and both families
from [[Sequences and Their Rules]] have a shortcut that sidesteps the
adding entirely.

## Adding without adding

Pair 1 with 100, 2 with 99, 3 with 98: fifty pairs, each summing to
101, total $50 \times 101 = 5050$. The pairing works for any
arithmetic series because the gaps are even — first-plus-last equals
second-plus-second-last, all the way in. In general, $n$ terms make
$\frac{n}{2}$ pairs:

$$
S_n = \frac{n(t_1 + t_n)}{2}
\qquad \text{or, expanding } t_n, \qquad
S_n = \frac{n}{2}\left[2a + (n - 1)d\right]
$$

So $3 + 7 + 11 + \cdots$ taken to 40 terms is
$S_{40} = \frac{40}{2}\left[2(3) + 39(4)\right] = 20(162) = 3240$ —
four numbers multiplied, not forty added.

## Multiply, shift, subtract

Geometric series need a different trick, and it is a beautiful one.
Write the sum, multiply the whole line by $r$, and subtract: every
term but two cancels, leaving

$$
S_n = \frac{a\left(r^n - 1\right)}{r - 1}
$$

For $2 + 6 + 18 + \cdots$ to 10 terms:
$S_{10} = \frac{2\left(3^{10} - 1\right)}{3 - 1} = 3^{10} - 1 =
59{,}048$. Reproduce the cancellation yourself once on paper — write
$S$, write $3S$ beneath it, subtract — rather than accepting the
formula on faith; the derivation *is* the understanding, and it is
worth a page in your [[Math Journal]].

Where this earns its living: a savings plan with a regular deposit is
a geometric series in disguise — every deposit grows for a different
length of time, and the total is exactly this sum. That story is told
properly in [[Money Over Time]], and
[[Sequences, Series, and Interest Practice]] runs the full route from
formula to future value.

[^1]: The trick is usually credited to ten-year-old Carl Friedrich
    Gauss, whose teacher assigned the sum to keep the class busy. The
    story has surely been polished by two centuries of retelling —
    but the mathematics is genuine, and rediscovering it at a
    whiteboard needs no permission from history.

%%curriculum-start%%
## Curriculum connection

![[C2.3]]

![[C2.4]]
%%curriculum-end%%
