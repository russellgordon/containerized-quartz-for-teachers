---
title: Close the Loop
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
Holding a temperature sounds like the easiest thing a computer could be
asked to do: read the sensor, and if it is too cold, turn the heater on.
That controller works, and it is also the reason your kitchen oven
swings ten degrees either side of what the dial says.

Today you build that controller, measure exactly how badly it swings,
and then replace it with one that decides *how much* heat rather than
*whether*. You will predict the overshoot before the heater is
energised, and you will end the period with two traces and a claim you
can defend.

> [!danger] Safety notes
> **A power resistor dissipating watts is a heating element, and it
> behaves like one.** Mount it on a ceramic terminal block or standoffs
> — never in a breadboard, whose plastic melts — with nothing flammable
> within a hand's width and no wire insulation touching it. It reaches
> temperatures that burn instantly and stays hot for minutes after
> power off. Read it with the infrared thermometer only. **The heater
> gets its own supply, with the current limit set before the first
> connection**, and only the grounds are tied together. **Your code
> must contain a hard limit that runs before any control logic**: a
> maximum on-time and a maximum temperature at which the output shuts
> off regardless of what the controller wants. Write that first, test
> it first. **Never leave a powered heater unattended**, not even to
> fetch a meter. **Predict the failure where the sensor falls off** —
> the controller reads cold, drives full power, and does not stop —
> and make sure your code detects an implausible reading and shuts
> down. **If your actuator is a fan or a pump rather than a resistor,
> it is inductive and needs a flyback diode**; a resistive heater does
> not. Everything in [[Safety in the Lab]] applies on top of this.

## What you need

- [ ] A $10\ \Omega$ wirewound or ceramic power resistor rated at least
      $5\ \text{W}$, on a ceramic terminal block
- [ ] Temperature sensor, mounted in firm thermal contact with the
      resistor, plus a way to secure it that cannot fall off
- [ ] Logic-level N-channel MOSFET, $220\ \Omega$ gate resistor,
      $100\ \text{k}\Omega$ gate pull-down
- [ ] Microcontroller board, breadboard for the low-power side only
- [ ] Bench supply for the heater, set to $5\ \text{V}$ with the
      current limit at $0.6\ \text{A}$
- [ ] Multimeter, oscilloscope or a plotting program, infrared
      thermometer, stopwatch, safety glasses

## Predict before you build

1. **Predict the heater power.** At $5\ \text{V}$ across
   $10\ \Omega$, $I = V/R = 0.5\ \text{A}$ and
   $P = VI = 2.5\ \text{W}$. Confirm that is inside the resistor's
   rating, then halve the rating and look again, as
   [[Reliability and Derating]] insists.
2. **Predict the pin problem.** $0.5\ \text{A}$ is many times what any
   output pin may deliver. Check your board's datasheet, write down the
   real limit, and say in one sentence why the MOSFET is not optional.
3. **Predict the time constant.** Switch the heater on at full power
   and estimate how long the sensor will take to rise by
   $10\ ^\circ\text{C}$. You are guessing — write the guess down
   anyway, because the whole of control is about this delay.
4. **Predict the bang-bang behaviour.** With a hysteresis band of
   $\pm 1\ ^\circ\text{C}$ around a setpoint, predict the peak-to-peak
   swing you will actually get and the period of the oscillation.
   Predict whether the real swing will be larger or smaller than the
   band, and say why.
5. **Predict the proportional controller's flaw.** If the output is
   $\text{duty} = K_p \times (\text{setpoint} - \text{temperature})$,
   what does the controller command at the exact moment the temperature
   reaches the setpoint? Follow that answer through and predict where
   the temperature will actually settle.

## The work

6. Build the low-power side first: gate to the pin through
   $220\ \Omega$, pull-down from gate to ground, source to ground.
   Power the board alone and confirm the gate sits low.
7. Connect the heater's supply last, grounds tied. Confirm the heater
   stays cold before the code runs.
8. **Write the safety limit before the controller.** It runs on every
   pass, before any control decision:

```python
MAX_SAFE_C = 70.0            # the resistor and its mounting decide this
MAX_ON_SECONDS = 120         # nothing runs longer than this without a check

def is_safe(temperature_c, seconds_on):
    if temperature_c is None:
        return False         # a sensor that stopped answering is not "cold"
    if temperature_c < -10.0 or temperature_c > MAX_SAFE_C:
        return False         # implausible readings mean the sensor moved
    if seconds_on > MAX_ON_SECONDS:
        return False
    return True
```

9. **Test the safety limit deliberately**, before any control runs:
   unplug the sensor and confirm the heater shuts off. Do not proceed
   until it does.
10. **Open loop first, for the record.** Drive the heater at full power
    and log temperature every second until it stops rising or reaches
    your safe limit. This curve is the system you are about to control,
    and every tuning decision refers back to it.
11. **Bang-bang.** Heater on below $(\text{setpoint} - 1)$, off above
    $(\text{setpoint} + 1)$. Log for five minutes. Measure the actual
    peak-to-peak swing and the period.
12. **Proportional.** Compute the error, multiply by $K_p$, clamp the
    result between $0$ and $100\%$ duty, and drive the heater with PWM.
    Start with a small $K_p$, log a full run, then double it and log
    another.
13. **Step test each version.** With the system settled, raise the
    setpoint by $10\ ^\circ\text{C}$ and log the response. From each
    log, read off the overshoot, the time to first reach the setpoint,
    and the settling time — that is your tuning evidence, and it is
    what [[The Control System]] asks you to produce.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Heater current (A) | 0.500 | |
| Heater power (W) | 2.50 | |
| MOSFET drain-source voltage while on (mV) | | |
| Time to rise 10 °C, full power (s) | | |
| Bang-bang swing, peak-to-peak (°C) | | |
| Bang-bang period (s) | | |
| Proportional, small $K_p$: overshoot (°C) | | |
| Proportional, small $K_p$: settling time (s) | | |
| Proportional, doubled $K_p$: overshoot (°C) | | |
| Proportional, doubled $K_p$: settling time (s) | | |
| Steady-state error, proportional (°C) | | |

## Predicted against measured

Your bang-bang swing is almost certainly wider than the
$\pm 1\ ^\circ\text{C}$ band you programmed, and the reason is the whole
lesson: heat already in the resistor keeps arriving at the sensor after
the power is off, and the sensor keeps reporting the past for a while
after that. The measured swing minus the programmed band is a direct
measurement of your system's delay. Name the two parts of that delay —
the thermal mass and the sensor's own response — and say which one you
could reduce.

The steady-state error row should match your prediction in step 5. A
proportional controller commands zero output at zero error, so it can
only hold a temperature that needs zero heat, which is room temperature.
It settles wherever the error is just large enough to command the heat
the system is losing. If you doubled $K_p$ and the error roughly halved,
you have measured that relationship rather than read it.

If doubling $K_p$ also produced overshoot or oscillation, you have found
the other half of control: a gain high enough to reduce error is a gain
high enough to make the delay dangerous.

## The question that matters

You have two controllers and neither one holds the setpoint properly:
one oscillates, the other settles somewhere below. Explain, with your
own two traces in front of you, why those are the *same* problem seen
from two directions. Then say what a third term in the controller would
have to do to fix the offset, and what new risk it would introduce.

Then the design-margin questions:

- The room is $10\ ^\circ\text{C}$ colder tomorrow. What happens to
  your steady-state error, and would your customer notice?
- The sensor comes loose. You already tested that case — now say how
  quickly your code detects it, and how you measured that.
- This runs eight hours a day for a year. What in your build wears out
  first: the resistor, the MOSFET, the mounting, or the sensor's
  contact? Justify it with a number.

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[A3.4]]

![[B5.3]]
%%curriculum-end%%
