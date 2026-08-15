---
title: The Chain Rule
publish: true
created: __CREATED__
tags:
  - concepts
---
The [[Number Strings]] warm-up put two machines in a row: triple a
number, then add one; square a number, then take the result's square
root. Composed machines were old friends from Grade 12 functions —
the new question is what happens to *rates* when machines feed each
other. If the inner machine is running at 3 units per second and the
outer machine multiplies whatever it receives by 5, the whole
assembly line runs at 15. Rates through a chain *multiply*.

$$\text{If } f(x) = g(u(x)), \text{ then } f'(x) = g'(u(x)) \cdot u'(x)$$

Differentiate the outside, leave the inside alone, then multiply by
the derivative of the inside. The last step — multiply by the inside
— is the one every calculus student on Earth forgets exactly once.

## Where your group found it

Nobody stated this rule first either. At the boards you took the
product rule to the family $f(x) = (x^2 + 1)^2$, then
$(x^2 + 1)^3$, then $(x^2 + 1)^4$, and the pattern stepped forward
on its own: each derivative was the old exponent, times the bracket
with the exponent knocked down one, times $2x$ — the derivative of
the inside, tagging along every single time.

> [!example] The rule in one worked line
> For $f(x) = (x^2 + 1)^3$: the outside is a cube, the inside is
> $x^2 + 1$.
>
> $$f'(x) = 3(x^2 + 1)^2 \cdot 2x = 6x(x^2 + 1)^2$$
>
> The $3(x^2+1)^2$ is the power rule holding the inside still; the
> $2x$ is the inside reporting its own rate. Omit the $2x$ and you
> have differentiated a different function — one where the inside
> never moves.

## The disguise-piercing rule

The chain rule matters beyond brackets-to-a-power, because it turns
two whole families of functions into things you can already handle.
A rational function is a product wearing a disguise:
$\frac{x^2 + 1}{x - 1} = (x^2 + 1)(x - 1)^{-1}$, and that $-1$
exponent needs the chain rule the moment you differentiate it. A
radical is a power in disguise:
$\sqrt{x^2 + 5} = (x^2 + 5)^{1/2}$. Between the product rule and the
chain rule, every function this course names — polynomial,
sinusoidal, exponential, rational, radical, and their combinations —
is differentiable by hand. That is the whole toolbox, complete.

The verification habit continues to pay: differentiate
$f(x) = (5x^3)^{1/3}$ by the chain rule, then simplify it first to
$5^{1/3}x$ and differentiate that — both roads give $5^{1/3}$.
When two methods agree, you built the confidence yourself.
[[Chain Rule Practice]] has the full range of disguises, and
[[Derivative Rules]] is the page underneath this one.

%%curriculum-start%%
## Curriculum connection

![[A3.4]]

![[A3.5]]
%%curriculum-end%%
