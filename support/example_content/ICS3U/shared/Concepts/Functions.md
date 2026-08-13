---
title: Functions
draft: false
created: __CREATED__
tags:
  - concepts
---
By the end of [[The Repeated Chunk]] every group had the same
complaint. The program worked, but the eight lines that converted a
mark to a letter grade appeared four times, and when the cutoff for a
B changed, three of the four copies got updated. The bug was not in
any line of code. It was in having four copies at all.

A function is the fix: name a chunk of thinking once, then use the
name.

```python
def letter_grade(mark):
    if mark >= 80:
        return "A"
    elif mark >= 70:
        return "B"
    elif mark >= 60:
        return "C"
    elif mark >= 50:
        return "D"
    else:
        return "R"
```

Now the cutoff lives in exactly one place. Change it there and every
part of the program that grades anything changes with it — including
the parts you have not written yet.

## What the parts are called

| Part | In the example | What it does |
| --- | --- | --- |
| Definition | `def letter_grade(mark):` | Names the chunk |
| Parameter | `mark` | The information the chunk needs |
| Body | the indented lines | The thinking itself |
| Return value | `return "A"` | The answer it hands back |
| Call | `letter_grade(78)` | Asking for that thinking, here, now |

A call is not a copy. When Python reaches `letter_grade(78)` it jumps
into the function, runs it with `mark` set to `78`, and comes back
holding `"B"`. The function does not print anything and does not know
who asked — which is exactly what makes it reusable.

## Why "returns" beats "prints"

An early instinct is to make the function print the grade. Resist it.
A function that *returns* can be used in ways you did not anticipate:

```python
grade = letter_grade(78)              # store it
print(f"You earned a {letter_grade(78)}")   # show it
if letter_grade(mark) == "R":         # decide with it
    print("See me — let's make a plan.")
```

A function that prints can only ever do the one thing. This is the
first place in the course where a small design decision quietly
decides how useful your code will be to somebody else — which is the
whole subject of [[Who Is This For]].

> [!question]- Self-check: why does this function return `None`?
> (click to expand)
> ```python
> def double(number):
>     print(number * 2)
> ```
> It prints, but never returns. `result = double(5)` displays `10` and
> then puts `None` in `result`, because a function with no `return`
> hands back nothing. Swap `print` for `return` and the caller decides
> what to do with the answer.

## Where this goes next

Functions are the unit you will design in when the problem gets bigger
than one screen — see [[Decomposition and Design]], where a whole
program becomes a handful of well-named chunks. Every program you
build from here on, including [[The Community App]], is easier to
finish and far easier to hand to somebody else when the thinking has
names. Practise the mechanics in [[Functions Practice]], then read
somebody else's in [[Writing Functions]].

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.2]]

![[B2.3]]
%%curriculum-end%%
