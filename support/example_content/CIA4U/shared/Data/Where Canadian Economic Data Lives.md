---
title: Where Canadian Economic Data Lives
draft: false
created: __CREATED__
tags:
  - data
  - unit-1
---
Almost every economic claim you make this term rests on a number somebody
else collected. Knowing which body collects it, what they call it, and
when they publish it next is the difference between an argument and an
opinion.

Three institutions produce nearly everything you need. Statistics Canada
measures the economy and publishes each figure in *The Daily* on the
morning it exists, with the table number printed at the bottom of the
release — that number, not the headline, is what you cite. The Bank of
Canada sets and publishes rates. The Department of Finance publishes the
budget, which [[Reading a Budget]] takes apart.

## The tables this course uses most

| What you want | Where it lives |
| --- | --- |
| Consumer Price Index | Statistics Canada table 18-10-0004-01 |
| Unemployment, employment, participation | Table 14-10-0287-01 |
| Real GDP by expenditure, quarterly | Table 36-10-0104-01 |
| GDP by industry, monthly | Table 36-10-0434-01 |
| Labour productivity, unit labour cost | Table 36-10-0206-01 |
| Poverty, Market Basket Measure | Table 11-10-0135-01 |
| Gini coefficients | Table 11-10-0134-01 |
| The policy interest rate | Bank of Canada series `V39079` |
| The Canadian dollar against the US dollar | Bank of Canada series `FXUSDCAD` |

Table numbers change. In June 2026 Statistics Canada archived four job
vacancy tables — 14-10-0325, 0326, 0328 and 0356 — and replaced them with
14-10-0441-01 through 14-10-0444-01 to carry a new industry
classification. A citation naming the table and the date you retrieved it
survives that. "Statistics Canada says" does not.

## The Bank of Canada will hand you today's number

The Bank's Valet service returns any of its series as data, with no key
and no charge. Ask it for `observations/V39079/json?recent=1` and you get
the current target for the overnight rate; ask for `FXUSDCAD` and you get
the day's Canadian dollar price of one US dollar, published each business
day by 16:30 Eastern.

> [!tip] Check the release calendar before you write, not after
> Statistics Canada publishes the date of every forthcoming release. The
> June 2026 CPI appeared on 20 July 2026 and the July figure on
> 17 August 2026. A paper written in early August calling the June figure
> current is right; the same sentence two weeks later is wrong. Knowing
> when the next number lands is what stops that.

Record each source the way [[Your Economics Notebook]] sets out, then
judge it the way [[Judging an Economic Claim]] does.

%%curriculum-start%%
## Curriculum connection

![[A1.2]]

![[A1.8]]
%%curriculum-end%%
