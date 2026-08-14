---
title: Empirical and Molecular Formulas
draft: false
created: __CREATED__
enableToc: true
tags:
  - concepts
  - quantities
---
In [[Finding an Empirical Formula]] you weighed a strip of magnesium,
burned it in a crucible, and weighed what was left. Two masses, a
balance, and a burner — and out of that comes the formula of a compound
you never saw made. That is worth stopping on. You did not look at the
atoms. You counted them, indirectly, by weighing.

## Empirical means the ratio, molecular means the molecule

Two different questions, two different answers, and they are often not
the same answer.

The **empirical formula** is the simplest whole-number ratio of atoms in
the compound. The **molecular formula** is the actual number of each
kind of atom in one molecule.

Glucose is $\ce{C6H12O6}$. Its atoms are in the
ratio 1 : 2 : 1, so its empirical formula is $\ce{CH2O}$ —
which is also the empirical formula of methanal, of ethanoic acid, and
of several sugars that are not glucose. An empirical formula alone does
not identify a compound, and that is not a flaw in the idea; it is the
honest limit of what a mass measurement can tell you.

Two cases where the distinction disappears:

- **Ionic compounds have no molecular formula at all**, because they
  have no molecules. $\ce{NaCl}$ and $\ce{CaCl2}$ are empirical
  formulas describing a lattice ratio, as
  [[Ionic and Covalent Bonding]] set out. There is nothing more to find.
- **Some molecules are already at their simplest ratio.** Water is
  $\ce{H2O}$ both ways; there is no $\ce{HO}$ to reduce to.

## The procedure

Everything below is one idea repeated: **masses tell you nothing about
ratios, and moles tell you everything.** Sixteen grams of oxygen and
sixteen grams of sulfur are not equal numbers of atoms. One mole of each
is.

- [ ] Start with masses in grams. If you were given percentages instead,
      assume a 100 g sample — then every percentage *is* a mass in
      grams, and you have lost nothing, because the ratio does not
      depend on how much you have.
- [ ] Divide each element's mass by that element's molar mass. You now
      have moles of each.
- [ ] Divide every one of those mole values by the smallest of them. The
      smallest becomes 1 and the others become ratios to it.
- [ ] If any result is not close to a whole number, multiply *all* of
      them by the smallest factor that clears the fraction: 2 for a
      .5, 3 for a .33 or .67, 4 for a .25 or .75.
- [ ] Write the whole numbers as subscripts. That is the empirical
      formula.
- [ ] Given a molar mass for the real compound, divide it by the
      empirical formula mass and multiply every subscript by the whole
      number you get. That is the molecular formula.

Your magnesium result runs through it in four lines. Suppose 0.243 g of
magnesium gave 0.403 g of oxide. The oxygen was not weighed directly —
it came out of the air — so you get it by subtraction: 0.160 g.

$$n(\ce{Mg}) = \frac{0.243}{24.31} = 0.0100 \text{ mol} \qquad n(\ce{O}) = \frac{0.160}{16.00} = 0.0100 \text{ mol}$$

Divide both by the smaller and you get 1 : 1. The formula is
$\ce{MgO}$ — which is also what the charges predict, $\ce{Mg^2+}$
with $\ce{O^2-}$, so two completely independent methods agree. When
that happens, believe the result.

A percentage example, for the more usual case. A compound is 40.0%
carbon, 6.7% hydrogen, and 53.3% oxygen by mass. Take 100 g:

$$\frac{40.0}{12.01} = 3.33 \qquad \frac{6.7}{1.01} = 6.63 \qquad \frac{53.3}{16.00} = 3.33$$

Divide by 3.33 and you get 1 : 1.99 : 1, which is 1 : 2 : 1, so the
empirical formula is $\ce{CH2O}$.

## From empirical to molecular

The empirical formula gives you the shape of the ratio. To get the real
molecule you need one more piece of information from outside the mass
data — the **molar mass of the compound**, which comes from a separate
measurement.

$$\text{multiplier} = \frac{\text{molar mass of the compound}}{\text{molar mass of the empirical formula}}$$

For the compound above, $\ce{CH2O}$ has a molar mass of
30.03 g/mol. If a separate experiment says the compound's molar mass is
180.16 g/mol, then

$$\frac{180.16}{30.03} = 6.00$$

and the molecular formula is $\ce{C6H12O6}$ —
glucose. Had the measured molar mass been 60.05, the multiplier would
be 2 and the compound would be ethanoic acid instead. Same empirical
formula, same percentage composition, different substance.

The multiplier is always a whole number, because a molecule contains a
whole number of atoms. If you calculate 3.4, something is wrong with an
input, and no amount of rounding will fix it honestly.

## When the numbers are not whole

This is where the method gets a reputation for being fiddly, and the
fiddliness is real. After dividing by the smallest, you will get
something like 1.00, 1.33, 2.51. Deciding what those mean is a judgement
call, so here is how to make it defensibly.

**Round when you are within about 0.02.** A ratio of 1.99 is 2. A ratio
of 3.01 is 3. Measurement noise of that size is expected, and pretending
otherwise produces absurd formulas like $\ce{C199H398}$.

**Multiply when you are near a familiar fraction.** 1.50 is not 2 and
must never be rounded to 2 — it is $\frac{3}{2}$, so multiply
everything by 2. Likewise 1.33 means multiply by 3, and 2.25 means
multiply by 4. The check is that *every* value must become whole, not
just the awkward one.

**Stop and think when you are in between.** A value of 1.6 is not near
anything simple. That is the number telling you something went wrong
upstream: a mass recorded incorrectly, an incomplete reaction, a product
that absorbed water before it was weighed, or a sample that was not
pure. Chasing it with a multiplier of 5 to force $\ce{C5}$ is how you
end up defending a formula that does not exist.

> [!note] Say what the data cannot support
> If your magnesium oxide comes out at $\ce{Mg1O_{1.3}}$,
> the useful sentence is not "so the formula is $\ce{MgO}$" and it is
> certainly not "$\ce{Mg10O13}$". It is: "the ratio came
> out at 1 : 1.3, higher in oxygen than $\ce{MgO}$ requires, which is
> consistent with some magnesium nitride forming as well since the
> crucible was open to the air." That sentence gets full marks. The
> other two do not.

Drill the procedure in [[Empirical Formula Practice]] until the five
steps run without you looking them up. Then [[Stoichiometry]] takes the
formula you now trust and puts it through a balanced equation.

%%curriculum-start%%
## Curriculum connection

![[D3.3]]

![[D2.4]]
%%curriculum-end%%
