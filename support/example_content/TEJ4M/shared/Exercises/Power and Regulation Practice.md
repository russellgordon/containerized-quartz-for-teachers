---
title: Power and Regulation Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Power Supplies and Regulation]] and
[[Reliability and Derating]], and they are the arithmetic behind
[[Build a Regulated Supply]]. Carry the units. A dissipation figure with
no watts on it has already lost the argument, and a junction temperature
you did not calculate is a part you are about to destroy.

## Dissipation, heat, and efficiency

1. A linear regulator supplies 5.0 V at 300 mA from a 12 V input.
   Calculate the power dissipated in the regulator, the power delivered
   to the load, and the efficiency.
2. That regulator's package has a junction-to-ambient thermal resistance
   of 62 °C/W in still air. The maximum junction temperature is 125 °C
   and the enclosure runs at 40 °C. Calculate the junction temperature,
   say whether the design is acceptable, and give the largest
   junction-to-ambient thermal resistance that would be.
3. A heat sink brings the total junction-to-ambient figure to 8 °C/W.
   Recalculate the junction temperature in the same 40 °C enclosure.
4. Instead of a heat sink, the input is changed to 7.5 V. Calculate the
   new dissipation and efficiency, and name one thing this change puts
   at risk.
5. A switching regulator of 85% efficiency replaces the linear part, on
   the same 12 V input and the same 5 V, 300 mA load. Calculate the
   input power, the input current, and the power lost as heat. How many
   times more heat did the linear regulator produce?

## Dropout, ripple, and setting the output

6. The 5 V regulator has a dropout voltage of 2.0 V at this load. A
   battery pack starts at 9.0 V and falls to 6.5 V as it discharges,
   sagging a further 0.4 V while the radio transmits. At what pack
   voltage does the output stop being 5.0 V, and what will a user
   observe first?
7. A full-wave rectified 60 Hz supply feeds a reservoir capacitor and
   then the regulator, at a load of 300 mA. Calculate the capacitance
   needed to keep the ripple to 1.0 V peak-to-peak, and then to 0.5 V.
   Which of those numbers does the dropout calculation in question 6
   care about?
8. An adjustable regulator sets its output by
   $V_{\text{out}} = V_{\text{ref}}\left(1 + \frac{R_2}{R_1}\right)$
   with $V_{\text{ref}} = 1.25\ \text{V}$ and $R_1 = 240\ \Omega$.
   Calculate $R_2$ for exactly 5.00 V, choose a standard 5% value, and
   state the resulting output and its percentage error. Then find the
   worst-case output if both resistors are ± 1%.
9. **Find the error.** A group reports: "We built the supply, measured
   5.02 V on the output, and it passes." Their circuit is the 12 V to
   5 V, 300 mA design from question 1, with no heat sink, and the
   measurement was taken with nothing connected to the output. List
   everything wrong with the claim and give the test they should have
   run.

## Answers

> [!success]- Answer 1
> The regulator drops the difference between input and output while
> passing the full load current.
>
> $P_{\text{regulator}} = (12\ \text{V} - 5\ \text{V}) \times 0.300\ \text{A} = 2.1\ \text{W}$
>
> $P_{\text{load}} = 5\ \text{V} \times 0.300\ \text{A} = 1.5\ \text{W}$
>
> $P_{\text{input}} = 12\ \text{V} \times 0.300\ \text{A} = 3.6\ \text{W}$, so the efficiency is $\frac{1.5}{3.6} \approx 41.7\%$.
>
> More than half the energy is heating the regulator. That is not a fault in the part — it is what a linear regulator *is*.

> [!success]- Answer 2
> Thermal resistance behaves like Ohm's law with watts for current and degrees for volts.
>
> $\Delta T = P \times \theta_{JA} = 2.1\ \text{W} \times 62\ ^\circ\text{C/W} \approx 130.2\ ^\circ\text{C}$
>
> $T_j = 40\ ^\circ\text{C} + 130.2\ ^\circ\text{C} \approx 170\ ^\circ\text{C}$
>
> **Not acceptable** — 170 °C is well past the 125 °C maximum. A good part will shut down thermally and produce a device that works for a few minutes at a time; a lesser one will degrade and eventually fail.
>
> For $T_j \leq 125\ ^\circ\text{C}$ at 40 °C ambient, the budget is $125 - 40 = 85\ ^\circ\text{C}$, so
>
> $\theta_{JA(\text{max})} = \frac{85\ ^\circ\text{C}}{2.1\ \text{W}} \approx 40.5\ ^\circ\text{C/W}$
>
> And that is the *destruction* limit. Designing to 100 °C instead — which is what [[Reliability and Derating]] would have you do — requires $\frac{60}{2.1} \approx 28.6\ ^\circ\text{C/W}$.

> [!success]- Answer 3
> $\Delta T = 2.1\ \text{W} \times 8\ ^\circ\text{C/W} = 16.8\ ^\circ\text{C}$, so $T_j = 40 + 16.8 \approx 56.8\ ^\circ\text{C}$.
>
> Comfortable, with about 68 °C of margin to the maximum. Note what the heat sink did and did not do: the regulator still wastes 2.1 W — the energy has not gone anywhere — but the junction now sits at a temperature the part can live at indefinitely.

> [!success]- Answer 4
> $P = (7.5\ \text{V} - 5\ \text{V}) \times 0.300\ \text{A} = 0.75\ \text{W}$, and the efficiency rises to $\frac{5}{7.5} \approx 66.7\%$.
>
> Dissipation falls to about a third, and in the same 62 °C/W package the rise is $0.75 \times 62 \approx 46.5\ ^\circ\text{C}$, giving a junction near 87 °C at 40 °C ambient — acceptable without a heat sink.
>
> **What it puts at risk:** headroom. With a 2 V dropout the input must stay above 7 V, and 7.5 V leaves only 0.5 V of margin for ripple, supply tolerance, and sag under load. Solving a thermal problem by moving toward the dropout limit means you must now do question 6's arithmetic honestly.

> [!success]- Answer 5
> Efficiency relates output power to input power, so work backwards from the load.
>
> $P_{\text{out}} = 5\ \text{V} \times 0.300\ \text{A} = 1.5\ \text{W}$
>
> $P_{\text{in}} = \frac{1.5\ \text{W}}{0.85} \approx 1.765\ \text{W}$
>
> $I_{\text{in}} = \frac{1.765\ \text{W}}{12\ \text{V}} \approx 0.147\ \text{A} = 147\ \text{mA}$
>
> $P_{\text{lost}} = 1.765 - 1.5 \approx 0.265\ \text{W}$
>
> The linear part lost 2.1 W, so it produced about **8 times** as much heat. Note the input current too: 147 mA against 300 mA. A switching regulator does not pass the load current straight through, which is exactly why battery life improves rather than merely the temperature.

> [!success]- Answer 6
> The regulator needs $V_{\text{out}} + V_{\text{dropout}} = 5.0 + 2.0 = 7.0\ \text{V}$ at its input, at every instant.
>
> With a 0.4 V sag during transmission, the pack must stay above $7.0 + 0.4 = 7.4\ \text{V}$ for the output to hold during a transmission. So:
>
> - Above 7.4 V: regulation holds always.
> - Between 7.0 V and 7.4 V: the output drops out **only while transmitting**.
> - Below 7.0 V: the output follows the input down continuously.
>
> **What the user observes first** is the intermittent case, and it is vicious: the device resets or misbehaves during transmission and works perfectly in between, so the fault appears to be in the radio code. The pack still reads a healthy 7.2 V on a meter afterwards.
>
> Note also that a pack falling to 6.5 V spends the end of its life outside the design entirely — the useful capacity is smaller than the datasheet's, and the specification should say so.

> [!success]- Answer 7
> The capacitor supplies the load between peaks. A full-wave rectified 60 Hz supply peaks 120 times a second, so the gap is $\frac{1}{120} \approx 8.33\ \text{ms}$. From $I = C\frac{dV}{dt}$:
>
> $C = \frac{I \times \Delta t}{\Delta V} = \frac{0.300\ \text{A} \times 0.00833\ \text{s}}{1.0\ \text{V}} = 2.5 \times 10^{-3}\ \text{F} = 2500\ \mu\text{F}$
>
> For 0.5 V of ripple, $C = 5000\ \mu\text{F}$ — halving the ripple doubles the capacitance, every time.
>
> **Which number matters for dropout:** the **trough**, not the average or the peak. With 1 V of ripple the input dips 1 V below its peak 120 times a second, and if the trough falls below $V_{\text{out}} + V_{\text{dropout}}$ the output has a 120 Hz disturbance on it that a slow meter will never show you. Measure the input with a scope, AC-coupled, and look at the bottom of the waveform.

> [!success]- Answer 8
> Rearranging for $R_2$:
>
> $R_2 = R_1\left(\frac{V_{\text{out}}}{V_{\text{ref}}} - 1\right) = 240\ \Omega \times \left(\frac{5.00}{1.25} - 1\right) = 240 \times 3 = 720\ \Omega$
>
> 720 Ω is not in the 5% (E24) series. The neighbours are 680 Ω and 750 Ω:
>
> With 750 Ω: $V_{\text{out}} = 1.25\left(1 + \frac{750}{240}\right) = 1.25 \times 4.125 \approx 5.156\ \text{V}$ — high by **3.1%**.
>
> With 680 Ω: $V_{\text{out}} = 1.25\left(1 + \frac{680}{240}\right) \approx 4.79\ \text{V}$ — low by 4.2%.
>
> Choose 750 Ω if the load tolerates a high rail, 680 Ω if it does not — and if neither is acceptable, that is the argument for 1% resistors from the E96 series, where 715 Ω and 732 Ω exist.
>
> **Worst case with ± 1% parts**, taking 750 Ω high and 240 Ω low, is $1.25\left(1 + \frac{757.5}{237.6}\right) \approx 5.235\ \text{V}$; the other extreme gives about 5.08 V. So the real output is roughly 5.08 – 5.24 V, and a 3.3 V device downstream fed from a rail specified at "5 V" is being fed by something you should describe honestly in the specification.

> [!success]- Answer 9
> **What is wrong with the claim:**
>
> The measurement was taken with **no load**. A linear regulator holds its output beautifully at zero current, so 5.02 V no-load proves only that the reference works. Every failure mode of interest — dropout, sag, thermal shutdown — appears under load.
>
> There is **no thermal evidence**. At 300 mA the part dissipates 2.1 W, which in this package without a heat sink puts the junction near 170 °C. The device may well measure 5.02 V for the first thirty seconds and then shut down.
>
> There is **no input measurement**. The claim says nothing about the input voltage under load, its ripple, or whether it stays above the dropout limit.
>
> There is **no acceptance test**. "It passes" is a verdict without a criterion; nobody stated what the output was required to be.
>
> **The test they should have run:**
>
> 1. State the criterion first: output within a stated tolerance of 5.00 V, from no load to the full 300 mA, with the input at its minimum and the enclosure closed.
> 2. Load the output to 300 mA with a resistive load, and measure the output voltage with a meter and the ripple with a scope.
> 3. Measure the input voltage under that load, at the trough of the ripple.
> 4. Run for at least 30 minutes with the enclosure closed and measure the regulator's case temperature.
> 5. Record all four measurements, with the load, the input voltage, and the ambient temperature written beside them.
>
> Every one of those numbers goes in the build log. "It passes" is not a measurement — and the habit of proving it under the conditions of use is what [[The Specification]] is marked on.

Bring the thermal arithmetic to [[Build a Regulated Supply]] before you
switch anything on, and put the calculated junction temperature next to
the measured case temperature in your [[Tech Journal]]. When those two
disagree, one of them is teaching you something.

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[B3.2]]
%%curriculum-end%%
