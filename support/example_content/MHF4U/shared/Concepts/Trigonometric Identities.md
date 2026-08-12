---
title: Trigonometric Identities
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[The Two Waves]], two groups modelled the same sound with
different-looking equations — and Desmos drew one curve for both. A
[[True or False]] round sharpened the question: when are two
expressions *the same function* in disguise, and how would you ever
know for certain? A graph is evidence; this page is about proof.

## What an identity claims

An **identity** is an equation that holds for *every* value in the
domain — not an equation to solve, but a claim about all inputs at
once. That makes the two possible verdicts wildly asymmetric. To
show something is *not* an identity, one counter-example ends the
conversation. To show it *is* one, no number of confirming examples
suffices — a million checks leave infinitely many unchecked — so only
a general argument will do. Graphing both sides is the right first
move: it tells you which verdict to pursue. It just cannot deliver
the second one.

## Proving one

Your toolkit: the quotient identity
$\tan x = \frac{\sin x}{\cos x}$, the Pythagorean identity
$\sin^2 x + \cos^2 x = 1$, the reciprocal identities, and the
[[Compound Angles|compound angle formulas]]. The discipline matters
as much as the tools — an identity proof is an argument, and
arguments have rules:

- [ ] Work on one side at a time. Never operate across the equals
      sign — that assumes the thing you are proving.
- [ ] Start from the messier side; simplifying is easier than
      complicating on purpose.
- [ ] When stuck, translate everything into $\sin$ and $\cos$ —
      the common language.
- [ ] Factor before you expand; $1 - \cos^2 x$ wants to be
      $\sin^2 x$.
- [ ] Note any values excluded from the domain — an identity with a
      $\tan x$ in it says nothing at $x = \frac{\pi}{2}$.

A proof that dead-ends is data: it usually means the fruitful first
move was on the other side.

## Equations are a different job

$2\sin x + 1 = 0$ is not an identity and never claimed to be — it is
true for some inputs, and your job is to find all of them in
$0 \le x \le 2\pi$. The unit circle does the honest work: sine is
$-\frac{1}{2}$ at reference angle $\frac{\pi}{6}$ in the third and
fourth quadrants, so $x = \frac{7\pi}{6}$ or $\frac{11\pi}{6}$.
Quadratic trigonometric equations factor like the quadratics they
are — treat $\sin x$ as the variable, factor, then send each piece
back to the circle. Expect a *list* of answers, and let the graph
confirm the count.

[[Identities and Equations Practice]] holds both jobs side by side,
because telling them apart is half the skill.

%%curriculum-start%%
## Curriculum connection

![[B3.1]]

![[B3.3]]

![[B3.4]]
%%curriculum-end%%
