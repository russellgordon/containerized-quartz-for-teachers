---
title: Transistor and Op-Amp Practice
publish: true
created: __CREATED__
tags:
  - exercises
---
These follow [[Transistors as Switches]] and [[Operational Amplifiers]],
and they are the numbers you need before
[[Switch a Load with a Transistor]] and [[Amplify a Sensor]] can be more
than wiring. Every
answer here is a design decision with arithmetic behind it — say which
standard value you would fit, and why you rounded the way you did.

## Switching a load

1. A relay coil draws 90 mA from a 12 V rail. The transistor's datasheet
   guarantees $h_{FE} \geq 50$ at that collector current. Calculate the
   minimum base current, then the base current for an overdrive factor
   of 5.
2. That base is driven from a 3.3 V logic pin through a resistor, with
   $V_{BE} \approx 0.7\ \text{V}$ when conducting. Calculate the base
   resistor, choose a standard value, and say which way you rounded and
   why.
3. The microcontroller's datasheet gives an absolute maximum of 8 mA per
   pin. Does your design from question 2 pass? Give three different ways
   to fix it, with the cost of each.
4. Repeat question 2 for a 5 V logic pin driving the same base current.
   What changed, and what did not?
5. The transistor saturates at $V_{CE} = 0.3\ \text{V}$. Calculate the
   power dissipated in it while the relay is on. Then calculate the
   dissipation if insufficient base current left it half-on at
   $V_{CE} = 6\ \text{V}$, and comment.
6. A logic-level MOSFET is specified at an on-resistance of
   $0.05\ \Omega$ with $V_{GS} = 4.5\ \text{V}$. Calculate its
   dissipation switching a 2 A load. A cheaper part specified only at
   $V_{GS} = 10\ \text{V}$ presents about $0.5\ \Omega$ when driven from
   3.3 V — calculate that dissipation and say what you would observe.

## Amplifying a signal

7. A non-inverting amplifier uses $R_f = 100\ \text{k}\Omega$ and
   $R_g = 10\ \text{k}\Omega$. Calculate the gain and the output for a
   0.20 V input.
8. An inverting amplifier uses $R_f = 220\ \text{k}\Omega$ and
   $R_{\text{in}} = 22\ \text{k}\Omega$, on a single 0 – 5 V supply.
   Calculate the gain and the output for a 0.15 V input. What will the
   circuit actually do, and why?
9. A sensor produces 0 – 20 mV and must fill the 0 – 3.3 V input range
   of a converter. Design a non-inverting stage: give the required gain,
   choose $R_g = 1\ \text{k}\Omega$ and calculate $R_f$, then fit the
   nearest standard 5% value and state the resulting gain and
   full-scale output.
10. The op-amp in question 9 has a gain–bandwidth product of 1 MHz.
    Calculate the bandwidth of your single stage. Then split the gain
    across two identical stages of gain 13 and calculate the bandwidth
    of each. What did splitting cost you?

## Answers

> [!success]- Answer 1
> Saturation is forced, not hoped for, and the calculation uses the
> **minimum** guaranteed gain because that is the only number the
> manufacturer promises.
>
> $I_{B(\text{min})} = \frac{I_C}{h_{FE(\text{min})}} = \frac{90\ \text{mA}}{50} = 1.8\ \text{mA}$
>
> With an overdrive factor of 5: $I_B = 5 \times 1.8\ \text{mA} = 9.0\ \text{mA}$.
>
> Using the *typical* gain instead — often several times higher — would give a base current that saturates the transistors that happen to be good and leaves the rest dissipating heat.

> [!success]- Answer 2
> The resistor takes whatever the base does not.
>
> $R_B = \frac{V_{\text{pin}} - V_{BE}}{I_B} = \frac{3.3\ \text{V} - 0.7\ \text{V}}{0.009\ \text{A}} = \frac{2.6\ \text{V}}{0.009\ \text{A}} \approx 289\ \Omega$
>
> Fit **270 Ω**, the nearest standard value *below* 289 Ω. Rounding down in resistance rounds *up* in current: $\frac{2.6\ \text{V}}{270\ \Omega} \approx 9.6\ \text{mA}$, an overdrive factor of $\frac{9.6}{1.8} \approx 5.3$.
>
> Round the safe way. Too much base current costs a few milliamps and a fraction of a milliwatt in the base; too little leaves the transistor in its linear region, where it becomes a heater.

> [!success]- Answer 3
> **No.** The design asks for 9.6 mA from a pin whose absolute maximum is 8 mA — and an absolute maximum is a destruction limit, not a target, so the honest design margin is worse than the 20% overrun suggests.
>
> **Fix 1 — reduce the overdrive factor to 3.** $I_B = 3 \times 1.8 = 5.4\ \text{mA}$, so $R_B = \frac{2.6}{0.0054} \approx 481\ \Omega$; fit 470 Ω, giving 5.5 mA and a factor of 3.1. *Cost:* it works, but you have spent your margin, and a transistor at the low end of its gain spread is now closer to leaving saturation.
>
> **Fix 2 — use a Darlington pair or a driver IC.** Current gain in the thousands means a fraction of a milliamp at the input. *Cost:* a higher saturation voltage (often around 1 V), so recheck the dissipation — at 90 mA that is 90 mW rather than 27 mW.
>
> **Fix 3 — use a logic-level MOSFET.** Essentially no steady gate current at all. *Cost:* you must confirm $R_{DS(\text{on})}$ is specified at a gate voltage you actually have, and fit a gate pull-down so the load stays off during reset.
>
> Fix 3 is the usual modern answer, and it is the one to defend at a design review.

> [!success]- Answer 4
> $R_B = \frac{5.0\ \text{V} - 0.7\ \text{V}}{0.009\ \text{A}} = \frac{4.3\ \text{V}}{0.009\ \text{A}} \approx 478\ \Omega$, so fit **470 Ω**, giving $\frac{4.3}{470} \approx 9.1\ \text{mA}$.
>
> **What changed:** the resistor, because the voltage available across it changed.
>
> **What did not:** the base current you need. That is set by the load current and the transistor's minimum gain, and it has nothing whatever to do with the logic voltage. Students who memorise "470 Ω for a transistor" have memorised the answer to one question and will apply it to a different one.

> [!success]- Answer 5
> Saturated: $P = V_{CE} \times I_C = 0.3\ \text{V} \times 0.090\ \text{A} = 0.027\ \text{W} = 27\ \text{mW}$. Nothing to worry about in any package.
>
> Half-on: $P = 6\ \text{V} \times 0.090\ \text{A} = 0.54\ \text{W}$ — **twenty times** the heat, in the same small package, from one resistor chosen badly.
>
> That is the whole reason for the overdrive factor. A transistor used as a switch spends its life at one end or the other; the linear region between them is where the power goes, and a device that is "working, just a bit warm" is a device that is being destroyed slowly, exactly as [[Reliability and Derating]] describes.

> [!success]- Answer 6
> Properly enhanced: $P = I^2 R = (2\ \text{A})^2 \times 0.05\ \Omega = 4 \times 0.05 = 0.2\ \text{W}$.
>
> Barely enhanced: $P = (2\ \text{A})^2 \times 0.5\ \Omega = 2.0\ \text{W}$ — ten times as much.
>
> **What you would observe:** a MOSFET that gets hot enough to smell, a voltage drop of $2\ \text{A} \times 0.5\ \Omega = 1.0\ \text{V}$ across a switch that should drop $2 \times 0.05 = 0.1\ \text{V}$, and a load running on a volt less than it should. Measure drain-to-source with the load on: if it is not a small fraction of a volt, the gate is not being driven properly.
>
> The lesson is the condition column of the datasheet. "$R_{DS(\text{on})} = 0.05\ \Omega$" is meaningless until you read the gate voltage it was measured at — the argument in [[Component Selection and Tolerances]], costing 1.8 W here.

> [!success]- Answer 7
> $G = 1 + \frac{R_f}{R_g} = 1 + \frac{100\ \text{k}\Omega}{10\ \text{k}\Omega} = 1 + 10 = 11$
>
> $V_{\text{out}} = 11 \times 0.20\ \text{V} = 2.2\ \text{V}$
>
> Check it against the supply before you believe it: 2.2 V is fine on a 5 V rail and impossible on a 3.3 V rail if the part cannot swing that close to its positive rail.

> [!success]- Answer 8
> $G = -\frac{R_f}{R_{\text{in}}} = -\frac{220\ \text{k}\Omega}{22\ \text{k}\Omega} = -10$, so arithmetically $V_{\text{out}} = -10 \times 0.15\ \text{V} = -1.5\ \text{V}$.
>
> **What the circuit actually does:** it cannot produce $-1.5$ V, because on a single 0 – 5 V supply there is no negative rail for the output to move toward. The output sits as low as the part can go — at or just above 0 V — and stays there. The stage looks like a dead sensor or a broken op-amp, and it is neither.
>
> **Fixes:** use a split supply so the output has somewhere negative to go; or bias the + input to mid-rail (2.5 V) so that "zero signal" sits in the middle of the range and the output swings either side of 2.5 V; or use the non-inverting configuration, which does not invert the sign in the first place.
>
> This is the single most common op-amp failure in student work, and it is a supply-rail question rather than a gain question.

> [!success]- Answer 9
> **Required gain:** $G = \frac{3.3\ \text{V}}{0.020\ \text{V}} = 165$.
>
> **Feedback resistor:** rearranging $G = 1 + \frac{R_f}{R_g}$ gives $R_f = (G - 1)R_g = 164 \times 1\ \text{k}\Omega = 164\ \text{k}\Omega$.
>
> **Standard value:** 164 kΩ is not in the 5% series; fit **160 kΩ**, giving $G = 1 + \frac{160}{1} = 161$ and a full-scale output of $0.020\ \text{V} \times 161 = 3.22\ \text{V}$.
>
> Rounding *down* in gain is deliberate: 3.22 V leaves a little headroom below the 3.3 V reference, whereas 180 kΩ would give a gain of 181 and a full-scale demand of 3.62 V, which the converter cannot represent and the op-amp probably cannot produce. The residual gain error is corrected by calibration, and the measured gain — not the nominal one — is the number that goes in your code and your log.

> [!success]- Answer 10
> Gain–bandwidth product is roughly constant, so the bandwidth is the product divided by the closed-loop gain.
>
> **One stage:** $f = \frac{1\ \text{MHz}}{161} \approx 6.2\ \text{kHz}$. Ample for a temperature sensor; useless for audio.
>
> **Two stages of gain 13:** total gain $13 \times 13 = 169$, and each stage has $f = \frac{1\ \text{MHz}}{13} \approx 77\ \text{kHz}$ — more than ten times the bandwidth for a slightly higher total gain.
>
> **What splitting cost you:** a second op-amp (often free, since they come in pairs), a second set of resistors and their tolerances, more board area, and more noise sources. Also note that two cascaded stages each rolling off at 77 kHz give a combined response that starts falling before 77 kHz, so the honest overall figure is somewhat lower than each stage's.
>
> Which you choose depends on the requirement. Design the gain from the signal, check the bandwidth against the signal, and only cascade when the check fails — which is the order [[Writing a Specification]] insists on.

Take the winning design from question 3 to
[[Switch a Load with a Transistor]] and measure the base current, the
saturation voltage, and the case temperature. A calculation that survives
a meter is evidence; one that has never met a meter is homework.

%%curriculum-start%%
## Curriculum connection

![[A3.2]]

![[A3.3]]

![[B3.2]]
%%curriculum-end%%
