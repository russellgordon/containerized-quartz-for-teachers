---
title: The Factor Theorem
publish: true
created: __CREATED__
tags:
  - concepts
---
On division day at the boards, every group divided the same cubic by
$x - a$ for a different value of $a$, then computed $f(a)$ — and the
room noticed before anyone announced it: the remainder *was* $f(a)$,
every single time. That observation has a name, and a consequence
worth the whole class.

The **remainder theorem**: when a polynomial $f(x)$ is divided by
$x - a$, the remainder equals $f(a)$. No division required — one
substitution tells you what the division would leave behind.

The **factor theorem** is the special case that earns its keep:
$x - a$ is a factor of $f(x)$ exactly when $f(a) = 0$. A zero
remainder means clean division, and clean division means a factor.
This is the tool Grade 10 never gave you — a way to factor cubics and
quartics, where no formula like the quadratic one is coming to save
you.

## A factoring workflow

To factor something like $x^3 - 4x^2 + x + 6$:

- [ ] List candidate zeros: the factors of the constant term, with
      both signs. Here: $\pm 1, \pm 2, \pm 3, \pm 6$.
- [ ] Test candidates by substitution until one gives $f(a) = 0$.
      Here $f(-1) = -1 - 4 - 1 + 6 = 0$, so $x + 1$ is a factor.
- [ ] Divide by that factor to drop the degree by one.
- [ ] Repeat, or finish with Grade 10 tools once you reach a
      quadratic. Here the quotient factors to $(x-2)(x-3)$, giving
      $f(x) = (x+1)(x-2)(x-3)$.
- [ ] Expand or substitute to confirm —
      [[Checking Your Own Work]] beats hoping.

The candidate list is not magic: if $x - a$ is a factor with integer
$a$, then $a$ must divide the constant term, because the constant is
the product of all the factors' constants. Testing candidates is
deduction, not guessing.

## Why it works

Division writes $f(x) = (x - a)\,q(x) + r$ for some quotient $q(x)$
and constant remainder $r$. Substitute $x = a$ and the first term
vanishes: $f(a) = r$. That is the entire proof — two lines, and worth
reconstructing at the boards whenever you doubt it. A theorem you can
rebuild is a theorem you cannot forget.

[[Factor Theorem Practice]] runs the workflow on cubics, quartics,
and problems where the unknown is a coefficient rather than a root.

%%curriculum-start%%
## Curriculum connection

![[C3.1]]

![[C3.2]]

![[C3.4]]

![[C3.7]]
%%curriculum-end%%
