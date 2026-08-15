---
title: The Limit
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
At the boards in [[How Fast Right Now?]], your group computed average
speeds over shrinking intervals and watched the answers march: $7$,
$6.1$, $6.01$, $6.001$ — each one closer to something, none of them
ever arriving. Then someone in your group said the sentence every
group eventually says: "it's *obviously* going to 6." The limit is
mathematics agreeing with that sentence, and giving it a notation:

$$\lim_{h \to 0} \frac{f(3+h) - f(3)}{h} = 6$$

## Naming the destination

A limit is the value a quantity *approaches*, whether or not it ever
gets there. That last clause is the whole idea. No secant your group
drew had slope exactly 6 — every one of them needed two separate
points, and two separate points always leave a gap $h$ between them.
The limit is not the best secant. It is the destination the secants
agree on, and it is exactly where [[Zooming In]] was pointing when
the curve started looking like a straight line under magnification.

> [!question]- Self-check: no secant has slope 6 — so where does the
> 6 come from? (click to expand)
> From the *pattern*, not from any single measurement. Each secant
> slope is $6 + h$ for its own small $h$, and the numbers $6.1$,
> $6.01$, $6.001$ leave no doubt about where that pattern is headed
> as $h$ shrinks. The limit is the one value the slopes crowd around
> — every smaller $h$ lands you closer to 6, and nothing else has
> that property.

## Two roads to the same limit

Your group found this limit twice, and the two routes matter.

The first road is numeric: substitute $h = 1$, $h = 0.1$, $h = 0.01$
into $\frac{(3+h)^2 - 9}{h}$ and watch the outputs settle. Honest,
slow, and convincing.

The second road is algebraic: simplify *first*.

$$\frac{(3+h)^2 - 9}{h} = \frac{6h + h^2}{h} = 6 + h$$

Now the destination is visible without a single substitution — as
$h \to 0$, the expression $6 + h$ heads straight for 6. The algebra
did not change the answer; it changed how clearly you could see it.
When a limit resists you later in the course, this is the move:
simplify until the destination shows itself.

## Limits in the wild

Limits were hiding in your mathematical life before this week. The
sequence $\left(1 + \frac{1}{n}\right)^n$ creeps toward a number near
$2.718$ that will matter enormously in
[[Derivatives of Exponential Functions|a few weeks]]. The ratio of
each Fibonacci number to the one before it settles toward the golden
ratio, about $1.618$. A graph sliding along an asymptote is a limit
drawn in ink. None of these processes *finishes* — and the limit is
how we speak precisely about where each one is going anyway.

[[The Derivative]] builds this idea into a definition, and
[[Limits Practice]] makes the two roads a reflex. Take the numeric
road first, every time — the estimate audits the algebra.

%%curriculum-start%%
## Curriculum connection

![[A1.3]]

![[A1.4]]

![[A1.5]]

![[A1.6]]
%%curriculum-end%%
