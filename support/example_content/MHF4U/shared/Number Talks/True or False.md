---
title: True or False
publish: true
created: __CREATED__
tags:
  - number-talks
---
One algebraic claim on the board — say, $\sin 2x = 2 \sin x$ — and
one job: put it on trial. Is it ever true? Always true? An equation
is not a fact just because it is written down; it is a claim about
numbers, and claims earn their verdicts in court. In Grade 12 the
stakes rise: a claim that survives every test is called an identity,
and identities must be *argued*, not voted on.

## How we play

1. Vote first — true, false, or "it depends" — before any working.
2. Prosecute and defend: test values, rewrite, sketch, whatever bites.
3. Deliver a verdict with evidence: *always*, *never*, or *exactly when*.

> [!example]- The trial of $\sin 2x = 2 \sin x$
> - "Try $x = 0$: both sides are 0. Looks true."
> - "Try $x = \frac{\pi}{6}$: the left side is
>   $\sin\frac{\pi}{3} = \frac{\sqrt{3}}{2}$, but the right side is
>   $2 \cdot \frac{1}{2} = 1$. False."
> - "Graph both: the left is a wave squeezed to half the period; the
>   right is a wave stretched to twice the height. They only meet
>   where both are zero."
> - Verdict: true exactly when $x$ is a multiple of $\pi$. Doubling
>   the *angle* is not doubling the *height* — the honest relation
>   is $\sin 2x = 2 \sin x \cos x$, and it comes from
>   [[Compound Angles]].

## One variation

Claims that *sound* too good to be true: "$(x - 2)$ is a factor of
$x^3 - x^2 - x - 2$ exactly when substituting $x = 2$ gives zero."
It does give zero — and the claim is *always* true, for any
polynomial and any number. That a single substitution can certify a
factor is the astonishment [[The Factor Theorem]] stages on purpose.

> [!tip] One witness is not a proof
> A single counter-example kills an "always" — $x = \frac{\pi}{6}$
> ended the trial above. A single confirming example proves nothing:
> $x = 0$ testified for the claim and the claim was still false. To
> speak about *all* numbers you need algebra or a graph — the
> standard [[Trigonometric Identities]] holds every proof to, and
> testing a value you were not given is [[Checking Your Own Work]]
> wearing a courtroom robe.
