---
title: Derivative Rules
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
You came to class carrying a conjecture. [[The Derivative]] ended by
asking what $f(x) = x^{17}$ would do, and in the [[Visual Patterns]]
warm-up your group lined up the evidence: $x^2$ gives $2x$, $x^3$
gives $3x^2$, $x^4$ gives $4x^3$. The exponent hops down front; the
new exponent is one less. Nobody handed you the power rule — you
caught it in the act.

$$\text{If } f(x) = x^n, \text{ then } f'(x) = nx^{n-1}$$

The definition proved it for each case your group checked, one limit
at a time. The rule is the pattern with a certificate.

## The toolbox

| Rule | Statement | What it lets you do |
| --- | --- | --- |
| Power | $(x^n)' = nx^{n-1}$ | any power, even $x^{1/2}$ |
| Constant | $(c)' = 0$ | flat graphs have slope zero |
| Constant multiple | $(cf)' = cf'$ | scale factors ride along |
| Sum and difference | $(f \pm g)' = f' \pm g'$ | one term at a time |

The last three are the reasonable rules — the ones the water-barrel
argument in class made obvious. If $f(t)$ and $g(t)$ are litres in
two barrels, then $f'(t) + g'(t)$ is how fast the *total* is rising,
and of course that equals $(f + g)'(t)$. Together the four rules
dismantle any polynomial: $f(x) = 2x^3 + 3x^2$ surrenders term by
term to $f'(x) = 6x^2 + 6x$, no limits required.

One caution worth writing in your [[Math Journal]]: the power rule
also handles rational exponents, so $f(x) = \sqrt{x} = x^{1/2}$ gives
$f'(x) = \frac{1}{2}x^{-1/2}$ — the rule is broader than the natural
numbers you conjectured it from, and that generosity gets verified,
not assumed.

## Products refuse to cooperate

At the boards your group tested the tempting guess — that the
derivative of a product is the product of the derivatives — and it
failed on the very first example. It is a good mistake; treat it as
data. The rule that actually works keeps both factors in play:

$$(fg)' = f'g + fg'$$

Each factor takes a turn changing while the other holds still. For
$f(x) = (3x + 2)(2x^2 - 1)$:

$$f'(x) = 3(2x^2 - 1) + (3x + 2)(4x) = 18x^2 + 8x - 3$$

Expand first instead and differentiate $6x^3 + 4x^2 - 3x - 2$ — the
same $18x^2 + 8x - 3$ appears. Two roads, one answer: that agreement
is the verification the course keeps asking for.

## Shortcuts remember; you understand

The rules are shortcuts, and shortcuts are earned. Every one of them
compresses a limit computation you have done by hand, and when a rule
ever feels like magic, the definition is one page away. Where slopes
are wanted on demand — a tangent line here, a rate there — the
toolbox delivers them in seconds, and [[Derivative Rules Practice]]
builds that speed honestly, without worshipping it. Functions hiding
*inside* other functions need one more idea: [[The Chain Rule]].

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.2]]

![[A3.3]]

![[A3.4]]
%%curriculum-end%%
