---
title: Solving Systems Algebraically
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
A graph shows roughly where two lines cross; algebra tells you
exactly. When your group hit a [[Linear Systems]] problem whose
intersection refused to land on a grid point, somebody said "there
has to be a way to just calculate it" — and there are two.

## Substitution — replace a name with what it stands for

If one equation already tells you what $y$ equals, carry that
information into the other equation:

$$
y = 2x - 3 \qquad 3x + y = 12
$$

Since $y$ *is* $2x - 3$, write it that way in the second equation:

$$
3x + (2x - 3) = 12 \implies 5x = 15 \implies x = 3
$$

Then $y = 2(3) - 3 = 3$. Substitution shines when a variable is
already isolated — a $y =$ or $x =$ equation is an open invitation.

## Elimination — combine equations to cancel a variable

When both equations arrive in $Ax + By = C$ form, line them up and
add or subtract so that one variable disappears:

$$
2x + 3y = 12 \qquad 4x - 3y = 6
$$

Adding the equations cancels the $y$ terms: $6x = 18$, so $x = 3$,
and substituting back gives $y = 2$. Elimination shines when nothing
is isolated and isolating would breed fractions; if nothing cancels
on its own, multiply one equation (or both) first to manufacture a
matching pair. Two methods, one answer — the choice is a judgement
call, not a loyalty oath, and comparing routes with a neighbouring
group is where that judgement comes from.

## The non-negotiable last step

Check the point in *both* original equations. A solution satisfies
the system, not half of it — a point that checks in one equation
but fails the other is how arithmetic slips announce themselves.
That is [[Checking Your Own Work]] doing real work.

> [!success]- Quick self-check (click to expand)
> Solve $x + y = 10$ and $y = 3x - 2$. Substitution:
> $x + (3x - 2) = 10$, so $4x = 12$ and $x = 3$, giving $y = 7$.
> Check both: $3 + 7 = 10$ ✓ and $3(3) - 2 = 7$ ✓. Certainty.

[[Linear Systems Practice]] mixes systems that favour each method,
and [[Break-Even]] is where the algebra pays for a real decision.

%%curriculum-start%%
## Curriculum connection

![[B1.1]]

![[B1.2]]
%%curriculum-end%%
