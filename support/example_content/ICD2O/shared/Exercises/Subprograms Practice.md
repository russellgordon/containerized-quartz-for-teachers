---
title: Subprograms Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Subprograms and Modules]]. A function is a
recipe with a name — write it once, use it everywhere.

## Questions

1. **Predict the output** — how many lines, and in what order?
   ```python
   def greet(name):
       print("Hello, " + name + "!")
   greet("Ada")
   greet("Grace")
   ```
2. **Predict the output.** Trace the value all the way through.
   ```python
   def double(n):
       return n * 2
   print(double(5) + 1)
   ```
3. Inside a function, how do `print` and `return` differ? One
   sentence each.
4. **Find the bug.** This prints `5` — then crashes. Explain both.
   ```python
   def add(a, b):
       print(a + b)
   total = add(2, 3) + 10
   ```
5. Write a function `area(width, height)` that *returns* a
   rectangle's area, then one line using it for a 3 by 5 rectangle.
6. **Challenge.** Write `is_teen(age)` returning `True` or `False`,
   then use it in an `if` to decide on a movie ticket price.

## Answers

> [!success]- Answer 1
> Two lines: `Hello, Ada!` then `Hello, Grace!`. The `def` block runs
> nothing by itself — each *call* runs it, in the order called.

> [!success]- Answer 2
> `double(5)` hands back `10`, then `10 + 1` is `11`, so `11` prints.
> The `return` value flows to wherever the call sits.

> [!success]- Answer 3
> `print` shows a value to the *human* and keeps nothing. `return`
> hands a value back to the *program*, for the next step to use.

> [!success]- Answer 4
> `add` prints its answer but returns nothing, so `add(2, 3)` is
> `None` — and `None + 10` is a `TypeError`. Use `return a + b`.

> [!success]- Answer 5
> `def area(width, height):` with `return width * height` beneath —
> then `print(area(3, 5))`, which shows `15`.

> [!success]- Answer 6
> `def is_teen(age):` then `return age >= 13 and age <= 19` — the
> comparison already *is* `True` or `False`. Then `if is_teen(15):`
> discount price, `else:` full price.

%%curriculum-start%%
## Curriculum connection

![[C3.3]]
%%curriculum-end%%
