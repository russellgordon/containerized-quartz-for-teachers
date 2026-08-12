---
title: Curve Sketching
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[The Slope Detective]], your group was handed a graph of $f'$ —
only the derivative, never the function — and asked to reconstruct
what $f$ must look like. The startling part was how much you could
recover: every climb, every turn, every flattening, all legible in a
graph of slopes. And the honest limit of the method mattered just as
much: your group's $f$ and the next group's $f$ differed by a
vertical shift, and *both were right*. The derivative knows a
function's shape completely and its height not at all — infinitely
many correct answers, one shape.

## What the first derivative knows

The sign of $f'$ is the story of $f$'s direction:

- $f'(x) > 0$ on an interval — $f$ is increasing there.
- $f'(x) < 0$ — decreasing.
- $f'(x) = 0$ — a flat moment: possibly a local maximum, possibly a
  local minimum, possibly a pause mid-climb.

That last "possibly" is why detectives check both sides. A local
maximum is $f'$ changing from $+$ to $-$; a minimum is $-$ to $+$;
no sign change, no turn — $f(x) = x^4 - 4x^3$ has $f'(0) = 0$ and
sails straight through.

## What the second derivative adds

$f''$ is the derivative's derivative — the same idea that was
acceleration in [[Motion on a Line]], now read as *bending*. Where
$f'' > 0$ the slopes are increasing and the graph is concave up,
holding water; where $f'' < 0$ it is concave down, shedding it. A
point where the concavity actually changes is a **point of
inflection** — the graph's wrist-flick, where tangent slopes stop
growing and start shrinking or the reverse. At an inflection point
$f'' = 0$, and $f'$ itself has a local maximum or minimum: the
steepest moment of the climb.

## The sketching checklist

Consolidating from the boards, the full routine for a polynomial
like $f(x) = x^3 - 6x^2 + 9x$:

- [ ] Intercepts: factor if you can — $x(x - 3)^2$ has roots at 0
      and 3.
- [ ] Compute $f'$ and find its zeros: $3(x - 1)(x - 3)$, so 1
      and 3.
- [ ] Sign chart for $f'$: increasing, then decreasing, then
      increasing — a local maximum at $(1, 4)$, a local minimum at
      $(3, 0)$.
- [ ] Compute $f''$ and its zeros: $6x - 12$, so an inflection point
      at $(2, 2)$ — concave down before, up after.
- [ ] Sketch, then verify with technology. Agreement is the point;
      a disagreement is data about where your chart went wrong.

Notice the double root at $x = 3$ and the local minimum at $(3, 0)$
are the *same fact* seen twice — the graph touching the axis without
crossing. When two lines of evidence corroborate, the sketch is
solid. [[Curve Sketching Practice]] runs this routine until it is
yours, and a worked sketch makes an excellent notes-to-future-self
entry in your [[Math Journal]]. The same machinery, pointed at
"which value is best?" instead of "what does it look like?", is
[[Optimization]].

%%curriculum-start%%
## Curriculum connection

![[B1.1]]

![[B1.3]]

![[B1.4]]

![[B1.5]]
%%curriculum-end%%
