---
title: Which One Doesn't Belong
draft: false
created: __CREATED__
tags:
  - warm-ups
---
Four things go up in a two-by-two grid and the question never changes:
which one doesn't belong? There is no answer key. Every corner can be
defended, and the defence is the entire point.

What has changed for Grade 12 is what goes in the corners. Last year
the grids held four components and a good defence named a property.
This year the grids hold **four things that could all do the same
job** — four ways to switch a load, four ways to make a rail, four
ways to sense a temperature — and a good defence names the property
that would decide it *in a real design*: cost, tolerance, heat,
isolation, availability, or how it fails.

## How to run it

1. Show the grid. One quiet minute — everyone commits to a corner in
   writing before any hands go up.
2. Hands up by corner. A good grid gets takers in all four; an empty
   corner means the grid needed more thought than it got.
3. Defenders speak. The rule is stricter than last year: name the
   property **and** name a design where that property decides the
   choice. "Only this one isolates the control side from the load, so
   it is the only one I could use if the load ran from the mains" is a
   Grade 12 defence.
4. Close by collecting the vocabulary the defences used. That list is
   the real output of the routine, and it is the vocabulary
   [[The Specification]] expects you to write in.

> [!example]- Four ways to switch a load
> | | |
> | --- | --- |
> | Mechanical relay | Bipolar transistor |
> | MOSFET | Solid-state relay |
>
> Only the ==relay== gives true galvanic isolation between the control
> side and the load with nothing but an air gap and a coil — and it is
> also the only one with moving contacts, so it is the only one with a
> finite number of operations in it before it wears out.
>
> Only the ==bipolar transistor== is controlled by a continuous
> *current* into its base rather than a voltage, and its on-state drop
> stays roughly constant as the load current rises — so its heat
> climbs in proportion to current.
>
> Only the ==MOSFET== behaves like a resistance when it is on, so its
> heat climbs with the *square* of the current, and that resistance
> rises as it gets hotter — which sounds bad and is actually why
> paralleled MOSFETs share current with each other instead of one of
> them hogging it all.
>
> Only the ==solid-state relay== arrives as a finished assembly whose
> isolation was designed, tested, and certified by somebody else. You
> buy that guarantee rather than making it, which is a completely
> different kind of engineering decision — see
> [[Standards and Professional Practice]].

> [!example]- Four ways to make a 3.3 V rail
> | | |
> | --- | --- |
> | Linear regulator | Switching buck converter |
> | Resistive divider | Zener shunt regulator |
>
> Only the ==resistive divider== has an output that moves whenever the
> load changes. It is not a regulator at all, which makes it the
> honest answer to "which one doesn't belong" and also the one that
> shows up in student designs most often.
>
> Only the ==linear regulator== turns exactly the voltage it drops
> into heat, at the load current, every time — which makes its thermal
> behaviour computable in one line and its efficiency a fixed
> consequence of the input voltage you chose.
>
> Only the ==buck converter== can be efficient regardless of how far
> it steps down, because it chops and stores energy rather than
> burning the difference — and it is the only one that puts noise onto
> your board deliberately, at its switching frequency, as a condition
> of working at all.
>
> Only the ==Zener shunt== draws its full design current from the
> supply whether the load wants it or not, so its worst case for heat
> is when nothing is connected. Every other corner gets cooler as the
> load goes away.

## One variation

Students build the grids from a real requirement. Take one line out of
a specification — "hold 3.3 V ±2 % at up to 400 mA, in a sealed
enclosure, from a 12 V input" — and put four candidate solutions in the
corners. A grid with four genuinely honest corners is far harder to
build than to solve, because you have to know four true properties and
check that each one is unique to its corner. Building one pays more
than solving five, and it is the same work
[[Component Selection and Tolerances]] asks for on a longer timescale.

> [!tip] Defend the corner you rejected
> Once your own corner is safe, go and argue for a different one — and
> then write down, in one sentence, why it lost. That sentence is
> exactly what your [[Tech Journal]] wants from every design decision
> this year, and it is the thing a design review will ask you for
> first. A choice you can only defend is a preference. A choice whose
> alternatives you can also defend is engineering.
