---
title: Precipitation and Net Ionic Equations
draft: false
created: __CREATED__
enableToc: true
tags:
  - concepts
  - solutions
---
You have already made a precipitate. In
[[Percentage Yield of a Precipitate]] two clear solutions went into a
beaker and a solid appeared out of nowhere, and you filtered it, dried
it, and weighed it. What that page did not say is what was actually
happening in the beaker — because most of what you poured in took no
part in the reaction at all.

This page is about writing down only the part that changed.

## Why anything precipitates

Start from [[Water and Solutions]]. A dissolved ionic compound is not
sitting in the water as tiny lumps of solid; it has come apart, and each
ion is drifting independently, wrapped in its own shell of water
molecules. Sodium chloride solution contains no sodium chloride. It
contains $\text{Na}^+$ and $\text{Cl}^-$, going their separate ways.

Now pour in a second solution. Its ions arrive and everything mixes.
Four kinds of ion are now present and each cation meets each anion many
times a second. Nothing happens — unless one particular pairing has an
attraction for each other strong enough to beat what the water is
offering. That pair drops out of solution as a solid, and keeps dropping
out until almost none is left dissolved.

Which pairings do that is not something you can reason out from the
periodic table; it was measured, and the results are tabulated in
[[Solubility Rules]]. Using the table is the second step of every
prediction, exactly as in [[Predicting Products]]:

1. Swap the partners to get the two possible products.
2. Look up each one. If either is insoluble, it precipitates.
3. If both are soluble, write **no reaction** — and mean it.

> [!info] What a solubility table is really claiming
> "Insoluble" is a threshold, not an absolute. The usual convention is
> that a compound is called soluble if more than about 0.1 mol/L
> dissolves, and insoluble below that. Silver chloride is called
> insoluble and a genuinely tiny amount of it does dissolve. This is
> why a precipitation reaction never quite recovers 100% of the
> theoretical yield, and it is one of the honest explanations available
> to you in [[Limiting Reagent and Yield]].

## Three ways to write the same reaction

Take silver nitrate solution mixed with sodium chloride solution. There
are three equations for it and each says something the others do not.

The **full equation** — sometimes called the molecular equation, which
is a poor name given that none of these is a molecule — writes every
compound in its complete form:

$$\text{AgNO}_3\text{(aq)} + \text{NaCl(aq)} \rightarrow \text{AgCl(s)} + \text{NaNO}_3\text{(aq)}$$

The **complete ionic equation** writes what is really in the beaker,
splitting apart everything that is genuinely present as separate ions:

$$\text{Ag}^+\text{(aq)} + \text{NO}_3^-\text{(aq)} + \text{Na}^+\text{(aq)} + \text{Cl}^-\text{(aq)} \rightarrow \text{AgCl(s)} + \text{Na}^+\text{(aq)} + \text{NO}_3^-\text{(aq)}$$

Look at what is identical on both sides. Sodium ions came in dissolved
and left dissolved. Nitrate ions did the same. They are **spectator
ions** — present, but taking no part — and cancelling them leaves the
**net ionic equation**:

$$\text{Ag}^+\text{(aq)} + \text{Cl}^-\text{(aq)} \rightarrow \text{AgCl(s)}$$

That is the reaction. Three lines of chemistry reduced to the one thing
that changed. It also makes a broader claim than the full equation did:
*any* soluble silver salt mixed with *any* soluble chloride will give
this same precipitate. Silver nitrate and sodium chloride were just the
bottles that happened to be on the bench.

> [!abstract] What gets split, and what does not
> Split it into ions if it is genuinely present as free ions in
> solution:
> - soluble ionic compounds labelled $\text{(aq)}$
> - strong acids and strong bases, which are fully ionised
>
> Leave it written whole if it is not:
> - anything solid, $\text{(s)}$ — including the precipitate itself
> - liquids and gases, $\text{(l)}$ and $\text{(g)}$ — water in
>   particular is never split
> - weak acids and weak bases, which are mostly un-ionised
>
> Getting the state symbols right is therefore not decoration. They are
> the instructions for the next step.

Two checks before you trust a net ionic equation. The atoms must
balance, as always — and so must the **charge**. In the equation above
the left side carries $(+1) + (-1) = 0$ and the right side is a neutral
solid, so charge balances. An equation whose charges do not match is
wrong even if every atom is accounted for.

## Neutralisation has one too

The same treatment applied to an acid and a base is startling, because
almost the entire equation cancels:

$$\text{HCl(aq)} + \text{NaOH(aq)} \rightarrow \text{NaCl(aq)} + \text{H}_2\text{O(l)}$$

Split the strong acid, the strong base, and the soluble salt, cancel
sodium and chloride, and what remains is

$$\text{H}^+\text{(aq)} + \text{OH}^-\text{(aq)} \rightarrow \text{H}_2\text{O(l)}$$

Every neutralisation of a strong acid by a strong base has that same net
ionic equation, whichever acid and base you chose. The salt is a
by-product; the reaction is the formation of water, which is what
[[Acids and Bases]] claimed and this is the proof of it.

Note what happens with a *weak* acid. Ethanoic acid is mostly
un-ionised, so it is not split, and the net ionic equation keeps the
whole molecule on the left. Different equation, different chemistry, and
the difference is visible only because you paid attention to strong
versus weak.

## Where this gets used

Precipitation is not only a classroom exercise; it is how you remove
something from water that you cannot filter out.

**Phosphorus removal at a wastewater plant.** Phosphate from detergents
and fertiliser causes algal blooms in lakes, and it is dissolved, so
filtration does nothing. Add an iron(III) or aluminium salt and it
becomes a solid that can be settled and removed:

$$\text{Fe}^{3+}\text{(aq)} + \text{PO}_4^{3-}\text{(aq)} \rightarrow \text{FePO}_4\text{(s)}$$

**Identifying an unknown ion.** Because each precipitate has a
characteristic colour and a characteristic set of conditions, adding
reagents one at a time and watching what falls out is a method of
qualitative analysis — the logic behind
[[The Unknown Substance]] extended to solutions.

**Measuring how much of something is present.** Precipitate it, filter,
dry to constant mass, and work backwards through
[[Stoichiometry]]. That is gravimetric analysis, and it is what
[[The Water Report]] will ask you to reason about alongside titration.

Next, the other precise way of measuring a dissolved amount:
[[Titrating an Acid]].

%%curriculum-start%%
## Curriculum connection

![[E2.5]]

![[E3.4]]
%%curriculum-end%%
