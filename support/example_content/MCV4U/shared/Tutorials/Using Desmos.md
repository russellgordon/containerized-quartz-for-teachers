---
title: Using Desmos
draft: false
created: __CREATED__
tags:
  - tutorials
---
Desmos is free, runs in any browser, and is the fastest way in the
world to ask a graph a question. Treat it as a thinking tool — a place
to test conjectures — not an answer machine you obey.

## A slider on a secant

Type $f(x) = x^2$, then the secant slope
$\frac{f(3 + h) - f(3)}{h}$ with a slider for $h$. Before you drag
anything, **predict aloud**: what should the slope read at $h = 1$?
What happens as $h$ slides toward zero — and what happens *at* zero?
Then slide, and watch the number settle toward 6 while the input it
wants is the one input it cannot have. Two minutes of sliding builds
the intuition behind [[The Limit]] faster than an hour of tables —
and the gap at $h = 0$ is not a bug in Desmos; it is the exact hole
[[The Derivative]] was invented to speak about. Prediction first is
what keeps Desmos a thinking tool; sliding without predicting is
just television.

> [!warning] Check the angle mode
> This course thinks in radians, and Desmos should too. Graph
> $y = \sin x$ alongside $\frac{d}{dx}\sin x$ — the derivative curve
> should be $\cos x$ exactly, peaking at 1. If it comes out crushed
> nearly flat, something is measuring in degrees, and every
> sinusoidal derivative it touches will be wrong by a factor nobody
> ordered.

## A function and its derivative, stacked

Desmos will graph $f'(x)$ if you simply type it. Put $f(x) = x^3 - 3x$
in one line and $f'(x)$ in the next, then interrogate the pair:
where the original peaks, its derivative should cross zero heading
down; where the original bottoms out, the derivative crosses zero
heading up; where the original falls, the derivative should be
underwater. Every claim in [[Curve Sketching]] can be
cross-examined this way — and when the two graphs surprise you, you
have found the exact edge of your understanding.

## When your head is faster

Desmos shines when the question is about *shape and behaviour*: a
family of cubics under a slider, a descent profile against its
acceleration, a conjectured derivative checked against the built-in
one in ten seconds. It is slower than your head for the power rule,
for the dot product of $\langle 3, 4 \rangle$ and
$\langle 5, 0 \rangle$, for reading where a sign chart changes, and
for everything [[Estimation Duels]] trains. Reaching for a tool you
do not need is its own kind of slow — the skill is knowing which
moment you are in.
