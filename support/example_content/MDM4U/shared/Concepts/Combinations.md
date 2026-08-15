---
title: Combinations
publish: true
created: __CREATED__
tags:
  - concepts
enableToc: true
---
Two prompts went up side by side. *From ten club members, choose a
president, vice-president, secretary, and treasurer.* *From ten club
members, choose a four-person steering committee where everyone is
equal.* Your group got $5040$ for the first and then stalled on the
second, until someone noticed that the committee $\{$Aisha, Ben,
Carla, Dev$\}$ had been counted $24$ separate times — once for every
way of handing those four people the four job titles.

## Dividing out the order

That is the entire idea. A combination is a selection in which order
does **not** carry meaning, so you count the arrangements and then
divide by the $r!$ orderings you cannot tell apart:

$$\binom{n}{r} = \frac{P(n,r)}{r!} = \frac{n!}{r!\,(n-r)!}$$

The committee is $\binom{10}{4} = \frac{5040}{24} = 210$. Say the
relationship out loud, because it is the connection the whole page
exists to make: **an arrangement is a selection followed by an
ordering**, so $P(10,4) = \binom{10}{4} \times 4!$.

Seven people at a gathering, everyone shaking everyone's hand once:
each handshake is a selection of 2 people from 7, order irrelevant, so
$\binom{7}{2} = 21$. Verify it the slow way if you like — the first
person shakes 6 hands, the next 5 new ones, then 4, and
$6+5+4+3+2+1 = 21$. Two routes, one number, which is how you know.

## The order test

Before you reach for a formula, run this:

- [ ] Would swapping two of the chosen items produce a *different*
      outcome? If yes, order matters — [[Permutations]].
- [ ] Do the chosen items receive distinct titles, positions, or
      slots? If yes, order matters.
- [ ] Are the chosen items simply a group, a hand, a subset, a
      committee? If yes, order does not matter — combinations.
- [ ] Still stuck? Shrink the problem to 3 or 4 objects and list them
      by hand. The small case tells you everything.

That last line is not a consolation prize. Shrinking a problem until
you can see it is the most reliable move in this course, and it is
exactly what [[Always, Sometimes, Never]] trains you to do quickly.

## Two properties worth trusting

Symmetry: $\binom{n}{r} = \binom{n}{n-r}$, because choosing the 5 you
take is the same act as choosing the 8 you leave behind. That is a
proof by *meaning*, not by algebra, and it is the better kind.

Selecting in stages: choosing a committee of 5 from 6 girls and 7 boys
with exactly 2 girls is a two-stage task, so multiply the
combinations — $\binom{6}{2} \times \binom{7}{3} = 15 \times 35 =
525$. Counting principles do not stop applying just because
combinations showed up; they are what combinations are built from.

These counts become probabilities the moment every outcome is equally
likely: a five-card hand is one of $\binom{52}{5} = 2\,598\,960$, and
$1287$ of those are all hearts. Work that out properly in
[[Permutations and Combinations Practice]], and meet the same numbers
again, arranged in a triangle, in [[Pascal's Triangle]].

%%curriculum-start%%
## Curriculum connection

![[A2.1]]

![[A2.2]]

![[A2.5]]
%%curriculum-end%%
