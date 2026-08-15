---
title: Number Strings
publish: true
created: __CREATED__
tags:
  - number-talks
---
A string is a chain of related problems, served one at a time: the
chance that two people in a room have *different* birthdays, then
three people, then four, then ten. Each answer is a stepping stone to
the next — and in this course, the strings are quietly building the
machinery before anyone names it.

## How we play

1. One problem at a time. Solve it in your head; thumb when ready.
2. A few people defend their methods; each goes on the board.
3. Before computing the next from scratch, ask: what can I reuse?

> [!example]- The string, walked
> - "Two people. The second person has to dodge one occupied day, so
>   the chance they differ is $\frac{364}{365}$ — call it 0.997. So
>   the chance they *match* is about 0.3%."
> - "Three people. The third has to dodge two days, so multiply what
>   we already had by $\frac{363}{365}$. About 0.992, so a match is
>   about 0.8%. I did not start over — I reused the last answer."
> - "Four: multiply again by $\frac{362}{365}$. The matching chance
>   creeps to about 1.6%. Every new person multiplies in a slightly
>   crueller fraction, so this is going to fall faster than it
>   looks."
> - "Ten people: nine multiplications in, the no-match chance is
>   about 0.88, so a match is about 12%. Someone said 'so it needs
>   about 180 people to reach a half' and someone else said 'no —
>   look how fast the drop is accelerating.'"
>
> Nobody was taught a formula that day. The string cornered the
> method — *find the chance of the thing not happening, then subtract
> from one* — and [[The Birthday Problem]] just handed the room the
> arithmetic to run it out to 23.

## One variation

Run a string on Pascal's triangle instead: $\binom{5}{2} = 10$ — and
$\binom{5}{3} = 10$ — so what is $\binom{6}{3}$? Every thumb goes up
at 20, because the room can see the two parents sitting above the
child. Then the sting in the tail: what is $\binom{6}{3}$ *without*
the triangle, from a room of six people choosing a committee of
three? The two answers must agree, and finding out why they must is
the entire content of [[Pascal's Triangle]].

> [!tip] Lazy, in the best way
> Mathematicians refuse to compute what they can deduce. If a problem
> feels brand new, look back along the string — it rarely is. The
> most reusable move in this whole course showed up in the string
> above: when "at least one" is hard, count the ways it *never*
> happens and take the complement, a habit [[Probability Basics]]
> installs permanently.
