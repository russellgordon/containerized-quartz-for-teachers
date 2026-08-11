---
title: Variables and Formulas in Code
draft: false
created: __CREATED__
tags:
  - coding
enableToc: true
---
On paper, an expression from [[Algebraic Expressions]] is frozen — you
evaluate it once and it holds still. In code, the same formula is a
living thing: change one variable, run again, and every consequence
updates itself. This is what "generalizing a relationship" buys you.

## The code

```python
base_fee = 15
cost_per_gb = 2
data_used = 6

bill = base_fee + cost_per_gb * data_used
print("This month's bill:", bill)

width = 4
length = width + 5
perimeter = 2 * width + 2 * length
print("Perimeter:", perimeter)
```

Two formulas, one habit: name the quantities, state the relationship,
let the machine do the arithmetic.

## Read it before you run it

Commit to answers on paper first:

1. What bill will print? Trace it: $15 + 2 \times 6$.
2. What perimeter will print? Careful — `length` depends on `width`.
3. Set `data_used = 0` in your head. What is the bill now, and which
   part of $y = mx + b$ from [[Linear Relations]] did you just find?

Run it and compare. The bill formula is exactly the phone-plan maths
from [[Which Phone Plan]] — code just lets you ask "what if?" faster
than a table of values ever could.

## Alter it

A rival plan charges a $\$10$ base fee but $\$3$ per gigabyte.
Alter the program to model it, predict the bill for 6 GB before
running, then find — by experimenting with `data_used` — the amount
of data where the two plans cost exactly the same. That crossover
point is worth writing down; it returns when linear relations meet.

%%curriculum-start%%
## Curriculum connection

![[C2.1]]

![[C1.2]]
%%curriculum-end%%
