---
title: Design and Build a Logic Block
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Grade 11 built logic circuits from a truth table somebody else wrote.
Today you go the whole way: a specification in words, a truth table you
derive, an expression you simplify with the laws of Boolean algebra, and
a circuit on the bench that does what the words said.

> [!danger] Safety notes
> Low voltage, but **static kills logic chips silently** — strap on,
> chips in their tube until the moment they go in the board. Power off
> before any wire moves; a supply rail into an input pin destroys a chip
> in microseconds and the failure is not always obvious afterwards.

## What you need

- [ ] Logic chips from the drawer, plus their datasheets
- [ ] Breadboard, wire, switches, and LEDs with their resistors
- [ ] Logic analyser or scope, per [[Using a Logic Analyzer]]
- [ ] Your simplification, written out, before you draw any wire

## Choose one block

- **A half adder, then a full adder.** Two bits and a carry in, sum and
  carry out.
- **A two-to-four decoder** with an enable input.
- **A four-input priority encoder** — which input is highest, and is any
  input active at all?
- **A three-input majority vote**, which is how redundant systems decide.
- **A seven-segment decoder** for one digit, which is more work than it
  sounds and worth it.

## The work

1. **Specify it in words**, including what happens in every case you
   might otherwise leave undefined. Ambiguity here becomes a bug later.
2. **Build the truth table.** Every input combination, no exceptions —
   $2^n$ rows for $n$ inputs.
3. **Write the expression** from the table, in sum-of-products form.
4. **Simplify it** using the laws of Boolean algebra, showing each step
   and naming the law you used. Count the gates before and after.
5. **Draw the circuit**, choosing gates that exist in the drawer — a
   NAND-only implementation is often cheaper in packages even when it
   looks longer on paper.
6. **Build it**, one section at a time, testing as you go.
7. **Verify every row of your truth table** on the bench. Not a sample —
   every row. This is the step that finds the wiring error.
8. **Time it.** Look at propagation delay on the analyser: the output is
   not instant, and in a fast system that delay is a design constraint.

## Record

| Row | Inputs | Predicted output | Measured output | Notes |
| --- | --- | --- | --- | --- |

Plus: gate count before and after simplification, the packages used, and
the measured propagation delay from input change to stable output.

## Think about it

1. Which simplification law saved you the most gates, and what did it
   cost in readability of the circuit?
2. Your measured propagation delay is longer than the sum of the
   datasheet figures for the gates in the path. Name two plausible
   causes.
3. A microcontroller could do this block in three lines of code. Give
   two situations where the gates are still the right answer, with a
   reason each. [[Timing, Interrupts, and Real Time]] is relevant to
   both.

%%curriculum-start%%
## Curriculum connection

![[A5.3]]

![[A5.4]]

![[B3.3]]
%%curriculum-end%%
