---
title: The Inverse of a Function
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
At the boards the puzzle ran backwards: "my function multiplied a
number by 3, then added 2, and printed 17 — what went in?" Every
group undid it the same way — subtract 2, *then* divide by 3 —
inverse operations, in reverse order, exactly how you take off shoes
and socks. The *inverse* of a function is that undoing, packaged as a
function of its own and written $f^{-1}$.

## Undoing, in the right order

For $f(x) = 3x + 2$, the inverse should take outputs back to inputs.
The algebra mirrors the idea:

- [ ] Write the function as $y = 3x + 2$.
- [ ] Swap $x$ and $y$ — outputs become inputs: $x = 3y + 2$.
- [ ] Solve for $y$, applying inverse operations in reverse order:
      $y = \dfrac{x - 2}{3}$.
- [ ] Test one pair: $f(5) = 17$, so $f^{-1}(17)$ had better be 5.
      It is.

That last box is not optional politeness — it is
[[Checking Your Own Work]] doing its cheapest, fastest job.

## The mirror line

Swapping inputs and outputs has a picture. Take any table of values
for $f$, exchange its columns, and you have a table for the inverse;
plot both and every point $(a, b)$ faces a partner $(b, a)$ across
the line $y = x$. The graph of the inverse is the reflection of the
graph of $f$ in that line — tracing paper folded along $y = x$ shows
it in one move, and [[Using Desmos]] confirms it in two. The swap
also trades the sets from [[Domain and Range]]: the domain of $f$
becomes the range of $f^{-1}$, and vice versa.

## When the inverse is not a function

Reflect $f(x) = x^2$ in the mirror line and the image fails the
vertical-line test — the output 9 came from both 3 and $-3$, so the
undoing cannot decide where to send 9 back. The inverse *relation*
always exists; it is a *function* only when $f$ never repeats an
output. You can rescue $x^2$ by restricting its domain: keep
$x \ge 0$ and the inverse is $g(x) = \sqrt{x}$; keep $x \le 0$ and it
is $h(x) = -\sqrt{x}$.

The same story in algebra, for $f(x) = (x - 2)^2 - 5$: swapping and
solving gives $y = 2 \pm \sqrt{x + 5}$ — the $\pm$ is the algebra
confessing that two answers exist.

Inverses are one of the four wings of [[The Transformation Gallery]],
so your curated examples for that task are the natural place to
practise these moves on functions you chose yourself.

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[A1.5]]

![[A1.6]]

![[A1.7]]
%%curriculum-end%%
