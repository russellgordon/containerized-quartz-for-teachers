---
title: Scatter Plots and Trends
draft: false
created: __CREATED__
tags:
  - concepts
---
One variable tells you what happened; two variables let you ask
*whether one thing travels with another*. A scatter plot puts one
variable on each axis and drops a dot for every observation — your
[[Bungee Drop]] data made one, storeys across and stretch up. The
picture answers three questions at a glance: is there a relationship,
which direction does it lean, and how tightly do the points hug it?

## Correlation, and what it does not say

When the dots drift upward together, the correlation is **positive**;
downward, **negative**; a formless cloud means little correlation at
all. Technology will happily fit different regression models to the
same cloud and report how well each fits — your job is to look at the
*shape* first, as in [[Linear Relations]], and judge whether a line is
even the right kind of model before trusting any number about it.

> [!warning] Correlation is not causation
> Ice cream sales and drowning incidents rise together every summer.
> Ice cream does not cause drowning — hot weather drives both. A
> scatter plot can show that two variables move together; it cannot
> tell you *why*. Deciding why takes knowledge from outside the graph,
> and claims that skip that step are exactly what
> [[Who Does Data Serve]] teaches you to interrogate.

## Prediction, and its limits

A line of best fit turns a cloud into a machine for predictions: pick
an $x$, read off a $y$. Predictions *between* your data points stand
on solid ground. Predictions *beyond* the data are on a ledge — your
bungee line says nothing trustworthy about storey fifty, because no
cord was ever tested there. Every prediction should come with its
pedigree: interpolated or extrapolated, tight fit or loose one. Saying
so plainly is part of [[Showing Your Thinking]].

[[Scatter Plot Practice]] builds the mechanics with real datasets,
[[Using Desmos]] fits and compares models in seconds, and
[[A Data Story]] asks you to build an honest claim from a plot of
your own.

%%curriculum-start%%
## Curriculum connection

![[D1.3]]
%%curriculum-end%%
