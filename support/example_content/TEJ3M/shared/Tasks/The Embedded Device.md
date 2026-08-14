---
title: The Embedded Device
draft: false
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Pairs · two bench periods plus finishing time · a working device, its
> code, its schematic, a fault log, and one measured claim ·
> demonstrated at the end of Unit 3

## What you are making

One sensor in, one actuator out, one job. A greenhouse fan that runs when
the soil sensor reads dry. A doorway counter that logs how many people
passed. A night light that fades up as the room darkens. A reaction-time
game with a scoreboard. A cooling fan that starts at a temperature you
chose and can defend.

What makes this a Grade 11 task is the claim. When you demonstrate, you
will state something specific and testable about your device — "the fan
starts within two seconds of the sensor crossing 700 counts, and it did
so on ten trials out of ten" — and then you will show the data that backs
it. [[Sensors and Actuators]] and [[Digital and Analog Signals]] are the
concepts; [[Blink, Read, React]] and [[Drive a Motor]] are the hands.

## Milestones

- [ ] **One sentence.** What it senses, what it does, and for whom.
- [ ] **Block diagram** — sensor, board, driver, actuator, supplies —
      before any component is chosen.
- [ ] **Schematic with values**, including the driver stage and, if
      anything inductive is in it, the flyback diode.
- [ ] **Current budget.** What every branch draws, checked against the
      pin limits and the supply, per [[Driving Outputs Safely]].
- [ ] **Code that a stranger could follow**, structured as
      [[Structuring Embedded Code]] describes: named constants, small
      functions, pin numbers in one place.
- [ ] **The measured claim**, with at least ten trials of data.
- [ ] **Fault log** — every fault, where you looked first, and what
      finally located it.

## How it is assessed

The criteria below, plus the framework in [[How Marks Work]]. Bench
periods are assessed as they happen. Your [[Tech Journal]] holds the fault
log and the trial data, and both of those are worth more here than a tidy
final photograph.

## Success criteria

| Quality | What it looks like at your bench |
| --- | --- |
| A device that does its job | The one-sentence job happens, on demand, repeatably |
| A claim that survives testing | A specific number, ten trials, and the data to show |
| A safe driver stage | Nothing inductive without a diode, nothing large hung off a pin |
| A budget that was checked | Every branch current calculated before it was connected |
| Code somebody else can read | Named constants, small functions, comments that explain why |
| A traced system | Either partner can narrate sensor to code to actuator |
| Faults chased methodically | The log shows halving and testing, not swapping parts |

## Reflect

In your [[Tech Journal]]: which half of this device fought you harder,
the hardware or the software — and how long did you spend searching the
wrong half? Then the useful part: what measurement, taken early, would
have told you which half to look in?
[[Debugging Hardware and Software Together]] is the technique; your entry
is the evidence you used it.

> [!example]- A claim worth making, and a claim that is not
> **Not a claim:** "The fan turns on when it gets hot." Unfalsifiable —
> at what reading, after how long, how reliably? **A claim:** "The fan
> starts within 2 s of the sensor reading rising above 700 counts —
> about 2.26 V at the input, on this board's ten-bit converter with a
> 3.3 V reference — and it did so on 10 of 10 trials." That version can
> be wrong, which is exactly what makes it worth stating and testing.

%%curriculum-start%%
## Curriculum connection

![[A3.5]]

![[B5.1]]

![[B5.2]]

![[B5.3]]

![[A1.1]]

![[A3.4]]

![[D1.1]]
%%curriculum-end%%
