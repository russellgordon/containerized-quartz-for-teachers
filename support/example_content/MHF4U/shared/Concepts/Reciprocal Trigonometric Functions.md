---
title: Reciprocal Trigonometric Functions
publish: true
created: __CREATED__
tags:
  - concepts
---
When your group graphed $y = \frac{1}{\sin x}$, someone said "we did
this exact move to polynomials" — and that was the whole lesson
arriving early. The choreography from [[The Reciprocal]] carries over
untouched: where $\sin x$ crosses zero, its reciprocal blows up; where
$\sin x$ peaks at 1, its reciprocal bottoms out at 1. Only the names
are new.

## Three new names, one old move

$$\csc x = \frac{1}{\sin x} \qquad \sec x = \frac{1}{\cos x} \qquad \cot x = \frac{1}{\tan x}$$

Cosecant, secant, cotangent — the reciprocals of sine, cosine, and
tangent. Their exact values at special angles cost nothing new: flip
the value you already own, so $\csc\frac{\pi}{4} = \sqrt{2}$ and
$\sec\frac{\pi}{6} = \frac{2\sqrt{3}}{3}$. Your calculator has no
buttons for them, deliberately — evaluate the primary ratio and take
the reciprocal, which keeps the definition in your hands.

> [!warning] The notation trap
> $\csc x$ can be written $\frac{1}{\sin x}$ — but **never**
> $\sin^{-1} x$. That superscript is reserved for the *inverse*
> function, the one that answers "which angle has this sine?"
> Reciprocal flips the output; inverse reverses the whole machine.
> The notation is genuinely inconsistent — $\sin^2 x$ does mean
> $(\sin x)^2$ — and the inconsistency is the exam question.

## Reading the graphs

Sketch the parent lightly, then let the reciprocal answer to it:

- Vertical asymptotes wherever the parent is zero — so $\csc x$ has
  asymptotes at $0, \pi, 2\pi, \ldots$, and its domain excludes them.
- Where the parent is $\pm 1$, the two graphs touch — the only points
  they share.
- The reciprocal keeps the parent's sign and its period, so $\csc x$
  and $\sec x$ repeat every $2\pi$, while $\cot x$, like $\tan x$,
  repeats every $\pi$.
- Range flips inside out: the parent's $-1 \le y \le 1$ becomes
  $y \le -1$ or $y \ge 1$.

Sketch $\csc x$ from $\sin x$ once at the boards and the graph stops
being a memorised shape — it becomes a consequence. A few questions
in [[Radian Measure Practice]] keep the exact values honest, and
[[Trigonometric Identities]] puts all six ratios to work at once.

%%curriculum-start%%
## Curriculum connection

![[B1.3]]

![[B1.4]]

![[B2.3]]
%%curriculum-end%%
