---
title: Crimp and Test a Cable
publish: true
created: __CREATED__
tags:
  - labs
enableToc: true
---
Every network you will ever build hangs off cables somebody made, and
today that somebody is you: cut, strip, order, crimp, test. The
colour order is the discipline of this lab — any order of copper
conducts, but only the standard keeps the right wires twisted
together, and the twists are what [[How Data Travels|cancel noise]].
At the end, a tester tells the truth about your work, light by light.

> [!danger] Safety notes
> **Cutter and crimper blades are sharp by design** — fingers stay
> behind the blade line, and tools go back sharp-end away, as agreed
> in [[Safety in the Lab]]. **Trimmed wire ends fly** — point the cut
> into the bench and wear safety glasses for every trim. **Sweep
> copper offcuts as you go**; they find their way into machines,
> shoes, and skin.

## What you need

- [ ] A length of twisted-pair network cable
- [ ] Two crimp plugs, plus spares — everyone spoils one
- [ ] Cable cutter, stripper, crimping tool, safety glasses
- [ ] Cable tester, and your class's colour-order chart

## The work

1. **Cut to length with a little mercy.** A cable trimmed twice is
   fine; a cable cut short once is scrap.
2. **Strip only the outer jacket**, about a thumb-width — score
   gently and flex. A stripper set deep enough to touch the
   conductors leaves nicks that fail months later.
3. **Untwist only what you must.** Each pair's twist is doing
   engineering; every extra untwisted centimetre invites noise in.
4. **Order the colours to the standard — only the standard.** There
   are two common orders; your class picked one. Mixing them across
   ends makes a cable that conducts but does not pair — the worst
   kind of wrong: partly working.
5. **Flatten, check the order again, and trim flush.** Uneven ends
   mean some conductors never reach their pins.
6. **Load the plug with the jacket inside, then crimp firmly.** The
   crimp must grip jacket, not bare wires — that grip is the strain
   relief that keeps every future tug away from the conductors.
7. **Do the other end, then test.** Lights in order means straight
   through; a dark light means a break; lights out of sequence means
   the order slipped. The tester has no opinions — only findings.

## What can go wrong

- **One light stays dark.** An open — usually a conductor not fully
  home before the crimp. Cut the plug off and redo that end; plugs
  are consumables, your time is not.
- **Two lights trade places.** The colour order slipped between your
  last check and the crimp. This is why step 5 checks *again*.
- **Passes the tester, flaky in use.** Almost always strain relief —
  the crimp caught conductors instead of jacket, and every tug works
  the joint. [[Cable Habits]] keeps finished cables healthy.

## Level up

Make a crossover cable — one end in each standard order — and find
out why it was once essential for connecting like to like, and why
modern equipment quietly made it a museum piece.

%%curriculum-start%%
## Curriculum connection

![[B3.1]]

![[A2.3]]
%%curriculum-end%%
