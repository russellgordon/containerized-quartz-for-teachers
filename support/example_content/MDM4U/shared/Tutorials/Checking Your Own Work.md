---
title: Checking Your Own Work
publish: true
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Nobody marks your checker but you. Every statistician you will ever
meet runs one — a quiet second pass that catches errors before they
matter — and the earlier you build yours, the sooner tests stop being
scary. Five habits make up the whole machine, and this course hands
you unusually good ones, because almost every quantity here is
fenced in by something.

## Ask whether the answer is even legal

Most wrong answers in this course announce themselves. A probability
must sit between 0 and 1 — if yours came out 1.4, you almost
certainly added overlapping outcomes. A correlation coefficient must
lie between $-1$ and $1$. A standard deviation is never negative. A
mean must land between the smallest and largest value in the data.
And $P(A \cap B)$ can never exceed either $P(A)$ or $P(B)$, because
"both happened" is a narrower event than either one alone. Run the
answer past its own fence before you run it past anyone else.

## Estimate first, compare after

Before computing, write down a rough expected size — the reflex
[[Estimation Duels]] trains. A combination count must come out
*smaller* than the matching permutation count, because
$\binom{n}{r}$ is $P(n,r)$ with the $r!$ orderings divided out; if
your combination is larger, you have the two backwards. A
conditional probability computed from a two-way table must match the
row you can see with your eyes. This check only works if the estimate
came *before* the answer did.

## Check the species, not just the size

Answers here have a *kind* as well as a number, and saying the kind
out loud is the cheapest check in the course. Is this a count, a
probability, a percentage, a rate, or a $z$-score? A count that came
out fractional is broken. A "probability" of 1.4 was never a
probability. A percentage with no stated denominator is not yet an
answer — 23% of *what*, counted among *whom*? Naming the species
usually finds the error faster than rereading the algebra, and it is
the same discipline [[Showing Your Thinking]] insists on in writing.

## Let a simulation referee it

This is the check this course has that the others did not. If you
computed a probability and are unsure, *do the experiment* — a
hundred thousand times, in about six lines, as
[[Simulating with Python]] shows. If your formula says 0.09 and the
simulation says 0.63, one of you has modelled the wrong situation,
and finding out which is a far better use of ten minutes than staring
at the formula. Agreement is not proof, but disagreement is
absolutely a bug.

## Ask who is missing before you believe the conclusion

The last check is not about arithmetic at all, and it catches the
errors that arithmetic cannot. Before you write down a conclusion,
ask who is *not* in the data that produced it. A survey of people who
answered the phone is a survey of people who answer phones. A
"school-wide" result gathered in one period is a result about the
students in that period. A dataset with the incomplete rows deleted
has quietly removed the people whose lives were too complicated to
fit the form — and those people are frequently the point. A
conclusion that survives this question is worth defending; one that
does not was never true, however clean the calculation was, and
[[What Makes a Model Good]] is where that argument gets its full
hearing.
