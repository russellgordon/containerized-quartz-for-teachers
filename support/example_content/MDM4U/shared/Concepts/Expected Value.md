---
title: Expected Value
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
The prompt at the boards was six sealed cases: three hold \$1 each,
two hold \$1000 each, one holds \$100 000. What is a fair price to
play once? Half the room said \$1000, reasoning from the middle. The
other half said something enormous, reasoning from the jackpot. The
number is \$17 000.50, and nobody guessed it, because a long-run
average is not a typical outcome and never has been.

## The weighted average

The **expected value** of a discrete random variable is every value
multiplied by its probability, summed:

$$E(X) = \sum x\,P(X = x)$$

For the cases: $E(X) = \frac{3}{6}(1) + \frac{2}{6}(1000) +
\frac{1}{6}(100\,000) = \frac{102\,003}{6} = 17\,000.5$.

This is a **weighted mean** — the ordinary mean is the special case
where every weight is equal. Roll one number cube and each face has
weight $\frac{1}{6}$, so
$E(X) = \frac{1+2+3+4+5+6}{6} = 3.5$, which is just the average of the
faces. Weight them unequally and the formula does the bookkeeping the
plain average cannot.

Two properties are worth testing rather than memorizing. Add a
constant to every value and the expected value rises by that constant.
Multiply every value by a constant and the expected value scales by
it. Both fall straight out of the formula, and both are quick to
verify on the six cases — do it once and you will never doubt them.

## The price of a fair game

A game is **fair** when the expected gain is zero: the price of
playing equals the expected winnings. That single sentence is the
engine of [[The Fair Game Audit]], and it is how carnivals stay in
business.

Consider a booth charging \$1 a ticket that pays out \$5 with
probability $0.1$ and nothing otherwise. Work in **net** dollars: a
win puts you $5 - 1 = 4$ ahead, a loss puts you $1$ behind.

$$E(\text{gain}) = (0.1)(4) + (0.9)(-1) = 0.4 - 0.9 = -0.50$$

Fifty cents lost per play, on average, forever. Not a scandal — that
is what it costs to run a booth — but it is a fact the sign above the
booth will never mention, and you can now compute it in under a
minute. Subtracting the ticket price before you weight, rather than
after, is where most of the errors in this topic live.

> [!question]- Self-check: you pay \$2 to roll one number cube and
> receive dollars equal to the number shown. Should you play?
> (click to expand)
> Expected receipt is $3.5$ dollars, and you paid $2$, so the
> expected gain is $3.5 - 2 = 1.5$ — a profit of \$1.50 per roll on
> average. Yes, play, and keep playing. A fair ticket price would be
> \$3.50 exactly. Note what "on average" hides: on any single roll
> you gain \$4 or lose \$1, and never \$1.50.

## What expected value does not promise

It does not promise a typical result. In the six-case game the
expected value of \$17 000.50 is not in any case; five of six players
walk away with \$1000 or less. A single number cannot describe a
lopsided distribution, and reporting only the mean is the most
respectable-looking way to mislead — a habit dissected properly in
[[One-Variable Statistics]].

It also says nothing about **risk**. Two games can share an expected
value and feel completely different to play, one paying small amounts
steadily and the other paying almost nothing almost always. That is a
difference in spread, not centre, and measuring spread is what
standard deviation is for.

And it takes its time. "Expected" means the average of many plays, so
a booth running thousands of games a day collects its fifty cents
reliably while any individual player's evening is mostly noise. That
gap between the long run and one night is the whole business model.

Expected value returns in [[The Binomial Distribution]] with a
shortcut formula, and it is the number your investigation will need if
you analyse a game of chance. Compute a dozen of them in
[[Distributions Practice]].

%%curriculum-start%%
## Curriculum connection

![[B1.1]]

![[B1.2]]

![[B1.7]]
%%curriculum-end%%
