---
title: Significant Figures and Units
publish: true
created: __CREATED__
enableToc: true
tags:
  - reference
  - quantities
---
Every answer in this course is a number, a unit, and a statement about
how well you know it. This page is the lookup sheet for the last two.
Working through the habits is [[Significant Figures in Practice]]; taking
the measurements well in the first place is [[Measuring Well]].

## Counting significant figures

| Situation | Significant? | Example |
| --- | --- | --- |
| Any non-zero digit | always | 4.72 has three |
| Zeros between non-zero digits | always | 3.05 has three; 1002 has four |
| Zeros before the first non-zero digit | never — they only place the decimal | 0.0042 has two |
| Zeros after the last non-zero digit, when a decimal point is present | yes | 2.50 has three; 0.04200 has four |
| Zeros after the last non-zero digit, with no decimal point | ambiguous | 1500 could be two, three, or four |
| Counted or defined numbers | unlimited — they never limit an answer | 12 in a dozen; the 1000 in 1 L = 1000 mL; the coefficients in a balanced equation |

The ambiguous row is solved by scientific notation, which is the reason
scientific notation exists. Writing $1.5 \times 10^3$ says two
significant figures; $1.500 \times 10^3$ says four. Both are 1500 and
they make different claims about the measurement.

## Calculating with them

| Operation | Rule | Example |
| --- | --- | --- |
| Multiplication and division | the answer keeps the **fewest significant figures** of any input | $4.72 \times 2.0 = 9.4$ |
| Addition and subtraction | the answer keeps the **fewest decimal places** of any input | $12.11 + 1.4 = 13.5$ |
| Several steps | carry one or two extra digits through and round **once**, at the end | — |
| Exact numbers | ignore them when deciding — they are infinitely precise | — |

The two rules are genuinely different and mixing them up is the most
common error. Multiplication counts *significant figures*; addition
counts *decimal places*. In the addition example above, 12.11 has four
significant figures and 1.4 has two, but the answer has three — because
1.4 is only known to one decimal place, and adding a number you know to
the tenth cannot produce an answer good to the hundredth.

> [!example] Where the rule earns its keep
> A balance reads 1.0 g for a paperclip. Divide by the molar mass of
> iron, 55.85 g/mol, and the calculator returns 0.017905. Multiply by
> Avogadro's number and it returns $1.0782 \times 10^{22}$.
>
> The correct answer is $1.1 \times 10^{22}$ atoms — **two**
> significant figures, because the mass had two. Writing
> $1.0782 \times 10^{22}$ claims you can distinguish that paperclip
> from one containing $1.0783 \times 10^{22}$ atoms, using a balance
> that could not tell 1.0 g from 1.04 g. The extra digits are not more
> accurate; they are a false claim about the instrument.

## Reading an instrument

- **Analogue scales** — record every digit you are certain of, and then
  estimate one more between the finest graduations. A ruler marked in
  millimetres gives you readings to a tenth of a millimetre, estimated.
- **Digital displays** — record every digit shown, including trailing
  zeros. A balance reading 2.50 g is claiming three significant figures
  and you must write all three.
- **Liquid volumes** — read the bottom of the meniscus, at eye level.
  Looking down at it introduces an error that is consistent, invisible,
  and entirely yours.
- **Burettes** — the scale increases downwards, and the volume delivered
  is the final reading minus the initial one. Both readings need the
  estimated digit.

## Units you will use constantly

| Quantity | Unit | Symbol |
| --- | --- | --- |
| Amount of substance | mole | mol |
| Mass | gram, kilogram | g, kg |
| Volume | litre, millilitre | L, mL |
| Molar mass | grams per mole | g/mol |
| Concentration | moles per litre | mol/L |
| Pressure | kilopascal | kPa |
| Temperature | kelvin, degree Celsius | K, °C |

| Prefix | Symbol | Multiplier |
| --- | --- | --- |
| kilo | k | $10^{3}$ |
| deci | d | $10^{-1}$ |
| centi | c | $10^{-2}$ |
| milli | m | $10^{-3}$ |
| micro | µ | $10^{-6}$ |
| nano | n | $10^{-9}$ |

## Conversions worth knowing by heart

- 1 L = 1000 mL, and 1 mL = 1 cm³
- 1 kg = 1000 g
- $T$ in kelvins $= t$ in degrees Celsius $+\ 273.15$
- 1 atm = 101.325 kPa = 760 mmHg
- 1 kPa = 1000 Pa

> [!warning] Kelvin is not optional in a gas law
> Every temperature in every calculation in [[The Gas Laws]] is in
> kelvins. Using Celsius does not give an approximate answer; it gives a
> wrong one, because the gas laws are proportionalities and Celsius has
> its zero in an arbitrary place.

## Carrying units through the calculation

Write the units into the working, not just onto the answer. They cancel
like algebra, and when they do not cancel you have caught a mistake
before it reached the page:

$$\frac{10.0 \text{ g}}{44.11 \text{ g/mol}} = 0.227 \text{ mol}$$

Grams over grams-per-mole leaves moles, which is what you wanted.
Multiplying instead would have given $\text{g}^2/\text{mol}$, which is
not a quantity anything has. This is the fastest self-check available in
[[Stoichiometry]], and it costs nothing.

An answer with no units is not an answer. "29.9" could be grams, moles,
or molecules, and a marker cannot award anything for a number that has
not said what it is.
