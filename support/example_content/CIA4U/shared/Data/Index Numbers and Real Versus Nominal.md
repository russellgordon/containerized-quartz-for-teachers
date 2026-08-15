---
title: Index Numbers and Real Versus Nominal
draft: false
created: __CREATED__
tags:
  - data
  - unit-3
---
An index number is not a quantity. It is a comparison, expressed as a
number, against a base period that somebody chose. Once you see that, half
the confusion in macroeconomic data disappears.

The Consumer Price Index is the example you will use most. It does not
measure the price of anything. It measures what a fixed basket of goods
and services costs now relative to what the same basket cost in the base
period, with the base set to 100. When you read that the CPI rose 2.8%
year over year in June 2026 (Statistics Canada, table 18-10-0004-01,
released 20 July 2026), you are reading a change in a ratio, not a price.

## Turning a nominal figure into a real one

Nominal means measured in the dollars of the day. Real means adjusted so
that dollars from different years mean the same thing. The conversion is
one line:

$$\text{real value} = \frac{\text{nominal value}}{\text{price index}} \times 100$$

Do this before you compare any two years. A wage that rose 3% in a year
when prices rose 2.8% bought about 0.2% more. A wage that rose 3% in a
year when prices rose 3.2% bought less than it did before — the worker was
paid more and could afford less, and both halves of that sentence are
true.

## Where the distinction decides an argument

Ontario's general minimum wage is \$17.60 an hour and rises to \$17.95 on
1 October 2026. The government announced that increase on 1 April 2026 and
described it as a 1.9% adjustment tracking the Ontario Consumer Price
Index. That is the point of the mechanism: it is designed to hold the real
wage roughly constant, not to raise it. Whether it succeeds depends
entirely on whether the index used matches what the workers in question
actually buy — food purchased from stores rose 3.9% year over year in June
2026 while shelter rose 1.5%, so a household whose budget is mostly
groceries faced a different inflation rate from the headline one.

> [!warning] The base period is a choice, and choices can be argued with
> Statistics Canada rebases its indexes and updates the basket weights as
> spending patterns change; the Market Basket Measure of poverty moved to a
> 2023 base for the figures released on 29 April 2026. Comparing numbers
> across a rebasing without saying so is a real error, not a technicality.
> Say which base you are using.

Take this into [[Reading a Time Series]] and into any claim that something
"has never been more expensive" — see [[Judging an Economic Claim]].

%%curriculum-start%%
## Curriculum connection

![[D1.4]]

![[A1.4]]
%%curriculum-end%%
