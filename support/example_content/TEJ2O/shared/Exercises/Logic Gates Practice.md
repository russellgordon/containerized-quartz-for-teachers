---
title: Logic Gates Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These questions follow [[Digital Logic Gates]] and the chips you
wired in [[Gates in Hardware]] — with the guessing game from
[[Predict the Circuit]] never far away.

## Questions

1. Complete the output column of the truth table for the AND gate,
   Y = A • B, for all four input rows: 00, 01, 10, 11.
2. Now the OR gate, Y = A + B — same four input rows, new outputs.
3. A gate has a single input, and its output is always the opposite
   of that input. Name it and describe its two-row truth table.
4. **Mystery gate.** Two inputs; the output is 0 *only* when both
   inputs are 1. Name the gate.
5. **Mystery gate.** Two inputs; the output is 1 only when the inputs
   *differ*. Name the gate and write out its truth table.
6. **Find the error.** A classmate reads Y = A + B and announces that
   when both inputs are 1, the output is 2 — "because one plus one".
   What has gone wrong?
7. **Trace this circuit.** An AND gate computes Z = A • B, and its
   output feeds an OR gate along with a third input: Y = Z + C.
   With A = 1, B = 0, C = 1, find Z and then Y.

## Answers

> [!success]- Answer 1
> Down the rows: 0, 0, 0, 1. AND is the strict gate — the output is 1
> only when *both* inputs are 1. Every other row starves it.

> [!success]- Answer 2
> Down the rows: 0, 1, 1, 1. OR is the generous gate — any 1 on an
> input is enough. Only the 00 row leaves it at 0.

> [!success]- Answer 3
> The NOT gate (an inverter). Input 0 gives output 1; input 1 gives
> output 0. Two rows, no surprises, endlessly useful.

> [!success]- Answer 4
> NAND — an AND gate followed by a NOT. Its column is AND's flipped:
> 1, 1, 1, 0. Only the both-on row is refused.

> [!success]- Answer 5
> XOR, the exclusive OR. Rows 00, 01, 10, 11 give 0, 1, 1, 0 — it
> answers the question "are these two inputs different?"

> [!success]- Answer 6
> The + in Y = A + B is Boolean OR, not arithmetic addition. A gate's
> output is a voltage that is on or off — there is no wire for "2".
> When both inputs are 1, the output is simply 1.

> [!success]- Answer 7
> Work gate by gate. Z = A • B = 1 • 0 = 0 — AND refuses. Then
> Y = Z + C = 0 + 1 = 1 — OR accepts, thanks entirely to C. One gate
> at a time, in order: that is all circuit tracing ever is.

%%curriculum-start%%
## Curriculum connection

![[A3.3]]

![[A3.4]]
%%curriculum-end%%
