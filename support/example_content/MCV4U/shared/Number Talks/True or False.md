---
title: True or False
draft: false
created: __CREATED__
tags:
  - number-talks
---
One algebraic claim on the board — say, *the derivative of a product
is the product of the derivatives* — and one job: put it on trial.
Is it ever true? Always true? An equation is not a fact just because
it is written down; it is a claim about functions now, not just
numbers, and claims earn their verdicts in court. The stakes are
real: this particular claim feels so natural that some part of every
class believes it, quietly, until the trial.

## How we play

1. Vote first — true, false, or "it depends" — before any working.
2. Prosecute and defend: test functions, rewrite, sketch, whatever bites.
3. Deliver a verdict with evidence: *always*, *never*, or *exactly when*.

> [!example]- The trial of $(fg)' = f' \cdot g'$
> - "Try $f(x) = x^2$ and $g(x) = x^3$. The product is $x^5$, whose
>   derivative is $5x^4$. The product of the derivatives is
>   $2x \cdot 3x^2 = 6x^3$. At $x = 0$ both come out to 0 — looks
>   true."
> - "Try $x = 1$: the left side gives 5, the right side gives 6.
>   False."
> - "Graph both: $5x^4$ and $6x^3$ are different shapes entirely —
>   they cross at exactly two points and disagree everywhere else."
> - Verdict: false — true only at scattered points, never as a rule.
>   And the *reason* is worth the trial: when $f$ and $g$ both grow,
>   the product grows for two reasons at once — each factor's growth
>   gets scaled by the *other factor's size*. The honest relation is
>   $(fg)' = f'g + fg'$, each term one of the two reasons, and it
>   comes from [[Derivative Rules]]. Check it on the evidence:
>   $2x \cdot x^3 + x^2 \cdot 3x^2 = 5x^4$. Exactly right.

## One variation

Claims that *sound* like the same trap but are not: "the derivative
of a sum is the sum of the derivatives." Every test passes — and
this one is *always* true, for any two differentiable functions.
Sums split and products do not, and saying *why* the two claims meet
different fates is worth more than either verdict. One more for the
docket: "the derivative of $\sin x$ is $\cos x$." Always — but only
because this course measures angles in radians, a fine-print clause
[[Derivatives of Sinusoidal Functions]] reads aloud.

> [!tip] One witness is not a proof
> A single counter-example kills an "always" — $x = 1$ ended the
> trial above. A single confirming example proves nothing: $x = 0$
> testified for the claim and the claim was still false. To speak
> about *all* functions you need a reason, not a coincidence — and
> testing a value you were not given is [[Checking Your Own Work]]
> wearing a courtroom robe.
