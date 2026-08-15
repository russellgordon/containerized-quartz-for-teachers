---
title: Significant Figures in Practice
publish: true
created: __CREATED__
enableToc: true
tags:
  - skills
  - quantities
---
Significant figures are not a marking convention invented to annoy you.
They are how a number says how well it is known, and they are the only
part of a calculated answer that carries information you did not compute.

Everything on this page follows from one sentence: **you cannot know a
result better than you knew the measurements that produced it.**

## The digits come from the instrument

Pick up a 100 mL graduated cylinder marked every 1 mL. You can see that
the meniscus sits between 47 and 48, and you can judge that it is about
a third of the way up, so you write **47.3 mL**.

Three digits, and they are three different kinds of thing. The 4 and the
7 you read off the glass; anybody standing beside you would write the
same two. The 3 you estimated, and the person beside you might have
written 2 or 4. That last digit is **uncertain, and it is still
significant** — it is a real, useful claim about where the meniscus was,
and throwing it away by writing 47 mL discards information the
instrument gave you for free.

Now measure the same volume with a burette, graduated every 0.1 mL, and
you write 47.32 mL. Four figures. Nothing about the liquid changed. The
count of significant figures is a fact about the **instrument**, not
about the substance, and that is the idea the rest of this page is built
on.

| Instrument | You can read | You estimate | So you report |
| --- | --- | --- | --- |
| Beaker graduations | Nothing usefully | — | Do not report a measurement from it |
| 100 mL graduated cylinder, 1 mL marks | Whole millilitres | Tenths | 47.3 mL |
| Burette, 0.1 mL marks | Tenths | Hundredths | 47.32 mL |
| Balance reading to 0.01 g | The display | Nothing — the balance already estimated | 12.46 g |
| Balance reading to 0.0001 g | The display | Nothing | 12.4613 g |

A digital display has already done the estimating for you. Report every
digit it shows, including a trailing zero — a balance reading 12.40 g is
telling you something different from one reading 12.4 g, and dropping
the zero is discarding a measurement.

## Counting them

| Number | Significant figures | Why |
| --- | --- | --- |
| 47.32 | 4 | Every non-zero digit counts |
| 2.005 | 4 | Zeros between digits count |
| 0.00450 | 3 | Leading zeros are placeholders; the trailing zero after a decimal point counts |
| 100.0 | 4 | The decimal point makes the trailing zeros meaningful |
| 1500 | Ambiguous | Could be 2, 3, or 4 — nothing tells you |
| $1.5 \times 10^{3}$ | 2 | Scientific notation removes the ambiguity |
| $1.500 \times 10^{3}$ | 4 | Same value, different claim about precision |

The 1500 row is the reason scientific notation exists in a chemistry
course. If a measured quantity has trailing zeros before the decimal
point, write it in scientific notation and the ambiguity disappears.

## The two rules, and why they are different

Almost everyone can recite these. Far fewer can say why they are not the
same rule, which is why the second one gets applied where the first
belongs.

**Multiplying or dividing:** the answer carries the **fewest significant
figures** of any measurement in it.

**Adding or subtracting:** the answer carries the **fewest decimal
places** of any measurement in it.

The reason is that uncertainty combines differently under the two
operations. When you multiply, **relative** uncertainties combine — a
quantity known to 2% times a quantity known to 0.1% gives an answer
known to about 2%. When you add, **absolute** uncertainties combine — a
value uncertain by 0.01 g plus a value uncertain by 0.1 g gives a sum
uncertain by about 0.1 g, and a gram is a gram regardless of how big the
number in front of it is.

> [!example]- Worked: watch the rules do their jobs
> **Dividing.** A sample of sodium chloride has a mass of 4.6 g on a
> balance reading to 0.1 g, and its molar mass is 58.44 g/mol.
>
> $n = \frac{4.6 \text{ g}}{58.44 \text{ g/mol}} = 0.078713… \text{ mol}$
>
> The mass is uncertain by 0.1 in 4.6, which is about 2%. Two percent of
> 0.0787 is 0.0016, so the uncertainty lands in the **third** decimal
> place, and there is no honest way to report the fourth. Answer:
> 0.079 mol — two significant figures, exactly as the rule promised,
> because the mass had two.
>
> **Adding.** Now add 12.11 g and 0.3 g.
>
> $12.11 \text{ g} + 0.3 \text{ g} = 12.41 \text{ g}$
>
> The 0.3 is uncertain by about 0.1 g, so the sum is uncertain by about
> 0.1 g, and the answer is 12.4 g — **three** significant figures, from
> ingredients with four and one. If you had applied the multiplication
> rule here you would have reported one significant figure, which is
> 10 g, which is nonsense. The rules are different because the
> arithmetic of uncertainty is different.

## Subtraction is where precision goes to die

This one deserves its own section because it is not intuitive and it
matters constantly — every mass you take by difference goes through it.

Weigh a crucible with a residue in it, then weigh the empty crucible:

$$48.27 \text{ g} - 46.19 \text{ g} = 2.08 \text{ g}$$

Both readings had four significant figures. The answer has three. You
did not do anything wrong; subtracting two large, similar numbers throws
away the leading digits they had in common, and those digits were most
of what you knew.

Push it further. Same balance, a smaller sample:

$$48.27 \text{ g} - 48.19 \text{ g} = 0.08 \text{ g}$$

Four figures and four figures give **one**. Each reading was uncertain
by 0.01 g, so the difference is uncertain by about 0.02 g — which is a
quarter of the answer. You have measured that sample to ±25%, on a
balance that measures to better than a tenth of a percent.

> [!warning] This is a design problem, not an arithmetic problem
> The fix is not to write more digits. The fix is to change the
> procedure: weigh the sample on its own rather than by difference from
> a heavy container, use a lighter container, or use a sample large
> enough that the difference is a decent fraction of the readings. If a
> quantity you care about comes out of the subtraction of two nearly
> equal numbers, that is the weakest link in your whole investigation
> and it belongs in the limitations section of
> [[Writing a Lab Report]].

## Rounding in the middle: the commonest silent error

Here is the one that costs the most marks in this course, and it never
announces itself.

Take the two crucible masses again, but with a four-figure balance:
24.5732 g and 24.1189 g. Suppose the rest of your data has three
significant figures, so you sensibly decide the answer will have three —
and you round each reading to three figures on the way past.

| What you do | The result |
| --- | --- |
| Round first: $24.6 - 24.1$ | 0.5 g |
| Subtract first: $24.5732 - 24.1189$ | 0.4543 g, then round to 0.454 g |

Ten percent apart. Both numbers you rounded were correct to three
significant figures. The rounding was individually harmless and jointly
catastrophic, for exactly the reason the previous section gave: the
digits you discarded were the ones the subtraction was about to promote.

**So: round once, at the end.** Carry every digit your calculator has
through the intermediate steps — or if you are writing them down, keep
at least two guard digits beyond what the final answer will show. The
significant-figure rules describe how to *report* an answer. They are
not instructions for what to do halfway through.

## Numbers that are exact

Some numbers in a calculation have no uncertainty at all, and they never
limit your answer.

- **Counted things.** Three trials, twelve test tubes.
- **Defined conversions.** 1 L is exactly 1000 mL, 1 kg is exactly
  1000 g. These are definitions, not measurements.
- **Coefficients in a balanced equation.** The 2 in
  $\ce{2H2 + O2 -> 2H2O}$ means
  exactly two, in the way that a dozen means exactly twelve.
- **The 100 in a percentage.**

Treat all of them as having infinitely many significant figures. A
common wrong move is to see the 2 in a mole ratio, count it as one
significant figure, and report a stoichiometry answer to one figure.

**Molar masses** are a near relation. They are measured quantities, but
you get to choose how many digits to take from the periodic table, so
take enough that they are never the limiting factor — a couple more
digits than your least precise measurement. Using 24 for magnesium when
your balance gave you four figures is throwing away the balance.

## Reporting a measurement with its uncertainty

Three significant figures says roughly how well you know a value.
Sometimes you need to say it exactly, and the form is

$$V = (25.00 \pm 0.04) \text{ mL}$$

read as "somewhere near 25.00, with about 0.04 either side". Where that
0.04 came from, in this case: a burette read twice, each reading good to
about ±0.02 mL, and absolute uncertainties add when you subtract.

Two conventions make it readable:

1. **Quote the uncertainty to one significant figure** — 0.04, not
   0.0412.
2. **Round the value to the same decimal place as the uncertainty.**
   Writing $0.078713 \pm 0.002$ is self-contradictory: the digits after
   the 9 are being claimed and disowned in the same expression. Write
   $0.079 \pm 0.002$.

For combining uncertainties through a calculation, two rules cover
nearly everything you will meet:

| Operation | Combine the | Example |
| --- | --- | --- |
| Adding or subtracting | Absolute uncertainties | $\pm 0.02$ and $\pm 0.02$ give $\pm 0.04$ |
| Multiplying or dividing | Relative (percentage) uncertainties | 2% and 0.1% give about 2% |

Notice that the second row is the multiplication rule for significant
figures, stated in a way that lets you carry it through a calculation
instead of only counting digits at the end. The significant-figure rules
are a shorthand for this; the percentages are the thing itself.[^1]

## Before you write the answer down

- [ ] Does every measured number have a unit?
- [ ] Did you round only once, at the end?
- [ ] Did you apply the decimal-places rule to additions and the
      significant-figures rule to multiplications, rather than one rule
      to everything?
- [ ] Are exact numbers and coefficients being treated as exact?
- [ ] Is your molar mass carrying more digits than your measurement?
- [ ] Does the number of digits in your answer match what your
      **worst** measurement could support?
- [ ] If you are comparing two results, is the gap between them bigger
      than the uncertainty in them?

That last one is not really a significant-figures question. It is the
question the whole course keeps asking, and this page is what lets you
answer it — see [[What Counts as Evidence]] and
[[Significant Figures and Units]] for the reference version of the
rules.

[^1]: One case that catches people later: quantities defined as
    logarithms, such as pH. Only the digits **after** the decimal point
    in a logarithm are significant, because the part before it encodes
    the power of ten rather than a measured amount. A hydrogen-ion
    concentration known to two significant figures gives a pH written to
    two decimal places — pH 3.00 is a two-figure measurement, not a
    three-figure one. You will meet this properly in
    [[Acids and Bases]].

%%curriculum-start%%
## Curriculum connection

![[A1.13]]

![[A1.12]]
%%curriculum-end%%
