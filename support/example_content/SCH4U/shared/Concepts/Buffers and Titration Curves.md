---
title: Buffers and Titration Curves
publish: true
created: __CREATED__
enableToc: true
tags:
  - concepts
  - equilibrium
---
Add one drop of strong acid to 100 mL of pure water and the pH falls off
a cliff. Add the same drop to 100 mL of a solution that was already
slightly acidic, and — depending entirely on what is dissolved in it —
the pH may barely move.

That difference is not a curiosity. It is why your blood pH stays inside
a narrow range while you exercise, and it is what
[[The Buffer Design]] asks you to engineer deliberately. Everything in
it comes out of [[Acids and Bases]] with nothing new added except the
insistence that **both halves of a conjugate pair are present at once**.

## A buffer is two reservoirs

A **buffer** is a solution containing significant amounts of a weak acid
**and** its conjugate base, which resists a change in pH when a small
amount of strong acid or strong base is added.

The mechanism is two reactions waiting to happen.

- Add **acid**, and the incoming $\ce{H3O+}$ is mopped up by
  the conjugate base:

$$\ce{A-(aq) + H3O+(aq) -> HA(aq) + H2O(l)}$$

- Add **base**, and the incoming $\ce{OH-}$ is mopped up by the weak
  acid:

$$\ce{HA(aq) + OH-(aq) -> A-(aq) + H2O(l)}$$

Either way the strong species is converted into a weak one, and the
ratio of the two reservoirs shifts a little instead of the pH shifting a
lot.

Both must be present **in quantity**. A weak acid solution on its own is
not a buffer, because it has no reservoir of conjugate base to absorb
added acid — and the trace produced by its own ionisation is nowhere
near enough. Two ways to make one:

1. Dissolve a weak acid and a salt of its conjugate base in the same
   solution — ethanoic acid together with sodium ethanoate.
2. Take a weak acid and neutralise **half** of it with strong base. What
   is left is half acid and half conjugate base, which is the same
   mixture arrived at differently.

## Capacity, and how a buffer fails

Buffers are often described as though they hold pH constant. They do
not, and this is the misconception worth killing early.

A buffer **resists** change. The pH does move when acid is added; it
moves far less than it would have. And the resistance is finite, because
each reservoir is finite. **Buffer capacity** is the amount of strong
acid or base a buffer can absorb before one of its two components is
essentially used up — and once that happens the solution behaves like
the plain strong acid or base it now is, and the pH moves suddenly and
far.

Two consequences for designing one:

- **Concentration sets capacity.** A more concentrated buffer holds out
  longer, because there is more of each reservoir.
- **The ratio sets the pH.** A buffer works best when the two reservoirs
  are close to equal, because then it can absorb roughly as much acid as
  base. That happens when the pH of the solution is near the
  $\text{p}K_a$ of the weak acid — so **choose the weak acid whose
  $\text{p}K_a$ is closest to the pH you want**, and get the rest of the
  way with the ratio. A pair pushed more than about one pH unit from its
  $\text{p}K_a$ is lopsided and buffers badly in one direction.

Blood is buffered chiefly by carbonic acid and the hydrogencarbonate
ion, which is a conjugate pair doing exactly what the two arrows above
describe, continuously, in every capillary.

## Reading a titration curve

Titrate a weak acid with a strong base, plotting pH against volume of
base added, and the curve has four distinct regions. Each one is a
different chemical situation, and the exam question is usually "which
region is point X in".

| Region | What is in the flask | Shape of the curve |
| --- | --- | --- |
| Before any base | weak acid only | starts at a moderate pH, not a very low one |
| Buffer region | weak acid and its conjugate base together | broad, shallow, slowly rising |
| Equivalence point | conjugate base only | steep, nearly vertical |
| After equivalence | conjugate base plus excess strong base | flattens out high |

The **half-equivalence point**, halfway along the buffer region, is the
most useful single point on the graph. At that moment exactly half the
acid has been converted, so $[\ce{HA}] = [\ce{A-}]$, those two
terms cancel out of the $K_a$ expression, and

$$\text{pH} = \text{p}K_a$$

That is not an approximation. It is how $\text{p}K_a$ values are
measured in the first place: titrate the acid, find the halfway volume,
read the pH off the graph.

Titrating a **strong** acid instead gives a curve with no buffer region
at all — it starts very low, runs almost flat, jumps vertically, and
flattens again. If a curve you are handed has a long shallow stretch
before the jump, the acid was weak, and you can read its
$\text{p}K_a$ off that stretch.

> [!success]- Finding an unknown concentration from titration data
> A 25.00 mL sample of a monoprotic acid of unknown concentration
> requires 18.60 mL of 0.1050 mol/L sodium hydroxide to reach the
> equivalence point. Find the concentration of the acid.
>
> $$\begin{aligned} n(\ce{NaOH}) &= (0.01860\ \text{L})(0.1050\ \text{mol/L}) \\ &= 1.953 \times 10^{-3}\ \text{mol} \end{aligned}$$
>
> The acid is monoprotic, so the mole ratio is one to one and the sample
> contained $1.953 \times 10^{-3}$ mol of acid.
>
> $$\begin{aligned} c(\text{acid}) &= \frac{1.953 \times 10^{-3}\ \text{mol}}{0.02500\ \text{L}} \\ &= 0.07812\ \text{mol/L} \end{aligned}$$
>
> Four significant figures, because every measurement carried four. Note
> what this calculation did **not** need: the identity of the acid,
> whether it was strong or weak, and the pH at any point. The
> equivalence point is defined by moles, and moles are all that was
> used.

## The equivalence point is not pH 7

The **equivalence point** is where the moles of titrant added are
exactly what the balanced equation requires. It is a stoichiometric
definition, and it says nothing directly about pH.

| Titration | What is left at equivalence | pH there |
| --- | --- | --- |
| Strong acid with strong base | a neutral salt | 7.00, at 25 °C |
| **Weak** acid with strong base | the conjugate base of a weak acid | **above** 7 |
| Strong acid with **weak** base | the conjugate acid of a weak base | **below** 7 |

The middle row is the one that catches people. Titrate ethanoic acid to
its equivalence point and the flask contains a solution of ethanoate
ions — and an ethanoate ion is a base, as [[Acids and Bases]] set out.
It takes protons from water, produces hydroxide, and the solution is
basic. There is nothing left over and no acid remains, and the pH is
still above 7.

> [!warning] The endpoint is not the equivalence point either
> The **equivalence point** is a fact about the chemistry. The
> **endpoint** is where your indicator changes colour, which is a fact
> about your indicator. They coincide only if you have chosen well.
>
> Choose an indicator whose colour-change range falls inside the steep
> part of the curve — which means bracketing the equivalence pH, not the
> number 7. Phenolphthalein changes in the mildly basic range and is the
> right choice for a weak acid against a strong base. Methyl orange
> changes in the acidic range and is right for a strong acid against a
> weak base. Using the wrong one puts your endpoint somewhere on the
> gentle part of the curve, where a large volume of titrant makes only a
> small pH change — and your answer is then wrong by a margin no amount
> of careful burette reading will recover.

> [!danger] Standard solutions and burettes
> The sodium hydroxide used for titration is dilute and standardised,
> and it still deserves respect: an alkali burn is painless at first and
> penetrates deeper than the equivalent acid burn. Eye protection is on
> from the moment the burette is filled. Fill the burette at bench
> level, not above your head. Nothing is ever pipetted by mouth. Rinse
> any splash immediately and for longer than feels necessary, and report
> it.

Practise the calculations in [[Acids and Bases Practice]], and get the
logarithms themselves solid in
[[Working with Logarithms in Chemistry]] — a pH answer with the wrong
number of decimal places is making a false claim about the measurement,
in exactly the way [[Significant Figures and Units]] describes. Then
design a buffer to a specification in [[The Buffer Design]].

%%curriculum-start%%
## Curriculum connection

![[E3.8]]

![[E2.5]]
%%curriculum-end%%
