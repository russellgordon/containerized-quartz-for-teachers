---
title: Would You Rather
draft: false
created: __CREATED__
tags:
  - number-talks
---
Two options on the board — "would you rather be handed \$5, or roll
one die and collect \$30 if it comes up six?" — and one rule: your
preference is worthless until mathematics backs it. Most good prompts
hide a third answer behind the two printed ones: *it depends* — and
the game is finding on what.

## How we play

1. Choose a side in silence. Commit before calculating feels safe.
2. Defend with numbers, a table, or a tree — not with vibes.
3. Hunt the tipping point: where, exactly, does the better choice
   switch?

> [!example]- The die duel, argued
> - "The sure five. A bird in the hand, and five times out of six the
>   roll pays me nothing at all."
> - "Put them in the same units before choosing. The roll pays 30
>   with probability $\frac{1}{6}$ and 0 otherwise, so its long-run
>   average payout is $\frac{1}{6} \times 30 = 5$. Dead tie. Now the
>   two offers can actually fight."
> - "Which means expected value has *declined to decide this*, and
>   that is the interesting part. Offered the pair once, the sure
>   five wins for most people, because 'on average' is a promise
>   about a long run you do not get. Offered the pair three hundred
>   times, the difference between the two dissolves — and anyone who
>   took the sure five three hundred times gave up nothing."
> - "Tipping point: the payout $p$ where $\frac{p}{6} = 5$, so
>   $p = 30$. Raise the prize past 30 and the roll wins on average;
>   drop it below and the sure thing does. But the variable that
>   decided our actual answers was never the prize — it was how many
>   times we get to play. [[Expected Value]] is an average over
>   repetitions, and 'repetitions' is doing enormous quiet work."

## One variation

"Would you rather learn what the country thinks from 1,000 people
chosen at random, or from 2 million people who chose to answer?" The
room always picks the 2 million, and the room is always wrong. A
famous magazine poll of the 1930s mailed millions of ballots and
counted over two million replies — and called the American
presidential election for the losing candidate by a wide margin,
while a rival polling a few tens of thousands of carefully chosen
respondents got it right. Size shrinks *noise*; only randomness
touches *bias*, and a sample of volunteers is a sample of people who
volunteer. [[Sampling Techniques]] makes that precise, and [[Bias]]
is the autopsy.

> [!tip] "It depends" is a mathematical answer
> The strongest defence names the variable it depends on and the
> exact value where the choice flips. For the die duel the prize
> flips at 30 — but the honest answer named a second variable the
> prompt never mentioned, the number of plays, which is exactly the
> move [[The Fair Game Audit]] asks you to make in writing about a
> real game of chance.
