---
title: Laws of Logarithms
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The [[Number Strings]] round went $\log 2$, $\log 4$, $\log 8$,
$\log 32$ — and the conjecture surfaced halfway through: the answers
were climbing by *equal steps* while the inputs *multiplied*. That
trade — multiplication downstairs becomes addition upstairs — is the
entire content of the laws of logarithms, and it is inherited
property, not new law.

## Exponent laws in disguise

A logarithm is an exponent — that was the whole point of
[[The Logarithm]] — so every law of exponents translates directly
into a law of logarithms:

| You already knew                | So it follows that                              |
| ------------------------------- | ----------------------------------------------- |
| $b^m \cdot b^n = b^{m+n}$        | $\log_b(xy) = \log_b x + \log_b y$              |
| $b^m \div b^n = b^{m-n}$         | $\log_b\!\frac{x}{y} = \log_b x - \log_b y$     |
| $(b^m)^n = b^{mn}$               | $\log_b(x^n) = n\log_b x$                       |

Take the first row: if $x = b^m$ and $y = b^n$, then $xy = b^{m+n}$,
so the exponent belonging to $xy$ is the sum of the exponents
belonging to $x$ and $y$. That is the product law, proved in one
breath. Verify it numerically until it feels inevitable —
$\log_{10}1000 - \log_{10}100 = 3 - 2 = 1 = \log_{10}10$ fits the
quotient law exactly.

## Simplifying and evaluating

The laws collapse expressions no calculator button handles directly:
$\log_{10}4 + \log_{10}25 = \log_{10}100 = 2$, and
$\log_2 48 - \log_2 3 = \log_2 16 = 4$. They also expose equivalent
functions wearing different clothes — $\log_{10}(100x)$ *is*
$2 + \log_{10}x$, which is why their graphs are the same curve, one
shifted up two. When an expression resists, rewrite it so the laws
apply; when it still resists, estimate — $\log_3 29$ sits just past
3, since $3^3 = 27$ — and let the estimate audit whatever the algebra
produces.

## Solving equations

Exponential equations offer two honest routes. If both sides can wear
a common base, match exponents: $9^x = 27^{x-1}$ becomes
$3^{2x} = 3^{3x-3}$, so $x = 3$. If no common base exists, take a
logarithm of both sides and let the power law pull the unknown down
out of the exponent — solving $3^x = 7$ via
$x = \frac{\log 7}{\log 3}$, base 10 because it is the base
calculators speak. Simple logarithmic equations run in reverse:
rewrite $\log_2(3x - 1) = 4$ in exponential form, solve
$3x - 1 = 16$, and — always — confirm the argument of the logarithm
came out positive, or the "solution" solved a different equation.

[[Logarithm Practice]] covers the whole arc, from evaluating to the
equations inside compound-interest and pH problems.

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[A3.1]]

![[A3.2]]

![[A3.3]]
%%curriculum-end%%
