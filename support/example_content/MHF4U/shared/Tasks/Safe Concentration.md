---
title: Safe Concentration
draft: false
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Pairs · launched with rational equations, due on the consolidation
> day · one dose curve, one window, both edges defended

## What you are making

Swallow a pill and the medication's concentration in the blood rises
fast, peaks, and drains away slowly. You will receive a data table
for a (fictional) medication — concentration in mg/L, hour by hour —
and the model family that pharmacologists actually reach for:

$$C(t) = \frac{at}{t^2 + b}$$

This medication only works above $0.4$ mg/L, and is only safe below
$1.2$ mg/L. You finish with the **fitted model**, a paragraph on why
no polynomial could do this job (what happens as $t$ grows?), and
the **safe-and-effective window**: the interval of hours where the
concentration is high enough to work and low enough to be safe —
each edge found exactly — plus your recommendation, in plain
language, for when the second dose should be taken.

## Milestones

- [ ] Data plotted by hand; the rise-then-fall shape and the long-run
      fade described before any formula appears
- [ ] The family interrogated: intercepts and the horizontal
      asymptote of $C(t)$, argued with [[Asymptotes]] thinking
- [ ] Parameters $a$ and $b$ fitted in [[Using Desmos]]; the misfit
      measured and stated in mg/L
- [ ] Each threshold crossing solved exactly as a rational equation,
      then checked against the graph
- [ ] The window stated as an interval, defended with a sign
      argument, and turned into a dosing recommendation

## How it is assessed

Per [[How Marks Work]], the reasoning is the product: a window that
is slightly off, with the misfit measured and its effect on the
recommendation discussed, outranks perfect numbers with no argument.
On the due date your pair defends both edges of the window out loud.
The [[Math Journal]] entry on what your model ignores — food, body
mass, the second dose itself — completes the evidence.

## Success criteria

| Quality | What it looks like in your work |
| --- | --- |
| Shape before symbols | Rise, peak, and fade explained from the data |
| A family understood | Intercepts and asymptote argued, not assumed |
| A measured misfit | Model-versus-data disagreement stated in mg/L |
| Exact edges | Both threshold crossings solved algebraically |
| A humane answer | The window translated into advice about hours |

> [!success]- If the fit will not settle
> Work one parameter at a time: $a$ scales the whole curve up and
> down, while $b$ decides how early the peak arrives. Fit the peak's
> timing first, then its height — and if the tail of your data still
> disagrees, say so in the write-up. That disagreement is evidence,
> not failure.

%%curriculum-start%%
## Curriculum connection

![[A2.4]]

![[A3.4]]

![[C2.1]]

![[C3.6]]

![[C4.2]]

![[D3.3]]
%%curriculum-end%%
