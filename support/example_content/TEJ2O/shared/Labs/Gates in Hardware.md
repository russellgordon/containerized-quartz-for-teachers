---
title: Gates in Hardware
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Truth tables stop being homework today. You will build a working AND
and a working OR — as logic chips on your breadboard, or as switch
circuits if that is what your bench stocks — and verify every row by
hand. The tables you derived in [[Digital Logic Gates]] and drilled
in [[Logic Gates Practice]] become predictions, and the hardware
grades them.

> [!danger] Safety notes
> **Logic chips are static-sensitive** — strap on, and each chip
> stays in its foam until the board is ready
> ([[Anti-Static Habits]]). **A warm chip is a wrongly powered chip**
> — power off immediately and recheck orientation. **Pins bend and
> break** — seat chips straight down with even pressure, and lever
> them out gently from both ends. Low voltage only, as always.

## What you need

- [ ] Breadboard, jumper wires, $5\ \text{V}$ supply
- [ ] An AND chip and an OR chip (or switches to build both)
- [ ] Two input switches, one LED with its $220\ \Omega$ resistor
- [ ] Blank truth tables in your journal — filled in *before* wiring

## The work

1. **Predict both truth tables first.** Four input rows each for AND
   and OR, outputs committed in ink — the lab only means something
   if the prediction comes before the evidence.
2. **Find pin 1.** The notch or dot marks it; every pin counts round
   from there. A chip seated backwards gets power where it expects
   ground — that is the warm chip from the safety notes.
3. **Power the chip itself** — corner power pins to the rails. A
   gate needs energy even to say 0; its output is driven, never
   merely "off".
4. **Wire both inputs through the switches to definite levels** —
   cleanly high or low, never dangling. A floating input reads
   electrical noise and answers with fiction.
5. **Put the LED and resistor on the output** — the loop from
   [[Breadboard a Circuit]] — so the gate decides and the LED
   reports.
6. **Step through all four rows** — off/off, off/on, on/off, on/on —
   recording the LED beside your prediction. Rewire for the second
   gate and repeat.
7. **Write each gate's Boolean equation** under its table:
   $Y = A \cdot B$ for AND, $Y = A + B$ for OR. Switch builders,
   notice the equations were visible all along — series is AND,
   parallel is OR.

## What can go wrong

- **The output flickers when your hand comes near.** A floating
  input — step 4 missed one, and the gate is amplifying the room.
  Tie it down and the fiction stops.
- **The output ignores the switches.** Wrong pin. Recount from the
  notch against the pin diagram — chips do not guess which legs you
  meant.
- **One row disagrees with your prediction.** Re-derive that row by
  hand before blaming the chip — in this lab the hardware is usually
  the honest party.

## Level up

Wire the AND's output into the OR's input and work out what the
combination computes — table first, then hardware. You have started
doing what [[Binary and Number Systems|processors do]] a billion
times a second.

%%curriculum-start%%
## Curriculum connection

![[B2.1]]

![[A3.3]]

![[A3.4]]
%%curriculum-end%%
