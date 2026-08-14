---
title: The Border Problem
publish: true
created: __CREATED__
tags:
  - explorations
enableToc: true
---
A square swimming pool, 10 tiles by 10 tiles, needs a border exactly
one tile wide all the way around. The question is not just *how many
border tiles* — it is *how many ways can you see the count without
counting one tile at a time?*

## The task

Find the number of border tiles for the 10-by-10 pool using a method
you can point at: a way of chopping the border into pieces whose
sizes you know. Then find a *second* way, and a third — different
chops, same border. For each way of seeing, write the count for an
$n$-by-$n$ pool as an expression, so that the expression's shape
matches the picture's shape. Your board should end up holding several
expressions that look nothing alike. The final job: convince another
group that they all *must* agree, for every $n$ — without checking
numbers one at a time.

> [!question]- Getting started (click to expand)
> - The corners are the whole difficulty. In your chop, who owns
>   them? Make sure nobody is counted twice — or not at all.
> - If 10-by-10 feels big, shrink it. A 4-by-4 pool fits on a board
>   corner, and a good method survives the trip back up.
> - "Four strips of…" — of what length, exactly? Say it from the
>   picture before you say it in symbols.

## What mathematics tends to surface

The same border yields $4n + 4$, $4(n + 1)$, $2(n + 2) + 2n$, even
$(n+2)^2 - n^2$ — one from strips, one from corners-first, one from
the big square minus the pool. Expressions that *look* different but
agree everywhere is the whole idea of equivalence, and expanding each
one down to $4n + 4$ is [[Expanding and Factoring]] with a picture
attached. The big-square-minus-pool view is a difference of squares
you can stand on.

## An extension

A paver has one square slab, $x$ by $x$, plus 8 thin strips, each
$x$ long and 1 wide. Arrange *all* of it into one large square — as
close as you can get. How many single tiles must you borrow to finish
the corner, and why is the answer "half of 8, then square it"? Hold
on to that move: [[The Vertex Form]] will pay it back with interest,
and [[Expanding and Factoring Practice]] keeps the chops sharp.

> [!note] The answer is not on this page
> No count and no expression list is printed here. The ways of
> seeing are your group's to find and defend at the boards.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.5]]
%%curriculum-end%%
