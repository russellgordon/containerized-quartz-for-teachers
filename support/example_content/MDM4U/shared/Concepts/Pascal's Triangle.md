---
title: Pascal's Triangle
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
You have built this triangle before, in Grade 9 or wherever patterns
were first fun, and it was a curiosity. It came back at the boards for
a reason. One group was computing $\binom{6}{2}$, another was adding
two numbers from the row above, and the numbers on the two boards were
the same. Not similar — the same. Pascal's triangle is not a party
trick that happens to resemble combinations. It **is** the
combinations, laid out so the pattern shows.

## The rule that builds it

Start with a $1$. Every entry after that is the sum of the two entries
above it, with $1$s down both edges.

| Row $n$ | Entries | Sum |
| --- | --- | --- |
| 0 | 1 | 1 |
| 1 | 1  1 | 2 |
| 2 | 1  2  1 | 4 |
| 3 | 1  3  3  1 | 8 |
| 4 | 1  4  6  4  1 | 16 |
| 5 | 1  5  10  10  5  1 | 32 |
| 6 | 1  6  15  20  15  6  1 | 64 |

Row $n$ sums to $2^n$, which is not a coincidence either: row $n$
counts every possible subset of $n$ objects, sorted by size, and there
are $2^n$ subsets in total.[^rows]

## Every entry is a combination

The entry in row $n$, position $r$ (both counted from zero) is exactly
$\binom{n}{r}$. Row 6 reads
$\binom{6}{0}, \binom{6}{1}, \ldots, \binom{6}{6}$, which is
$1, 6, 15, 20, 15, 6, 1$ — and its symmetry is the symmetry you
already proved in [[Combinations]], that choosing what you take is the
same act as choosing what you leave.

The addition rule becomes a statement about choosing:

$$\binom{n}{r} = \binom{n-1}{r-1} + \binom{n-1}{r}$$

Read it with a person in mind. Pick any one member of the group, say
Dev. Every committee either contains Dev — then the rest is
$\binom{n-1}{r-1}$ — or it does not, and the whole committee comes
from the other $n-1$ people. Two cases, no overlap, so add them. Check
it: $\binom{10}{3} = 120$ and $\binom{9}{2} + \binom{9}{3} = 36 + 84 =
120$.

## The diagonals, and the grid walk

The third diagonal — $1, 3, 6, 10, 15, \ldots$ — is the triangular
numbers, and it is also $\binom{n}{2}$: the number of handshakes among
$n$ people. Two very different stories, one sequence, because both are
counting pairs.

The triangle's best-known application is a walk on a grid. Your school
is 5 blocks west and 3 blocks south of home, and at every corner you
go west or south. Each route is a sequence of 8 moves in which 3 are
south, so the count is $\binom{8}{3} = 56$ — and if you write the
number of routes to each corner on a map, you are writing Pascal's
triangle onto the streets. That is worth doing once by hand; the map
explains the formula better than the formula explains the map.

This triangle returns in Unit 2, wearing a different hat. The row-$n$
entries are precisely the coefficients that make
[[The Binomial Distribution]] work, which is why the two topics feel
like the same idea twice. Build the triangle and use it in
[[Counting Practice]], then extend it in
[[Permutations and Combinations Practice]].

[^rows]: The Ministry's expectation numbers the apex as **row 1** and
    the outer diagonal of $1$s as **diagonal 1**, so what this page
    calls row 2 the curriculum calls row 3. Both conventions are in
    common use. This page counts from zero because that is what makes
    "row $n$, position $r$ is $\binom{n}{r}$" true without corrections.

%%curriculum-start%%
## Curriculum connection

![[A2.2]]

![[A2.4]]
%%curriculum-end%%
