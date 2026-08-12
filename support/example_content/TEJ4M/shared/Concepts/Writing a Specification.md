---
title: Writing a Specification
draft: false
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The autopsy in [[The Failure Autopsy]] ended in an argument. Half the
room said the device had failed; the other half said it had done exactly
what it was built to do, in a place nobody had said it would have to
work. Both were right, and that is the problem. Nobody could produce a
single sentence saying what the thing was supposed to do, under what
conditions, and how you would know. Without that sentence there is no
such thing as a failure — only a surprise.

A **specification** is that sentence, multiplied. It is the document a
stranger could build from, test against, and argue with. This year you
write one before you choose a single component.

## Requirements, constraints, and acceptance tests

Three different kinds of statement go into a spec, and mixing them up is
the most common thing that goes wrong in Grade 12 work.

A **requirement** says what the device must do. A **constraint** is a
limit the solution has to live inside — cost, size, supply voltage, the
parts actually in the drawer. An **acceptance test** is the procedure
that decides whether a requirement has been met, written so that two
different people running it get the same verdict.

| Statement | Kind | Why it works or fails |
| --- | --- | --- |
| "The alarm shall sound when the door opens." | Requirement | Says what, not how — good |
| "Uses a piezo buzzer." | Constraint (or a design decision in disguise) | Fine if it is genuinely imposed; otherwise it is you deciding early |
| "The alarm shall sound within 500 ms of the door opening." | Requirement | Testable, because it has a number |
| "Open the door and time the buzzer with a stopwatch, five trials, all under 500 ms." | Acceptance test | Two people, one verdict |
| "The alarm should be reliable." | None of the above | Untestable. Delete it or replace it with a number |

That last row is the whole lesson. A requirement without a number is a
wish, and a wish cannot fail, which means it also cannot pass.[^1]

## Making a requirement testable

Take a vague statement and push a number into it. "Long battery life"
becomes "shall run for at least 48 hours on one 2000 mAh cell". Now it
can be checked before anything is built, which is the point of writing it
down early. Suppose your budget says the board draws 25 mA, the sensor
3 mA, and the radio 120 mA for 200 ms once a minute. The radio's
contribution averaged over the minute is

$$I_{\text{radio,avg}} = 120\ \text{mA} \times \frac{0.2\ \text{s}}{60\ \text{s}} = 0.4\ \text{mA}$$

so the average draw is $25 + 3 + 0.4 = 28.4\ \text{mA}$ and the run time
is

$$t = \frac{2000\ \text{mA} \cdot \text{h}}{28.4\ \text{mA}} \approx 70\ \text{h}$$

which clears 48 hours with room to spare — and if it had not, you would
have found out on paper instead of on the last night before the demo.
[[Specification Practice]] drills exactly this arithmetic.

> [!question] Whose requirement is it?
> Every requirement in a real spec comes from somebody: a user, a
> standard, a safety code, a purchasing limit, or the physics of the
> problem. Write the source beside it. When a requirement later turns
> out to be expensive, the first question at a design review is "who
> asked for this?" — and "I assumed" is an answer that costs you the
> argument.

## The shape of the document

1. **Purpose** — one paragraph a non-specialist can read.
2. **Requirements** — numbered, each testable, each with a source.
3. **Constraints** — supply, size, cost, environment, parts available.
4. **Interfaces** — every signal that crosses the boundary of your
   device, with its voltage, direction, and meaning. This is where
   [[System Block Diagrams]] and the spec meet.
5. **Acceptance tests** — one per requirement, by number.
6. **Open questions** — what you have not decided yet, honestly listed.

Number everything, because the numbers are how the rest of your work
refers back. When [[Component Selection and Tolerances]] justifies a
part, it cites the requirement that forced the choice. When your build
log records a test, it cites the acceptance test it ran. When
[[The Specification]] is marked, that traceability is most of the mark.

Keep the document under revision control or at least under revision
*numbering* — [[Version Control for Firmware]] applies to prose as much
as to code, and a specification that changed silently between the design
review and the build is not a specification.

[^1]: The word **shall** does the heavy lifting in real engineering
    specifications: by long convention it marks a binding requirement,
    while *should* marks a preference and *may* marks a permission.
    Standards bodies write their documents this way so that a reader can
    tell obligations from suggestions at a glance. Adopt the habit — it
    costs nothing and removes an entire category of argument.

%%curriculum-start%%
## Curriculum connection

![[A3.1]]

![[B2.2]]

![[B3.1]]

![[D3.3]]
%%curriculum-end%%
