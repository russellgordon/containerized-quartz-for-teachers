---
title: Reading a Data Table
publish: true
created: __CREATED__
enableToc: true
tags:
  - skills
---
A data table looks like a list of facts and is nothing of the kind. It
is a set of measurements, made by people, under conditions somebody
chose, reported to a precision somebody decided was honest, using
conventions somebody agreed on.

Grade 11 leaned on tables. This course *runs* on them. Almost every
calculation in Units 3, 4, and 5 begins by taking a number out of a data
booklet, and the number is only as good as your reading of the small
type around it.

## Read these five things before you read a number

1. **What quantity is this?** $K_a$ and $K_b$ sit in adjacent columns
   and behave in opposite directions. Enthalpy of formation and enthalpy
   of combustion are different quantities for the same substance.
2. **In what units?** kJ/mol and J/mol differ by a factor of a thousand,
   and both appear in real sources.
3. **At what temperature?** See the next section. This is the one that
   matters most in this course and is the one most often skipped.
4. **Under what other conditions?** Standard state, standard pressure,
   1 mol/L, aqueous, pure — every one of these is an assumption the
   table made and your flask may not meet.
5. **To what precision?** How many digits are printed, and does the
   source say anything about uncertainty?

Only then look at the row you came for.

## Every constant in this course carries a temperature

Grade 11 tables were mostly about substances: molar masses, solubility
rules, an activity series. Those do not change much with conditions.

The Grade 12 tables are different in kind. $K_c$, $K_a$, $K_b$, $K_w$,
$K_{sp}$, and $E^\circ$ are all **equilibrium quantities**, and every one
of them is a function of temperature. A value quoted without a
temperature is not a conservative value or a rough value. It is an
incomplete one.

| Quantity | Standard conditions it usually assumes | What changes if you ignore that |
| --- | --- | --- |
| $K_c$, $K_a$, $K_b$ | A stated temperature, usually 25 °C | The constant itself is different at your temperature; the disagreement is real and is not your error |
| $K_w$ | 25 °C, giving $1.0 \times 10^{-14}$ | The neutral pH is not 7 at any other temperature |
| $K_{sp}$ | 25 °C, in pure water | A common ion, or anything that complexes the ion, changes what dissolves |
| $E^\circ$ | 1 mol/L, 25 °C, 100 kPa, relative to the hydrogen electrode | Your measured cell potential differs, predictably, and saying so is the answer |
| $\Delta H_f$ | Elements in their standard states, at a stated temperature | Adding enthalpies from two sources with different reference states gives a wrong total |

The practical consequence is a habit: **write the temperature in your
notebook every time you take a value out of the booklet**, next to the
value. It costs three seconds and it turns "my $K_c$ disagreed" into a
sentence you can actually investigate.

## Sign conventions, which are decisions rather than facts

Two tables in this course will hand you a number whose sign came from an
agreement rather than from an instrument, and both catch people.

**Standard reduction potentials** are all written as reductions, even
for the half-reaction that is going to run backwards in your cell. When
a half-reaction is reversed, its potential changes sign. And the whole
table is relative: the hydrogen electrode is *defined* as exactly zero,
so no value in the column is an absolute quantity. A value of zero there
is a choice, not a measurement, and every other entry is a difference
from it. [[Reading a Reduction Potential Table]] works through what
follows from that.

**Enthalpies of formation** are zero for an element in its standard
state — again by definition, not because nothing happens when an element
sits there. That convention is what makes Hess's law arithmetic come out
right; see [[Hess's Law]].

> [!important] Negative is not the same as spontaneous, and large is not the same as fast
> Two sign-shaped misreadings, both common enough to be worth naming.
>
> A negative $\Delta H$ tells you a reaction releases energy. It does
> not by itself tell you the reaction will happen, and it says nothing
> whatever about how long it will take — that is
> [[Collision Theory and Catalysts]], a different table and a different
> question.
>
> A large $K_c$ tells you the position of equilibrium lies far to the
> right. It does not tell you the reaction is quick. A reaction can have
> an enormous equilibrium constant and take years, which is precisely
> why [[Dynamic Equilibrium]] and [[Rates of Reaction]] are separate
> units.

## What the digits are telling you

A published table quotes a value to the precision it is actually known
to. That is a claim, and you should read it as one.

Two rules that keep you out of trouble:

- **Carry more digits than your own measurement gave you.** If your
  concentration is known to two significant figures, a $K_a$ printed to
  two is fine and a $K_a$ printed to four costs you nothing. The table
  should never be your limiting factor.
- **Do not inherit the table's precision into your answer.** A booklet
  value of $1.8 \times 10^{-5}$ combined with a concentration you
  measured to two figures gives a two-figure result, no matter how
  confident the printed constant looks.

There is something worth noticing behind those digits, too.
Equilibrium constants are printed without units, and that is not
sloppiness — it follows from how the quantity is defined.[^1]

## Interpolating, and the line you must not cross

If a table gives values at 20 °C and 30 °C and you need 25 °C,
estimating between them is **interpolation**. It is usually reasonable;
say so, and say you did it.

Estimating *beyond* the last row is **extrapolation**, and it is a guess
wearing a table's clothes. The table stops where it stops for a reason,
and frequently the reason is that the behaviour changes: the substance
decomposes, the solution saturates, the assumption of ideal behaviour
gives out. Beyond the last row you have no evidence at all, only a
pattern you liked.

Equilibrium constants are a particularly bad thing to extrapolate,
because they do not vary linearly with temperature. Two rows and a ruler
will give you a number, and the number will be wrong in a way that looks
completely reasonable.

## Where the good tables are

You are asked to find sources yourself in this course, so it is worth
being concrete about what a good one looks like.

**Reliable ground:** the data booklet issued in this room, which is
where every value in an assessment will come from; a published chemical
data handbook; a safety data sheet from the supplier, which has to be
accurate because people handle the product; a national standards,
metrology, or health body; a university or government database that says
where its numbers came from.

**Ground to be careful on:** an encyclopaedia entry, which is often
excellent and is a *pointer* to a source rather than the source; a
textbook other than the one you have, which may use a different
convention for standard pressure or a different reference state; any
page that gives a constant with no temperature attached.

**Ground to stay off:** a page with no author and no citation; a forum
answer; a site selling the substance, or selling the alternative;
anything that generated the number rather than measuring it. If you
cannot find out where a value came from, you cannot defend it, and a
number you cannot defend is worth less than no number at all.

## Judging a source you found yourself

- [ ] Who compiled it, and what are they for?
- [ ] Does it say where the measurements came from?
- [ ] Are the temperature and the other conditions stated?
- [ ] Are the units and the sign convention unambiguous?
- [ ] Is the precision plausible for the quantity, or suspiciously high?
- [ ] Is the source **adequate** for the question you are asking, or is
      it a sound answer to a different one?
- [ ] Does an independent source agree — genuinely independent, or has
      everyone copied the same page?
- [ ] Does anybody benefit from this number being what it says?

That last one is not cynicism. A supplier's page about its own product,
a company's page about its own emissions, and a campaign's page about
somebody else's are all sources with an interest, and having an interest
does not make a number wrong. It makes it something to check against a
source with a different interest — the argument is worked through in
[[What Counts as Evidence]].

> [!tip] Two sources beat one, and disagreement is a finding
> If two tables give different values, do not average them and move on.
> Find out why: different temperatures, different standard pressures,
> different reference states, different definitions of the quantity, a
> different convention for whether water is counted as liquid or vapour.
> The reason is almost always more interesting than either number, and
> writing it down is what turns a decent report into a strong one.

[^1]: An equilibrium constant is properly defined in terms of
    *activities* rather than concentrations — a quantity that compares
    each species against a chosen reference state and is therefore a
    ratio with no units of its own. For dilute solutions the activity is
    very nearly the concentration in mol/L, which is why this course
    writes the expression with square brackets and never worries about
    it. The convention explains something otherwise puzzling: why
    $K_c$ for a reaction with different numbers of particles on each
    side still comes out as a plain number, and why you cannot fix the
    units by inspection.

%%curriculum-start%%
## Curriculum connection

![[A1.9]]

![[A1.3]]
%%curriculum-end%%
