---
title: Visual Patterns
draft: false
created: __CREATED__
tags:
  - number-talks
---
Three figures of dots go up on the board, every dot joined to every
other by a straight segment. Figure 3 is a triangle: 3 dots, 3
segments. Figure 4 is a square with both diagonals: 4 dots, 6
segments. Figure 5: 5 dots, 10 segments. Two questions, always the
same: how many segments in figure 10? and — the one this course cares
about — how many segments does figure $n$ *gain* when one more dot
walks in?

## How we play

1. Study the figures in silence. See the *structure*, not the total.
2. Predict figure 10 from how you see the pattern growing.
3. Defend your count of the growth by pointing at the picture.

> [!example]- Three ways to see the growth
> - "Watch the newcomer. When a sixth dot arrives, it has to shake
>   hands with each of the 5 already there — 5 new segments, and not
>   one of the old segments changes. So figure 6 has $10 + 5 = 15$."
> - "Count from every dot at once. Each of $n$ dots touches $n - 1$
>   others, giving $n(n-1)$ — but that walks every segment twice,
>   once from each end, so the honest total is
>   $\frac{n(n-1)}{2}$. Figure 10 is $\frac{10 \times 9}{2} = 45$."
> - "It is a choosing problem in disguise. A segment *is* a pair of
>   dots, so the count is $\binom{n}{2}$ — and sure enough
>   $\binom{10}{2} = 45$. The growth numbers 3, 4, 5 are just the
>   number of partners the newcomer finds waiting."

Three groups, three pictures, one formula — and the third defence is
the one that travels. Once a segment is a *pair*, this pattern stops
being about dots and starts counting handshakes at a party, matches
in a round-robin schedule, and the pairs of people in a room who
might share a birthday.

## One variation

I put the first five rows of a triangle of numbers on the board — 1;
1 1; 1 2 1; 1 3 3 1; 1 4 6 4 1 — and ask for row six with no formula
allowed, only the picture. Every entry is the sum of the two above
it, so the row builds itself: 1 5 10 10 5 1. Then the sting: those
are $\binom{5}{0}$ through $\binom{5}{5}$, and the addition rule the
room just used is the statement that choosing 3 from 6 means either
taking the newest item or not. [[Pascal's Triangle]] is where that
gets said carefully, and the pattern-first version is
[[Counting Without Counting]].

> [!tip] The general lives inside the specific
> Nobody counts figure 10 segment by segment. The way you *see*
> figure 5 — every new dot shaking hands with everyone already there
> — is already the formula for figure $n$. Say what you see, and the
> algebra writes itself; [[Combinations]] does the same thing to
> whole families of counting problems, starting from pictures exactly
> like this one.
