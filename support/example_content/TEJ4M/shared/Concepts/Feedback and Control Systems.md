---
title: Feedback and Control Systems
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
On/off control got the plate in [[Close the Loop]] to hold 25 °C, give or
take a degree, with the heater slamming between full power and nothing
and the temperature sawing up and down forever. It works. It is also the
crudest possible answer to the question "how much heat?", and the whole
of control engineering is the observation that the answer should depend
on how far off you are.

## Error first, then a decision about it

Every controller starts with the same subtraction:

$$e = \text{setpoint} - \text{measured}$$

A positive error means you are below target and the output should push
up. The controller is whatever function turns $e$ into an output, and the
first one worth your time is **proportional control**:

$$\text{output} = K_p \times e$$

Take $K_p = 20$ percent of duty per degree of error. An error of 1.5 °C
asks for 30% duty; an error of 0.5 °C asks for 10%. The heater eases off
as the plate approaches the setpoint instead of charging past it, and the
sawing largely disappears.

Two consequences fall straight out of that one line of arithmetic.

The **proportional band** — the error span over which the output moves
from nothing to everything — is $100\% / K_p = 5\ ^\circ\text{C}$ here.
Outside that band the controller is simply saturated: an error of 6 °C
would call for 120% duty, and there is no such thing, so it delivers 100%
and behaves exactly like the on/off controller until it comes back into
band. Your code must clamp the output, and it must do so on purpose.

And a proportional controller **cannot** sit at its setpoint while doing
work. If holding the plate at temperature needs 40% duty, then

$$e = \frac{40\%}{20\%/^\circ\text{C}} = 2\ ^\circ\text{C}$$

of error is required to generate that 40%. Zero error would produce zero
output and the plate would cool. This permanent gap is called
**steady-state offset**, or droop, and it is not a bug — it is the
definition of proportional control. Raise $K_p$ and the offset shrinks,
but the loop becomes twitchier and eventually oscillates. That trade is
the reason integral action exists: a term that accumulates error over
time and keeps pushing until the error is genuinely zero, at the cost of
a new failure mode when the accumulator winds up during a long saturation
and takes forever to unwind. Derivative action, responding to the *rate*
of change, damps overshoot and amplifies noise while it does it.

You are not expected to tune a full three-term controller this year. You
are expected to know why a proportional-only loop settles a little short,
and to say so in your report rather than quietly redefining the setpoint.

## The actuator is not linear, and the loop must know

Between the controller's output and the world sits a real device with
real behaviour, and the arithmetic above assumes a straight line that
does not exist.

Most small DC motors will not turn at all below some duty — call it 20% —
because friction wins. A controller asking for 8% produces nothing, sees
no change, and asks for less. Map the command onto the range that
actually does something:

$$\text{duty} = 20\% + 0.8 \times \text{command}$$

so a command of 50 becomes 60% duty, a command of 0 becomes the 20% at
which the motor just moves, and 100 stays 100. The same idea, in
different clothes, handles a heater with a slow start or a valve with a
mechanical deadband. Measure your own actuator's threshold on the bench
and write the number down; borrowing somebody else's is how a loop
becomes untunable.

> [!important] Sample the loop at a rate the process deserves
> A control loop is a discrete thing: it looks, decides, and acts, over
> and over. The period between those looks must be short compared with
> how fast the process moves, and long enough that the process has
> actually responded.
>
> A heated plate with a time constant near 60 seconds is well served by a
> loop running once a second — sixty decisions per time constant, which
> is plenty. Run that same loop every five minutes and it is blind
> between decisions; run it a thousand times a second and you have
> multiplied the noise, burned the processor, and gained nothing, because
> the plate cannot possibly have changed.
>
> Fix the period, keep it fixed, and never build it out of `sleep` calls
> that also block your buttons — [[Timing, Interrupts, and Real Time]] is
> how a loop keeps time while the rest of the device stays awake.

## Tuning, and how to know when to stop

Tune in the open, with numbers, and log every run:

1. Start with the loop period and the actuator mapping settled. Tuning a
   loop whose timing wanders is guesswork.
2. Raise $K_p$ until the response is brisk and then just short of
   oscillating. If it oscillates, you have gone past — halve it.
3. Measure what you now have: rise time to the setpoint, overshoot,
   settling time, and the steady-state offset. Those four numbers are
   your evidence.
4. Only then decide whether the offset matters enough to add integral
   action. Sometimes the honest answer is to move the setpoint by the
   known offset and document it.

A loop that oscillates forever is not "nearly tuned" — it is a system
whose gain exceeds what its delays allow. Every real loop contains delay:
the sensor's own response time, your filter, the sampling period, and the
time the process takes to react. The more of it you have, the less gain
you can use. That is why a heavily filtered signal is not a free lunch
and why [[Filters and Noise]] and this page are one problem, not two.

Bring the four measured numbers, the tuning log, and the failure case
from [[Open and Closed Loop Control]] to the design review for
[[The Control System]]. Rehearse the arithmetic in
[[Control Systems Practice]] and write the controller itself using the
structure in [[State Machines in Code]], so that "holding setpoint",
"warming up", and "sensor failed" are states you named rather than
conditions you hope for.

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[B5.2]]

![[B5.3]]
%%curriculum-end%%
