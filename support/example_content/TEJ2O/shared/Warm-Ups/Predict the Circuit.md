---
title: Predict the Circuit
publish: true
created: __CREATED__
tags:
  - warm-ups
---
A simple schematic goes up — a battery, a switch, an LED or two,
resistors in sensible places — and two questions follow: what
lights when the switch closes, and what changes if one named
component disappears? Commit on paper before anything is built.
This is the thinking half of [[Breadboard a Circuit]]: the head
runs the current around before the hands touch the board.

## How to run it

1. Show the schematic. A quiet minute; everyone writes both
   predictions down.
2. Poll the room. Disagreement is the good outcome — surface it.
3. Trace the circuit aloud together, positive terminal back home.
4. If the bench is stocked, build it and let the LED be the judge.

> [!example]- A worked round (click to expand)
> Battery, switch, then two LEDs on separate branches, each with
> its own resistor. What lights? Both — each branch gets the full
> battery voltage. Remove one LED and its branch goes dark; the
> other keeps shining, because parallel branches do not share a
> fate. Rewire them in series instead, and one missing LED
> darkens everything.

## One variation

Reverse it: describe a behaviour — "one switch, two lamps, either
can light alone" — and have students sketch a schematic that would
do it. Drawing from behaviour is design; reading is diagnosis.

> [!tip] Wrong predictions are the productive ones
> A prediction that fails on the breadboard is worth three that
> succeed — the surprise marks exactly where the mental model
> needs a part swapped. Say the misses out loud, with pride.

%%curriculum-start%%
## Curriculum connection

![[B2.1]]
%%curriculum-end%%
