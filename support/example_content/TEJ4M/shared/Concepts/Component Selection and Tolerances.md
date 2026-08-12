---
title: Component Selection and Tolerances
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Two groups built the same voltage divider from the same drawer of
resistors, and the two outputs differed by 40 mV. Neither group had made
a mistake. Both had built exactly what the schematic said, and the
schematic — like every schematic — was quietly claiming that a resistor
marked 10 kΩ is 10 kΩ. It is not. It is somewhere in a band the
manufacturer guarantees, and this year you are expected to know how wide
that band is and what it does to your output.

## The numbers on a datasheet that actually bite

A datasheet is long because it is a legal statement about many
conditions. Four kinds of number matter more than the rest.

| Kind of number | Example | What it costs you if ignored |
| --- | --- | --- |
| Absolute maximum | $V_{CE}$ max, $T_j$ max | These are destruction limits, not operating points — running at them is not "within spec" |
| Guaranteed minimum | $h_{FE}$ min at a stated $I_C$ | Design on the *minimum*; the typical figure is marketing for your purposes |
| Tolerance | $\pm 1\%$, $\pm 5\%$ | Moves your calculated value before you power anything |
| Condition attached to all of the above | "at 25 °C", "at $V_{GS} = 4.5\ \text{V}$" | A spec measured in conditions you will never meet is a spec you do not have |

The condition column is the Grade 12 one. A MOSFET's on-resistance is
only that low at the gate voltage the table names; a regulator's dropout
is only that small at the current the table names; a resistor's power
rating assumes 25 °C in still air, which is the whole argument of
[[Reliability and Derating]]. [[Reading a Datasheet Like an Engineer]]
walks a real sheet top to bottom.

## Tolerance is not decoration

Resistors come in preferred series — E24 for 5% parts, E96 for 1% parts —
and the spacing of the values is chosen so that the tolerance bands
almost touch. That is why 720 Ω is not a value you can buy in E24 and
750 Ω is. Design with the values that exist.

Now stack the tolerances. Take a divider of two nominally equal 10 kΩ
resistors, each $\pm 1\%$, on a 5 V supply that is itself $\pm 5\%$. The
worst case for a high output is the top resistor low and the bottom
resistor high, on a high supply:

$$V_{\text{out,max}} = 5.25\ \text{V} \times \frac{10.1\ \text{k}\Omega}{9.9\ \text{k}\Omega + 10.1\ \text{k}\Omega} = 5.25\ \text{V} \times 0.505 \approx 2.651\ \text{V}$$

and the mirror image gives 4.75 V times 0.495, or about 2.351 V.
Nominally you designed 2.500 V; in production you have built something
between 2.35 V and 2.65 V, a spread of about $\pm 6\%$. If a
comparator threshold sat at 2.6 V, some of your boards work and some do
not, and they all measure "correct".

Two ways out, and you should be able to name both at a design review.
**Tighten** the parts — 0.1% resistors and a regulated reference cost
money and shrink the spread. Or **design the sensitivity away** — use a
ratiometric measurement, where the same supply feeds both the divider and
the converter's reference, so a supply that moves cancels itself out.
The second is usually cheaper and always more elegant.

## Choosing a part you can still buy next year

Selection is not just "does it meet the spec". A component you cannot
source is a component you do not have.

- **Availability and lifecycle.** Check that the part is stocked, in a
  package you can actually solder, and not marked obsolete or
  not-recommended-for-new-designs.
- **A second source.** If one distributor's stock is the entire plan,
  the plan has a single point of failure. Name an alternative part in
  the spec.
- **Package and thermals.** The same silicon in a smaller package
  dissipates less heat. That is a decision, not a detail.
- **Total cost, honestly.** Unit price, plus the connector, the heat
  sink, and the hour of your labour it takes to fit.
- **The ethics of the purchase.** Grade 12 asks you to weigh more than
  price when you specify: [[D2.2|a purchasing policy]] takes
  environmental and human-rights questions into account, and a
  professional specification says so out loud rather than pretending the
  question does not exist.

Write the justification next to each part in your spec: the requirement
number it serves, the datasheet figure that proves it, and the margin you
left. "It was in the drawer" is a Grade 10 answer.
[[Specification Practice]] and [[Power and Regulation Practice]] drill the
arithmetic, [[Name That Part]] keeps the identification quick, and
[[Tech Journal]] is where the sourcing decisions have to be recorded
while you still remember why you made them.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[A3.3]]

![[A3.5]]
%%curriculum-end%%
