---
title: Loops Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Loops]]. A loop is a bargain with the
computer: you describe one round precisely, it does all of them.

## Questions

1. Which of these needs a loop — (a) locking one door, (b) handing
   back 28 quizzes, (c) wearing boots *if* it rains?
2. **Predict the output** — how many lines, and what is on each?
   ```python
   for number in range(4):
       print(number)
   ```
3. Trace `total` through every round, then predict what prints.
   ```python
   total = 0
   for number in range(1, 4):
       total = total + number
   print(total)
   ```
4. **Find the bug.** This countdown never reaches lift-off — or ends.
   ```python
   count = 3
   while count > 0:
       print("T-minus", count)
   ```
5. Write a loop that prints `10` down to `1` — countdown style.
6. **Challenge.** Keep asking `Password?` until the user types
   `sesame`, then print how many attempts were needed.

## Answers

> [!success]- Answer 1
> Only (b) — one action, 28 repeats. (a) is a single step, and (c) is
> a decision: a job for a [[Conditionals|conditional]], not a loop.

> [!success]- Answer 2
> Four lines: `0`, `1`, `2`, `3`. `range(4)` starts at 0 and stops
> *before* 4 — four numbers, none of them 4. Everyone trips on this.

> [!success]- Answer 3
> `total` goes 0, then 1, then 3, then 6 — `range(1, 4)` supplies 1,
> 2, 3. Only `6` prints: the `print` sits *outside* the loop.

> [!success]- Answer 4
> Nothing inside the loop ever changes `count`, so `T-minus 3` prints
> forever. Add `count = count - 1` inside — it ends in three lines.

> [!success]- Answer 5
> `for number in range(10, 0, -1):` then `print(number)` beneath.
> The third value steps by `-1`; the stop value `0` is never printed.

> [!success]- Answer 6
> Start `attempts = 0` and `word = ""`. Then `while word != "sesame":`
> read `word = input("Password? ")` and add 1 to `attempts` inside the
> loop. Print `attempts` after — the loop only ends on success.

%%curriculum-start%%
## Curriculum connection

![[C2.4]]

![[C1.5]]
%%curriculum-end%%
