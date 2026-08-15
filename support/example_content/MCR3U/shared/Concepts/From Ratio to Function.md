---
title: From Ratio to Function
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
For most of your mathematical life $\sin$ has been a ratio — a number
you get out of a triangle. Turning it into a *function* means letting
the angle be the input and watching what comes out as the angle keeps
growing past the triangle's limits, and the graph you get is the reason
trigonometry describes tides, sound, daylight, and alternating current.

## The unit circle does the work

Put a point on a circle of radius 1 and let it travel counterclockwise.
At angle $x$ the point is at $(\cos x, \sin x)$. So:

- $\sin x$ is the **height** of the point above the horizontal axis;
- $\cos x$ is its **horizontal position**.

Now let $x$ keep growing past $90^\circ$, past $180^\circ$, past
$360^\circ$. The triangle stopped making sense a while ago; the circle
does not care. Plot the height against the angle and a wave appears,
repeating every $360^\circ$ because the point has come back to where it
started.

That repetition is what **periodic** means, and it is the property that
makes these functions useful for anything that cycles.

## Reading a periodic graph

| Feature | What it is | How to find it |
| --- | --- | --- |
| Period | The horizontal length of one full cycle | Peak to the next peak |
| Amplitude | Half the distance from maximum to minimum | $\dfrac{\max - \min}{2}$ |
| Axis | The horizontal centre line | $\dfrac{\max + \min}{2}$ |
| Phase shift | How far the cycle starts from the standard position | Compare a peak with where the parent's peak sits |

A function is **sinusoidal** when it has that shape — a smooth,
symmetric wave. Many periodic functions are not: a sawtooth voltage and
the number of daylight minutes rounded to whole days both repeat without
being sinusoidal. Periodic is the general family; sinusoidal is the
smooth member of it.

## The four parameters again

$$y = a\sin\bigl(k(x - d)\bigr) + c$$

The same $a$, $k$, $d$, $c$ as everywhere else in this course, with
trigonometric names attached:

- $\lvert a\rvert$ is the **amplitude** — how tall the wave is.
- $k$ compresses horizontally, so the **period** becomes
  $\dfrac{360^\circ}{\lvert k\rvert}$. This is the one that surprises
  people: a larger $k$ makes a *shorter* period.
- $d$ is the **phase shift**, moving the wave sideways.
- $c$ raises the **axis** to $y = c$.

Predict each before you graph it in [[Using Desmos]], the same routine
as [[Transformations of Functions]]. The habit is the point: the
parameters do not change meaning when the parent function changes, and
noticing that is most of what Grade 11 functions is for.

## Going from a situation to an equation

Given real measurements — a tide table, a Ferris wheel, hours of
daylight — the route is always the same:

1. Find the maximum and minimum. Those give the amplitude and the axis.
2. Find how long one cycle takes. That gives $k$.
3. Decide where the cycle starts. That gives $d$, and choosing $\sin$
   or $\cos$ can make $d$ zero — take the easier one.
4. Check with a data point you did not use to build it.

Step 4 is the one students skip and the one that catches a wrong period.
[[The Ferris Wheel]] and [[The Tide Problem]] are where you do all four
under real conditions.

%%curriculum-start%%
## Curriculum connection

![[D2.3]]

![[D2.5]]

![[D3.2]]
%%curriculum-end%%
