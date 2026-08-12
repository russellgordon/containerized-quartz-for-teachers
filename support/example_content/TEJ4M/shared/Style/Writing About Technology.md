---
title: Writing About Technology
draft: false
created: __CREATED__
tags:
  - reference
enableToc: true
---
Half of this course happens at the bench. The other half happens when
you put technical work into words that somebody else can act on — in
your [[Tech Journal]], in a specification, in build documentation, and
in the design defence attached to every task. Technical writing has one
rule that does most of the work, and two standards stacked on top of
it.

> [!important] Write for the next engineer, who might be you
> Documentation is addressed to somebody who cannot see your bench,
> including future-you, who in three weeks will remember nothing about
> this design. If it only makes sense with you standing beside it
> pointing at things, it is not finished.

> [!important] A claim needs a measurement; a measurement needs units and conditions
> "The output was low" is an impression. "The output measured 0.4 V
> with the supply at 5.0 V and the motor stalled" is a fact somebody
> else can reproduce, argue with, or build on. Every number you write
> down carries three things — the value, the unit, and what was true at
> the time.

> [!important] A design decision needs its rejected alternative
> This is the Grade 12 standard, and it is the one that will feel
> unnatural for about a month. "I used a MOSFET" records an event. "I
> used a MOSFET rather than the bipolar transistor, because at 1.2 A
> the bipolar's saturation drop would have put roughly 0.4 W into a
> small package, and it cost me a gate driver I had not planned for" —
> that is a decision, with its reason, its number, and its price.

## Precision is kindness

| Instead of… | Try… |
| --- | --- |
| "It's broken" | "No output. Rail reads 5.02 V at idle, 4.10 V under load at the board. Pin 7 reads 0.00 V, pin 14 reads 4.98 V" |
| "The regulator got hot" | "Regulator case reached 61 °C after 20 min at 200 mA, ambient 23 °C; it is dropping 7 V, so 1.4 W" |
| "I fixed it" | "Set the analyzer threshold for 3.3 V logic instead of 5 V; decode is clean and the bus had never been faulty" |
| "About three volts" | "3.24 V, meter on the 20 V range, probes across R4, supply at 5.0 V, fan off" |
| "The signal looked clean" | "40 mV peak-to-peak ripple at the regulator output, AC coupled, 20 MHz limit on, 350 mA load" |
| "I chose a bigger capacitor" | "Went from 10 µF to 47 µF because the rail dipped 380 mV at motor start and the budget is 250 mV; measured 190 mV after" |
| "It's done" | "Meets every acceptance criterion in the specification except thermal, which is untested above 30 °C ambient" |

Notice the right-hand column is barely longer than the left. What it
costs is one extra clause per sentence. What it buys is a document that
keeps working after you have left the room.

## A requirement needs a test that could fail

Specifications are new writing for you this year, and they have their
own discipline. The whole test is this: **could somebody hand this
requirement to a stranger and have them decide, without asking you,
whether it passes?**

- "The device should be reliable" — untestable. Nothing to measure.
- "The device shall operate continuously for 24 hours at 40 °C ambient
  without exceeding a 60 °C case temperature on any component" —
  testable, and somebody could fail it.

Three habits carry most of it.

- **Use the strong verb deliberately.** In specification writing,
  *shall* marks a binding requirement, *should* marks a preference, and
  *may* marks an option. Mixing them casually makes it impossible to
  tell what is actually required, so pick each word on purpose.
- **Kill the adjectives.** Fast, robust, efficient, user-friendly, and
  low-power are not requirements; they are moods. Each one has to
  become a number with a unit and a condition.
- **State the conditions with the number.** "Draws under 500 mA" is
  half a requirement. Under 500 mA average, at 12 V input, with the
  motor at full speed, at room temperature — now it can be tested, and
  now somebody can be held to it.

[[Writing a Specification]] takes this much further; this page is about
the sentences.

## A design decision needs its rejected alternative

The form is four parts and it fits in two sentences:

1. **The choice.**
2. **The alternative that lost.**
3. **The number or property that decided it.**
4. **What the choice cost you.**

Part four is the one people leave out, and it is the one that proves
you were choosing rather than preferring. Every real decision costs
something — money, board area, complexity, a part that is harder to
buy, an extra rail. A write-up that records only upside is describing a
wish, and everybody in the room can tell.

If there genuinely was no alternative, write that: "chose it because it
was the only suitable part in the lab, and I have not verified it
against the temperature requirement" is honest, useful, and flags
something to return to. That is a much stronger sentence than a reason
invented after the fact.

## Units are not optional decoration

Three habits, all cheap, all worth enforcing on yourself until they are
automatic.

- **Write the prefix.** `mA` and `A` differ by a factor of a thousand,
  `µs` and `ms` likewise, and a design error of that size does not
  announce itself politely.
- **Match the precision to the instrument.** Your meter reads three or
  four digits; reporting nine of them is a claim about accuracy you
  cannot support, and reporting one throws away information you paid
  for. A scope measurement's precision is bounded by its own
  resolution and bandwidth — see
  [[Using an Oscilloscope Properly]].
- **Say what the value was measured against, and where.** A voltage is
  always *between two points*, and this year it also matters *which
  end of the wire*. "5.00 V at the supply terminals" and "4.10 V at the
  board" are both true and they are not the same fact.

## Sentence stems that unlock a stuck entry

- I predicted… because… but measured… which tells me…
- The requirement was… and the test that would fail it is…
- I chose… over… because… and it cost me…
- The symptom was… and the first thing I measured was… because…
- This is finished for me, but somebody who is not me would still
  need… before it is genuinely done.
- I am at… % of this part's rating, which leaves margin for…

## Claims about technology need evidence too

The same standard applies when you argue rather than build. When you
write about [[Who Owns the Firmware|who owns a device you bought]],
[[Security Is a Trade-Off|what security actually buys]], or
[[When Good Enough Is Not Safe|what safe enough means]], the bench's
rule still holds: specific beats sweeping, sources get named, and "I
read somewhere" is a loose connection that will fail under load. And
the Grade 12 addition applies here too — the strongest position in an
argument is usually held by the person willing to state the cost of
their own proposal.

Strong technical writing — in a journal, a specification, a build
record, or an argument — reads like a good service log. Symptom,
evidence, decision, verification, and an honest note about what you do
not yet know.
