---
title: Debugging Practice
publish: true
created: __CREATED__
tags:
  - exercises
---
Six snippets, six crashes. For each: read the error message *first*
and say what Python is complaining about, then fix the code, then
predict what the fix does. [[Debugging Step by Step]] has the method.

## Questions

1. `SyntaxError: '(' was never closed` — what was left unfinished?
   ```python
   print("See you later!"
   ```
2. `print(Hello)` crashes with `NameError: name 'Hello' is not
   defined`. Why does Python treat `Hello` as a *name*?
3. `age = int("ten")` stops with `ValueError: invalid literal for
   int() with base 10: 'ten'`. Translate that into English, then fix.
4. `IndentationError: expected an indented block` — expected where?
   ```python
   if score > 90:
   print("Amazing!")
   ```
5. `ZeroDivisionError: division by zero` — but nobody typed a zero.
   ```python
   people = 0
   print("Slices each:", 8 / people)
   ```
6. `SyntaxError: expected ':'` — fix it, then look again: a *second*
   bug is hiding here. Predict what the fixed code does.
   ```python
   while lives > 0
       print("Still playing")
   ```

## Answers

> [!success]- Answer 1
> The bracket. Every `(` needs a `)` — add it after the quote and the
> line prints `See you later!` exactly once.

> [!success]- Answer 2
> Without quotes, `Hello` looks like a variable — a name — and no
> variable called `Hello` exists. Quote it: `print("Hello")`.

> [!success]- Answer 3
> "You asked me to turn `'ten'` into a whole number, and I cannot."
> `int()` reads digits, not words — `int("10")` works fine.

> [!success]- Answer 4
> Indented *under the `if`*. The line after a `:` must step right so
> Python knows it belongs to the condition. Indent the `print`.

> [!success]- Answer 5
> The zero arrived by variable — `people` holds `0`, so line 2 divides
> by zero. Give `people` a sensible value, or check before dividing.

> [!success]- Answer 6
> The `while` line needs a colon at the end. Fixed, it runs — forever:
> nothing inside the loop ever changes `lives`. Crashes announce
> themselves; logic bugs like this one quietly ruin your day.

%%curriculum-start%%
## Curriculum connection

![[C2.6]]
%%curriculum-end%%
