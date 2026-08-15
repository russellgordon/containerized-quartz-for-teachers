---
title: Sinusoids in Radians
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
You met $y = a\sin(k(x-d)) + c$ in Grade 11 with the angle in degrees.
Nothing about the transformations changes here. What changes is the unit
on the horizontal axis — and that one change is what lets these
functions be differentiated next year, which is the real reason the
course insists on it.

## What radians change, and what they do not

The parameters do exactly what they always did:

| Parameter | Effect | In radians |
| --- | --- | --- |
| $a$ | Vertical stretch; reflects when $a<0$ | Amplitude is $\lvert a\rvert$ |
| $k$ | Horizontal compression | Period is $\dfrac{2\pi}{\lvert k\rvert}$ |
| $d$ | Horizontal translation | Phase shift, in radians |
| $c$ | Vertical translation | Axis at $y=c$ |

The only formula that changes is the period: $\tfrac{360^\circ}{|k|}$
becomes $\tfrac{2\pi}{|k|}$. Everything else is the same sentence in a
different language.

## Sketching, in the order that works

Given $y = 3\sin\bigl(2(x - \tfrac{\pi}{4})\bigr) + 1$:

1. **Axis first**: $y = 1$. Draw it.
2. **Amplitude**: 3, so the curve runs from $-2$ to $4$. Mark those.
3. **Period**: $\tfrac{2\pi}{2} = \pi$. One full cycle in $\pi$.
4. **Start point**: the parent's cycle begins at 0, so this one begins
   at $x = \tfrac{\pi}{4}$.
5. **Five points**: divide one period into quarters and place the
   maximum, the axis crossings, and the minimum.

Doing it in that order means no point is ever guessed. Doing it in any
other order means the phase shift gets applied to a curve whose shape is
not yet decided, which is where sketches go wrong.

## Reading the equation off a graph

Reverse the order:

1. Axis from the midline: $c = \tfrac{\max + \min}{2}$.
2. Amplitude: $a = \tfrac{\max - \min}{2}$.
3. Period from peak to peak, then $k = \tfrac{2\pi}{\text{period}}$.
4. Phase: compare a maximum with where the parent's maximum sits.

Choosing $\sin$ or $\cos$ is yours to make — pick whichever puts a
convenient feature at $x = 0$, and $d$ often becomes zero. Two different
equations describing the same curve are both correct, and saying so is
part of a complete answer.

## The tangent function

$\tan x$ is a ratio you have used for years; as a *function* it behaves
unlike the other two.

$$\tan x = \frac{\sin x}{\cos x}$$

Wherever $\cos x = 0$ the ratio is undefined, so at
$x = \tfrac{\pi}{2}, \tfrac{3\pi}{2}, \dots$ there are **vertical
asymptotes**. Between them the curve climbs from $-\infty$ to $+\infty$,
and the whole picture repeats every $\pi$ — not $2\pi$, which surprises
everybody the first time. Graph it in [[Using Desmos]] alongside
$\sin x$ and $\cos x$ and watch the asymptotes land exactly where the
cosine crosses zero.

There is no amplitude, because there is no maximum or minimum to take
half of. A question asking for the amplitude of a tangent function is
testing whether you noticed.

## Posing your own problem

The expectation that catches people is the one asking you to *pose* a
problem, not solve one. It means: find a periodic situation, decide what
the variables are, choose a sensible domain in radians, and write the
question you would want answered.

Good candidates are around you — a wheel, a tide, a pendulum, daylight
across a year, an alternating voltage, the depth of water in a tank
being filled and drained on a cycle. The test of a well-posed problem is
that somebody else can answer it without asking you what you meant, and
that its answer is a number with a unit.

%%curriculum-start%%
## Curriculum connection

![[B2.2]]

![[B2.4]]

![[B2.5]]

![[B2.6]]

![[B2.7]]
%%curriculum-end%%
