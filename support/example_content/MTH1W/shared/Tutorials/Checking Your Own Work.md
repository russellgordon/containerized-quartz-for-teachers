---
title: Checking Your Own Work
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Nobody marks your checker but you. Every mathematician you will ever
meet runs one — a quiet second pass that catches errors before they
matter — and the earlier you build yours, the sooner tests stop being
scary. Four habits make up the whole machine.

## Substitute back

Solved an equation? The equation itself will referee. If you believe
$x = 4$ solves $2x + 7 = 15$, feed it back in: $2(4) + 7 = 15$. A true
statement means solved; a false one means the equation just caught
you — no answer key required. [[Solving Equations]] builds this in
from day one, and code makes the referee effortless:

```python
x = 4
print(2 * x + 7 == 15)  # True means the solution checks
```

## Estimate first, compare after

Before solving, write down a rough expected size — the reflex
[[Estimation Duels]] trains. Expected "around 50" and got 4 967? One
of you is wrong, and now you know to look. This check only works if
the estimate came *before* the answer did.

## Check the units

Units are a free error detector. If a phone-plan answer arrives in
dollars per gigabyte when the question asked for gigabytes, something
upstream broke — and the units caught it without you rereading one
step. Carry them through every line, as [[Showing Your Thinking]]
insists.

## Run the inverse

Most operations have an undo. Subtracted? Add back. Multiplied?
Divide. Converted metres to centimetres? Convert back and see whether
you land where you started. A round trip that fails has found your
error; one that succeeds bought certainty for the price of a line.

%%curriculum-start%%
## Curriculum connection

![[C1.5]]
%%curriculum-end%%
