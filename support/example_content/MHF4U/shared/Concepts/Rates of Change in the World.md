---
title: Rates of Change in the World
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Before any calculus, a plain idea: a rate of change compares how much
one quantity moved against how much another did. Everything in this
strand is that comparison, made more careful.

## What a rate of change actually is

$$\text{average rate of change} = \frac{\Delta y}{\Delta x} = \frac{\text{change in the dependent variable}}{\text{change in the independent variable}}$$

Dependent over independent, always. That order is not a convention to
memorise — it is what "per" means. Kilometres **per** hour: distance
changed, divided by the time it took.

The units tell you whether you have it the right way up. If you compute
hours per kilometre when the question asked how fast, the units say so
before the number does.

## Where they turn up, and what they are called

| Situation | The rate | Its units |
| --- | --- | --- |
| A car's position over time | Speed | km/h |
| A population over years | Growth rate | people/year |
| A tank draining | Flow rate | L/min |
| A drug leaving the bloodstream | Elimination rate | mg/h |
| Cost against units produced | Marginal cost | dollars/unit |
| Temperature up a mountain | Lapse rate | °C/km |
| A country's emissions over time | Rate of change of emissions | Mt/year |

Two of those repay a closer look. **Marginal cost** is the rate that
decides whether a factory makes one more unit — a business idea that is
purely a rate of change. And the last row is a rate whose own *rate of
change* is what the argument is about: emissions can be rising while
their rate of increase falls, and a headline that confuses the two is
wrong in a way most readers cannot see.

## Average against instantaneous

An **average** rate covers an interval: the secant slope between two
points. An **instantaneous** rate is at a single moment: the tangent
slope at one point.

A speedometer shows an instantaneous rate. A journey's "we averaged 80"
is an average rate, and the two can disagree wildly — the average over
a trip says nothing about the moment you were stopped at a light.

Estimating an instantaneous rate without calculus is straightforward:
take average rates over shorter and shorter intervals around the point
and watch them settle. [[How Fast Is It Changing?]] is that
investigation, and the settling is exactly the limit that MCV4U will
make formal.

## Sketching a graph from a description

The skill worth practising: somebody describes a situation in words, and
you draw the graph.

> A tank fills quickly at first, then more slowly as the pressure drops,
> and finally stops when the valve closes.

Three features have to appear: rising, with a **steep** slope early; the
slope **decreasing** through the middle; and a **horizontal** section at
the end. The shape follows from the rate, not from the values.

Then verify it. Pick three moments, estimate the slope at each from your
sketch, and check that the numbers behave as the words said. A graph
that looks right and fails that check is telling you which word you
misread.

> [!question]- Increasing, or increasing more slowly?
> "Growth is slowing" does not mean the quantity is falling — it means
> the *rate* is falling while the quantity still rises. Drawn as a
> graph: still going up, but flattening. Nearly every public argument
> about a trend contains this confusion somewhere, and being able to
> draw the difference is what settles it.

%%curriculum-start%%
## Curriculum connection

![[D1.1]]

![[D1.2]]

![[D1.3]]
%%curriculum-end%%
