---
title: Redox and Cells Practice
draft: false
created: __CREATED__
enableToc: false
tags:
  - chemistry
  - exercises
---
Two rules run this entire page. Neither of them ever changes, in any
kind of cell, under any conditions:

> [!important] Anode, oxidation. Cathode, reduction.
> **Oxidation always happens at the anode. Reduction always happens at
> the cathode.** In a galvanic cell, in an electrolytic cell, in a
> corroding pipe, in a battery on a shelf.
>
> What *does* change between the two kinds of cell is the **sign** of
> each electrode, and the two facts get tangled together constantly. Keep
> them separate: the anode-is-oxidation rule is about chemistry and is
> permanent; the sign is about which way you are pushing the electrons
> and is not.

The oxidation number rules, in the order they are applied:

1. An element on its own is 0. $\text{Zn(s)}$, $\text{O}_2$,
   $\text{Cl}_2$ — all zero.
2. A monatomic ion takes the charge of the ion.
3. Oxygen is $-2$, except in peroxides, where it is $-1$.
4. Hydrogen is $+1$ with non-metals, and $-1$ with metals.
5. The sum over a neutral compound is 0; over an ion, it equals the
   charge.

Standard reduction potentials come from your data booklet. Values given
inside a question are given so everyone works from the same ones — and
before you use the booklet at all, read
[[Reading a Reduction Potential Table]], because the sign convention in
it catches nearly everyone once.

**1.** Define *half-reaction*, *oxidising agent*, *reducing agent*, and
*oxidation number*. Then assign oxidation numbers to the underlined
element in $\text{MnO}_4^-$, $\text{Cr}_2\text{O}_7^{2-}$,
$\text{H}_2\text{O}_2$, $\text{SO}_4^{2-}$, and $\text{NaH}$.

> [!success]- Answer 1
> **Half-reaction**: one half of a redox process written on its own,
> showing either the loss of electrons or the gain, with the electrons
> written explicitly. Half-reactions do not happen in isolation —
> electrons lost by one substance are gained by another — but separating
> them is what makes the bookkeeping possible.
>
> **Oxidising agent**: the substance that causes another to be oxidised,
> which it does by taking electrons. So the oxidising agent is itself
> **reduced**. This crossover is the source of most of the confusion in
> the topic and it is worth saying out loud a few times.
>
> **Reducing agent**: the substance that causes another to be reduced by
> giving electrons, and is therefore itself **oxidised**.
>
> **Oxidation number**: a bookkeeping charge assigned to an atom as
> though every bond it takes part in were fully ionic. It is not a real
> charge. It is a device for tracking where electrons went, and its
> justification is entirely that it works.
>
> | Species | Working | Oxidation number |
> | --- | --- | --- |
> | $\text{MnO}_4^-$ | $\text{Mn} + 4(-2) = -1$ | Mn is $+7$ |
> | $\text{Cr}_2\text{O}_7^{2-}$ | $2\text{Cr} + 7(-2) = -2$ | Cr is $+6$ |
> | $\text{H}_2\text{O}_2$ | $2(+1) + 2\text{O} = 0$ | O is $-1$ |
> | $\text{SO}_4^{2-}$ | $\text{S} + 4(-2) = -2$ | S is $+6$ |
> | $\text{NaH}$ | $(+1) + \text{H} = 0$ | H is $-1$ |
>
> **The last two are the exceptions in the rule list, and they are there
> deliberately.** In hydrogen peroxide the two oxygens are bonded to
> each other, so neither can take electrons from the other, and each
> ends at $-1$ instead of $-2$. In sodium hydride the metal is less
> electronegative than the hydrogen, so the bookkeeping runs the other
> way and hydrogen is $-1$.
>
> Note also that manganese at $+7$ is nowhere near a real charge — no
> atom carries seven units of charge. It is a count, not a measurement,
> and treating it as a physical charge is where students start
> disbelieving the method.

**2.** For
$\text{Zn(s)} + \text{Cu}^{2+}\text{(aq)} \rightarrow \text{Zn}^{2+}\text{(aq)} + \text{Cu(s)}$,
identify what is oxidised, what is reduced, the oxidising agent, and the
reducing agent. Write both half-reactions.

> [!success]- Answer 2
> Track the oxidation numbers first:
>
> | Species | Before | After | Change |
> | --- | --- | --- | --- |
> | Zn | 0 | $+2$ | Increased — **oxidised** |
> | Cu | $+2$ | 0 | Decreased — **reduced** |
>
> **Oxidation, at the anode:**
> $\text{Zn(s)} \rightarrow \text{Zn}^{2+}\text{(aq)} + 2e^-$
>
> **Reduction, at the cathode:**
> $\text{Cu}^{2+}\text{(aq)} + 2e^- \rightarrow \text{Cu(s)}$
>
> - **Zinc is oxidised**, so zinc is the **reducing agent** — it gave
>   the electrons that reduced the copper.
> - **Copper(II) is reduced**, so copper(II) is the **oxidising agent**
>   — it took the electrons that oxidised the zinc.
>
> **Two checks that cost nothing.** The electrons must balance: two lost,
> two gained, so these half-reactions can be added directly with no
> multiplying. And each half-reaction must balance for charge: on the
> left of the oxidation, charge is 0; on the right, $+2$ and $2e^-$
> gives 0. ✓
>
> **The agent is always the opposite of what happened to it**, and the
> way to stop getting it backwards is to read the word "agent" as
> "the thing that did it to the other one".

**3.** Balance in acidic solution, using the half-reaction method:
$\text{MnO}_4^-\text{(aq)} + \text{Fe}^{2+}\text{(aq)} \rightarrow \text{Mn}^{2+}\text{(aq)} + \text{Fe}^{3+}\text{(aq)}$

> [!success]- Answer 3
> **Split into half-reactions.**
>
> $\text{MnO}_4^- \rightarrow \text{Mn}^{2+}$ and
> $\text{Fe}^{2+} \rightarrow \text{Fe}^{3+}$
>
> **Balance the iron half**, which needs only electrons:
>
> $\text{Fe}^{2+} \rightarrow \text{Fe}^{3+} + e^-$
>
> **Balance the manganese half**, in the standard order — element first,
> then oxygen with water, then hydrogen with $\text{H}^+$, then charge
> with electrons:
>
> $\begin{aligned} \text{MnO}_4^- &\rightarrow \text{Mn}^{2+} + 4\text{H}_2\text{O} \\ \text{MnO}_4^- + 8\text{H}^+ &\rightarrow \text{Mn}^{2+} + 4\text{H}_2\text{O} \\ \text{MnO}_4^- + 8\text{H}^+ + 5e^- &\rightarrow \text{Mn}^{2+} + 4\text{H}_2\text{O} \end{aligned}$
>
> Check the electron count on that last line: the left is
> $-1 + 8 - 5 = +2$ and the right is $+2$. ✓
>
> **Equalise the electrons.** One half gives up 1 electron, the other
> takes 5, so multiply the iron half by 5:
>
> $5\text{Fe}^{2+} \rightarrow 5\text{Fe}^{3+} + 5e^-$
>
> **Add and cancel the electrons:**
>
> $$\text{MnO}_4^-\text{(aq)} + 8\text{H}^+\text{(aq)} + 5\text{Fe}^{2+}\text{(aq)} \rightarrow \text{Mn}^{2+}\text{(aq)} + 4\text{H}_2\text{O(l)} + 5\text{Fe}^{3+}\text{(aq)}$$
>
> **The two checks that catch every error in this method:**
>
> **Atoms.** Mn: 1 and 1. O: 4 and 4. H: 8 and 8. Fe: 5 and 5. ✓
>
> **Charge.** Left: $(-1) + (+8) + (+10) = +17$.
> Right: $(+2) + 0 + (+15) = +17$. ✓
>
> A balanced redox equation that balances for atoms but not for charge
> is still wrong, and charge is the check people skip. Do both.
>
> This reaction is the basis of a common titration, and it needs no
> indicator — permanganate is intensely purple and $\text{Mn}^{2+}$ is
> nearly colourless, so the first drop of excess titrant colours the
> flask permanently.

**4.** Balance in **basic** solution:
$\text{MnO}_4^-\text{(aq)} + \text{I}^-\text{(aq)} \rightarrow \text{MnO}_2\text{(s)} + \text{I}_2\text{(s)}$

> [!success]- Answer 4
> **The iodide half:**
>
> $2\text{I}^- \rightarrow \text{I}_2 + 2e^-$
>
> **The manganese half, balanced for basic conditions.** Oxygen is
> balanced with water on the side needing it and hydroxide on the other:
>
> $\text{MnO}_4^- + 2\text{H}_2\text{O} + 3e^- \rightarrow \text{MnO}_2 + 4\text{OH}^-$
>
> Check that half before continuing. Mn: 1 and 1. O: $4 + 2 = 6$ on the
> left, $2 + 4 = 6$ on the right. H: 4 and 4. Charge:
> $-1 - 3 = -4$ on the left, $-4$ on the right. ✓
>
> **Equalise the electrons.** Three and two, so multiply by 2 and 3
> respectively to reach six:
>
> $\begin{aligned} 2\text{MnO}_4^- + 4\text{H}_2\text{O} + 6e^- &\rightarrow 2\text{MnO}_2 + 8\text{OH}^- \\ 6\text{I}^- &\rightarrow 3\text{I}_2 + 6e^- \end{aligned}$
>
> **Add:**
>
> $$2\text{MnO}_4^-\text{(aq)} + 4\text{H}_2\text{O(l)} + 6\text{I}^-\text{(aq)} \rightarrow 2\text{MnO}_2\text{(s)} + 8\text{OH}^-\text{(aq)} + 3\text{I}_2\text{(s)}$$
>
> **Atoms.** Mn: 2 and 2. O: $8 + 4 = 12$ and $4 + 8 = 12$. H: 8 and 8.
> I: 6 and 6. ✓
>
> **Charge.** Left: $(-2) + 0 + (-6) = -8$. Right: $0 + (-8) + 0 = -8$.
> ✓
>
> **Why basic conditions are handled differently.** In a basic solution
> there is essentially no $\text{H}^+$ available, so an equation
> containing it would be describing a species that is not there. Water
> and hydroxide are both abundant, and they do the same job.
>
> An alternative route that some find easier: balance the whole thing as
> though it were acidic, then add enough $\text{OH}^-$ to **both** sides
> to neutralise every $\text{H}^+$, and combine each
> $\text{H}^+ + \text{OH}^-$ into water. Either route gives the same
> equation; use whichever you can do without looking it up.

**5.** Suppose your booklet gives
$E^\circ = +0.34$ V for the copper(II)/copper couple and
$E^\circ = -0.76$ V for the zinc(II)/zinc couple. For a cell built from
these two half-cells, find $E^\circ_{\text{cell}}$, identify the anode
and the cathode, and write the cell notation.

> [!success]- Answer 5
> **Decide which half-cell reduces.** The one with the more positive
> reduction potential has the stronger pull on electrons, so copper is
> reduced and zinc is oxidised.
>
> - **Anode (oxidation):**
>   $\text{Zn(s)} \rightarrow \text{Zn}^{2+}\text{(aq)} + 2e^-$
> - **Cathode (reduction):**
>   $\text{Cu}^{2+}\text{(aq)} + 2e^- \rightarrow \text{Cu(s)}$
>
> $E^\circ_{\text{cell}} = E^\circ_{\text{cathode}} - E^\circ_{\text{anode}} = (+0.34) - (-0.76) = +1.10\ \text{V}$
>
> **$E^\circ_{\text{cell}} = +1.10$ V.**
>
> **Cell notation**, anode on the left, cathode on the right, double bar
> for the salt bridge:
>
> $$\text{Zn(s)}\ |\ \text{Zn}^{2+}\text{(aq)}\ ||\ \text{Cu}^{2+}\text{(aq)}\ |\ \text{Cu(s)}$$
>
> **Note what was subtracted and what was not.** Both values in the
> booklet are written as **reduction** potentials, including zinc's,
> even though zinc is being oxidised here. You do not flip zinc's sign
> and then subtract — the subtraction in the formula does the flipping
> for you. Flipping the sign *and* subtracting is a double negative and
> gives $-0.42$ V, which is one of the two most common errors on this
> topic.
>
> **The positive value means the reaction is spontaneous as written**,
> which is what a galvanic cell is: a spontaneous reaction with its two
> halves separated so the electrons have to travel through a wire you
> can put a load on.
>
> Your own measured value in
> [[Building a Galvanic Cell]] will have come out below 1.10 V, and the
> reasons are on that page.

**6.** For
$2\text{Al(s)} + 3\text{Cu}^{2+}\text{(aq)} \rightarrow 2\text{Al}^{3+}\text{(aq)} + 3\text{Cu(s)}$,
with $E^\circ = -1.66$ V for the aluminium(III)/aluminium couple and
$E^\circ = +0.34$ V for copper(II)/copper, find
$E^\circ_{\text{cell}}$. A classmate multiplies the aluminium value by 2
and the copper value by 3 before subtracting. What is wrong with that?

> [!success]- Answer 6
> Aluminium is oxidised, so it is the anode; copper(II) is reduced, so
> it is the cathode.
>
> $E^\circ_{\text{cell}} = E^\circ_{\text{cathode}} - E^\circ_{\text{anode}} = (+0.34) - (-1.66) = +2.00\ \text{V}$
>
> **$E^\circ_{\text{cell}} = +2.00$ V**, and the coefficients in the
> balanced equation play no part in it at all.
>
> **Why the classmate's method is wrong.** A potential is an
> **intensive** property — it does not depend on how much material is
> involved. It belongs to the same family as temperature, density, and
> concentration, and not to the family that contains mass, volume, and
> $\Delta H$.
>
> The physical statement behind that: a potential is energy **per unit
> charge**. Double the reaction and you double both the energy released
> and the charge that moves, so the ratio is unchanged.
>
> **The evidence is in front of you and needs no theory.** Two identical
> batteries side by side are still 1.5 V. A bigger battery of the same
> chemistry is still 1.5 V — it lasts longer, which is a statement about
> charge, not about voltage. And in your own investigation, groups using
> larger metal strips than yours got the same reading you did.
>
> **The contrast to hold in your head:**
>
> | Quantity | Type | Doubling the equation |
> | --- | --- | --- |
> | $\Delta H$ | Extensive | Doubles it |
> | $E^\circ_{\text{cell}}$ | **Intensive** | **Leaves it alone** |
>
> Those two rules are opposite, they are applied to equations that look
> alike, and they are examined a fortnight apart. Write both down
> together, once, and stop guessing.

**7.** Using $E^\circ = +0.80$ V for the silver(I)/silver couple and
$E^\circ = +0.34$ V for copper(II)/copper, predict whether each of these
happens spontaneously. Give $E^\circ_{\text{cell}}$ for each.
*(a)* A copper strip placed in silver nitrate solution.
*(b)* A silver strip placed in copper(II) sulfate solution.

> [!success]- Answer 7
> **(a) Copper in silver nitrate.** For this to happen, copper must be
> oxidised — copper is the anode — and silver(I) must be reduced —
> silver is the cathode.
>
> $E^\circ_{\text{cell}} = (+0.80) - (+0.34) = +0.46\ \text{V}$
>
> **Positive, so spontaneous.** The copper strip dissolves, silver metal
> deposits on it as a grey fuzz, and the solution turns blue as
> $\text{Cu}^{2+}$ builds up.
>
> $2\text{Ag}^+\text{(aq)} + \text{Cu(s)} \rightarrow 2\text{Ag(s)} + \text{Cu}^{2+}\text{(aq)}$
>
> Note the 2 on the silver — one copper atom supplies two electrons, and
> each silver ion needs one. It does not affect
> $E^\circ_{\text{cell}}$, exactly as in question 6.
>
> **(b) Silver in copper(II) sulfate.** Now silver would have to be
> oxidised — silver is the anode — and copper(II) reduced.
>
> $E^\circ_{\text{cell}} = (+0.34) - (+0.80) = -0.46\ \text{V}$
>
> **Negative, so not spontaneous.** Nothing happens. A silver spoon in
> copper sulfate solution stays a silver spoon.
>
> **The two answers are the same number with opposite signs**, which
> they must be — they are the same reaction read in the two directions,
> and reversing a reaction reverses the sign of its cell potential in
> exactly the way that reversing an equation reverses the sign of
> $\Delta H$.
>
> **The general rule:** $E^\circ_{\text{cell}} > 0$ means spontaneous as
> written; $E^\circ_{\text{cell}} < 0$ means spontaneous in reverse.
> A negative value does not mean "nothing can happen" — it means you
> would have to **drive** it, with an external supply, which is what an
> electrolytic cell is.
>
> **What it does not tell you is when.** A positive
> $E^\circ_{\text{cell}}$ says the reaction is favoured; it says nothing
> about the rate, exactly as a negative $\Delta H$ and a large $K_c$ say
> nothing about the rate. Aluminium in air has a very favourable
> reaction available to it and survives for decades because of the oxide
> layer that forms first.

**8.** Four claims from a study group. Correct each.
*(a) "The anode is always the negative electrode."*
*(b) "We doubled the equation, so $E^\circ_{\text{cell}}$ doubled."*
*(c) "Reduction happens at the anode, because the anode is where the
electrons come from."*
*(d) "$E^\circ_{\text{cell}}$ is positive, so the reaction will go
quickly."*

> [!success]- Answer 8
> **(a) True for galvanic cells, false for electrolytic ones.**
>
> | | Anode | Cathode |
> | --- | --- | --- |
> | Reaction | **Oxidation** | **Reduction** |
> | Sign, galvanic cell | Negative | Positive |
> | Sign, electrolytic cell | **Positive** | **Negative** |
>
> The chemistry rule never moves. The sign does, and the reason is
> straightforward once you ask what is driving the electrons. In a
> galvanic cell the reaction pushes them, so they pile up at the
> electrode where oxidation is happening and it becomes negative. In an
> electrolysis, a power supply pushes them, and its positive terminal
> pulls electrons out of the solution at the electrode where oxidation
> is happening — which makes that anode positive.
>
> **Learn "anode, oxidation" and derive the sign from the situation.**
> Learning the sign and deriving the chemistry gets you half of all
> electrochemistry questions backwards.
>
> **(b) Cell potentials are intensive and never scale.** See question 6.
> This is the error the classmate made there, appearing again as a
> general principle, because it is the one that costs the most marks in
> Unit 5.
>
> **(c) Half right, which is why it is convincing.** The electrons *do*
> come from the anode — because that is where **oxidation** happens, and
> oxidation is the loss of electrons. Losing electrons is what puts them
> into the wire.
>
> The student has correctly identified where electrons originate and
> then attached the wrong process to it. Oxidation gives electrons up;
> reduction takes them in. The electrons travel from the anode, through
> the external circuit, to the cathode, where reduction consumes them.
>
> **(d) Spontaneity is not speed**, and this is the third time this
> course has made the same point with a different quantity. A negative
> $\Delta H$ does not mean fast. A large $K_c$ does not mean fast. A
> positive $E^\circ_{\text{cell}}$ does not mean fast.
>
> All three describe where a reaction is **going**. How quickly it gets
> there depends on the activation energy and on the surfaces and
> concentrations involved, and it is a completely separate question with
> a completely separate answer.
>
> The everyday evidence: a battery on a shelf has a positive
> $E^\circ_{\text{cell}}$ the whole time and takes years to run down,
> because the only route between its two halves is through a circuit you
> have not connected yet.
>
> One safety note attached to this last point, because it comes up the
> moment anyone runs an electrolysis: **passing current through an
> aqueous solution produces gas at both electrodes, and one of them is
> usually hydrogen.** No flames in the room, and the cell is never
> sealed or covered — a stoppered electrolysis cell is a pressure vessel
> full of flammable gas, built by accident.

Reference: [[Redox Bookkeeping]] and
[[Galvanic and Electrolytic Cells]], then
[[Corrosion and Electrolysis]] for where this goes in the world. Before
you use the booklet: [[Reading a Reduction Potential Table]]. Measuring
a cell yourself: [[Building a Galvanic Cell]].

%%curriculum-start%%
## Curriculum connection

![[F2.1]]

![[F2.3]]

![[F2.6]]
%%curriculum-end%%
