---
title: Derivatives of Exponential Functions
publish: true
created: __CREATED__
tags:
  - concepts
---
Today's class was a hunt. With a slider controlling $a$, your group
graphed $f(x) = a^x$ next to its derivative and chased a question:
for what base does the derivative land exactly *on top of* the
function? At $a = 2$ the derivative ran below; at $a = 3$ it ran
above. The prey was somewhere between — and the class cornered it
near $2.718$. That number is called $e$, and it is the reason this
page is short.

$$\text{If } f(x) = e^x, \text{ then } f'(x) = e^x$$

A function that is its own derivative: at every point, the slope of
the tangent *equals the height of the graph*. Let that be strange
for a minute. Growth whose speed is its size is exactly what
populations, investments, and decaying isotopes do — which is why
$e$ shows up wherever things grow.

## Every other base

The hunt revealed something about the bases that *lost*, too. For
any $a > 0$, $a \neq 1$, the derivative of $a^x$ is a vertical
stretch of the original — the ratio $\frac{f'(x)}{f(x)}$ is the same
constant at every $x$. The constant has a name:

$$\text{If } f(x) = a^x, \text{ then } f'(x) = a^x \ln a$$

Here $\ln x$ is the *natural logarithm*, $\log_e x$ — the inverse of
$e^x$, exactly as $\log_2 x$ inverts $2^x$. And the two facts are
one fact: when $a = e$, the stretch factor is $\ln e = 1$, and the
derivative lands on the function. Every base is trying to be $e$;
only one succeeds.

Worth checking with your own hands — [[Using Desmos]] shows you how,
and an [[Estimation Duels]] instinct makes the numbers meaningful:

- [ ] Graph $f(x) = 2^x$ and its derivative. Verify the ratio
      $\frac{f'(x)}{f(x)}$ is near $0.693$ at several values of $x$
      — then compute $\ln 2$.
- [ ] Evaluate $\frac{2^h - 1}{h}$ for $h = 0.1$, $0.01$, $0.001$.
      The march should be heading for that same $0.693$.
- [ ] Predict the stretch factor for $f(x) = 10^x$ before you check
      it. Bigger or smaller than 1? Why must it be bigger?

With the chain rule along, composites like $e^{3x}$ fall too:
derivative $3e^{3x}$, the inside reporting its rate as always.
[[Exponential and Sinusoidal Derivatives Practice]] puts this to
work on real growth and decay, and the other family of functions
that models the world — the repeating kind — is next, in
[[Derivatives of Sinusoidal Functions]].

%%curriculum-start%%
## Curriculum connection

![[A2.5]]

![[A2.6]]

![[A2.7]]

![[A2.8]]
%%curriculum-end%%
