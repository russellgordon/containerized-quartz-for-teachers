---
title: Limiting Reagent and Yield
draft: false
created: __CREATED__
tags:
  - concepts
  - quantities
---
In [[Percentage Yield of a Precipitate]] you calculated how much solid
you should have recovered, filtered it, dried it, weighed it — and got a
different number. Nobody in the room got the calculated value. That gap
is not a failure of the experiment; it is the measurement the experiment
was for.

Two ideas sit behind it. The first is that a reaction stops when one
reactant is used up, no matter how much of everything else is left. The
second is that what you recover is never quite what the arithmetic
promised, and the size and direction of the difference tells you what
happened at the bench.

## Which reactant runs out first

Take the reaction of aluminium with chlorine, and suppose you have
10.0 g of aluminium and 30.0 g of chlorine.

$$2\text{Al(s)} + 3\text{Cl}_2\text{(g)} \rightarrow 2\text{AlCl}_3\text{(s)}$$

There is three times as much chlorine by mass. It is tempting to
conclude that the aluminium must run out first, and that conclusion is
wrong. Masses cannot be compared against a mole ratio; only moles can.

Convert both, then divide each by its own coefficient. That second step
is the one people skip, and it is the whole method: dividing by the
coefficient asks how many *times over* the reaction could run on that
reactant alone.

| Reactant | Mass | Molar mass | Moles | Coefficient | Moles ÷ coefficient |
| --- | --- | --- | --- | --- | --- |
| $\text{Al}$ | 10.0 g | 26.98 g/mol | 0.3706 | 2 | 0.1853 |
| $\text{Cl}_2$ | 30.0 g | 70.90 g/mol | 0.4231 | 3 | **0.1410** |

The smaller quotient identifies the **limiting reagent**: chlorine, in
spite of outweighing the aluminium three to one. Aluminium is the
**excess reagent**, and some of it will still be sitting there when the
reaction stops.

Everything after this point uses the limiting reagent and ignores the
other one entirely. Chlorine gives $\frac{2}{3} \times 0.4231 = 0.2821$
moles of aluminium chloride, and with a molar mass of 133.33 g/mol that
is 37.6 g of product.

You can also find out how much aluminium is left over. The reaction
consumes $\frac{2}{3} \times 0.4231 = 0.2821$ mol of it, out of 0.3706
mol available, leaving 0.0885 mol — about 2.39 g of unreacted metal.

That is worth one check: 7.61 g of aluminium consumed plus 30.0 g of
chlorine consumed is 37.6 g of product. Mass balances, as it must. If
your leftover and your product do not add back up to what you started
with, an arithmetic slip is hiding somewhere.

## Percentage yield

The **theoretical yield** is what the calculation above predicts. The
**actual yield** is what you weighed. The comparison is

$$\text{percentage yield} = \frac{\text{actual yield}}{\text{theoretical yield}} \times 100\%$$

and both quantities must be the same substance in the same units, which
is normally grams of the dried product.

Yields below 100% are ordinary, and the reasons are mostly physical
rather than chemical:

- product left behind on the filter paper, the stirring rod, or the
  walls of the beaker;
- product that is slightly soluble and stayed in the filtrate — "insoluble"
  means low solubility, not zero;
- a reaction that did not go to completion in the time allowed;
- a side reaction consuming some of the reactant to make something else;
- product lost while transferring, which for a fine precipitate is
  easier than it sounds.

A good report names which of these it thinks dominated and points at
evidence. "Some was lost" is not a source of error; "the filtrate was
faintly cloudy after filtering, so some precipitate passed through the
paper" is.

## A yield above 100% is information

Every year somebody calculates 104% and assumes they have made an
arithmetic mistake. Check the arithmetic, certainly. But if the
arithmetic holds, the result is real and it is telling you something
specific: **you weighed more product than exists**, so what is on the
balance is not all product.

There are only a few candidates, and they are diagnosable:

- **It was not dry.** Water is heavy and invisible. This is by far the
  most common cause, and the reason a precipitate is dried to constant
  mass — weigh, dry further, weigh again, and repeat until two readings
  agree to within the balance's resolution.
- **It was contaminated.** Unreacted starting material, or filter paper
  fibres, or the product of a side reaction, all weigh something.
- **The blank was wrong.** The mass of the dry filter paper or the
  watch glass was recorded incorrectly or subtracted twice.

The professional response is to say so in the report and state which
one you think it was. The response that costs marks is quietly rounding
104% down to "about 100%".

> [!success] This is what a good result looks like
> A yield of 78% with a clear account of where the missing 22% went is
> better science, and a better mark, than a yield of 99% with no
> account of anything. The number on its own is not the finding — the
> number *plus the explanation* is. That is the standard
> [[The Yield Investigation]] is assessed against, and the reason
> [[Mistakes Are Data]] is a discussion rather than a slogan.

Practise identifying the limiting reagent before calculating anything in
[[Limiting Reagent Practice]]. Then Unit 4 changes the question from how
much you have to how much is dissolved in it, starting with
[[Water and Solutions]].

%%curriculum-start%%
## Curriculum connection

![[D2.6]]
%%curriculum-end%%
