---
title: Checking Your Own Work
draft: false
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Nobody marks your checker but you. Every mathematician you will ever
meet runs one — a quiet second pass that catches errors before they
matter — and the earlier you build yours, the sooner tests stop being
scary. Four habits make up the whole machine.

## Substitute back — into everything

Solved an equation? The equation itself will referee — and in this
course that referee has real work to do, because logarithmic
equations produce *candidates*, not answers. Solving
$\log x + \log(x - 3) = 1$ yields $x = 5$ and $x = -2$; substitute
back and the original refuses $-2$ at the door, because
$\log(-2)$ is not a thing. No answer key required — the equation
knew. The same reflex checks a model: feed your concentration curve
an hour you did *not* use to build it, and see whether the level it
predicts matches the data.

## Estimate first, compare after

Before solving, write down a rough expected size — the reflex
[[Estimation Duels]] trains. $\log_2 100$ must land between 6 and 7,
because $2^6 = 64$ and $2^7 = 128$ bracket 100; if your algebra
hands you 50, one of you is wrong, and now you know to look. This
check only works if the estimate came *before* the answer did.

## Check the units

Units are a free error detector. If a concentration answer arrives in
hours when the question asked for milligrams per litre, something
upstream broke — and the units caught it without you rereading a
single step. Angles count too: a calculator answer of 60 from a
machine working in radians is not $60^\circ$, and saying the unit
out loud is the cheapest way to notice. Carry them through every
line, as [[Showing Your Thinking]] insists.

## Ask whether the graph agrees with its own story

After sketching from factored form, interrogate the sketch. The
factor $(x - 2)^2$ promises a *bounce* at 2 — if your curve crosses
there, one of them is lying, and it is not the algebra. A
concentration model that dips below zero milligrams per litre is
promising blood chemistry that does not exist, and the sketch
objects instantly. A graph that disagrees with its own situation is
the cheapest alarm in [[Zeros and Multiplicity]] — and the question
behind it is the one [[What Makes a Model Good]] asks of every
model: does it tell the truth about the world it claims to describe?
