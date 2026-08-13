---
title: Calorimetry
draft: false
created: __CREATED__
enableToc: true
tags:
  - concepts
  - energy
---
[[Enthalpy]] told you what $\Delta H$ means. It did not tell you where
the number comes from, and every number in every thermochemistry table
ever printed began as somebody watching a thermometer.

In [[Calorimetry of a Neutralisation]] you were that somebody. A
polystyrene cup, a lid, a thermometer, two solutions of known
concentration, and a temperature that moved. This page turns that
reading into a value in kilojoules per mole.

## One equation, four symbols

$$Q = mc\Delta T$$

$Q$ is the heat gained or lost by a substance, in joules. The three
symbols on the right are the only things you need to measure.

- $m$ — the **mass of the thing whose temperature changed**. In a
  solution calorimetry experiment that is the mass of the *solution*,
  not the mass of the solute and not the mass of the cup. This is the
  symbol most often filled in wrongly.
- $c$ — the **specific heat capacity**: the energy needed to raise one
  gram of that substance by one degree. For water it is
  4.18 J/(g·°C), and it is unusually large, which is exactly why water
  is what calorimeters are filled with and why a lake takes until August
  to warm up.
- $\Delta T$ — the temperature change, always the final temperature
  minus the initial one. A difference in degrees Celsius and a
  difference in kelvins are the same number, so no conversion is needed
  here.

Read the three together and the meaning is plain: how much energy a
sample soaks up depends on how much of it there is, what it is made of,
and how far its temperature moved.

## Turning $Q$ into $\Delta H$

Two steps, and both of them are where marks are lost.

**Step one — flip the sign.** $Q$ as calculated above is the heat gained
by the *solution*. The reaction is the system; the solution is the
surroundings. Whatever one gained, the other lost:

$$Q_\text{reaction} = -Q_\text{solution}$$

**Step two — divide by the amount.** $Q$ is in joules for the quantity
you happened to use. A molar enthalpy has to be per mole, so divide by
the moles of the substance the value is *about*, and convert to
kilojoules:

$$\Delta H = \frac{-Q_\text{solution}}{n}$$

The phrase "the substance the value is about" is doing work. An enthalpy
of neutralisation is per mole of water formed. An enthalpy of combustion
is per mole of fuel burned. An enthalpy of solution is per mole of
solute dissolved. Read the name of the quantity to find out what to
divide by.

## A calculation, all the way through

Equal volumes of 1.00 mol/L hydrochloric acid and 1.00 mol/L sodium
hydroxide, 50.0 mL of each, both starting at 21.0 °C. Mixed in a
polystyrene calorimeter, the highest temperature reached is 27.7 °C.
Find the molar enthalpy of neutralisation.

Work out what you know before you reach for the equation: the total
volume is 100.0 mL, the temperature rose by 6.7 °C, and each solution
contained 0.0500 mol.

> [!success]- The full working, once you have tried it
> Assume the dilute solution has the density and specific heat capacity
> of water, so its mass is 100.0 g and $c$ is 4.18 J/(g·°C).
>
> $$\begin{aligned} Q_\text{solution} &= mc\Delta T \\ &= (100.0)(4.18)(6.7) \\ &= 2.8 \times 10^{3} \ \text{J} \end{aligned}$$
>
> The neutralisation is one to one, so 0.0500 mol of acid reacts with
> 0.0500 mol of base to form 0.0500 mol of water.
>
> $$\begin{aligned} \Delta H &= \frac{-2.8 \times 10^{3}\ \text{J}}{0.0500\ \text{mol}} \\ &= -5.6 \times 10^{4}\ \text{J/mol} \\ &= -56\ \text{kJ/mol} \end{aligned}$$
>
> Two significant figures, because $\Delta T$ had two — the two
> temperatures were each read to a tenth of a degree, and subtracting
> them left only 6.7. Everything else in the calculation was known to
> three figures or better and none of it helps.
>
> The sign is negative and the thermometer went **up**. Those two
> statements agree, and if yours do not, you have skipped the flip.

Notice that 6.7 is where all the uncertainty in that answer lives. Two
readings good to three significant figures were subtracted and produced
a difference good to two. That is what
[[Significant Figures and Units]] means about subtraction, and it is why
[[Measuring Well]] insists on reading a thermometer properly rather than
quickly.

## What the coffee cup is not telling you

Every calorimetry answer rests on assumptions, and a Grade 12 lab report
states them rather than hiding them.

| Assumption made | What it ignores | Which way the error goes |
| --- | --- | --- |
| The solution has water's density and $c$ | dissolved ions change both slightly | small, either way |
| The calorimeter absorbs no heat | the cup and thermometer warm up too | measured rise too small |
| No heat escapes to the room | it does, through the lid and walls | measured rise too small |
| The reaction is complete and instant | mixing takes a few seconds | measured rise too small |

Read the right-hand column. Three of the four errors push the same way,
so a simple polystyrene calorimeter almost always returns a **magnitude
of $\Delta H$ that is too small**. That is not a random error to be
averaged away by repeating the experiment; it is a systematic one, and
the honest way to handle it is to say so and to compare against an
accepted value rather than claiming agreement.

A serious calorimeter is calibrated so that the apparatus's own heat
capacity is known and can be added in. And an open cup works at constant
atmospheric pressure, which is the condition under which heat measured
*is* the enthalpy change — a sealed, rigid calorimeter measures
something slightly different.

> [!danger] Combustion calorimetry is a demonstration
> Burning a fuel under a can of water is a classic experiment and it
> involves an open flame, a flammable liquid, and hot metal that looks
> identical to cold metal. In this course it is done at the front, by
> your teacher, unless the procedure you are given is explicitly written
> for student hands. Eye protection stays on for the whole
> demonstration, including the cleaning up.

Practise the arithmetic and the sign conventions in
[[Enthalpy Practice]]. Then go to [[Hess's Law]], which exists because
there are reactions whose $\Delta H$ nobody can measure this way — too
slow, too violent, or producing something other than what you wanted.

%%curriculum-start%%
## Curriculum connection

![[D3.3]]

![[D2.3]]
%%curriculum-end%%
