---
title: Redox Bookkeeping
publish: true
created: __CREATED__
enableToc: true
tags:
  - concepts
  - electrochemistry
---
In [[Building a Galvanic Cell]] you put two metals into two solutions,
joined them, and a voltmeter registered. Something was flowing, and it
was flowing in a particular direction that depended on which two metals
you chose. In Grade 11 the activity series told you *which* metal wins.
It never told you why, or how much.

The answer is electrons, and this page is about counting them. The
counting looks like bookkeeping because it **is** bookkeeping — an
accounting convention invented to keep track of something real.

## Oxidation is loss

The definitions are short and worth having verbatim.

- **Oxidation** is the **loss** of electrons.
- **Reduction** is the **gain** of electrons.

Neither can happen alone. Electrons do not go anywhere unless something
takes them, so every oxidation is paired with a reduction in the same
reaction — hence **redox**. If you have written a reaction in which
something is oxidised and nothing is reduced, you have made an error,
not a discovery.

The two mnemonics are equivalent and you only need one: **LEO says GER**
— Loss of Electrons is Oxidation, Gain of Electrons is Reduction. Or
**OIL RIG** — Oxidation Is Loss, Reduction Is Gain.

Names for the participants get reversed in a way that is initially
maddening:

| Species | What happens to it | What it does to the other |
| --- | --- | --- |
| **Reducing agent** | is oxidised — loses electrons | reduces the other species |
| **Oxidising agent** | is reduced — gains electrons | oxidises the other species |

The agent is named for what it does to its partner, not for what happens
to it. A reducing agent hands electrons over and is itself oxidised in
the act. Say that sentence a few times; it comes up in every question in
[[Redox and Cells Practice]].

## Oxidation numbers are a fiction that works

Loss of electrons is easy to see when a neutral zinc atom becomes a
$\ce{Zn^2+}$ ion. It is much harder to see in a reaction between two
covalent molecules, where nothing is fully gained or lost by anybody.

So chemistry invented a convention. Pretend, for the purposes of
counting, that **every bond is fully ionic** — assign both electrons of
each bonding pair to whichever atom is more electronegative — and then
record the charge each atom would carry under that pretence. That number
is the **oxidation number**.

> [!important] An oxidation number is not a charge
> The carbon in methane has an oxidation number of $-4$. There is no
> $\ce{C^4-}$ ion in methane and there never was. The bonding
> electrons are shared, merely shared unequally, and the $-4$ is the
> result of a deliberate over-simplification applied consistently.
>
> The convention is useful precisely because it is applied consistently:
> when the number **increases**, that atom has lost control of electrons
> and has been oxidised, and when it **decreases**, it has been reduced.
> The fiction cancels out, and the change is real.

The rules, in the order you apply them:

| Situation | Oxidation number |
| --- | --- |
| An element on its own | $0$ |
| A monatomic ion | its charge |
| Group 1 in a compound | $+1$ |
| Group 2 in a compound | $+2$ |
| Fluorine in a compound | $-1$, always |
| Hydrogen | $+1$, except $-1$ in a metal hydride |
| Oxygen | $-2$, except $-1$ in a peroxide, and positive with fluorine |
| Sum over a neutral compound | $0$ |
| Sum over a polyatomic ion | the charge on the ion |

The last two rows are how you find the awkward one. In the permanganate
ion, $\ce{MnO4-}$, the four oxygens contribute $4 \times (-2) = -8$,
and the total must be $-1$, so manganese is $+7$. Nobody measured that;
it was deduced from a rule about oxygen and a rule about sums.

## The half-reaction method

Balancing a redox equation by inspection is miserable. Splitting it into
two halves and balancing each separately is mechanical, and it also
produces exactly the half-equations that
[[Galvanic and Electrolytic Cells]] needs.

For a reaction in **acidic** solution:

1. Split the reaction into an oxidation half and a reduction half.
2. Balance every element **except oxygen and hydrogen**.
3. Balance oxygen by adding $\ce{H2O}$.
4. Balance hydrogen by adding $\ce{H+}$.
5. Balance the **charge** by adding electrons to the more positive side.
6. Multiply one or both halves so that the electrons cancel exactly.
7. Add the halves together and cancel anything appearing on both sides.

In **basic** solution, do all of that, then add as many $\ce{OH-}$ to
both sides as there are $\ce{H+}$, combine each pair into water, and
cancel the water that appears twice.

> [!success]- Permanganate and iron(II), worked through
> **Skeleton:** $\ce{MnO4- + Fe^2+ -> Mn^2+ + Fe^3+}$, in acidic solution.
>
> Manganese goes from $+7$ to $+2$ — reduced. Iron goes from $+2$ to
> $+3$ — oxidised.
>
> **Reduction half.** Manganese is already balanced. Four oxygens on the
> left, so add four waters on the right; that puts eight hydrogens on
> the right, so add eight $\ce{H+}$ on the left. The left now carries
> a charge of $-1 + 8 = +7$ and the right carries $+2$, so five
> electrons go on the left:
>
> $$\ce{MnO4- + 8H+ + 5e- -> Mn^2+ + 4H2O}$$
>
> **Oxidation half.** One electron leaves:
>
> $$\ce{Fe^2+ -> Fe^3+} + e^-$$
>
> **Combine.** The reduction consumes five electrons and the oxidation
> supplies one, so multiply the oxidation half by five and add:
>
> $$\ce{MnO4- + 8H+ + 5Fe^2+ -> Mn^2+ + 4H2O + 5Fe^3+}$$
>
> **Check both.** Atoms: one manganese, four oxygens, eight hydrogens,
> five irons on each side. Charge: $-1 + 8 + 10 = +17$ on the left, and
> $+2 + 0 + 15 = +17$ on the right. A redox equation that balances for
> atoms but not for charge is not balanced.

One case that looks like a paradox and is not. In

$$\ce{Cl2 + 2OH- -> Cl- + ClO- + H2O}$$

chlorine starts at $0$ and ends at both $-1$ and $+1$. The same element
is oxidised and reduced in one reaction. That is called
**disproportionation**, and the bookkeeping handles it without any
special treatment — which is a decent argument that the bookkeeping is
tracking something real.

## Where this is going

Every half-equation you just wrote is a **half-cell** waiting to be
built. Separate the two halves physically, connect them with a wire, and
the electrons that were transferred directly in a beaker now have to
travel through the circuit to get where they are going — and on the way
they can do work.

That is a battery, and it is [[Galvanic and Electrolytic Cells]]. The
numbers that say which half-reaction wins are in
[[Reading a Reduction Potential Table]], and they replace the Grade 11
activity series with something quantitative.

%%curriculum-start%%
## Curriculum connection

![[F3.1]]

![[F2.3]]
%%curriculum-end%%
