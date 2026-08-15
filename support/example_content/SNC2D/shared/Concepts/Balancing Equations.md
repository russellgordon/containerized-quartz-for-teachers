---
title: Balancing Equations
publish: true
created: __CREATED__
tags:
  - concepts
---
In [[Balancing by Counting]] your group massed a sealed bag before and
after the reaction inside it fizzed. The mass did not change. Nothing
left, nothing arrived — the atoms rearranged, and every one of them was
still in the bag. That measurement is the whole reason equations have
to balance: a chemical equation that does not balance is a claim that
atoms appeared or vanished, and your own bag says otherwise.

## What an unbalanced equation is claiming

Write the reaction between hydrogen and oxygen the naive way:

$$\ce{H2 + O2 -> H2O}$$

Count the atoms on each side. Two hydrogens on the left, two on the
right — fine. But **two** oxygens on the left and only **one** on the
right. Written that way, the equation says one oxygen atom ceased to
exist. Balancing is not a ritual; it is fixing a false statement.

$$\ce{2H2 + O2 -> 2H2O}$$

Now: four hydrogens each side, two oxygens each side. The equation
finally says what the bag said.

## The one rule people break

You may change **coefficients** — the big numbers in front. You may
never change **subscripts** — the small numbers inside a formula.

| Change | What it does | Allowed? |
| --- | --- | --- |
| $\ce{H2O} \to \ce{2H2O}$ | Two water molecules instead of one | Yes |
| $\ce{H2O} \to \ce{H2O2}$ | A different substance entirely | No |

Changing a subscript does not balance the equation — it swaps one
chemical for another. Hydrogen peroxide is not water with extra oxygen
along for the ride; it is a substance that bleaches hair and
decomposes on your shelf. The formula is the substance's identity, and
you do not get to edit somebody's identity to make your arithmetic
work.

## A method that always terminates

- [ ] Count every element on both sides, in a table. Write the counts
      down; do not hold them in your head.
- [ ] Balance the element that appears in the fewest formulas first.
- [ ] Leave pure elements (such as $\ce{O2}$ or $\ce{Na}$) until last —
      they are the easiest to adjust without disturbing anything else.
- [ ] Recount everything. Every time.
- [ ] Check the coefficients share no common factor:
      $\ce{4H2 + 2O2 -> 4H2O}$ is balanced
      but not in lowest terms.

> [!example]- Worked: the combustion of methane
> Start with $\ce{CH4 + O2 -> CO2 + H2O}$.
> Carbon is already balanced (one each side). Hydrogen: four on the
> left, two on the right, so put a 2 in front of water —
> $\ce{CH4 + O2 -> CO2 + 2H2O}$.
> Now recount oxygen: two in $\ce{CO2}$ plus two in
> $\ce{2H2O}$ makes four on the right, two on the left. Put a
> 2 in front of $\ce{O2}$:
> $$\ce{CH4 + 2O2 -> CO2 + 2H2O}$$
> Final count: 1 C, 4 H, 4 O on each side. Balanced, and in lowest
> terms.

## Why this matters beyond the page

Every quantitative claim in chemistry rests on a balanced equation —
how much oxygen a furnace needs, how much carbon dioxide a fuel
releases, whether a reaction can produce what somebody claims it can.
When you read a number about emissions in [[The Climate Brief]], a
balanced equation is somewhere underneath it. Practise until the
counting is automatic in [[Balancing Practice]], then sort real
reactions by what they do in [[Types of Chemical Reactions]].

%%curriculum-start%%
## Curriculum connection

![[C3.2]]

![[C3.4]]

![[C2.4]]
%%curriculum-end%%
