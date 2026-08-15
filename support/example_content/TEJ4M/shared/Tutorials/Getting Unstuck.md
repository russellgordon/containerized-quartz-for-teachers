---
title: Getting Unstuck
publish: true
created: __CREATED__
tags:
  - tutorials
enableToc: true
---
Stuck is a normal working condition at a bench — [[Getting Help]] says
so, and working technicians live there daily. Last year you learned to
tell spinning from diagnosing, and the difference was usually a meter.

This year the faults have changed shape. The ones that will cost you a
week are intermittent, timing-dependent, or living in the seam between
hardware and firmware where neither side looks guilty. So the table
grows a column.

| Spinning | Diagnosing (Grade 11) | Diagnosing (Grade 12) |
| --- | --- | --- |
| Rewiring the same connection | Measuring both ends of it | Measuring it while the load switches |
| "Maybe the chip is dead" | "Pin 14 reads 4.98 V, so it has power" | "The rail dips to 3.9 V for 4 ms at motor start" |
| Changing three things | Changing one thing | Changing one thing, and recording the version it was |
| Rereading the code | Toggling a pin and watching the meter | Toggling a spare pin at the top and bottom of the routine and watching the timing on a scope |
| "It works sometimes" | "It failed twice in ten tries" | "It fails on the first run after a cold start, 9 times in 10" |
| "The bus is broken" | "No acknowledgement from the device" | "Clock only reaches 2.1 V — the pull-ups are too weak" |

The right-hand column is not cleverer. It is the same method with a
better instrument and a written record.

## Seven moves

1. **Check power and ground first, and check them under load.** Not
   "it should have power" — measure it, with the circuit doing the
   thing that fails. An astonishing proportion of Grade 12 faults are a
   rail that is fine at idle and unacceptable when something switches.
   [[Bench Power Supply Habits]] is half of this move.
2. **Make it reproducible before you make it go away.** An intermittent
   fault you cannot trigger on demand cannot be confirmed as fixed —
   you will only ever know that it has not happened *yet*. Spend the
   time finding the trigger: cold start, a particular sequence, a
   temperature, a specific input. That work is never wasted, because it
   also becomes your test procedure.
3. **Change one thing, and write down which version it was.** One
   wire, one part, one line, then test. With firmware, "which version"
   means a commit — see [[Version Control for Firmware]] — so that a
   result three days old still means something.
4. **Split it in half, in whichever dimension is longest.** Halve the
   signal path and measure in the middle. Halve the code history and
   test the midpoint. Halve the configuration and disable half the
   features. Four or five measurements localise a fault anywhere,
   which beats checking components in the order you happen to like
   them.
5. **Make the invisible visible.** A spare output pin set high at the
   start of a routine and low at the end turns a timing question into a
   scope trace. A counter printed once a second turns "it hangs
   sometimes" into "it stops after about 40 000 iterations". An
   analyzer capture with a pre-trigger buffer shows you what happened
   *before* the failure. Instrumenting a fault is usually faster than
   reasoning about it.
6. **Suspect the instrument, once.** Is that ringing real, or is it
   your ground lead? Is the decode garbage, or is the analyzer's
   threshold wrong? Is the rail really 5.00 V, or is that the supply's
   own display? Ask this question once per fault — not constantly,
   which is its own kind of spinning.
7. **Compare against a known good.** The bench next to you built
   something similar; you have a tagged commit from last week that
   worked. Measure the same node, run the same test, and let the
   difference point. This is legitimate and professional, not copying —
   the norm in [[Our Classroom Norms]] is that help gets named, not
   that help is forbidden.

## Write the fault report before you ask anybody

Not after. The act of writing it is a diagnostic step, and it resolves
a surprising number of faults before anyone else reads a word.

A fault report has five parts, and this is the same shape a service log
uses everywhere in the trade:

- **Symptom** — exactly what happens, with numbers.
- **Conditions** — when it happens and when it does not. This is where
  reproducibility gets recorded.
- **What you have measured** — values with units and conditions, and
  the instrument used.
- **What you have ruled out** — and the measurement that ruled it out.
  "Not the power supply" is an opinion; "rail holds 4.97 V throughout,
  measured at the board" is a rule-out.
- **What you think it is** — your best hypothesis, and the single
  measurement that would confirm or kill it.

Half the value of asking well is that you often answer yourself in the
middle of the sentence. The other half is that a report in this shape
belongs in your [[Tech Journal]] unchanged.

## Explaining it aloud still works

To a partner, or to an empty chair: "the supply comes in here, the
regulator drops it to 3.3, the sensor's output goes into the ADC, and
the reading is fine until the fan starts, so — wait." Saying a system
out loud forces you through the step you were skipping, and the fault
usually lives in exactly that step. It works better every year, because
you can say numbers and timings instead of hopes.

## When to stop and ask

Twenty minutes of real diagnosis is time well spent. Twenty minutes of
spinning is suffering with extra steps. The honest test: **when did you
last change something on purpose, and what did you measure
afterwards?** If the answer is "three attempts ago", escalate up the
ladder in [[Getting Help]].

> [!danger] Some questions are not twenty-minute questions
> Everything above assumes a low-voltage circuit on a current-limited
> supply, being changed with the output off. Anything involving a
> component that got hot, a smell of burning, a capacitor that may
> still be charged, a supply stacked in series, or any equipment
> plugged into the wall is ask-first, immediately, every time. That is
> the standing agreement in [[Safety in the Lab]], and no amount of
> diagnostic cleverness outranks it.

%%curriculum-start%%
## Curriculum connection

![[B2.1]]

![[B2.2]]
%%curriculum-end%%
