---
title: Zeros and Multiplicity
draft: false
created: __CREATED__
tags:
  - concepts
---
At the boards, your group graphed $(x-2)(x-3)$, then
$(x-2)^2(x-3)$, then $(x-2)^3(x-3)$ in [[Using Desmos|Desmos]] — same
zeros, three different behaviours at $x = 2$. Cross, bounce, flatten.
The repeated factor was doing something, and your group's job was to
say what. The name for what you found is **multiplicity**: how many
times a factor appears.

## The shape at a zero

Near a zero of multiplicity $m$, the graph behaves like $x^m$ does at
the origin, just relocated:

- Multiplicity 1 — the graph cuts straight through the axis.
- Even multiplicity — the graph *touches* the axis and turns back,
  like a parabola's vertex sitting on the line.
- Odd multiplicity of 3 or more — the graph crosses, but flattens as
  it does, like $x^3$ leaning through the origin.

This is why factored form is the sketching form. Read off the zeros,
mark the behaviour at each one, settle the ends with the degree and
leading coefficient, and check the sign of one test value between
intercepts. The zeros of the function are exactly the roots of the
equation $f(x) = 0$ — the graph and the algebra are answering the
same question from two directions.

## From zeros to an equation

Zeros alone do not pin down a polynomial. Every function in the
family $f(x) = k(x-2)(x+1)(x+4)$ has the same three intercepts — the
constant $k$ stretches the graph without moving where it lands. To
choose one member of the family you need one more piece of
information: a point the graph passes through. Substitute the point,
solve for $k$, done. One point, one member.

> [!question]- Self-check: how many cubics have zeros at $-1$, $2$,
> and $5$ — and which one passes through $(0, 20)$? (click to expand)
> Infinitely many: $f(x) = k(x+1)(x-2)(x-5)$ for any $k \ne 0$.
> Substituting $(0, 20)$: $k(1)(-2)(-5) = 10k = 20$, so $k = 2$. The
> family is infinite; the member through your point is unique.

[[Polynomial Graphing Practice]] runs this from both directions —
graph from equation, and equation from graph.

%%curriculum-start%%
## Curriculum connection

![[C1.5]]

![[C1.7]]

![[C1.8]]

![[C3.3]]
%%curriculum-end%%
