---
title: Coding Visual Patterns
draft: false
created: __CREATED__
tags:
  - coding
enableToc: true
---
Every growing pattern from [[Visual Patterns]] hides a rule: a
starting amount, plus a step repeated. A loop is that rule set in
motion — the computer builds term after term while you watch the
structure unfold. This page is training for [[Pattern Machines]].

## The code

```python
start = 4
step = 3

for term_number in range(1, 11):
    tiles = start + step * (term_number - 1)
    print("Term", term_number, "has", tiles, "tiles")
```

The line inside the loop is the pattern's rule, written once and
used ten times — that is what `range(1, 11)` arranges.

## Read it before you run it

Predictions on paper first:

1. How many lines will this print — ten or eleven? What do the two
   numbers in `range(1, 11)` actually mean?
2. What exactly will the first line of output say?
3. What will term 5 be? Check by counting up in steps of 3, *and* by
   the formula $4 + 3 \times (5 - 1)$.
4. Predict term 100 — without changing the code and without running
   anything 100 times. The formula hands it to you; that shortcut is
   the whole reason algebra beats counting.

Run it. Notice that `step` is the rate of change and `start` the
initial value — the same two numbers that define every relation in
[[Linear Relations]], wearing loop clothes.

## Alter it

Change `start` and `step` so that term 10 has exactly 40 tiles.
More than one answer works — find two, and explain to a partner why
the pattern has room for both.

%%curriculum-start%%
## Curriculum connection

![[C2.2]]

![[C3.2]]
%%curriculum-end%%
