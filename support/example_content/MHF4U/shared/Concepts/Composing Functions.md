---
title: Composing Functions
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Adding, subtracting, multiplying, and dividing functions gives you a new
function built from two old ones. **Composition** is different: it feeds
one function's output into the other's input, and it is the operation
that explains what a transformation actually is.

## The notation, and the order

$$(f \circ g)(x) = f\bigl(g(x)\bigr)$$

Inside first. $g$ acts on $x$, and $f$ acts on whatever $g$ produced.
The order matters and reversing it usually changes the answer:

With $f(x) = x^2$ and $g(x) = x + 3$:

$$(f \circ g)(x) = (x+3)^2 \qquad\text{but}\qquad (g \circ f)(x) = x^2 + 3$$

Those are different functions with different graphs. "Square then add
three" and "add three then square" are different instructions, which is
obvious in words and easy to lose in symbols.

## The domain question

A composition's domain is smaller than you expect, because a value has
to survive *both* steps: it must be in $g$'s domain, and $g(x)$ must
then be in $f$'s domain.

With $f(x) = \sqrt{x}$ and $g(x) = x - 5$, the composition
$f(g(x)) = \sqrt{x-5}$ needs $x \ge 5$ — even though $g$ alone accepts
every real number. The restriction came from the second step and applies
to the first.

## Composition in the world

Real situations compose constantly, and naming the two functions is most
of the work:

- Cost depends on quantity; quantity depends on time. Cost as a function
  of time is a composition.
- A currency conversion applied to a price already including tax.
- Temperature depends on altitude; altitude depends on time in a climb.

The habit that makes these tractable: write both functions separately,
with their units, *before* composing. `cost(quantity)` and
`quantity(time)` compose in only one sensible order, and the units say
which.

## Why transformations are compositions

This is the connection worth carrying:

$$y = f(x - 3) \quad\text{is}\quad f \circ g \;\text{ where } g(x) = x - 3$$

Every horizontal transformation is a composition with a simple linear
function on the inside, and every vertical one is a composition on the
outside. That is why the inside works "backwards" — $x - 3$ shifts the
graph *right* — which is otherwise an arbitrary rule students memorise
and misremember. It is not arbitrary: to get the same output the inner
function needed a larger input, so the graph moved right.

> [!tip] Checking a composition
> Evaluate at one number both ways. If $f(g(2))$ and your simplified
> expression disagree at $x = 2$, the algebra is wrong and you have
> found it in ten seconds rather than at the end of the question.

[[Combining Functions]] covers the arithmetic operations; the two ideas
meet whenever a problem asks you to build one function out of several.

%%curriculum-start%%
## Curriculum connection

![[D2.6]]

![[D2.8]]
%%curriculum-end%%
