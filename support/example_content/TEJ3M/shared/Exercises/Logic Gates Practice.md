---
title: Logic Gates Practice
draft: false
created: __CREATED__
tags:
  - exercises
---
These follow [[Logic Gates]] and the tables you filled in by measurement
in [[Gates on the Bench]]. Write every truth table out in full, including
the rows you think you already know — half a table has never once caught
an error.

## Reading gates

1. Copy this table and complete every column.

   | A | B | AND | OR | NAND | NOR | XOR |
   | --- | --- | --- | --- | --- | --- | --- |
   | 0 | 0 |  |  |  |  |  |
   | 0 | 1 |  |  |  |  |  |
   | 1 | 0 |  |  |  |  |  |
   | 1 | 1 |  |  |  |  |  |

2. A two-input gate has this behaviour: output 1 when the inputs are
   0 and 0, and output 0 in every other row. Which gate is it?
3. Build the truth table for $Y = A \cdot \overline{B}$. Describe in one
   plain sentence what this circuit detects.
4. Which single gate outputs 1 exactly when its two inputs disagree, and
   what everyday job does that make it good at?

## Combining gates

5. Build the full truth table for $Y = (A + B) \cdot \overline{C}$.
   Eight rows. Then say, in one sentence, what the circuit does.
6. Show how to make a NOT gate using only a NAND gate, and then how to
   make an AND gate using only NAND gates. Explain why this matters when
   you are standing at the parts drawer.
7. A workshop alarm should sound when the system is armed **and** a door
   sensor reads open — or whenever the panic button is pressed,
   regardless of anything else. Write the Boolean expression using $S$
   for armed, $D$ for door open, and $P$ for panic, and name the gates
   you would need.
8. **Find the error.** A classmate wires one input of a two-input AND
   gate to a switch, leaves the other input unconnected, observes that
   the output "mostly follows" the switch, and concludes the chip is
   faulty. What is actually happening, and what should they do?

## Answers

> [!success]- Answer 1
> | A | B | AND | OR | NAND | NOR | XOR |
> | --- | --- | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 1 | 1 | 0 |
> | 0 | 1 | 0 | 1 | 1 | 0 | 1 |
> | 1 | 0 | 0 | 1 | 1 | 0 | 1 |
> | 1 | 1 | 1 | 1 | 0 | 0 | 0 |
>
> Read the NAND column against the AND column and the NOR column against
> the OR column: each is the other one inverted, row for row. That is the
> whole meaning of the bubble on the schematic symbol.

> [!success]- Answer 2
> **NOR.** It outputs 1 only when neither input is 1 — "neither" is
> exactly the negation of "at least one". Compare it with the OR column
> in answer 1 and you will find it upside down.

> [!success]- Answer 3
> | A | B | $\overline{B}$ | $Y = A \cdot \overline{B}$ |
> | --- | --- | --- | --- |
> | 0 | 0 | 1 | 0 |
> | 0 | 1 | 0 | 0 |
> | 1 | 0 | 1 | 1 |
> | 1 | 1 | 0 | 0 |
>
> In words: the output is 1 only when A is present and B is absent. It
> detects one specific combination — "A but not B" — which is how an
> interlock is built. The machine runs when the start signal is on *and*
> the guard-open signal is not.

> [!success]- Answer 4
> **XOR**, the exclusive OR. Its output is 1 when exactly one input is 1,
> which is the same as saying the inputs differ.
>
> The everyday job is comparison. Feed two bits into an XOR and the
> output tells you whether they match — which is the building block of
> equality checks, of parity for error detection, and of the addition
> circuit inside every processor, where XOR produces the sum bit and AND
> produces the carry.

> [!success]- Answer 5
> | A | B | C | $A + B$ | $\overline{C}$ | $Y$ |
> | --- | --- | --- | --- | --- | --- |
> | 0 | 0 | 0 | 0 | 1 | 0 |
> | 0 | 0 | 1 | 0 | 0 | 0 |
> | 0 | 1 | 0 | 1 | 1 | 1 |
> | 0 | 1 | 1 | 1 | 0 | 0 |
> | 1 | 0 | 0 | 1 | 1 | 1 |
> | 1 | 0 | 1 | 1 | 0 | 0 |
> | 1 | 1 | 0 | 1 | 1 | 1 |
> | 1 | 1 | 1 | 1 | 0 | 0 |
>
> In words: the output is 1 when at least one of A and B is present and
> C is absent. C is an inhibit input — whenever C is 1, the output is 0
> no matter what else is happening. Look down the $Y$ column and notice
> that every row with C = 1 is 0. That is a disable line, and it is how
> an emergency stop is wired.

> [!success]- Answer 6
> **NOT from NAND:** tie both inputs together and drive them with the
> same signal. Only two rows of the NAND table can now occur — 0,0 which
> gives 1, and 1,1 which gives 0. That is inversion.
>
> **AND from NAND:** a NAND is an AND followed by an inversion, so invert
> it back. Feed A and B into one NAND, then feed that output into a
> second NAND wired as an inverter. Two NANDs, one AND.
>
> **Why it matters:** NAND is *universal* — every other gate can be built
> from it. In practice that means a single chip containing four NAND
> gates can stand in for a design you drew with AND, OR, and NOT gates,
> so you can finish a build at four o'clock on a Friday with the parts
> actually in the drawer. It is also cheaper in silicon, which is why
> real integrated circuits are full of NAND.

> [!success]- Answer 7
> $\text{Siren} = (S \cdot D) + P$.
>
> One AND gate to combine armed with door-open, and one OR gate to let
> the panic button override everything. Read the expression back as a
> sentence to confirm it says what you meant: "armed and door open, or
> panic" — yes.
>
> Worth noticing: because $P$ is ORed in at the very end, no combination
> of $S$ and $D$ can suppress it. That is what "regardless of anything
> else" translates to in a circuit, and getting that structure right is
> the difference between a safety feature and a decoration.

> [!success]- Answer 8
> **What is happening:** the unconnected input is *floating*. It has no
> defined voltage, so it drifts, picks up interference from the bench and
> from your classmate's hand, and lands on whatever side of the chip's
> threshold it happens to reach. When it happens to float high, the AND
> gate passes the switch through. When it does not, the output stays low.
> "Mostly follows" is the signature of a floating input.
>
> **What is not happening:** a fault. The chip is behaving exactly as
> specified for an input that was never given a value.
>
> **What to do:** tie the unused input deliberately — to the supply
> through a resistor for a logic 1, or to ground for a logic 0 — and
> retest. Then adopt it as a rule: every unused input on every chip gets
> tied to something. A circuit whose behaviour changes when you touch it
> has a floating input somewhere, every time.

Once the gates are secure, start reducing them in
[[Boolean Simplification Practice]], then build something that has to
work in [[The Logic Machine]].
