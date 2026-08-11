---
title: Loops
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
[[Computational Thinking]] made a promise: anything that repeats is a
loop waiting to be written. You have already *been* one — executing
the same steps over and over in [[Human Robot]]. Copy-pasting a line
five times works too, until "five" becomes "five hundred", or "until
they get it right". Loops let a program repeat without you repeating.

## for — when you can count the laps

```python
for number in range(1, 6):
    print(number, "times 7 is", number * 7)
```

`for` runs its block once per item — here, once for each number from
1 through 5. Use it when the number of repetitions is knowable before
the loop starts: every question in a quiz, every line in a file.

## while — when you cannot

```python
answer = ""
while answer != "yes":
    answer = input("Are we there yet? ")
print("Finally.")
```

`while` keeps going as long as its condition stays true. You cannot
know in advance how many tries a player will need in
[[Guess My Number]] — that is `while` territory. The danger is a
condition that never turns false: the infinite loop. When a program
hangs, that is the first suspect.

## Choosing between them

One question settles it: *do I know the lap count before the loop
begins?* Known count → `for`. Repeat until something changes →
`while`.

## Off by one

The most famous loop bug is being wrong by exactly one lap.

> [!question]- Self-check: how many lines does this print?
> ```python
> for count in range(3, 7):
>     print(count)
> ```
> Four — 3, 4, 5, 6. `range` includes its first number and stops
> *before* its second. Fence-post errors like this are why
> [[Predict the Output]] exists: it is cheaper to be wrong out loud
> than in code.

When loops start feeling natural, [[Loops Practice]] has the reps —
and [[The Quiz Machine]] is where they begin earning their keep.

%%curriculum-start%%
## Curriculum connection

![[C1.5]]

![[C2.4]]
%%curriculum-end%%
