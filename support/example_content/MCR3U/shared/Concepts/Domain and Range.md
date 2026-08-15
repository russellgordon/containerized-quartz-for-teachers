---
title: Domain and Range
publish: true
created: __CREATED__
tags:
  - concepts
---
When your group graphed the thrown-ball function at the boards,
someone asked the question this page answers: "wait — are we allowed
to plug in $t = -3$?" The *domain* of a function is the set of inputs
it accepts; the *range* is the set of outputs it can produce. Every
function drags both sets around with it, and stating them is part of
describing the function.

## The four parents

| Function | Domain | Range |
| --- | --- | --- |
| $f(x) = x$ | all real numbers | all real numbers |
| $f(x) = x^2$ | all real numbers | $y \ge 0$ |
| $f(x) = \sqrt{x}$ | $x \ge 0$ | $y \ge 0$ |
| $f(x) = \dfrac{1}{x}$ | $x \ne 0$ | $y \ne 0$ |

Each restriction has a reason you can say out loud: a square is never
negative; a square root refuses negative inputs; division by zero has
no meaning, and $\frac{1}{x}$ can never actually *be* zero. Say the
reason, not just the rule — the reason survives in your memory long
after the rule fades.

Domain and range travel with the graph under
[[Transformations of Functions|transformations]]. Slide
$f(x) = \sqrt{x}$ right 4 to get $g(x) = \sqrt{x - 4}$ and the domain
slides too: $x \ge 4$. Lift $y = x^2$ by 1 and the range lifts:
$y \ge 1$. If you can sketch the image, you can read both sets
straight off it — [[Using Desmos]] makes the check instant.

## When context narrows the view

Algebra is generous; reality is not. The height of a thrown ball,
$h(t) = -5t^2 + 20t$, is algebraically happy with any real $t$ — but
the throw starts at $t = 0$ and the ball lands at $t = 4$, so the
model's domain is $0 \le t \le 4$ and its range is $0 \le h \le 20$.
A cost function for concert tickets only accepts whole numbers of
tickets. Whenever a function models something, finish the sentence:
"…and the context restricts the domain to —." Many of our
[[Graph Talks]] hinge on exactly that finishing move.

[[Domain and Range Practice]] runs you through both jobs: reading the
sets from equations, and letting a context shrink them.

%%curriculum-start%%
## Curriculum connection

![[A1.3]]

![[A1.9]]
%%curriculum-end%%
