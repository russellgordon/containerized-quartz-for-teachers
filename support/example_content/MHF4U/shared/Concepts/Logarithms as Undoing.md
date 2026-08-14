---
title: Logarithms as Undoing
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
A logarithm answers one question: **what exponent do I need?** Once that
sentence is in place, most logarithm work becomes translation rather
than technique.

## The two forms are the same statement

$$\log_b(x) = y \iff b^y = x$$

$\log_5 125 = 3$ and $5^3 = 125$ say exactly the same thing. Reading a
logarithm aloud as "the exponent that turns 5 into 125" makes the
translation automatic, and it makes evaluation possible without a
calculator:

| Logarithmic form | Exponential form | Read as |
| --- | --- | --- |
| $\log_2 16 = 4$ | $2^4 = 16$ | The exponent turning 2 into 16 |
| $\log_{10} 0.001 = -3$ | $10^{-3} = 0.001$ | Negative, because the result is below 1 |
| $\log_9 3 = \tfrac{1}{2}$ | $9^{1/2} = 3$ | Fractional, because it is a root |
| $\log_b 1 = 0$ | $b^0 = 1$ | Always, for any base |

Two facts follow immediately and are worth stating. The argument of a
logarithm must be **positive**, because no exponent turns a positive
base into a negative number or into zero. And $\log_b b = 1$ for every
base, which is the identity every simplification eventually leans on.

## Evaluating without technology

Ask "what power of the base is this?" and work in whole steps:

$$\log_4 64 : \quad 4^1 = 4,\; 4^2 = 16,\; 4^3 = 64 \;\Rightarrow\; \log_4 64 = 3$$

When the answer is not a whole number, express the argument as a power
of the base first: $\log_8 2$ becomes $\log_8 8^{1/3} = \tfrac{1}{3}$.
This is the skill an examination tests, because it shows you understand
the definition rather than owning a calculator.

## Transforming a logarithmic function

$y = \log_{10} x$ has a vertical asymptote at $x = 0$, passes through
$(1, 0)$, and grows without ever stopping — slowly. The parameters do
what they do everywhere else:

$$y = a\log_{10}\bigl(k(x - d)\bigr) + c$$

with one difference worth watching: **$d$ moves the asymptote**, to
$x = d$. That mirrors the exponential case, where $c$ moved the
horizontal asymptote — which is not a coincidence, since the two
functions are inverses and their graphs are reflections in $y = x$.

Predict each of these before graphing, then check in [[Using Desmos]]:

$$y = \log_{10}(x - 3) \qquad y = 2\log_{10} x \qquad y = \log_{10} x + 4 \qquad y = \log_{10}(-x)$$

The last one is the interesting case: reflecting in the $y$-axis moves
the whole curve to the negative side, where the domain becomes $x < 0$.
A domain that moves is the signature of a horizontal transformation on
a logarithm.

> [!question]- Why does the graph grow so slowly?
> Because its inverse grows so fast. $10^x$ reaches a million by $x = 6$;
> therefore $\log_{10}$ of a million is only 6. Every property of the
> logarithm is a property of the exponential seen from the side — which
> is why [[The Logarithm]] and [[Laws of Logarithms]] can be derived
> from the exponent laws rather than memorised separately.

%%curriculum-start%%
## Curriculum connection

![[A1.3]]

![[A2.1]]

![[A2.3]]
%%curriculum-end%%
