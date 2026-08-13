---
title: When Code Hurts
draft: false
created: __CREATED__
tags:
  - discussions
---
Nobody writes a line of code that says "work badly for these people."
The harm gets in anyway, and usually through the same three doors: the
**data** a system learned from or stores, the **design** choices about
who was imagined using it, and the **deployment** — where it ends up,
and on whom. Three concrete cases, none of them exotic:

- A form that requires a phone number to submit. Anyone without a
  phone is now not a customer, and nobody on the team noticed because
  everyone on the team has a phone.
- A booking system that puts important information in colour alone —
  red for full, green for open. A colour-blind user reads a grid of
  identical grey boxes.
- A registration field for a name that rejects apostrophes, accents,
  or names shorter than three letters. Real people are told their real
  names are invalid.

None of these is a bug in the sense of a crash. Each one is a decision
that treated some group of people as an edge case, and every one of
them is fixable by a Grade 11 programmer in an afternoon.

> [!important] Error messages are where dignity lives or dies
> `INVALID INPUT` tells a user they are the problem. "Please type the
> number of hours using digits, like 12" tells them what to do next.
> The second one takes ten more seconds to write and is the entire
> difference between a program that helps and a program that scolds.

Questions worth arguing about:

1. Which of the three cases above is the most harmful, and to whom?
   Does "nobody meant it" change your answer — and should it matter to
   the person locked out?
2. When a system works better for some accents, some names, or some
   bodies than others, somebody's version was treated as the default.
   How would a team even *notice*, if everyone on it shared the
   default?
3. Is a tool a disabled person cannot operate a case of bias, or of
   oversight? From the outside, is there a difference?
4. Suppose an automated system makes fewer mistakes on average than
   the humans it replaces, but the mistakes it does make land on the
   same group every time. Use it, or not?
5. What can you already do, this term, with the programs you write?
   Name three habits — and be honest about which ones you have skipped
   because you were rushing.

The habits have addresses in this course: readable interfaces and
honest error messages in [[Writing Code Others Can Read]], testing
with somebody who is not you in [[The Bad Input Hunt]], and the wider
picture in [[Computers and Society]]. Per [[Our Classroom Norms]], we
argue this one with ideas and never at people. The point is to build
better, not to find villains.
