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

## Sliders on a factored form

Type $y = a(x - b)^2(x - c)$ and Desmos offers to make $a$, $b$, and
$c$ adjustable. Before you drag anything, **predict aloud**: what
will the graph do at $x = b$, where the factor is squared? Which way
do both arms swing when $a$ goes negative? Then slide, and watch the
graph agree or object. Two minutes of sliding builds the intuition
behind [[Zeros and Multiplicity]] faster than an hour of
hand-plotting — and when the graph surprises you (the bounce at the
squared factor surprises everyone the first time), you have found
the exact edge of your understanding. Prediction first is what keeps
Desmos a thinking tool; sliding without predicting is just
television.

> [!warning] Check the angle mode
> This course thinks in radians, and Desmos should too. Graph
> $y = \sin x$ and look at where the first peak lands: near $1.57$
> — that is $\frac{\pi}{2}$, and all is well. If your calculator and
> your graph ever disagree about the same sine, one of them is
> quietly working in degrees.

## A table of data and a candidate curve

Paste in a table — hours and drug concentrations, and the points
appear on screen. Now type your candidate model over top and tune
its parameters *by hand* until the curve deserves the data:
asymptote first, because it is the one feature the situation
guarantees, then the rest. Hand-tuning is the entire modelling loop
of [[Safe Concentration]] run at high speed — and every parameter
you adjust asks you what that knob *means*, which is the standard
[[What Makes a Model Good]] holds models to.

## When your head is faster

Desmos shines when the question is about *shape and behaviour*:
families of polynomials, a rational function against its asymptotes,
a conjectured identity checked on ten inputs in ten seconds. It is
slower than your head for the exact values of [[The Unit Circle]],
for $\log_2 32$, for reading end behaviour off a leading term, and
for everything [[Estimation Duels]] trains. Reaching for a tool you
do not need is its own kind of slow — the skill is knowing which
moment you are in.
