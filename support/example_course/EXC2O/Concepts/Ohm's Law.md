---
createdSection1: 2026-11-20T08:00:00.000-0500
draftSection1: false
createdSection2: 2026-11-20T08:00:00.000-0500
draftSection2: false
enableToc: true
tags:
  - physics
---
## The idea

For many materials, the current through a conductor is proportional to the
potential difference across it. Georg Ohm published this in 1827 and was
ridiculed for it.

$$
V = IR
$$

Rearranged as needed:

$$
I = \frac{V}{R} \qquad R = \frac{V}{I}
$$

## Worked example

A $12\ \mathrm{V}$ battery drives a $6.0\ \Omega$ resistor. What current
flows?

$$
I = \frac{V}{R} = \frac{12\ \mathrm{V}}{6.0\ \Omega} = 2.0\ \mathrm{A}
$$

## Finding it from data, not from the formula

The point of [[Ohm's Law Investigation]] is that **you** discover this
relationship. Measure current at several voltages and plot $V$ against $I$:

| $V$ (V) | $I$ (A) |
| --- | --- |
| 2.0 | 0.20 |
| 4.0 | 0.41 |
| 6.0 | 0.59 |
| 8.0 | 0.80 |
| 10.0 | 1.01 |

A straight line through the origin means proportional. Its **slope** is the
resistance:

$$
R = \frac{\Delta V}{\Delta I} \approx \frac{10.0 - 2.0}{1.01 - 0.20} \approx 9.9\ \Omega
$$

> [!tip] Use the slope, not one point
> Dividing a single pair of readings uses one measurement and all of its error.
> The slope of a best-fit line uses every point you took. That is a habit worth
> carrying into every science course you ever take.

> [!warning] It is a *model*, not a law of nature
> Heat a filament and its resistance climbs, and the line bends. Materials that
> follow $V = IR$ are called **ohmic**; plenty are not.

## Curriculum

- ![[D2.4]] — [[D2.4]]
- ![[D2.5]] — [[D2.5]]
