---
title: Derivatives from First Principles
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Every rule in [[Derivative Rules]] came from one calculation, done once,
carefully. Doing it yourself is what makes the rules something you
understand rather than something you were handed — and it is the only
place where the derivative's *definition* is visible.

## The quotient before the limit

Take two points on a curve, $x$ and $x + h$. The slope of the line
through them is rise over run:

$$\frac{f(x + h) - f(x)}{h}$$

That is an average rate of change over an interval of width $h$ — a
**secant** slope, and completely ordinary. The whole of calculus is what
happens when $h$ shrinks.

## The definition

$$f'(x) = \lim_{h \to 0} \frac{f(x + h) - f(x)}{h}$$

Read it as an instruction: build the quotient, simplify until the $h$ in
the denominator cancels, and only then let $h$ go to zero. The order
matters. Substituting $h = 0$ first gives $\tfrac{0}{0}$, which is not a
number and not an answer.

## Doing it, slowly

For $f(x) = x^2$:

$$\frac{f(x+h) - f(x)}{h} = \frac{(x+h)^2 - x^2}{h} = \frac{x^2 + 2xh + h^2 - x^2}{h} = \frac{2xh + h^2}{h}$$

Every term still has an $h$, so the fraction simplifies:

$$\frac{h(2x + h)}{h} = 2x + h \qquad (h \neq 0)$$

Now the limit is safe, because nothing is dividing by zero any more:

$$f'(x) = \lim_{h \to 0}\,(2x + h) = 2x$$

That is the power rule for $n = 2$, derived rather than asserted. Do
$f(x) = x^3$ the same way and $3x^2$ falls out; the pattern is visible
after two or three, which is exactly how the rule was found.

| Step | What you are doing | The trap |
| --- | --- | --- |
| Expand | Substitute and expand fully | Forgetting a middle term of the binomial |
| Cancel | Subtract $f(x)$; every remaining term has $h$ | Cancelling before subtracting |
| Divide | Factor $h$ out and cancel it | Writing $h = 0$ at this stage |
| Take the limit | Let $h \to 0$ in what remains | Stopping before this step |

## Positive, negative, and zero — read off the numbers

Before any algebra, a table of values tells you most of what a
derivative is for. Compute the average rate of change over short
intervals across a function's domain and watch the sign:

- **Positive** intervals: the function is increasing there.
- **Negative** intervals: it is decreasing.
- **Zero**, or a sign change: a maximum, a minimum, or a moment of
  levelling off.

Build that table in [[Using Desmos]] or a spreadsheet for a cubic, with
$h = 0.001$, and plot the results against $x$. What appears is the graph
of the derivative — discovered numerically, before you can compute it
symbolically. [[The Slope Detective]] is that investigation in full, and
it is why the shape of $f'$ feels familiar by the time you meet it
algebraically.

> [!question]- Why bother, once you know the rules?
> Three reasons. It is the definition, so every proof of every rule
> starts here. It is what a computer does when no rule applies —
> numerical differentiation is this quotient with a small fixed $h$. And
> when a question asks you to differentiate something the rules do not
> cover, first principles is the method that always works, slowly.

%%curriculum-start%%
## Curriculum connection

![[A2.3]]

![[A2.1]]

![[A2.2]]
%%curriculum-end%%
