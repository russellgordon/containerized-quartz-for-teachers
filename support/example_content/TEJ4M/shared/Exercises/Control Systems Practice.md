---
title: Control Systems Practice
publish: true
created: __CREATED__
tags:
  - exercises
---
These follow [[Open and Closed Loop Control]] and
[[Feedback and Control Systems]], and they are the arithmetic you bring
to [[Close the Loop]]. A control answer is never just a number: it is a
number plus what happens at the limits, because every real loop meets a
saturated output, a noisy sensor, and an actuator that will not move
below some threshold.

## Deciding how much output

1. A thermostat holds 25 °C using on/off control with a symmetrical
   hysteresis band of ± 0.5 °C. State the two switching thresholds. The
   sensor noise is measured at ± 0.3 °C peak — is this band adequate,
   and what happens if the band is reduced to ± 0.1 °C?
2. A proportional controller uses $K_p = 20$ percent of duty per degree
   of error. Calculate the commanded output for errors of 0.5 °C,
   1.5 °C, 3.0 °C, and 6.0 °C, and state what the code must do with the
   last one.
3. Calculate the proportional band for that controller, and explain in
   one sentence what the controller does outside it.
4. Holding the plate at temperature requires 40% duty. Calculate the
   steady-state error for $K_p = 20$, then for $K_p = 50$. Why not
   simply keep raising $K_p$?
5. A motor will not turn below 20% duty. Write the mapping from a
   0 – 100 command to actual duty, calculate the duty for a command of
   50, and explain what the loop does without this mapping.

## Timing, measurement, and tuning

6. A PWM output takes an 8-bit duty value. Calculate the value nearest
   to 30%, and the actual duty percentage it produces.
7. An encoder wheel has 20 slots. The controller counts 240 pulses in
   2.0 s. Calculate the pulses per second, the revolutions per second,
   and the speed in rpm.
8. The heated plate has a time constant near 60 s. Comment on running
   the control loop (a) once per second, (b) once every five minutes,
   and (c) a thousand times a second.
9. **Find the error.** A group reports: "We raised the gain until the
   temperature started oscillating, which showed us the controller was
   working hard, and left it there. It holds within about 2 degrees and
   the fan is always doing something." What is wrong, and what should
   they measure and report instead?

## Answers

> [!success]- Answer 1
> **Thresholds:** heat below $25.0 - 0.5 = 24.5\ ^\circ\text{C}$, stop above $25.0 + 0.5 = 25.5\ ^\circ\text{C}$. The full band is 1.0 °C wide.
>
> **Is it adequate?** Yes, comfortably. The band is 1.0 °C wide and the noise is ± 0.3 °C, so a noise excursion cannot carry the reading across both thresholds — the noise would have to exceed the half-band of 0.5 °C to cause a false switch.
>
> **Reduced to ± 0.1 °C:** the band becomes 0.2 °C wide while the noise is ± 0.3 °C. Noise alone now carries the reading back and forth across both thresholds, so the heater switches rapidly and repeatedly — chattering. Relay contacts and mechanical actuators wear out on exactly this, and the average power delivered stops being controlled in any meaningful way.
>
> The rule that falls out: **the hysteresis band must be comfortably wider than the noise**, which means you must measure the noise first, using the methods in [[Filters and Noise]].

> [!success]- Answer 2
> $\text{output} = K_p \times e$:
>
> $0.5\ ^\circ\text{C} \rightarrow 20 \times 0.5 = 10\%$
>
> $1.5\ ^\circ\text{C} \rightarrow 20 \times 1.5 = 30\%$
>
> $3.0\ ^\circ\text{C} \rightarrow 20 \times 3.0 = 60\%$
>
> $6.0\ ^\circ\text{C} \rightarrow 20 \times 6.0 = 120\%$
>
> **What the code must do with 120%:** clamp it to 100%. There is no such thing as 120% duty, and an unclamped value written to a PWM register produces something nobody designed — commonly a wrapped value that turns the output *down*, which is the worst possible response to a large error. Clamp at the point the value leaves your code, as in [[Defensive Embedded Code]].

> [!success]- Answer 3
> The proportional band is the error span over which the output travels from 0% to 100%:
>
> $\text{band} = \frac{100\%}{20\%/^\circ\text{C}} = 5\ ^\circ\text{C}$
>
> **Outside it** the controller is saturated and behaves exactly like an on/off controller — full output until the error comes back within 5 °C of the setpoint.

> [!success]- Answer 4
> With $K_p = 20$: $e = \frac{40\%}{20\%/^\circ\text{C}} = 2.0\ ^\circ\text{C}$.
>
> With $K_p = 50$: $e = \frac{40\%}{50\%/^\circ\text{C}} = 0.8\ ^\circ\text{C}$.
>
> The plate settles that far *below* the setpoint, permanently, because a proportional controller needs an error to produce an output. This is steady-state offset, and it is a property of the design, not a fault.
>
> **Why not keep raising $K_p$:** every loop contains delay — the sensor's response, the filter, the sampling period, and the process itself. Higher gain means the controller responds more violently to an error it is seeing late, so it overshoots, corrects violently the other way, and eventually oscillates continuously. The gain at which that begins is set by the delays, so the honest sequence is: reduce the delays where you can, raise the gain until the response is brisk but stable, then decide whether the remaining offset needs integral action.

> [!success]- Answer 5
> Map the command onto the range in which the motor actually moves:
>
> $\text{duty} = 20\% + \frac{100 - 20}{100} \times \text{command} = 20\% + 0.8 \times \text{command}$
>
> A command of 50 gives $20 + 0.8 \times 50 = 60\%$ duty. A command of 0 gives 20%, and 100 gives 100%.
>
> **Without the mapping:** commands between 1 and 19 produce nothing. The loop sees no change, concludes the error is still there, and — with proportional control — asks for *less* as the error shrinks, so it never escapes. The motor sits still while the controller quietly insists it is working. With integral action it eventually winds up and then lurches.
>
> One refinement worth noting: a command of exactly zero should usually mean *stop*, not 20%, so the mapping needs a genuine off case. Measure your own actuator's threshold rather than borrowing this 20%.

> [!success]- Answer 6
> An 8-bit duty value runs from 0 to 255, so 30% is
>
> $0.30 \times 255 = 76.5$
>
> which must be rounded to an integer: **76** (or 77). The actual duty is
>
> $\frac{76}{255} \times 100 \approx 29.8\%$
>
> Small, and worth stating anyway — 76 is what the hardware does, 30% is what you asked for, and a report should say which number it is quoting. With a 16-bit duty value the same 30% is $0.30 \times 65535 \approx 19\,661$, where the rounding error is negligible.

> [!success]- Answer 7
> $\frac{240\ \text{pulses}}{2.0\ \text{s}} = 120\ \text{pulses/s}$
>
> $\frac{120\ \text{pulses/s}}{20\ \text{pulses/rev}} = 6.0\ \text{rev/s}$
>
> $6.0\ \text{rev/s} \times 60\ \text{s/min} = 360\ \text{rpm}$
>
> Two practical notes. The resolution of this measurement over a 2 s window is one pulse in 240, but over a 0.1 s window it would be one pulse in 12 — about 8% — so a fast loop measuring speed this way is measuring coarsely. And every pulse must be counted, which is what the interrupt handler in [[Timing, Interrupts, and Real Time]] is for; a polled loop that misses pulses under-reports the speed and the controller responds by speeding the motor up.

> [!success]- Answer 8
> **(a) Once per second** — sensible. Sixty decisions per time constant is plenty to follow the process, and there is time in each pass for averaging, logging, and the rest of the device.
>
> **(b) Once every five minutes** — far too slow. The loop is blind for five time constants at a stretch; the plate can heat past the setpoint and cool again between decisions, and no gain setting can fix a controller that is not looking.
>
> **(c) A thousand times a second** — pointless and mildly harmful. The plate cannot change measurably in a millisecond, so consecutive readings differ only by noise, which the controller then amplifies into a jittery output. It also burns processor time and rules out averaging. Sampling faster than the process is not more control; it is more noise.
>
> The useful rule: sample fast compared with the process, slow compared with the noise and the work the loop must do, and keep the period **fixed** — a control loop whose period wanders is a control loop whose gain wanders.

> [!success]- Answer 9
> **What is wrong:**
>
> Oscillation is not evidence that the controller is working hard; it is evidence that the loop gain exceeds what its delays permit. Leaving the gain there guarantees the output never settles.
>
> "The fan is always doing something" is being read as a feature. It is the symptom: continuous actuator movement means continuous wear, continuous power, and a plate temperature that is never where it was asked to be.
>
> "Holds within about 2 degrees" is an unmeasured claim. Within 2 degrees of what, over what interval, from what disturbance, measured with which instrument?
>
> The tuning method is also backwards. The gain at which oscillation starts is an upper bound to back away from, not a destination.
>
> **What they should do and report:**
>
> 1. Reduce the gain — halving it from the oscillation point is the standard first move — and confirm the oscillation stops.
> 2. Apply a repeatable disturbance (a step change in setpoint, or opening the enclosure) and record the response against a reference thermometer.
> 3. Report four numbers with units: **rise time** to reach the setpoint, **overshoot** in degrees, **settling time** to stay within a stated band, and **steady-state offset** in degrees.
> 4. State the loop period and the actuator mapping used, since neither the gain nor the response means anything without them.
> 5. Only then decide whether the remaining offset justifies integral action — and if it does not, say so and document the offset instead.
>
> Those four numbers are the deliverable for [[The Control System]]. "It holds pretty well" is not a measurement, and a design review will ask for the graph.

Take the tuning log to [[Close the Loop]] and keep every run, including
the ones that oscillated. A record of what did not work, with the gain
written beside it, is the most convincing evidence in the report — see
[[Tech Journal]].

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[A3.4]]

![[B5.3]]
%%curriculum-end%%
