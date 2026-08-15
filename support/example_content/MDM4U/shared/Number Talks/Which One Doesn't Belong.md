---
title: Which One Doesn't Belong
publish: true
created: __CREATED__
tags:
  - number-talks
---
Four things, four corners, and one question: which one doesn't
belong? The trick is that there is no trick — every corner can be
defended, so the game is never about *the* answer. It is about
naming, precisely, the property your corner alone possesses. In this
course the corners are usually summaries of data, and the sharpest
properties are about what each summary *notices* and what it quietly
throws away.

|  |  |
| --- | --- |
| **A** — the mean | **B** — the median |
| **C** — the mode | **D** — the range |

> [!example]- A defence for every corner
> - **A** — the only one that moves when *any* single value moves.
>   Change one number by a dollar and the mean shifts; the other
>   three may not blink. That sensitivity is its gift and its
>   weakness: it is also the only one an outlier can drag across the
>   room.
> - **B** — the only one defined by *position* rather than value. It
>   asks who is standing in the middle of the line, not what they are
>   holding, which is exactly why a billionaire joining the queue
>   barely disturbs it.
> - **C** — the only one that works on data that are not numbers at
>   all. There is no mean favourite colour. It is also the only one
>   that can refuse to be unique, or fail to exist.
> - **D** — the only one that is not a measure of centre at all. It
>   answers a different question — how spread out? — using exactly
>   two values and ignoring everyone in between, which is why
>   [[One-Variable Statistics]] replaces it with standard deviation
>   the moment the stakes rise.

## One variation

Four counts, four corners: $\binom{10}{3}$ · $\binom{10}{7}$ ·
$_{10}P_{3}$ · $\binom{10}{2}$. Two of them are the same number
wearing different clothes — choosing 3 to take is choosing 7 to
leave, so both come to 120. The permutation is the odd one for the
reason this unit turns on: it counts the same selections but insists
on their orders, so it lands on $120 \times 3! = 720$. And
$\binom{10}{2} = 45$ belongs to the pairs family that makes
[[The Birthday Problem]] work. Sorting the four without a calculator
is [[Permutations]] and [[Combinations]] earning their keep.

> [!tip] "It looks different" scores nothing
> Precision is the whole game. Not "the mean is affected by outliers"
> but "the mean is the only one of the four that changes when a
> single value changes, which is why a skewed distribution should be
> reported with its median beside it." A property you can state
> exactly is a property you can use — and stating one exactly is the
> same skill [[Writing About Data]] asks for in full sentences.
