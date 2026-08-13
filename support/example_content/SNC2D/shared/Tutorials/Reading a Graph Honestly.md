---
title: Reading a Graph Honestly
draft: false
created: __CREATED__
enableToc: true
tags:
  - skills
  - climate
---
A graph is an argument. Somebody chose the axes, the range, and what to
leave out, and every one of those choices can be made honestly or
dishonestly using exactly the same data. This page is about spotting
which, and about not doing it yourself by accident.

## Read these four things before you read the line

1. **What is on each axis, and in what units.** Temperature, or
   temperature *anomaly* — a difference from a baseline — are different
   quantities, and the second one is what most climate graphs plot.
2. **The range of both axes.** Where does the data start and stop, and
   why there?
3. **What each point is.** A single measurement, a monthly mean, an
   annual mean, a ten-year running average? Smoothing removes noise and
   also removes real events.
4. **What is not plotted.** The years, places, or categories that were
   left out are the argument's quietest part.

## The five moves, and when each is legitimate

| The move | When it is fine | When it is a trick |
| --- | --- | --- |
| Y-axis not starting at zero | The zero is arbitrary — an anomaly, a pH, a year | The bar's length is the value, so cutting the axis multiplies the apparent difference |
| Choosing where the data starts | The record starts there | The start year was picked because it was unusual |
| Smoothing | Removing known seasonal noise, and saying so | Smoothing hard enough to erase what you dislike |
| Two y-axes | Genuinely different units, honestly scaled | The two scales were slid until the curves lie on top of each other |
| Plotting a trend line | The relationship plausibly is linear | A straight line drawn through data that is obviously not straight |

The first row is the one people get wrong in both directions. A bar
chart must start at zero, because you read bars by length. A line of
temperature anomalies does not have to, because there is no meaningful
zero to start from — forcing one squashes the signal into a flat line,
which is its own kind of lie.

## Cherry-picking, using the example you will actually meet

Global temperature records wobble year to year — volcanic eruptions,
and the El Niño and La Niña cycle in the Pacific, move an individual
year up or down without changing the long-run trend at all. So if you
begin your plot at an exceptionally warm year, the following decade
looks flat, and you can say so while every number on your graph is
correct. Begin two years earlier, or two later, and it does not.

> [!warning] The test for a cherry-picked range
> Move the start point by a few years in each direction. If the story
> survives, it is a trend. If it collapses, you were looking at where
> somebody put the edge of the picture. Ask the same question of the
> end point — a series that stops early is hiding the same way.

Where to look instead: the long temperature and precipitation records
published by **Environment and Climate Change Canada**, the global
surface and ocean datasets from **NOAA**, and the assessment reports of
the **IPCC**, which are summaries of the published literature rather
than a single study. Go to the dataset or the report and read what its
own authors say about its uncertainty. Do not take a number from an
article that does not tell you where it came from.

## Error bars and shaded ranges

An error bar is not an admission of sloppiness. It is a statement about
how well the quantity is known, and a graph without one is often less
honest than a graph with a wide one.

- If the bars on two points **overlap substantially**, your data may
  not be able to tell those two values apart. Saying they differ is
  claiming more than you measured.
- A shaded band around a projection is usually a range of outcomes
  across models or scenarios, not the space where somebody is unsure
  whether they did the arithmetic right.
- On your own graphs, the bar comes from the resolution of your
  instrument and the spread across your trials — see
  [[Writing a Lab Report]] for how to state it.

## Correlation, and the sentence that gives it away

Two quantities that both rise over time will correlate with each other
whether or not they have anything to do with one another. So when a
graph shows two rising lines, three explanations are on the table
before you look at anything else: the first causes the second, the
second causes the first, or something else drives both.

What lifts a claim past that is a **mechanism you can state and test**.
The reason rising carbon dioxide is not merely correlated with rising
temperature is that the absorption of infrared radiation by the gas was
measured in a laboratory long before the trend in the atmosphere was an
argument — the mechanism came first, and it predicts the sign and
roughly the size of the effect. That is what [[The Greenhouse Effect]]
is for.

> [!question] One more, for weather and climate
> A record cold week is not evidence against a warming trend, and a
> record hot week is not proof of one. A trend is a statement about the
> whole distribution over decades; a week is one draw from it. If you
> would not accept the cold week as an argument, do not use the hot week
> as one either.

Practise on real series in [[Climate Data Practice]], then use what you
find in [[The Climate Brief]]. Related:
[[Natural and Human Influences on Climate]] and
[[Feedback Loops in Climate]].
