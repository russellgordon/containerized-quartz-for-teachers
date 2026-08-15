---
title: Writing About Technology
publish: true
created: __CREATED__
tags:
  - reference
enableToc: true
---
Half of this course happens at the bench. The other half happens when
you put technical work into words that somebody else can act on — in
your [[Tech Journal]], in your build documentation, and in the written
part of every task. Technical writing has one rule that does most of
the work, and one standard that separates Grade 11 from Grade 10.

> [!important] Write for the next technician, who might be you
> Documentation is addressed to somebody who cannot see your bench,
> including future-you, who in three weeks will remember nothing about
> this circuit. If it only makes sense with you standing beside it
> pointing at things, it is not finished.

And the standard:

> [!important] A claim needs a measurement; a measurement needs units and conditions
> "The output was low" is an impression. "The output measured 0.4 V
> with the supply at 5.0 V and the motor stalled" is a fact somebody
> else can reproduce, argue with, or build on. Every number you write
> down carries three things — the value, the unit, and what was true
> at the time.

## Precision is kindness

| Instead of… | Try… |
| --- | --- |
| "It's broken" | "No output. Rail measures 5.02 V, pin 14 reads 4.98 V, pin 7 reads 0.00 V" |
| "The resistor got hot" | "The 100 Ω in the LED branch was too hot to touch; measured 62 mA where the design called for 15 mA" |
| "I fixed it" | "Reflowed the joint on pin 3, which was dull and lumpy. Continuity now beeps; input reads low when the button is pressed" |
| "About three volts" | "3.24 V, meter on the 20 V range, probes across R4, supply at 5.0 V" |
| "Used a guide" | "Followed the manufacturer's application note, figure 7; credited in my notes" |
| "It's done" | "Meets the brief. Known issue: display flickers on motor start, cause not yet measured" |

Notice that the right-hand column is barely longer than the left. What
it costs is one extra clause per sentence. What it buys is a document
that keeps working after you have left the room.

## Units are not optional decoration

Three habits, all cheap, all worth enforcing on yourself until they
are automatic.

- **Write the prefix.** `mA` and `A` differ by a factor of a thousand,
  and a design error of that size does not announce itself politely.
- **Match the precision to the instrument.** Your meter reads three or
  four digits; reporting nine of them is a claim about accuracy you
  cannot support, and reporting one throws away information you paid
  for.
- **Say what the value was measured against.** A voltage is always
  *between two points*. "3.3 V" without saying between what is half a
  sentence.

## Sentence stems that unlock a stuck entry

- I predicted… because… but measured… which tells me…
- The symptom was… and the first thing I measured was… because…
- The fix was… and the reason it worked is… so next time I would…
- This is finished for me, but a client who is not me would still
  need… before it is genuinely done.

## Claims about technology need evidence too

The same standard applies when we argue rather than build. When you
write about [[Who Pays for the Hardware|the cost of hardware]],
[[Repair or Replace|repairability]], or
[[When Good Enough Is Not Safe|what safe enough means]], the bench's
rule still holds: specific beats sweeping, sources get named with
their year, and "I read somewhere" is a loose connection that will
fail under load.

Strong technical writing — in a journal, a build record, or an
argument — reads like a good service log. Symptom, evidence, action,
verification, and an honest note about what you do not yet know.

%%curriculum-start%%
## Curriculum connection

![[D3.4]]
%%curriculum-end%%
