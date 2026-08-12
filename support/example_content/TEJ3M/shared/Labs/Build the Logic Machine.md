---
title: Build the Logic Machine
draft: false
created: __CREATED__
tags:
  - labs
enableToc: true
---
This is the bench day for [[The Logic Machine]]: you arrive with a truth
table, a simplified Boolean expression, and a schematic, and you leave
with a circuit that has been tested against every row of that table — not
the rows you happened to try, every row.

A machine that behaves correctly in the four states you demonstrated and
wrongly in the fifth is not "mostly working". It is broken in a way that
will be found by somebody else, later, in worse circumstances. Testing
every row is not thoroughness. It is the job.

> [!danger] Safety notes
> **Strap on before the chips come out** — [[Anti-Static Habits]] again,
> every time, including today when you are in a hurry.
> **Orientation and supply pins checked twice before power**: on 14-pin
> packages $V_{CC}$ is pin 14 and ground is pin 7, and a reversed supply
> destroys a chip in a second while getting hot enough to burn. **Supply
> at $5\ \text{V}$ with the current limit set low** — for a circuit of
> this size, $100\ \text{mA}$ is generous, and a limit that trips is a
> mistake that stayed cheap. **Power off before every rewire**, no
> exceptions when you are three faults deep and impatient. **A chip that
> is warm to the touch is telling you something**: power down and find
> the floating input or the shorted output before you power up again.

## What you need

- [ ] Your schematic, truth table, and simplified expression, on paper
- [ ] Logic ICs as your design requires, plus spares
- [ ] One $100\ \text{nF}$ ceramic capacitor per chip
- [ ] Switches with $10\ \text{k}\Omega$ pull-down resistors for inputs
- [ ] LEDs with $1\ \text{k}\Omega$ resistors for outputs
- [ ] Breadboard, jumper wires, $5\ \text{V}$ supply, multimeter
- [ ] Anti-static strap, safety glasses, and your journal

## Predict before you build

1. **Predict the supply current** your machine will draw in its
   quiescent state and with every output lit. The logic itself draws
   almost nothing — CMOS quiescent current is measured in microamps —
   so your prediction is essentially the sum of the LED currents. With
   $1\ \text{k}\Omega$ resistors and LEDs dropping about $2\ \text{V}$
   from a $5\ \text{V}$ rail, each lit LED is roughly $3\ \text{mA}$.
   Two LEDs lit means about $6\ \text{mA}$. Write the number down.
2. **Predict the gate count** your simplified expression needs, and the
   count your unsimplified one would have needed. The difference is the
   part of [[Boolean Algebra]] that shows up on an invoice.
3. **Predict which row will fail first.** Genuinely — pick one, in
   writing, with a reason. Most benches pick a row involving the latch,
   and most benches are right, and knowing that in advance changes how
   you wire.

## The work

4. Wire the supply rails, ground, and one decoupling capacitor per chip
   first. Power up with no logic connected and confirm $5\ \text{V}$ at
   every chip's supply pins.
5. Build **one stage at a time** and test that stage before adding the
   next. A machine built entirely and then tested is a machine you will
   debug backwards.
6. Tie every unused input. Every one. This is the fault that hides
   longest because it produces behaviour that changes when you touch the
   board.
7. Walk the full truth table with the supply on: set the inputs, record
   the output voltage, mark the row pass or fail.
8. For each failure, form a hypothesis before you touch anything, write
   it down, then test only that hypothesis. Halve the circuit, probe the
   middle, and see which half lied — the method in [[Getting Unstuck]].
9. When every row passes, hand the machine to the bench across the aisle
   and let them try to break it. Record what they find.

## Results

| Row | Inputs | Expected output | Measured output (V) | Pass? |
| --- | --- | --- | --- | --- |
| 1 | | | | |
| 2 | | | | |
| 3 | | | | |
| 4 | | | | |
| 5 | | | | |
| 6 | | | | |
| 7 | | | | |
| 8 | | | | |

| Measurement | Predicted | Measured |
| --- | --- | --- |
| Quiescent supply current (mA) | | |
| Supply current, all outputs active (mA) | | |
| Gate count, simplified | | |
| Gate count, unsimplified | | |

## Predicted against measured

Compare your predicted supply current to the measured figure. If the
measurement is much higher than the LEDs can account for, something is
drawing current that should not be — a floating input oscillating, an
output fighting another output, or a chip in backwards. Find it before
you go further; that current is being turned into heat inside a part you
would like to keep.

Compare your predicted first failure to the row that actually failed
first. If you were right, say what you knew. If you were wrong, say what
you had assumed that turned out not to be true. Both answers are worth
the same to us, and the second one is worth more to you.

## The question that matters

Your machine passed all eight rows. Does that prove it is correct? Argue
both sides honestly. Then find the situation your truth table never
described — two inputs changing at the same instant, a switch bouncing, a
power-up in an unknown state — and go find out at the bench what your
machine does there. That gap between "passes its tests" and "is correct"
is the whole subject of [[When Good Enough Is Not Safe]].

%%curriculum-start%%
## Curriculum connection

![[A5.3]]

![[B3.1]]

![[B3.3]]
%%curriculum-end%%
