---
title: Estimation Duels
publish: true
created: __CREATED__
tags:
  - number-talks
---
A quantity goes on the board — how many different five-card hands a
deck can deal, how many people it takes before a shared birthday is
more likely than not, how many people a national poll actually asks —
and two duellists commit to estimates before anyone computes. Each
defends a reason. Then the class brackets: surely too low, surely too
high, squeezed until cornered.

## How we play

1. Commit in writing first. A number without a reason scores nothing.
2. Defend: what did you compare it to, and which way did rounding
   push you?
3. Bracket as a class, then calculate the reveal.

> [!example]- One duel: how many five-card hands from a standard deck?
> - "Fewer than $52^5 = 380{,}204{,}032$ — that would be the count if
>   a card could be dealt to you five times, and it cannot."
> - "Fewer still: $52 \times 51 \times 50 \times 49 \times 48 =
>   311{,}875{,}200$. That is the honest count of *ordered* deals —
>   but a hand is a hand no matter what order it arrived in."
> - "So divide by the number of orders one hand can arrive in, which
>   is $5! = 120$. That corners it near $311{,}875{,}200 \div 120$,
>   which is about 2.6 million."
> - The reveal: exactly $2{,}598{,}960$. Nobody computed
>   $\binom{52}{5}$ that morning; the room reasoned its way to the
>   formula's *shape* — count the ordered ways, then divide out the
>   orders — which is the whole idea [[Combinations]] makes official.

## One variation

The birthday duel, and it humbles a room every time. How many people
must be present before a shared birthday is more likely than not?
Estimates cluster near 180, because 365 halved feels right. The
bracket that breaks the intuition: with 23 people there are
$\binom{23}{2} = 253$ *pairs*, and every pair is a chance. Counting
people is the wrong count — counting pairs is the right one, and the
answer is 23. [[The Birthday Problem]] is where your group proves it
rather than being told.

| People in the room | Chance two share a birthday |
| --- | --- |
| 10 | about 12% |
| 23 | about 51% |
| 30 | about 71% |
| 50 | about 97% |

> [!tip] Bracketing is a life skill
> An answer you cannot bracket is an answer you cannot check. Naming
> "too low" and "too high" first is [[Checking Your Own Work]] done
> in advance — before the mistake instead of after it. Probabilities
> come with free walls: nothing can be below 0 or above 1, and a
> conditional probability cannot exceed the unconditional one it was
> narrowed from. Use the walls.
