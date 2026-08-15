---
title: Money Over Time
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
In [[The Allowance Choice]], the doubling penny looked laughable next
to the flat weekly allowance — until it wasn't, suddenly and by a
mile. That collision between steady adding and steady multiplying is
the entire mathematics of money, and you already own both halves of
it.

## Interest is a sequence wearing dollar signs

**Simple interest** pays the same amount every period: the balance is
an arithmetic sequence, and its graph is a straight line.
**Compound interest** pays interest *on the interest*: each balance
is the previous one multiplied by the same factor, which makes the
balances a geometric sequence — and the amount function

$$
A = P(1 + i)^n
$$

is [[The Exponential Function]] wearing dollar signs. Here $P$ is the
principal, $i$ the interest rate *per compounding period*, and $n$
the *number of periods*. Watch the gap open — \$1000 at 6% for ten
years:

| Arrangement | Amount after 10 years |
| --- | --- |
| Simple interest | \$1600.00 |
| Compounded annually | \$1790.85 |
| Compounded monthly | \$1819.40 |

The compounding column pulls further ahead every year, and compounding
*more often* at the same nominal rate quietly pays more. That is the
constant-ratio engine at work.

## The formula and its fine print

The fine print is $i$ and $n$. "6% per year, compounded monthly for
ten years" means $i = 0.06 \div 12 = 0.005$ and
$n = 12 \times 10 = 120$ — so
$A = 1000(1.005)^{120} \approx \textdollar 1819.40$. Misreading the
period is the classic error here, and it
is a productive one: compare the wrong answer with the right one and
you *feel* what compounding frequency does — [[Mistakes Are Data]],
with a dollar value attached.

Reverse questions — "how long until it doubles?" — are solved the
same honest ways as any exponential question at this stage:
systematic guess-and-check on $n$, or trace the graph in
[[Using Desmos|Desmos]]. At 8% compounded annually,
$(1.08)^n = 2$ lands almost exactly at $n = 9$ years.

## Annuities — and the other side of the ledger

Almost nobody saves with one deposit. An *annuity* is a stream of
equal deposits at regular intervals — and since each deposit
compounds for a different length of time, the future value is a
geometric [[Series|series]]: the last deposit grows not at all, the
first grows longest, and the sum formula adds the whole stream in one
line.

Time in the market beats size of deposit, and the gap is not subtle.
At 6% compounded annually, \$1000 every year from age 20 to 65
becomes about \$213,000; \$3000 every year from age 50 to 65 —
the *same* \$45,000 deposited — becomes about \$70,000. The
early dollars simply compound longer. A tax-free savings account
makes exactly this mathematics available to you within a few years of
this course.

Borrowing runs the same formula in reverse — now *you* are the
investment. Leave \$2000 unpaid on a credit card at 20% per year,
compounded monthly, and two years later the debt is about \$2974:
nearly a thousand dollars for waiting. When you compare the total
interest on any loan with the amount actually borrowed, the formula
is neither cruel nor kind — it is just exponential, and it works for
whoever owns the principal.

[[Your Financial Future]] hands you a spreadsheet and lets you test
your own plans against these formulas;
[[Sequences, Series, and Interest Practice]] builds the fluency
first.

%%curriculum-start%%
## Curriculum connection

![[C3.2]]

![[C3.3]]

![[C3.5]]

![[C3.7]]
%%curriculum-end%%
