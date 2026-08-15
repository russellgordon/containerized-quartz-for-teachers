---
title: Estimation Duels
publish: true
created: __CREATED__
tags:
  - number-talks
---
A quantity goes on the board — the slope of a tangent nobody is
allowed to differentiate yet, the angle between two arrows, how fast
a puddle's area grows the moment its radius passes a metre — and two
duellists commit to estimates before anyone computes. Each defends a
reason. Then the class brackets: surely too low, surely too high,
squeezed until cornered.

## How we play

1. Commit in writing first. A number without a reason scores nothing.
2. Defend: what did you compare it to, and which way did rounding push you?
3. Bracket as a class, then calculate the reveal.

> [!example]- One duel: the slope of $y = x^2$ at $x = 3$
> - "More than 5 — because the secant from $x = 2$ to $x = 3$ has
>   slope $\frac{9 - 4}{1} = 5$, and the curve is steepening, so the
>   tangent at 3 must beat every secant that arrives from the left."
> - "Less than 7 — because the secant from $x = 3$ to $x = 4$ has
>   slope $\frac{16 - 9}{1} = 7$, and by the same steepening the
>   tangent must lose to every secant that leaves to the right. So
>   it is cornered between 5 and 7 before anyone computes anything."
> - "Split the difference with the secant that *straddles* the
>   point: from $x = 2$ to $x = 4$, slope $\frac{16 - 4}{2} = 6$.
>   I said 6."
> - The reveal: exactly 6. For a parabola, the straddling secant is
>   not an estimate at all — it lands on the tangent dead centre.
>   Why that happens for this curve, and not for every curve, is a
>   question worth carrying into [[The Derivative]].

## One variation

Vector duels: the angle between $\langle 3, 4 \rangle$ and
$\langle 5, 0 \rangle$. Less than $90^\circ$, because both arrows
lean the same general way; more than $45^\circ$, because the first
arrow rises faster than it runs. Cornered between $45^\circ$ and
$90^\circ$ before any formula appears — the reveal is about
$53^\circ$, and [[The Dot Product]] is the machine that turns the
bracket into an exact number.

> [!tip] Bracketing is a life skill
> An answer you cannot bracket is an answer you cannot check. Naming
> "too low" and "too high" first is [[Checking Your Own Work]] done
> in advance — before the mistake instead of after it. Tangent
> slopes need it most: a secant on each side of the point corners
> the tangent between them, which is the entire strategy of
> [[The Limit]] wearing estimation clothes.
