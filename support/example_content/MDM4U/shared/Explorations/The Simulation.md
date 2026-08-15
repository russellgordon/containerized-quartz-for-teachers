---
title: The Simulation
publish: true
created: __CREATED__
tags:
  - explorations
enableToc: true
---
In the 1650s a French gambler noticed that betting on at least one six
in four rolls of a die made him money, while betting on at least one
double six in twenty-four throws of two dice slowly ruined him. He
thought the two bets were equivalent. He was wrong, and the argument
he started built probability theory.

You have something he did not: a machine that can play both bets ten
thousand times in a second.

## The task

**Part one — a probability you can check.** Simulate both of the
gambler's bets, several thousand rounds each, and estimate how often
each one wins. Are they equal? Then compute both probabilities
exactly, and see whether your simulation agrees. When the estimate and
the calculation disagree slightly, decide which one you trust and say
why. When they disagree *a lot*, find the bug — it is always in the
simulation, and it is usually the difference between "at least one"
and "exactly one".

Then the question underneath: how many rounds did you need before your
estimate stopped wandering? Plot your running estimate against the
number of rounds and describe the shape.

**Part two — a probability you cannot easily check.** A cereal company
puts one of six different prizes in every box, at random and in equal
numbers. How many boxes should you expect to buy to collect all six?

Guess first, as a group. Then simulate it — the simulation is barely
harder than part one. Then try to compute it exactly, and notice how
much harder that is than the simulating was. Start with two prizes
instead of six; then three. A pattern is waiting there for the groups
who go small before they go clever.

> [!tip]- Facilitation notes — for the teacher
> Part one exists so that part two can be trusted. A tool nobody has
> validated is not evidence, and the gambler's two bets are close
> enough in value that a sloppy simulation cannot tell them apart —
> which is exactly the lesson. Groups running only two hundred trials
> will get the *wrong* ordering surprisingly often; let that happen
> before you suggest more trials.
>
> The running-estimate plot is the heart of the day: it is the law of
> large numbers, discovered rather than asserted, and it is the
> picture students should have in mind whenever anyone says "the
> experimental probability approaches the theoretical".
>
> Part two is the payoff — the coupon collector's problem, whose exact
> answer needs a tool this course does not teach. Groups who reduce to
> two prizes and then three usually find the pattern; the sum they
> write down is the harmonic series in disguise, and it is worth
> telling them so. Fast groups: what if one prize is deliberately made
> rarer than the others? The simulation handles it in one line, and
> the intuition about what the company gains is worth the discussion.
>
> Have [[Simulating with Python]] open on the projector. Spreadsheets
> work too — but a spreadsheet running ten thousand trials makes the
> cost of the tool visible in a useful way.

## What mathematics tends to surface

Experimental probability converging on theoretical probability as
trials grow — visibly, on a plot the group made themselves. The
difference between an estimate and a value. A random variable and the
distribution of its outcomes, met as "the histogram we accidentally
built" before it is met as a definition. And, for part two, the first
real experience of a quantity that is easy to estimate and hard to
calculate — the situation most working data analysts live in.

## Where it leads

[[Random Variables and Distributions]] names what you were tabulating
without knowing it, [[Expected Value]] gives the cereal-box answer its
proper name, and simulation returns as a research tool in
[[The Culminating Investigation]] whenever the mathematics gets ahead
of the class.

> [!note] The answer is not on this page
> Neither of the gambler's probabilities, nor the number of cereal
> boxes. They are all reachable in one class with a machine and a
> stubborn group.

%%curriculum-start%%
## Curriculum connection

![[A1.4]]

![[B1.1]]
%%curriculum-end%%
