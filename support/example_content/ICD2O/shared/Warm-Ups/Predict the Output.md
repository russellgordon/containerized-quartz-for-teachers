---
title: Predict the Output
publish: true
created: __CREATED__
tags:
  - warm-ups
---
A short program goes on the board. Before anyone touches a keyboard,
you commit to a prediction — the exact output, in ink. Then we run
it. Being wrong costs nothing; refusing to commit costs everything —
the gap between prediction and reality is where the learning lives.

## How to run it

1. Read the program twice, silently — no talking yet.
2. Write the exact output you expect, character for character.
3. Compare with a neighbour; the code, not volume, settles disputes.
4. Run it. Surprised? The line that fooled you is today's lesson.

> [!example]- One program, three defensible readings (click to expand)
> ```python
> x = "5"
> y = x + x
> print(y)
> ```
> `10` — five plus five. `55` — the quotation marks make `x` text,
> and `+` glues text together. A crash — you cannot add words. Only
> one reading is what Python does; the quotation marks decide it.

## One variation

Reverse it: show only the *output*; pairs write a program that would
produce it. There is never just one answer — which is the point.

> [!tip] Commit before you run
> A guess never written down cannot surprise you, and code that never
> surprises you never teaches you — [[Debugging Is the Job]] says why.

%%curriculum-start%%
## Curriculum connection

![[C2.6]]

![[C3.1]]
%%curriculum-end%%
