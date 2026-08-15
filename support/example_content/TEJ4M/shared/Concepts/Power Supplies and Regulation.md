---
title: Power Supplies and Regulation
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[Build a Regulated Supply]] the output was a beautiful, steady 5.00 V
and the regulator was too hot to keep a finger on. Both facts came from
the same arithmetic, and a supply that is right on the meter and wrong on
the thermometer is not finished.

## The missing volts turn into heat

A linear regulator works by dropping whatever voltage it has to in order
to hold the output where you asked. It does not convert the excess — it
burns it. The current that leaves the output came in through the input,
so the power dissipated in the regulator is

$$P = (V_{\text{in}} - V_{\text{out}}) \times I_{\text{load}}$$

Twelve volts in, five volts out, 300 mA of load:

$$P = (12\ \text{V} - 5\ \text{V}) \times 0.300\ \text{A} = 2.1\ \text{W}$$

while the load itself receives only 1.5 W, since
$5\ \text{V} \times 0.300\ \text{A} = 1.5\ \text{W}$. The efficiency is
$1.5 / 3.6 \approx 42\%$; more of your battery is heating the regulator
than running the circuit.

Then ask what 2.1 W does to the part. If the package has a
junction-to-ambient thermal resistance of 62 °C/W in free air, the
junction sits

$$\Delta T = 2.1\ \text{W} \times 62\ ^\circ\text{C/W} \approx 130\ ^\circ\text{C}$$

above ambient. In a 40 °C enclosure that is a junction at about 170 °C,
well past the 125 °C maximum typical of these parts. The regulator will
shut itself down thermally if it is a good one and die quietly if it is
not. Bolt it to a heat sink that brings the total to 8 °C/W and the rise
is 16.8 °C — junction at about 57 °C, which is a design.

> [!danger] Supplies bite after you switch them off
> Anything with a mains transformer has live conductors you must treat as
> live, and the filter capacitors in a supply store real energy for
> minutes after the power is removed. Discharge and *verify* with a meter
> before you touch a rail — the industry standard is to prove it dead,
> not to assume it. Never work inside a supply alone, keep one hand
> behind your back when probing anything you have not proven dead, and
> follow the practices in [[Safety in the Lab]] and
> [[Bench Power Supply Habits]]. This is not classroom caution; it is
> [[D1.1|the health and safety expectation the course is built on]].

## Dropout sets the floor under your input

A regulator needs a minimum voltage across itself to regulate at all.
That figure — the **dropout voltage** — is stated at a particular load
current and temperature, and if the input falls below
$V_{\text{out}} + V_{\text{dropout}}$, the output simply follows the
input down.

With a 5 V output and a 2 V dropout, the input must never fall below 7 V:
not at the bottom of the ripple, not at the end of the battery's life,
not during the current spike when a motor starts. A pack that starts at
9 V and sags to 6.5 V under load has spent part of its life outside the
design and produced an unexplainable brown-out reset in the middle of it.

Low-dropout parts exist and cost you something else — usually a fussier
output capacitor and a specified equivalent series resistance you have to
respect. Everything is a trade.

## Linear or switching

| | Linear | Switching |
| --- | --- | --- |
| How it works | Burns the difference | Chops and stores energy, then averages it |
| Efficiency (12 V → 5 V) | About 42% here | Commonly 80 – 90% |
| Heat at 300 mA | 2.1 W in the regulator | About 0.26 W at 85% |
| Noise | Very low | Switching ripple at the chopping frequency |
| Complexity | Three parts | Inductor, layout discipline, more to get wrong |

At 85% efficiency the switcher delivers the same 1.5 W while drawing
$1.5 / 0.85 \approx 1.76\ \text{W}$ from the 12 V rail — about 147 mA in
rather than 300 mA, and roughly one-eighth the wasted heat. That is why
anything battery-powered switches. It is also why the analog front end in
[[Operational Amplifiers]] often gets its own small linear regulator
downstream of a switcher: the switcher's noise is a real signal, and
[[Filters and Noise]] is about the trouble it causes.

## Ripple, and the capacitor that hides it

Rectified AC is not DC. A reservoir capacitor holds the voltage up
between peaks, and it discharges into the load while it does. From
$I = C \frac{dV}{dt}$, rearranged for the capacitance you need:

$$C = \frac{I \times \Delta t}{\Delta V} = \frac{0.300\ \text{A} \times 8.33\ \text{ms}}{1\ \text{V}} = 2500\ \mu\text{F}$$

using the 8.33 ms between peaks of a full-wave rectified 60 Hz supply.
Ask for half the ripple and you need twice the capacitance — and the
ripple trough, not the peak, is the number the dropout rule above cares
about.

Design a supply, then, in this order: load current first (with the
worst-case peak, not the average), then the output voltage and its
tolerance, then the minimum input including ripple and battery sag, then
the dissipation and the thermal path, and only then the part number.
[[Power and Regulation Practice]] runs that sequence numerically until it
is automatic, and [[The Interface]] expects you to have done it before
anything is plugged into your board.

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[A3.3]]

![[B3.2]]

![[D1.1]]
%%curriculum-end%%
