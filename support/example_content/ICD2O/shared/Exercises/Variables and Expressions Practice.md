---
title: Variables and Expressions Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Data in Programs]] — the tracing habit comes
from [[Predict the Output]]. Trace on paper first; the computer checks.

## Questions

1. After these lines run, what is stored in `score`? Explain why `=`
   here cannot mean what it means in maths class.
   ```python
   score = 10
   score = score + 5
   ```
2. **Predict the output**, character by character — spaces count.
   ```python
   first = "Rob"
   last = "Ott"
   print(first + last)
   ```
3. **Predict the output.** Does changing `a` afterwards change `b`?
   ```python
   a = 3
   b = a
   a = 7
   print(b)
   ```
4. **Find the bug.** `prize = "100"` then `total = prize + 50` — and
   line 2 crashes. Name the problem, then fix it two different ways.
5. Write a three-line snippet: your name in one variable, your
   favourite number in another, then print a sentence using both.
6. **Challenge.** Variables `red` and `blue` hold values. Swap them —
   afterwards, each must hold the other's old value.

## Answers

> [!success]- Answer 1
> `score` is `15`. In Python, `=` is an instruction — work out the
> right side, store it on the left — so line 2 adds 5 to what is there.

> [!success]- Answer 2
> `RobOtt` — no space, because `+` glues strings together exactly as
> they are. Want `Rob Ott`? Add it yourself: `first + " " + last`.

> [!success]- Answer 3
> It prints `3`. Line 2 copies the *value* 3 into `b` — it does not
> tie `b` to `a` forever. Reassigning `a` later changes nothing.

> [!success]- Answer 4
> `prize` holds the *text* `"100"`, and adding text to a number is a
> `TypeError`. Fix 1: `prize = 100`. Fix 2: `total = int(prize) + 50`.

> [!success]- Answer 5
> One version — yours will differ: `name = "Priya"`, `number = 17`,
> then `print(name + " picks " + str(number) + " every time.")`.

> [!success]- Answer 6
> A third variable holds one value while the other moves:
> `spare = red`, `red = blue`, `blue = spare`. Try it *without* the
> spare and watch a value get overwritten — that is why it exists.

%%curriculum-start%%
## Curriculum connection

![[C2.1]]
%%curriculum-end%%
