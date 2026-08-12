---
title: Rates of Change
draft: false
created: __CREATED__
tags:
  - concepts
---
In [[How Fast Is It Changing?]], your group could compute the average
speed of a falling object over any interval — that was just Grade 9
slope — but the question on the board was harder: how fast is it
falling *right now*, at the instant $t = 3$? "Right now" is a single
point. Slope needs two. That tension is the question calculus asks,
and this page takes you to its doorstep.

## Average — the slope you can compute

The **average rate of change** of $f$ over an interval is the change
in output over the change in input:

$$\frac{f(b) - f(a)}{b - a}$$

Geometrically it is the slope of the **secant** — the line through
the two endpoints on the graph. It is an honest summary and a blunt
one: a ball thrown upward can have an average velocity of *zero*
over an interval where it plainly moved, because it came back to
where it started. For a linear function the rate never changes; for
everything else in this course, *the rate itself changes*, which is
exactly what makes the question "how fast right now?" non-trivial.

## Instantaneous — the slope you can corner

You cannot compute a slope at one point. But you can *trap* it. Fix
one end of the secant at the moment you care about and slide the
other end closer, and the secant slopes settle toward a single value.
For the falling object $d = 5t^2$, anchored at $t = 3$:

| Interval      | Average rate (m/s) |
| ------------- | ------------------ |
| $[3, 4]$      | $35$               |
| $[3, 3.1]$    | $30.5$             |
| $[3, 3.01]$   | $30.05$            |
| $[3, 3.001]$  | $30.005$           |

The slopes are cornering $30$ — and the line they are cornering is
the **tangent**, the line that grazes the curve at that single point.
The **instantaneous rate of change** is the tangent's slope: $30$
m/s, the number a speedometer would show. Every average in the table
is an approximation of it, and the shorter the interval, the better
the approximation.

Where the tangent is flat, the function has paused — the ball at the
top of its arc; where the tangent tilts down, the function is
falling. Reading tangents is reading the function's story. What this
course does *not* give you is a machine for producing tangent slopes
exactly — that machine is the derivative, and it is the opening act
of calculus. What you own now is the idea the machine is built from.

[[Rates of Change Practice]] works both rates from tables, graphs,
and equations — no formulas, all reasoning.

%%curriculum-start%%
## Curriculum connection

![[D1.4]]

![[D1.5]]

![[D1.6]]

![[D1.7]]
%%curriculum-end%%
