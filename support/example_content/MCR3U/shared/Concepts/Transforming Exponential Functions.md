---
title: Transforming Exponential Functions
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
You already know what $a$, $k$, $d$, and $c$ do to a parabola. They do
exactly the same things to an exponential curve, which is the point:
transformations are a property of *functions*, not of parabolas. What
changes is which features move, because an exponential has an asymptote
and a parabola does not.

## The general form

$$y = a f(k(x - d)) + c \qquad \text{where } f(x) = b^x$$

| Parameter | What it does | What to watch |
| --- | --- | --- |
| $a$ | Vertical stretch by $\lvert a\rvert$; reflects in the $x$-axis when $a<0$ | The asymptote does not move |
| $k$ | Horizontal compression by $\dfrac{1}{\lvert k\rvert}$; reflects in the $y$-axis when $k<0$ | The $y$-intercept does not move |
| $d$ | Horizontal translation, right when $d>0$ | Inside the bracket, so it works backwards |
| $c$ | Vertical translation, up when $c>0$ | **The asymptote moves to $y=c$** |

That last row is the whole difference from quadratics. An exponential
function's graph approaches a horizontal line it never reaches, and only
$c$ can move it.

## Watching it happen

Start from $y = 2^x$, which passes through $(0, 1)$ with asymptote
$y = 0$, and take one step at a time in [[Using Desmos]]. Predict each
before you press enter:

$$y = 3(2^x) \qquad y = 2^{x-4} \qquad y = 2^x - 5 \qquad y = -2^x$$

The third one is the interesting one. Subtracting 5 drags the whole
curve down, so the asymptote becomes $y = -5$ — and the graph now
crosses the $x$-axis, which $y = 2^x$ never does. A transformation
changed the *number of zeros*, and that is not a cosmetic change.

## Reading the equation off a graph

Given a graph, work in this order and the algebra stays easy:

1. **Find the asymptote.** That is $c$, immediately.
2. **Subtract it away.** What remains behaves like $y = a b^{k(x-d)}$
   with asymptote zero.
3. **Use two points.** Substituting gives two equations; dividing one by
   the other kills $a$ and leaves you solving for the base or for $k$.
4. **Check with a third point.** If it does not fit, one of your first
   two readings was off the grid line.

Worked briefly: a curve with asymptote $y = 3$ passing through $(0, 5)$
and $(1, 7)$. Then $c = 3$, and $5 - 3 = 2$ gives $a = 2$ at $x = 0$;
$7 - 3 = 4$ gives $2b = 4$, so $b = 2$. The function is
$y = 2(2^x) + 3$, and a third point will confirm it.

> [!question]- Why do $a$ and $k$ overlap for exponentials?
> Because a horizontal stretch of an exponential is also a vertical
> stretch: $2^{x-3} = 2^{-3}\cdot 2^{x} = \tfrac{1}{8}(2^x)$. Sliding
> the curve sideways is indistinguishable from scaling it vertically —
> which is true for exponentials and false for parabolas. Two different
> equations can therefore describe the same curve, and both are correct.

## Why this matters beyond the graph

Every growth or decay situation in [[The Exponential Function]]
arrives with a starting amount and a rate — which is to say, with $a$
and $b$ already decided by the context. The transformations are how you
get from the situation to the equation without guessing, and how you
recognise, from a graph somebody hands you, what the situation must have
been.

%%curriculum-start%%
## Curriculum connection

![[B2.2]]

![[B2.3]]

![[B2.5]]
%%curriculum-end%%
