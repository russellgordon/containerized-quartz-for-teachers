---
title: Expanding and Factoring
publish: true
created: __CREATED__
tags:
  - concepts
---
When your group tiled the frame in [[The Border Problem]], you found
the same area two ways — as one big product, and as a sum of
pieces. That double-counting is the whole relationship between
expanding and factoring: two names for the same area, read in
opposite directions.

## Expanding — multiplying out

To expand $(x + 3)(x + 5)$, treat it as the area of a rectangle with
sides $x + 3$ and $x + 5$, cut into four pieces:

| $\times$ | $x$ | $+5$ |
| --- | --- | --- |
| $x$ | $x^2$ | $5x$ |
| $+3$ | $3x$ | $15$ |

Total area: $x^2 + 5x + 3x + 15 = x^2 + 8x + 15$. Every term in one
bracket meets every term in the other — the area model guarantees
nothing gets missed, and it scales to $(2x - y)(x + 3y)$ or
$(2x + 5)^2$ with no new rules to learn.

## Factoring — multiplying in reverse

Factoring asks: this expression is the area — what were the side
lengths? Three patterns cover this course.

**Common factor.** Every term of $2x^2 + 4x$ contains $2x$, so pull
it out: $2x(x + 2)$. Always look for this first.

**Trinomials.** For $x^2 + 8x + 15$, hunt for two numbers that
multiply to $15$ and add to $8$ — that is $3$ and $5$, so the sides
were $(x + 3)(x + 5)$: the rectangle above, rebuilt from its area.
When the front coefficient is not 1, as in $2a^2 + 11a + 5$, the
area model earns its keep again: $(2a + 1)(a + 5)$.

**Difference of squares.** $4x^2 - 25 = (2x - 5)(2x + 5)$. Expand
the right side and watch the middle terms cancel — a difference of
squares is secretly a trinomial whose middle term is $0$.

Expanding is mechanical; factoring is detective work — and checking
is free, because any factoring claim can be expanded to test it. A
factoring that does not expand back to the original is not a failure
to hide; it is information, which is the whole point of
[[Mistakes Are Data]].

Why care? A factored quadratic hands you its zeros, which is where
[[Zeros and the Quadratic Formula]] picks up the story.
[[Expanding and Factoring Practice]] builds the pattern-recognition
speed that makes the rest of the quadratics work feel light.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.2]]
%%curriculum-end%%
