---
title: Limiting Reagent Practice
publish: true
created: __CREATED__
tags:
  - chemistry
  - exercises
---
Up to now every question told you that everything else was present in
excess, which meant one reactant decided the answer and you were told
which. Real beakers do not come with that note attached. Here you are
given amounts of **both** reactants and have to work out which one runs
out first.

The method that always works, and the only one worth learning:

1. Convert every reactant to **moles**.
2. Divide each amount by its **coefficient** in the balanced equation.
3. The **smallest** result belongs to the limiting reagent.
4. Do all the product arithmetic from the limiting reagent, and never
   from the other one.

Step 2 is the step people skip, and skipping it is why "there is less of
that one" gets the wrong answer so often.

**1.** For $\ce{Zn + 2HCl -> ZnCl2 + H2}$,
you have 0.50 mol of zinc and 0.80 mol of hydrochloric acid.
(a) Which is limiting?
(b) How many moles of hydrogen form?
(c) How much of the excess reactant is left over?

> [!success]- Answer 1
> **(a)** Divide each amount by its coefficient:
>
> $\begin{aligned} \ce{Zn} &: \frac{0.50}{1} = 0.50 \\ \ce{HCl} &: \frac{0.80}{2} = 0.40 \end{aligned}$
>
> 0.40 is smaller, so **the hydrochloric acid is limiting**.
>
> Check it the long way to see that the two agree: consuming all 0.50
> mol of zinc would need $2 \times 0.50 = 1.00$ mol of acid, and you
> only have 0.80 mol. The acid runs out first.
>
> **(b)** Hydrogen and acid are in a 1 to 2 ratio:
>
> $n(\ce{H2}) = 0.80 \times \frac{1}{2} = 0.40 \text{ mol}$
>
> **(c)** The acid consumes zinc in a 2 to 1 ratio, so
> $0.80 \times \frac{1}{2} = 0.40$ mol of zinc is used up. Left over:
>
> $0.50 - 0.40 = 0.10 \text{ mol of zinc}$
>
> That leftover is worth taking seriously rather than treating as a
> leftover. It is metal you paid for, it sits in the flask, and in a
> recovered product it is contamination.

**2.** 5.00 g of zinc is added to 50.0 mL of 1.00 mol/L hydrochloric
acid.
(a) Which reactant is limiting?
(b) What mass of hydrogen is produced?
(c) What mass of the excess reactant remains?

> [!success]- Answer 2
> Everything to moles first. The acid is given as a concentration and a
> volume, so use $n = cV$ with the **volume in litres**.
>
> $\begin{aligned} n(\ce{Zn}) &= \frac{5.00 \text{ g}}{65.38 \text{ g/mol}} = 0.076476 \text{ mol} \\ n(\ce{HCl}) &= (1.00 \text{ mol/L})(0.0500 \text{ L}) = 0.0500 \text{ mol} \end{aligned}$
>
> **(a)** Divide by coefficients:
>
> $\ce{Zn} : \frac{0.076476}{1} = 0.0765 \qquad \ce{HCl} : \frac{0.0500}{2} = 0.0250$
>
> **The acid is limiting**, and by a wide margin — you would need about
> three times as much acid to use up all that zinc.
>
> **(b)** $n(\ce{H2}) = 0.0500 \times \frac{1}{2} = 0.0250 \text{ mol}$
>
> $m(\ce{H2}) = (0.0250 \text{ mol})(2.02 \text{ g/mol}) = 0.0505 \text{ g}$
>
> **0.0505 g of hydrogen** — about fifty milligrams, from five grams of
> metal and fifty millilitres of acid. Hydrogen's molar mass is so small
> that even a visibly vigorous reaction produces a mass a school balance
> can barely resolve. This is exactly why the gas is measured by
> **volume** rather than mass in [[Measuring a Gas Law]].
>
> **(c)** Zinc consumed: $0.0500 \times \frac{1}{2} = 0.0250$ mol, which
> is $(0.0250)(65.38) = 1.63$ g.
>
> $5.00 - 1.63 = 3.37 \text{ g of zinc left over}$
>
> Two thirds of the metal never reacted. If you had assumed the zinc was
> limiting because five grams sounds like more than fifty millilitres,
> you would have predicted three times too much hydrogen.

**3.** 14.0 g of nitrogen and 3.00 g of hydrogen are combined:
$\ce{N2 + 3H2 -> 2NH3}$.
(a) Which is limiting?
(b) What mass of ammonia forms?
(c) What mass of the excess reactant remains?

> [!success]- Answer 3
> $\begin{aligned} n(\ce{N2}) &= \frac{14.0}{28.02} = 0.49964 \text{ mol} \\ n(\ce{H2}) &= \frac{3.00}{2.02} = 1.48515 \text{ mol} \end{aligned}$
>
> **(a)** Divide by coefficients:
>
> $\ce{N2} : \frac{0.49964}{1} = 0.49964 \qquad \ce{H2} : \frac{1.48515}{3} = 0.49505$
>
> **The hydrogen is limiting** — but only just. The two numbers differ
> by about one part in a hundred, which means this mixture is very close
> to exactly stoichiometric and the answer would flip if the masses had
> been slightly different.
>
> This is a good question to have got wrong by rounding early. Round
> those moles to two figures and both come out as 0.50, and you cannot
> tell which is limiting at all.
>
> **(b)** $n(\ce{NH3}) = 1.48515 \times \frac{2}{3} = 0.99010 \text{ mol}$
>
> $m(\ce{NH3}) = (0.99010)(17.04) = 16.87 \text{ g}$
>
> **16.9 g of ammonia**, to three significant figures.
>
> **(c)** Nitrogen consumed: $1.48515 \times \frac{1}{3} = 0.49505$ mol.
>
> $\begin{aligned} n \text{ left} &= 0.49964 - 0.49505 = 0.00459 \text{ mol} \\ m \text{ left} &= (0.00459)(28.02) = 0.13 \text{ g} \end{aligned}$
>
> **About 0.13 g of nitrogen remains**, and you should quote it with
> that hedge. It is the difference of two numbers that agree to three
> figures, so almost all of the precision cancels: the inputs were good
> to about one part in a thousand and this answer is good to perhaps one
> part in three. Subtracting nearly equal quantities destroys
> significant figures, and pretending otherwise by writing 0.1287 g
> would be the most confident wrong number on the page.

**4.** 25.0 mL of 0.100 mol/L silver nitrate is mixed with 25.0 mL of
0.150 mol/L sodium chloride:
$\ce{AgNO3 + NaCl -> AgCl(s) + NaNO3}$.
(a) What mass of silver chloride should form?
(b) What is the concentration of the leftover reactant in the mixture?

> [!success]- Answer 4
> $\begin{aligned} n(\ce{AgNO3}) &= (0.100)(0.0250) = 2.50 \times 10^{-3} \text{ mol} \\ n(\ce{NaCl}) &= (0.150)(0.0250) = 3.75 \times 10^{-3} \text{ mol} \end{aligned}$
>
> **(a)** Both coefficients are 1, so the smaller amount limits: the
> **silver nitrate**.
>
> $M(\ce{AgCl}) = 107.87 + 35.45 = 143.32 \text{ g/mol}$
>
> $m = (2.50 \times 10^{-3})(143.32) = 0.3583 \text{ g}$
>
> **0.358 g of silver chloride.**
>
> **(b)** Sodium chloride left over:
>
> $3.75 \times 10^{-3} - 2.50 \times 10^{-3} = 1.25 \times 10^{-3} \text{ mol}$
>
> The volumes add, so it is now dissolved in
> $25.0 + 25.0 = 50.0 \text{ mL}$:
>
> $c = \frac{n}{V} = \frac{1.25 \times 10^{-3} \text{ mol}}{0.0500 \text{ L}} = 0.0250 \text{ mol/L}$
>
> Forgetting that the volumes add is the standard slip here, and it
> doubles the answer. Any time two solutions are mixed, the excess ends
> up in the **combined** volume.

**5.** A group carries out the reaction in question 4 and recovers
0.321 g of dry silver chloride. Calculate the percentage yield.

> [!success]- Answer 5
> $$\text{percentage yield} = \frac{\text{actual}}{\text{theoretical}} \times 100\%$$
>
> $\frac{0.321 \text{ g}}{0.3583 \text{ g}} \times 100\% = 89.6\%$
>
> **89.6%**, using the unrounded theoretical yield. Using the rounded
> 0.358 g gives 89.7%, and that third figure is not worth arguing about
> — which is itself the point. Quote this as **about 90%** unless you
> can defend the tenth.
>
> Where did the missing tenth of a gram go? Almost certainly onto glass
> and paper: precipitate left on the beaker wall and the stirring rod,
> and the finest particles passing straight through the filter paper
> with the filtrate. Both of those lower the recovered mass, and neither
> has anything to do with the reaction being incomplete.

**6.** A second group, running the same reaction, reports recovering
0.372 g and calculates a yield of 103.8%. Their conclusion is that their
reaction was unusually efficient. What actually happened?

> [!success]- Answer 6
> First, confirm the arithmetic, because it is right:
>
> $\frac{0.372}{0.3583} \times 100\% = 103.8\%$
>
> **The number is correct and the conclusion is not.** A yield above
> 100% is impossible as chemistry — you cannot recover more silver
> chloride than there was silver to make it from. So the extra mass is
> not silver chloride, and the question is what else was on the balance.
>
> Three routes, all of which add mass:
>
> **Water that had not finished leaving.** Silver chloride filtered from
> an aqueous solution comes out wet, and a precipitate dried for ten
> minutes is not dry. This is the commonest cause by some distance, and
> the fix is drying to **constant mass** rather than to a schedule.
>
> **Soluble salts left behind because the precipitate was not washed.**
> The filtrate contains sodium nitrate and leftover sodium chloride,
> and any of it clinging to the crystals dries into the product.
>
> **Filter paper that gained moisture.** Paper massed dry, then left on
> the bench while the filtration ran, takes up water from the air. The
> mass you subtract at the end is then too small.
>
> None of this is a disgrace and none of it should be quietly rounded
> away. **A yield over 100% is information about the procedure**, and a
> report that says "103.8%, most likely incomplete drying, since we
> dried for one period and did not check for constant mass" is worth far
> more than a report that says 98%.

**7.** Two conceptual questions.
(a) If you double the amount of **both** reactants in question 1, does
the limiting reagent change?
(b) Is percentage yield a property of the reaction?

> [!success]- Answer 7
> **(a) No.** Doubling both amounts doubles both of the
> divided-by-coefficient values, and doubling two numbers does not
> change which is smaller. In question 1 they become 1.00 and 0.80, and
> the acid is still limiting.
>
> What **does** change is the amount of product — it doubles too — and
> the amount of leftover zinc, which doubles to 0.20 mol. The limiting
> reagent is fixed by the **ratio** of the amounts, not by their size,
> which is precisely why you compare the two divided values rather than
> the two raw amounts.
>
> **(b) No, and this matters more than it looks.** Percentage yield
> depends on the apparatus, the technique, the drying time, how
> carefully the precipitate was washed, whether the filter was a funnel
> or a Büchner, and how much of the afternoon was available. Run the
> same reaction with better equipment and the yield changes, without any
> chemistry having changed at all.
>
> So a percentage yield is a measurement of **your procedure**, reported
> alongside the reaction rather than about it. Which is why the honest
> way to quote it is "we recovered 89.6% of the theoretical yield under
> this procedure", and why the interesting part of a lab report is the
> account of where the other 10.4% went.

**8.** Three claims about question 2. Correct each.
*(a) "The zinc is limiting, because 5.00 g of zinc is a smaller number
than 50.0 mL of acid."*
*(b) "Once the acid ran out, we threw away the leftover zinc, so our
percentage yield is low."*
*(c) "The limiting reagent is whichever reactant you have fewer moles
of."*

> [!success]- Answer 8
> **(a) Two errors stacked, and the second is hidden by the first.**
> Grams and millilitres are different quantities, so "smaller number"
> is not a comparison at all — you may as well compare a mass with a
> Tuesday. Everything has to be converted to **moles** before any
> comparison is possible.
>
> And even in moles, the raw amounts do not decide it. The acid appears
> with a coefficient of 2, so it is consumed twice as fast per mole as
> the zinc, and the comparison has to account for that. Here the correct
> comparison gives 0.0765 against 0.0250, and the acid is limiting even
> though there is a smaller **mass** of it.
>
> **(b) The leftover excess has nothing to do with percentage yield.**
> The theoretical yield was calculated from the limiting reagent, which
> was the acid, and the acid was entirely consumed. Unreacted zinc was
> never going to become hydrogen and was never counted in the
> theoretical yield, so discarding it changes nothing.
>
> The excess **does** matter for two other reasons: it is wasted
> material, and if it ends up in your recovered product it contaminates
> it. Neither of those is percentage yield.
>
> **(c) Almost right, and wrong exactly where the coefficients live.**
> The limiting reagent is whichever reactant gives the smallest value of
> $\frac{n}{\text{coefficient}}$, not the smallest $n$. Question 3 is
> the counterexample: there are 0.49964 mol of nitrogen and 1.48515 mol
> of hydrogen, so there is **three times as much** hydrogen by amount —
> and the hydrogen is limiting, because it is consumed three times as
> fast.
>
> The claim is only safe when both coefficients happen to be 1, as in
> question 4. Learning it in that form and then meeting question 3 is
> how a rule that worked four times in a row costs you a whole question.

Reference: [[Limiting Reagent and Yield]] and [[Stoichiometry]]. Your
own yield, measured rather than calculated:
[[Percentage Yield of a Precipitate]] and [[The Yield Investigation]].

%%curriculum-start%%
## Curriculum connection

![[D2.6]]
%%curriculum-end%%
