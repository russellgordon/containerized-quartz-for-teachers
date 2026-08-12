---
title: Random Variables and Distributions
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[The Simulation]] your group rolled two number cubes a few hundred
times — physically at first, then a few hundred thousand times once
the spreadsheet took over — and built a histogram of the sums. Somebody
had predicted a flat bar chart. What appeared was a tent, peaked at 7,
falling away on both sides. Nothing was rigged. The shape was there
before you rolled anything, waiting in the structure of the sample
space. A distribution is what that shape is called once you write it
down honestly.

## A random variable is a rule, not a mystery

A **discrete random variable** $X$ assigns one number to each outcome
of a discrete sample space. Toss a coin ten times: the outcome is a
sequence of heads and tails, but $X$ = "number of heads" turns it into
a single number from $0$ to $10$. Roll two cubes: the outcome is an
ordered pair, and $X$ = "the sum" turns it into a number from $2$ to
$12$.

That translation is the point. Outcomes are hard to add up; numbers
are not. Once you have a random variable you can average it, graph it,
and compare it to another one — none of which you can do with "heads,
tails, heads, heads".

The **probability distribution** of $X$ is the function that maps each
value $x$ to $P(X = x)$. Almost always you meet it first as a table.

| $x$ (sum) | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| $P(X = x)$ | $\frac{1}{36}$ | $\frac{2}{36}$ | $\frac{3}{36}$ | $\frac{4}{36}$ | $\frac{5}{36}$ | $\frac{6}{36}$ | $\frac{5}{36}$ | $\frac{4}{36}$ | $\frac{3}{36}$ | $\frac{2}{36}$ | $\frac{1}{36}$ |

Add the row: $\frac{36}{36} = 1$. Every distribution you ever write
must pass that check, and it catches more mistakes than any other
habit in Unit 2.

## Probability histograms, and why the area is 1

A **probability histogram** draws one rectangle per value of $X$, each
with base $1$ centred on that value, and height $P(X = x)$. Since
area $=$ base $\times$ height $= 1 \times P(X = x)$, the area of each
bar *is* its probability, and the total area is $1$.

That is the same tent your class built from experimental data, with
one difference worth being precise about: the frequency histogram had
counts on its vertical axis and depended on how many times you rolled;
the probability histogram has probabilities and does not. Divide every
frequency by the number of trials and one becomes the other. As the
trials pile up, the experimental shape settles onto the theoretical
one — exactly the tendency you watched in [[Probability Basics]].

> [!example]- Two coins, worked from the sample space up
> Sample space: HH, HT, TH, TT — four equally likely outcomes. Let
> $X$ be the number of heads. Then $X = 0$ for TT, $X = 1$ for both
> HT and TH, and $X = 2$ for HH. So $P(X=0) = \frac{1}{4}$,
> $P(X=1) = \frac{1}{2}$, $P(X=2) = \frac{1}{4}$, summing to $1$.
> The histogram has three bars of heights $0.25$, $0.5$, $0.25$ and
> total area $1$. Notice that $X = 1$ is twice as likely as either
> extreme purely because two different outcomes map to it — the
> asymmetry between outcomes and values is where most intuition
> goes wrong.

## Discrete and continuous

A **continuous random variable** takes values from an infinite,
unbroken range: the time a task takes, the height of a seedling, the
distance a ball is thrown. You cannot list its values, and this has a
consequence that sounds wrong the first time: the probability that a
continuous variable equals any *single* exact value is $0$. Not
unlikely — zero. There are infinitely many values and only $1$ of
probability to share.

So for continuous variables you ask about **ranges** instead: the
probability that a bulb lasts between 90 and 115 hours, which is an
area under a curve rather than the height of a bar. That shift from
height to area is the doorway into [[The Normal Distribution]], and it
is why frequency polygons and interval widths matter so much once your
own investigation data arrives.

Next comes the single most useful number you can extract from a
distribution — its long-run average, in [[Expected Value]]. Build and
check distributions in [[Distributions Practice]].

%%curriculum-start%%
## Curriculum connection

![[B1.1]]

![[B1.3]]

![[B2.1]]

![[B2.5]]
%%curriculum-end%%
