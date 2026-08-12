---
title: Sinusoidal Functions
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The height graph your group sketched during [[The Ferris Wheel]] rose,
fell, and rose again — the same wave, over and over. Phenomena that
repeat on a fixed schedule are *periodic*: one complete repeat is a
**cycle**, the time it takes is the **period**, the horizontal midline
is the **axis**, and the distance from axis to peak is the
**amplitude**. The smoothest periodic functions of all come straight
out of trigonometry.

## From a spinning point to a graph

Take the rotating arm from [[Special Angles]] and record the height
of its tip as the angle grows: at 0° the height is 0, at 90° it
peaks at 1, at 180° it returns to 0, at 270° it bottoms out at $-1$.
Plot height against angle and the unit circle unrolls into the wave
$f(x) = \sin x$ — a genuine function, since one angle can only put
the arm in one place. Its period is 360°, its amplitude 1, its range
$-1 \le y \le 1$. Tracking the *horizontal* position instead gives
$f(x) = \cos x$: the identical wave, starting at its peak.

## Reading the equation

Sinusoids are transformed sines and cosines, and the recipe is the
same $a$, $k$, $d$, $c$ as [[Transformations of Functions]] — each
letter now owning a wave-word:

| Letter | Wave feature | How to read it |
| --- | --- | --- |
| $a$ | amplitude $= \lvert a \rvert$ | axis-to-peak distance |
| $k$ | period $= \dfrac{360°}{k}$ | bigger $k$, faster repeats |
| $d$ | phase shift | whole wave slides right by $d$ |
| $c$ | axis $y = c$ | max is $c + \lvert a \rvert$, min is $c - \lvert a \rvert$ |

So $f(x) = 3\sin(2(x - 15°)) + 4$ has amplitude 3, period 180°, a
15° shift right, axis $y = 4$ — hence a maximum of 7 and a minimum
of 1, and range $1 \le y \le 7$. To sketch it, transform a wave you
know, exactly as you transformed parabolas; to check it, type it into
[[Using Desmos|Desmos]] and see whether the peaks land where you
promised.

## Modelling without angles

The input does not have to be an angle. Tides, daylight hours,
breathing, a Ferris wheel seat — anything cyclic can ride a sinusoid
whose input is *time*. A tide with amplitude 5 m, high tide at
midnight, and a 12-hour cycle fits
$h(t) = 5\sin(30(t + 3))$, with $t$ in hours: the $k = 30$ delivers
the 12-hour period ($360° \div 30$), and the shift puts the peak at
$t = 0$. Build the equation from the story's features — amplitude
from half the high-low gap, $c$ from their average, $k$ from the
period, $d$ last — and then interrogate it: heights at any time,
times of any height.

That is precisely the job in [[The Tide Problem]], and
[[Sinusoidal Functions Practice]] rehearses every layer, from reading
equations to predicting what changes when the wheel spins faster.

%%curriculum-start%%
## Curriculum connection

![[D2.4]]

![[D2.6]]

![[D2.7]]

![[D3.3]]
%%curriculum-end%%
