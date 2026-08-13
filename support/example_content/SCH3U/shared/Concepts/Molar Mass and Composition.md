---
title: Molar Mass and Composition
draft: false
created: __CREATED__
enableToc: true
tags:
  - concepts
  - quantities
---
[[The Mole]] built the bridge between mass and count, and then used it
only on elements — one mole of iron, one mole of carbon, read straight
off the periodic table. Almost nothing you weigh out in this room is an
element. This page extends the bridge to compounds, and then turns it
around: instead of asking what a compound weighs, it asks what fraction
of that weight is each element.

That second question is the one an analytical chemist is usually paid to
answer. How much iron is in this ore, how much nitrogen is in this
fertiliser, how much water is in this crystal.

## Molar mass of a compound is a sum

The **molar mass** $M$ of a compound is the sum of the molar masses of
every atom in its formula, in grams per mole. That is all it is. The
subscripts multiply, and anything in brackets multiplies through.

Sulfuric acid, $\text{H}_2\text{SO}_4$: two hydrogens at 1.01, one
sulfur at 32.07, four oxygens at 16.00.

$$M = 2(1.01) + 32.07 + 4(16.00) = 98.09 \text{ g/mol}$$

Calcium nitrate, $\text{Ca(NO}_3\text{)}_2$: one calcium, and then
*two* nitrate groups, each of which is one nitrogen and three oxygens.

$$M = 40.08 + 2\left[14.01 + 3(16.00)\right] = 164.10 \text{ g/mol}$$

The bracket is where marks are lost. Two nitrate ions means two
nitrogens and six oxygens, not two nitrogens and three.

With $M$ in hand, everything from [[The Mole]] works unchanged:
$n = \frac{m}{M}$ going one way, $m = n \times M$ going the other, and
$N = n \times 6.022 \times 10^{23}$ when you want particles. The only
new skill is the addition.

## Percentage composition

The **percentage composition** of a compound is the percentage of its
mass contributed by each element. For one element $\text{X}$:

$$\%\,\text{X} = \frac{\text{mass of X in one mole of the compound}}{\text{molar mass of the compound}} \times 100\%$$

Because it is a ratio of masses, it does not matter how much of the
substance you have. Any pure sample of a compound has the same
percentage composition, which is why the number identifies a substance
and a mass does not.

> [!example] Worked: the water in blue copper sulfate
> Copper(II) sulfate pentahydrate, $\text{CuSO}_4 \cdot 5\text{H}_2\text{O}$,
> is the blue crystal. The dot means five water molecules are built into
> the crystal structure — they are part of the formula, not
> contamination.
>
> $\begin{aligned} M(\text{CuSO}_4) &= 63.55 + 32.07 + 4(16.00) = 159.62 \text{ g/mol} \\ M(5\text{H}_2\text{O}) &= 5\left[2(1.01) + 16.00\right] = 90.10 \text{ g/mol} \\ M(\text{total}) &= 159.62 + 90.10 = 249.72 \text{ g/mol} \end{aligned}$
>
> So the water is $\frac{90.10}{249.72} \times 100\% = 36.08\%$ of the
> mass, and the copper is
> $\frac{63.55}{249.72} \times 100\% = 25.45\%$.
>
> More than a third of that blue crystal is water you cannot see, and
> you can drive it off with a burner and weigh the difference.

## From a measurement to a percentage

The calculation above is theoretical — it comes from a formula somebody
already knew. The experiment runs the other way: you measure masses and
find out what the percentage actually is, which is the point of
[[Finding an Empirical Formula]].

Heating a hydrate is the clean version. Weigh the crucible, weigh it
with the hydrate in it, heat it, let it cool, and weigh it again. The
mass lost is the water. Two details make the difference between a result
and a number:

**Heat to constant mass.** Heat, cool, weigh, and then heat again and
weigh again. When two successive masses agree to within the balance's
resolution, the water is gone. Stopping after one heating is guessing,
and it always guesses low.

**Cool before weighing, every time.** Hot air rises off hot glassware
and pushes up on the pan, so a hot crucible reads light. It also
damages the balance. Cool it on a heatproof mat or in a desiccator, and
give it the same amount of time each round so the comparison is fair.

When your measured percentage misses the theoretical one, the direction
of the miss is informative rather than embarrassing:

- **Measured percentage of water too low** — you did not drive it all
  off, or the sample reabsorbed moisture from the air before you
  weighed it.
- **Measured percentage of water too high** — you overheated and
  decomposed the compound itself, or some of the solid spattered out of
  the crucible, or the crucible was still hot.

Say which you think happened and what evidence points at it. That is the
whole difference between a Grade 10 lab report and a Grade 11 one, and
it is the standard set in [[Writing a Lab Report]].

> [!warning] Hot crucibles look exactly like cold ones
> Use tongs for everything, put hot ware down only on a heatproof mat
> and never on the bench, and do not lean over a crucible while it is
> being heated in case the contents spit. Eye protection stays on until
> everyone in the room has finished heating, not until you have.

## Where this goes

Percentage composition is the bridge to the next idea rather than an end
in itself. If you can measure the mass of each element in a sample, you
can find the ratio in which their atoms combine — and that ratio is the
compound's formula, worked out from nothing but a balance. That is
[[Empirical and Molecular Formulas]].

Before that, get the conversions automatic in
[[Mole Conversions Practice]], and make sure the sig-fig rules in
[[Significant Figures and Units]] are not costing you marks on answers
that are otherwise right.

%%curriculum-start%%
## Curriculum connection

![[D2.2]]

![[D2.3]]
%%curriculum-end%%
