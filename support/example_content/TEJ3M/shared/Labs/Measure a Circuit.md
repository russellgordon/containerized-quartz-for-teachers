---
title: Measure a Circuit
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
One resistor, one supply, and a meter — and by the end of the period a
table that nobody dictated to you. You will set the supply to six
different voltages, measure the current each time, and take those numbers
away to graph. Next class the graph turns into [[Ohm's Law]], but today
nobody says that name. Today you are just an honest instrument attached to
a circuit.

The equipment is the lesson as much as the circuit is.
[[Using a Multimeter]] is the manual; read it before you touch the dial,
because the single most common way to ruin a period is to measure current
the way you measure voltage.

> [!danger] Safety notes
> **The bench supply only** — never wall power, never a supply you did
> not set yourself. Set the **current limit** to about $50\ \text{mA}$
> before the first connection; a limit is a mistake that stays small.
> **Never place the meter in current mode across a supply.** In current
> mode the meter is nearly a piece of wire, and connecting a wire across
> a supply is a short circuit — it blows the meter's internal fuse at
> best. **Measure resistance only with power off** and the resistor out
> of the circuit; an ohmmeter puts its own small voltage out, and a live
> circuit gives a meaningless reading. **Move the red lead back** to the
> V/Ω jack the moment you finish a current measurement, per
> [[Safety in the Lab]].

## What you need

- [ ] Bench supply with an adjustable current limit
- [ ] One $470\ \Omega$ quarter-watt resistor — check the
      colour bands, then check them with the meter
- [ ] Breadboard and jumper wires
- [ ] Digital multimeter with test leads, and safety glasses

## Predict before you measure

1. **Measure the resistor cold**, out of circuit, and write the value
   down. That measured value — not the printed one — is what your
   predictions use.
2. **Predict the current at every supply voltage** in the table below,
   before anything is connected. If your measured resistor is
   $468\ \Omega$, then at $3.00\ \text{V}$ you expect
   $I = 3.00\ \text{V} / 468\ \Omega = 0.00641\ \text{A}$, which is
   $6.41\ \text{mA}$. Six rows, six numbers, all in milliamps, in pen.
3. **Sanity-check the power** before you energise anything. At
   $6\ \text{V}$ the resistor dissipates
   $P = V^2 / R = 36 / 468 \approx 0.077\ \text{W}$, comfortably inside
   a quarter-watt part. That calculation is what stops a resistor from
   turning into smoke.

## The work

4. Build the loop with the supply **off**: supply positive, resistor,
   back to supply negative. One loop, nothing else.
5. Break the loop and put the meter **in series** for current — red lead
   in the current jack, dial on mA. The meter must be part of the loop,
   because current flows *through* it.
6. Set the supply to $1.00\ \text{V}$. Record the current. Step through
   $2, 3, 4, 5$, and $6\ \text{V}$, recording each time.
7. Now move the meter to **parallel** across the resistor and record the
   voltage actually across it at each setting. This is not the same as
   the supply's front-panel number, and finding out why is part of today.
8. Power off, leads back to the V/Ω jack, resistor measured once more
   while it is warm.

## Results

| Supply set (V) | Predicted $I$ (mA) | Measured $I$ (mA) | Measured $V$ across $R$ (V) | $V/I$ (Ω) |
| --- | --- | --- | --- | --- |
| 1.00 | | | | |
| 2.00 | | | | |
| 3.00 | | | | |
| 4.00 | | | | |
| 5.00 | | | | |
| 6.00 | | | | |

## Predicted against measured

Work out the percent difference for every row — measured minus
predicted, divided by predicted, times one hundred — and then account
for it. Every one of these is a real, checkable cause, and
at least two of them are in your data today:

- **Resistor tolerance.** A gold band means ±5 %, so a
  $470\ \Omega$ part may honestly be anywhere from $446$ to
  $494\ \Omega$. This is why you predicted from the *measured* value.
- **The supply is not exactly where the dial says.** Measure it; front
  panels round.
- **Burden voltage.** The ammeter has resistance of its own, so a little
  of your supply voltage is dropped across the meter instead of the
  resistor. This is why column four is not equal to column one.
- **Contact and lead resistance.** Breadboard springs and clip leads add
  a fraction of an ohm each, and they add up.
- **Warming.** A resistor's value drifts slightly as it heats.

## The question that matters

Plot measured current against measured voltage, with current on the
vertical axis. What shape do the points make, and what does the shape of
that graph claim about the resistor? Then find a bench with a different
resistor value and compare graphs. What is the same, what is different,
and what does the steepness of each line have to do with the number
printed on the part?

Bring the graph to the next class. You are one period away from being
able to name what you found.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.3]]

![[B3.2]]
%%curriculum-end%%
