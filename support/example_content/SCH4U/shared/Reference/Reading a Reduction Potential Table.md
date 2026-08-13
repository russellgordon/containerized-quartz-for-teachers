---
title: Reading a Reduction Potential Table
draft: false
created: __CREATED__
enableToc: true
tags:
  - reference
  - electrochemistry
---
This page contains no potentials. The values come from **the data
booklet you are given**, and the skill worth having is knowing what a
row of that table entitles you to say.

It replaces the Grade 11 activity series, and it is a considerable
upgrade: the activity series told you the order, and this tells you the
order **and the size of the gap**. The chemistry is in
[[Galvanic and Electrolytic Cells]].

## Every entry is written as a reduction

Every line in the table has the same form — the oxidised species on the
left, electrons on the left, the reduced species on the right, and a
potential in volts:

$$\text{oxidised form} + n e^- \rightleftharpoons \text{reduced form} \qquad E^\circ$$

That is a convention, adopted so that every entry can be compared with
every other. It is not a claim that the reaction runs that way. In any
real cell one of your two chosen half-reactions is running **backwards**.

To use an entry as an oxidation:

1. **Reverse the equation** — the reduced form is now on the left.
2. **Change the sign** of $E^\circ$.

Do both or neither. Reversing without flipping the sign is the single
most productive source of wrong answers in Unit 5.

The zero point in the middle of the table is the **standard hydrogen
electrode**, assigned exactly 0.00 V by agreement rather than
measurement — because no half-cell potential can be measured on its own,
only against another. Every number in the table is a difference from
that reference.

## The two ends of the table

Assume for the moment that your booklet prints the most positive value
at the top. **Check that** — some sources sort the other way, and a few
older ones print oxidation potentials, in which case every sign is
reversed. The heading tells you; read it once at the start of the unit
rather than mid-question.

With the most positive at the top:

| End of the table | Potential | The species on the **left** of the row | The species on the **right** |
| --- | --- | --- | --- |
| Top | most positive | strongest **oxidising** agents — most easily reduced | weakest reducing agents |
| Bottom | most negative | weakest oxidising agents | strongest **reducing** agents — most easily oxidised |

Fluorine sits at or near the top, which says it takes electrons from
almost anything. Lithium sits at the bottom, which says the *metal* —
on the right of its row — gives electrons up more readily than anything
else on the sheet. Neither of those is a coincidence; they are
electronegativity and ionisation energy showing up in a different
measurement, exactly as [[The Blocks of the Periodic Table]] would
predict.

That gives the **diagonal rule** for spontaneity: a species on the
**left** of a higher row will react spontaneously with a species on the
**right** of a lower row. Draw the two rows, connect left-of-the-upper
to right-of-the-lower, and if the line runs down and to the left, it
happens.

Copper's row sits above zinc's. So copper ions on the left of the upper
row will react with zinc metal on the right of the lower row — copper is
reduced, zinc is oxidised, and that is precisely what you saw the strip
of zinc do in [[Building a Galvanic Cell]].

## Getting a cell potential out of it

Identify which half-reaction is the reduction — the one higher up the
table, if you want a spontaneous cell — and which is the oxidation. Then
take **both values straight from the table as printed reductions**, with
their printed signs, and subtract:

$$E^\circ_\text{cell} = E^\circ_\text{cathode} - E^\circ_\text{anode}$$

A **positive** answer means the reaction as written is spontaneous: a
galvanic cell that will drive a circuit. A **negative** answer means it
is not, and running it anyway needs a power supply providing at least
that voltage: an electrolytic cell.

Because the anode's value is subtracted, you do **not** separately
reverse its sign before substituting. Doing both is a double negative
and gives an answer that is wrong by twice the anode potential — a very
plausible-looking wrong answer, since it is still a number of about the
right size.

> [!warning] Never multiply a potential
> Balancing a redox equation requires multiplying half-equations so that
> the electrons cancel. That multiplication applies to the **equation**
> and to nothing else.
>
> $E^\circ$ is energy per unit of charge — a volt is a joule per
> coulomb. Doubling a half-equation doubles the energy *and* doubles the
> charge, so the ratio is unchanged. Potential is **intensive**, like
> temperature or density.
>
> Contrast $\Delta H$, which is **extensive** and is scaled when the
> equation is scaled. Two adjacent topics, two opposite rules. The
> question to ask is always: is this quantity "per something"? If it is,
> it does not scale.

## Five things the table does not tell you

**Nothing about rate.** A large positive $E^\circ_\text{cell}$ says a
reaction is favoured, not that it is quick. Aluminium's potential says
it should corrode readily and it visibly does not, because the oxide
layer stops the reaction rather than the thermodynamics — the argument
is on [[Corrosion and Electrolysis]], and it is the same argument about
kinetics against thermodynamics made in
[[Collision Theory and Catalysts]].

**Nothing outside standard conditions.** Every value assumes 1 mol/L
solutions, gases at standard pressure, and 25 °C. A cell that has been
running has consumed reactants and accumulated products, so its actual
voltage is lower than $E^\circ_\text{cell}$ — which is why a battery
fades rather than stopping abruptly.

**Nothing about which reaction wins in a mixture.** In an aqueous
electrolytic cell, water itself can be oxidised or reduced, and it
competes with whatever else is dissolved. The table lists the
candidates; predicting the winner in a real cell also needs the
concentrations and, in practice, an extra voltage that some electrode
reactions demand over and above the theoretical value.

**Nothing about how much product you get.** Potential is per electron.
The quantity of substance deposited or dissolved depends on the total
charge passed — current multiplied by time — which is a separate
calculation entirely.

**Nothing about safety.** A half-reaction with a modest potential can
still produce chlorine gas. Read [[Lab Safety and WHMIS]], not the
voltage column.

Practise pulling rows, assigning anode and cathode, and computing cell
potentials in [[Redox and Cells Practice]]. If reading a dense table is
itself the difficulty rather than the chemistry, start with
[[Reading a Data Table]].
