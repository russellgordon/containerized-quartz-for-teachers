---
title: The Logarithm
publish: true
created: __CREATED__
tags:
  - concepts
---
At the boards, your group tried to undo $y = 2^x$ — and got stuck in
an honest way. Undoing $y = x^3$ was easy: take the cube root. But
"what power of 2 gives 10?" has no button you already own. You could
*bracket* it (between 3 and 4, closer to 3.3), you could read it off
a graph, but you could not *name* it. The logarithm is that name.

$$\log_b x = y \quad\text{means}\quad b^y = x$$

A logarithm is not a new kind of number — it is a new *question*
about old numbers. $\log_2 10$ asks "2 to what power makes 10?", and
the answer was always sitting on the exponential graph; the logarithm
just reads the graph sideways.

## The inverse, literally

The logarithm is the inverse of the exponential — the Grade 11 idea
you rebuilt at the boards in [[Undoing the Exponential]], now doing
real work. Everything you
know about inverses applies:

- The graph of $y = \log_b x$ is $y = b^x$ reflected in the line
  $y = x$.
- Inputs and outputs trade jobs: the exponential's range (positive
  reals) becomes the logarithm's *domain* — which is why
  $\log_b(-3)$ is not a thing.
- Each undoes the other: $\log_b(b^x) = x$ and $b^{\log_b x} = x$.

> [!question]- Self-check: why does $y = \log_b x$ have a vertical
> asymptote at $x = 0$? (click to expand)
> Because $y = b^x$ has a *horizontal* asymptote at $y = 0$ — the
> reflection in $y = x$ turns horizontal into vertical. The
> exponential never quite reaches height zero, so the logarithm
> never quite reaches input zero.

## Reading log scales

Logarithms earn their keep wherever quantities span many sizes at
once. The Richter scale, decibels, and pH are all logarithms wearing
uniforms: one step on the scale means one *factor* in the quantity.
A magnitude 7 earthquake is not "a bit worse" than a magnitude 5 —
it is $10^2 = 100$ times the amplitude. When a scale hides a
multiplication inside an addition, there is a logarithm underneath.

Estimating without a calculator is a respectable skill here:
$\log_{10} 500$ lives between 2 and 3, and closer to 3 — defend that
sentence and you understand the definition. The
[[Laws of Logarithms]] turn that estimating instinct into algebra,
and [[Logarithm Practice]] makes both a reflex.

%%curriculum-start%%
## Curriculum connection

![[A1.1]]

![[A1.2]]

![[A2.2]]
%%curriculum-end%%
