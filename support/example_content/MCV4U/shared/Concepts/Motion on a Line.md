---
title: Motion on a Line
publish: true
created: __CREATED__
tags:
  - concepts
---
Someone in your group walked in front of the motion sensor today —
forward, pause, drift back — and the class watched a
position–time graph draw itself in real time. Then came the request
that turns walking into calculus: *walk so the graph comes out
straight; now walk so it curves upward.* Position, how position
changes, and how *that* changes: the whole page is those three
layers.

If $s(t)$ is position at time $t$, then:

- **Velocity** is the derivative of position: $v(t) = s'(t)$. Its
  sign is direction; its size is speed.
- **Acceleration** is the derivative of velocity:
  $a(t) = v'(t) = s''(t)$ — the rate of change of the rate of
  change, and your first meeting with a *second derivative*.

That double-prime is a genuinely new idea wearing familiar clothes.
The [[Which One Doesn't Belong]] set of motion graphs turned on it:
two graphs can climb equally fast on average while one of them is
easing off and the other is winding up.

## Speeding up or slowing down?

Here is the trap the sensor walk exposed: acceleration is *not*
"speeding up". A ball thrown upward with
$s(t) = -5t^2 + 20t$ has $v(t) = -10t + 20$ and constant
$a(t) = -10$ — yet it slows on the way up and speeds up on the way
down, with the same acceleration throughout. What matters is the
*agreement* between velocity and acceleration:

| $v(t)$ | $a(t)$ | The object is |
| --- | --- | --- |
| $+$ | $+$ | moving in the positive direction, speeding up |
| $+$ | $-$ | moving in the positive direction, slowing down |
| $-$ | $+$ | moving in the negative direction, slowing down |
| $-$ | $-$ | moving in the negative direction, speeding up |

Same signs, speeding up; opposite signs, slowing down. The ball
turns around at $t = 2$, when $v = 0$ — twenty metres up,
momentarily still, accelerating the whole time.

## The pattern behind motion

Motion is the curriculum's favourite costume for derivatives, but
the same two-layer reading works on any quantity that changes:
population and growth rate, prices and inflation, a tank's volume
and its rate of flow. A question about "the moment inflation peaked"
is a question about the derivative of a derivative, whoever is
asking. The [[Smooth Landing]] task lives here — height, velocity,
and acceleration all behaving at once — and the motion questions in
[[Curve Sketching Practice]] rehearse the sign analysis above. The
same first-and-second-derivative reading, applied to graphs instead
of walkers, is [[Curve Sketching]] — it is the next page, and it is
the same page.

%%curriculum-start%%
## Curriculum connection

![[B1.2]]

![[B2.1]]

![[B2.2]]
%%curriculum-end%%
