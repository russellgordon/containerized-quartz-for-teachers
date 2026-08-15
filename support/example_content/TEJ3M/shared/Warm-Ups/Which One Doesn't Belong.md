---
title: Which One Doesn't Belong
publish: true
created: __CREATED__
tags:
  - warm-ups
---
Four things go up in a two-by-two grid and the question never changes:
which one doesn't belong? There is no answer key. Every corner can be
defended, and the defence is the entire point — arguing out loud
demands the precise vocabulary that pointing and saying "that one"
lets you skip. This year the grids are four components or four gates,
and a defence has to name a *property*, not an appearance.

## How to run it

1. Show the grid. One quiet minute — everyone commits to a corner in
   writing before any hands go up.
2. Hands up by corner. A good grid gets takers in all four; if one
   corner is empty, the grid needed more thought than it got.
3. Defenders speak. The rule: name the property. "Only one stores
   energy and gives it back" beats "it looks different".
4. Close by collecting the vocabulary the defences used. That list is
   the real output of the routine.

> [!example]- A components grid with four honest corners
> | | |
> | --- | --- |
> | 220 Ω resistor | red LED |
> | 470 µF electrolytic capacitor | 1N4148 diode |
>
> Only the resistor works either way round — the other three are
> polarised, and installing any of them backwards ruins the circuit
> or the part. Only the LED reports its own state; the rest do their
> jobs invisibly. Only the capacitor stores energy and returns it
> later, which is why it can smooth a supply or set a timing
> interval. And only the 1N4148 is identified by a part number rather
> than a value and a unit — you order the other three by number, and
> that one by name, which is exactly when
> [[Reading a Datasheet]] stops being optional.

> [!example]- A logic grid with four honest corners
> | | |
> | --- | --- |
> | AND | OR |
> | XOR | NAND |
>
> Only NAND is universal — give a technician nothing but NAND gates
> and every other function on this grid can be built from them. Only
> XOR outputs 0 for both of the input pairs that match each other,
> which is why it is the gate that answers "are these two different?"
> Only AND puts out a 1 for exactly one of the four input
> combinations. And only OR does in a circuit what its English word
> promises in a sentence — XOR is what people usually *mean* when
> they say "or", which is a source of confusion worth naming out
> loud once and then never falling for again.

## One variation

Students build the grids, pulling from the parts drawer, from the
datasheets they have open, or from four values on a schematic. A grid
with four genuinely honest corners is far harder to build than to
solve — you have to know four true properties of four parts and check
that each one is unique to its corner. That is why building one pays
more than solving five.

> [!tip] Take up a corner you did not pick
> Once your own corner is safe, go and defend a different one. The
> vocabulary from [[Components and Their Markings]] and
> [[Logic Gates]] is only yours when you can argue all four sides,
> and the corner you find hardest to defend is the part you
> understand least.
