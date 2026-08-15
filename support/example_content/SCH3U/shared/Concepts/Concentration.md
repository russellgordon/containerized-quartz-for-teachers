---
title: Concentration
publish: true
created: __CREATED__
enableToc: true
tags:
  - concepts
  - solutions
---
Two beakers of copper(II) sulfate solution sat at the front of the room,
one pale blue and one nearly navy. Same compound, same solvent, same
temperature. Everybody could see the difference and nobody could put a
number on it, which is the problem this page solves.

[[Water and Solutions]] explained *whether* something dissolves.
Concentration is *how much*, and it is the point at which solutions stop
being descriptive chemistry and start feeding into the calculations from
[[Stoichiometry]].

## Concentration is a ratio, and both numbers matter

The concentration a chemist reaches for first is **molar
concentration**: amount of solute in moles, divided by volume of
solution in litres.

$$c = \frac{n}{V}$$

Its units are mol/L, and it is written in square brackets when you are
naming a species — $[\ce{Cl-}] = 0.20$ mol/L means the chloride ion
concentration is 0.20 mol/L.

Two traps live in that one small equation.

**The volume is litres, not millilitres.** Every piece of glassware in
the room is calibrated in millilitres and every concentration is per
litre, so a division by 1000 has to happen somewhere and it is the most
frequently forgotten step in the unit.

**It is volume of solution, not volume of solvent.** Dissolving
something changes the volume — sometimes up, occasionally down. This is
why a standard solution is made in a volumetric flask: you dissolve the
solid in less water than you need, then top up to the etched line, so
the final *solution* is exactly the stated volume. Measuring out 250 mL
of water and then adding solid to it gives you a solution of unknown
volume and therefore unknown concentration. That is the whole reason
[[Preparing a Standard Solution]] is done the way it is done.

A worked example. Dissolve 5.85 g of sodium chloride and make it up to
250.0 mL:

$$n = \frac{5.85 \text{ g}}{58.44 \text{ g/mol}} = 0.1001 \text{ mol} \qquad c = \frac{0.1001 \text{ mol}}{0.2500 \text{ L}} = 0.400 \text{ mol/L}$$

## Other units, and when each one is used

Molar concentration is the one that goes into equations. It is not the
one on most labels, because most labels are not written for people doing
stoichiometry.

| Unit | What it means | Where you meet it |
| --- | --- | --- |
| mol/L | moles of solute per litre of solution | anything feeding a balanced equation; titration work |
| g/L or g/100 mL | grams of solute per litre, or per 100 mL, of solution | solubility tables and curves |
| % (m/v) | grams per 100 mL of solution, as a percentage | saline, disinfectants, medical solutions |
| % (v/v) | millilitres per 100 mL of solution | mixtures of liquids — alcohol content |
| ppm | one part per million by mass | trace metals, chlorine in tap water |
| ppb | one part per billion by mass | contaminants measurable at very low levels |

Parts per million deserves a note, because it is the unit almost every
environmental measurement is reported in and it looks more mysterious
than it is. One part per million is one gram of solute in one million
grams of solution. For **dilute aqueous solutions**, one litre of
solution has a mass of very nearly one kilogram, which is $10^6$
milligrams — so 1 ppm is 1 mg/L. That equivalence is a convenience of
water's density and it does not transfer to other solvents.

The reason to care is that guideline limits for metals and other
contaminants in drinking water are published in milligrams per litre.
Being out by a factor of a thousand between mg/L and g/L is not a
rounding error; it is the difference between safe and not, and it is
exactly the kind of unit reasoning [[The Water Report]] will ask you to
be careful with.

## Dilution conserves moles

Add water to a solution and the concentration falls. Nothing else
changes: no solute is created and none is destroyed, so the **number of
moles of solute is the same before and after**. That single sentence is
the entire derivation.

Since $n = cV$ and $n$ is unchanged,

$$c_1V_1 = c_2V_2$$

Use 0.400 mol/L stock to make 100.0 mL of a more dilute solution: take
10.0 mL of the stock and add water to the 100.0 mL mark. The
concentration is

$$c_2 = \frac{c_1V_1}{V_2} = \frac{(0.400)(10.0)}{100.0} = 0.0400 \text{ mol/L}$$

Note that the volumes appear on both sides, so as long as you use the
same unit throughout, millilitres are fine here. Dilution is the one
place in this unit where you do not have to convert.

> [!warning] Add acid to water, never water to acid
> Diluting a concentrated acid releases a substantial amount of heat.
> Pour acid slowly into a large volume of water and that heat is spread
> through the water, which has a high heat capacity, and the mixture
> warms gently. Pour water into concentrated acid and the heat is
> released in the small volume of the first drop, which can boil
> instantly and spit concentrated acid out of the container and up at
> your face.
>
> Add acid to water. Stir. Use the dilute reagents supplied, never
> concentrated stock, and never return unused solution to the stock
> bottle — see [[Lab Safety and WHMIS]].

## Concentration in a stoichiometry problem

Nothing about the road in [[Stoichiometry]] changes. Concentration is
simply a third way onto it, alongside mass and — later — gas volume.

$$n = \frac{m}{M} \qquad n = cV \qquad n = \frac{N}{6.022 \times 10^{23}}$$

Three doors into the same room. Once you have moles, everything works
the way it always did: mole ratio from the coefficients, then back out
through whichever door the question wants.

This matters immediately, because the two techniques the rest of the
unit is built on are both stoichiometry with $n = cV$ at the front:
finding out how much precipitate two solutions will produce, in
[[Precipitation and Net Ionic Equations]], and finding an unknown
concentration by reacting it with a known one, in
[[Titrating an Acid]].

Get the conversions fluent in [[Concentration Practice]] first — the
chemistry in this unit is straightforward and almost every lost mark is
a factor of 1000.

%%curriculum-start%%
## Curriculum connection

![[E2.2]]
%%curriculum-end%%
