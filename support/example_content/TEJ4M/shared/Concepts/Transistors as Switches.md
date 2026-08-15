---
title: Transistors as Switches
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[Switch a Load with a Transistor]] two benches wired the same relay,
the same transistor, and the same board. One relay clicked and one
buzzed, and the transistor on the buzzing bench was warm. The difference
was a single resistor value, chosen by feel on one bench and calculated
on the other. This page is that calculation.

## Saturation is a design condition, not a hope

Used as a switch, a bipolar transistor has exactly two states you want:
fully off, and **saturated** — hard on, with only a few tenths of a volt
across it. In between is the linear region, where the transistor behaves
like a resistor, dissipates real power, and gets hot. A switch that
lingers there is a heater with an identity crisis.

Saturation is not something the transistor decides. You force it by
supplying more base current than the transistor strictly needs:

$$I_B \geq k \times \frac{I_C}{h_{FE(\text{min})}}$$

where $k$ is an overdrive factor, conventionally somewhere between 2 and
10 in design practice. Two details in that expression carry the whole
Grade 12 point. Use $h_{FE}$ **minimum**, at the collector current you
are actually running — gain falls at high current, varies enormously
between parts of the same type, and the "typical" figure describes a part
you did not necessarily buy. And use an overdrive factor deliberately,
because the datasheet's saturation voltage is itself specified at a
stated ratio of base to collector current.

## Sizing the base resistor

A relay coil draws 90 mA from 12 V. The datasheet guarantees
$h_{FE} \geq 50$ at that collector current. A 3.3 V logic pin drives the
base through a resistor.

$$I_{B(\text{min})} = \frac{90\ \text{mA}}{50} = 1.8\ \text{mA}$$

Take an overdrive factor of 5, so $I_B = 9\ \text{mA}$. The resistor sees
the pin voltage less the base–emitter drop, about 0.7 V when conducting:

$$R_B = \frac{3.3\ \text{V} - 0.7\ \text{V}}{9\ \text{mA}} = \frac{2.6\ \text{V}}{0.009\ \text{A}} \approx 289\ \Omega$$

The nearest standard value below that is 270 Ω, giving
$2.6 / 270 = 9.6\ \text{mA}$ and an overdrive factor of 5.3 — round *down*
in resistance here, because more base current is the safe direction for
saturation.

With the transistor saturated at, say, 0.3 V, it dissipates
$0.3\ \text{V} \times 0.090\ \text{A} = 27\ \text{mW}$, which nothing
needs to worry about. Leave it half-on at 6 V instead and it dissipates
0.54 W — twenty times as much, in the same little package. That is the
buzzing bench.

> [!success]- Check yourself: the same load on a 5 V pin *(click to expand)*
> The base resistor sees $5\ \text{V} - 0.7\ \text{V} = 4.3\ \text{V}$,
> so for the same 9 mA of base current
> $R_B = 4.3 / 0.009 \approx 478\ \Omega$, and 470 Ω is the standard
> value to fit — giving $4.3 / 470 \approx 9.1\ \text{mA}$.
>
> Notice what did **not** change: the base current you need is set by the
> load and the transistor's gain, never by the logic voltage. The logic
> voltage only decides the resistor that delivers it.

## When the pin cannot supply the base current

Now check the other end. Nine milliamps out of one pin is a lot. Many
microcontroller pins are specified for something in the region of 8 to
12 mA each, with a further limit on the total across all pins — and those
are absolute maximums, not operating targets. Design a circuit that needs
9 mA from a pin rated for 8 mA and you have designed a circuit that fails
its own datasheet before it is built.

Three honest ways out:

1. **Lower the overdrive factor** to 3, needing 5.4 mA and a 470 Ω
   resistor. Legal, but you have spent your margin.
2. **Use a Darlington pair or a driver IC**, whose enormous current gain
   needs only a fraction of a milliamp at the input. You pay in a higher
   saturation voltage, so recheck the dissipation.
3. **Use a MOSFET**, which needs essentially no steady gate current at
   all — the usual modern answer.

## MOSFETs and the gate threshold trap

A MOSFET's gate is a capacitor, not a diode. Hold it above threshold and
the channel conducts; the steady current into the gate is negligible.
That makes it the obvious choice for a 3.3 V microcontroller — with one
condition that catches nearly everybody.

The on-resistance in the headline is quoted at a stated gate voltage.
Many common power MOSFETs quote $R_{DS(\text{on})}$ at
$V_{GS} = 10\ \text{V}$; drive that part's gate with 3.3 V and it is
barely turned on, with an on-resistance that may be ten times higher or
worse. **Logic-level** MOSFETs are the category specified for full
enhancement at gate voltages a logic pin can supply — check the
$R_{DS(\text{on})}$ line and confirm it is specified at a gate voltage
you actually have.

The arithmetic is unforgiving. Switching 2 A through a part that is
properly enhanced at 0.05 Ω dissipates

$$P = I^2 R = (2\ \text{A})^2 \times 0.05\ \Omega = 0.2\ \text{W}$$

but the same 2 A through a partly-enhanced 0.5 Ω dissipates 2 W — ten
times the heat, from choosing the part by its price instead of its
conditions. That habit is [[Component Selection and Tolerances]] and
[[Reliability and Derating]] arriving together.

Two more rules that keep boards alive, both carried forward from Grade 11
and both now your responsibility to justify rather than obey:

- **A pull-down resistor on the gate**, typically tens to hundreds of
  kilohms, holds the switch off while the microcontroller is resetting
  and its pins are floating inputs. Without it, a motor can start during
  boot.
- **A flyback diode across every inductive load** — relay coil, solenoid,
  motor — fitted so it does not conduct in normal operation. Switching
  off a coil produces a reverse spike that will punch straight through
  the transistor otherwise.

Work the numbers in [[Transistor and Op-Amp Practice]], prove them with a
meter and a scope in [[Switch a Load with a Transistor]], and put the
driver calculation in the design review package for [[The Interface]] —
"it worked" is not the deliverable, the margin is.

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[A3.3]]

![[B3.2]]
%%curriculum-end%%
