---
title: The Locker Problem
draft: false
created: __CREATED__
tags:
  - explorations
enableToc: true
---
A hallway has 100 closed lockers. One hundred students walk it in turn.
Student 1 opens every locker. Student 2 changes every second locker —
open becomes closed, closed becomes open. Student 3 changes every third
locker, and so on, until student 100 changes locker 100 alone.

## The task

After all 100 students have walked the hall, which lockers are open?
Do not simulate all hundred in your head — find a way to know what
happens to *one* locker, and the whole hallway follows. Then the
question that matters: *why those lockers?* A list is an observation; a
reason that would still work for 1000 lockers is mathematics.

> [!question]- Getting started (click to expand)
> - Shrink the hallway. Ten lockers and ten students fits on one
>   whiteboard, and the pattern already shows itself.
> - Track locker 12 alone. Exactly which students touch it? What do
>   those student numbers have to do with 12?
> - A locker ends open if it is touched an odd number of times. What
>   kind of number gets touched an odd number of times — and why?

## What mathematics tends to surface

Every touch of locker $n$ comes from a factor of $n$, and factors come
in pairs — except when they don't. Groups usually land on a special
family of numbers and then have to explain *why* the pairing breaks
exactly there. The open lockers also thin out as the hallway grows,
which raises a bigger question about how special families sit inside
the endless list of naturals — the territory of
[[Number Sets and Infinity]].

## An extension

The rule is a set of instructions — which makes it code. Decompose the
hallway into computational steps and let a loop walk 1000 lockers, in
the spirit of [[Coding Visual Patterns]] (start with
[[Getting Started with Python]] if loops are new). Does your *why*
survive at any size?

> [!note] The answer is not on this page
> On purpose. Your class builds the why together at the boards — a
> printed list of open lockers would spoil the only part that matters.

%%curriculum-start%%
## Curriculum connection

![[B1.3]]

![[C2.2]]
%%curriculum-end%%
