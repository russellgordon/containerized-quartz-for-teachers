---
title: Getting Started with Python
draft: false
created: __CREATED__
tags:
  - coding
enableToc: true
---
A variable in algebra is a letter holding a value. A variable in code
is the same idea, made touchable: you set it, use it, and change it —
and the computer keeps perfect track. This first program does nothing
but print, calculate, and store, which is exactly enough.

## The code

Type this into an online Python interpreter — typing it yourself,
rather than pasting, is how the syntax gets into your hands:

```python
print("Hello, MTH1W!")
print(3 + 4 * 2)

storeys = 5
stretch_per_storey = 40
total_stretch = storeys * stretch_per_storey
print(total_stretch)

storeys = 12
print(storeys * stretch_per_storey)
```

## Read it before you run it

Write down your answers *before* pressing run — the gap between your
prediction and the output is where the learning lives:

1. Will the second line print $14$ or $11$? Which order of
   operations does Python believe in?
2. What number does `print(total_stretch)` show?
3. After `storeys = 12`, what does the last line print — and does
   the value of `total_stretch` change too? Why or why not?

Now run it. If any output surprised you, you just found the
interesting part — question 3 catches almost everyone once. This is
the [[Bungee Drop]] calculation, by the way: cord stretch per storey,
done by machine.

## Alter it

Make the program yours: add variables for something you actually buy
— bus tickets, bubble tea, anything with a price — and have the
program print the cost of 7 of them. Predict the output before you
run, as always.

%%curriculum-start%%
## Curriculum connection

![[C2.1]]
%%curriculum-end%%
