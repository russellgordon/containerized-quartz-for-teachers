---
title: Reading a Data Table
draft: false
created: __CREATED__
enableToc: true
tags:
  - skills
---
A data table looks like a list of facts and is nothing of the kind. It
is a set of measurements, made by people, under conditions somebody
chose, reported to a precision somebody decided was honest. Every one of
those choices is written down somewhere on the page, usually in smaller
type than the numbers.

This course will hand you tables constantly — periodic trends,
solubilities, the activity series, molar masses. Learning to read the
apparatus around a table is worth more than memorising anything in one.

## Read these four things before you read a number

1. **What quantity is this?** Atomic radius and ionic radius are
   different columns and behave differently. Melting point and boiling
   point sit next to each other and get swapped constantly.
2. **In what units?** See the next section; this is where most of the
   damage happens.
3. **Under what conditions?** Solubility depends on temperature.
   Density depends on temperature. Gas volumes depend on temperature and
   pressure. A table without stated conditions is either incomplete or
   using a convention it expects you to know.
4. **To what precision?** How many digits are printed, and does the
   table say anything about uncertainty?

Only then look at the row you came for.

## Units are where the mistakes actually happen

| The quantity | Units you will meet | The trap |
| --- | --- | --- |
| Solubility | g per 100 mL of water; g/L; mol/L | Three different numbers for the same substance. Sodium chloride is about 36 in the first and about 6 in the third |
| Atomic radius | picometres (pm); nanometres (nm); ångströms (Å) | An older table in ångströms gives numbers a hundred times smaller than one in picometres |
| Concentration | mol/L; g/L; percent | Percent by mass and percent by volume are not interchangeable, and the table may not say which |
| Ionisation energy | kJ/mol; eV | A factor of about 96 between them |
| Temperature | °C; K | Fine for a difference, disastrous in a gas law |

None of those is a hard idea. All of them are things people get wrong at
speed, in the last ten minutes of a period, because they read the number
and not the heading.

## What the digits are telling you

A published table quotes a value to the precision it is actually known
to. That is a claim, and you should read it as one.

The molar mass of iron appears as 55.845 in a reference handbook, as
55.85 on a classroom periodic table, and as 56 in a hurried textbook.
The first is what the measurement supports; the second is rounded for
convenience and is perfectly usable; the third has quietly discarded
information you may need. Which one to take depends on your own
measurement — carry more digits than your balance gave you, as
[[Significant Figures in Practice]] explains, and the table will never
be your limiting factor.

There is something worth noticing behind those digits, too. The molar
mass of chlorine is printed as 35.45, and **no chlorine atom has that
mass**. It is a weighted average over the isotopes that occur naturally,
in the proportions they occur in. The number in the table is not a
property of an atom; it is a property of a typical sample of the
element, and the table is quietly assuming your sample is typical.

## Qualitative tables are mostly exceptions

Some of the most useful tables in this course contain no numbers at all.
[[Solubility Rules]] is a list of generalisations, each with a short
list of exceptions attached — and the exceptions are not fine print.
They are the content. A rule that says "most carbonates are insoluble"
tells you very little; the same rule with its exceptions tells you which
precipitate will form.

The same is true of [[The Activity Series]]. It is a ranking assembled
from a large number of individual observations, and its only claim is
about which reactions go, not about how fast or how far. Reading it as
more than that is reading something into it that nobody measured.

> [!example]- Reading one row properly, all the way through
> Suppose a solubility table gives, for potassium nitrate:
> **31.6 g / 100 mL, 20 °C**.
>
> Unpacked, that says: at twenty degrees Celsius, one hundred millilitres
> of water will dissolve 31.6 grams of potassium nitrate and no more.
> Three significant figures, so it was measured carefully. The
> temperature is quoted because the value changes strongly with it — for
> this substance, a good deal more dissolves when warm, which is exactly
> why it can be recrystallised by cooling.
>
> What the row does **not** say: how fast it dissolves; whether it
> dissolves at all in anything other than water; whether the same number
> holds if something else is already dissolved in that water. Those are
> three separate measurements that this table did not make, and
> assuming them is the single commonest way a table gets misused.

## Interpolating, and the line you must not cross

If a table gives you values at 20 °C and 30 °C and you need 25 °C,
estimating between them is **interpolation**, and it is usually
reasonable — say so, and say you did it.

Estimating *beyond* the last row is **extrapolation**, and it is a
guess wearing a table's clothes. The table stops where it stops for a
reason, and frequently the reason is that the behaviour changes: the
substance decomposes, the solution saturates, the gas condenses. Beyond
the last row you have no evidence at all, only a pattern you liked.

## Where the good tables are

You are asked to find sources yourself in this course, so it is worth
being concrete about what a good one looks like.

**Reliable ground:** a published chemical data handbook; the periodic
table issued in this room; a safety data sheet from the supplier, which
has to be accurate because people handle the product; a national
standards, metrology, or health body; a university or government
database that says where its numbers came from.

**Ground to be careful on:** an encyclopaedia entry, which is often
excellent and is a *pointer* to the source rather than the source; a
textbook other than the one you have, which may use a different
convention; a page that gives a number with no conditions attached.

**Ground to stay off:** any page with no author and no citation; a
forum answer; a site selling the substance, or selling the alternative;
anything that generated the number rather than measuring it. If you
cannot find out where a value came from, you cannot defend it, and a
number you cannot defend is worth less than no number at all.

## Judging a source you found yourself

- [ ] Who compiled it, and what are they for?
- [ ] Does it say where the measurements came from?
- [ ] Are the conditions stated?
- [ ] Are the units stated, unambiguously?
- [ ] Is the precision plausible for the quantity, or suspiciously high?
- [ ] Does an independent source agree — and is it genuinely
      independent, or has everyone copied the same page?
- [ ] Does anybody benefit from this number being what it says?

That last one is not cynicism. A supplier's page about its own product,
a company's page about its own emissions, and a campaign's page about
somebody else's emissions are all sources with an interest, and having
an interest does not make a number wrong. It makes it something to check
against a source with a different interest.

> [!tip] Two sources beat one, and disagreement is a finding
> If two independent tables give you different values, do not average
> them and move on. Find out why: different temperatures, different
> units, different isotopic assumptions, different definitions of the
> quantity. The reason is almost always more interesting than either
> number, and writing it down is the sort of thing that turns a decent
> report into a strong one.

Related: [[Periodic Trends]] for the first real table this course throws
at you, [[What Counts as Evidence]] for how a published value competes
with your own measurement, and [[Writing a Lab Report]] for citing what
you used.

%%curriculum-start%%
## Curriculum connection

![[A1.9]]

![[A1.3]]
%%curriculum-end%%
