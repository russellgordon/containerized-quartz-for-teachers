---
title: The Logic Machine
publish: true
created: __CREATED__
tags:
  - tasks
enableToc: true
---
> [!abstract] At a glance
> Pairs · one design period and one bench period · a working gate
> circuit, its truth table, its simplified expression, and a test log ·
> demonstrated at the end of Unit 2

## What you are making

A circuit built from logic gates that does one job requiring it to
*remember* something. A two-floor lift indicator that holds the last
floor called. A three-judge vote that latches the result until reset. A
door that stays unlocked once the right combination is entered. A machine
that will not start until two separate people have each pressed a button.

Combinational logic decides; sequential logic remembers. Your machine has
to do both, which means at least one latch, built from gates you can
point at — [[Sequential Logic and Memory]] is the reference, and
[[Gates on the Bench]] gave you the chips.

## Milestones

- [ ] **One sentence.** What the machine does, and what it remembers.
- [ ] **Truth table**, complete — every combination of inputs, no gaps,
      including the ones you think cannot happen.
- [ ] **Boolean expression** derived from the table, then **simplified**
      with the working shown, per [[Boolean Algebra]].
- [ ] **Gate count, before and after** simplification. The saving is
      part of the deliverable.
- [ ] **Schematic** with chips, pin numbers, and decoupling capacitors
      drawn — not implied.
- [ ] **Built and tested**, every row of the table, in
      [[Build the Logic Machine]].
- [ ] **Test log** listing every fault found, the hypothesis you formed,
      and the test that confirmed it.

## How it is assessed

Assessment follows the criteria below and the framework in
[[How Marks Work]]. The design period counts as much as the bench
period: a machine that was simplified on paper before it was wired uses
fewer chips, fails in fewer places, and finishes earlier, and that is not
a coincidence. Your [[Tech Journal]] carries the reasoning.

## Success criteria

| Quality | What it looks like at your bench |
| --- | --- |
| A machine that remembers | The stored state survives the input going away |
| A complete truth table | Every input combination present, including the awkward ones |
| Simplification that paid | Gate count before and after, with the algebra shown |
| A schematic that matches | Pin numbers, supply pins, and decoupling all drawn and all present |
| Tested, not demonstrated | Every row checked and recorded, not the four that work |
| Faults chased, not guessed | Each fault has a hypothesis and the test that confirmed it |
| Careful handling | Strap on, orientation checked, power off before rewiring |

## Reflect

In your [[Tech Journal]]: your machine has a state it can be in at
power-up that your truth table never described. Find it, describe it, and
say what you would add to make the machine start in a known state every
time. Real products get this wrong regularly, and users experience it as
"you have to unplug it and plug it back in".

> [!warning]- If your simplified circuit behaves differently from the original
> Then one of the two is not what you think it is. Do not adjust wires
> until it agrees — go back to the truth table and evaluate both
> expressions row by row on paper. Either the algebra has a slip in it,
> or the circuit does not match the expression you believe you built.
> Both are found faster on paper than at the bench.

%%curriculum-start%%
## Curriculum connection

![[A5.3]]

![[B3.1]]

![[B3.2]]

![[B3.3]]

![[A5.1]]

![[A5.2]]
%%curriculum-end%%
