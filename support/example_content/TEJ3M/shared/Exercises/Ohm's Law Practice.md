---
title: Ohm's Law Practice
publish: true
created: __CREATED__
tags:
  - exercises
---
These follow [[Ohm's Law]] and the readings you took in
[[Measure a Circuit]]. Every answer below carries its units through the
working, and so should yours — volts divided by ohms is amperes, and if
your units do not land there, the working is wrong.

## Reading the law in every direction

1. A 470 Ω resistor sits across a 12 V supply. What current flows?
   Give the answer in amperes and in milliamperes.
2. A current of 15 mA passes through a 1.2 kΩ resistor. What voltage
   appears across it?
3. A component drops 3.3 V while carrying 22 mA. What resistance is it
   presenting?
4. A resistor marked 1 kΩ ±5 % is measured in a live circuit: 4.72 V
   across it, 4.55 mA through it. What resistance is it actually
   presenting, and is the part within its tolerance?

## Designing with it

5. A red LED with a forward drop of 1.8 V is to run at 15 mA from a 5 V
   supply. Calculate the series resistor, then choose the standard E12
   value you would actually fit and state the current that value gives.
6. Repeat for a blue LED with a forward drop of 3.2 V, running at 10 mA
   from the same 5 V supply. Comment on what you notice about the answer.
7. A green LED with a forward drop of 2.1 V is to run at 5 mA from a
   3.3 V rail. Calculate the ideal resistor, then work out the current
   you would get from the two nearest E12 values, 220 Ω and 270 Ω.
8. **Find the error.** Asked for the current in question 1, a classmate
   writes $I = V \times R = 12 \times 470 = 5640\ \text{A}$ and moves
   on. Name both mistakes.

## Answers

> [!success]- Answer 1
> $I = \frac{V}{R} = \frac{12\ \text{V}}{470\ \Omega} \approx 0.0255\ \text{A}$, which is $25.5\ \text{mA}$. A perfectly ordinary bench current — small enough to be safe, large enough to light something.

> [!success]- Answer 2
> Convert first, then substitute: 15 mA is $0.015\ \text{A}$ and 1.2 kΩ is $1200\ \Omega$, so $V = IR = 0.015\ \text{A} \times 1200\ \Omega = 18\ \text{V}$.
>
> Watch the two unit conversions. Working in milliamps and kilohms
> without converting is the single most common way this question goes
> wrong — although notice that mA multiplied by kΩ happens to give volts
> directly, which is a shortcut worth knowing once you can prove it.

> [!success]- Answer 3
> $R = \frac{V}{I} = \frac{3.3\ \text{V}}{0.022\ \text{A}} = 150\ \Omega$ exactly — and 150 Ω is a standard E12 value, which is not a coincidence. Someone designed that circuit around a part they could buy.

> [!success]- Answer 4
> $R = \frac{V}{I} = \frac{4.72\ \text{V}}{0.00455\ \text{A}} \approx 1037\ \Omega$.
>
> Now judge it. A 1 kΩ part with ±5 % tolerance is allowed to be
> anywhere from 950 Ω to 1050 Ω. The measured 1037 Ω is
> $\frac{1037 - 1000}{1000} = 3.7\ \%$ high, so the part is well inside
> its band and is not the fault you are looking for. This is the whole
> point of question 4: "not exactly 1000" and "out of specification" are
> different findings.

> [!success]- Answer 5
> The LED takes 1.8 V, so the resistor gets what is left: $5\ \text{V} - 1.8\ \text{V} = 3.2\ \text{V}$. Then $R = \frac{3.2\ \text{V}}{0.015\ \text{A}} \approx 213\ \Omega$.
>
> 213 Ω is not a value you can buy. Go *up* to the next E12 value, 220 Ω,
> because rounding up lowers the current and rounding down raises it —
> and the current is the thing you were protecting the LED from. Fitting
> 220 Ω gives $I = \frac{3.2\ \text{V}}{220\ \Omega} \approx 14.5\ \text{mA}$, comfortably close to the 15 mA you asked for.

> [!success]- Answer 6
> $R = \frac{5\ \text{V} - 3.2\ \text{V}}{0.010\ \text{A}} = \frac{1.8\ \text{V}}{0.010\ \text{A}} = 180\ \Omega$, which is exactly an E12 value — no rounding needed.
>
> The thing to notice: a blue LED leaves only 1.8 V for the resistor
> where the red one left 3.2 V. Less headroom means the resistor value is
> more sensitive to the LED's actual forward drop, and blue LEDs vary
> more from part to part than red ones do. On a 5 V rail this is fine; on
> a 3.3 V rail a blue LED leaves almost nothing to work with, which is
> why datasheet values matter more as the supply drops.

> [!success]- Answer 7
> Ideal value: $R = \frac{3.3\ \text{V} - 2.1\ \text{V}}{0.005\ \text{A}} = \frac{1.2\ \text{V}}{0.005\ \text{A}} = 240\ \Omega$. That is an E24 value but not an E12 one, so from an E12 drawer you must choose either side.
>
> With 220 Ω: $I = \frac{1.2\ \text{V}}{220\ \Omega} \approx 5.45\ \text{mA}$ — about 9 % over target.
>
> With 270 Ω: $I = \frac{1.2\ \text{V}}{270\ \Omega} \approx 4.44\ \text{mA}$ — about 11 % under.
>
> Either is entirely safe for the LED. Take 270 Ω if you care about
> battery life and 220 Ω if you want the brighter indicator, and write
> down which and why. That sentence is what an engineering decision looks
> like.

> [!success]- Answer 8
> **The algebra.** Solving $V = IR$ for current gives $I = \frac{V}{R}$ — division, not multiplication. The correct answer is $25.5\ \text{mA}$.
>
> **The sanity check that never happened.** $5640\ \text{A}$ is arc-welding territory, delivered by a bench supply into a quarter-watt resistor. A number you cannot picture happening is a number to stop and question, and that reflex is worth more than the algebra.

Take the same arithmetic to a real circuit in [[Predict the Circuit]],
where the meter gets the last word, and to
[[Series and Parallel Practice]] when one resistor stops being enough.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.3]]
%%curriculum-end%%
