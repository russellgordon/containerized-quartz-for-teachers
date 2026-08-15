---
title: When Good Enough Is Not Safe
publish: true
created: __CREATED__
tags:
  - discussions
---
Everything you build this semester works on the bench before it works
anywhere else, and "works on the bench" is the weakest claim in
engineering. It means the thing functioned once, at room temperature,
while an attentive person watched it, for about four minutes. The
question this discussion asks is what has to be true before you are
willing to hand it to somebody who will plug it in, walk away, and
trust it.

> [!danger] The gap this page is about
> A circuit that works is not a circuit that is safe. Working is
> observed behaviour under the conditions you happened to test.
> Safe is a claim about behaviour under conditions you did *not*
> test — hotter, older, wetter, with the wrong plug in the wrong
> socket, and with someone's child in the room. Nothing you measure
> on a good day tells you what happens on the bad one.

The profession has built machinery for exactly this gap, and it is
worth knowing what it is before deciding what you think of it. Parts
carry **absolute maximum ratings**, and the practice of running well
below them has a name: derating. Products sold in Canada carry a
certification mark from an accredited body, which means an independent
laboratory tested a sample against a published standard. Electrical
work in Ontario is inspected. Professional engineers are licensed, and
the licence can be taken away. Counterfeit phone chargers are a
standard cautionary example in the trade precisely because the failure
they exhibit is invisible: too little isolation between the mains side
and the low-voltage side, in a product that charges phones perfectly
well right up until it does not.

Software makes the gap worse, not better, because a fault in code
leaves no burn mark. The case every engineering programme teaches is
the Therac-25, a radiation therapy machine whose control software
could, under a rare sequence of operator inputs, deliver a massive
overdose. It killed people. The machine was not sabotaged and the
engineers were not villains; safety interlocks that had previously
been physical were moved into software, the failure mode was rare
enough to look like operator error, and reports from the field were
not believed quickly enough. You will write code that drives hardware
in Unit 3. Read that sentence again then.

Questions worth arguing about:

1. Where exactly is the line between a prototype and a product? Name
   the specific tests, documents, and margins that would have to
   exist before you would let a family member use something you
   built. Be concrete: how many hours, what temperature, what happens
   when a wire comes loose?
2. A part's absolute maximum rating says 30 mA. Your design runs it
   at 28 mA and works perfectly. Defend that design. Then argue
   against it. Which argument is easier, and which one is right?
3. Standards and certification cost money, slow products down, and
   are set by committees that include the manufacturers. Is that
   capture, or is it the only way to get the expertise in the room?
4. The Therac-25's operators reported problems that were not believed.
   In any system — a hospital, a shop, a classroom — what makes a
   report get taken seriously? What in *our* lab makes reporting a
   near miss easy or hard?
5. Suppose you knowingly ship something with a known flaw and
   document the flaw honestly. Are you covered? What does honest
   documentation actually transfer, and what does it not?

The connection to your own bench is direct rather than metaphorical.
[[Health and Safety in the Shop]] carries the standards and the
practice; [[Documenting Your Build]] is where the honest known-issues
list gets written; and every task this semester is marked partly on
whether somebody else could safely service what you made. Decide here
what you think you owe the person who plugs it in, because you will be
asked to act on that answer within the week.

%%curriculum-start%%
## Curriculum connection

![[D1.1]]

![[D1.2]]

![[B1.2]]
%%curriculum-end%%
