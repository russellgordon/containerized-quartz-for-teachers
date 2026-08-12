---
title: The Birthday Problem
draft: false
created: __CREATED__
tags:
  - explorations
enableToc: true
---
People keep arriving in a room, one at a time. Nobody has anything in
common yet. At some point two of them share a birthday — same day,
same month, year irrelevant. How many people have to walk in before
that is *more likely than not*?

Write your first instinct on the board before you do anything else.
Everyone's guess goes up, unedited, with a name beside it. This
course begins with a number the whole room gets wrong together.

## The task

First, guess. Then defend the guess — out loud, with a reason, not a
feeling. Then test it. You have the class in front of you and a
random-number generator if you want one, so you can run the
experiment: build rooms of a chosen size, over and over, and count how
often a shared birthday turns up.

Now the harder half. Simulation tells you *what* happens; it never
tells you *why*. Work out the chance exactly. Start smaller than the
question — two people, then three — and find the move that lets you
grow the answer one person at a time. Two hints you will need to
discover rather than be given: it is far easier to compute the chance
that **nobody** shares, and the thing that grows as the room fills is
not the number of people.

Then push. What happens with $366$ people, and why is that question
easy? What changes if you only count matches with *you* — how does
that number compare, and can your group explain the gap without
computing it? And what did you assume about birthdays that is not
quite true of real ones?

> [!tip]- Facilitation notes — for the teacher
> Take the guesses publicly and keep them visible; the gap between the
> board and the answer is the hook for the whole course, and it only
> works if the guesses are committed to in ink. Most rooms cluster
> around half of $365$, which is the tell: they are counting people,
> not pairs. Do not correct that — ask a group of four to list every
> pair among themselves, then ask what happens to that list when a
> fifth person joins.
>
> The complement is the pivot. Groups grinding at "at least one match"
> directly will stall; ask what the *opposite* of "at least one" is
> and let the silence do its work. Groups that get the recursion early
> can be sent at the follow-up questions — the "matches with me"
> version is the one that cements the pairs idea, because the answer
> is so much larger.
>
> Expect an objection that birthdays are not uniformly distributed
> (they are not — more babies are born on some days than others) and
> that twins exist. Both objections are correct and both make a shared
> birthday *more* likely, not less. Say so; it is a first taste of a
> model whose assumptions are wrong in a knowable direction.

## What mathematics tends to surface

Nearly everything Unit 1 needs, arriving because the problem demands
it: a sample space somebody has to describe before it can be counted;
the complement, discovered as a labour-saving device rather than a
rule; independent events multiplied together; and the first honest
encounter with a model whose assumptions do not quite match reality.
The room also meets the idea that intuition about probability is
unreliable in a *systematic* direction — which is why the rest of the
unit exists.

## Where it leads

[[Probability Basics]] names the pieces your boards used — sample
space, event, complement, independence. The counting that made the
computation possible gets its own days in
[[The Fundamental Counting Principle]] and [[Combinations]], and the
habit of checking a surprising answer by simulation returns in
[[The Simulation]].

> [!note] The answer is not on this page
> The threshold, the exact probability, and the reason the growth is
> so fast all get built at the boards. Bring your worst guess.

%%curriculum-start%%
## Curriculum connection

![[A1.3]]

![[A1.5]]
%%curriculum-end%%
