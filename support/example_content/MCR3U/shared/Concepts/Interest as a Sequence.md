---
title: Interest as a Sequence
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Money over time is the most useful place these two strands meet.
Simple interest is an arithmetic sequence wearing a financial hat;
compound interest is a geometric one. Once you see that, the formulas
stop being things to memorise.

## Simple interest is arithmetic growth

Interest calculated only on the original principal adds the same amount
every period:

$$A = P(1 + rt)$$

Deposit $\textdollar 1000$ at 5% simple interest and the balances are
$1050, 1100, 1150, 1200, \dots$ — a common difference of $\textdollar
50$, which is an arithmetic sequence with $t_1 = 1050$ and $d = 50$.
Plot it and you get points on a straight line, because a constant
difference *is* linear growth. Three descriptions, one behaviour:

| Language | The same fact |
| --- | --- |
| Financial | Interest on the principal only |
| Sequence | Arithmetic, common difference $Pr$ |
| Function | Linear, slope $Pr$ |

## Compound interest is geometric growth

Interest calculated on the accumulated balance multiplies instead:

$$A = P(1 + i)^n$$

The same $\textdollar 1000$ at 5% compounded annually gives $1050,
1102.50, 1157.63, \dots$ — a common *ratio* of 1.05. Geometric sequence,
exponential function, curve rather than line.

At small $n$ the two are nearly indistinguishable, which is exactly why
compounding is easy to underestimate. Over 30 years, simple interest
returns $\textdollar 2500$ and compound returns about $\textdollar
4322$. Same rate, same deposit; the difference is entirely in what the
interest is calculated on.

## Where the technology belongs

Some questions have no clean algebraic answer. "What monthly payment
clears a $\textdollar 12{,}000$ loan in four years at 6.9%?" cannot be
rearranged pleasantly by hand, and rearranging it is not the skill being
taught.

Use a **TVM solver** — on a graphing calculator, in a spreadsheet, or
one of the standard online tools — and treat it as five quantities where
knowing four gives the fifth:

| Symbol | What it means |
| --- | --- |
| $N$ | Number of compounding periods |
| $I\%$ | Annual interest rate, as a percentage |
| $PV$ | Present value — what it is worth now |
| $PMT$ | The regular payment |
| $FV$ | Future value — what it is worth at the end |

Two conventions save most of the errors: money coming *to* you is
positive and money leaving you is negative, and $N$ counts compounding
periods rather than years. Get either backwards and the answer is
confidently wrong.

> [!tip] Always sanity-check the machine
> Before accepting a payment figure, multiply it out: 48 payments of
> $\textdollar 287$ is about $\textdollar 13{,}800$ on a $\textdollar
> 12{,}000$ loan, so roughly $\textdollar 1{,}800$ of interest over four
> years at 6.9% — plausible. A tool that says $\textdollar 87$ a month
> has been given the rate as 0.069% or the term in months where it
> wanted years, and the arithmetic check catches it in five seconds.

[[Your Financial Future]] is where you use all of this on decisions
somebody is actually facing, and [[Money Over Time]] has the annuity
formulas the solver is doing for you.

%%curriculum-start%%
## Curriculum connection

![[C3.1]]

![[C3.4]]
%%curriculum-end%%
