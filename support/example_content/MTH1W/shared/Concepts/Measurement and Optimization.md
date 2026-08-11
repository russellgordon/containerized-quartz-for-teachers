---
title: Measurement and Optimization
draft: false
created: __CREATED__
tags:
  - concepts
---
Building [[The Best Box]] from identical sheets of card, your class
found that equal amounts of material hold very different amounts of
popcorn — measurement is full of trade-offs like that, and this page
collects the machinery for reasoning about them.

## Units are ratios in disguise

Converting units is proportional reasoning from
[[Ratios, Rates, and Proportions]] wearing a lab coat: $1$ m $= 100$
cm is a rate, and converting just means scaling by it. The same logic
crosses between systems — metric to imperial, or the many measurement
systems developed by cultures worldwide, from hand spans to
paces — as long as you know one honest linking rate. Keep the units
visible in your work and they check the work for you: if the answer
comes out in cm² when you wanted cm³, the units caught the error
before you did.

## What doubling a dimension really does

Stretch, and the measurements do *not* all stretch together:

| Measure | Dimensions involved | Double one length… | Double all |
| --- | --- | --- | --- |
| Perimeter | one | part grows $\times 2$ | $\times 2$ |
| Area | two | grows $\times 2$ | $\times 4$ |
| Volume | three | grows $\times 2$ | $\times 8$ |

Area answers to *two* dimensions, so doubling both lengths quadruples
it; volume answers to three, so doubling everything multiplies it by
eight. This is why a pizza twice the diameter is four times the pizza,
and why guesses at [[Estimation Duels]] about big objects go wrong in
predictable ways. It is also why optimisation is interesting at all:
perimeter and area grow at different speeds, so among all rectangles
with the same perimeter, the square encloses the most area — spending
the same fence differently buys different amounts of yard.

One more relationship worth owning: a pyramid holds exactly one third
of the prism it fits inside, and a cone one third of its cylinder —
fill one with water and pour three times to see it. Between scaling
effects and these thirds, most volume problems in
[[Design Under Constraints]] reduce to shapes you already know.

%%curriculum-start%%
## Curriculum connection

![[E1.3]]

![[E1.4]]

![[E1.6]]
%%curriculum-end%%
