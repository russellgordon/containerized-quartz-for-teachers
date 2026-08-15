---
title: Concentration Practice
publish: true
created: __CREATED__
tags:
  - chemistry
  - exercises
---
Concentration is an amount divided by a volume, and almost every mistake
on this topic is a unit problem rather than a chemistry problem. Two
relationships carry the page:

$$c = \frac{n}{V} \qquad c_1V_1 = c_2V_2$$

**Volumes go in litres** before they go into either formula. A
millilitre left unconverted moves your answer by a factor of a thousand,
which is large enough to be obvious and small enough to be missed if you
are not checking magnitudes.

Molar masses to two decimal places; round once, at the end.

**1.** 5.85 g of sodium chloride is dissolved and made up to 250.0 mL of
solution. Find the concentration in mol/L.

> [!success]- Answer 1
> $M(\ce{NaCl}) = 22.99 + 35.45 = 58.44 \text{ g/mol}$
>
> $\begin{aligned} n &= \frac{5.85 \text{ g}}{58.44 \text{ g/mol}} = 0.10010 \text{ mol} \\ c &= \frac{n}{V} = \frac{0.10010 \text{ mol}}{0.2500 \text{ L}} = 0.4004 \text{ mol/L} \end{aligned}$
>
> **0.400 mol/L**, to three significant figures.
>
> Note what happened at the volume: 250.0 mL became 0.2500 L, and the
> trailing zeros were kept because the flask really does deliver four
> figures. Writing 0.25 L would have thrown away precision the
> volumetric flask gave you for free.
>
> Note also the wording: **made up to** 250.0 mL of solution, not
> dissolved in 250.0 mL of water. Those are different volumes and only
> the first one is the one in the formula — which is the whole reason
> [[Preparing a Standard Solution]] insists on a volumetric flask.

**2.** What mass of glucose, $\ce{C6H12O6}$, is
needed to prepare 500.0 mL of a 0.200 mol/L solution?

> [!success]- Answer 2
> Work backwards along the same chain: concentration and volume give
> moles, moles and molar mass give grams.
>
> $n = cV = (0.200 \text{ mol/L})(0.5000 \text{ L}) = 0.100 \text{ mol}$
>
> $M = 6(12.01) + 12(1.01) + 6(16.00) = 72.06 + 12.12 + 96.00 = 180.18 \text{ g/mol}$
>
> $m = nM = (0.100 \text{ mol})(180.18 \text{ g/mol}) = 18.018 \text{ g}$
>
> **18.0 g of glucose**, to three significant figures.
>
> Sanity check on the size: a fifth of a mole of a compound with a molar
> mass near 180 should be somewhere around 36 g, and you are making half
> a litre rather than a full one, so about 18 g. If your answer had come
> out at 1.80 g or 180 g you converted a volume wrongly, and the
> estimate catches it before the calculator does.

**3.** What volume of 2.00 mol/L hydrochloric acid is needed to prepare
250.0 mL of 0.150 mol/L acid by dilution?

> [!success]- Answer 3
> Dilution adds solvent and adds **no solute**, so the moles before
> equal the moles after. That single sentence is the whole of
> $c_1V_1 = c_2V_2$, and it is worth deriving rather than memorising.
>
> $V_1 = \frac{c_2V_2}{c_1} = \frac{(0.150 \text{ mol/L})(250.0 \text{ mL})}{2.00 \text{ mol/L}} = 18.75 \text{ mL}$
>
> **18.8 mL**, to three significant figures.
>
> The volumes can stay in millilitres here because they appear on both
> sides and the units cancel — but only in this formula, and only when
> both volumes are in the same unit. Everywhere else on this page,
> convert to litres.
>
> **How you would actually do it.** Measure 18.8 mL of the stock acid
> with a graduated pipette, run it into a 250.0 mL volumetric flask that
> already contains some distilled water, then make up to the mark and
> invert to mix.
>
> The order in that sentence is a safety instruction, not a
> preference. **Add acid to water, never water to acid.** Diluting acid
> releases heat; with water already in the flask the heat spreads
> through a large volume, whereas acid poured into a few drops of water
> can boil and spit acid back out at your face.

**4.** A 250 mL water sample is found to contain 3.5 mg of chloride ion.
Express this concentration in mg/L and in parts per million, and explain
why those two numbers are the same.

> [!success]- Answer 4
> $c = \frac{3.5 \text{ mg}}{0.250 \text{ L}} = 14 \text{ mg/L}$
>
> **14 mg/L**, which is **14 ppm**.
>
> **Why they coincide.** Parts per million is a mass ratio: milligrams
> of solute per million milligrams of solution. One litre of a dilute
> aqueous solution has a density very close to that of water, about
> 1.00 g/mL, so it has a mass of about 1000 g, which is
> $1.0 \times 10^6$ mg.
>
> So 1 mg in 1 L is 1 mg in $10^6$ mg — one part per million, exactly.
> The two units are numerically interchangeable **for dilute aqueous
> solutions** and for nothing else. In a concentrated brine, or in a
> solvent that is not water, the density assumption fails and so does
> the equivalence.
>
> Two significant figures throughout, because 3.5 mg had two. This is
> the unit that drinking water guidelines are written in, and you will
> use it in [[The Water Report]].

**5.** What volume of 0.250 mol/L sodium hydroxide is needed to
neutralise 25.0 mL of 0.200 mol/L sulfuric acid?

> [!success]- Answer 5
> Balanced equation first, because the ratio here is **not** 1 to 1 and
> that is the entire question:
>
> $$\ce{H2SO4 + 2NaOH -> Na2SO4 + 2H2O}$$
>
> $\begin{aligned} n(\ce{H2SO4}) &= (0.200)(0.0250) = 5.00 \times 10^{-3} \text{ mol} \\ n(\ce{NaOH}) &= 2 \times 5.00 \times 10^{-3} = 1.00 \times 10^{-2} \text{ mol} \\ V &= \frac{n}{c} = \frac{1.00 \times 10^{-2}}{0.250} = 0.0400 \text{ L} \end{aligned}$
>
> **40.0 mL of sodium hydroxide.**
>
> Sulfuric acid supplies two acidic hydrogens per molecule, so it takes
> twice as much base per mole as hydrochloric acid would. Skip the
> equation and you get 20.0 mL, which is exactly half of the right
> answer and looks entirely plausible on the page.
>
> Sanity check: the base is more concentrated than the acid but is
> needed in twice the amount, so the volume should be somewhere near the
> aliquot volume rather than wildly different. 40.0 mL against 25.0 mL
> is comfortable.

**6.** 50.0 mL of 0.100 mol/L barium chloride is added to an excess of
sodium sulfate solution. What mass of barium sulfate precipitates?

> [!success]- Answer 6
> $$\ce{BaCl2 + Na2SO4 -> BaSO4(s) + 2NaCl}$$
>
> "An excess" tells you the barium chloride is limiting, so you never
> need the other solution's numbers.
>
> $n(\ce{BaCl2}) = (0.100 \text{ mol/L})(0.0500 \text{ L}) = 5.00 \times 10^{-3} \text{ mol}$
>
> The ratio to the precipitate is 1 to 1, so
> $n(\ce{BaSO4}) = 5.00 \times 10^{-3}$ mol.
>
> $M(\ce{BaSO4}) = 137.33 + 32.07 + 4(16.00) = 233.40 \text{ g/mol}$
>
> $m = (5.00 \times 10^{-3})(233.40) = 1.167 \text{ g}$
>
> **1.17 g of barium sulfate.**
>
> This is a theoretical yield. What comes off the filter paper will be
> less, and by how much is the subject of
> [[Percentage Yield of a Precipitate]].

**7.** Two conceptual questions.
(a) A student has 0.0100 mol of solid and wants 0.100 mol/L. They add
100.0 mL of water to it in a beaker. What is wrong?
(b) When you dilute a solution, what changes and what does not?

> [!success]- Answer 7
> **(a) Two separate problems, and both of them make the concentration
> wrong in the same direction.**
>
> *The volume is of the wrong thing.* Concentration is moles per litre
> of **solution**, not per litre of solvent. Dissolved solid takes up
> room, so 0.0100 mol of solute plus 100.0 mL of water gives slightly
> **more** than 100.0 mL of solution — and therefore a concentration
> slightly below 0.100 mol/L. This is why the technique is to dissolve
> in less water than you need and then make up to the mark.
>
> *The container is not calibrated.* Beaker graduations are moulded into
> the glass during manufacture, not calibrated, and are commonly out by
> several percent. A volumetric flask is calibrated to a single line, to
> a stated tolerance, at a stated temperature, and that is the only
> reason its number can be trusted.
>
> **(b)** The **amount of solute in moles does not change** — that is
> the entire content of $c_1V_1 = c_2V_2$, which is just the statement
> $n_1 = n_2$ with both sides written as $cV$.
>
> What changes: the **volume** goes up, the **concentration** goes down,
> and they do so in exact inverse proportion. Halve the concentration by
> doubling the volume.
>
> A useful consequence: once you have added too much water, you cannot
> fix it by pouring some off. Removing solution removes solute along
> with it, so the concentration stays exactly where it was and you have
> less of it. The only repair is to start again.

**8.** A student writes: *"I need 100.0 mL of 0.500 mol/L hydrochloric
acid and I have a 2.00 mol/L stock. I measured 25.0 mL of the stock into
a beaker and added 100.0 mL of water. Then I poured the water in first
and added the acid to it — no, wait, the other way round, I poured the
water into the acid. Anyway, diluting it means there are fewer moles of
acid now, so it is safer."* Find every error.

> [!success]- Answer 8
> **Error 1 — the arithmetic gives the wrong concentration.** The moles
> taken are right:
>
> $n = (2.00 \text{ mol/L})(0.0250 \text{ L}) = 0.0500 \text{ mol}$
>
> But adding 100.0 mL of water to 25.0 mL of stock gives a final volume
> of about 125.0 mL, not 100.0 mL. So
>
> $c = \frac{0.0500 \text{ mol}}{0.1250 \text{ L}} = 0.400 \text{ mol/L}$
>
> — not 0.500 mol/L. The student diluted **to an added volume** when the
> formula requires a **final volume**.
>
> **The correct method:** run 25.0 mL of the stock into a 100.0 mL
> volumetric flask containing some distilled water, then make up **to
> the mark** so that the final volume is 100.0 mL. That gives
> $\frac{0.0500}{0.1000} = 0.500$ mol/L exactly, and the flask does the
> measuring rather than the arithmetic.
>
> **Error 2 — the water went into the acid.** This is the one that could
> hurt somebody. **Add acid to water, never water to acid.** Dilution
> releases heat. When the water is already in the flask, that heat is
> spread through a large volume and the temperature rise is small; when
> water is poured onto acid, the heat is released in the few drops at
> the surface, which can boil and throw acid out of the container at
> whoever is standing over it. The student noticed the rule, restated it
> backwards, and did the dangerous version.
>
> **Error 3 — diluting does not remove moles.** The number of moles of
> hydrochloric acid is unchanged at 0.0500 mol before and after. What
> changed is how many of them are in each litre. All of the acid is
> still in the beaker and it will still neutralise exactly as much base
> as it would have before.
>
> Dilute acid **is** less hazardous than concentrated acid, so the
> student's conclusion is not wrong — but the reason given is, and a
> right answer resting on a wrong mechanism will fail the next question
> it meets.

Reference: [[Concentration]] and [[Water and Solutions]]. Making one for
yourself: [[Preparing a Standard Solution]]. Measuring one you did not
make: [[Titrating an Acid]].

%%curriculum-start%%
## Curriculum connection

![[E2.1]]

![[E2.2]]

![[E2.6]]
%%curriculum-end%%
