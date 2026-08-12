---
title: What a Strong Entry Looks Like
draft: false
created: __CREATED__
tags:
  - portfolio
enableToc: true
---
Once the journal habit exists, the only remaining question is quality.
Last year quality came down to one property: reproducibility — enough
detail that somebody else could rebuild the situation and get the same
result. That standard has not moved, and you should hold it without
being reminded.

This year there is a second property stacked on top of it:
**defensibility**. A strong Grade 12 entry does not only let somebody
reproduce what happened. It lets somebody interrogate why you did it
that way, and find an answer waiting.

## Side by side

| Weak | Strong |
| --- | --- |
| "It wouldn't work." | "Rail sagged to 4.1 V when the fan started, measured at the board with the supply set to 5.00 V. Supply's own display still read 5.00, so the drop is in the leads — about 0.9 V at 450 mA, so roughly 2 Ω of lead and connector." |
| "I picked a MOSFET." | "MOSFET rather than the BJT: at 1.2 A the BJT's saturation drop would have dissipated close to 0.4 W in a small package, and I did not want a heatsink inside the enclosure. Cost me a gate driver I did not originally plan for." |
| "It runs warm." | "Regulator case measured 61 °C by IR after 20 min at 200 mA, ambient 23 °C. Dropping 7 V at 200 mA is 1.4 W, which matches. Sealed box will be worse — moving to a switcher or a lower input voltage." |
| "The bus works now." | "Analyzer decode was garbage until I set the threshold for 3.3 V logic instead of 5 V. The bus had been fine the whole time; the instrument was lying to me." |
| "Group work went fine." | "Ines wrote the state machine; I wrote the test that drives it through every transition and caught a state with no exit. Next task I want the state machine and she can break mine." |

Read the weak column again: nothing happened in it. The strong column
is the same bench day, remembered properly — a voltage, a temperature,
a current, a threshold setting. Notice the strong versions are barely
longer. Specific is not the same as long.

## A decision without its rejected alternative is a preference

This is the Grade 12 upgrade, and it is the thing most often missing
from otherwise excellent entries. Row two of that table is the model.
It contains four things:

1. **The choice.** A MOSFET.
2. **The alternative that lost.** The bipolar transistor.
3. **The number that decided it.** Roughly 0.4 W in a small package.
4. **What the choice cost.** A gate driver that was not in the plan.

Item four is the one people skip, and it is the one that proves you
were choosing rather than preferring. Every real design decision costs
something. An entry that records only upside is describing a wish.

If you genuinely had no alternative — the drawer had one part and the
period was ending — write that. "Chose it because it was the only one
in the bin, and I have not checked whether it is right" is an honest
and useful entry, and it flags something for you to come back to.

## Conditions, still, every time

"3.2 V" is not a measurement. "3.2 V across the motor terminals,
supply at 6.0 V, motor stalled" is a measurement, because it says what
was true at the time. A scope reading needs both scale settings and the
probe attenuation. A temperature needs the ambient it was measured
against and how long the thing had been running. A current needs to say
whether anything else was drawing from the same rail.

It costs one extra clause and it is the whole difference between a
number somebody can use and a number somebody has to repeat.

## Feelings are welcome, anchored to a moment and a part

The journal is not a lab report. Frustrated, proud, embarrassed, and
delighted all belong in it. The rule is that a feeling arrives attached
to the moment that caused it and the hardware involved. "I felt
useless" floats free and teaches you nothing later. "I felt useless
watching the decode come out as garbage for forty minutes — then I
checked the analyzer's threshold and the whole capture was suddenly
readable, and the bus had never been broken at all" is a feeling with
an address and an exit. The feeling is real data about you; the fault
is the handle you can actually turn. That pairing is the entire method
in [[Getting Unstuck]].
