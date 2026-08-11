---
title: Box Plots and Quartiles
draft: false
created: __CREATED__
tags:
  - concepts
---
A single average can hide almost everything. Two classes can share a
median mark while one is tightly bunched and the other is scattered
from top to bottom — and anyone deciding based on the median alone
would never know. Box plots exist to show the *spread* of one
variable, not just its middle.

## Quartiles are fair quarters

Sort the data, then cut it into four groups with equal *counts* — not
equal widths. The three cut points are the quartiles: $Q_1$, the
median, and $Q_3$. Between $Q_1$ and $Q_3$ sits the middle half of
the data, and the width of that interval — the **interquartile
range** — is the honest one-number answer to "how spread out is
this?". The box in a box plot *is* that middle half; the whiskers
stretch to the least and greatest values. A long box means the middle
half disagrees with itself; a long whisker means stragglers.

> [!success]- Quick self-check (click to expand)
> Data (already sorted): $4,\ 6,\ 7,\ 8,\ 9,\ 11,\ 15$. The median is
> the middle value, $8$. The lower half $4, 6, 7$ has median
> $Q_1 = 6$; the upper half $9, 11, 15$ has median $Q_3 = 11$. So the
> five-number summary is $4,\ 6,\ 8,\ 11,\ 15$ and the interquartile
> range is $11 - 6 = 5$. Half of all the values live in that span of
> five.

## Comparing groups honestly

Box plots earn their keep when two or more groups sit on the same
scale. Stacked box plots let you compare middles *and* spreads at
once: maybe both bus routes have the same median wait, but one has a
box twice as wide — same "typical", very different gamble. Resist the
urge to crown a winner from medians alone; overlapping boxes mean the
groups genuinely intermingle, and saying so is more truthful than a
verdict. Note what box plots give up, too: they show no individual
values and cannot show *how many* points there are — which is why
[[A Data Story]] asks you to choose a display to *match* your claim,
and why the questions in [[Who Does Data Serve]] apply to displays,
not just data. For relationships between *two* variables, you want
[[Scatter Plots and Trends]] instead.

%%curriculum-start%%
## Curriculum connection

![[D1.2]]
%%curriculum-end%%
