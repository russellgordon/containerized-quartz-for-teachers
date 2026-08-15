---
title: Derivatives of Sinusoidal Functions
publish: true
created: __CREATED__
tags:
  - concepts
---
In today's [[Graph Talks]], the graph on the screen was $y = \sin x$
and the question was only this: *where is it steepest?* Your group
pointed at the places the curve crosses its axis, and flat spots at
the crests and troughs. Then you plotted those slopes as points in
their own right — steepest, flat, steepest-downhill, flat — and a
familiar shape assembled itself out of the slopes of sine. The
derivative of $\sin x$ was hiding in plain sight:

$$\text{If } f(x) = \sin x, \text{ then } f'(x) = \cos x$$

Where sine crests, cosine crosses zero — the flat top of the wave.
Where sine crosses zero going up, cosine sits at its maximum — the
steepest climb. The same slope-plotting move on $y = \cos x$ gives
$-\sin x$: cosine starts at a crest, so its derivative starts flat
and goes negative.[^1]

## The four-step cycle

Differentiate repeatedly and the family chases its own tail:

$$\sin x \;\to\; \cos x \;\to\; -\sin x \;\to\; -\cos x \;\to\; \sin x$$

Four derivatives return you home. No other functions you have met do
this, and it is the mathematical signature of things that oscillate
— a pendulum's displacement and velocity trade shapes exactly this
way, which the motion-sensor demonstration made visible: the bob is
fastest through the middle, momentarily still at the ends.

## Combinations that model the world

Real oscillations arrive dressed: a tide is not $\sin t$ but
something like $3\sin\left(\frac{\pi t}{6}\right) + 5$. The chain
rule from [[The Chain Rule]] handles the dressing — the inside
$\frac{\pi t}{6}$ reports its rate $\frac{\pi}{6}$ as a factor —
and the product rule handles genuine hybrids like $x \sin x$. That
is all the machinery there is; the [[Smooth Landing]] task asks you
to make a descent profile behave using exactly these moves, and
[[Exponential and Sinusoidal Derivatives Practice]] works the same
muscles on tides, daylight, and pendulums.

One habit to keep: before differentiating any sinusoidal model,
predict where the rate should be zero — the crests and troughs of
the story — and check your derivative against the prediction. A
tide's rate of rise at high tide had better come out to zero, and
when it does, you know far more than "the algebra worked".

[^1]: All of this is true in radians only — one more reason radians
    are the calculus-ready angle measure. Differentiate sine in
    degrees and an unlovely factor of $\frac{\pi}{180}$ leaks into
    every formula.

%%curriculum-start%%
## Curriculum connection

![[A2.4]]

![[A3.5]]

![[B2.3]]
%%curriculum-end%%
