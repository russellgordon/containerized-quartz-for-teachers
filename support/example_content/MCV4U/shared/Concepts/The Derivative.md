---
title: The Derivative
draft: false
created: __CREATED__
tags:
  - concepts
---
For six classes you have been sneaking up on an instant. Average speed
over a minute, over a second, over a tenth of a second — each secant a
little more honest than the last, and at the boards in
[[How Fast Right Now?]] your group watched the numbers settle toward
one value they never quite reached. [[The Limit]] gave that value a
name. The derivative is what you get when you build the whole idea
into one definition:

$$f'(a) = \lim_{h \to 0} \frac{f(a+h) - f(a)}{h}$$

Read it slowly, because every piece is something you did with your
hands: $\frac{f(a+h) - f(a)}{h}$ is the slope of a secant from $a$ to
a nearby point; $h \to 0$ marches the nearby point home; the limit is
the value the march settles on. The derivative of $f$ at $a$ is the
slope of the tangent there — the speed *right now*, not over any
interval at all.

## One number, three costumes

| Costume | What $f'(a)$ is | Where you meet it |
| --- | --- | --- |
| Geometric | Slope of the tangent at $(a, f(a))$ | [[Curve Sketching]] |
| Physical | Instantaneous rate of change — velocity, growth, flow | [[Motion on a Line]] |
| Algebraic | The limit of difference quotients | [[Limits Practice]] |

The costumes matter because problems arrive wearing them. A question
about a tangent line, a question about a falling stone, and a question
about a shrinking limit are the *same question*, and the mark of
fluency in this course is hearing that.

## From a point to a function

Compute $f'(a)$ at enough points and a pattern appears — the slopes
themselves form a function, $f'(x)$, the derivative function. For
$f(x) = x^2$ the definition gives, at any $x$:

$$\begin{aligned} f'(x) &= \lim_{h \to 0} \frac{(x+h)^2 - x^2}{h} \\ &= \lim_{h \to 0} \frac{2xh + h^2}{h} \\ &= \lim_{h \to 0} (2x + h) = 2x \end{aligned}$$

- [ ] Check that against your group's secant tables from
      [[Zooming In]]: at $x = 3$, were the slopes settling near 6?
- [ ] Try the same three-line computation for $f(x) = x^3$.
- [ ] Conjecture what $f(x) = x^{17}$ will do — then bring your
      conjecture to class, where the [[Derivative Rules|toolbox]]
      starts from exactly this pattern.

One honest warning: the definition is the *meaning*, and the rules
that follow are the *shortcuts*. When a problem confuses you later in
the course, come back here — the definition never does.

%%curriculum-start%%
## Curriculum connection

![[A2.1]]

![[A2.2]]
%%curriculum-end%%
