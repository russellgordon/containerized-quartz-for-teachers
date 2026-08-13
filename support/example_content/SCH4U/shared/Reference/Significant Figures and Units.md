---
title: Significant Figures and Units
draft: false
created: __CREATED__
enableToc: true
tags:
  - reference
  - quantities
---
Every answer in this course is a number, a unit, and a claim about how
well you know it. Grade 11 established the habit. Grade 12 adds two
things that break it: **logarithms**, which do not obey the ordinary
rules, and **subtractions of nearly equal quantities**, which destroy
precision faster than anything else you will do.

Taking the measurements well in the first place is [[Measuring Well]].

## Counting them

| Situation | Significant? | Example |
| --- | --- | --- |
| Any non-zero digit | always | 4.72 has three |
| Zeros between non-zero digits | always | 3.05 has three; 1002 has four |
| Zeros before the first non-zero digit | never — they only place the decimal | 0.0042 has two |
| Zeros after the last non-zero digit, with a decimal point present | yes | 2.50 has three; 0.04200 has four |
| Zeros after the last non-zero digit, no decimal point | ambiguous | 1500 could be two, three, or four |
| Counted or defined numbers | unlimited — they never limit an answer | the coefficients in a balanced equation; the 1000 in 1 L = 1000 mL |

Scientific notation settles the ambiguous row, which is why it exists:
$1.5 \times 10^3$ claims two significant figures and
$1.500 \times 10^3$ claims four. Both are 1500 and they make different
statements about the instrument.

## Calculating with them

| Operation | Rule | Example |
| --- | --- | --- |
| Multiplication and division | keep the **fewest significant figures** of any input | $4.72 \times 2.0 = 9.4$ |
| Addition and subtraction | keep the **fewest decimal places** of any input | $12.11 + 1.4 = 13.5$ |
| Several steps | carry two extra digits and round **once**, at the end | — |
| Exact numbers | ignore them entirely when deciding | — |

The two rules are genuinely different and confusing them is the most
common error in the topic. Multiplication counts **significant
figures**; addition counts **decimal places**.

## Logarithms are the exception

This is new this year and it catches everybody once.

> In a logarithm, only the digits **after** the decimal point are
> significant. The digits before it record the power of ten and carry no
> information about precision.

So the rule for pH is:

> The number of decimal places in the pH equals the number of
> significant figures in the concentration.

| Concentration | Significant figures | pH | Decimal places |
| --- | --- | --- | --- |
| $1.0 \times 10^{-3}$ mol/L | 2 | 3.00 | 2 |
| $3.4 \times 10^{-5}$ mol/L | 2 | 4.47 | 2 |
| $5.62 \times 10^{-10}$ mol/L | 3 | 9.250 | 3 |

Read the middle row both ways. A concentration known to two significant
figures gives a pH written with two decimal places — **four characters
in total**, and the leading 4 is not one of the two. Writing that pH as
"4.5" throws away a digit you had; writing it as "4.4685" claims four
you never had.

The reverse conversion follows the same rule. A pH of 9.250, with three
decimal places, gives a concentration to three significant figures.

The same applies to $\text{p}K_a$, $\text{p}K_w$, and pOH, because they
are all logarithms. Working through the mechanics is
[[Working with Logarithms in Chemistry]].

## Units this course uses

| Quantity | Symbol | Unit |
| --- | --- | --- |
| Amount of substance | $n$ | mol |
| Concentration | $c$ or $[\ ]$ | mol/L |
| Heat | $Q$ | J |
| Specific heat capacity | $c$ | J/(g·°C) |
| Enthalpy change of a reaction | $\Delta H$ | kJ for the equation as written |
| Molar enthalpy | $\Delta H$ | kJ/mol |
| Rate of reaction | — | mol/(L·s) |
| Standard cell potential | $E^\circ$ | V |
| Temperature | $T$ | K, or °C |

Four traps live in that table.

- **$c$ is doing two jobs.** Concentration and specific heat capacity
  share a symbol, and both appear in the same calorimetry question.
  Label them.
- **$\Delta H$ in kJ is not $\Delta H$ in kJ/mol.** The first belongs to
  a thermochemical equation and scales when you double the coefficients;
  the second is per mole of a named substance and does not. See
  [[Enthalpy]].
- **The units of a rate constant change with the order.** They are not
  memorised; they fall out of the algebra. First order gives s⁻¹, second
  order gives L/(mol·s), third order gives L²/(mol²·s). If your units do
  not come out to mol/(L·s) when you substitute back, the order is
  wrong.
- **Equilibrium constants are quoted with no units at all.** That is a
  convention with a real justification — the expression is strictly
  built from ratios rather than raw concentrations — and at this level
  you simply write $K_a$, $K_{sp}$, and $K_w$ as bare numbers.

Temperature needs its own note. A temperature **difference** is the same
number in degrees Celsius and in kelvins, so $\Delta T$ never needs
converting. An **absolute** temperature in any proportionality does need
converting, at 273.15.

## Where the uncertainty actually lives

The rules above are arithmetic. The judgement is knowing which
measurement is limiting your answer, and in this course it is almost
always a **difference between two similar numbers**.

> [!example] Two readings good to four figures, one answer good to two
> A calorimetry run records an initial temperature of 21.0 °C and a
> final temperature of 27.7 °C. Each reading is good to three
> significant figures.
>
> Their difference is 6.7 °C — **two** significant figures, and every
> subsequent step in the calculation is capped there. The mass was known
> to four figures and the specific heat capacity to three, and neither
> helps at all. The whole precision of the experiment was decided by a
> subtraction.
>
> The same thing happens with a burette. Two readings to a hundredth of
> a millilitre subtract to a titre whose uncertainty is the sum of both,
> which is why titrations are repeated until several concordant titres
> agree rather than trusting one.

Two habits follow.

**Carry the units through the working**, not just onto the answer. They
cancel like algebra, and when they refuse to cancel you have caught an
error before it reached the page. Grams divided by grams per mole leaves
moles; multiplying instead would leave $\text{g}^2/\text{mol}$, which is
not a quantity anything has.

**Say which errors are systematic.** Rounding rules handle random
scatter. They do nothing about a calorimeter that leaks heat every
single time, or a burette read consistently from above. A Grade 12 lab
report names those separately, states which direction each one pushes
the result, and does not claim that repeating the experiment fixed
them — [[Writing a Lab Report]] has the full expectation.

An answer with no units is not an answer. "56" could be joules,
kilojoules per mole, or millilitres, and a marker cannot award anything
for a number that has not said what it is.
