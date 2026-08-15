---
title: Working With Census Data
publish: true
created: __CREATED__
tags:
  - mapping
  - unit-3
---
Canada counts itself every five years, publishes the result free, and lets
you look up any community in the country. Most of the skill is knowing
which product you are holding.

## The tool

Census Profile is the front door:
[www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/index.cfm?Lang=E](https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/index.cfm?Lang=E)
(accessed August 2026). No account, no fee. Search by **place name, postal
code, or geographic code**, or browse down through a province.

Every geography carries an identifier that appears in the address bar once
you land on a profile. Notice it, because it is how you prove two people
looked at the same place. "Toronto" is ambiguous; `2021A00053520005`, the
census subdivision for the City of Toronto, is not.

## Choosing a variable

Profiles run to hundreds of rows, so the question comes first and the
variable second: size and change, age structure, households and dwellings,
or origins and language. Then take a **rate** rather than a count wherever
you plan to map it — [[Making a Thematic Map]] depends on that difference.

The City of Toronto profile from the 2021 Census returns a population of
2,794,356 against 2,731,571 in 2016, a change of 2.3 per cent, on 631.10
square kilometres, with an average age of 41.5 and a median of 39.6. Each
figure means something only with a boundary and a year attached.

> [!warning] 2021 is the current census. There is no 2026 census data yet
> The 2026 Census was collected in May 2026, but the first population and
> dwelling counts are not released until **10 February 2027**. Until then,
> 2021 is the most recent published count.
>
> You will still find "2026 population" figures online. Those are
> **quarterly estimates** — a different Statistics Canada product, built
> by starting from a census count, adjusting for people the census missed,
> and adding growth since. Estimates are useful, and they are not counts.
>
> The gap is big enough to wreck an argument. The Toronto census
> metropolitan area was **6,202,225 by the 2021 count** and roughly **7.1
> million by the estimate for 1 July 2024**. Same place, two instruments.
> Never put a count and an estimate in one table, and always write which
> one you used.

## Before you quote a number

Say the boundary out loud — city or census metropolitan area, tract or
subdivision, since all of them get called "Toronto" by somebody. Say the
year. Say whether it is a count or an estimate. Do those three things and
a stranger can check you, which is the only standard that matters;
[[Citing Geographic Sources]] has the format.

Build the argument in [[The Population Profile]]; the concepts behind the
variables are in [[Reading a Population]].

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[D1.1]]
%%curriculum-end%%
