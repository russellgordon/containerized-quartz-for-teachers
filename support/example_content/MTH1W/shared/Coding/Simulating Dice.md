---
title: Simulating Dice
publish: true
created: __CREATED__
tags:
  - coding
enableToc: true
---
You can *reason* that a fair die shows a six one time in six — but
what does that actually look like in ten rolls? In ten thousand?
Simulation lets you experience variability and sample size directly,
which is the instinct [[A Data Story]] will lean on when real data
arrives messy.

## The code

```python
import random

rolls = 10
sixes = 0

for roll_number in range(rolls):
    result = random.randint(1, 6)
    if result == 6:
        sixes = sixes + 1

print(sixes, "sixes in", rolls, "rolls")
```

`random.randint(1, 6)` is the die; the `if` line is you, tallying.

## Read it before you run it

1. How many sixes do you *expect* in 10 rolls? Is 0 a reasonable
   outcome? Is 5?
2. If you run the program twice, will the outputs agree?
3. Change `rolls` to `10000` in your head. Roughly how many sixes
   now — and roughly what *fraction* of the rolls is that?

Now run it ten times at `rolls = 10` and record each result — the
scatter will surprise you. Then set `rolls = 10000` and run a few
times more. The count still varies, but the fraction settles hard
against $\frac{1}{6} \approx 0.167$. Small samples swing wildly;
large samples steady — you have just watched the reason polls,
studies, and [[Scatter Plots and Trends]] all care about sample size.

## Alter it

Simulate *two* dice and count how often the sum is 7. Before
running: will 7 come up more often, less often, or as often as 12?
List the ways each sum can happen, commit to a prediction, then let
ten thousand rolls settle the argument.

%%curriculum-start%%
## Curriculum connection

![[C2.2]]

![[D2.4]]
%%curriculum-end%%
