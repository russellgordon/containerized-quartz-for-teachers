---
title: Switch a Load with a Transistor
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
A microcontroller pin is a decision, not a power source. Today you put a
transistor between the decision and the load, size the parts that make
it work, and then measure how much of your supply the switch itself
wastes. Two switches, the same lamp: a bipolar transistor and a
logic-level MOSFET, compared on the numbers rather than on which one
your neighbour used.

The lamp is chosen deliberately. A cold filament is a fraction of its
hot resistance, so the instant you switch it on it draws many times its
running current. Everything you design today has to survive that
moment, and nothing on the bench will tell you about it unless you go
looking.

> [!danger] Safety notes
> **The load gets its own supply.** Set the bench supply to
> $12\ \text{V}$ and its current limit to about $0.5\ \text{A}$
> *before* the first connection — the limit is not a safety net you add
> afterwards. **Tie the two grounds together and only the grounds**;
> without a common ground the transistor has no reference and the
> circuit does surprising things. **Never wire a load directly to a
> pin**, not even briefly to see what happens. **If your load is a
> relay, a solenoid, or a motor, a flyback diode goes across it**,
> banded end to the positive side — an inductive load switched off
> generates whatever voltage it takes to keep current flowing, and that
> is the end of your transistor. **The lamp gets hot enough to burn**
> and stays hot after power off. **No probing a powered board with
> loose leads**: clip your meter on with power off, then power up. Read
> the transistor's case temperature with the infrared thermometer, not
> a fingertip. Everything in [[Safety in the Lab]] applies on top of
> this.

## What you need

- [ ] A small $12\ \text{V}$ incandescent lamp, about $100\ \text{mA}$
      rated, in a holder that is bolted down
- [ ] A general-purpose NPN transistor and its datasheet
- [ ] A logic-level N-channel MOSFET and its datasheet — logic level
      matters, because an ordinary MOSFET will not turn fully on from a
      $3.3\ \text{V}$ gate
- [ ] Resistors: $470\ \Omega$ and $220\ \Omega$ quarter-watt, plus a
      $10\ \text{k}\Omega$ and a $100\ \text{k}\Omega$
- [ ] Microcontroller board, breadboard, jumper wires
- [ ] Bench supply, multimeter, oscilloscope, infrared thermometer,
      safety glasses

## Predict before you build

1. **Predict the load current.** The lamp's rating is a starting point;
   compute the hot resistance it implies,
   $R = V / I = 12 / 0.100 = 120\ \Omega$, then measure the lamp cold
   with the ohmmeter. The two numbers will not agree, and the ratio
   between them is the most useful thing you will learn today.
2. **Predict the inrush.** At the instant of switch-on the filament is
   still cold, so the current is set by the cold resistance you just
   measured. If it read $10\ \Omega$, predict
   $12 / 10 = 1.2\ \text{A}$ — twelve times the running current, for a
   few milliseconds until the filament heats.
3. **Size the base resistor.** A bipolar transistor is a current
   amplifier, and to drive it firmly into saturation you supply far
   more base current than its datasheet gain would demand. Design for a
   forced gain of about 20: $I_B = I_C / 20 = 100 / 20 = 5\ \text{mA}$.
   The pin drives through the resistor into a base that sits about
   $0.7\ \text{V}$ above ground, so
   $R_B = (3.3 - 0.7)\ \text{V} / 0.005\ \text{A} = 520\ \Omega$, and
   the nearest standard part below that is $470\ \Omega$, giving
   $I_B = 2.6 / 470 = 5.5\ \text{mA}$.
4. **Check the pin can supply it.** Find the maximum current per output
   pin in your board's datasheet — it is a real limit, not a guideline,
   and it is often smaller than students expect. If $5.5\ \text{mA}$ is
   uncomfortable against that limit, say so now and design for a forced
   gain of 30 instead.
5. **Predict the waste heat in each switch.** For the bipolar
   transistor, find $V_{CE(sat)}$ in the datasheet at your collector
   current — around $0.2$ to $0.3\ \text{V}$ is typical — so
   $P = V_{CE(sat)} \, I_C \approx 0.3 \times 0.1 = 30\ \text{mW}$. For
   the MOSFET, find $R_{DS(on)}$ at a gate drive of $3.3\ \text{V}$ and
   compute $P = I^2 R_{DS(on)}$; at $0.05\ \Omega$ that is
   $0.1^2 \times 0.05 = 0.5\ \text{mW}$. Write both down before you
   have any evidence.

## The work

6. Build the bipolar version with everything unpowered: lamp from the
   $12\ \text{V}$ rail to the collector, emitter to ground, base to the
   board's pin through $470\ \Omega$, and a $10\ \text{k}\Omega$ from
   base to ground so the lamp stays off while the board boots.
7. Tie the two grounds. Nothing else crosses between the supplies.
8. Power the load supply alone and confirm the lamp stays dark. If it
   lights, your pull-down is missing or your transistor is in backwards.
9. Power the board, switch the pin high, and measure, in this order:
   the current into the base, the current through the lamp, and the
   voltage from collector to emitter while it is on.
10. **Catch the inrush.** Put the scope across a small sense resistor in
    the load's ground return, or use a current probe if your bench has
    one, and switch the lamp on with the timebase set for a few
    milliseconds per division. Record the peak and how long it lasts.
11. Power down, rebuild with the MOSFET: gate to the pin through
    $220\ \Omega$, $100\ \text{k}\Omega$ from gate to ground, source to
    ground, drain to the lamp.
12. Repeat step 9, measuring gate current, lamp current, and the
    drain-to-source voltage while on.
13. Leave each version running for two minutes and read the case
    temperature of the switching device.

## Results

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Lamp cold resistance (Ω) | | |
| Lamp hot resistance, from V and I (Ω) | 120 | |
| Running current (mA) | 100 | |
| Inrush peak (A) | | |
| Inrush duration (ms) | | |
| Base current, bipolar (mA) | 5.5 | |
| $V_{CE(sat)}$ while on (V) | ≈ 0.3 | |
| Bipolar dissipation (mW) | ≈ 30 | |
| Gate current, MOSFET, steady state (mA) | ≈ 0 | |
| Drain-source voltage while on (mV) | | |
| MOSFET dissipation (mW) | | |
| Case temperature after 2 min (°C) | | |

## Predicted against measured

Start with the two you are most likely to have got wrong. The inrush
peak is often lower than the cold-resistance arithmetic predicts,
because the supply's own output impedance, the wiring, and the
transistor all limit it — and because the filament starts heating within
the first millisecond. The base current is often slightly *higher* than
predicted, because $V_{BE}$ is not exactly $0.7\ \text{V}$; look up the
real curve in the datasheet and see what your measured base current
implies about it.

If your $V_{CE(sat)}$ came out well above the datasheet figure, you are
not saturated. That means not enough base current, and it is the single
most common fault in this circuit: the lamp lights, so it looks like it
works, while the transistor quietly turns milliwatts into a warm case.
Reduce $R_B$, measure again, and watch the collector voltage fall.

Name a cause for every remaining gap. Resistor tolerance, supply
accuracy, meter burden voltage, and contact resistance in a breadboard
are all still on the table.

## The question that matters

The MOSFET wastes a fraction of the power the bipolar transistor does,
and it needs no steady drive current at all. Explain, in words a Grade
10 student would follow, why the bipolar transistor is nevertheless
still used everywhere — and name a situation where you would choose it
on purpose.

Then the design-margin questions. Give a number with each answer:

- The next version drives a load that draws $500\ \text{mA}$. What
  changes, and what is the first thing that stops being adequate?
- The device lives in a closed enclosure that reaches
  $50\ ^\circ\text{C}$. Look up the derating curve for your switch and
  say what current it is still good for there.
- Somebody switches this lamp on and off every ten seconds for a year.
  That is about three million inrush pulses. What in your circuit would
  you now specify differently, and why?

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[A3.3]]

![[B3.2]]
%%curriculum-end%%
