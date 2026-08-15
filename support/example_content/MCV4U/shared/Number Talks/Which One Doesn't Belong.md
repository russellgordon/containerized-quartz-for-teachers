---
title: Which One Doesn't Belong
publish: true
created: __CREATED__
tags:
  - number-talks
---
Four functions, four corners, and one question: which one doesn't
belong? The trick is that there is no trick — every corner can be
defended, so the game is never about *the* answer. It is about
naming, precisely, the property your corner alone possesses — and in
this course, the sharpest properties are about *rates*: not what a
function is, but how it changes.

|  |  |
| --- | --- |
| **A** — $y = x^2$ | **B** — $y = e^x$ |
| **C** — $y = \sin x$ | **D** — $y = \lvert x \rvert$ |

> [!example]- A defence for every corner
> - **A** — the only one whose rate of change is itself a straight
>   line: the slopes read $2x$, growing steadily forever. Also the
>   only polynomial in the room.
> - **B** — the only one that *is* its own rate of change: at every
>   point, the slope equals the height. Also the only one with no
>   zero — it never touches the axis at all.
> - **C** — the only periodic one, and the only one whose slope
>   changes sign forever: climbing, falling, climbing, falling, for
>   the rest of time.
> - **D** — the only one with a point where the rate of change has
>   *no value*: zoom in on the corner at zero as long as you like
>   and it never straightens into a line. The other three all do —
>   a difference [[Zooming In]] hands your group a microscope for.

## One variation

Four ways of writing, four corners: $f'(3)$ · the slope of the
tangent to $y = f(x)$ at $x = 3$ ·
$\lim_{h \to 0} \frac{f(3+h) - f(3)}{h}$ ·
$\frac{f(4) - f(2)}{2}$. Three of the corners are the same number in
different costumes — the fourth is an impostor, an *average* rate
dressed convincingly as an instantaneous one, close enough to fool a
glance (and for some curves, close enough to be exactly right).
Finding it without computing anything is [[The Derivative]] earning
its keep.

> [!tip] "It looks different" scores nothing
> Precision is the whole game. Not "D is pointy" but "D has exactly
> one input where no tangent line exists, and everywhere else its
> slope is either $-1$ or $1$ with nothing in between". The
> slope-reading defences of corners A and B are the daily work of
> [[Derivative Rules]] — and the corner in D is the reason
> [[The Limit]] has to be stated carefully rather than waved at.
