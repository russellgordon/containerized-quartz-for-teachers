---
title: A Budget Calculator in Code
draft: false
created: __CREATED__
tags:
  - coding
enableToc: true
---
This page reverses the usual order: the code is already written, and
your job is to *read* it, predict its outputs, and then alter it when
circumstances change — because circumstances always change, and a
budget that cannot bend is a budget that breaks.

## The code

```python
income = 220        # per month: part-time shifts plus allowance

phone = 45
transit = 60
food = 50
fun = 40

spending = phone + transit + food + fun
savings = income - spending

print("Spent each month:", spending)
print("Saved each month:", savings)
print("Saved after a year:", savings * 12)
```

## Read it before you run it

Predict all three printed numbers before touching the run button.
Then check — and if any missed, trace which line surprised you.

One more prediction: which single variable, reduced by $\$10$, would
change *all three* outputs? Is there any variable that would change
only some of them?

## Alter it

Life intervenes, twice:

1. The transit pass rises to $\$75$ a month. Change one line,
   predict the new yearly savings before running, and write one
   sentence justifying which *other* line you would change to
   protect your savings — every budget change needs a rationale.
2. You want a $\$480$ concert ticket. Add a line that prints how
   many months of saving it takes at your adjusted rate. If the
   answer feels too slow, decide what to cut — and defend the cut.

Money that sits in savings can also grow on its own; how, and by
how much, is the business of [[Interest and Growth]].

%%curriculum-start%%
## Curriculum connection

![[C2.3]]

![[F1.4]]
%%curriculum-end%%
