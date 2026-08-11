---
title: Spot the Bug
draft: false
created: __CREATED__
tags:
  - warm-ups
---
One short program on the board, and a promise: it contains exactly
one bug. Your job is to find it by *reading* — no running, no random
guessing. Programs fail in a handful of predictable ways, and
learning to spot them cold is what turns a panicked debugging session
into the calm routine of [[Debugging Step by Step]].

## How to run it

1. Read the whole program before judging any line — bugs love the
   line you skimmed.
2. Decide: will it crash, or run and quietly do the wrong thing?
3. Name the line, name the fault, predict the exact error message.
4. Only then run it — and read the real message, bottom line first.

> [!example]- Try one (click to expand)
> ```python
> age = input("How old are you? ")
> if age >= 13:
>     print("Welcome to the teen zone")
> ```
> It looks fine, and it crashes on line 2. `input` always hands back
> *text*, and Python refuses to compare text with the number `13`.
> The fix is one word — but naming the fault is today's whole job.

## One variation

Show only a traceback — no program at all — and work backwards: what
kind of line must have produced this message?

> [!tip] Error messages are not insults
> They are the most honest writing you will read all day — what went
> wrong, and where. Read them calmly, bottom line first, every time.

%%curriculum-start%%
## Curriculum connection

![[C2.6]]
%%curriculum-end%%
